import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/features/timeline/domain/audio_ops.dart';
import 'package:stitch/features/timeline/domain/composition.dart';
import 'package:stitch/features/timeline/domain/keyframes.dart';
import 'package:stitch/features/timeline/domain/models.dart';
import 'package:stitch/features/timeline/domain/text_ops.dart';
import 'package:stitch/features/timeline/domain/video_ops.dart';

import 'fixtures.dart';

// The engines get keyframes with their times on the timeline and only
// evaluate them. These tests check that what they compute is what the
// editor shows, and pin the shared table the Swift and Kotlin evaluators
// are tested against.

const KeyframeOwner _a = (kind: KeyframeOwnerKind.clip, id: 'a');

/// Every [stepUs] from [fromUs] to [toUs].
Iterable<int> _times(int fromUs, int toUs, [int stepUs = 50000]) sync* {
  for (var t = fromUs; t <= toUs; t += stepUs) {
    yield t;
  }
}

void _expectClose(KeyframeValues got, KeyframeValues want, String at) {
  for (final (name, g, w) in [
    ('x', got.x, want.x),
    ('y', got.y, want.y),
    ('scale', got.scale, want.scale),
    ('rotationDeg', got.rotationDeg, want.rotationDeg),
    ('opacity', got.opacity, want.opacity),
    ('volume', got.volume, want.volume),
  ]) {
    expect(g, closeTo(w, 1e-4), reason: '$name at $at');
  }
}

/// Zooms and turns clip a, eased, then trims, speeds up, and splits it.
Timeline _edited() {
  var t = track([4, 3]);
  t = t.addKeyframe(_a, s(0.5), id: 'k1');
  t = t.setValuesAt(
    _a,
    s(2),
    (v) => v.copyWith(scale: 2, rotationDeg: 30, x: 0.2, opacity: 0.4),
    newKeyframeId: 'k2',
  );
  t = t.setValuesAt(
    _a,
    s(3.5),
    (v) => v.copyWith(volume: 0.2, y: -0.1),
    newKeyframeId: 'k3',
  );
  t = t
      .setKeyframeEasing(_a, 'k1', KeyframeEasing.easeInOut)
      .setKeyframeEasing(_a, 'k2', KeyframeEasing.hold);
  return t
      .trimClip('a', ClipEdge.start, s(0.3))
      .setClipSpeed('a', 1.5)
      .splitClip('a', s(1), newId: 'a2')
      .setAudioMix(originalLevel: 0.5);
}

Map<String, Object> _case(
  String name,
  List<Keyframe> keyframes,
  Iterable<int> times, {
  int loopStartUs = 0,
  int loopUs = 0,
}) => {
  'name': name,
  'keyframes': [for (final k in keyframes) k.toJson()],
  'loopStartUs': loopStartUs,
  'loopUs': loopUs,
  'samples': [
    for (final t in times)
      {
        'timeUs': t,
        'values': engineValuesAt(
          keyframes,
          t,
          loopStartUs: loopStartUs,
          loopUs: loopUs,
        )!.toJson(),
      },
  ],
};

/// The shared table: each easing, a loop, and a single keyframe.
Map<String, Object> _table() {
  Keyframe k(int us, KeyframeEasing easing, KeyframeValues values) =>
      Keyframe(id: '$us', timeUs: us, values: values, easing: easing);
  const a = KeyframeValues();
  const b = KeyframeValues(
    x: 0.25,
    y: -0.5,
    scale: 3,
    rotationDeg: -90,
    opacity: 0.2,
    volume: 1.8,
  );
  final easings = [
    for (final (i, e) in KeyframeEasing.values.indexed)
      k(s(i), e, i.isEven ? a : b),
    k(s(KeyframeEasing.values.length), KeyframeEasing.linear, a),
  ];
  return {
    '_comment':
        'Keyframe values at timeline times, from the Dart evaluator '
        '(engineValuesAt in lib/features/timeline/domain/keyframes.dart). '
        'Written by test/features/timeline/engine_keyframes_test.dart with '
        'UPDATE_KEYFRAME_CASES=1; the Swift and Kotlin engine tests check '
        'their evaluators against it.',
    'cases': [
      _case('easings', easings, _times(-s(0.5), s(6.5), 125000)),
      _case(
        'loop',
        [
          k(s(1.5), KeyframeEasing.easeOut, a),
          k(s(2.5), KeyframeEasing.linear, b),
        ],
        _times(0, s(7), 125000),
        loopStartUs: s(1),
        loopUs: s(2),
      ),
      _case('single', [k(s(1), KeyframeEasing.easeIn, b)], [0, s(1), s(9)]),
    ],
  };
}

