import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stitch/app/router.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/design/theme.dart';
import 'package:stitch/features/settings/application/settings_controller.dart';
import 'package:stitch/features/settings/domain/app_settings.dart';
import 'package:stitch/l10n/generated/app_localizations.dart';

class StitchApp extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(settingsControllerProvider.select((s) => s.theme));
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: switch (theme) {
        ThemeChoice.system => ThemeMode.system,
        ThemeChoice.dark => ThemeMode.dark,
        ThemeChoice.light => ThemeMode.light,
      },
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: ref.watch(routerProvider),
      // Status and navigation bars follow the theme.
      builder: (context, child) {
        final colors = context.colors;
        final dark = Theme.of(context).brightness == Brightness.dark;
        final icons = dark ? Brightness.light : Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: colors.background,
            statusBarBrightness: dark ? Brightness.dark : Brightness.light,
            statusBarIconBrightness: icons,
            systemNavigationBarColor: colors.background,
            systemNavigationBarIconBrightness: icons,
          ),
          child: child!,
        );
      },
    );
  }
}
