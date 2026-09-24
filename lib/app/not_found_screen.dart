import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/l10n/generated/app_localizations.dart';

/// Shown for unknown routes.
class NotFoundScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: EmptyState(
            title: l10n.pageNotFoundTitle,
            message: l10n.pageNotFound,
            actionLabel: l10n.backToProjects,
            onAction: () => context.go('/'),
            primaryAction: true,
          ),
        ),
      ),
    );
  }
}
