import 'dart:math' as math;

import 'package:stitch/features/timeline/domain/layout.dart';
import 'package:stitch/features/timeline/domain/models.dart';

/// Restores the timeline invariants after an edit:
///
/// - each transition follows an existing clip that has a next clip, one
///   per cut, with its duration within the cap;
/// - items are anchored to clip content whenever there are clips;
/// - text items and audio items on the same lane do not overlap.
///
/// Every operation ends with this, so individual operations only need to
/// get their own change right.
Timeline normalize(Timeline timeline) {
  final clips = timeline.videoClips;
  final nextOf = <String, VideoClip>{
    for (var i = 0; i + 1 < clips.length; i++) clips[i].id: clips[i + 1],
  };
  final seen = <String>{};
  final transitions = <Transition>[];
  for (final t in timeline.transitions) {
    final next = nextOf[t.afterClipId];
    if (next == null || !seen.add(t.afterClipId)) continue;
    final cap = transitionCapUs(timeline.clipById(t.afterClipId)!, next);
    if (cap <= 0) continue;
    transitions.add(t.durationUs > cap ? t.copyWith(durationUs: cap) : t);
  }

  var result = timeline.copyWith(transitions: transitions);
  final layout = TimelineLayout.of(result);

  // Items fall back to absolute times only while there are no clips. Once
  // clips exist again, anchor them to the content under them.
  if (layout.spans.isNotEmpty) {
    result = mapAnchors(
      result,
      (a) => a is TimeAnchor ? layout.anchorAt(a.startUs) : a,
    );
  }

  final textLanes = packLanes([
    for (final item in result.textItems)
      (
        startUs: layout.startOf(item.anchor),
        endUs: layout.startOf(item.anchor) + item.durationUs,
        lane: item.laneIndex,
      ),
  ]);
  final audioLanes = packLanes([
    for (final item in result.audioItems)
      (
        startUs: layout.startOf(item.anchor),
        endUs: audioEndUs(item, layout),
        lane: item.laneIndex,
      ),
  ]);

  return result.copyWith(
    textItems: [
      for (final (i, item) in result.textItems.indexed)
        item.laneIndex == textLanes[i]
            ? item
            : item.copyWith(laneIndex: textLanes[i]),
    ],
    audioItems: [
      for (final (i, item) in result.audioItems.indexed)
        item.laneIndex == audioLanes[i]
            ? item
            : item.copyWith(laneIndex: audioLanes[i]),
    ],
  );
}

/// End of an audio item on the timeline. Looping items run to the end of
/// the video (and at least one pass, so they stay visible when the video
/// is shorter).
int audioEndUs(AudioItem item, TimelineLayout layout) {
  final start = layout.startOf(item.anchor);
  final onePass = start + item.durationUs;
  return item.loop ? math.max(onePass, layout.durationUs) : onePass;
}

/// Re-anchors items whose anchor clip [clipId] is being removed. Each item
/// stays at the time it had in [before] (clamped to the new length), is
/// anchored to whatever is there afterwards, and is flagged for review.
Timeline reanchorOrphans(
  Timeline timeline, {
  required String clipId,
  required TimelineLayout before,
}) {
  final after = TimelineLayout.of(timeline);
  bool orphan(Anchor a) => a is ClipAnchor && a.clipId == clipId;
  Anchor moved(Anchor a) {
    final t = before.startOf(a);
    return after.anchorAt(
      after.durationUs == 0 ? t : math.min(t, after.durationUs),
    );
  }

  return timeline.copyWith(
    textItems: [
      for (final item in timeline.textItems)
        orphan(item.anchor)
            ? item.copyWith(anchor: moved(item.anchor), needsReview: true)
            : item,
    ],
    captionTrack: timeline.captionTrack.copyWith(
      segments: [
        for (final s in timeline.captionTrack.segments)
          orphan(s.anchor)
              ? s.copyWith(anchor: moved(s.anchor), needsReview: true)
              : s,
      ],
    ),
    audioItems: [
      for (final item in timeline.audioItems)
        orphan(item.anchor)
            ? item.copyWith(anchor: moved(item.anchor), needsReview: true)
            : item,
    ],
  );
}

/// Applies [map] to every anchor in the timeline.
Timeline mapAnchors(Timeline timeline, Anchor Function(Anchor) map) =>
    timeline.copyWith(
      textItems: [
        for (final item in timeline.textItems)
          item.copyWith(anchor: map(item.anchor)),
      ],
      captionTrack: timeline.captionTrack.copyWith(
        segments: [
          for (final s in timeline.captionTrack.segments)
            s.copyWith(anchor: map(s.anchor)),
        ],
      ),
      audioItems: [
        for (final item in timeline.audioItems)
          item.copyWith(anchor: map(item.anchor)),
      ],
    );

/// Replaces the element with [id] in [items] using [update].
List<T> replaceById<T>(
  List<T> items,
  String id,
  String Function(T) idOf,
  T Function(T) update,
) => [for (final item in items) idOf(item) == id ? update(item) : item];
