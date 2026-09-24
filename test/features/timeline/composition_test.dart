import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/features/timeline/domain/audio_ops.dart';
import 'package:stitch/features/timeline/domain/caption_ops.dart';
import 'package:stitch/features/timeline/domain/composition.dart';
import 'package:stitch/features/timeline/domain/models.dart';
import 'package:stitch/features/timeline/domain/text_ops.dart';
import 'package:stitch/features/timeline/domain/transition_ops.dart';
import 'package:stitch/features/timeline/domain/video_ops.dart';

import 'fixtures.dart';

void main() {
  test('empty timeline resolves to an empty composition', () {
    final comp = ResolvedComposition.resolve(Timeline.empty);
    expect(comp.durationUs, 0);
    expect(comp.clips, isEmpty);
  });

  test('clips carry absolute ranges and source ranges', () {
    final comp = ResolvedComposition.resolve(
      Timeline(videoClips: [clip('a', 2, from: 5), clip('b', 4, speed: 2)]),
    );
    expect(comp.durationUs, s(4));
    expect(comp.clips[0].startUs, 0);
    expect(comp.clips[0].endUs, s(2));
    expect(comp.clips[0].sourceInUs, s(5));
    expect(comp.clips[1].startUs, s(2));
    expect(comp.clips[1].endUs, s(4));
    expect(comp.clips[1].speed, 2);
  });

  test('transitions resolve to windows and matching audio crossfades', () {
    final comp = ResolvedComposition.resolve(
      track([3, 3, 3])
          .setTransition('a', TransitionType.crossfade, durationUs: s(1)),
    );
    final t = comp.transitions.single;
    expect(t.fromClipId, 'a');
    expect(t.toClipId, 'b');
    expect(t.startUs, s(2));
    expect(t.durationUs, s(1));
    expect(comp.clips[0].audioFadeOutUs, s(1));
    expect(comp.clips[1].audioFadeInUs, s(1));
    expect(comp.clips[1].audioFadeOutUs, 0);
    expect(comp.clips[2].audioFadeInUs, 0);
  });

  group('clip volume', () {
    test('scaled by the original sound level', () {
      final comp = ResolvedComposition.resolve(
        track([1]).setClipVolume('a', 0.5).setAudioMix(originalLevel: 0.5),
      );
      expect(comp.clips.single.volume, closeTo(0.25, 1e-9));
    });

    test('silent when original sound is off, extracted, or a photo', () {
      expect(
        ResolvedComposition.resolve(
          track([1]).setAudioMix(originalSoundEnabled: false),
        ).clips.single.volume,
        0,
      );
      expect(
        ResolvedComposition.resolve(
          track([1]).extractAudio('a', newId: 'x', name: 'a'),
        ).clips.single.volume,
        0,
      );
      expect(
        ResolvedComposition.resolve(
          Timeline(
            videoClips: [VideoClip.photo(id: 'p', mediaId: 'm')],
          ),
        ).clips.single.volume,
        0,
      );
    });
  });

  test('text past the video end is cut; text wholly past it is dropped', () {
    final t = track([4])
        .addText(id: 'cut', text: 'a', atUs: s(3), durationUs: s(3))
        .addText(id: 'gone', text: 'b', atUs: s(1), durationUs: s(1))
        .trimClip('a', ClipEdge.end, -s(3));
    final comp = ResolvedComposition.resolve(t);
    // After trimming to 1s, "cut" (anchored at 3s of source) extrapolates
    // past the end and "gone" starts exactly at the end.
    expect(comp.durationUs, s(1));
    expect(comp.texts, isEmpty);

    final kept = ResolvedComposition.resolve(
      track([4]).addText(id: 'cut', text: 'a', atUs: s(3), durationUs: s(3)),
    );
    expect(kept.texts.single.startUs, s(3));
    expect(kept.texts.single.endUs, s(4));
  });

  test('audio fades are clamped to what remains after the cut', () {
    final comp = ResolvedComposition.resolve(
      track([2])
          .addAudio(
            id: 'm',
            mediaId: 'song',
            kind: AudioKind.music,
            name: 'Song',
            mediaDurationUs: s(10),
            atUs: s(1),
          )
          .setAudioFades('m', fadeInUs: s(0.5), fadeOutUs: s(3)),
    );
    final m = comp.audio.single;
    expect(m.endUs - m.startUs, s(1));
    expect(m.fadeInUs, s(0.5));
    expect(m.fadeOutUs, s(0.5));
  });

  test('round-trips through JSON', () {
    final comp = ResolvedComposition.resolve(
      track([3, 3])
          .setTransition('a', TransitionType.wipeLeft)
          .addText(id: 't', text: 'Hi', atUs: s(1))
          .setCaptions([
            (
              id: 'c',
              text: 'hello',
              startUs: s(1),
              endUs: s(2),
              words: [(text: 'hello', startUs: s(1), endUs: s(2))],
            ),
          ])
          .addAudio(
            id: 'm',
            mediaId: 'song',
            kind: AudioKind.music,
            name: 'Song',
            mediaDurationUs: s(10),
            atUs: 0,
          ),
    );
    expect(comp.captions.single.words, isNotEmpty);
    final json = jsonDecode(jsonEncode(comp.toJson())) as Map<String, dynamic>;
    expect(ResolvedComposition.fromJson(json), comp);
  });
}
