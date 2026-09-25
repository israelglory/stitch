import 'dart:math' as math;

import 'package:stitch/features/timeline/domain/limits.dart';
import 'package:stitch/features/timeline/domain/models.dart';

/// Where a clip sits on the timeline.
final class ClipSpan {
  const new({required this.clip, required this.index, required this.startUs});

  final VideoClip clip;
  final int index;
  final int startUs;

  int get endUs => startUs + clip.durationUs;
}

/// A resolved anchor: the item's start time, and whether the anchored
/// moment is still inside its clip (false when trimmed away; the item then
/// keeps its distance to where that moment would be).
final class AnchorPosition {
  const new(this.startUs, {this.inRange = true});

  final int startUs;
  final bool inRange;
}

/// Computed placement of the main track. Build one per timeline snapshot
/// with [TimelineLayout.of]; it is cheap for realistic clip counts.
///
/// Transitions overlap the clips around them: a clip after a transition of
/// length d starts d before the previous clip ends.
final class TimelineLayout {
  const new _(this.spans, this.durationUs, this._byId, this._transitionUs);

  factory of(Timeline timeline) {
    final clips = timeline.videoClips;
    final spans = <ClipSpan>[];
    final byId = <String, ClipSpan>{};
    final transitionUs = <String, int>{};
    var start = 0;
    for (var i = 0; i < clips.length; i++) {
      final clip = clips[i];
      final span = ClipSpan(clip: clip, index: i, startUs: start);
      spans.add(span);
      byId[clip.id] = span;
      var overlap = 0;
      if (i + 1 < clips.length) {
        final t = timeline.transitionAfter(clip.id);
        if (t != null) {
          overlap = math.min(t.durationUs, transitionCapUs(clip, clips[i + 1]));
          transitionUs[clip.id] = overlap;
        }
      }
      start = span.endUs - overlap;
    }
    final duration = spans.isEmpty ? 0 : spans.last.endUs;
    return TimelineLayout._(spans, duration, byId, transitionUs);
  }

  final List<ClipSpan> spans;

  /// Total length of the video.
  final int durationUs;
  final Map<String, ClipSpan> _byId;
  final Map<String, int> _transitionUs;

  ClipSpan? span(String clipId) => _byId[clipId];

  /// Effective length of the transition after [clipId], after the cap.
  /// Zero for a hard cut.
  int transitionUs(String clipId) => _transitionUs[clipId] ?? 0;

  /// The clip showing at [timeUs]. Inside a transition this is the incoming
  /// clip. Times outside the video clamp to the first or last clip.
  ClipSpan? spanAt(int timeUs) {
    if (spans.isEmpty) return null;
    for (var i = spans.length - 1; i >= 0; i--) {
      if (spans[i].startUs <= timeUs) return spans[i];
    }
    return spans.first;
  }

  /// Where [anchor] would be without the timeline start bounding it:
  /// negative for a moment trimmed off the front of the first clip.
  int unboundedStartOf(Anchor anchor) => switch (anchor) {
    TimeAnchor(:final startUs) => startUs,
    ClipAnchor(:final clipId, :final sourceUs) => switch (_byId[clipId]) {
      null => 0,
      final span =>
        span.startUs +
            sourceToTimelineUs(
              sourceUs - span.clip.sourceInUs,
              span.clip.speed,
            ),
    },
  };

  /// Timeline position of [anchor].
  AnchorPosition resolve(Anchor anchor) {
    switch (anchor) {
      case TimeAnchor(:final startUs):
        return AnchorPosition(startUs);
      case ClipAnchor(:final clipId, :final sourceUs):
        final span = _byId[clipId];
        // A dangling anchor only exists transiently inside an edit.
        if (span == null) return const AnchorPosition(0, inRange: false);
        final clip = span.clip;
        final inRange =
            sourceUs >= clip.sourceInUs && sourceUs <= clip.sourceOutUs;
        // Not clamped to the clip: an item whose moment was trimmed away
        // keeps its distance to the content, which keeps extracted audio
        // in sync with the picture. Only the timeline start bounds it.
        final offset = sourceUs - clip.sourceInUs;
        return AnchorPosition(
          math.max(0, span.startUs + sourceToTimelineUs(offset, clip.speed)),
          inRange: inRange,
        );
    }
  }

  /// Start time of [anchor].
  int startOf(Anchor anchor) => resolve(anchor).startUs;

  /// Anchor for an item placed at [timeUs]: the content moment under that
  /// time, or an absolute time when there are no clips.
  Anchor anchorAt(int timeUs) {
    final t = math.max(0, timeUs);
    final span = spanAt(t);
    if (span == null) return Anchor.time(startUs: t);
    final clip = span.clip;
    final offset = timelineToSourceUs(
      clampInt(t - span.startUs, 0, clip.durationUs),
      clip.speed,
    );
    return Anchor.clip(
      clipId: clip.id,
      sourceUs: math.min(clip.sourceInUs + offset, clip.sourceOutUs),
    );
  }
}

/// Longest transition allowed between [a] and [b]: half the shorter clip.
int transitionCapUs(VideoClip a, VideoClip b) =>
    math.min(a.durationUs, b.durationUs) ~/ 2;

/// Places items on lanes so none overlap. Each item keeps its preferred
/// lane unless an earlier item already occupies it at that time, in which
/// case it moves to the next free lane. Returns the lane for each input,
/// in input order.
List<int> packLanes(List<({int startUs, int endUs, int lane})> items) {
  final order = List<int>.generate(items.length, (i) => i)
    ..sort((a, b) {
      final byStart = items[a].startUs.compareTo(items[b].startUs);
      if (byStart != 0) return byStart;
      final byLane = items[a].lane.compareTo(items[b].lane);
      return byLane != 0 ? byLane : a.compareTo(b);
    });

  final placed = <int, List<(int, int)>>{};
  final result = List<int>.filled(items.length, 0);
  for (final i in order) {
    final item = items[i];
    var lane = math.max(0, item.lane);
    while ((placed[lane] ?? const []).any(
      (p) => item.startUs < p.$2 && p.$1 < item.endUs,
    )) {
      lane++;
    }
    (placed[lane] ??= []).add((item.startUs, item.endUs));
    result[i] = lane;
  }
  return result;
}
