import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Severity of a log record.
enum LogLevel { debug, info, warning, error }

/// Minimal local logger.
///
/// Writes to the platform log only. The app has no analytics or remote
/// reporting, so nothing logged here ever leaves the device.
class Logger {
  const new(this.name);

  final String name;

  void debug(String message) => _log(LogLevel.debug, message);

  void info(String message) => _log(LogLevel.info, message);

  void warning(String message, [Object? error, StackTrace? stackTrace]) =>
      _log(LogLevel.warning, message, error, stackTrace);

  void error(String message, [Object? error, StackTrace? stackTrace]) =>
      _log(LogLevel.error, message, error, stackTrace);

  void _log(
    LogLevel level,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    if (level == LogLevel.debug && !kDebugMode) return;
    developer.log(
      message,
      name: name,
      level: _levelValue(level),
      error: error,
      stackTrace: stackTrace,
    );
  }

  // Values follow package:logging so tools filter them correctly.
  static int _levelValue(LogLevel level) => switch (level) {
    LogLevel.debug => 500,
    LogLevel.info => 800,
    LogLevel.warning => 900,
    LogLevel.error => 1000,
  };
}
