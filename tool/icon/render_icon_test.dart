// Draws the app icon masters. Run with tool/make_icons.sh, which resizes
// them for iOS and Android.
//
// The mark: two clips side by side, sewn together by three stitches in
// the accent color, on the app's background.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _background = Color(0xFF0B0B0C);
const _clip = Color(0xFFF2F2F3);
const _accent = Color(0xFF4C8DFF);

/// Paints the mark on a [side] x [side] canvas, scaled by [markScale]
/// (Android's adaptive icon keeps the mark inside a smaller safe zone).
void _paintMark(
  Canvas canvas,
  double side,
  double markScale, {
  bool fill = true,
}) {
  if (fill) {
    canvas.drawRect(
      Offset.zero & Size.square(side),
      Paint()..color = _background,
    );
  }
  canvas
    ..save()
    ..translate(side / 2, side / 2)
    ..scale(side / 1024 * markScale)
    ..translate(-512, -512);
  final clip = Paint()..color = _clip;
  const r = Radius.circular(44);
  canvas
    ..drawRRect(RRect.fromLTRBR(212, 302, 492, 722, r), clip)
    ..drawRRect(RRect.fromLTRBR(532, 302, 812, 722, r), clip);
  final stitch = Paint()..color = _accent;
  for (final y in [392.0, 512.0, 632.0]) {
    canvas.drawRRect(
      RRect.fromLTRBR(442, y - 16, 582, y + 16, const Radius.circular(8)),
      stitch,
    );
  }
  canvas.restore();
}

Future<void> _save(
  String path,
  double side,
  void Function(Canvas) paint,
) async {
  final recorder = ui.PictureRecorder();
  paint(Canvas(recorder));
  final image = await recorder.endRecording().toImage(
    side.toInt(),
    side.toInt(),
  );
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(png!.buffer.asUint8List());
}

void main() {
  test('render icon masters', () async {
    const out = String.fromEnvironment('ICON_OUT', defaultValue: 'build/icon');
    await _save('$out/icon_1024.png', 1024, (c) => _paintMark(c, 1024, 1));
    // Android adaptive foreground: 108 dp with the mark inside the 66 dp
    // safe zone, on transparent.
    await _save(
      '$out/foreground_432.png',
      432,
      (c) => _paintMark(c, 432, 66 / 108 * 1.1, fill: false),
    );
  });
}
