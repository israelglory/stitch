import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stitch/app/router.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/l10n/generated/app_localizations.dart';

/// Route stub. Replaced in M10; the design gallery row stays, debug only.
class SettingsScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: AppIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.back,
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.settingsTitle),
      ),
      body: ListView(
        children: [
          if (kDebugMode || kProfileMode)
            ListRow(
              title: l10n.designGalleryTitle,
              showChevron: true,
              onTap: () => context.go(AppRoutes.designGallery),
            ),
        ],
      ),
    );
  }
}
