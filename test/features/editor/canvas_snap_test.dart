import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/features/editor/domain/canvas_snap.dart';

void main() {
  const w = 360.0;
  const h = 640.0;

  group('boxes', () {
    test('a box near the middle snaps to it, with a centre line', () {
      final r = snapBox(
        (cx: 183, cy: 400, hw: 50, hh: 20),
        width: w,
        height: h,
      );
      expect(r.cx, 180);
      expect(r.cy, 400, reason: 'nothing near on y');
      expect(r.guides, [(vertical: true, at: 180.0, kind: GuideKind.center)]);
    });

    test('edges snap to the frame', () {
      final r = snapBox((cx: 54, cy: 616, hw: 50, hh: 20), width: w, height: h);
      expect(r.cx, 50);
      expect(r.cy, 620);
      expect(r.guides.map((g) => g.kind), [
        GuideKind.frameEdge,
        GuideKind.frameEdge,
      ]);
    });

    test('lines up with another item', () {
      const other = (cx: 120.0, cy: 300.0, hw: 60.0, hh: 15.0);
      // Top edge 3 px below the other's top edge (285).
      final r = snapBox(
        (cx: 250, cy: 308, hw: 40, hh: 20),
        width: w,
        height: h,
        others: [other],
      );
      expect(r.cy, 305, reason: 'top edges meet at 285');
      expect(r.guides.single, (
        vertical: false,
        at: 285.0,
        kind: GuideKind.item,
      ));
    });

    test('far from everything, nothing moves', () {
      final r = snapBox(
        (cx: 120, cy: 200, hw: 30, hh: 10),
        width: w,
        height: h,
      );
      expect((r.cx, r.cy), (120.0, 200.0));
      expect(r.guides, isEmpty);
    });

    test('a turned box takes more room', () {
      final e = turnedHalfExtents(100, 20, 90);
      expect(e.hw, closeTo(10, 1e-9));
      expect(e.hh, closeTo(50, 1e-9));
      final d = turnedHalfExtents(100, 100, 45);
      expect(d.hw, closeTo(70.71, 0.01));
    });
  });

  test('angles snap to quarter turns', () {
    expect(snapRotation(3.5), (degrees: 0.0, snapped: true));
    expect(snapRotation(-2), (degrees: 0.0, snapped: true));
    expect(snapRotation(87), (degrees: 90.0, snapped: true));
    expect(snapRotation(12), (degrees: 12.0, snapped: false));
    expect(displayAngle(350), -10);
    expect(displayAngle(-190), 170);
  });

  test('scale snaps to the original size', () {
    expect(snapScale(1.02), (scale: 1.0, snapped: true));
    expect(snapScale(1.2), (scale: 1.2, snapped: false));
  });
}
