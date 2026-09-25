import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stitch/app/failure_messages.dart';
import 'package:stitch/app/providers.dart';
import 'package:stitch/app/router.dart';
import 'package:stitch/core/storage/bytes.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/features/captions/application/caption_providers.dart';
import 'package:stitch/features/captions/data/caption_models.dart';
import 'package:stitch/features/export/domain/export_options.dart';
import 'package:stitch/features/export/presentation/export_sheet.dart';
import 'package:stitch/features/projects/presentation/format_screen.dart';
import 'package:stitch/features/settings/application/settings_controller.dart';
import 'package:stitch/features/settings/application/storage.dart';
import 'package:stitch/features/settings/domain/app_settings.dart';
import 'package:stitch/l10n/generated/app_localizations.dart';

/// Where the source code lives.
const sourceCodeUrl = 'https://github.com/israelglory/stitch';

final FutureProvider<String> _appVersionProvider = FutureProvider(
  (ref) => ref.watch(systemServicesProvider).appVersion(),
);

/// Export defaults, the new project format, theme, storage with Clear
/// cache, caption models, and about.
class SettingsScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final caps = ref.watch(exportCapabilitiesProvider).value;
    final version = ref.watch(_appVersionProvider).value;

    String resolutionName(ExportResolution r) => switch (r) {
      ExportResolution.hd => l10n.resolution720,
      ExportResolution.fullHd => l10n.resolution1080,
      ExportResolution.uhd => l10n.resolution4k,
    };
    String qualityName(ExportQuality q) => switch (q) {
      ExportQuality.smaller => l10n.qualitySmaller,
      ExportQuality.better => l10n.qualityBetter,
    };
    String themeName(ThemeChoice t) => switch (t) {
      ThemeChoice.system => l10n.themeSystem,
      ThemeChoice.dark => l10n.themeDark,
      ThemeChoice.light => l10n.themeLight,
    };
    final export = settings.export;

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
          _Section(l10n.settingsExport),
          ListRow(
            title: l10n.exportResolution,
            value: resolutionName(export.resolution),
            showChevron: true,
            onTap: () => _choose(
              context,
              title: l10n.exportResolution,
              options: [
                for (final r in ExportResolution.values)
                  if (r != ExportResolution.uhd || (caps?.max4k ?? false))
                    (r, resolutionName(r)),
              ],
              selected: export.resolution,
              onSelected: (r) => controller.update(
                (s) => s.copyWith(export: s.export.copyWith(resolution: r)),
              ),
            ),
          ),
          ListRow(
            title: l10n.exportFrameRate,
            value: '${export.frameRate}',
            showChevron: true,
            onTap: () => _choose(
              context,
              title: l10n.exportFrameRate,
              options: [for (final f in exportFrameRates) (f, '$f')],
              selected: export.frameRate,
              onSelected: (f) => controller.update(
                (s) => s.copyWith(export: s.export.copyWith(frameRate: f)),
              ),
            ),
          ),
          ListRow(
            title: l10n.exportQuality,
            value: qualityName(export.quality),
            showChevron: true,
            onTap: () => _choose(
              context,
              title: l10n.exportQuality,
              options: [
                for (final q in ExportQuality.values) (q, qualityName(q)),
              ],
              selected: export.quality,
              onSelected: (q) => controller.update(
                (s) => s.copyWith(export: s.export.copyWith(quality: q)),
              ),
            ),
          ),
          _Section(l10n.settingsNewProjects),
          ListRow(
            title: l10n.settingsDefaultFormat,
            value: aspectLabel(l10n, settings.aspect),
            showChevron: true,
            onTap: () => _choose(
              context,
              title: l10n.settingsDefaultFormat,
              options: [
                for (final (preset, _, _) in aspectChoices)
                  (preset, aspectLabel(l10n, preset)),
              ],
              selected: settings.aspect,
              onSelected: (a) =>
                  controller.update((s) => s.copyWith(aspect: a)),
            ),
          ),
          _Section(l10n.settingsAppearance),
          ListRow(
            title: l10n.settingsTheme,
            value: themeName(settings.theme),
            showChevron: true,
            onTap: () => _choose(
              context,
              title: l10n.settingsTheme,
              options: [for (final t in ThemeChoice.values) (t, themeName(t))],
              selected: settings.theme,
              onSelected: (t) => controller.update((s) => s.copyWith(theme: t)),
            ),
          ),
          _Section(l10n.settingsStorage),
          const _Storage(),
          _Section(l10n.settingsCaptionModels),
          for (final model in CaptionModel.values) _ModelRow(model),
          _Section(l10n.settingsAbout),
          ListRow(title: l10n.settingsVersion, value: version ?? ''),
          ListRow(
            title: l10n.openSourceLicenses,
            showChevron: true,
            onTap: () => context.go(AppRoutes.licenses),
          ),
          ListRow(
            title: l10n.sourceCode,
            subtitle: 'github.com/israelglory/stitch',
            trailing: Icon(
              AppIcons.externalLink,
              size: AppSizes.inlineIcon,
              color: context.colors.textTertiary,
            ),
            onTap: () => unawaited(
              ref.read(systemServicesProvider).openUrl(sourceCodeUrl),
            ),
          ),
          if (kDebugMode || kProfileMode)
            ListRow(
              title: l10n.designGalleryTitle,
              showChevron: true,
              onTap: () => context.go(AppRoutes.designGallery),
            ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

/// A list of [options] in a sheet, the [selected] one checked. Choosing
/// one closes the sheet.
void _choose<T>(
  BuildContext context, {
  required String title,
  required List<(T, String)> options,
  required T selected,
  required ValueChanged<T> onSelected,
}) {
  unawaited(
    showAppBottomSheet<void>(
      context: context,
      builder: (context) => AppBottomSheet(
        title: title,
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (value, label) in options)
              ListRow(
                title: label,
                trailing: value == selected
                    ? Icon(AppIcons.check, color: context.colors.accent)
                    : null,
                onTap: () {
                  onSelected(value);
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    ),
  );
}

class _Section extends StatelessWidget {
  const new(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.screen,
      AppSpacing.xl,
      AppSpacing.screen,
      AppSpacing.xs,
    ),
    child: Semantics(
      header: true,
      child: Text(
        title,
        style: AppTypography.caption.semibold.copyWith(
          color: context.colors.textSecondary,
        ),
      ),
    ),
  );
}

/// Space used, measured in the background, and Clear cache.
class _Storage extends ConsumerStatefulWidget {
  const new();

  @override
  ConsumerState<_Storage> createState() => _StorageState();
}

class _StorageState extends ConsumerState<_Storage> {
  bool _clearing = false;

  Future<void> _clear() async {
    final l10n = AppLocalizations.of(context);
    final ok = await showConfirmDialog(
      context: context,
      title: l10n.clearCacheTitle,
      message: l10n.clearCacheMessage,
      confirmLabel: l10n.clear,
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _clearing = true);
    await ref.read(cacheCleanerProvider).clear();
    ref.invalidate(storageUseProvider);
    if (mounted) setState(() => _clearing = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final use = ref.watch(storageUseProvider);
    Widget row(String title, int? bytes) => ListRow(
      title: title,
      value: bytes == null ? null : formatBytes(bytes),
      trailing: bytes == null
          ? Skeleton.text(AppTypography.body, width: AppSizes.skeletonValue)
          : null,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (use case AsyncError(:final error))
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: ErrorBanner(
              message: failureMessage(l10n, error) ?? l10n.failureGeneric,
              onRetry: () => ref.invalidate(storageUseProvider),
            ),
          )
        else ...[
          row(l10n.storageProjects, use.value?.projects),
          row(l10n.storageCache, use.value?.cache),
          row(l10n.storageModels, use.value?.models),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.sm,
            AppSpacing.screen,
            0,
          ),
          child: SecondaryButton(
            label: l10n.clearCache,
            onPressed: _clearing || (use.value?.cache ?? 0) == 0
                ? null
                : () => unawaited(_clear()),
          ),
        ),
      ],
    );
  }
}

