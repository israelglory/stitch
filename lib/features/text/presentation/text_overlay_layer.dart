import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/features/editor/application/canvas_frame_preview.dart';
import 'package:stitch/features/editor/application/clip_frame_preview.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';
import 'package:stitch/features/editor/application/editor_state.dart';
import 'package:stitch/features/editor/application/playback_controller.dart';
import 'package:stitch/features/editor/application/resolved_texts.dart';
import 'package:stitch/features/editor/domain/canvas_snap.dart';
import 'package:stitch/features/text/application/text_rendering.dart';
import 'package:stitch/features/text/domain/text_motion.dart';
import 'package:stitch/features/text/presentation/text_editor_sheet.dart';
import 'package:stitch/features/timeline/domain/composition.dart';
import 'package:stitch/features/timeline/domain/keyframes.dart';
import 'package:stitch/features/timeline/domain/models.dart';
import 'package:stitch/features/timeline/domain/overlay_ops.dart';
import 'package:stitch/l10n/generated/app_localizations.dart';

/// Text on the preview, drawn by the editor rather than the engine: the
/// selected item (with its selection frame, dragged, pinched, and rotated
/// in place) and ones being handed back to the engine. With no native
/// preview ([drawAll]) it draws every text item.
///
/// Also takes the preview's taps: a tap on text selects it (or edits it
/// when already selected); elsewhere it deselects, or toggles playback.
/// With a clip selected, dragging elsewhere moves it, pinching zooms it,
/// and twisting turns it (a keyframe at the playhead once it has any).
///
/// While something is moved, it snaps to the frame's centre and edges
/// (text also to other text), turns snap to level, and a clip's zoom snaps
/// to filling or fitting the frame. Guides show what it snapped to.
class TextOverlayLayer extends ConsumerStatefulWidget {
  const new({required this.projectId, required this.drawAll, super.key});

  final String projectId;
  final bool drawAll;

  @override
  ConsumerState<TextOverlayLayer> createState() => _TextOverlayLayerState();
}

/// A text item as it shows at the playhead: its placement and opacity
/// there (keyframes move them), and its in and out motion.
final class _Shown {
  const new(this.text, this.layout, this.motion, this.transform, this.opacity);

  final ResolvedText text;
  final OverlayTextLayout layout;
  final TextMotion motion;
  final ItemTransform transform;
  final double opacity;
}

/// What the guides show while something is moved on the preview.
@immutable
final class _Guides {
  const new({
    this.lines = const [],
    this.angle,
    this.outline,
    this.center = false,
    this.filled = false,
  });

  /// Lines the item snapped to.
  final List<Guide> lines;

  /// The angle readout, while turning.
  final int? angle;

  /// A moved clip's corners on the preview.
  final List<Offset>? outline;

  /// A mark at the frame's centre.
  final bool center;

  /// The clip exactly fills the frame.
  final bool filled;

  static const none = _Guides();
}

class _TextOverlayLayerState extends ConsumerState<TextOverlayLayer> {
  /// Layouts by what they draw, reused while nothing about them changes.
  final _layouts =
      <(String, TextStyleSpec, double, double), OverlayTextLayout>{};

  /// The dragged item, its values at the playhead, and the focal point
  /// when the drag started.
  String? _dragging;
  KeyframeValues? _dragBase;
  Offset _dragStart = Offset.zero;

  /// The clip or overlay being moved, zoomed, or turned on the canvas.
  KeyframeOwner? _canvasDragging;

  final ValueNotifier<_Guides> _guides = ValueNotifier(_Guides.none);

  /// What the moved item snaps to now, to tap once when a snap engages.
  Set<Object> _engaged = const {};

  void _showGuides(_Guides guides, Set<Object> engaged) {
    if (engaged.difference(_engaged).isNotEmpty) unawaited(AppHaptics.snap());
    _engaged = engaged;
    _guides.value = guides;
  }

  void _clearGuides() {
    _engaged = const {};
    _guides.value = _Guides.none;
  }

  /// How far a gesture has turned, -180 to 180 degrees: the angle it
  /// reports can be a whole turn off.
  static double _turnDegrees(ScaleUpdateDetails d) {
    final degrees = d.rotation * 180 / math.pi;
    return degrees - (degrees / 360).roundToDouble() * 360;
  }

