import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/features/timeline/domain/audio_ops.dart';
import 'package:stitch/features/timeline/domain/limits.dart';
import 'package:stitch/features/timeline/domain/models.dart';
import 'package:stitch/features/timeline/domain/text_ops.dart';
import 'package:stitch/features/timeline/domain/transition_ops.dart';
import 'package:stitch/features/timeline/domain/video_ops.dart';

import 'fixtures.dart';

void main() {
  group('insert', () {
    test('inserts at an index and appends', () {
      final t = track([1, 2])
          .insertClips(1, [clip('x', 3)])
          .appendClips([clip('y', 1)]);
      expect(t.videoClips.map((c) => c.id), ['a', 'x', 'b', 'y']);
      expect(t.durationUs, s(7));
    });

    test('a whole video file spans its full length', () {
      final t = Timeline.empty.appendClips([
        VideoClip.video(id: 'v', mediaId: 'm', mediaDurationUs: s(7)),
      ]);
      expect(t.durationUs, s(7));
      expect(t.clipById('v')!.sourceInUs, 0);
    });

    test('photos default to 3 seconds', () {
      final t = Timeline.empty.appendClips([
        VideoClip.photo(id: 'p', mediaId: 'm'),
      ]);
      expect(t.durationUs, TimelineLimits.photoDurationUs);
    });

    test('inserting nothing returns the same timeline', () {
      final t = track([1]);
      expect(identical(t.insertClips(0, []), t), isTrue);
    });
  });

  group('delete', () {
    test('closes the gap', () {
      final t = track([1, 2, 3]).deleteClip('b');
      expect(t.videoClips.map((c) => c.id), ['a', 'c']);
      expect(t.startOfClip('c'), s(1));
      expect(t.durationUs, s(4));
    });

    test('unknown id is a no-op', () {
      final t = track([1]);
      expect(identical(t.deleteClip('zzz'), t), isTrue);
    });

    test('removes the transition after the clip, keeps the one before', () {
      final t = track([2, 2, 2])
          .setTransition('a', TransitionType.crossfade)
          .setTransition('b', TransitionType.wipeLeft)
          .deleteClip('b');
      expect(t.transitions.map((x) => x.afterClipId), ['a']);
    });

    test('items on later clips shift left with their content', () {
      final t = track([2, 3])
          .addText(id: 'txt', text: 'Hi', atUs: s(3))
          .deleteClip('a');
      expect(t.startOfText('txt'), s(1));
      expect(t.textItems.single.needsReview, isFalse);
    });

    test('items on the deleted clip stay put and are flagged', () {
      final t = track([2, 2, 2])
          .addText(id: 'txt', text: 'Hi', atUs: s(2.5), durationUs: s(1))
          .deleteClip('b');
      final item = t.textItems.single;
      expect(t.startOfText('txt'), s(2.5));
      expect(item.needsReview, isTrue);
      expect((item.anchor as ClipAnchor).clipId, 'c');
    });

    test('items re-anchor to content when clips are added again', () {
      final t = track([4])
          .addText(id: 'txt', text: 'Hi', atUs: s(1))
          .deleteClip('a')
          .appendClips([clip('b', 3)]);
      final anchor = t.textItems.single.anchor as ClipAnchor;
      expect(anchor.clipId, 'b');
      expect(t.startOfText('txt'), s(1));
    });

    test('deleting the last clip leaves items anchored in absolute time', () {
      final t = track([4])
          .addText(id: 'txt', text: 'Hi', atUs: s(1))
          .deleteClip('a');
      expect(t.textItems.single.anchor, isA<TimeAnchor>());
      expect(t.textItems.single.needsReview, isTrue);
    });
  });

  group('duplicate', () {
    test('inserts a copy right after', () {
      final t = track([1, 2]).duplicateClip('a', newId: 'a2');
      expect(t.videoClips.map((c) => c.id), ['a', 'a2', 'b']);
      expect(t.clipById('a2')!.sourceOutUs, t.clipById('a')!.sourceOutUs);
    });

    test('rejects an id already in use', () {
      final t = track([1, 2]);
      expect(identical(t.duplicateClip('a', newId: 'b'), t), isTrue);
    });
  });

  group('split', () {
    test('splits source at the playhead', () {
      final t = track([4]).splitClip('a', s(1.5), newId: 'a2');
      expect(t.clipById('a')!.sourceOutUs, s(1.5));
      expect(t.clipById('a2')!.sourceInUs, s(1.5));
      expect(t.clipById('a2')!.sourceOutUs, s(4));
      expect(t.durationUs, s(4));
    });

    test('accounts for speed', () {
      final t = Timeline(videoClips: [clip('a', 4, from: 10, speed: 2)])
          .splitClip('a', s(1), newId: 'a2');
      expect(t.clipById('a')!.sourceOutUs, s(12));
      expect(t.clipById('a2')!.sourceInUs, s(12));
    });

    test('refuses to leave a part shorter than the minimum', () {
      final t = track([2]);
      expect(t.canSplitClip('a', s(0.05)), isFalse);
      expect(t.canSplitClip('a', s(1.95)), isFalse);
      expect(t.canSplitClip('a', s(0.1)), isTrue);
      expect(identical(t.splitClip('a', s(0.05), newId: 'x'), t), isTrue);
    });

    test('the transition after the clip moves to the second part', () {
      final t = track([4, 2])
          .setTransition('a', TransitionType.crossfade)
          .splitClip('a', s(1), newId: 'a2');
      expect(t.transitions.single.afterClipId, 'a2');
    });

    test('items after the split point follow the second part', () {
      final t = track([4])
          .addText(id: 'early', text: '1', atUs: s(0.5), durationUs: s(0.5))
          .addText(id: 'late', text: '2', atUs: s(3), durationUs: s(0.5))
          .splitClip('a', s(2), newId: 'a2');
      expect((t.textById('early')!.anchor as ClipAnchor).clipId, 'a');
      expect((t.textById('late')!.anchor as ClipAnchor).clipId, 'a2');
      expect(t.startOfText('late'), s(3));
    });
  });

  group('trim', () {
    test('trimming the end ripples later clips', () {
      final t = track([3, 2]).trimClip('a', ClipEdge.end, -s(1));
      expect(t.clipById('a')!.sourceOutUs, s(2));
      expect(t.startOfClip('b'), s(2));
    });

    test('trimming the start keeps the clip in place and ripples', () {
      final t = track([3, 2]).trimClip('a', ClipEdge.start, s(1));
      expect(t.clipById('a')!.sourceInUs, s(1));
      expect(t.startOfClip('a'), 0);
      expect(t.startOfClip('b'), s(2));
    });

    test('clamps to the source file', () {
      final t = Timeline(videoClips: [clip('a', 3, from: 1, mediaSeconds: 5)]);
      expect(
        t.trimClip('a', ClipEdge.start, -s(10)).clipById('a')!.sourceInUs,
        0,
      );
      expect(
        t.trimClip('a', ClipEdge.end, s(10)).clipById('a')!.sourceOutUs,
        s(5),
      );
    });

    test('clamps to the minimum length', () {
      final t = track([3]);
      final shorter = t.trimClip('a', ClipEdge.end, -s(10)).clipById('a')!;
      expect(shorter.durationUs, TimelineLimits.minDurationUs);
      final later = t.trimClip('a', ClipEdge.start, s(10)).clipById('a')!;
      expect(later.durationUs, TimelineLimits.minDurationUs);
    });

    test('photos can be extended without limit', () {
      final t = Timeline.empty
          .appendClips([VideoClip.photo(id: 'p', mediaId: 'm')])
          .trimClip('p', ClipEdge.end, s(20));
      expect(t.durationUs, s(23));
    });

    test('works in timeline time at speed', () {
      final t = Timeline(videoClips: [clip('a', 4, speed: 2)])
          .trimClip('a', ClipEdge.end, -s(0.5));
      expect(t.clipById('a')!.sourceOutUs, s(3));
      expect(t.durationUs, s(1.5));
    });

    test('items on the trimmed clip stay with their content', () {
      final t = track([4])
          .addText(id: 'txt', text: 'Hi', atUs: s(2), durationUs: s(1))
          .trimClip('a', ClipEdge.start, s(1));
      expect(t.startOfText('txt'), s(1));
    });

    test('an edge that cannot move returns the same timeline', () {
      final t = track([3]);
      expect(identical(t.trimClip('a', ClipEdge.start, -s(1)), t), isTrue);
      expect(identical(t.trimClip('a', ClipEdge.end, 0), t), isTrue);
    });
  });

  group('move', () {
    test('reorders clips', () {
      final t = track([1, 2, 3]).moveClip('a', 2);
      expect(t.videoClips.map((c) => c.id), ['b', 'c', 'a']);
      expect(t.startOfClip('a'), s(5));
    });

    test('anchored items travel with their clip', () {
      final t = track([1, 2, 3])
          .addText(id: 'txt', text: 'Hi', atUs: s(0.5), durationUs: s(0.3))
          .moveClip('a', 2);
      expect(t.startOfText('txt'), s(5.5));
    });

    test('a transition travels with its clip and is dropped at the end', () {
      final moved = track([2, 2, 2])
          .setTransition('a', TransitionType.crossfade)
          .moveClip('a', 1);
      expect(moved.transitions.single.afterClipId, 'a');

      final last = track([2, 2, 2])
          .setTransition('a', TransitionType.crossfade)
          .moveClip('a', 2);
      expect(last.transitions, isEmpty);
    });

    test('moving to the same index is a no-op', () {
      final t = track([1, 2]);
      expect(identical(t.moveClip('a', 0), t), isTrue);
    });
  });

  group('speed and volume', () {
    test('speed scales duration and is clamped', () {
      final t = track([4]);
      expect(t.setClipSpeed('a', 2).durationUs, s(2));
      expect(t.setClipSpeed('a', 100).clipById('a')!.speed, 4);
      expect(t.setClipSpeed('a', 0.01).clipById('a')!.speed, 0.25);
    });

    test('speed cannot shrink a clip below the minimum', () {
      final t = track([0.2]).setClipSpeed('a', 4);
      expect(t.clipById('a')!.durationUs, TimelineLimits.minDurationUs);
    });

    test('items on a sped-up clip keep their content moment', () {
      final t = track([4, 2])
          .addText(id: 'txt', text: 'Hi', atUs: s(2), durationUs: s(1))
          .addText(id: 'next', text: 'Yo', atUs: s(5), durationUs: s(0.5))
          .setClipSpeed('a', 2);
      expect(t.startOfText('txt'), s(1));
      expect(t.startOfText('next'), s(3));
    });

    test('framing is stored per clip', () {
      const framing = ClipFraming(mode: FramingMode.manual, scale: 1.5);
      final t = track([1]).setClipFraming('a', framing);
      expect(t.clipById('a')!.framing, framing);
      expect(identical(t.setClipFraming('a', framing), t), isTrue);
    });

    test('volume is clamped', () {
      final t = track([1]);
      expect(t.setClipVolume('a', 5).clipById('a')!.volume, 2);
      expect(t.setClipVolume('a', -1).clipById('a')!.volume, 0);
    });
  });

  group('replace', () {
    test('keeps length when the new source is long enough', () {
      final t = track([3]).replaceClipMedia(
        'a',
        mediaId: 'new',
        kind: MediaKind.video,
        mediaDurationUs: s(10),
      );
      expect(t.clipById('a')!.mediaId, 'new');
      expect(t.durationUs, s(3));
    });

    test('shortens to a shorter source and undoes extraction', () {
      final t = track([3])
          .extractAudio('a', newId: 'x', name: 'a')
          .replaceClipMedia(
            'a',
            mediaId: 'new',
            kind: MediaKind.video,
            mediaDurationUs: s(1),
          );
      expect(t.durationUs, s(1));
      expect(t.clipById('a')!.audioDetached, isFalse);
    });

    test('anchored items keep their offset into the clip', () {
      final t = Timeline(videoClips: [clip('a', 3, from: 20)])
          .addText(id: 'txt', text: 'Hi', atUs: s(1), durationUs: s(1))
          .replaceClipMedia(
            'a',
            mediaId: 'new',
            kind: MediaKind.video,
            mediaDurationUs: s(10),
          );
      expect(t.startOfText('txt'), s(1));
    });
  });
}
