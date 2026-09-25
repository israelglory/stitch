import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stitch/app/router.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/l10n/generated/app_localizations.dart';

/// Every license the app carries, by package: Dart and Flutter packages
/// (collected by Flutter) and the bundled fonts, sounds, and native code
/// (registered in bootstrap).
final FutureProvider<Map<String, List<LicenseEntry>>> _licensesProvider =
    FutureProvider((ref) async {
      final byPackage = <String, List<LicenseEntry>>{};
      await for (final entry in LicenseRegistry.licenses) {
        for (final package in entry.packages) {
          (byPackage[package] ??= []).add(entry);
        }
      }
      final names = byPackage.keys.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      return {for (final n in names) n: byPackage[n]!};
    });

class LicensesScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final licenses = ref.watch(_licensesProvider);
    return Scaffold(
      appBar: AppBar(
        leading: AppIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.back,
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.openSourceLicenses),
      ),
      body: switch (licenses) {
        AsyncData(:final value) => ListView(
          children: [
            for (final MapEntry(key: package, value: entries) in value.entries)
              ListRow(
                title: package,
                value: l10n.licenseCount(entries.length),
                showChevron: true,
                onTap: () => context.go(AppRoutes.license(package)),
              ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
        AsyncError() => Padding(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: ErrorBanner(
            message: l10n.failureGeneric,
            onRetry: () => ref.invalidate(_licensesProvider),
          ),
        ),
        _ => ListView(
          children: [
            for (var i = 0; i < 10; i++)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screen,
                  vertical: AppSpacing.md,
                ),
                child: Skeleton.text(AppTypography.bodyLarge),
              ),
          ],
        ),
      },
    );
  }
}

/// The license texts of one [package].
class LicenseScreen extends ConsumerWidget {
  const new({required this.package, super.key});

  final String package;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final entries = ref.watch(_licensesProvider).value?[package] ?? const [];
    return Scaffold(
      appBar: AppBar(
        leading: AppIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.back,
          onPressed: () => context.pop(),
        ),
        title: Text(package),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        children: [
          for (final (i, entry) in entries.indexed) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Divider(color: colors.border, height: 1),
              ),
            for (final paragraph in entry.paragraphs)
              Padding(
                padding: EdgeInsetsDirectional.only(
                  bottom: AppSpacing.sm,
                  start: paragraph.indent == LicenseParagraph.centeredIndent
                      ? 0
                      : AppSpacing.lg * paragraph.indent,
                ),
                child: Text(
                  paragraph.text,
                  textAlign: paragraph.indent == LicenseParagraph.centeredIndent
                      ? TextAlign.center
                      : TextAlign.start,
                  style: AppTypography.body.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
