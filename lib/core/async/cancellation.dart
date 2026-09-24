import 'package:stitch/core/errors/failure.dart';

/// Cooperative cancellation for long tasks. The task checks
/// [throwIfCancelled] between steps; the UI calls [cancel].
final class CancellationToken {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() => _cancelled = true;

  /// Throws [CancelledFailure] once [cancel] has been called.
  void throwIfCancelled() {
    if (_cancelled) throw const CancelledFailure();
  }
}
