// Renders every transition with its Flutter shader (the same source the
// engines run) and checks or writes the reference images both engines'
// tests compare their exports to: test_media/transitions/<id>_<percent>.png,
// each 45 x 80, the 360 x 640 canvas averaged in 8 x 8 blocks.
//
//   UPDATE_TRANSITION_REFERENCES=1 flutter test \
//     test/features/transitions/transition_references_test.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/features/timeline/domain/transition_catalog.g.dart';

const _width = 360;
const _height = 640;
const _block = 8;
const _progresses = [0.25, 0.5, 0.75];
const _dir = 'test_media/transitions';
final _update = Platform.environment['UPDATE_TRANSITION_REFERENCES'] == '1';

/// The outgoing test frame: a warm gradient, a dark disc, a light band.
/// Large, smooth shapes, so video compression barely changes them.
ui.Image _fromFrame() {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const rect = Rect.fromLTWH(0, 0, 360, 640);
  canvas
    ..drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, const Offset(360, 0), [
          const Color(0xFFE53935),
          const Color(0xFFFFC107),
        ]),
    )
    ..drawCircle(
      const Offset(120, 200),
      90,
      Paint()..color = const Color(0xFF3E2723),
    )
    ..drawRect(
      const Rect.fromLTWH(0, 420, 360, 80),
      Paint()..color = const Color(0xFFFFF8E1),
    );
  return recorder.endRecording().toImageSync(_width, _height);
}

/// The incoming test frame: a cool gradient and a white square.
ui.Image _toFrame() {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const rect = Rect.fromLTWH(0, 0, 360, 640);
  canvas
    ..drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, const Offset(0, 640), [
          const Color(0xFF1E88E5),
          const Color(0xFF26C6DA),
        ]),
    )
    ..drawRect(
      const Rect.fromLTWH(180, 380, 140, 140),
      Paint()..color = const Color(0xFFFFFFFF),
    );
  return recorder.endRecording().toImageSync(_width, _height);
}

/// RGB of [image], averaged in [_block] x [_block] blocks.
Future<Uint8List> _averaged(ui.Image image) async {
  final rgba = (await image.toByteData())!.buffer.asUint8List();
  const w = _width ~/ _block;
  const h = _height ~/ _block;
  final out = Uint8List(w * h * 3);
  for (var by = 0; by < h; by++) {
    for (var bx = 0; bx < w; bx++) {
      for (var c = 0; c < 3; c++) {
        var sum = 0;
        for (var y = 0; y < _block; y++) {
          for (var x = 0; x < _block; x++) {
            sum += rgba[((by * _block + y) * _width + bx * _block + x) * 4 + c];
          }
        }
        out[(by * w + bx) * 3 + c] = (sum / (_block * _block)).round();
      }
    }
  }
  return out;
}

/// Mean difference per channel, 0 to 1.
double _difference(Uint8List a, Uint8List b) {
  var sum = 0;
  for (var i = 0; i < a.length; i++) {
    sum += (a[i] - b[i]).abs();
  }
  return sum / a.length / 255;
}

Future<ui.Image> _render(
  ui.FragmentProgram program,
  ui.Image from,
  ui.Image to,
  double progress,
) async {
  final shader = program.fragmentShader()
    ..setFloat(0, _width.toDouble())
    ..setFloat(1, _height.toDouble())
    ..setFloat(2, progress)
    ..setFloat(3, _width / _height)
    ..setImageSampler(0, from)
    ..setImageSampler(1, to);
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    Rect.fromLTWH(0, 0, _width.toDouble(), _height.toDouble()),
    Paint()..shader = shader,
  );
  final image = recorder.endRecording().toImageSync(_width, _height);
  shader.dispose();
  return image;
}

Future<Uint8List> _png(Uint8List rgb, int w, int h) async {
  final rgba = Uint8List(w * h * 4);
  for (var i = 0; i < w * h; i++) {
    rgba
      ..[i * 4] = rgb[i * 3]
      ..[i * 4 + 1] = rgb[i * 3 + 1]
      ..[i * 4 + 2] = rgb[i * 3 + 2]
      ..[i * 4 + 3] = 255;
  }
  final buffer = await ui.ImmutableBuffer.fromUint8List(rgba);
  final descriptor = ui.ImageDescriptor.raw(
    buffer,
    width: w,
    height: h,
    pixelFormat: ui.PixelFormat.rgba8888,
  );
  final codec = await descriptor.instantiateCodec();
  final image = (await codec.getNextFrame()).image;
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  return png!.buffer.asUint8List();
}

Future<Uint8List> _readPng(String path) async {
  final codec = await ui.instantiateImageCodec(File(path).readAsBytesSync());
  final image = (await codec.getNextFrame()).image;
  final rgba = (await image.toByteData())!.buffer.asUint8List();
  return Uint8List.fromList([
    for (var i = 0; i < rgba.length; i += 4) ...[
      rgba[i],
      rgba[i + 1],
      rgba[i + 2],
    ],
  ]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ui.Image from;
  late ui.Image to;
  late Uint8List fromAveraged;
  late Uint8List toAveraged;

  setUpAll(() async {
    from = _fromFrame();
    to = _toFrame();
    fromAveraged = await _averaged(from);
    toAveraged = await _averaged(to);
    if (_update) {
      Directory(_dir).createSync(recursive: true);
      for (final (name, image) in [('from', from), ('to', to)]) {
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$_dir/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
      }
    }
  });

  test('the catalog has 50 transitions, each id once', () {
    final ids = [for (final t in transitionCatalog) t.id];
    expect(ids, hasLength(50));
    expect(ids.toSet(), hasLength(50));
  });

  for (final spec in transitionCatalog) {
    test('${spec.id} starts on the outgoing clip, ends on the incoming one, '
        'and matches its references', () async {
      final program = await ui.FragmentProgram.fromAsset(
        'shaders/transitions/${spec.id}.frag',
      );
      // Exact at both ends, so a transition never jumps at the cut.
      expect(
        _difference(
          await _averaged(await _render(program, from, to, 0)),
          fromAveraged,
        ),
        lessThan(0.005),
        reason: 'progress 0 is the outgoing clip',
      );
      expect(
        _difference(
          await _averaged(await _render(program, from, to, 1)),
          toAveraged,
        ),
        lessThan(0.005),
        reason: 'progress 1 is the incoming clip',
      );

      for (final p in _progresses) {
        final averaged = await _averaged(await _render(program, from, to, p));
        final path = '$_dir/${spec.id}_${(p * 100).round()}.png';
        if (_update) {
          File(path).writeAsBytesSync(
            await _png(averaged, _width ~/ _block, _height ~/ _block),
          );
        } else {
          expect(
            File(path).existsSync(),
            isTrue,
            reason: 'Run with UPDATE_TRANSITION_REFERENCES=1 to write $path',
          );
          expect(
            _difference(averaged, await _readPng(path)),
            lessThan(0.01),
            reason: '$path is out of date: the shader changed',
          );
        }
      }
    });
  }
}
