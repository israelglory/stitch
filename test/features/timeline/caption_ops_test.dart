import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/features/timeline/domain/caption_ops.dart';
import 'package:stitch/features/timeline/domain/composition.dart';
import 'package:stitch/features/timeline/domain/models.dart';
import 'package:stitch/features/timeline/domain/video_ops.dart';

import 'fixtures.dart';

RecognizedSegment seg(String id, num start, List<(String, num, num)> words) => (
  id: id,
  text: words.map((w) => w.$1).join(' '),
  startUs: s(start),
  endUs: s(words.last.$3),
  words: [
    for (final (text, from, to) in words)
      (text: text, startUs: s(from), endUs: s(to)),
  ],
);

void main() {
  final base = track([3, 3]).setCaptions([
    seg('1', 0.5, [('We', 0.5, 0.8), ('made', 0.8, 1.2), ('it', 1.2, 1.5)]),
    seg('2', 3.5, [('to', 3.5, 3.7), ('the', 3.7, 3.9), ('coast', 3.9, 4.6)]),
  ], language: 'en');

  test('setCaptions anchors segments and stores word offsets', () {
    expect(base.captionTrack.language, 'en');
    expect(base.startOfCaption('1'), s(0.5));
    expect(base.startOfCaption('2'), s(3.5));
    final s2 = base.captionById('2')!;
    expect((s2.anchor as ClipAnchor).clipId, 'b');
    expect(s2.durationUs, s(1.1));
    expect(s2.words.first.startOffsetUs, 0);
    expect(s2.words.last.endOffsetUs, s(1.1));
  });

  test('captions follow their speech when earlier clips change', () {
    final t = base.trimClip('a', ClipEdge.start, s(1));
    expect(t.startOfCaption('2'), s(2.5));
    // Segment 1 started at 0.5s, now trimmed away.
    final comp = ResolvedComposition.resolve(t);
    expect(comp.captions.map((c) => c.id), ['2']);
  });

  test('trimming back brings hidden captions back', () {
    final t = base
        .trimClip('a', ClipEdge.start, s(1))
        .trimClip('a', ClipEdge.start, -s(1));
    final comp = ResolvedComposition.resolve(t);
    expect(comp.captions.map((c) => c.id), ['1', '2']);
    expect(comp.captions.first.startUs, s(0.5));
  });

  group('edit text', () {
    test('same word count keeps word timing', () {
      final t = base.editCaptionText('1', 'We made et');
      final words = t.captionById('1')!.words;
      expect(words.map((w) => w.text), ['We', 'made', 'et']);
      expect(words[1].startOffsetUs, s(0.3));
    });

    test('a different word count spreads words evenly', () {
      final t = base.editCaptionText('1', 'We finally made it');
      final words = t.captionById('1')!.words;
      expect(words, hasLength(4));
      expect(words.first.startOffsetUs, 0);
      expect(words.last.endOffsetUs, s(1));
      expect(words[1].startOffsetUs, s(0.25));
    });

    test('unchanged text is a no-op', () {
      expect(
        identical(base.editCaptionText('1', ' We made it '), base),
        isTrue,
      );
    });
  });

  test('merge joins consecutive segments into the first', () {
    expect(base.canMergeCaptions('1', '2'), isTrue);
    expect(base.canMergeCaptions('2', '1'), isFalse);
    final t = base.mergeCaptions('1', '2');
    final merged = t.captionById('1')!;
    expect(t.captionTrack.segments, hasLength(1));
    expect(merged.text, 'We made it to the coast');
    expect(merged.durationUs, s(4.1));
    expect(merged.words[3].text, 'to');
    expect(merged.words[3].startOffsetUs, s(3));
  });

  test('split before a word', () {
    expect(base.canSplitCaption('2', 0), isFalse);
    expect(base.canSplitCaption('2', 3), isFalse);
    final t = base.splitCaption('2', 2, newId: '2b');
    expect(t.captionById('2')!.text, 'to the');
    expect(t.captionById('2b')!.text, 'coast');
    expect(t.startOfCaption('2b'), s(3.9));
    expect(t.captionById('2b')!.words.single.startOffsetUs, 0);
    expect(t.captionById('2')!.durationUs, s(0.4));
  });

  test('timing edits re-anchor and clamp words', () {
    final t = base.setCaptionTiming('2', s(4), s(4.5));
    expect(t.startOfCaption('2'), s(4));
    expect(t.captionById('2')!.durationUs, s(0.5));
    expect(
      t.captionById('2')!.words.every((w) => w.endOffsetUs <= s(0.5)),
      isTrue,
    );
  });

  test('trimming the start keeps words at their absolute times', () {
    final t = base.trimCaption('2', ClipEdge.start, s(0.2));
    expect(t.startOfCaption('2'), s(3.7));
    final words = t.captionById('2')!.words;
    expect(words[1].startOffsetUs, 0); // 'the' at 3.7s
    expect(words[2].startOffsetUs, s(0.2)); // 'coast' at 3.9s
  });

  test('composition gives absolute word times', () {
    final comp = ResolvedComposition.resolve(base);
    final coast = comp.captions.last.words.last;
    expect(coast.text, 'coast');
    expect(coast.startUs, s(3.9));
    expect(coast.endUs, s(4.6));
  });

  test('delete, clear, and style', () {
    expect(base.deleteCaption('1').captionTrack.segments, hasLength(1));
    expect(base.clearCaptions().captionTrack.segments, isEmpty);
    final styled = base.setCaptionStyle(
      preset: CaptionPreset.highlightWord,
      position: CaptionPosition.top,
    );
    expect(styled.captionTrack.preset, CaptionPreset.highlightWord);
    expect(styled.captionTrack.position, CaptionPosition.top);
    expect(identical(styled.setCaptionStyle(), styled), isTrue);
  });
}
