import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/features/text/domain/text_motion.dart';
import 'package:stitch/features/timeline/domain/models.dart';

void main() {
  TextMotion at(
    int tUs, {
    TextAnimation animIn = TextAnimation.none,
    TextAnimation animOut = TextAnimation.none,
    int durationUs = 3000000,
  }) => textMotionAt(
    animationIn: animIn,
    inUs: textAnimationUs(animIn, durationUs),
    animationOut: animOut,
    outUs: textAnimationUs(animOut, durationUs),
    durationUs: durationUs,
    tUs: tUs,
  );

  test('animation lengths: 0.4 s, a third of short items; typewriter 1 s', () {
    expect(textAnimationUs(TextAnimation.none, 3000000), 0);
    expect(textAnimationUs(TextAnimation.fade, 3000000), 400000);
    expect(textAnimationUs(TextAnimation.fade, 600000), 200000);
    expect(textAnimationUs(TextAnimation.typewriter, 3000000), 1000000);
    expect(textAnimationUs(TextAnimation.typewriter, 1000000), 500000);
  });

  test('without animations, text is fully shown throughout', () {
    for (final t in [0, 1500000, 2999999]) {
      final m = at(t);
      expect((m.alpha, m.dy, m.scale, m.reveal), (1.0, 0.0, 1.0, 1.0));
    }
  });

  test('fade in starts hidden, eases out, and is done after 0.4 s', () {
    expect(at(0, animIn: TextAnimation.fade).alpha, 0);
    // Ease out: past the linear midpoint halfway through.
    expect(at(200000, animIn: TextAnimation.fade).alpha, closeTo(0.875, 1e-9));
    expect(at(400000, animIn: TextAnimation.fade).alpha, 1);
  });

  test('fade out ends hidden', () {
    expect(at(3000000, animOut: TextAnimation.fade).alpha, 0);
    expect(at(2600000, animOut: TextAnimation.fade).alpha, 1);
  });

  test('slide up rises into place and rises away', () {
    expect(at(0, animIn: TextAnimation.slideUp).dy, textSlideDistance);
    expect(at(3000000, animOut: TextAnimation.slideUp).dy, -textSlideDistance);
    expect(at(0, animIn: TextAnimation.slideDown).dy, -textSlideDistance);
    expect(at(3000000, animOut: TextAnimation.slideDown).dy, textSlideDistance);
  });

  test('scale grows from 60 percent', () {
    expect(at(0, animIn: TextAnimation.scale).scale, textScaleFrom);
    expect(at(400000, animIn: TextAnimation.scale).scale, 1);
  });

  test('typewriter reveals at an even pace, and un-types at the end', () {
    expect(at(500000, animIn: TextAnimation.typewriter).reveal, 0.5);
    expect(at(1000000, animIn: TextAnimation.typewriter).reveal, 1);
    expect(at(2500000, animOut: TextAnimation.typewriter).reveal, 0.5);
    expect(at(500000, animIn: TextAnimation.typewriter).alpha, 1);
  });

  test('in and out combine', () {
    final m = at(
      100000,
      animIn: TextAnimation.fade,
      animOut: TextAnimation.fade,
      durationUs: 300000,
    );
    // 0.1 s into a 0.1 s fade in, 0.2 s from the end of a 0.1 s fade out.
    expect(m.alpha, 1);
  });
}
