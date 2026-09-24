import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/features/timeline/domain/audio_ops.dart';
import 'package:stitch/features/timeline/domain/caption_ops.dart';
import 'package:stitch/features/timeline/domain/models.dart';
import 'package:stitch/features/timeline/domain/snapping.dart';
import 'package:stitch/features/timeline/domain/text_ops.dart';

import 'fixtures.dart';

void main() {
  group('scale', () {
    test('converts between time and pixels', () {
      const scale = TimelineScale(100);
      expect(scale.usToPx(s(2)), 200);
      expect(scale.pxToUs(50), s(0.5));
    });

    test('zoom is clamped', () {
      const scale = TimelineScale(64);
      expect(
        scale.zoomed(100).pixelsPerSecond,
        TimelineScale.maxPixelsPerSecond,
      );
      expect(
        scale.zoomed(0.001).pixelsPerSecond,
        TimelineScale.minPixelsPerSecond,
      );
    });
  });

  group('snap', () {
    test('pulls to the nearest target within the pixel threshold', () {
      final r = snap(s(1.05), [s(1), s(2)], scale: const TimelineScale(100));
      expect(r.snapped, isTrue);
      expect(r.timeUs, s(1));
    });

    test('leaves the time alone when nothing is close', () {
      final r = snap(s(1.5), [s(1), s(2)], scale: const TimelineScale(100));
      expect(r.snapped, isFalse);
      expect(r.timeUs, s(1.5));
    });

    test('the same gap snaps when zoomed out but not when zoomed in', () {
      // 0.1s is 2px at 20px/s but 20px at 200px/s; threshold is 8px.
      expect(
        snap(s(1.1), [s(1)], scale: const TimelineScale(20)).snapped,
        isTrue,
      );
      expect(
        snap(s(1.1), [s(1)], scale: const TimelineScale(200)).snapped,
        isFalse,
      );
    });
  });

  test('targets cover playhead, cuts, and item edges, minus excluded', () {
    final t = track([2, 3])
        .addText(id: 'x', text: 'a', atUs: s(0.5), durationUs: s(1))
        .addText(id: 'y', text: 'b', atUs: s(3), durationUs: s(1));
    final targets = snapTargets(t, playheadUs: s(4.2), excludeIds: {'y'});
    expect(targets, containsAll(<int>[0, s(2), s(5), s(4.2), s(0.5), s(1.5)]));
    expect(targets.contains(s(3)), isFalse);
  });

  test('targets include caption and audio edges', () {
    final t = track([5])
        .setCaptions([
          (id: 'c', text: 'hi', startUs: s(1), endUs: s(1.7), words: []),
        ])
        .addAudio(
          id: 'm',
          mediaId: 'song',
          kind: AudioKind.music,
          name: 'Song',
          mediaDurationUs: s(2),
          atUs: s(2.5),
        );
    final targets = snapTargets(t, playheadUs: 0);
    expect(targets, containsAll(<int>[s(1), s(1.7), s(2.5), s(4.5)]));
  });
}
