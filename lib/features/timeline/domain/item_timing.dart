import 'dart:math' as math;

import 'package:stitch/features/timeline/domain/layout.dart';
import 'package:stitch/features/timeline/domain/limits.dart';
import 'package:stitch/features/timeline/domain/models.dart';
import 'package:stitch/features/timeline/domain/video_ops.dart';

/// Timing of an overlay item: where it starts and how long it lasts.
typedef ItemTiming = ({Anchor anchor, int durationUs});

/// Shared move, trim, and split math for text, caption, and audio items.
/// Items may not start before zero, and end no later than the video when
/// there is a video.
final class ItemTimingMath {
  const new(this.layout);

  final TimelineLayout layout;

  int get _videoEnd => layout.spans.isEmpty ? 1 << 50 : layout.durationUs;

  /// Start time for an item of [durationUs] dropped at [toUs]: clamped so
  /// it starts inside the video.
  int clampStart(int toUs, int durationUs) => clampInt(
    toUs,
    0,
    math.max(0, _videoEnd - math.min(durationUs, TimelineLimits.minDurationUs)),
  );

  ItemTiming move(ItemTiming item, int toUs) => (
    anchor: layout.anchorAt(clampStart(toUs, item.durationUs)),
    durationUs: item.durationUs,
  );

  ItemTiming trim(ItemTiming item, ClipEdge edge, int deltaUs) {
    final start = layout.startOf(item.anchor);
    final end = start + item.durationUs;
    switch (edge) {
      case ClipEdge.start:
        final newStart = clampInt(
          start + deltaUs,
          0,
          end - TimelineLimits.minDurationUs,
        );
        return (anchor: layout.anchorAt(newStart), durationUs: end - newStart);
      case ClipEdge.end:
        final newEnd = clampInt(
          end + deltaUs,
          start + TimelineLimits.minDurationUs,
          math.max(_videoEnd, end),
        );
        return (anchor: item.anchor, durationUs: newEnd - start);
    }
  }

  bool canSplit(ItemTiming item, int atUs) {
    final start = layout.startOf(item.anchor);
    return atUs - start >= TimelineLimits.minDurationUs &&
        start + item.durationUs - atUs >= TimelineLimits.minDurationUs;
  }

  /// The two halves of [item] split at [atUs]. Check [canSplit] first.
  (ItemTiming, ItemTiming) split(ItemTiming item, int atUs) {
    final start = layout.startOf(item.anchor);
    return (
      (anchor: item.anchor, durationUs: atUs - start),
      (
        anchor: layout.anchorAt(atUs),
        durationUs: start + item.durationUs - atUs,
      ),
    );
  }
}
