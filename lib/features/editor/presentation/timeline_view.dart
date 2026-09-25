import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stitch/app/providers.dart';
import 'package:stitch/core/time/time.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/features/audio/application/audio_providers.dart';
import 'package:stitch/features/audio/application/waveforms.dart';
import 'package:stitch/features/audio/domain/waveform_slice.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';
import 'package:stitch/features/editor/application/editor_state.dart';
import 'package:stitch/features/editor/application/playback_controller.dart';
import 'package:stitch/features/editor/presentation/clip_frame.dart';
import 'package:stitch/features/editor/presentation/editor_media.dart';
import 'package:stitch/features/timeline/domain/audio_ops.dart';
import 'package:stitch/features/timeline/domain/caption_ops.dart';
import 'package:stitch/features/timeline/domain/layout.dart';
import 'package:stitch/features/timeline/domain/models.dart' as m;
import 'package:stitch/features/timeline/domain/normalize.dart';
import 'package:stitch/features/timeline/domain/snapping.dart';
import 'package:stitch/features/timeline/domain/text_ops.dart';
import 'package:stitch/features/timeline/domain/video_ops.dart';
import 'package:stitch/l10n/generated/app_localizations.dart';

/// Drag speed below which a released scrub stops instead of gliding.
const double _minFlingVelocity = 50;

/// Friction of a gliding scrub (fraction of velocity kept per second).
const double _flingDrag = 0.135;

/// Room after the last clip for the add button.
const double _trailingSpace = AppSizes.minTouchTarget + AppSpacing.xxl;

/// Visual gap between neighboring clips.
const double _clipGap = AppSizes.strokeWidth;

enum _RowKind { text, captions, video, audio }

final class _Row {
  const new(this.kind, this.lane, this.height);

  final _RowKind kind;
  final int lane;
  final double height;
}

/// The horizontal timeline. The playhead is a fixed center line and the
/// content scrolls under it: the scroll position *is* the playhead time.
///
/// Content is rebuilt only when the project or zoom changes. Playback and
/// scrubbing move it with a transform driven by a position notifier, so the
/// timeline does not rebuild at display rate.
class TimelineView extends ConsumerStatefulWidget {
  const new({
    required this.projectId,
    required this.onAddMedia,
    required this.onTransition,
    super.key,
  });

  final String projectId;
  final VoidCallback onAddMedia;

  /// Opens the transition sheet for the cut after the given clip.
  final ValueChanged<String> onTransition;