void main() {
  test('clips: the engines see what the editor shows', () {
    final t = _edited();
    final composition = ResolvedComposition.resolve(t);
    for (final clip in composition.clips.where((c) => c.clipId != 'b')) {
      final owner = (kind: KeyframeOwnerKind.clip, id: clip.clipId);
      expect(clip.keyframes, isNotEmpty);
      for (final at in _times(clip.startUs, clip.endUs)) {
        final want = t.valuesAt(owner, at)!;
        _expectClose(
          engineValuesAt(clip.keyframes, at)!,
          want.copyWith(volume: want.volume * 0.5),
          '${clip.clipId} $at',
        );
      }
    }
    // Keyframes that no longer shape anything are left out.
    expect(composition.clips.first.keyframes.length, lessThanOrEqualTo(3));
    expect(composition.clips.last.keyframes, isEmpty);
  });

  test('muted clips get silent keyframes', () {
    final t = _edited().setAudioMix(originalSoundEnabled: false);
    final clip = ResolvedComposition.resolve(t).clips.first;
    expect(clip.keyframes.every((k) => k.values.volume == 0), isTrue);
  });

  test('text: timeline times from the item start', () {
    const owner = (kind: KeyframeOwnerKind.text, id: 't');
    var t = track([10]).addText(id: 't', text: 'Hi', atUs: s(2));
    t = t.addKeyframe(owner, s(2.5), id: 'k1');
    t = t.setValuesAt(
      owner,
      s(4),
      (v) => v.copyWith(opacity: 0, scale: 2),
      newKeyframeId: 'k2',
    );
    final text = ResolvedComposition.resolve(t).texts.single;
    expect(text.keyframes.map((k) => k.timeUs), [s(2.5), s(4)]);
    for (final at in _times(text.startUs, text.endUs)) {
      _expectClose(
        engineValuesAt(text.keyframes, at)!,
        t.valuesAt(owner, at)!,
        '$at',
      );
    }
  });

  group('audio', () {
    Timeline withMusic({required bool loop}) {
      const owner = (kind: KeyframeOwnerKind.audio, id: 'm');
      var t = track([4, 4]).addAudio(
        id: 'm',
        mediaId: 'music',
        kind: AudioKind.music,
        name: 'Music',
        mediaDurationUs: s(3),
        atUs: s(0.5),
      );
      t = t.addKeyframe(owner, s(1), id: 'k1');
      t = t.setValuesAt(
        owner,
        s(3),
        (v) => v.copyWith(volume: 0.25),
        newKeyframeId: 'k2',
      );
      t = t.setKeyframeEasing(owner, 'k1', KeyframeEasing.easeIn);
      return t
          .setAudioLoop('m', loop: loop)
          .setAudioSpeed('m', 1.25)
          .setAudioMix(addedLevel: 1.5);
    }

    void expectMatches(Timeline t, String id) {
      final owner = (kind: KeyframeOwnerKind.audio, id: id);
      final item = ResolvedComposition.resolve(t).audio
          .firstWhere((a) => a.id == id);
      expect(item.keyframes, isNotEmpty);
      for (final at in _times(item.startUs, item.endUs - 1)) {
        final want = t.valuesAt(owner, at)!;
        expect(
          engineValuesAt(
            item.keyframes,
            at,
            loopStartUs: item.startUs,
            loopUs: item.keyframeLoopUs,
          )!.volume,
          closeTo(want.volume * t.audioMix.addedLevel, 1e-6),
          reason: 'at $at',
        );
      }
    }

    test('one pass', () {
      final t = withMusic(loop: false);
      expectMatches(t, 'm');
      expect(ResolvedComposition.resolve(t).audio.single.keyframeLoopUs, 0);
    });

    test('a loop repeats its keyframes', () {
      final t = withMusic(loop: true);
      final item = ResolvedComposition.resolve(t).audio.single;
      expect(item.keyframeLoopUs, t.audioItems.single.durationUs);
      expect(item.endUs, greaterThan(item.startUs + item.keyframeLoopUs));
      expectMatches(t, 'm');
    });

    test('extracted sound trimmed at the front stays in sync', () {
      var t = track([4, 4]);
      t = t.addKeyframe(_a, s(1), id: 'k1');
      t = t.setValuesAt(
        _a,
        s(3),
        (v) => v.copyWith(volume: 0),
        newKeyframeId: 'k2',
      );
      t = t.extractAudio('a', newId: 'x', name: 'Sound');
      t = t.trimClip('a', ClipEdge.start, s(1.5));
      expectMatches(t, 'x');
    });
  });

  test('the shared table is up to date', () {
    final file = File('test_media/keyframe_cases.json');
    final table = const JsonEncoder.withIndent(' ').convert(_table());
    if (Platform.environment['UPDATE_KEYFRAME_CASES'] == '1') {
      file.writeAsStringSync('$table\n');
    }
    expect(
      file.readAsStringSync(),
      '$table\n',
      reason: 'Run with UPDATE_KEYFRAME_CASES=1 to rewrite it',
    );
  });
}
