import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/features/audio/domain/waveform_slice.dart';

void main() {
  // One peak per 100 ms of source, numbered by position.
  final peaks = [for (var i = 0; i < 50; i++) i / 100];

  List<double> slice({
    int inUs = 0,
    int outUs = 5000000,
    double speed = 1,
    bool loop = false,
    int durationUs = 1000000,
  }) => waveformSlice(
    peaks,
    peaksPerSecond: 10,
    sourceInUs: inUs,
    sourceOutUs: outUs,
    speed: speed,
    loop: loop,
    durationUs: durationUs,
  );

  test('takes the peaks of the source range the item plays', () {
    expect(slice(inUs: 2000000), [for (var i = 20; i < 30; i++) i / 100]);
  });

  test('speed covers more source per peak', () {
    expect(slice(speed: 2), [for (var i = 0; i < 20; i += 2) i / 100]);
  });

  test('a loop starts over at the in point', () {
    final looped = slice(inUs: 1000000, outUs: 1500000, loop: true);
    expect(looped, [for (var i = 0; i < 10; i++) (10 + i % 5) / 100]);
  });

  test('nothing for empty sources or items', () {
    expect(
      waveformSlice(
        const [],
        peaksPerSecond: 10,
        sourceInUs: 0,
        sourceOutUs: 1000000,
        speed: 1,
        loop: false,
        durationUs: 1000000,
      ),
      isEmpty,
    );
    expect(slice(durationUs: 0), isEmpty);
  });
}
