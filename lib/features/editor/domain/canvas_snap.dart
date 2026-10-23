import 'dart:math' as math;

// Snapping for things moved on the preview (text, a clip in its frame):
// to the frame's centre and edges, to other items' edges and centres, to
// level angles, and to a clip's own size. Everything is in preview
// pixels. Each axis snaps to its nearest target within the threshold, so
// a snap is easy to drag past.

/// An item's bounds on the preview: the centre, and half the width and
/// height of the upright box around it (turned items take more room).
typedef SnapBox = ({double cx, double cy, double hw, double hh});

/// What a guide line marks.
enum GuideKind {
  /// The frame's centre line.
  center,

  /// An edge of the frame.
  frameEdge,

  /// An edge or the centre of another item.
  item,
}

/// A guide line: vertical at x = `at`, or horizontal at y = `at`.
typedef Guide = ({bool vertical, double at, GuideKind kind});

/// A box moved to the targets it snaps to, and the guides to show.
typedef SnapResult = ({double cx, double cy, List<Guide> guides});

/// Half the width and height of the upright box around a [width] x
/// [height] box turned [degrees].
({double hw, double hh}) turnedHalfExtents(
  double width,
  double height,
  double degrees,
) {
  final a = degrees * math.pi / 180;
  final c = math.cos(a).abs();
  final s = math.sin(a).abs();
  return (hw: (width * c + height * s) / 2, hh: (width * s + height * c) / 2);
}

/// Snaps [box] on a [width] x [height] preview: its centre to the frame's
/// centre, its edges to the frame's edges, and its edges and centre to
/// those of [others]. Within [threshold] pixels on each axis.
SnapResult snapBox(
  SnapBox box, {
  required double width,
  required double height,
  List<SnapBox> others = const [],
  double threshold = 6,
}) {
  final x = _snapAxis(
    box.cx,
    box.hw,
    size: width,
    others: [for (final o in others) (o.cx, o.hw)],
    threshold: threshold,
  );
  final y = _snapAxis(
    box.cy,
    box.hh,
    size: height,
    others: [for (final o in others) (o.cy, o.hh)],
    threshold: threshold,
  );
  return (
    cx: x.center,
    cy: y.center,
    guides: [
      if (x.guide case (final at, final kind))
        (vertical: true, at: at, kind: kind),
      if (y.guide case (final at, final kind))
        (vertical: false, at: at, kind: kind),
    ],
  );
}

({double center, (double, GuideKind)? guide}) _snapAxis(
  double center,
  double half, {
  required double size,
  required List<(double, double)> others,
  required double threshold,
}) {
  // (where a point of the box must go, offset of that point from the
  // centre, what it lines up with)
  final targets = <(double, double, GuideKind)>[
    (size / 2, 0, GuideKind.center),
    (0, -half, GuideKind.frameEdge),
    (size, half, GuideKind.frameEdge),
    for (final (oc, oh) in others)
      for (final at in [oc - oh, oc, oc + oh])
        for (final offset in [-half, 0.0, half]) (at, offset, GuideKind.item),
  ];
  (double, GuideKind)? best;
  var bestDistance = threshold;
  var snapped = center;
  for (final (at, offset, kind) in targets) {
    final distance = (center + offset - at).abs();
    // Ties go to the earlier target: the centre, then the frame.
    if (distance <= bestDistance && (best == null || distance < bestDistance)) {
      bestDistance = distance;
      best = (at, kind);
      snapped = at - offset;
    }
  }
  return (center: snapped, guide: best);
}

/// [degrees] snapped to the nearest quarter turn (0, 90, 180, 270)
/// within [threshold] degrees.
({double degrees, bool snapped}) snapRotation(
  double degrees, {
  double threshold = 4,
}) {
  final quarter = (degrees / 90).roundToDouble() * 90;
  return (degrees - quarter).abs() <= threshold
      ? (degrees: quarter, snapped: true)
      : (degrees: degrees, snapped: false);
}

/// [scale] snapped to [target] when within [threshold] of it (relative).
({double scale, bool snapped}) snapScale(
  double scale, {
  double target = 1,
  double threshold = 0.03,
}) => (scale / target - 1).abs() <= threshold
    ? (scale: target, snapped: true)
    : (scale: scale, snapped: false);

/// Size of a [mediaWidth] x [mediaHeight] picture fitted into ([fill]:
/// filling) a [width] x [height] frame, before its zoom: how clips and
/// overlays are placed. A picture of unknown size takes the frame's.
({double width, double height}) framedSize(
  double width,
  double height,
  double mediaWidth,
  double mediaHeight, {
  bool fill = false,
}) {
  final mw = mediaWidth > 0 ? mediaWidth : width;
  final mh = mediaHeight > 0 ? mediaHeight : height;
  final scale = fill
      ? math.max(width / mw, height / mh)
      : math.min(width / mw, height / mh);
  return (width: mw * scale, height: mh * scale);
}

/// [degrees] as shown while turning: -180 to 180, whole degrees.
int displayAngle(double degrees) {
  var a = degrees % 360;
  if (a > 180) a -= 360;
  return a.round();
}
