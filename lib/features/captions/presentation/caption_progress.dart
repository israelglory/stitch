import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stitch/app/failure_messages.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/features/captions/application/caption_generation.dart';
import 'package:stitch/features/captions/presentation/captions_sheet.dart';
import 'package:stitch/l10n/generated/app_localizations.dart';

/// Caption generation in the editor: its progress with Cancel while it
/// runs (editing goes on), or why it failed. Nothing otherwise. Keeps the
/// generation alive while the editor shows it.
class CaptionProgress extends ConsumerWidget {
  const new({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final job = ref.watch(captionGenerationProvider(projectId));
    final notifier = ref.read(captionGenerationProvider(projectId).notifier);
    final Widget child;
    switch (job) {
      case CaptionJobIdle():
        return const SizedBox.shrink();
      case CaptionJobRunning(:final fraction):
        final percent = (fraction * 100).floor();
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.captionsProgress(percent),
                    style: AppTypography.body.tabular.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                AppTextButton(label: l10n.cancel, onPressed: notifier.cancel),
              ],
            ),
            LinearProgress(value: fraction),
          ],
        );
      case CaptionJobFailed(:final failure):
        final message = failureMessage(l10n, failure);
        if (message == null) return const SizedBox.shrink();
        child = ErrorBanner(
          message: message,
          onRetry: () {
            notifier.dismiss();
            unawaited(showCaptionsSheet(context, projectId));
          },
        );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        0,
        AppSpacing.screen,
        AppSpacing.sm,
      ),
      child: child,
    );
  }
}