  /// What a set of snapped [lines] (and a snapped turn or zoom) engages.
  static Set<Object> _engagedBy(
    List<Guide> lines, {
    bool rotation = false,
    bool scale = false,
  }) => {
    for (final l in lines) (l.vertical, l.at.round()),
    if (rotation) #rotation,
    if (scale) #scale,
  };

  /// Drops layouts not in [keep] (text changes as it is typed).
  void _keepLayouts(Set<(String, TextStyleSpec, double, double)> keep) {
    _layouts.removeWhere((key, layout) {
      if (keep.contains(key)) return false;
      layout.dispose();
      return true;
    });
  }

  EditorController get _controller =>
      ref.read(editorControllerProvider(widget.projectId).notifier);

  /// Starts moving a clip or overlay ([owner]) on the canvas, when the
  /// playhead is on it: from its values there, showing its frame there (a
  /// clip's), or the whole picture there (an overlay's).
  void _startCanvasDrag(
    EditorState state,
    KeyframeOwner owner,
    int playhead,
    Offset focal,
  ) {
    final values = state.timeline.valuesAt(owner, playhead, state.layout);
    final sourceUs = state.timeline.keyframeTimeAt(
      owner,
      playhead,
      state.layout,
    );
    if (values == null || sourceUs == null) return;
    final playback = ref.read(playbackControllerProvider.notifier);
    if (ref.read(playbackControllerProvider).isPlaying) {
      unawaited(playback.pause());
    }
    _dragging = owner.id;
    _canvasDragging = owner;
    _dragBase = values;
    _dragStart = focal;
    if (owner.kind == KeyframeOwnerKind.clip) {
      ref
          .read(clipFramePreviewProvider(widget.projectId).notifier)
          .follow(owner.id, sourceUs);
    } else {
      unawaited(
        ref
            .read(canvasFramePreviewProvider(widget.projectId).notifier)
            .follow(playhead),
      );
    }
    _controller.beginGesture();
  }

  /// The media, framing mode, and lane of a clip or overlay.
  static ({String mediaId, FramingMode mode})? _placed(
    EditorState state,
    KeyframeOwner owner,
  ) => switch (owner.kind) {
    KeyframeOwnerKind.clip => switch (state.timeline.clipById(owner.id)) {
      null => null,
      final c => (mediaId: c.mediaId, mode: c.framing.mode),
    },
    KeyframeOwnerKind.overlay => switch (state.timeline.overlayById(owner.id)) {
      null => null,
      final o => (mediaId: o.mediaId, mode: o.framing.mode),
    },
    _ => null,
  };

  /// The topmost overlay showing at [playhead] under [point], if any.
  static String? _overlayAt(
    EditorState state,
    int playhead,
    Offset point,
    Size preview,
  ) {
    final timeline = state.timeline;
    final overlays = [...timeline.overlayClips]
      ..sort((a, b) => b.laneIndex.compareTo(a.laneIndex));
    for (final o in overlays) {
      final owner = (kind: KeyframeOwnerKind.overlay, id: o.id);
      if (!overlayShowsAt(o, playhead, state.layout)) continue;
      final v = timeline.valuesAt(owner, playhead, state.layout)!;
      if (v.opacity < 0.01) continue;
      final asset = state.project.media[o.mediaId];
      final size = framedSize(
        preview.width,
        preview.height,
        (asset?.width ?? 0).toDouble(),
        (asset?.height ?? 0).toDouble(),
        fill: o.framing.mode == FramingMode.fill,
      );
      // Into the overlay's own frame: unturned, from its centre.
      final d =
          point -
          Offset((0.5 + v.x) * preview.width, (0.5 + v.y) * preview.height);
      final a = -v.rotationDeg * math.pi / 180;
      final lx = d.dx * math.cos(a) - d.dy * math.sin(a);
      final ly = d.dx * math.sin(a) + d.dy * math.cos(a);
      // A little slack makes small overlays easier to catch.
      const slack = AppSizes.minTouchTarget / 4;
      if (lx.abs() <= size.width * v.scale / 2 + slack &&
          ly.abs() <= size.height * v.scale / 2 + slack) {
        return o.id;
      }
    }
    return null;
  }

