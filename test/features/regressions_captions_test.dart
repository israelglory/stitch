// Regression tests for the caption and audio fixes found in the MVP review.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/core/storage/cache_pruning.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/features/captions/application/caption_providers.dart';
import 'package:stitch/features/captions/application/caption_rendering.dart';
import 'package:stitch/features/captions/data/caption_models.dart';
import 'package:stitch/features/captions/domain/transcript.dart';
import 'package:stitch/features/text/application/text_rendering.dart';
import 'package:stitch/features/timeline/domain/caption_ops.dart';
import 'package:stitch/features/timeline/domain/composition.dart';
import 'package:stitch/features/timeline/domain/models.dart';
import 'package:stitch/features/timeline/domain/video_ops.dart';

import '../helpers/app_scope.dart';
import '../helpers/fake_captions.dart';
import '../helpers/fake_text_rasterizer.dart';
import 'timeline/fixtures.dart';

/// Fails for the caption text [failing]; draws the rest.
class _FlakyRasterizer extends FakeTextRasterizer {
  new(this.failing);

  final String failing;

  @override
  Future<TextRaster> render({
    required String text,
    required TextStyleSpec style,
    required bool typewriter,
    required int canvasWidth,
    required int canvasHeight,
    double wrapFraction = textWrapFraction,
    TextHighlight? highlight,
  }) {
    if (text == failing) return Future.error(StateError('no'));
    return super.render(
      text: text,
      style: style,
      typewriter: typewriter,
      canvasWidth: canvasWidth,
      canvasHeight: canvasHeight,
      wrapFraction: wrapFraction,
      highlight: highlight,
    );
  }
}

Timeline _withCaption(Timeline t, {String? language}) => t.setCaptions([
  (
    id: 'c',
    text: 'One two',
    startUs: s(2),
    endUs: s(4),
    words: [
      (text: 'One', startUs: s(2), endUs: s(3)),
      (text: 'two', startUs: s(3), endUs: s(4)),
    ],
  ),
], language: language);

void main() {
  test('captions follow their clip speeding up', () {
    final base = _withCaption(track([10]));
    final fast = base.setClipSpeed('a', 2);
    final caption = fast.captionById('c')!;
    expect(fast.startOfCaption('c'), s(1));
    expect(caption.durationUs, s(1));
    expect(caption.words.map((w) => w.startOffsetUs), [0, s(0.5)]);
  });

  test('captions never run into the next one', () {
    final transcript = Transcript(
      language: 'en',
      segments: [
        [
          token(' First.', 0, 1500),
          // Whisper's end times can overlap the next word.
          token(' Second', 1200, 1800),
        ],
      ],
    );
    final captions = transcript.captions(newId: () => 'x');
    expect(captions, hasLength(2));
    expect(captions[0].endUs, lessThanOrEqualTo(captions[1].startUs));
  });

  group('languages without spaces', () {
    test('merge and split add no spaces', () {
      final t = track([10])
          .setCaptions([
            (id: 'a', text: 'こんにちは', startUs: 0, endUs: s(1), words: const []),
            (id: 'b', text: '世界', startUs: s(1), endUs: s(2), words: const []),
          ], language: 'ja')
          .mergeCaptions('a', 'b');
      expect(t.captionById('a')!.text, 'こんにちは世界');
    });

    test('a typo fix keeps word timings', () {
      final t = track([10]).setCaptions([
        (
          id: 'a',
          text: 'こんにちは世界',
          startUs: 0,
          endUs: s(2),
          words: [
            (text: 'こんにちは', startUs: 0, endUs: s(1)),
            (text: '世界', startUs: s(1), endUs: s(2)),
          ],
        ),
      ], language: 'ja');
      final edited = t.editCaptionText('a', 'こんばんは世界');
      final words = edited.captionById('a')!.words;
      expect(words.map((w) => w.text), ['こんばんは', '世界']);
      expect(words[1].startOffsetUs, s(1));
    });
  });

  test('one caption that cannot be drawn leaves the others', () async {
    final t = track([10]).setCaptions([
      (id: 'a', text: 'Good', startUs: 0, endUs: s(1), words: const []),
      (id: 'b', text: 'Bad', startUs: s(1), endUs: s(2), words: const []),
    ]);
    final images = await renderCaptions(
      _FlakyRasterizer('Bad'),
      ResolvedComposition.resolve(t),
      canvasWidth: 1080,
      canvasHeight: 1920,
    );
    expect(images.map((i) => i.id), ['a#0']);
  });

  test('leftovers of interrupted work are cleared at startup', () async {
    final cache = Directory.systemTemp.createTempSync('leftovers');
    addTearDown(() => cache.deleteSync(recursive: true));
    final speech = File('${cache.path}/speech/p.f32')
      ..createSync(recursive: true);
    final part = File('${cache.path}/exports/a.part.mp4')
      ..createSync(recursive: true);
    final kept = File('${cache.path}/exports/done.mp4')..createSync();
    final model = File('${cache.path}/models/m.bin')
      ..createSync(recursive: true);
    await removeLeftovers(cache);
    expect(speech.existsSync(), isFalse);
    expect(part.existsSync(), isFalse);
    expect(kept.existsSync(), isTrue);
    expect(model.existsSync(), isTrue);
  });

  test('asking twice for a model downloads it once', () async {
    final env = await TestEnv.create();
    final models = env.container.read(captionModelsProvider.notifier);
    await Future.wait([
      models.download(CaptionModel.tiny),
      models.download(CaptionModel.tiny),
    ]);
    expect(env.models.downloads, [CaptionModel.tiny.fileName]);
  });
}
