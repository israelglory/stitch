import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/core/time/time.dart';

void main() {
  group('conversions', () {
    test('seconds and microseconds round trip', () {
      expect(secondsToUs(1.5), 1500000);
      expect(secondsToUs(0.1), 100000);
      expect(usToSeconds(2500000), 2.5);
    });

    test('frame duration', () {
      expect(frameDurationUs(30), 33333);
      expect(frameDurationUs(24), 41667);
      expect(frameDurationUs(60), 16667);
    });

    test('snapToFrame lands on the nearest frame', () {
      expect(snapToFrame(0, 30), 0);
      expect(snapToFrame(20000, 30), 33333);
      expect(snapToFrame(10000, 30), 0);
      expect(snapToFrame(1000000, 30), 1000000);
      expect(snapToFrame(1010000, 24), 1000000);
    });
  });

  group('formatDuration', () {
    test('minutes and seconds', () {
      expect(formatDuration(0), '0:00');
      expect(formatDuration(999999), '0:00');
      expect(formatDuration(5 * usPerSecond), '0:05');
      expect(formatDuration(75 * usPerSecond), '1:15');
      expect(formatDuration(600 * usPerSecond), '10:00');
    });

    test('hours', () {
      expect(formatDuration(3600 * usPerSecond), '1:00:00');
      expect(formatDuration(3725 * usPerSecond), '1:02:05');
    });

    test('negative clamps to zero', () {
      expect(formatDuration(-1), '0:00');
    });
  });

  group('formatPreciseDuration', () {
    test('tenths', () {
      expect(formatPreciseDuration(0), '0:00.0');
      expect(formatPreciseDuration(1250000), '0:01.2');
      expect(formatPreciseDuration(61900000), '1:01.9');
    });

    test('negative clamps to zero', () {
      expect(formatPreciseDuration(-5), '0:00.0');
    });
  });
}
