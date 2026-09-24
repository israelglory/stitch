/// Source of the current time, replaceable in tests.
typedef Clock = DateTime Function();

DateTime systemClock() => DateTime.now().toUtc();
