import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/features/timeline/domain/keyframes.dart';
import 'package:stitch/features/timeline/domain/limits.dart';
import 'package:stitch/features/timeline/domain/models.dart';
import 'package:stitch/features/timeline/domain/text_ops.dart';
import 'package:stitch/features/timeline/domain/video_ops.dart';

import 'fixtures.dart';

const KeyframeOwner _a = (kind: KeyframeOwnerKind.clip, id: 'a');
const KeyframeOwner _b = (kind: KeyframeOwnerKind.clip, id: 'b');

/// Zoom from 1 at 1 s to 3 at 3 s of clip a's content.
Timeline _zooming({KeyframeEasing easing = KeyframeEasing.linear}) {
  var t = track([4, 4]);
  t = t.addKeyframe(_a, s(1), id: 'k1');
  t = t.setValuesAt(_a, s(3), (v) => v.copyWith(scale: 3), newKeyframeId: 'k2');
  return t.setKeyframeEasing(_a, 'k1', easing);
}

void main() {
  group('easing', () {
    test('every curve starts at 0 and ends at 1, except hold', () {
      for (final e in KeyframeEasing.values) {
        expect(easeProgress(e, 0), closeTo(0, 1e-9), reason: e.name);
        if (e == KeyframeEasing.hold) {
          expect(easeProgress(e, 0.99), 0);
        } else {
          expect(easeProgress(e, 1), closeTo(1, 1e-9), reason: e.name);
          expect(easeProgress(e, 0.5), inInclusiveRange(0, 1));
        }
      }
      expect(easeProgress(KeyframeEasing.easeIn, 0.5), lessThan(0.5));
      expect(easeProgress(KeyframeEasing.easeOut, 0.5), greaterThan(0.5));
      expect(easeProgress(KeyframeEasing.easeInOut, 0.5), closeTo(0.5, 1e-9));
    });
  });

  group('values over time', () {
    test('without keyframes the item keeps its own values', () {
      final t = track([4]);
      expect(t.valuesAt(_a, s(2))!.scale, 1);
      expect(t.keyframesOf(_a), isEmpty);
    });

    test('between keyframes values move; outside they hold', () {
      final t = _zooming();
      expect(t.keyframesOf(_a).map((k) => k.timeUs), [s(1), s(3)]);
      expect(t.valuesAt(_a, s(0.5))!.scale, 1);
      expect(t.valuesAt(_a, s(2))!.scale, closeTo(2, 1e-9));
      expect(t.valuesAt(_a, s(3.5))!.scale, 3);
    });

    test('easing shapes the way between keyframes', () {
      final eased = _zooming(easing: KeyframeEasing.easeIn);
      expect(eased.valuesAt(_a, s(2))!.scale, closeTo(1 + 2 * 0.125, 1e-9));
      final held = _zooming(easing: KeyframeEasing.hold);
      expect(held.valuesAt(_a, s(2.9))!.scale, 1);
      expect(held.valuesAt(_a, s(3))!.scale, 3);
    });

    test('many keyframes are looked up correctly', () {
      var t = track([10]);
      for (var i = 0; i <= 9; i++) {
        t = t.setValuesAt(
          _a,
          s(i),
          (v) => v.copyWith(opacity: i.isEven ? 1 : 0),
          newKeyframeId: 'k$i',
        );
        if (i == 0) t = t.addKeyframe(_a, s(0), id: 'k0');
      }
      expect(t.keyframesOf(_a), hasLength(10));
      expect(t.valuesAt(_a, s(6.5))!.opacity, closeTo(0.5, 1e-9));
      expect(t.valuesAt(_a, s(7))!.opacity, 0);
    });
  });

  group('editing', () {
    test('a keyframe holds the values at the playhead', () {
      final t = _zooming().addKeyframe(_a, s(2), id: 'k3');
      final k = t.keyframesOf(_a).firstWhere((k) => k.id == 'k3');
      expect(k.values.scale, closeTo(2, 1e-9));
    });

    test('no two keyframes closer than a frame', () {
      final t = _zooming();
      expect(identical(t.addKeyframe(_a, s(1) + 10000, id: 'x'), t), isTrue);
      expect(t.keyframeAt(_a, s(1) + 10000)?.id, 'k1');
      expect(t.keyframeAt(_a, s(1.5)), isNull);
    });

    test('changing a value records a keyframe once there are any', () {
      // No keyframes: the item's own value changes, nothing is recorded.
      final plain = track([4]).setValuesAt(
        _a,
        s(2),
        (v) => v.copyWith(opacity: 0.5),
        newKeyframeId: 'n',
      );
      expect(plain.clipById('a')!.opacity, 0.5);
      expect(plain.keyframesOf(_a), isEmpty);

      // With keyframes: on one, it changes; between, a new one appears.
      final t = _zooming()
          .setValuesAt(
            _a,
            s(1),
            (v) => v.copyWith(scale: 1.5),
            newKeyframeId: 'x',
          )
          .setValuesAt(
            _a,
            s(2),
            (v) => v.copyWith(opacity: 0.25),
            newKeyframeId: 'k4',
          );
      expect(t.keyframesOf(_a).map((k) => k.id), ['k1', 'k4', 'k2']);
      expect(t.keyframesOf(_a).first.values.scale, 1.5);
      expect(t.valuesAt(_a, s(2))!.opacity, 0.25);
      expect(t.clipById('a')!.opacity, 1, reason: 'own value untouched');
    });

    test('the playhead is on a keyframe wherever another cannot go', () {
      final t = _zooming();
      // A frame time a little off the keyframe (players report those).
      for (final off in [-30000, -20000, 20000, 33332]) {
        final at = s(1) + off;
        expect(t.keyframeAt(_a, at)?.id, 'k1', reason: 'at $off');
        expect(identical(t.addKeyframe(_a, at, id: 'x'), t), isTrue);
      }
      expect(t.keyframeAt(_a, s(1) + 33334), isNull);
      expect(
        t.addKeyframe(_a, s(1) + 33334, id: 'x').keyframesOf(_a),
        hasLength(3),
      );
    });

    test('values stay within limits', () {
      final t = track([4]).setValuesAt(
        _a,
        s(1),
        (v) => v.copyWith(scale: 100, opacity: -1, volume: 9),
        newKeyframeId: 'n',
      );
      final v = t.valuesAt(_a, s(1))!;
      expect(v.scale, TimelineLimits.maxScale);
      expect(v.opacity, 0);
      expect(v.volume, TimelineLimits.maxVolume);
    });

    test('removing the last keyframe keeps its values', () {
      final t = _zooming().removeKeyframe(_a, 'k1').removeKeyframe(_a, 'k2');
      expect(t.keyframesOf(_a), isEmpty);
      expect(t.clipById('a')!.framing.scale, 3);
    });

    test('easing is set per keyframe', () {
      final t = _zooming().setKeyframeEasing(_a, 'k2', KeyframeEasing.easeOut);
      expect(t.keyframesOf(_a).last.easing, KeyframeEasing.easeOut);
      expect(
        identical(t.setKeyframeEasing(_a, 'k2', KeyframeEasing.easeOut), t),
        isTrue,
      );
    });
  });

  group('keyframes follow their content', () {
    /// Values at every 100 ms of clip a's content, keyed by source time.
    Map<int, double> scaleByContent(Timeline t) => {
      for (final clip in t.videoClips)
        if (clip.mediaId == 'media-a')
          for (var us = clip.sourceInUs; us <= clip.sourceOutUs; us += s(0.1))
            us: t.valuesAt(
              (kind: KeyframeOwnerKind.clip, id: clip.id),
              t.timelineTimeOfKeyframe((
                kind: KeyframeOwnerKind.clip,
                id: clip.id,
              ), us)!,
            )!.scale,
    };

    test('through a split', () {
      final before = scaleByContent(_zooming());
      final split = _zooming().splitClip('a', s(2), newId: 'a2');
      final after = scaleByContent(split);
      for (final MapEntry(key: us, value: scale) in after.entries) {
        expect(scale, closeTo(before[us]!, 1e-9), reason: 'at $us');
      }
      // Each part keeps only what shapes it.
      expect(split.clipById('a')!.keyframes, hasLength(2));
      expect(split.clipById('a2')!.keyframes, hasLength(2));
    });

    test('through a trim and a speed change', () {
      final before = scaleByContent(_zooming());
      final edited = _zooming()
          .trimClip('a', ClipEdge.start, s(0.5))
          .setClipSpeed('a', 2);
      final after = scaleByContent(edited);
      for (final MapEntry(key: us, value: scale) in after.entries) {
        expect(scale, closeTo(before[us]!, 1e-9), reason: 'at $us');
      }
      // Twice as fast: the zoom takes one second of the timeline.
      final k = edited.keyframesOf(_a);
      final from = edited.timelineTimeOfKeyframe(_a, k.first.timeUs)!;
      final to = edited.timelineTimeOfKeyframe(_a, k.last.timeUs)!;
      expect(to - from, s(1));
    });

    test('other clips are not affected', () {
      expect(_zooming().keyframesOf(_b), isEmpty);
      expect(_zooming().valuesAt(_b, s(5))!.scale, 1);
    });
  });

  group('text', () {
    const owner = (kind: KeyframeOwnerKind.text, id: 't');

    Timeline fading() {
      var t = track([10]).addText(id: 't', text: 'Hi', atUs: s(2));
      t = t.addKeyframe(owner, s(2), id: 'k1');
      return t.setValuesAt(
        owner,
        s(4),
        (v) => v.copyWith(opacity: 0),
        newKeyframeId: 'k2',
      );
    }

    test('keyframes count from the item start', () {
      final t = fading();
      expect(t.keyframesOf(owner).map((k) => k.timeUs), [0, s(2)]);
      expect(t.valuesAt(owner, s(3))!.opacity, closeTo(0.5, 1e-9));
    });

    test('a trimmed start keeps them at the same moments', () {
      final t = fading().trimText('t', ClipEdge.start, s(0.5));
      expect(t.startOfText('t'), s(2.5));
      expect(t.valuesAt(owner, s(3))!.opacity, closeTo(0.5, 1e-9));
    });

    test('a split keeps the fade on both parts', () {
      final before = fading();
      final split = fading().splitText('t', s(3), newId: 't2');
      const second = (kind: KeyframeOwnerKind.text, id: 't2');
      expect(
        split.valuesAt(owner, s(2.5))!.opacity,
        closeTo(before.valuesAt(owner, s(2.5))!.opacity, 1e-9),
      );
      expect(
        split.valuesAt(second, s(3.5))!.opacity,
        closeTo(before.valuesAt(owner, s(3.5))!.opacity, 1e-9),
      );
    });
  });

  test('keyframes survive saving; older projects load without them', () {
    final t = _zooming(easing: KeyframeEasing.easeInOut);
    final back = Timeline.fromJson(
      jsonDecode(jsonEncode(t.toJson())) as Map<String, dynamic>,
    );
    expect(back, t);

    final old = track([4]).toJson();
    final clips = (old['videoClips'] as List).cast<Map<String, dynamic>>();
    for (final c in clips) {
      c
        ..remove('keyframes')
        ..remove('opacity');
    }
    final loaded = Timeline.fromJson(
      jsonDecode(jsonEncode(old)) as Map<String, dynamic>,
    );
    expect(loaded.clipById('a')!.keyframes, isEmpty);
    expect(loaded.clipById('a')!.opacity, 1);
  });
}
