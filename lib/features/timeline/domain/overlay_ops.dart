import 'dart:math' as math;

import 'package:stitch/features/timeline/domain/item_timing.dart';
import 'package:stitch/features/timeline/domain/keyframes.dart';
import 'package:stitch/features/timeline/domain/layout.dart';
import 'package:stitch/features/timeline/domain/limits.dart';
import 'package:stitch/features/timeline/domain/models.dart';
import 'package:stitch/features/timeline/domain/normalize.dart';
import 'package:stitch/features/timeline/domain/video_ops.dart';

/// A file to add as an overlay: its media and (for videos) length.
typedef OverlaySource = ({
  String id,
  String mediaId,
  MediaKind kind,
  int? mediaDurationUs,
});

/// Zoom of a new overlay: smaller than the frame, so it reads as a
/// picture in the picture.
const double newOverlayScale = 0.6;

/// Whether [overlay] shows at timeline time [atUs]: from its start, up to
/// (not at) its end or the end of the video, as the engines draw it.
bool overlayShowsAt(OverlayClip overlay, int atUs, TimelineLayout layout) {
  final start = layout.startOf(overlay.anchor);
  final end = math.min(start + overlay.durationUs, layout.durationUs);
  return atUs >= start && atUs < end;
}

/// Overlay edits: videos and photos over the main track.
extension OverlayOps on Timeline {
  /// Adds [sources] one after another from [atUs], on the lowest lane
  /// free for all of them. Photos last the photo default.
  Timeline addOverlays(List<OverlaySource> sources, {required int atUs}) {
    final fresh = [
      for (final s in sources)
        if (overlayById(s.id) == null &&
            (s.kind == MediaKind.photo || (s.mediaDurationUs ?? 0) > 0))
          s,
    ];
    if (fresh.isEmpty) return this;
    final layout = TimelineLayout.of(this);
    final lengths = [
      for (final s in fresh)
        s.kind == MediaKind.photo
            ? TimelineLimits.photoDurationUs
            : s.mediaDurationUs!,
    ];
    final start = ItemTimingMath(layout).clampStart(atUs, lengths.first);
    final end = start + lengths.fold<int>(0, (a, b) => a + b);
    final lane = _freeLane(layout, start, end);
    var at = start;
    final added = <OverlayClip>[];
    for (final (i, s) in fresh.indexed) {
      added.add(
        OverlayClip(
          id: s.id,
          mediaId: s.mediaId,
          kind: s.kind,
          anchor: layout.anchorAt(at),
          mediaDurationUs: s.kind == MediaKind.photo ? null : s.mediaDurationUs,
          sourceInUs: 0,
          sourceOutUs: lengths[i],
          laneIndex: lane,
          framing: const ClipFraming(scale: newOverlayScale),
        ),
      );
      at += lengths[i];
    }
    return normalize(copyWith(overlayClips: [...overlayClips, ...added]));
  }

  /// The lowest lane with nothing between [startUs] and [endUs].
  int _freeLane(TimelineLayout layout, int startUs, int endUs) {
    for (var lane = 0; ; lane++) {
      final taken = overlayClips.any((o) {
        if (o.laneIndex != lane) return false;
        final s = layout.startOf(o.anchor);
        return startUs < s + o.durationUs && s < endUs;
      });
      if (!taken) return lane;
    }
  }

  /// Moves an overlay to start at [toUs]. If its lane is taken there, it
  /// goes up to the next free one.
  Timeline moveOverlay(String id, int toUs) {
    final item = overlayById(id);
    if (item == null) return this;
    final timing = ItemTimingMath(TimelineLayout.of(this))
        .move((anchor: item.anchor, durationUs: item.durationUs), toUs);
    if (timing.anchor == item.anchor) return this;
    return normalize(
      _replace(
        id,
        (o) => o.copyWith(anchor: timing.anchor, needsReview: false),
      ),
    );
  }

