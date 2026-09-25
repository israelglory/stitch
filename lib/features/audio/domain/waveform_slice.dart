import 'dart:math' as math;

/// The part of a file's [peaks] (taken [peaksPerSecond] times a second of
/// source) that an item plays over [durationUs] of timeline: from
/// [sourceInUs] to [sourceOutUs] at [speed], starting over at the in
/// point when it [loop]s. One peak per 1 / [peaksPerSecond] of timeline.
List<double> waveformSlice(
  List<double> peaks, {
  required int peaksPerSecond,
  required int sourceInUs,
  required int sourceOutUs,
  required double speed,
  required bool loop,
  required int durationUs,
}) {
  if (peaks.isEmpty || durationUs <= 0 || sourceOutUs <= sourceInUs) {
    return const [];
  }
  final count = math.max(1, durationUs * peaksPerSecond ~/ 1000000);
  final passUs = sourceOutUs - sourceInUs;
  return [
    for (var i = 0; i < count; i++)
      () {
        final timelineUs = i * 1000000 ~/ peaksPerSecond;
        var intoUs = (timelineUs * speed).round();
        if (loop) intoUs %= passUs;
        final sourceUs = math.min(sourceInUs + intoUs, sourceOutUs - 1);
        final index = sourceUs * peaksPerSecond ~/ 1000000;
        return peaks[index.clamp(0, peaks.length - 1)];
      }(),
  ];
}
