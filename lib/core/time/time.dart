/// Time utilities. All timeline times are integer microseconds.
library;

/// Microseconds per second.
const int usPerSecond = 1000000;

/// Microseconds per millisecond.
const int usPerMillisecond = 1000;

/// Converts seconds to microseconds, rounding to the nearest microsecond.
int secondsToUs(double seconds) => (seconds * usPerSecond).round();

/// Converts microseconds to seconds.
double usToSeconds(int us) => us / usPerSecond;

/// Duration of one frame at [fps], in microseconds, rounded.
int frameDurationUs(int fps) {
  assert(fps > 0, 'fps must be positive');
  return (usPerSecond / fps).round();
}

/// Snaps [us] to the nearest frame boundary at [fps].
int snapToFrame(int us, int fps) {
  assert(fps > 0, 'fps must be positive');
  final frame = (us * fps / usPerSecond).round();
  return (frame * usPerSecond / fps).round();
}

/// Formats [us] as `m:ss` or `h:mm:ss`, used for durations and the
/// current time readout. Negative values clamp to zero.
///
/// Render with tabular figures so the text does not jitter while playing.
String formatDuration(int us) {
  final totalSeconds = (us < 0 ? 0 : us) ~/ usPerSecond;
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  final ss = seconds.toString().padLeft(2, '0');
  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:$ss';
  }
  return '$minutes:$ss';
}

/// Formats [us] as `m:ss.f` (tenths), used on the timeline ruler and while
/// trimming, where sub-second precision matters. Negative values clamp to
/// zero.
String formatPreciseDuration(int us) {
  final clamped = us < 0 ? 0 : us;
  final tenths = clamped ~/ (usPerSecond ~/ 10);
  final totalSeconds = tenths ~/ 10;
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}.${tenths % 10}';
}