  /// Moves an edge by [deltaUs] of timeline time, trimming the source.
  /// Photos have no natural end. The end stays within the video (or
  /// where it already was past it).
  Timeline trimOverlay(String id, ClipEdge edge, int deltaUs) {
    final item = overlayById(id);
    if (item == null || deltaUs == 0) return this;
    final layout = TimelineLayout.of(this);
    final start = layout.startOf(item.anchor);
    final minSource = timelineToSourceUs(
      TimelineLimits.minDurationUs,
      item.speed,
    );
    final sourceDelta = timelineToSourceUs(deltaUs, item.speed);
    final OverlayClip trimmed;
    switch (edge) {
      case ClipEdge.start:
        // Cannot start before zero on the timeline, or before the file.
        final minIn = item.sourceInUs - timelineToSourceUs(start, item.speed);
        final sourceIn = clampInt(
          item.sourceInUs + sourceDelta,
          math.max(0, minIn),
          item.sourceOutUs - minSource,
        );
        final moved = sourceToTimelineUs(
          sourceIn - item.sourceInUs,
          item.speed,
        );
        trimmed = item.copyWith(
          sourceInUs: sourceIn,
          anchor: layout.anchorAt(start + moved),
        );
      case ClipEdge.end:
        final end = start + item.durationUs;
        final videoEnd = layout.spans.isEmpty ? end : layout.durationUs;
        final maxEnd = math.max(videoEnd, end);
        final maxOut = math.min(
          item.mediaDurationUs ?? (1 << 50),
          item.sourceInUs + timelineToSourceUs(maxEnd - start, item.speed),
        );
        trimmed = item.copyWith(
          sourceOutUs: clampInt(
            item.sourceOutUs + sourceDelta,
            item.sourceInUs + minSource,
            maxOut,
          ),
        );
    }
    if (trimmed == item) return this;
    return normalize(_replace(id, (_) => trimmed));
  }

  bool canSplitOverlay(String id, int atUs) {
    final item = overlayById(id);
    if (item == null) return false;
    return ItemTimingMath(TimelineLayout.of(this))
        .canSplit((anchor: item.anchor, durationUs: item.durationUs), atUs);
  }

  /// Splits at [atUs]; the second part gets [newId].
  Timeline splitOverlay(String id, int atUs, {required String newId}) {
    if (!canSplitOverlay(id, atUs) || overlayById(newId) != null) return this;
    final layout = TimelineLayout.of(this);
    final item = overlayById(id)!;
    final start = layout.startOf(item.anchor);
    final splitSource =
        item.sourceInUs + timelineToSourceUs(atUs - start, item.speed);
    final first = item.copyWith(
      sourceOutUs: splitSource,
      keyframes: item.keyframes.within(item.sourceInUs, splitSource),
    );
    final second = item.copyWith(
      id: newId,
      sourceInUs: splitSource,
      anchor: layout.anchorAt(atUs),
      keyframes: item.keyframes.within(splitSource, item.sourceOutUs),
    );
    return normalize(
      copyWith(
        overlayClips: [
          for (final o in overlayClips)
            if (o.id == id) ...[first, second] else o,
        ],
      ),
    );
  }

  /// A copy right after the original, on its lane when that is free.
  Timeline duplicateOverlay(String id, {required String newId}) {
    final item = overlayById(id);
    if (item == null || overlayById(newId) != null) return this;
    final layout = TimelineLayout.of(this);
    final end = layout.startOf(item.anchor) + item.durationUs;
    final copy = item.copyWith(
      id: newId,
      anchor: layout.anchorAt(end),
      needsReview: false,
    );
    return normalize(copyWith(overlayClips: [...overlayClips, copy]));
  }

  Timeline deleteOverlay(String id) {
    if (overlayById(id) == null) return this;
    return copyWith(
      overlayClips: [
        for (final o in overlayClips)
          if (o.id != id) o,
      ],
    );
  }

  Timeline setOverlayVolume(String id, double volume) {
    final item = overlayById(id);
    if (item == null) return this;
    final v = clampDouble(
      volume,
      TimelineLimits.minVolume,
      TimelineLimits.maxVolume,
    );
    return v == item.volume ? this : _replace(id, (o) => o.copyWith(volume: v));
  }

  /// Sets speed (pitch is kept), clamped so the overlay stays at least
  /// the minimum length.
  Timeline setOverlaySpeed(String id, double speed) {
    final item = overlayById(id);
    if (item == null) return this;
    final maxForLength = item.sourceDurationUs / TimelineLimits.minDurationUs;
    final s = clampDouble(
      speed,
      TimelineLimits.minSpeed,
      math.min(TimelineLimits.maxSpeed, maxForLength),
    );
    if (s == item.speed) return this;
    return normalize(_replace(id, (o) => o.copyWith(speed: s)));
  }

  Timeline _replace(String id, OverlayClip Function(OverlayClip) update) =>
      copyWith(
        overlayClips: replaceById(overlayClips, id, (o) => o.id, update),
      );
}
