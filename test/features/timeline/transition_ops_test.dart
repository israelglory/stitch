import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/features/timeline/domain/models.dart';
import 'package:stitch/features/timeline/domain/transition_ops.dart';
import 'package:stitch/features/timeline/domain/video_ops.dart';

import 'fixtures.dart';

void main() {
  test('sets a transition with the default duration', () {
    final t = track([2, 2]).setTransition('a', TransitionType.crossfade);
    expect(t.transitions.single.durationUs, s(0.5));
    expect(t.durationUs, s(3.5));
  });

  test('changing type keeps the duration', () {
    final t = track([4, 4])
        .setTransition('a', TransitionType.crossfade, durationUs: s(1.2))
        .setTransition('a', TransitionType.slideLeft);
    expect(t.transitions.single.type, TransitionType.slideLeft);
    expect(t.transitions.single.durationUs, s(1.2));
  });

  test('null removes the transition', () {
    final t = track([2, 2])
        .setTransition('a', TransitionType.crossfade)
        .setTransition('a', null);
    expect(t.transitions, isEmpty);
    expect(t.durationUs, s(4));
  });

  test('duration is clamped to 0.2 to 1.5 seconds', () {
    final t = track([10, 10]);
    expect(
      t
          .setTransition('a', TransitionType.crossfade, durationUs: s(5))
          .transitions
          .single
          .durationUs,
      s(1.5),
    );
    expect(
      t
          .setTransition('a', TransitionType.crossfade, durationUs: s(0.01))
          .transitions
          .single
          .durationUs,
      s(0.2),
    );
  });

  test('duration is capped at half the shorter clip', () {
    final t = track([0.8, 10]);
    expect(t.maxTransitionUs('a'), s(0.4));
    expect(
      t
          .setTransition('a', TransitionType.crossfade, durationUs: s(1))
          .transitions
          .single
          .durationUs,
      s(0.4),
    );
  });

  test('a cap below the slider minimum still allows a short transition', () {
    final t = track([0.2, 10]).setTransition('a', TransitionType.crossfade);
    expect(t.transitions.single.durationUs, s(0.1));
  });

  test('the last clip has no cut after it', () {
    final t = track([2, 2]);
    expect(t.canSetTransition('b'), isFalse);
    expect(
      identical(t.setTransition('b', TransitionType.crossfade), t),
      isTrue,
    );
  });

  test('trimming a clip re-applies the cap', () {
    final t = track([4, 4])
        .setTransition('a', TransitionType.crossfade, durationUs: s(1.5))
        .trimClip('b', ClipEdge.end, -s(3));
    expect(t.transitions.single.durationUs, s(0.5));
  });

  test('apply to all sets every cut, each within its own cap', () {
    final t = track([4, 0.6, 4, 4])
        .applyTransitionToAll(TransitionType.fadeToBlack, durationUs: s(1));
    expect(t.transitions, hasLength(3));
    final byClip = {for (final x in t.transitions) x.afterClipId: x.durationUs};
    expect(byClip['a'], s(0.3));
    expect(byClip['b'], s(0.3));
    expect(byClip['c'], s(1));
    expect(
      t.transitions.every((x) => x.type == TransitionType.fadeToBlack),
      isTrue,
    );
  });

  test('apply none to all removes every transition', () {
    final t = track([2, 2, 2])
        .applyTransitionToAll(TransitionType.crossfade)
        .applyTransitionToAll(null);
    expect(t.transitions, isEmpty);
  });
}
