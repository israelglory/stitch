import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/features/timeline/domain/limits.dart';
import 'package:stitch/features/timeline/domain/models.dart';
import 'package:stitch/features/timeline/domain/text_ops.dart';
import 'package:stitch/features/timeline/domain/video_ops.dart';

import 'fixtures.dart';

void main() {
  final base = track([3, 3]);

  test('adds at a time with the default length', () {
    final t = base.addText(id: 't', text: 'Hi', atUs: s(4));
    expect(t.startOfText('t'), s(4));
    expect(t.textById('t')!.durationUs, TimelineLimits.textDurationUs);
    expect((t.textById('t')!.anchor as ClipAnchor).clipId, 'b');
  });

  test('overlapping items go to separate lanes', () {
    final t = base
        .addText(id: '1', text: 'a', atUs: 0, durationUs: s(2))
        .addText(id: '2', text: 'b', atUs: s(1), durationUs: s(2))
        .addText(id: '3', text: 'c', atUs: s(2.5), durationUs: s(1));
    expect(t.textById('1')!.laneIndex, 0);
    expect(t.textById('2')!.laneIndex, 1);
    expect(t.textById('3')!.laneIndex, 0);
  });

  test('update changes content but never timing', () {
    final t = base.addText(id: 't', text: 'Hi', atUs: s(1));
    final updated = t.updateText(
      't',
      (item) => item.copyWith(
        text: 'Hello',
        durationUs: 1,
        style: const TextStyleSpec(color: 0xFFFF0000),
      ),
    );
    expect(updated.textById('t')!.text, 'Hello');
    expect(updated.textById('t')!.style.color, 0xFFFF0000);
    expect(updated.textById('t')!.durationUs, TimelineLimits.textDurationUs);
  });

  test('move re-anchors, clamps into the video, and clears review', () {
    final flagged = base
        .addText(id: 't', text: 'Hi', atUs: s(3.5), durationUs: s(1))
        .deleteClip('b');
    expect(flagged.textById('t')!.needsReview, isTrue);

    final moved = flagged.moveText('t', s(1));
    expect(moved.startOfText('t'), s(1));
    expect(moved.textById('t')!.needsReview, isFalse);

    expect(
      base
          .addText(id: 't', text: 'x', atUs: 0)
          .moveText('t', -s(5))
          .startOfText('t'),
      0,
    );
    final late = base.addText(id: 't', text: 'x', atUs: 0).moveText('t', s(99));
    expect(late.startOfText('t'), s(6) - TimelineLimits.minDurationUs);
  });

  test('trim start keeps the end; trim end keeps the start', () {
    final t = base.addText(id: 't', text: 'Hi', atUs: s(1), durationUs: s(2));
    final fromStart = t.trimText('t', ClipEdge.start, s(0.5));
    expect(fromStart.startOfText('t'), s(1.5));
    expect(fromStart.textById('t')!.durationUs, s(1.5));

    final fromEnd = t.trimText('t', ClipEdge.end, s(1));
    expect(fromEnd.startOfText('t'), s(1));
    expect(fromEnd.textById('t')!.durationUs, s(3));
  });

  test('trim respects the minimum length and the video end', () {
    final t = base.addText(id: 't', text: 'Hi', atUs: s(1), durationUs: s(2));
    expect(
      t.trimText('t', ClipEdge.start, s(10)).textById('t')!.durationUs,
      TimelineLimits.minDurationUs,
    );
    expect(
      t.trimText('t', ClipEdge.end, s(100)).textById('t')!.durationUs,
      s(5),
    );
    expect(t.trimText('t', ClipEdge.start, -s(100)).startOfText('t'), 0);
  });

  test('split makes two consecutive items', () {
    final t = base
        .addText(id: 't', text: 'Hi', atUs: s(1), durationUs: s(2))
        .splitText('t', s(2), newId: 't2');
    expect(t.textById('t')!.durationUs, s(1));
    expect(t.startOfText('t2'), s(2));
    expect(t.textById('t2')!.durationUs, s(1));
    expect(t.textById('t2')!.laneIndex, t.textById('t')!.laneIndex);
    expect(base.canSplitText('t', s(2)), isFalse);
  });

  test('duplicate lands on the next lane at the same time', () {
    final t = base
        .addText(id: 't', text: 'Hi', atUs: s(1))
        .duplicateText('t', newId: 'copy');
    expect(t.startOfText('copy'), s(1));
    expect(t.textById('copy')!.laneIndex, 1);
  });

  test('delete removes the item', () {
    final t = base.addText(id: 't', text: 'Hi', atUs: 0).deleteText('t');
    expect(t.textItems, isEmpty);
    expect(identical(t.deleteText('t'), t), isTrue);
  });

  test('lanes repack when a clip edit creates an overlap', () {
    // Two items on lane 0 anchored to different clips, 1s apart.
    final t = base
        .addText(id: '1', text: 'a', atUs: s(1), durationUs: s(1.5))
        .addText(id: '2', text: 'b', atUs: s(3), durationUs: s(1));
    expect(t.textById('2')!.laneIndex, 0);
    // Trimming 1s off clip a pulls item 2 left onto item 1.
    final trimmed = t.trimClip('a', ClipEdge.end, -s(1));
    expect(trimmed.textById('1')!.laneIndex, 0);
    expect(trimmed.textById('2')!.laneIndex, 1);
  });
}
