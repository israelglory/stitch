import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/engine/fake_editor_engine.dart';
import 'package:stitch/features/audio/application/waveforms.dart';

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('stitch_wave'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('asks the engine once, then answers from memory and disk', () async {
    final engine = FakeEditorEngine();
    var calls = 0;
    engine.waveformHandler = (path, pps) {
      calls++;
      return [0.1, 0.5, 1];
    };
    final file = File('${dir.path}/song.m4a')..writeAsBytesSync([1, 2, 3]);
    final cache = WaveformCache(engine, Directory('${dir.path}/cache'));

    // Two requests at once share one engine call.
    final both = await Future.wait([
      cache.peaks(file.path),
      cache.peaks(file.path),
    ]);
    expect(both, [
      [0.1, 0.5, 1.0],
      [0.1, 0.5, 1.0],
    ]);
    expect(calls, 1);

    // A new cache (a new launch) reads the disk copy.
    final later = WaveformCache(engine, Directory('${dir.path}/cache'));
    expect(await later.peaks(file.path), [0.1, 0.5, 1.0]);
    expect(calls, 1);

    // A changed file is read again.
    file.writeAsBytesSync([1, 2, 3, 4]);
    await later.peaks(file.path);
    expect(calls, 2);
  });
}
