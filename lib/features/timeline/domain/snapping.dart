import 'package:stitch/core/time/time.dart';
import 'package:stitch/features/timeline/domain/layout.dart';
import 'package:stitch/features/timeline/domain/models.dart';
import 'package:stitch/features/timeline/domain/normalize.dart';

/// Horizontal zoom of the timeline.
final class TimelineScale {
  const new(this.pixelsPerSecond);

  static const double minPixelsPerSecond = 8;
  static const double maxPixelsPerSecond = 400;
  static const double defaultPixelsPerSecond = 64;

  final double pixelsPerSecond;

  double usToPx(int us) => us * pixelsPerSecond / usPerSecond;

  int pxToUs(double px) => (px * usPerSecond / pixelsPerSecond).round();

  /// This scale multiplied by [factor] (a pinch), within the zoom limits.
  TimelineScale zoomed(double factor) => TimelineScale(
    (pixelsPerSecond * factor).clamp(minPixelsPerSecond, maxPixelsPerSecond),
  );
}

/// Where a dragged time landed.
final class SnapResult {
  const new(this.timeUs, {this.snapped = false});

  final int timeUs;

  /// True when pulled onto a target; the UI plays a light haptic when
  /// this becomes true.
  final bool snapped;
}

/// Snaps [candidateUs] to the nearest of [targetsUs] within [thresholdPx]
/// on screen. The threshold is in pixels, not time, so snapping feels the
/// same at every zoom level.
SnapResult snap(
  int candidateUs,
  Iterable<int> targetsUs, {
  required TimelineScale scale,
  double thresholdPx = 8,
}) {
  final maxDistance = scale.pxToUs(thresholdPx);
  int? best;
  var bestDistance = maxDistance + 1;
  for (final target in targetsUs) {
    final distance = (target - candidateUs).abs();
    if (distance < bestDistance) {
      best = target;
      bestDistance = distance;
    }
  }
  return best == null
      ? SnapResult(candidateUs)
      : SnapResult(best, snapped: true);
}

/// Everything a drag can snap to: the playhead, the start and end of the
/// video, every cut, and the edges of every text, caption, and audio item
/// except those in [excludeIds] (the ones being dragged).
Set<int> snapTargets(
  Timeline timeline, {
  required int playheadUs,
  Set<String> excludeIds = const {},
}) {
  final layout = TimelineLayout.of(timeline);
  final targets = <int>{playheadUs, 0, layout.durationUs};
  for (final span in layout.spans) {
    if (excludeIds.contains(span.clip.id)) continue;
    targets
      ..add(span.startUs)
      ..add(span.endUs);
  }
  void addItem(String id, Anchor anchor, int endUs) {
    if (excludeIds.contains(id)) return;
    targets
      ..add(layout.startOf(anchor))
      ..add(endUs);
  }

  for (final t in timeline.textItems) {
    addItem(t.id, t.anchor, layout.startOf(t.anchor) + t.durationUs);
  }
  for (final s in timeline.captionTrack.segments) {
    addItem(s.id, s.anchor, layout.startOf(s.anchor) + s.durationUs);
  }
  for (final a in timeline.audioItems) {
    addItem(a.id, a.anchor, audioEndUs(a, layout));
  }
  return targets;
}