  /// Moves (offsets are fractions of the canvas), zooms, and turns the
  /// clip, snapping it to the frame; with keyframes, records one at the
  /// playhead.
  void _updateCanvasDrag(
    ScaleUpdateDetails d,
    KeyframeValues base,
    EditorState state,
    int playhead,
    Size preview,
  ) {
    final owner = _canvasDragging;
    final placed = owner == null ? null : _placed(state, owner);
    if (owner == null || placed == null) return;
    final w = preview.width;
    final h = preview.height;
    // Its size at zoom 1: fitted or filling, as the preview shows it.
    final media = state.project.media[placed.mediaId];
    final size = framedSize(
      w,
      h,
      (media?.width ?? 0).toDouble(),
      (media?.height ?? 0).toDouble(),
      fill: placed.mode == FramingMode.fill,
    );
    final cw = size.width;
    final ch = size.height;

    // Twisting and pinching snap; a drag alone keeps the turn and zoom.
    final turning = d.pointerCount > 1;
    var scale = base.scale * d.scale;
    var scaleSnapped = false;
    var rotation = base.rotationDeg + _turnDegrees(d);
    var rotationSnapped = false;
    if (turning) {
      // Zoom 1, filling the frame, or fitting in it.
      for (final target in {
        1.0,
        math.max(w / cw, h / ch),
        math.min(w / cw, h / ch),
      }) {
        final snap = snapScale(scale, target: target);
        if (snap.snapped) {
          scale = snap.scale;
          scaleSnapped = true;
          break;
        }
      }
      (degrees: rotation, snapped: rotationSnapped) = snapRotation(rotation);
    }
    final extents = turnedHalfExtents(cw * scale, ch * scale, rotation);
    final delta = d.localFocalPoint - _dragStart;
    final snap = snapBox(
      (
        cx: (0.5 + base.x) * w + delta.dx,
        cy: (0.5 + base.y) * h + delta.dy,
        hw: extents.hw,
        hh: extents.hh,
      ),
      width: w,
      height: h,
    );

    final center = Offset(snap.cx, snap.cy);
    final a = rotation * math.pi / 180;
    Offset corner(double sx, double sy) {
      final px = sx * cw * scale / 2;
      final py = sy * ch * scale / 2;
      return center +
          Offset(
            px * math.cos(a) - py * math.sin(a),
            px * math.sin(a) + py * math.cos(a),
          );
    }

    // Level, and its edges on the frame's on both sides of one axis while
    // covering the other: it fills the frame exactly.
    const slack = 0.5;
    final level =
        (rotation / 90 - (rotation / 90).roundToDouble()).abs() < 1e-6;
    final covers =
        snap.cx - extents.hw <= slack &&
        snap.cx + extents.hw >= w - slack &&
        snap.cy - extents.hh <= slack &&
        snap.cy + extents.hh >= h - slack;
    final flush =
        (2 * extents.hw - w).abs() <= slack ||
        (2 * extents.hh - h).abs() <= slack;
    _showGuides(
      _Guides(
        lines: snap.guides,
        angle: turning ? displayAngle(rotation) : null,
        outline: [corner(-1, -1), corner(1, -1), corner(1, 1), corner(-1, 1)],
        center: true,
        filled: level && covers && flush,
      ),
      _engagedBy(snap.guides, rotation: rotationSnapped, scale: scaleSnapped),
    );
    _controller.updateGesture(
      (b) => b.setValuesAt(
        owner,
        playhead,
        (v) => v.copyWith(
          x: snap.cx / w - 0.5,
          y: snap.cy / h - 0.5,
          scale: scale,
          rotationDeg: rotation,
        ),
        newKeyframeId: _controller.gestureKeyframeId,
      ),
    );
  }

