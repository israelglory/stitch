/// Editing limits. All durations in microseconds.
abstract final class TimelineLimits {
  /// Shortest clip or item on the timeline.
  static const int minDurationUs = 100000;

  /// Default duration of a photo clip.
  static const int photoDurationUs = 3000000;

  /// Default duration of a new text item.
  static const int textDurationUs = 3000000;

  static const double minSpeed = 0.25;
  static const double maxSpeed = 4;

  /// Volumes are linear gain; 1.0 is unchanged, 2.0 is +6 dB.
  static const double minVolume = 0;
  static const double maxVolume = 2;

  static const int minTransitionUs = 200000;
  static const int maxTransitionUs = 1500000;
  static const int defaultTransitionUs = 500000;
}

/// Converts a source-time span to timeline time at [speed].
int sourceToTimelineUs(int sourceUs, double speed) =>
    (sourceUs / speed).round();

/// Converts a timeline span to source time at [speed].
int timelineToSourceUs(int timelineUs, double speed) =>
    (timelineUs * speed).round();

/// [value] limited to [min]..[max]. Typed alternative to `num.clamp`.
/// When [max] is below [min], [min] wins.
int clampInt(int value, int min, int max) =>
    value > max ? (max < min ? min : max) : (value < min ? min : value);

/// [value] limited to [min]..[max]. When [max] is below [min], [min] wins.
double clampDouble(double value, double min, double max) =>
    value > max ? (max < min ? min : max) : (value < min ? min : value);
