import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/features/projects/application/import_controller.dart';
import 'package:stitch/l10n/generated/app_localizations.dart';

/// Runs [task] while showing import progress in a sheet that cannot be
/// dismissed except by Cancel. Returns the task's result once it finishes.
Future<T> runWithImportProgress<T>(
  BuildContext context,
  Future<T> Function() task,
) async {
  final navigator = Navigator.of(context);
  var open = true;
  unawaited(
    showAppBottomSheet<void>(
      context: context,
      isDismissible: false,
      builder: (_) => const ImportProgressSheet(),
    ).whenComplete(() => open = false),
  );
  try {
    return await task();
  } finally {
    if (open && navigator.mounted) navigator.pop();
  }
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
    return AppBottomSheet(
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
    );
  }
}