  /// Moves, zooms, and turns text [s], snapping it to the frame and to
  /// [shown] text; with keyframes, records one at the playhead.
  void _updateTextDrag(
    ScaleUpdateDetails d,
    KeyframeValues base,
    _Shown s,
    List<_Shown> shown,
    int playhead,
    Size preview,
    double unit,
  ) {
    final w = preview.width;
    final h = preview.height;
    final turning = d.pointerCount > 1;
    final scale = base.scale * d.scale;
    var rotation = base.rotationDeg + _turnDegrees(d);
    var rotationSnapped = false;
    if (turning) {
      (degrees: rotation, snapped: rotationSnapped) = snapRotation(rotation);
    }
    final size = s.layout.size * (unit * scale * s.motion.scale);
    final extents = turnedHalfExtents(size.width, size.height, rotation);
    final delta = d.localFocalPoint - _dragStart;
    final snap = snapBox(
      (
        cx: (base.x + delta.dx / w).clamp(0.0, 1.0) * w,
        cy: ((base.y + delta.dy / h).clamp(0.0, 1.0) + s.motion.dy) * h,
        hw: extents.hw,
        hh: extents.hh,
      ),
      width: w,
      height: h,
      others: [
        for (final o in shown)
          if (o.text.id != s.text.id)
            () {
              final r = MatrixUtils.transformRect(
                _transform(o, preview, unit),
                Offset.zero & o.layout.size,
              );
              return (
                cx: r.center.dx,
                cy: r.center.dy,
                hw: r.width / 2,
                hh: r.height / 2,
              );
            }(),
      ],
    );
    _showGuides(
      _Guides(
        lines: snap.guides,
        angle: turning ? displayAngle(rotation) : null,
      ),
      _engagedBy(snap.guides, rotation: rotationSnapped),
    );
    _controller.updateGesture(
      (b) => b.setValuesAt(
        (kind: KeyframeOwnerKind.text, id: s.text.id),
        playhead,
        (v) => v.copyWith(
          x: (snap.cx / w).clamp(0.0, 1.0),
          y: (snap.cy / h - s.motion.dy).clamp(0.0, 1.0),
          scale: scale,
          rotationDeg: rotation,
        ),
        newKeyframeId: _controller.gestureKeyframeId,
      ),
    );
  }

  @override
  void dispose() {
    for (final layout in _layouts.values) {
      layout.dispose();
    }
    _guides.dispose();
    super.dispose();
  }

  OverlayTextLayout _layout(ResolvedText t, double width, double height) {
    final key = (t.text, t.style, width, height);
    return _layouts[key] ??= OverlayTextLayout(
      overlaySpecFor(t.text, t.style, canvasWidth: width, canvasHeight: height),
    );
  }

  /// Canvas pixels to preview pixels.
  static Matrix4 _transform(_Shown s, Size preview, double unit) {
    final t = s.transform;
    return Matrix4.identity()
      ..translateByDouble(
        t.x * preview.width,
        (t.y + s.motion.dy) * preview.height,
        0,
        1,
      )
      ..rotateZ(t.rotationDeg * math.pi / 180)
      ..scaleByDouble(
        unit * t.scale * s.motion.scale,
        unit * t.scale * s.motion.scale,
        1,
        1,
      )
      ..translateByDouble(
        -s.layout.size.width / 2,
        -s.layout.size.height / 2,
        0,
        1,
      );
  }

