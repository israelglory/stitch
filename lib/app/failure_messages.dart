import 'package:stitch/core/errors/failure.dart';
import 'package:stitch/l10n/generated/app_localizations.dart';

/// Plain message for [failure]. Null for failures the user should not see
/// a message for (a cancel).
String? failureMessage(AppLocalizations l10n, Object failure) =>
    switch (failure) {
      CancelledFailure() => null,
      MissingSourceFailure() => l10n.failureMissingSource,
      InsufficientStorageFailure() => l10n.failureStorage,
      UnsupportedMediaFailure() => l10n.failureUnsupported,
      ProjectCorruptedFailure() => l10n.failureProject,
      PermissionDeniedFailure() => l10n.failurePermission,
      DownloadFailure() => l10n.failureDownload,
      CaptionFailure(:final problem) => switch (problem) {
        CaptionProblem.unavailable => l10n.captionsUnavailable,
        CaptionProblem.modelDamaged => l10n.failureCaptionModel,
        CaptionProblem.noSpeech => l10n.failureNoSpeech,
        CaptionProblem.failed => l10n.failureCaptions,
      },
      EngineFailure(code: 'interrupted') => l10n.failureExportInterrupted,
      EngineFailure(code: 'export_failed') => l10n.failureExport,
      EngineFailure() || UnexpectedFailure() => l10n.failureGeneric,
      _ => l10n.failureGeneric,
    };
