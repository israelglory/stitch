import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/features/timeline/domain/keyframes.dart';
import 'package:stitch/features/timeline/domain/limits.dart';
import 'package:stitch/features/timeline/domain/models.dart';
import 'package:stitch/features/timeline/domain/text_ops.dart';
import 'package:stitch/features/timeline/domain/video_ops.dart';

import 'fixtures.dart';

void main() {
  Timeline freeze(Timeline t, String clipId, int atUs) =>
      t.freezeClip(clipId, atUs, stillId: 'f', splitId: 'b2', mediaId: 'still');

  test('splits the clip and holds the frame between the parts', () {
    final t = freeze(track([4, 3]), 'a', s(1.5));
    expect(t.videoClips.map((c) => c.id), ['a', 'f', 'b2', 'b']);
    final still = t.clipById('f')!;
    expect(still.isPhoto, isTrue);
    expect(still.mediaId, 'still');
    expect(still.durationUs, TimelineLimits.photoDurationUs);
    expect(t.startOfClip('f'), s(1.5));
    // The rest plays on after it.
    expect(t.startOfClip('b2'), s(4.5));
    expect(t.clipById('b2')!.sourceInUs, s(1.5));
    expect(t.durationUs, s(10));
  });

  test('keeps the place, zoom, turn, and opacity of that moment', () {
    const owner = (kind: KeyframeOwnerKind.clip, id: 'a');
    final keyed = track([4])
        .addKeyframe(owner, 0, id: 'k1')
        .setValuesAt(
          owner,
          s(2),
          (v) => v.copyWith(x: 0.2, scale: 2, rotationDeg: 10, opacity: 0.5),
          newKeyframeId: 'k2',
        );
    final still = freeze(keyed, 'a', s(1)).clipById('f')!;
    expect(still.framing.offsetX, closeTo(0.1, 1e-9));
    expect(still.framing.scale, closeTo(1.5, 1e-9));
    expect(still.framing.rotationDeg, closeTo(5, 1e-9));
    expect(still.opacity, closeTo(0.75, 1e-9));
    expect(still.keyframes, isEmpty);
  });

  test('at the very start or end of a clip, it goes before or after', () {
    final start = freeze(track([4, 3]), 'b', s(4));
    expect(start.videoClips.map((c) => c.id), ['a', 'f', 'b']);
    final end = freeze(track([4, 3]), 'a', s(4) - 1);
    expect(end.videoClips.map((c) => c.id), ['a', 'f', 'b']);
  });

  test('items later in the clip move on with their content', () {
    final t = track([6]).addText(id: 'late', text: 'Hi', atUs: s(4));
    final frozen = freeze(t, 'a', s(2));
    expect(frozen.startOfText('late'), s(7));
  });

  test('the transition after the clip stays after its second part', () {
    final t = track([4, 4]).copyWith(
      transitions: [
        const Transition(
          afterClipId: 'a',
          type: 'crossfade',
          durationUs: 500000,
        ),
      ],
    );
    final frozen = freeze(t, 'a', s(2));
    expect(frozen.transitionAfter('b2')?.type, 'crossfade');
    expect(frozen.transitionAfter('a'), isNull);
    expect(frozen.transitionAfter('f'), isNull);
  });

  test('photos and times off the clip are not frozen', () {
    final photo = Timeline(
      videoClips: [VideoClip.photo(id: 'p', mediaId: 'm')],
    );
    expect(photo.canFreezeClip('p', s(1)), isFalse);
    expect(freeze(photo, 'p', s(1)), same(photo));
    final t = track([2, 2]);
    expect(t.canFreezeClip('a', s(3)), isFalse);
  });
}
