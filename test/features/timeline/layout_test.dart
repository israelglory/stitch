import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/features/timeline/domain/layout.dart';
import 'package:stitch/features/timeline/domain/models.dart';

import 'fixtures.dart';

void main() {
  group('clip spans', () {
    test('clips sit back to back', () {
      final t = track([2, 3, 1]);
      expect(t.startOfClip('a'), 0);
      expect(t.startOfClip('b'), s(2));
      expect(t.startOfClip('c'), s(5));
      expect(t.durationUs, s(6));
    });

    test('empty timeline has zero length', () {
      expect(Timeline.empty.durationUs, 0);
      expect(Timeline.empty.layout.spanAt(0), isNull);
    });

    test('speed changes timeline length', () {
      final t = Timeline(videoClips: [clip('a', 4, speed: 2), clip('b', 1)]);
      expect(t.clipById('a')!.durationUs, s(2));
      expect(t.startOfClip('b'), s(2));
    });

    test('a transition overlaps the clips around it', () {
      final t = track([2, 3]).copyWith(
        transitions: [
          Transition(
            afterClipId: 'a',
            type: TransitionType.crossfade,
            durationUs: s(0.5),
          ),
        ],
      );
      expect(t.startOfClip('b'), s(1.5));
      expect(t.durationUs, s(4.5));
      expect(t.layout.transitionUs('a'), s(0.5));
    });

    test('the effective transition never exceeds half the shorter clip', () {
      final t = track([0.6, 3]).copyWith(
        transitions: [
          Transition(
            afterClipId: 'a',
            type: TransitionType.crossfade,
            durationUs: s(1.5),
          ),
        ],
      );
      expect(t.layout.transitionUs('a'), s(0.3));
    });

    test('spanAt picks the incoming clip inside a transition', () {
      final t = track([2, 3]).copyWith(
        transitions: [
          Transition(
            afterClipId: 'a',
            type: TransitionType.crossfade,
            durationUs: s(1),
          ),
        ],
      );
      expect(t.layout.spanAt(s(0.5))!.clip.id, 'a');
      expect(t.layout.spanAt(s(1.2))!.clip.id, 'b');
      expect(t.layout.spanAt(s(99))!.clip.id, 'b');
      expect(t.layout.spanAt(-5)!.clip.id, 'a');
    });
  });

  group('anchors', () {
    final t = Timeline(
      videoClips: [
        clip('a', 2),
        clip('b', 4, from: 10, speed: 2), // 2s on the timeline
      ],
    );

    test('anchorAt stores the content moment under a time', () {
      final anchor = t.layout.anchorAt(s(3)) as ClipAnchor;
      expect(anchor.clipId, 'b');
      // 1s into b at 2x is 2s into the source, which starts at 10s.
      expect(anchor.sourceUs, s(12));
    });

    test('resolve inverts anchorAt', () {
      for (final time in [0, s(0.5), s(2), s(2.7), s(3.999)]) {
        expect(t.layout.startOf(t.layout.anchorAt(time)), time);
      }
    });

    test('times past the end anchor to the end of the last clip', () {
      final anchor = t.layout.anchorAt(s(100)) as ClipAnchor;
      expect(anchor.clipId, 'b');
      expect(anchor.sourceUs, s(14));
    });

    test('without clips, anchors are absolute', () {
      expect(Timeline.empty.layout.anchorAt(s(5)), Anchor.time(startUs: s(5)));
      expect(Timeline.empty.layout.startOf(Anchor.time(startUs: s(5))), s(5));
    });

    test('a trimmed-away moment extrapolates and reports out of range', () {
      final trimmed = Timeline(
        videoClips: [clip('a', 2), clip('b', 3, from: 5)],
      );
      // The moment 4s into b's source, 1s before b's current start.
      final pos = trimmed.layout.resolve(
        Anchor.clip(clipId: 'b', sourceUs: s(4)),
      );
      expect(pos.inRange, isFalse);
      expect(pos.startUs, s(1));
    });

    test('extrapolation never goes before zero', () {
      final t2 = Timeline(videoClips: [clip('a', 2, from: 5)]);
      final pos = t2.layout.resolve(
        const Anchor.clip(clipId: 'a', sourceUs: 0),
      );
      expect(pos.startUs, 0);
      expect(pos.inRange, isFalse);
    });
  });

  group('packLanes', () {
    test('keeps preferred lanes when free', () {
      expect(
        packLanes([
          (startUs: 0, endUs: 10, lane: 0),
          (startUs: 10, endUs: 20, lane: 0),
          (startUs: 5, endUs: 8, lane: 1),
        ]),
        [0, 0, 1],
      );
    });

    test('the later item moves to the next free lane', () {
      expect(
        packLanes([
          (startUs: 5, endUs: 15, lane: 0),
          (startUs: 0, endUs: 10, lane: 0),
          (startUs: 12, endUs: 14, lane: 0),
          (startUs: 9, endUs: 13, lane: 0),
        ]),
        // 12-14 fits on lane 0 after 0-10 ends; 9-13 overlaps lanes 0
        // and 1, so it goes to lane 2.
        [1, 0, 0, 2],
      );
    });

    test('touching items share a lane', () {
      expect(
        packLanes([
          (startUs: 0, endUs: 10, lane: 0),
          (startUs: 10, endUs: 12, lane: 0),
        ]),
        [0, 0],
      );
    });
  });
}
