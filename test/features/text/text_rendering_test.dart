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

  test('zoomed text is drawn with more pixels, within limits', () async {
    Future<int> heightAt(double zoom, {String text = 'Zoom'}) async {
      final raster = await PngTextRasterizer(dir).render(
        text: text,
        style: const TextStyleSpec(),
        typewriter: false,
        canvasWidth: 1080,
        canvasHeight: 1920,
        zoom: zoom,
      );
      final bytes = await File(raster.paths.single).readAsBytes();
      final image = (await (await ui.instantiateImageCodec(
        bytes,
      )).getNextFrame()).image;
      return (image.height / raster.height).round();
    }

    expect(await heightAt(1), 2);
    expect(await heightAt(1.6), 4);
    expect(await heightAt(8), 8, reason: 'at most four times the detail');
    expect(
      PngTextRasterizer.detailFor(8, typewriter: true),
      PngTextRasterizer.maxTypewriterDetail,
    );
    // Long text stays within the GPU's texture size.
    final raster = await PngTextRasterizer(dir).render(
      text: 'A long line of text ' * 12,
      style: const TextStyleSpec(),
      typewriter: false,
      canvasWidth: 1080,
      canvasHeight: 1920,
      zoom: 8,
    );
    final bytes = await File(raster.paths.single).readAsBytes();
    final image = (await (await ui.instantiateImageCodec(
      bytes,
    )).getNextFrame()).image;
    expect(
      image.width > image.height ? image.width : image.height,
      lessThanOrEqualTo(PngTextRasterizer.maxImageSide + 1),
    );
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
