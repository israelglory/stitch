import 'dart:math' as math;

import 'package:stitch/features/timeline/domain/layout.dart';
import 'package:stitch/features/timeline/domain/limits.dart';
import 'package:stitch/features/timeline/domain/models.dart';
import 'package:stitch/features/timeline/domain/normalize.dart';

/// Transition edits. A transition lives in the cut after a clip.
extension TransitionOps on Timeline {
  /// Longest transition allowed after [clipId]: half the shorter adjacent
  /// clip, and never more than the slider maximum. Zero when there is no
  /// next clip.
  int maxTransitionUs(String clipId) {
    final i = indexOfClip(clipId);
    if (i < 0 || i + 1 >= videoClips.length) return 0;
    return math.min(
      TimelineLimits.maxTransitionUs,
      transitionCapUs(videoClips[i], videoClips[i + 1]),
    );
  }

  bool canSetTransition(String clipId) => maxTransitionUs(clipId) > 0;

  /// Sets the transition after [clipId], or removes it when [type] is null.
  /// The duration defaults to the current one (or the default) and is
  /// clamped to the allowed range for this cut.
  Timeline setTransition(
    String clipId,
    TransitionType? type, {
    int? durationUs,
  }) {
    final existing = transitionAfter(clipId);
    if (type == null) {
      if (existing == null) return this;
      return copyWith(
        transitions: [
          for (final t in transitions)
            if (t.afterClipId != clipId) t,
        ],
      );
    }
    final max = maxTransitionUs(clipId);
    if (max <= 0) return this;
    final duration = clampInt(
      durationUs ?? existing?.durationUs ?? TimelineLimits.defaultTransitionUs,
      math.min(TimelineLimits.minTransitionUs, max),
      max,
    );
    final next = Transition(
      afterClipId: clipId,
      type: type,
      durationUs: duration,
      params: existing?.type == type ? existing!.params : const {},
    );
    if (next == existing) return this;
    return normalize(
      copyWith(
        transitions: [
          for (final t in transitions)
            if (t.afterClipId != clipId) t,
          next,
        ],
      ),
    );
  }

  /// Applies [type] with [durationUs] to every cut. Each cut clamps the
  /// duration to its own cap. A null [type] removes all transitions.
  Timeline applyTransitionToAll(TransitionType? type, {int? durationUs}) {
    var result = this;
    for (var i = 0; i + 1 < videoClips.length; i++) {
      result = result.setTransition(
        videoClips[i].id,
        type,
        durationUs: durationUs,
      );
    }
    return result;
  }
}
