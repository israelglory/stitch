import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/features/timeline/domain/audio_ops.dart';
import 'package:stitch/features/timeline/domain/composition.dart';
import 'package:stitch/features/timeline/domain/limits.dart';
import 'package:stitch/features/timeline/domain/models.dart';
import 'package:stitch/features/timeline/domain/video_ops.dart';

import 'fixtures.dart';

extension on Timeline {
  Timeline addSong(
    String id,
    num atSeconds,
    num lengthSeconds, {
    int lane = 0,
  }) => addAudio(
    id: id,
    mediaId: 'song-$id',
    kind: AudioKind.music,
    name: 'Song $id',
    mediaDurationUs: s(lengthSeconds),
    atUs: s(atSeconds),
    lane: lane,
  );
}

void main() {
  final base = track([5, 5]);

  test('adds a whole file at a time', () {
    final t = base.addSong('m', 1, 20);
    final item = t.audioById('m')!;
    expect(t.startOfAudio('m'), s(1));
    expect(item.sourceInUs, 0);
    expect(item.sourceOutUs, s(20));
  });

  test('overlapping items stack on lanes; audioLanes groups them', () {
    final t = base.addSong('1', 0, 4).addSong('2', 2, 4).addSong('3', 5, 2);
    expect(t.audioLanes.map((l) => l.map((a) => a.id).toList()).toList(), [
      ['1', '3'],
      ['2'],
    ]);
  });

  test('moving onto an occupied lane uses the next free one', () {
    final t = base.addSong('1', 0, 4).addSong('2', 6, 2).moveAudio('2', s(1));
    expect(t.audioById('2')!.laneIndex, 1);
    expect(t.startOfAudio('2'), s(1));
  });

  group('trim', () {
    test('start trims the source and moves the start', () {
      final t = base.addSong('m', 1, 10).trimAudio('m', ClipEdge.start, s(2));
      expect(t.audioById('m')!.sourceInUs, s(2));
      expect(t.startOfAudio('m'), s(3));
    });

    test('start cannot be pulled before zero or the source start', () {
      final t = base.addSong('m', 1, 10);
      final pulled = t.trimAudio('m', ClipEdge.start, -s(5));
      expect(identical(pulled, t), isTrue);

      // Pulled back as far as possible, the source start returns to 0.
      final trimmed = t.trimAudio('m', ClipEdge.start, s(3));
      final back = trimmed.trimAudio('m', ClipEdge.start, -s(10));
      expect(back.audioById('m')!.sourceInUs, 0);
      expect(back.startOfAudio('m'), s(1));

      // Moved to 1s with 3s trimmed, only 1s can be restored before the
      // item would start before zero.
      final moved = trimmed.moveAudio('m', s(1));
      final limited = moved.trimAudio('m', ClipEdge.start, -s(10));
      expect(limited.startOfAudio('m'), 0);
      expect(limited.audioById('m')!.sourceInUs, s(2));
    });

    test('end clamps to the file and the minimum', () {
      final t = base.addSong('m', 0, 4);
      expect(
        t.trimAudio('m', ClipEdge.end, s(10)).audioById('m')!.sourceOutUs,
        s(4),
      );
      expect(
        t.trimAudio('m', ClipEdge.end, -s(10)).audioById('m')!.durationUs,
        TimelineLimits.minDurationUs,
      );
    });

    test('trimming re-clamps fades to the shorter item', () {
      final t = base
          .addSong('m', 0, 2)
          .setAudioFades('m', fadeInUs: s(1), fadeOutUs: s(1))
          .trimAudio('m', ClipEdge.end, -s(0.5));
      final m = t.audioById('m')!;
      expect(m.fadeInUs + m.fadeOutUs, lessThanOrEqualTo(m.durationUs));
    });

    test('the end of a looping item is fixed', () {
      final t = base.addSong('m', 0, 4).setAudioLoop('m', loop: true);
      expect(identical(t.trimAudio('m', ClipEdge.end, -s(1)), t), isTrue);
    });
  });

  test('split divides source and drops the inner fades', () {
    final t = base
        .addSong('m', 1, 6)
        .setAudioFades('m', fadeInUs: s(1), fadeOutUs: s(1))
        .splitAudio('m', s(3), newId: 'm2');
    final a = t.audioById('m')!;
    final b = t.audioById('m2')!;
    expect(a.sourceOutUs, s(2));
    expect(b.sourceInUs, s(2));
    expect(t.startOfAudio('m2'), s(3));
    expect(a.fadeInUs, s(1));
    expect(a.fadeOutUs, 0);
    expect(b.fadeInUs, 0);
    expect(b.fadeOutUs, s(1));
  });

  test('looping items cannot be split', () {
    final t = base.addSong('m', 0, 4).setAudioLoop('m', loop: true);
    expect(t.canSplitAudio('m', s(2)), isFalse);
  });

  test('fades are clamped to fit the item', () {
    final t = base
        .addSong('m', 0, 2)
        .setAudioFades('m', fadeInUs: s(1.5), fadeOutUs: s(1.5));
    expect(t.audioById('m')!.fadeInUs, s(1.5));
    expect(t.audioById('m')!.fadeOutUs, s(0.5));
  });

  test('setting one fade keeps the other', () {
    final t = base
        .addSong('m', 0, 4)
        .setAudioFades('m', fadeInUs: s(1))
        .setAudioFades('m', fadeOutUs: s(0.5));
    expect(t.audioById('m')!.fadeInUs, s(1));
    expect(t.audioById('m')!.fadeOutUs, s(0.5));
    expect(identical(t.setAudioFades('m'), t), isTrue);
  });

  test('speed changes length and re-clamps fades', () {
    final t = base
        .addSong('m', 0, 4)
        .setAudioFades('m', fadeInUs: s(2), fadeOutUs: s(2))
        .setAudioSpeed('m', 2);
    expect(t.audioById('m')!.durationUs, s(2));
    expect(t.audioById('m')!.fadeInUs + t.audioById('m')!.fadeOutUs, s(2));
  });

  test('volume and mix are clamped', () {
    final t = base
        .addSong('m', 0, 4)
        .setAudioVolume('m', 9)
        .setAudioMix(originalLevel: -1, addedLevel: 0.5);
    expect(t.audioById('m')!.volume, TimelineLimits.maxVolume);
    expect(t.audioMix.originalLevel, 0);
    expect(t.audioMix.addedLevel, 0.5);
  });

  group('extract audio', () {
    test('creates an item under the clip and silences the clip', () {
      final t = track([2, 3]).extractAudio('b', newId: 'x', name: 'Clip 2');
      expect(t.clipById('b')!.audioDetached, isTrue);
      expect(t.startOfAudio('x'), s(2));
      expect(t.audioById('x')!.durationUs, s(3));
      expect(t.audioById('x')!.kind, AudioKind.extracted);
      expect(t.canExtractAudio('b'), isFalse);
    });

    test('stays in sync with the picture when the clip start is trimmed', () {
      final t = track([2, 3])
          .extractAudio('b', newId: 'x', name: 'Clip 2')
          .trimClip('b', ClipEdge.start, s(1));
      // The audio's first second now plays under clip a, so the rest still
      // lines up with b's frames.
      expect(t.startOfAudio('x'), s(1));
    });

    test('photos have no audio to extract', () {
      final t = Timeline.empty.appendClips([
        VideoClip.photo(id: 'p', mediaId: 'm'),
      ]);
      expect(t.canExtractAudio('p'), isFalse);
    });
  });

  group('in the composition', () {
    test('music past the video end is cut and marked', () {
      final comp = ResolvedComposition.resolve(base.addSong('m', 8, 10));
      final m = comp.audio.single;
      expect(m.startUs, s(8));
      expect(m.endUs, s(10));
      expect(m.cutAtVideoEnd, isTrue);
    });

    test('looping fills to the end of the video', () {
      final comp = ResolvedComposition.resolve(
        base.addSong('m', 1, 2).setAudioLoop('m', loop: true),
      );
      expect(comp.audio.single.endUs, s(10));
      expect(comp.audio.single.loop, isTrue);
      expect(comp.audio.single.cutAtVideoEnd, isFalse);
    });

    test('item volume is scaled by the added-audio level', () {
      final comp = ResolvedComposition.resolve(
        base
            .addSong('m', 0, 2)
            .setAudioVolume('m', 0.8)
            .setAudioMix(addedLevel: 0.5),
      );
      expect(comp.audio.single.volume, closeTo(0.4, 1e-9));
    });
  });
}
