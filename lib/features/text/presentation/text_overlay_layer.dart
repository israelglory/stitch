import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';
import 'package:stitch/features/editor/application/editor_state.dart';
import 'package:stitch/features/editor/application/playback_controller.dart';
import 'package:stitch/features/editor/application/resolved_texts.dart';
import 'package:stitch/features/text/application/text_rendering.dart';
import 'package:stitch/features/text/domain/text_motion.dart';
import 'package:stitch/features/text/presentation/text_editor_sheet.dart';
import 'package:stitch/features/timeline/domain/composition.dart';
import 'package:stitch/features/timeline/domain/models.dart';
import 'package:stitch/features/timeline/domain/text_ops.dart';
import 'package:stitch/l10n/generated/app_localizations.dart';

/// Text on the preview, drawn by the editor rather than the engine: the
/// selected item (with its selection frame, dragged, pinched, and rotated
/// in place) and ones being handed back to the engine. With no native
/// preview ([drawAll]) it draws every text item.
///
/// Also takes the preview's taps: a tap on text selects it (or edits it
/// when already selected); elsewhere it deselects, or toggles playback.
class TextOverlayLayer extends ConsumerStatefulWidget {
  const new({required this.projectId, required this.drawAll, super.key});

  final String projectId;
  final bool drawAll;

  @override
  ConsumerState<TextOverlayLayer> createState() => _TextOverlayLayerState();
}

/// A text item as it shows at the playhead.
final class _Shown {
  const new(this.text, this.layout, this.motion);

  final ResolvedText text;
  final OverlayTextLayout layout;
  final TextMotion motion;
}

class _TextOverlayLayerState extends ConsumerState<TextOverlayLayer> {
  /// Layouts by what they draw, reused while nothing about them changes.
  final _layouts =
      <(String, TextStyleSpec, double, double), OverlayTextLayout>{};

  /// The dragged item, its transform, and the focal point when the drag
  /// started.
  String? _dragging;
  ItemTransform? _dragBase;
  Offset _dragStart = Offset.zero;

  static const _minScale = 0.2;
  static const _maxScale = 8.0;

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

  @override
  void dispose() {
    for (final layout in _layouts.values) {
      layout.dispose();
    }
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
    final t = s.text.transform;
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

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) {
            final hit = _hit(shown, d.localPosition, preview, unit);
            if (hit == null) {
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
            final item = id == null ? null : state.timeline.textById(id);
            if (id == null || item == null) return;
            if (id != selectedId) _controller.select(TextSelected(id));
            _dragging = id;
            _dragBase = item.transform;
            _dragStart = d.localFocalPoint;
            _controller.beginGesture();
          },
          onScaleUpdate: (d) {
            final id = _dragging;
            final base = _dragBase;
            if (id == null || base == null) return;
            // Scale and rotation are totals since the start.
            final delta = d.localFocalPoint - _dragStart;
            final moved = base.copyWith(
              x: (base.x + delta.dx / preview.width).clamp(0.0, 1.0),
              y: (base.y + delta.dy / preview.height).clamp(0.0, 1.0),
              scale: (base.scale * d.scale).clamp(_minScale, _maxScale),
              rotationDeg: base.rotationDeg + d.rotation * 180 / math.pi,
            );
            _controller.updateGesture(
              (b) => b.updateText(id, (t) => t.copyWith(transform: moved)),
            );
          },
          onScaleEnd: (_) {
            if (_dragging == null) return;
            _dragging = null;
            _dragBase = null;
            _controller.endGesture();
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
      final alpha = s.motion.alpha.clamp(0.0, 1.0);
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
        final scale = unit * s.text.transform.scale * s.motion.scale;
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
