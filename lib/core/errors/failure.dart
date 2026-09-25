/// Typed failures shared across the app.
///
/// Every failure that can reach the UI is a subclass of [Failure]. The
/// presentation layer maps each subclass to a plain, localized message, so
/// nothing here carries user-facing text.
sealed class Failure implements Exception {
  const new({this.cause, this.stackTrace});

  /// The underlying error, kept for logging only.
  final Object? cause;

  /// Stack trace of [cause], kept for logging only.
  final StackTrace? stackTrace;
}

/// A source file referenced by a project can no longer be found.
final class MissingSourceFailure extends Failure {
  const new(this.path, {super.cause, super.stackTrace});

  final String path;
}

/// There is not enough free space for the requested operation.
final class InsufficientStorageFailure extends Failure {
  const new({
    required this.requiredBytes,
    required this.availableBytes,
    super.cause,
    super.stackTrace,
  });

  final int requiredBytes;
  final int availableBytes;
}

/// The user denied a permission the operation needs.
final class PermissionDeniedFailure extends Failure {
  const new(
    this.permission, {
    this.permanentlyDenied = false,
    super.cause,
    super.stackTrace,
  });

  final AppPermission permission;

  /// True when the system will no longer show the prompt, so the only way
  /// forward is the system settings screen.
  final bool permanentlyDenied;
}

/// A media file exists but could not be decoded.
final class UnsupportedMediaFailure extends Failure {
  const new(this.path, {super.cause, super.stackTrace});

  final String path;
}

/// A stored project could not be read or migrated.
final class ProjectCorruptedFailure extends Failure {
  const new(this.projectId, {super.cause, super.stackTrace});

  final String projectId;
}

/// The native engine reported an error during preview or export.
final class EngineFailure extends Failure {
  const new(this.code, {super.cause, super.stackTrace});

  /// Stable, engine-defined error code, used for logging and mapping.
  final String code;
}

/// A long-running task was cancelled by the user.
///
/// Not an error from the user's point of view; the UI shows no message.
final class CancelledFailure extends Failure {
  const new();
}

/// A network download (caption models only) failed.
final class DownloadFailure extends Failure {
  const new({super.cause, super.stackTrace});
}

/// Captions could not be made.
final class CaptionFailure extends Failure {
  const new(this.problem, {super.cause, super.stackTrace});

  final CaptionProblem problem;
}

enum CaptionProblem {
  /// Speech recognition is not built for this device's processor.
  unavailable,

  /// The downloaded model could not be loaded; downloading it again helps.
  modelDamaged,

  /// Recognition ran but heard no speech.
  noSpeech,

  /// Recognition stopped with an error.
  failed,
}

/// Anything not covered above. Should be rare; log it and fix the mapping.
final class UnexpectedFailure extends Failure {
  const new({super.cause, super.stackTrace});
}

/// Permissions the app may request, always at time of use.
enum AppPermission { photoLibrary, microphone, notifications }
