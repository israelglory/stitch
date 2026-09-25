import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stitch/app/failure_messages.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/features/projects/application/import_controller.dart';
import 'package:stitch/l10n/generated/app_localizations.dart';

/// Runs [task] while showing import progress in a sheet that cannot be
/// dismissed except by Cancel. Returns the task's result once it finishes.
///
/// With [reportFailure], a failed import is explained in a notice (the
/// caller has nowhere else to show it) and then cleared.
Future<T> runWithImportProgress<T>(
  BuildContext context,
  Future<T> Function() task, {
  bool reportFailure = true,
}) async {
  final navigator = Navigator.of(context);
  final container = ProviderScope.containerOf(context, listen: false);
  var open = true;
  unawaited(
    showAppBottomSheet<void>(
      context: context,
      isDismissible: false,
      builder: (_) => const ImportProgressSheet(),
    ).whenComplete(() => open = false),
  );
  final T result;
  try {
    result = await task();
  } finally {
    if (open && navigator.mounted) navigator.pop();
  }
  final state = container.read(importControllerProvider);
  if (reportFailure && state is ImportFailed && context.mounted) {
    final l10n = AppLocalizations.of(context);
    await showNoticeDialog(
      context: context,
      title: l10n.importFailedTitle,
      message: failureMessage(l10n, state.failure) ?? l10n.failureGeneric,
      buttonLabel: l10n.ok,
    );
    container.read(importControllerProvider.notifier).reset();
  }
  return result;
}

/// Progress of the running import, with Cancel.
class ImportProgressSheet extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(importControllerProvider);
    final (done, total, fraction) = switch (state) {
      ImportRunning(:final progress) => (
        progress.completed,
        progress.total,
        progress.fraction,
      ),
      _ => (0, 0, null),
    };
    // Back cancels, like the button: the sheet never closes on its own
    // while the import runs.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) ref.read(importControllerProvider.notifier).cancel();
      },
      child: AppBottomSheet(
        title: l10n.importingProgress(
          (done + 1).clamp(1, total == 0 ? 1 : total),
          total,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.sm),
            LinearProgress(
              value: fraction,
              semanticLabel: l10n.importingProgress(done, total),
            ),
            const SizedBox(height: AppSpacing.xl),
            SecondaryButton(
              label: l10n.cancel,
              expand: true,
              onPressed: () =>
                  ref.read(importControllerProvider.notifier).cancel(),
            ),
          ],
        ),
      ),
    );
  }
}
