import 'package:stitch/features/timeline/domain/item_timing.dart';
import 'package:stitch/features/timeline/domain/layout.dart';
import 'package:stitch/features/timeline/domain/limits.dart';
import 'package:stitch/features/timeline/domain/models.dart';
import 'package:stitch/features/timeline/domain/normalize.dart';
import 'package:stitch/features/timeline/domain/video_ops.dart';

/// Text overlay edits.
extension TextOps on Timeline {
  TextItem? textById(String id) {
    for (final t in textItems) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Adds a text item at [atUs], on the lowest free lane.
  Timeline addText({
    required String id,
    required String text,
    required int atUs,
    int durationUs = TimelineLimits.textDurationUs,
    TextStyleSpec style = const TextStyleSpec(),
  }) {
    if (textById(id) != null) return this;
    final math = ItemTimingMath(TimelineLayout.of(this));
    final duration = durationUs < TimelineLimits.minDurationUs
        ? TimelineLimits.minDurationUs
        : durationUs;
    return normalize(
      copyWith(
        textItems: [
          ...textItems,
          TextItem(
            id: id,
            text: text,
            anchor: math.move((
              anchor: const Anchor.time(startUs: 0),
              durationUs: duration,
            ), atUs).anchor,
            durationUs: duration,
            style: style,
          ),
        ],
      ),
    );
  }

  /// Changes content, style, placement, or animation. Timing changes go
  /// through [moveText] and [trimText] so anchors stay consistent.
  Timeline updateText(String id, TextItem Function(TextItem) update) {
    final item = textById(id);
    if (item == null) return this;
    final updated = update(item).copyWith(
      id: item.id,
      anchor: item.anchor,
      durationUs: item.durationUs,
      laneIndex: item.laneIndex,
    );
    if (updated == item) return this;
    return _replaceText(id, (_) => updated);
  }

  /// Moves a text item to start at [toUs], optionally onto [lane]. Clears
  /// the review flag, since the user has placed it deliberately.
  Timeline moveText(String id, int toUs, {int? lane}) {
    final item = textById(id);
    if (item == null) return this;
    final timing = ItemTimingMath(TimelineLayout.of(this))
        .move((anchor: item.anchor, durationUs: item.durationUs), toUs);
    return normalize(
      _replaceText(
        id,
        (t) => t.copyWith(
          anchor: timing.anchor,
          laneIndex: lane ?? t.laneIndex,
          needsReview: false,
        ),
      ),
    );
  }

  Timeline trimText(String id, ClipEdge edge, int deltaUs) {
    final item = textById(id);
    if (item == null || deltaUs == 0) return this;
    final timing = ItemTimingMath(
      TimelineLayout.of(this),
    ).trim((anchor: item.anchor, durationUs: item.durationUs), edge, deltaUs);
    return normalize(
      _replaceText(
        id,
        (t) => t.copyWith(anchor: timing.anchor, durationUs: timing.durationUs),
      ),
    );
  }

  bool canSplitText(String id, int atUs) {
    final item = textById(id);
    return item != null &&
        ItemTimingMath(TimelineLayout.of(this))
            .canSplit((anchor: item.anchor, durationUs: item.durationUs), atUs);
  }

  Timeline splitText(String id, int atUs, {required String newId}) {
    if (!canSplitText(id, atUs) || textById(newId) != null) return this;
    final item = textById(id)!;
    final (first, second) = ItemTimingMath(TimelineLayout.of(this))
        .split((anchor: item.anchor, durationUs: item.durationUs), atUs);
    return normalize(
      copyWith(
        textItems: [
          for (final t in textItems)
            if (t.id == id) ...[
              t.copyWith(durationUs: first.durationUs),
              t.copyWith(
                id: newId,
                anchor: second.anchor,
                durationUs: second.durationUs,
              ),
            ] else
              t,
        ],
      ),
    );
  }

  /// Copies a text item to the same time; lane packing puts it on the next
  /// free lane.
  Timeline duplicateText(String id, {required String newId}) {
    final item = textById(id);
    if (item == null || textById(newId) != null) return this;
    return normalize(
      copyWith(
        textItems: [
          ...textItems,
          item.copyWith(id: newId),
        ],
      ),
    );
  }

  Timeline deleteText(String id) {
    if (textById(id) == null) return this;
    return copyWith(
      textItems: [
        for (final t in textItems)
          if (t.id != id) t,
      ],
    );
  }

  Timeline _replaceText(String id, TextItem Function(TextItem) update) =>
      copyWith(textItems: replaceById(textItems, id, (t) => t.id, update));
}
