import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/features/updates/application/update_providers.dart';
import 'package:stitch/features/updates/domain/store_update.dart';
import 'package:stitch/l10n/generated/app_localizations.dart';

/// Offers a newer version from the store over [child] (the projects
/// screen): once per launch, and only while that screen is on top.
class UpdatePrompt extends ConsumerStatefulWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<UpdatePrompt> createState() => _UpdatePromptState();
}

class _UpdatePromptState extends ConsumerState<UpdatePrompt> {
  bool _offering = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual(pendingUpdateProvider, (_, next) {
      if (next.value case final update?) unawaited(_offer(update));
    }, fireImmediately: true);
  }

  Future<void> _offer(StoreUpdate update) async {
    if (_offering) return;
    _offering = true;
    // The first answer can arrive while this screen is still being built.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? false)) {
      _offering = false;
      return;
    }
    final pending = ref.read(pendingUpdateProvider.notifier);
    final l10n = AppLocalizations.of(context);
    final version = update.version;
    final accepted = await showConfirmDialog(
      context: context,
      title: l10n.updateAvailableTitle,
      message: version == null
          ? l10n.updateAvailableMessage
          : l10n.updateAvailableVersionMessage(version),
      confirmLabel: l10n.updateNow,
      cancelLabel: l10n.updateLater,
    );
    _offering = false;
    await pending.answer(update: accepted);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