  /// The topmost item under [point], if any.
  static String? _hit(
    List<_Shown> shown,
    Offset point,
    Size preview,
    double unit,
  ) {
    for (final s in shown.reversed) {
      final inverse = Matrix4.tryInvert(_transform(s, preview, unit));
      if (inverse == null) continue;
      final local = MatrixUtils.transformPoint(inverse, point);
      // A little slack makes small text easier to catch.
      final slack = AppSizes.minTouchTarget / 4 / unit;
      if ((Offset.zero & s.layout.size).inflate(slack).contains(local)) {
        return s.text.id;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(editorControllerProvider(widget.projectId)).value;
    final texts = ref.watch(resolvedTextsProvider(widget.projectId));
    final playhead = ref.watch(
      playbackControllerProvider.select((p) => p.positionUs),
    );
    if (state == null) return const SizedBox.shrink();
    final canvas = state.project.canvas;
    final selection = state.selection;
    final selectedId = selection is TextSelected ? selection.id : null;

    return LayoutBuilder(
      builder: (context, box) {
        final preview = box.biggest;
        final unit = preview.width / canvas.width;
        final shown = <_Shown>[
          for (final t in texts)
            if (playhead >= t.startUs && playhead < t.endUs)
              () {
                final duration = t.endUs - t.startUs;
                final v = state.timeline.valuesAt(
                  (kind: KeyframeOwnerKind.text, id: t.id),
                  playhead,
                  state.layout,
                );
                return _Shown(
                  t,
                  _layout(t, canvas.width.toDouble(), canvas.height.toDouble()),
                  textMotionAt(
                    animationIn: t.animationIn,
                    inUs: textAnimationUs(t.animationIn, duration),
                    animationOut: t.animationOut,
                    outUs: textAnimationUs(t.animationOut, duration),
                    durationUs: duration,
                    tUs: playhead - t.startUs,
                  ),
                  v == null
                      ? t.transform
                      : ItemTransform(
                          x: v.x,
                          y: v.y,
                          scale: v.scale,
                          rotationDeg: v.rotationDeg,
                        ),
                  v?.opacity ?? 1,
                );
              }(),
        ];
        _keepLayouts({
          for (final s in shown)
            (
              s.text.text,
              s.text.style,
              canvas.width.toDouble(),
              canvas.height.toDouble(),
            ),
        });
        final drawn = [
          for (final s in shown)
            if (widget.drawAll || state.liveTexts.contains(s.text.id)) s,
        ];

        // The preview's Play button speaks for taps here; text boxes have
        // their own nodes below.
        return GestureDetector(
          excludeFromSemantics: true,
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) {
            final hit = _hit(shown, d.localPosition, preview, unit);
            final overlay = hit == null
                ? _overlayAt(state, playhead, d.localPosition, preview)
                : null;
            if (overlay != null) {
              if (selection != OverlaySelected(overlay)) {
                unawaited(AppHaptics.selection());
                _controller.select(OverlaySelected(overlay));
              }
            } else if (hit == null) {
              if (selectedId != null) {
                _controller.select(const NoSelection());
              } else {
                unawaited(
                  ref.read(playbackControllerProvider.notifier).toggle(),
                );
              }
            } else if (hit == selectedId) {
              unawaited(showTextEditor(context, widget.projectId, textId: hit));
            } else {
              _controller.select(TextSelected(hit));
            }
          },
          onScaleStart: (d) {
            final hit = _hit(shown, d.localFocalPoint, preview, unit);
            // Two fingers may start anywhere once a text is selected.
            final id = hit ?? (d.pointerCount > 1 ? selectedId : null);
            final values = id == null
                ? null
                : state.timeline.valuesAt(
                    (kind: KeyframeOwnerKind.text, id: id),
                    playhead,
                    state.layout,
                  );
            if (id == null || values == null) {
              // The selected overlay under the finger (or anywhere, with
              // two), the selected clip anywhere, else the overlay under
              // the finger.
              final under = _overlayAt(
                state,
                playhead,
                d.localFocalPoint,
                preview,
              );
              final owner = switch (selection) {
                OverlaySelected(:final id)
                    when under == id || d.pointerCount > 1 =>
                  (kind: KeyframeOwnerKind.overlay, id: id),
                ClipSelected(:final id) => (
                  kind: KeyframeOwnerKind.clip,
                  id: id,
                ),
                _ when under != null => (
                  kind: KeyframeOwnerKind.overlay,
                  id: under,
                ),
                _ => null,
              };
              if (owner == null) return;
              if (owner.kind == KeyframeOwnerKind.overlay &&
                  selection != OverlaySelected(owner.id)) {
                _controller.select(OverlaySelected(owner.id));
              }
              _startCanvasDrag(state, owner, playhead, d.localFocalPoint);
              return;
            }
            if (id != selectedId) _controller.select(TextSelected(id));
            _dragging = id;
            _dragBase = values;
            _dragStart = d.localFocalPoint;
            _controller.beginGesture();
          },
          onScaleUpdate: (d) {
            final id = _dragging;
            final base = _dragBase;
            if (id == null || base == null) return;
            if (_canvasDragging != null) {
              _updateCanvasDrag(d, base, state, playhead, preview);
              return;
            }
            // Scale and rotation are totals since the start. Keyframed
            // text records a keyframe at the playhead.
            final s = shown.where((s) => s.text.id == id).firstOrNull;
            if (s == null) return;
            _updateTextDrag(d, base, s, shown, playhead, preview, unit);
          },
          onScaleEnd: (_) {
            if (_dragging == null) return;
            final canvas = _canvasDragging;
            _dragging = null;
            _canvasDragging = null;
            _dragBase = null;
            _clearGuides();
            _controller.endGesture();
            // After the edit is sent: its frame stays until shown.
            if (canvas?.kind == KeyframeOwnerKind.clip) {
              ref
                  .read(clipFramePreviewProvider(widget.projectId).notifier)
                  .end();
            } else if (canvas != null) {
              ref
                  .read(canvasFramePreviewProvider(widget.projectId).notifier)
                  .end();
            }
            unawaited(HapticFeedback.selectionClick());
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _TextPainter(
                  drawn: drawn,
                  selectedId: selectedId,
                  preview: preview,
                  unit: unit,
                  frameColor: context.colors.accent,
                ),
                foregroundPainter: _GuidePainter(
                  guides: _guides,
                  lineColor: context.colors.accent,
                  frameColor: context.colors.onOverlay,
                ),
              ),
              ValueListenableBuilder(
                valueListenable: _guides,
                builder: (context, guides, _) => switch (guides.angle) {
                  null => const SizedBox.shrink(),
                  final angle => Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: ExcludeSemantics(
                        child: MediaLabel(l10n.angleDegrees(angle)),
                      ),
                    ),
                  ),
                },
              ),
              // Screen readers find each text box; its bounds, unrotated.
              for (final s in shown)
                Positioned.fromRect(
                  rect: MatrixUtils.transformRect(
                    _transform(s, preview, unit),
                    Offset.zero & s.layout.size,
                  ),
                  child: Semantics(
                    button: true,
                    selected: s.text.id == selectedId,
                    label: l10n.textItemSemantics(s.text.text),
                    onTap: () => s.text.id == selectedId
                        ? unawaited(
                            showTextEditor(
                              context,
                              widget.projectId,
                              textId: s.text.id,
                            ),
                          )
                        : _controller.select(TextSelected(s.text.id)),
                    child: const SizedBox.expand(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TextPainter extends CustomPainter {
  const new({
    required this.drawn,
    required this.selectedId,
    required this.preview,
    required this.unit,
    required this.frameColor,
  });

  final List<_Shown> drawn;
  final String? selectedId;
  final Size preview;
  final double unit;
  final Color frameColor;

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in drawn) {
      canvas
        ..save()
        ..transform(
          _TextOverlayLayerState._transform(s, preview, unit).storage,
        );
      final alpha = (s.motion.alpha * s.opacity).clamp(0.0, 1.0);
      if (alpha < 1) {
        canvas.saveLayer(
          Offset.zero & s.layout.size,
          Paint()..color = frameColor.withValues(alpha: alpha),
        );
      }
      final count = s.layout.characterCount;
      s.layout.paint(
        canvas,
        Offset.zero,
        revealed: s.motion.reveal >= 1
            ? null
            : (s.motion.reveal * count).ceil(),
      );
      if (alpha < 1) canvas.restore();
      if (s.text.id == selectedId) {
        // A thin frame, the same width at any scale.
        final scale = unit * s.transform.scale * s.motion.scale;
        canvas.drawRect(
          Offset.zero & s.layout.size,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = AppSizes.strokeWidth / scale
            ..color = frameColor,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_TextPainter old) =>
      old.drawn != drawn ||
      old.selectedId != selectedId ||
      old.preview != preview ||
      old.frameColor != frameColor;
}

/// Snap guides: lines at what the moved item lines up with, a moved
/// clip's outline and the frame's centre, and a border when the clip
/// fills the frame exactly.
class _GuidePainter extends CustomPainter {
  new({required this.guides, required this.lineColor, required this.frameColor})
    : super(repaint: guides);

  final ValueNotifier<_Guides> guides;
  final Color lineColor;
  final Color frameColor;

  @override
  void paint(Canvas canvas, Size size) {
    final g = guides.value;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppSizes.borderWidth
      ..color = lineColor;
    if (g.center) {
      final c = size.center(Offset.zero);
      const arm = AppSpacing.sm;
      canvas
        ..drawLine(c - const Offset(arm, 0), c + const Offset(arm, 0), line)
        ..drawLine(c - const Offset(0, arm), c + const Offset(0, arm), line);
    }
    if (g.outline case final outline?) {
      canvas.drawPath(
        Path()..addPolygon(outline, true),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = AppSizes.strokeWidth
          ..color = lineColor,
      );
    }
    // Lines on the frame's edges sit just inside it.
    const inset = AppSizes.borderWidth / 2;
    for (final l in g.lines) {
      final at = l.at.clamp(
        inset,
        (l.vertical ? size.width : size.height) - inset,
      );
      if (l.vertical) {
        canvas.drawLine(Offset(at, 0), Offset(at, size.height), line);
      } else {
        canvas.drawLine(Offset(0, at), Offset(size.width, at), line);
      }
    }
    if (g.filled) {
      canvas.drawRect(
        (Offset.zero & size).deflate(AppSizes.strokeWidth / 2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = AppSizes.strokeWidth
          ..color = frameColor,
      );
    }
  }

  @override
  bool shouldRepaint(_GuidePainter old) =>
      old.guides != guides ||
      old.lineColor != lineColor ||
      old.frameColor != frameColor;
}
