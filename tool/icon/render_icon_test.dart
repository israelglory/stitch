// Builds the app icon masters from assets/light.png and assets/dark.png.
// Run with tool/make_icons.sh, which puts them in place for iOS and
// Android.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Android's adaptive icon is 108 dp, of which a launcher shows about the
/// middle 72 dp. The artwork fills those 72 dp, so it looks the same size
/// as on iOS and stays inside the 66 dp safe zone.
const double _adaptiveVisible = 72 / 108;

/// Side of the splash artwork square, in logical pixels. Matches
/// `AppSizes.splashLogo`.
const double _splashLogoSize = 160;

Future<ui.Image> _load(String path) async {
  final codec = await ui.instantiateImageCodec(File(path).readAsBytesSync());
  return (await codec.getNextFrame()).image;
}

/// The top left pixel, as #RRGGBB.
Future<String> _corner(ui.Image image) async {
  final data = (await image.toByteData())!;
  final rgb = [
    for (var i = 0; i < 3; i++)
      data.getUint8(i).toRadixString(16).padLeft(2, '0'),
  ];
  return '#${rgb.join().toUpperCase()}';
}

Future<void> _save(
  String path,
  int side,
  void Function(Canvas canvas, Rect bounds) paint,
) async {
  final recorder = ui.PictureRecorder();
  paint(Canvas(recorder), Offset.zero & Size.square(side.toDouble()));
  final image = await recorder.endRecording().toImage(side, side);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(png!.buffer.asUint8List());
}

void _draw(Canvas canvas, ui.Image image, Rect to, [Paint? paint]) {
  canvas.drawImageRect(
    image,
    Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
    to,
    (paint ?? Paint())..filterQuality = FilterQuality.high,
  );
}

/// Draws the white-on-black artwork as just its letters in [color], on
/// transparent: brightness becomes coverage.
Paint _letters(Color color) => Paint()
  ..colorFilter = ColorFilter.matrix([
    0, 0, 0, 0, color.r * 255, //
    0, 0, 0, 0, color.g * 255,
    0, 0, 0, 0, color.b * 255,
    0.2126, 0.7152, 0.0722, 0, 0,
  ]);

void main() {
  test('render icon masters', () async {
    const out = String.fromEnvironment('ICON_OUT', defaultValue: 'build/icon');
    final light = await _load('assets/light.png');
    final dark = await _load('assets/dark.png');

    // iOS: full squares; the system rounds the corners.
    await _save('$out/ios_light.png', 1024, (c, b) => _draw(c, light, b));
    await _save('$out/ios_dark.png', 1024, (c, b) => _draw(c, dark, b));

    // Android adaptive foregrounds: the letters alone, on transparent,
    // over a background color.
    Rect artwork(Rect b) => Rect.fromCenter(
      center: b.center,
      width: b.width * _adaptiveVisible,
      height: b.height * _adaptiveVisible,
    );
    await _save('$out/android_foreground_light.png', 432, (c, b) {
      _draw(c, dark, artwork(b), _letters(const Color(0xFF000000)));
    });
    await _save('$out/android_foreground_dark.png', 432, (c, b) {
      _draw(c, dark, artwork(b), _letters(const Color(0xFFFFFFFF)));
    });

    // Splash logo: the artwork square at `_splashLogoSize` logical pixels,
    // letters only, per scale. The same images serve Flutter, iOS, and
    // Android before 12.
    for (final (name, ink) in [
      ('light', const Color(0xFF000000)),
      ('dark', const Color(0xFFFFFFFF)),
    ]) {
      for (final scale in [1, 2, 3, 4]) {
        await _save(
          '$out/splash_${name}_${scale}x.png',
          (_splashLogoSize * scale).round(),
          (c, b) => _draw(c, dark, b, _letters(ink)),
        );
      }
      // Android 12 and later draw the splash icon in a 288 dp box (masked
      // to a 192 dp circle); the artwork keeps its size in the middle.
      await _save('$out/splash_${name}_android12.png', 288 * 4, (c, b) {
        final logo = Rect.fromCenter(
          center: b.center,
          width: _splashLogoSize * 4,
          height: _splashLogoSize * 4,
        );
        _draw(c, dark, logo, _letters(ink));
      });
    }

    File('$out/backgrounds.txt')
        .writeAsStringSync('${await _corner(light)} ${await _corner(dark)}\n');
  });
}
