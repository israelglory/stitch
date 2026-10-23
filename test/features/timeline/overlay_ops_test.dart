import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/features/timeline/domain/composition.dart';
import 'package:stitch/features/timeline/domain/keyframes.dart';
import 'package:stitch/features/timeline/domain/models.dart';
import 'package:stitch/features/timeline/domain/overlay_ops.dart';
import 'package:stitch/features/timeline/domain/video_ops.dart';

import 'fixtures.dart';

OverlaySource video(String id, num seconds) => (
  id: id,
  mediaId: 'm-$id',
  kind: MediaKind.video,
  mediaDurationUs: s(seconds),
);

OverlaySource photo(String id) =>
    (id: id, mediaId: 'm-$id', kind: MediaKind.photo, mediaDurationUs: null);

extension on Timeline {
  int startOfOverlay(String id) => layout.startOf(overlayById(id)!.anchor);
}

void main() {
  group('adding', () {
    test('at the playhead, smaller than the frame, on the first lane', () {
      final t = track([4, 6]).addOverlays([video('o', 3)], atUs: s(2));
      final o = t.overlayById('o')!;
      expect(t.startOfOverlay('o'), s(2));
      expect(o.durationUs, s(3));
      expect(o.laneIndex, 0);
      expect(o.framing.scale, newOverlayScale);
      // Anchored into the clip under it.
      expect(o.anchor, const Anchor.clip(clipId: 'a', sourceUs: 2000000));
    });

    test('several go one after another; photos last 3 s', () {
      final t = track([20])
          .addOverlays([video('a', 2), photo('b')], atUs: s(1));
      expect(t.startOfOverlay('a'), s(1));
      expect(t.startOfOverlay('b'), s(3));
      expect(t.overlayById('b')!.durationUs, s(3));
      expect(t.overlayById('b')!.mediaDurationUs, isNull);
    });

    test('over another one, it goes on the next lane up', () {
      final t = track([20])
          .addOverlays([video('a', 5)], atUs: 0)
          .addOverlays([video('b', 5)], atUs: s(2));
      expect(t.overlayById('a')!.laneIndex, 0);
      expect(t.overlayById('b')!.laneIndex, 1);
      expect(t.overlayLaneCount, 2);
      // Clear of it, back on the first.
      final later = t.addOverlays([video('c', 1)], atUs: s(12));
      expect(later.overlayById('c')!.laneIndex, 0);
    });

    test('starts inside the video', () {
      final t = track([4]).addOverlays([video('o', 3)], atUs: s(10));
      expect(t.startOfOverlay('o'), lessThan(s(4)));
    });
  });

  group('editing', () {
    final base = track([10, 10]).addOverlays([video('o', 6)], atUs: s(2));

    test('moves with the content it is anchored to', () {
      final t = base.trimClip('a', ClipEdge.start, s(1));
      expect(t.startOfOverlay('o'), s(1));
    });

    test('moves in time', () {
      final t = base.moveOverlay('o', s(12));
      expect(t.startOfOverlay('o'), s(12));
      expect(t.overlayById('o')!.anchor, isA<ClipAnchor>());
    });

    test('trims at either end', () {
      final start = base.trimOverlay('o', ClipEdge.start, s(1));
      expect(start.startOfOverlay('o'), s(3));
      expect(start.overlayById('o')!.sourceInUs, s(1));
      final end = base.trimOverlay('o', ClipEdge.end, -s(2));
      expect(end.overlayById('o')!.durationUs, s(4));
      // Not past the end of its file.
      final past = base.trimOverlay('o', ClipEdge.end, s(30));
      expect(past.overlayById('o')!.sourceOutUs, s(6));
    });

    test('a photo trims longer, up to the end of the video', () {
      final t = track([10]).addOverlays([photo('p')], atUs: s(1));
      final longer = t.trimOverlay('p', ClipEdge.end, s(30));
      expect(longer.overlayById('p')!.durationUs, s(9));
    });

    test('splits at the playhead, each part keeping its keyframes', () {
      const owner = (kind: KeyframeOwnerKind.overlay, id: 'o');
      final keyed = base
          .addKeyframe(owner, s(3), id: 'k1')
          .addKeyframe(owner, s(7), id: 'k2');
      expect(keyed.canSplitOverlay('o', s(5)), isTrue);
      final t = keyed.splitOverlay('o', s(5), newId: 'o2');
      expect(t.overlayById('o')!.durationUs, s(3));
      expect(t.startOfOverlay('o2'), s(5));
      expect(t.overlayById('o2')!.sourceInUs, s(3));
      expect(t.overlayById('o')!.keyframes.map((k) => k.id), ['k1', 'k2']);
      expect(t.overlayById('o2')!.keyframes.map((k) => k.id), ['k1', 'k2']);
      expect(t.overlayById('o2')!.laneIndex, 0);
    });

    test('duplicates right after itself', () {
      final t = base.duplicateOverlay('o', newId: 'copy');
      expect(t.startOfOverlay('copy'), s(8));
      expect(t.overlayById('copy')!.laneIndex, 0);
    });

    test('speed changes its length; volume is clamped', () {
      final t = base.setOverlaySpeed('o', 2).setOverlayVolume('o', 5);
      expect(t.overlayById('o')!.durationUs, s(3));
      expect(t.overlayById('o')!.volume, 2);
    });

    test('keyframes move, zoom, and fade it like a clip', () {
      const owner = (kind: KeyframeOwnerKind.overlay, id: 'o');
      final t = base
          .addKeyframe(owner, s(2), id: 'k1')
          .setValuesAt(
            owner,
            s(6),
            (v) => v.copyWith(x: 0.25, opacity: 0.5),
            newKeyframeId: 'k2',
          );
      final mid = t.valuesAt(owner, s(4))!;
      expect(mid.x, closeTo(0.125, 1e-9));
      expect(mid.opacity, closeTo(0.75, 1e-9));
      expect(mid.scale, newOverlayScale);
    });

    test('deleting its clip keeps it in place, flagged', () {
      final t = base.deleteClip('a');
      expect(t.overlayById('o')!.needsReview, isTrue);
      expect(t.overlayById('o')!.anchor, isA<ClipAnchor>());
    });

    test('relinking its file points it at the new one', () {
      final t = base.relinkMedia(
        'm-o',
        toMediaId: 'new',
        mediaDurationUs: s(4),
      );
      expect(t.overlayById('o')!.mediaId, 'new');
      expect(t.overlayById('o')!.sourceOutUs, s(4));
    });

    test('deletes', () {
      expect(base.deleteOverlay('o').overlayClips, isEmpty);
    });
  });

  group('for the engines', () {
    test('resolved by lane, cut at the end of the video', () {
      final t = track([5])
          .addOverlays([video('a', 4)], atUs: s(2))
          .addOverlays([video('b', 2)], atUs: 0)
          .setAudioMixForTest(originalLevel: 0.5);
      final c = ResolvedComposition.resolve(t);
      expect(c.overlayClips.map((o) => o.id), ['b', 'a']);
      final a = c.overlayClips.last;
      expect(a.startUs, s(2));
      expect(a.endUs, s(5));
      expect(a.sourceOutUs, s(3));
      expect(a.laneIndex, 0);
      expect(a.volume, 0.5);
      expect(c.overlayClips.first.laneIndex, 0);
    });

    test('photos are silent; keyframes are on the timeline', () {
      const owner = (kind: KeyframeOwnerKind.overlay, id: 'p');
      final t = track([10])
          .addOverlays([photo('p')], atUs: s(4))
          .addKeyframe(owner, s(5), id: 'k');
      final p = ResolvedComposition.resolve(t).overlayClips.single;
      expect(p.volume, 0);
      expect(p.keyframes.single.timeUs, s(5));
      expect(p.keyframes.single.values.volume, 0);
    });

    test('an overlay after the end of the video is left out', () {
      final t = track([4])
          .addOverlays([video('o', 2)], atUs: s(1))
          .trimClip('a', ClipEdge.end, -s(3));
      expect(ResolvedComposition.resolve(t).overlayClips, isEmpty);
    });

    test('older projects load without overlays', () {
      final json = track([1]).toJson()..remove('overlayClips');
      expect(Timeline.fromJson(json).overlayClips, isEmpty);
    });
  });
}

extension on Timeline {
  Timeline setAudioMixForTest({required double originalLevel}) =>
      copyWith(audioMix: audioMix.copyWith(originalLevel: originalLevel));
}
