import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/features/text/application/text_rendering.dart';
import 'package:stitch/features/timeline/domain/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('stitch_text'));
  tearDown(() => dir.deleteSync(recursive: true));

  Future<TextRaster> render(
    String text, {
    bool typewriter = false,
    TextStyleSpec style = const TextStyleSpec(),
  }) => PngTextRasterizer(dir).render(
    text: text,
    style: style,
    typewriter: typewriter,
    canvasWidth: 1080,
    canvasHeight: 1920,
  );

  test('draws a PNG at twice the canvas size, and caches it', () async {
    final first = await render('Hello');
    expect(first.paths, hasLength(1));
    final file = File(first.paths.single);
    expect(file.existsSync(), isTrue);

    final codec = await ui.instantiateImageCodec(await file.readAsBytes());
    final image = (await codec.getNextFrame()).image;
    // 5 percent of 1920 is 96 px per line; drawn at 2x.
    expect(image.height, closeTo(first.height * 2, 2));
    expect(first.height, greaterThan(96));

    final modified = file.lastModifiedSync();
    final again = await render('Hello');
    expect(again.paths, first.paths);
    expect(file.lastModifiedSync(), modified);
  });

  test('a typewriter gets a frame per step, at most 24', () async {
    expect((await render('Hi', typewriter: true)).paths, hasLength(2));
    final long = await render('A' * 60, typewriter: true);
    expect(long.paths, hasLength(TextRasterizer.maxTypewriterFrames));
  });

  test('a box and outline make the image bigger', () async {
    final plain = await render('Box');
    final boxed = await render(
      'Box',
      style: const TextStyleSpec(
        backgroundColor: 0xFF000000,
        strokeColor: 0xFF000000,
        strokeWidth: 0.08,
      ),
    );
    expect(boxed.width, greaterThan(plain.width));
    expect(boxed.height, greaterThan(plain.height));
  });

  test('redraws when pruning deleted a frame', () async {
    final raster = await render('Hi', typewriter: true);
    File(raster.paths.first).deleteSync();
    final again = await render('Hi', typewriter: true);
    expect(again.paths.every((p) => File(p).existsSync()), isTrue);
  });
}