/// A caption model: its size and whether it is here, with Download,
/// Cancel, or Delete.
class _ModelRow extends ConsumerWidget {
  const new(this.model);

  final CaptionModel model;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final status = ref.watch(captionModelsProvider)[model]!;
    final models = ref.read(captionModelsProvider.notifier);
    final size = formatBytes(model.bytes);
    final title = switch (model) {
      CaptionModel.tiny => l10n.captionModelTiny,
      CaptionModel.base => l10n.captionModelBase,
    };
    return switch (status) {
      ModelReady() => ListRow(
        title: title,
        subtitle: l10n.modelDownloaded(size),
        trailing: AppTextButton(
          label: l10n.delete,
          onPressed: () async {
            final ok = await showConfirmDialog(
              context: context,
              title: l10n.deleteModelTitle,
              message: l10n.deleteModelMessage,
              confirmLabel: l10n.delete,
              destructive: true,
            );
            if (!ok) return;
            await models.delete(model);
            ref.invalidate(storageUseProvider);
          },
        ),
      ),
      ModelDownloading(:final fraction) => ListRow(
        title: title,
        subtitle: l10n.captionModelDownloading((fraction * 100).floor()),
        trailing: AppTextButton(
          label: l10n.cancel,
          onPressed: () => unawaited(models.cancel(model)),
        ),
      ),
      ModelMissing() || ModelFailed() => ListRow(
        title: title,
        subtitle: status is ModelFailed
            ? failureMessage(l10n, status.failure) ?? l10n.failureDownload
            : l10n.modelNotDownloaded(size),
        trailing: AppTextButton(
          label: status is ModelFailed ? l10n.retry : l10n.download,
          onPressed: () async {
            await models.download(model);
            ref.invalidate(storageUseProvider);
          },
        ),
      ),
    };
  }
}