  @override
  ConsumerState<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends ConsumerState<TimelineView>
    with SingleTickerProviderStateMixin {
  TimelineScale _scale = const TimelineScale(
    TimelineScale.defaultPixelsPerSecond,
  );
  final _position = ValueNotifier<int>(0);
  late final AnimationController _fling = AnimationController.unbounded(
    vsync: this,
  )..addListener(_onFlingTick);

  /// True while a finger (or a glide) drives the playhead.
  bool _scrubbing = false;
  int _gestureStartUs = 0;
  double _panDx = 0;
  int _pointers = 0;
  TimelineScale _zoomStart = const TimelineScale(
    TimelineScale.defaultPixelsPerSecond,
  );
  int _flingStartUs = 0;

  EditorController get _editor =>
      ref.read(editorControllerProvider(widget.projectId).notifier);
  PlaybackController get _playback =>
      ref.read(playbackControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    ref.listenManual(playbackControllerProvider.select((p) => p.positionUs), (
      _,
      position,
    ) {
      if (!_scrubbing) _position.value = position;
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _fling
      ..stop()
      ..dispose();
    _position.dispose();
    super.dispose();
  }

  int get _durationUs =>
      ref
          .read(editorControllerProvider(widget.projectId))
          .value
          ?.layout
          .durationUs ??
      0;

  void _setPosition(int us) {
    final clamped = us.clamp(0, _durationUs);
    _position.value = clamped;
    _playback.scrubTo(clamped);
  }

  // Scrub and zoom.

  void _onScaleStart(ScaleStartDetails d) {
    _fling.stop();
    _pointers = d.pointerCount;
    if (!_scrubbing) {
      _scrubbing = true;
      _playback.beginScrub();
    }
    _gestureStartUs = _position.value;
    _panDx = 0;
    _zoomStart = _scale;
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    _pointers = math.max(_pointers, d.pointerCount);
    if (d.pointerCount >= 2) {
      // Zoom keeps the playhead time fixed under the center line.
      final next = _zoomStart.zoomed(d.horizontalScale);
      if (next.pixelsPerSecond != _scale.pixelsPerSecond) {
        setState(() => _scale = next);
      }
    } else {
      _panDx += d.focalPointDelta.dx;
      _setPosition(_gestureStartUs - _scale.pxToUs(_panDx));
    }
  }

  void _onScaleEnd(ScaleEndDetails d) {
    final velocity = d.velocity.pixelsPerSecond.dx;
    if (_pointers == 1 && velocity.abs() > _minFlingVelocity) {
      _flingStartUs = _position.value;
      unawaited(
        _fling
            .animateWith(FrictionSimulation(_flingDrag, 0, -velocity))
            .whenComplete(_endScrub),
      );
    } else {
      _endScrub();
    }
    _pointers = 0;
  }

  void _onFlingTick() {
    if (!_scrubbing || !mounted) return;
    _setPosition(_flingStartUs + _scale.pxToUs(_fling.value));
    final atEdge = _position.value == 0 || _position.value == _durationUs;
    if (atEdge) _fling.stop();
  }

  void _endScrub() {
    if (!_scrubbing) return;
    _scrubbing = false;
    _playback.endScrub();
  }

  // Item editing, used by the content.

  late final _actions = _TimelineActions(this);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorControllerProvider(widget.projectId)).value;
    if (state == null) return const SizedBox.shrink();
    final rows = _rowsFor(state.timeline);
    final contentHeight =
        AppSizes.rulerHeight +
        rows.fold<double>(0, (sum, r) => sum + r.height + AppSpacing.xs) +
        AppSpacing.sm;

    return LayoutBuilder(
      builder: (context, box) {
        final center = box.maxWidth / 2;
        final contentWidth =
            _scale.usToPx(state.layout.durationUs) + _trailingSpace;

        final content = _Content(
          state: state,
          rows: rows,
          scale: _scale,
          width: contentWidth,
          actions: _actions,
          onAddMedia: widget.onAddMedia,
          onTransition: widget.onTransition,
        );

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _editor.select(const NoSelection()),
          onScaleStart: _onScaleStart,
          onScaleUpdate: _onScaleUpdate,
          onScaleEnd: _onScaleEnd,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: SizedBox(
              height: contentHeight,
              child: Stack(
                children: [
                  // Scrolling content, positioned by the playhead.
                  Positioned.fill(
                    child: ValueListenableBuilder<int>(
                      valueListenable: _position,
                      builder: (context, position, child) =>
                          Transform.translate(
                            offset: Offset(center - _scale.usToPx(position), 0),
                            child: child,
                          ),
                      child: OverflowBox(
                        alignment: AlignmentDirectional.topStart,
                        maxWidth: double.infinity,
                        child: SizedBox(
                          width: contentWidth,
                          child: RepaintBoundary(child: content),
                        ),
                      ),
                    ),
                  ),
                  // Fixed lane headers, over the content.
                  Positioned(
                    left: 0,
                    top: AppSizes.rulerHeight,
                    child: _LaneHeaders(
                      rows: rows,
                      originalSoundEnabled:
                          state.timeline.audioMix.originalSoundEnabled,
                      onToggleSound: () => _editor.apply(
                        (t) => t.setAudioMix(
                          originalSoundEnabled:
                              !t.audioMix.originalSoundEnabled,
                        ),
                      ),
                    ),
                  ),
                  // Fixed playhead.
                  Positioned(
                    left: center - AppSizes.strokeWidth / 2,
                    top: 0,
                    bottom: 0,
                    child: const Playhead(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Rows top to bottom: text lanes (highest first), captions, video,
  /// audio lanes. Empty lanes other than video are not shown.
  static List<_Row> _rowsFor(m.Timeline t) {
    final textLanes = t.textItems.isEmpty
        ? 0
        : t.textItems.map((x) => x.laneIndex).reduce(math.max) + 1;
    return [
      for (var lane = textLanes - 1; lane >= 0; lane--)
        _Row(_RowKind.text, lane, AppSizes.laneHeight),
      if (t.captionTrack.segments.isNotEmpty)
        const _Row(_RowKind.captions, 0, AppSizes.laneHeight),
      const _Row(_RowKind.video, 0, AppSizes.videoTrackHeight),
      for (var lane = 0; lane < t.audioLanes.length; lane++)
        _Row(_RowKind.audio, lane, AppSizes.laneHeight),
    ];
  }
}

/// Editing gestures on timeline items, with snapping and haptics.
final class _TimelineActions {
  new(this._view);

  final _TimelineViewState _view;

  EditorController get _editor => _view._editor;
  TimelineScale get scale => _view._scale;

  m.Timeline? _base;
  int _basePositionUs = 0;
  double _dragPx = 0;
  bool _snapped = false;

  void select(Selection selection) {
    unawaited(AppHaptics.selection());
    _editor.select(selection);
  }

  /// Snaps [candidateUs] against everything except [excludeId], playing
  /// the snap haptic when it first catches.
  int _snap(int candidateUs, String excludeId) {
    final result = snap(
      candidateUs,
      snapTargets(_base!, playheadUs: _basePositionUs, excludeIds: {excludeId}),
      scale: scale,
    );
    if (result.snapped && !_snapped) unawaited(AppHaptics.snap());
    _snapped = result.snapped;
    return result.timeUs;
  }

  void _begin() {
    _editor.beginGesture();
    _base = _view.ref
        .read(editorControllerProvider(_view.widget.projectId))
        .requireValue
        .timeline;
    _basePositionUs = _view._position.value;
    _dragPx = 0;
    _snapped = false;
  }

  void _end() {
    _editor.endGesture();
    _base = null;
    unawaited(_view._playback.seek(_view._position.value));
  }

  /// Trim callbacks for an item whose edges on the base timeline are
  /// given by [edges], applied with [trim].
  TrimCallbacks trimFor({
    required String id,
    required (int, int) Function(m.Timeline base) edges,
    required m.Timeline Function(m.Timeline base, ClipEdge edge, int deltaUs)
    trim,
    bool keepEndInPlace = false,
  }) => TrimCallbacks(
    onStart: (_) => _begin(),
    onUpdate: (edge, dx) {
      final base = _base;
      if (base == null) return;
      _dragPx += dx;
      final (start, end) = edges(base);
      final domainEdge = edge == TrimEdge.start ? ClipEdge.start : ClipEdge.end;
      final original = domainEdge == ClipEdge.start ? start : end;
      final target = _snap(original + scale.pxToUs(_dragPx), id);
      _editor.updateGesture((b) => trim(b, domainEdge, target - original));

      if (keepEndInPlace && domainEdge == ClipEdge.start) {
        // Main-track start trims ripple the clip's end instead of moving
        // its start. Shift the view by the same amount so the dragged edge
        // follows the finger and everything after it stays still.
        final now = _view.ref
            .read(editorControllerProvider(_view.widget.projectId))
            .requireValue;
        final newEnd = now.layout.span(id)?.endUs ?? end;
        _view._position.value = math.max(0, _basePositionUs - (end - newEnd));
      }
    },
    onEnd: (_) => _end(),
  );

  // Moving items by long-press drag.

  String? movingId;

  void beginMove(String id) {
    unawaited(AppHaptics.selection());
    movingId = id;
    _begin();
  }

  void updateMove({
    required String id,
    required int originalStartUs,
    required int durationUs,
    required double dx,
    required m.Timeline Function(m.Timeline base, int startUs) move,
  }) {
    if (_base == null) return;
    final raw = originalStartUs + scale.pxToUs(dx);
    // Snap whichever edge is closer to a target.
    final snappedStart = _snap(raw, id);
    final start = snappedStart != raw
        ? snappedStart
        : _snap(raw + durationUs, id) - durationUs;
    _editor.updateGesture((b) => move(b, start));
  }

  void endMove() {
    movingId = null;
    _end();
  }
}

class _LaneHeaders extends StatelessWidget {
  const new({
    required this.rows,
    required this.originalSoundEnabled,
    required this.onToggleSound,
  });

  final List<_Row> rows;
  final bool originalSoundEnabled;
  final VoidCallback onToggleSound;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ColoredBox(
      color: context.colors.background,
      child: Column(
        children: [
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: switch (row.kind) {
                _RowKind.video => LaneHeader(
                  icon: originalSoundEnabled ? AppIcons.volume : AppIcons.muted,
                  label: originalSoundEnabled ? l10n.laneSound : l10n.laneMuted,
                  height: row.height,
                  active: originalSoundEnabled,
                  onPressed: onToggleSound,
                ),
                _RowKind.text => LaneHeader(
                  icon: AppIcons.text,
                  label: l10n.laneText,
                  height: row.height,
                ),
                _RowKind.captions => LaneHeader(
                  icon: AppIcons.captions,
                  label: l10n.laneCaptions,
                  height: row.height,
                ),
                _RowKind.audio => LaneHeader(
                  icon: AppIcons.audio,
                  label: l10n.laneAudio,
                  height: row.height,
                ),
              },
            ),
        ],
      ),
    );
  }
}

/// All timeline items, laid out at time zero = x zero.
class _Content extends ConsumerStatefulWidget {
  const new({
    required this.state,
    required this.rows,
    required this.scale,
    required this.width,
    required this.actions,
    required this.onAddMedia,
    required this.onTransition,
  });

  final EditorState state;
  final List<_Row> rows;
  final TimelineScale scale;
  final double width;
  final _TimelineActions actions;
  final VoidCallback onAddMedia;
  final ValueChanged<String> onTransition;

  @override
  ConsumerState<_Content> createState() => _ContentState();
}

class _ContentState extends ConsumerState<_Content> {
  /// Clip being reordered, and the index it would drop at.
  String? _reorderId;
  int? _reorderTarget;
  double _reorderStartX = 0;

  double _px(int us) => widget.scale.usToPx(us);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = widget.state;
    final ratio = MediaQuery.devicePixelRatioOf(context);
    var top = AppSizes.rulerHeight;
    final children = <Widget>[
      TimeRuler(
        pixelsPerSecond: widget.scale.pixelsPerSecond,
        originX: 0,
        durationUs: state.layout.durationUs,
      ),
    ];

    for (final row in widget.rows) {
      top += AppSpacing.xs;
      children.addAll(switch (row.kind) {
        _RowKind.video => _videoRow(l10n, top, ratio),
        _RowKind.text => _textRow(row.lane, top),
        _RowKind.captions => _captionRow(top),
        _RowKind.audio => _audioRow(row.lane, top),
      });
      top += row.height;
    }

    return SizedBox(
      width: widget.width,
      child: Stack(clipBehavior: Clip.none, children: children),
    );
  }

  List<Widget> _videoRow(AppLocalizations l10n, double top, double ratio) {
    final state = widget.state;
    final layout = state.layout;
    final spans = layout.spans;
    final actions = widget.actions;
    final widgets = <Widget>[];

    // Clips are drawn meeting at the middle of each transition overlap.
    double visualStart(int i) =>
        _px(spans[i].startUs) +
        (i == 0 ? 0 : _px(layout.transitionUs(spans[i - 1].clip.id)) / 2);
    double visualEnd(int i) =>
        _px(spans[i].endUs) - _px(layout.transitionUs(spans[i].clip.id)) / 2;

    for (final (i, span) in spans.indexed) {
      final clip = span.clip;
      final selected = state.selection == ClipSelected(clip.id);
      final left = visualStart(i) + _clipGap / 2;
      final double width = math.max(
        0,
        visualEnd(i) - visualStart(i) - _clipGap,
      );
      final durationLabel =
          '${(clip.durationUs / usPerSecond).toStringAsFixed(1)}s';
      widgets.add(
        Positioned(
          left: left,
          top: top,
          child: Opacity(
            opacity: _reorderId == clip.id ? 0.4 : 1,
            child: GestureDetector(
              onLongPressStart: (d) {
                unawaited(AppHaptics.selection());
                setState(() {
                  _reorderId = clip.id;
                  _reorderTarget = i;
                  _reorderStartX = left + d.localPosition.dx;
                });
              },
              onLongPressMoveUpdate: (d) => setState(
                () => _reorderTarget = _dropIndex(
                  _reorderStartX + d.offsetFromOrigin.dx,
                  clip.id,
                  visualStart,
                  visualEnd,
                ),
              ),
              onLongPressEnd: (_) => _finishReorder(clip.id),
              child: VideoClipTile(
                width: width,
                durationLabel: durationLabel,
                speedLabel: clip.speed == 1 ? null : _speedLabel(clip.speed),
                isMissing: state.missingMedia.contains(clip.mediaId),
                selected: selected,
                onTap: () => actions.select(ClipSelected(clip.id)),
                trim: selected
                    ? actions.trimFor(
                        id: clip.id,
                        keepEndInPlace: true,
                        edges: (b) {
                          final s = TimelineLayout.of(b).span(clip.id);
                          return (s?.startUs ?? 0, s?.endUs ?? 0);
                        },
                        trim: (b, edge, delta) =>
                            b.trimClip(clip.id, edge, delta),
                      )
                    : null,
                frameBuilder: (context, i) {
                  final asset = state.project.media[clip.mediaId];
                  final cacheWidth = (AppSizes.videoTrackHeight * ratio)
                      .round();
                  if (asset == null || clip.isPhoto) {
                    return MediaPoster(
                      project: state.project,
                      mediaId: clip.mediaId,
                      cacheWidth: cacheWidth,
                    );
                  }
                  // Middle of the frame's slot, in source time.
                  final slotUs = widget.scale.pxToUs(
                    (i + 0.5) * AppSizes.videoTrackHeight,
                  );
                  final sourceUs = math.min(
                    clip.sourceOutUs,
                    clip.sourceInUs + (slotUs * clip.speed).round(),
                  );
                  return ClipFrame(
                    project: state.project,
                    mediaId: clip.mediaId,
                    mediaPath: ref
                        .read(projectStoreProvider)
                        .resolve(state.project.id, asset.path),
                    sourceUs: sourceUs,
                    cacheWidth: cacheWidth,
                  );
                },
              ),
            ),
          ),
        ),
      );
    }

    // Transition buttons at each cut. The cuts next to the selected clip
    // are left free, since the buttons would cover its trim handles.
    final selectedIndex = switch (state.selection) {
      ClipSelected(:final id) => state.timeline.indexOfClip(id),
      _ => -1,
    };
    for (var i = 0; i + 1 < spans.length; i++) {
      if (i == selectedIndex || i + 1 == selectedIndex) continue;
      final x = visualEnd(i);
      final clipId = spans[i].clip.id;
      widgets.add(
        Positioned(
          left: x - AppSizes.minTouchTarget / 2,
          top: top + (AppSizes.videoTrackHeight - AppSizes.minTouchTarget) / 2,
          child: TransitionButton(
            semanticLabel: l10n.transitionSemantics(i + 1),
            hasTransition: state.timeline.transitionAfter(clipId) != null,
            onPressed: () => widget.onTransition(clipId),
          ),
        ),
      );
    }

    // Drop indicator while reordering.
    if (_reorderId != null && _reorderTarget != null) {
      final order = [
        for (final s in spans)
          if (s.clip.id != _reorderId) s,
      ];
      final t = _reorderTarget!;
      final x = order.isEmpty
          ? 0.0
          : t >= order.length
          ? visualEnd(order.last.index)
          : visualStart(order[t].index);
      widgets.add(
        Positioned(
          left: x - AppSizes.strokeWidth / 2,
          top: top - AppSpacing.xs,
          child: IgnorePointer(
            child: Container(
              width: AppSizes.strokeWidth,
              height: AppSizes.videoTrackHeight + AppSpacing.sm,
              color: context.colors.accent,
            ),
          ),
        ),
      );
    }

    // Add button after the last clip.
    widgets.add(
      Positioned(
        left: _px(layout.durationUs) + AppSpacing.sm,
        top: top + (AppSizes.videoTrackHeight - AppSizes.minTouchTarget) / 2,
        child: AppIconButton(
          icon: AppIcons.add,
          semanticLabel: AppLocalizations.of(context).addClip,
          style: IconButtonStyle.filled,
          onPressed: widget.onAddMedia,
        ),
      ),
    );
    return widgets;
  }

  /// Index the clip would take if dropped at content x [x].
  int _dropIndex(
    double x,
    String movingId,
    double Function(int) visualStart,
    double Function(int) visualEnd,
  ) {
    var index = 0;
    for (final span in widget.state.layout.spans) {
      if (span.clip.id == movingId) continue;
      final mid = (visualStart(span.index) + visualEnd(span.index)) / 2;
      if (x > mid) index++;
    }
    return index;
  }

  void _finishReorder(String clipId) {
    final target = _reorderTarget;
    setState(() {
      _reorderId = null;
      _reorderTarget = null;
    });
    if (target == null) return;
    widget.actions._editor.apply((t) => t.moveClip(clipId, target));
  }

  List<Widget> _textRow(int lane, double top) {
    final state = widget.state;
    final layout = state.layout;
    return [
      for (final item in state.timeline.textItems)
        if (item.laneIndex == lane)
          _laneItem(
            id: item.id,
            top: top,
            start: layout.startOf(item.anchor),
            duration: item.durationUs,
            selection: TextSelected(item.id),
            move: (b, start) => b.moveText(item.id, start),
            trim: (b, edge, delta) => b.trimText(item.id, edge, delta),
            edgesOf: (b) {
              final x = b.textById(item.id);
              final s = x == null ? 0 : TimelineLayout.of(b).startOf(x.anchor);
              return (s, s + (x?.durationUs ?? 0));
            },
            build: ({required width, required selected, trim}) =>
                OverlayItemTile(
                  kind: OverlayKind.text,
                  label: item.text,
                  width: width,
                  selected: selected,
                  needsReview: item.needsReview,
                  trim: trim,
                  onTap: () => widget.actions.select(TextSelected(item.id)),
                ),
          ),
    ];
  }

  List<Widget> _captionRow(double top) {
    final state = widget.state;
    final layout = state.layout;
    return [
      for (final item in state.timeline.captionTrack.segments)
        _laneItem(
          id: item.id,
          top: top,
          start: layout.startOf(item.anchor),
          duration: item.durationUs,
          selection: CaptionSelected(item.id),
          move: (b, start) => b.moveCaption(item.id, start),
          trim: (b, edge, delta) => b.trimCaption(item.id, edge, delta),
          edgesOf: (b) {
            final x = b.captionById(item.id);
            final s = x == null ? 0 : TimelineLayout.of(b).startOf(x.anchor);
            return (s, s + (x?.durationUs ?? 0));
          },
          build: ({required width, required selected, trim}) => OverlayItemTile(
            kind: OverlayKind.caption,
            label: item.text,
            width: width,
            selected: selected,
            needsReview: item.needsReview,
            trim: trim,
            onTap: () => widget.actions.select(CaptionSelected(item.id)),
          ),
        ),
    ];
  }

  List<Widget> _audioRow(int lane, double top) {
    final state = widget.state;
    final layout = state.layout;
    return [
      for (final item in state.timeline.audioItems)
        if (item.laneIndex == lane)
          () {
            final start = layout.startOf(item.anchor);
            final end = audioEndUs(item, layout);
            final media = state.project.media[item.mediaId];
            final peaks = media == null
                ? null
                : ref
                      .watch(
                        waveformProvider(
                          ref
                              .read(projectStoreProvider)
                              .resolve(state.project.id, media.path),
                        ),
                      )
                      .value;
            final waveform = peaks == null
                ? null
                : waveformSlice(
                    peaks,
                    peaksPerSecond: waveformPeaksPerSecond,
                    sourceInUs: item.sourceInUs,
                    sourceOutUs: item.sourceOutUs,
                    speed: item.speed,
                    loop: item.loop,
                    durationUs: end - start,
                  );
            return _laneItem(
              id: item.id,
              top: top,
              start: start,
              duration: end - start,
              selection: AudioSelected(item.id),
              move: (b, s) => b.moveAudio(item.id, s),
              trim: (b, edge, delta) => b.trimAudio(item.id, edge, delta),
              edgesOf: (b) {
                final x = b.audioById(item.id);
                if (x == null) return (0, 0);
                final l = TimelineLayout.of(b);
                return (l.startOf(x.anchor), audioEndUs(x, l));
              },
              build: ({required width, required selected, trim}) =>
                  AudioItemTile(
                    kind: switch (item.kind) {
                      m.AudioKind.music => AudioKind.music,
                      m.AudioKind.soundEffect => AudioKind.soundEffect,
                      m.AudioKind.voiceover => AudioKind.voiceover,
                      m.AudioKind.extracted => AudioKind.extracted,
                    },
                    label: item.name,
                    width: width,
                    waveform: waveform,
                    fadeInPx: _px(item.fadeInUs),
                    fadeOutPx: _px(item.fadeOutUs),
                    overflowStartPx: end > layout.durationUs
                        ? _px(layout.durationUs - start)
                        : null,
                    selected: selected,
                    needsReview: item.needsReview,
                    trim: trim,
                    onTap: () => widget.actions.select(AudioSelected(item.id)),
                  ),
            );
          }(),
    ];
  }

  Widget _laneItem({
    required String id,
    required double top,
    required int start,
    required int duration,
    required Selection selection,
    required m.Timeline Function(m.Timeline base, int startUs) move,
    required m.Timeline Function(m.Timeline, ClipEdge, int) trim,
    required (int, int) Function(m.Timeline base) edgesOf,
    required Widget Function({
      required double width,
      required bool selected,
      TrimCallbacks? trim,
    })
    build,
  }) {
    final actions = widget.actions;
    final selected = widget.state.selection == selection;
    final width = math.max(_px(duration) - _clipGap, AppSpacing.xs);
    return Positioned(
      left: _px(start) + _clipGap / 2,
      top: top,
      child: GestureDetector(
        onLongPressStart: (_) => actions.beginMove(id),
        onLongPressMoveUpdate: (d) => actions.updateMove(
          id: id,
          originalStartUs: start,
          durationUs: duration,
          dx: d.offsetFromOrigin.dx,
          move: move,
        ),
        onLongPressEnd: (_) => actions.endMove(),
        child: build(
          width: width,
          selected: selected,
          trim: selected
              ? actions.trimFor(id: id, edges: edgesOf, trim: trim)
              : null,
        ),
      ),
    );
  }
}

String _speedLabel(double speed) {
  final text = speed.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  return '${text}x';
}
