import 'dart:math' as math;

import 'package:stitch/features/timeline/domain/models.dart';

/// How long an in or out [animation] runs on an item [durationUs] long.
/// Most take up to 0.4 s, and never more than a third of the item; a
/// typewriter takes up to 1 s, at most half the item.
int textAnimationUs(TextAnimation animation, int durationUs) =>
    switch (animation) {
      TextAnimation.none => 0,
      TextAnimation.typewriter => math.min(1000000, durationUs ~/ 2),
      _ => math.min(400000, durationUs ~/ 3),
    };

/// A text item's look at one moment of its entrance or exit.
final class TextMotion {
  const new({this.alpha = 1, this.dy = 0, this.scale = 1, this.reveal = 1});

  /// Opacity, 0 to 1.
  final double alpha;

  /// Vertical offset as a fraction of the canvas height, down.
  final double dy;

  /// Multiplies the item's own scale.
  final double scale;

  /// Fraction of the text shown by a typewriter, 0 to 1.
  final double reveal;

  static const shown = TextMotion();
}

/// The motion at [tUs] into an item [durationUs] long that enters with
/// [animationIn] over [inUs] and leaves with [animationOut] over [outUs].
///
/// Each animation is driven by its phase: 0 hidden, 1 fully shown. The
/// entrance phase rises over the first [inUs]; the exit phase falls over
/// the last [outUs]. Mirrored by the engines (TextMotion.swift and
/// TextMotion.kt); docs/engine.md defines the looks.
TextMotion textMotionAt({
  required TextAnimation animationIn,
  required int inUs,
  required TextAnimation animationOut,
  required int outUs,
  required int durationUs,
  required int tUs,
}) {
  double phase(int spanUs, int intoUs) =>
      spanUs <= 0 ? 1 : (intoUs / spanUs).clamp(0.0, 1.0);
  final a = _apply(animationIn, phase(inUs, tUs), entering: true);
  final b = _apply(
    animationOut,
    phase(outUs, durationUs - tUs),
    entering: false,
  );
  return TextMotion(
    alpha: a.alpha * b.alpha,
    dy: a.dy + b.dy,
    scale: a.scale * b.scale,
    reveal: math.min(a.reveal, b.reveal),
  );
}

/// Distance a slide travels, as a fraction of the canvas height.
const textSlideDistance = 0.05;

/// Smallest size a scale animation starts or ends at.
const textScaleFrom = 0.6;

TextMotion _apply(
  TextAnimation animation,
  double phase, {
  required bool entering,
}) {
  // Ease out: fast from the edge, gentle into place (and the mirror when
  // leaving, since the exit phase runs backwards).
  final e = 1 - math.pow(1 - phase, 3).toDouble();
  return switch (animation) {
    TextAnimation.none => TextMotion.shown,
    TextAnimation.fade => TextMotion(alpha: e),
    // Slide up: rises into place, and rises away.
    TextAnimation.slideUp => TextMotion(
      alpha: e,
      dy: (1 - e) * textSlideDistance * (entering ? 1 : -1),
    ),
    // Slide down: drops into place, and drops away.
    TextAnimation.slideDown => TextMotion(
      alpha: e,
      dy: (1 - e) * textSlideDistance * (entering ? -1 : 1),
    ),
    TextAnimation.scale => TextMotion(
      alpha: e,
      scale: textScaleFrom + (1 - textScaleFrom) * e,
    ),
    // Letters appear at an even pace.
    TextAnimation.typewriter => TextMotion(reveal: phase),
  };
}
