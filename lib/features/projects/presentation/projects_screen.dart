import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stitch/app/failure_messages.dart';
import 'package:stitch/app/providers.dart';
import 'package:stitch/app/router.dart';
import 'package:stitch/core/time/time.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/features/projects/application/projects_controller.dart';
import 'package:stitch/features/projects/domain/project.dart';
import 'package:stitch/features/projects/presentation/edited_label.dart';
import 'package:stitch/l10n/generated/app_localizations.dart';

const int _columns = 2;

/// Home: the user's projects, newest first.
class ProjectsScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final projects = ref.watch(projectsControllerProvider);
    final isEmpty = projects.hasValue && projects.requireValue.isEmpty;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppHeader(
            title: l10n.projectsTitle,
            trailing: [
              AppIconButton(
                icon: AppIcons.settings,
                semanticLabel: l10n.settingsTitle,
                onPressed: () => context.go(AppRoutes.settings),
              ),
            ],
          ),
          if (!isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.sm,
                AppSpacing.screen,
                AppSpacing.lg,
              ),
              child: PrimaryButton(
                label: l10n.newProject,
                icon: AppIcons.add,
                expand: true,
                onPressed: () => context.go(AppRoutes.newProject),
              ),
            ),
          Expanded(
            child: switch (projects) {
              AsyncData(value: final list) when list.isEmpty => Center(
                child: EmptyState(
                  title: l10n.projectsEmptyTitle,
                  message: l10n.projectsEmptyMessage,
                  actionLabel: l10n.newProject,
                  primaryAction: true,
                  onAction: () => context.go(AppRoutes.newProject),
                ),
              ),
              AsyncData(value: final list) => _ProjectGrid(projects: list),
              AsyncError() => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screen,
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ErrorBanner(
                    message: l10n.projectsLoadError,
                    onRetry: () =>
                        ref.read(projectsControllerProvider.notifier).refresh(),
                  ),
                ),
              ),
              _ => const _LoadingGrid(),
            },
          ),
        ],
      ),
    );
  }
}

/// Lays items out in rows of [_columns], each row as tall as its
/// tallest card, so large text grows the cards instead of clipping them.
class _Rows extends StatelessWidget {
  const new({required this.itemCount, required this.itemBuilder});

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    final rows = (itemCount / _columns).ceil();
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        0,
        AppSpacing.screen,
        AppSpacing.xxl,
      ),
      itemCount: rows,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
      itemBuilder: (context, row) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var c = 0; c < _columns; c++) ...[
            if (c > 0) const SizedBox(width: AppSpacing.md),
            Expanded(
              child: row * _columns + c < itemCount
                  ? itemBuilder(context, row * _columns + c)
                  : const SizedBox.shrink(),
            ),
          ],
        ],
      ),
    );
  }
}

class _LoadingGrid extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) =>
      _Rows(itemCount: 4, itemBuilder: (_, _) => const ProjectCard.loading());
}

class _ProjectGrid extends ConsumerWidget {
  const new({required this.projects});

  final List<ProjectSummary> projects;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final store = ref.watch(projectStoreProvider);
    final now = ref.watch(clockProvider)();
    final locale = Localizations.localeOf(context).toLanguageTag();

    return _Rows(
      itemCount: projects.length,
      itemBuilder: (context, i) {
        final project = projects[i];
        final poster = project.posterPath;
        return ProjectCard(
          name: project.name,
          durationLabel: formatDuration(project.durationUs),
          editedLabel: editedLabel(
            l10n,
            project.updatedAt,
            now,
            locale: locale,
          ),
          thumbnail: poster == null
              ? null
              : Image.file(
                  File(store.resolve(project.id, poster)),
                  fit: BoxFit.cover,
                  cacheWidth: 480,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
          onTap: () => context.go(AppRoutes.editor(project.id)),
          onMore: () => _showOptions(context, ref, project),
        );
      },
    );
  }

  Future<void> _showOptions(
    BuildContext context,
    WidgetRef ref,
    ProjectSummary project,
  ) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(projectsControllerProvider.notifier);
    // A failure (a full disk while copying, say) is explained, not lost.
    Future<void> attempt(Future<void> Function() action) async {
      try {
        await action();
      } on Object catch (e) {
        if (!context.mounted) return;
        await showNoticeDialog(
          context: context,
          title: l10n.projectActionFailed,
          message: failureMessage(l10n, e) ?? l10n.failureGeneric,
          buttonLabel: l10n.ok,
        );
      }
    }

    return showActionSheet(
      context: context,
      title: project.name,
      actions: [
        SheetAction(
          icon: AppIcons.rename,
          label: l10n.rename,
          onSelected: () async {
            final name = await showTextInputDialog(
              context: context,
              title: l10n.renameProjectTitle,
              confirmLabel: l10n.save,
              initialValue: project.name,
            );
            if (name != null) {
              await attempt(() => controller.rename(project.id, name));
            }
          },
        ),
        SheetAction(
          icon: AppIcons.duplicate,
          label: l10n.duplicate,
          onSelected: () => attempt(
            () => controller.duplicate(
              project.id,
              name: l10n.copyName(project.name),
            ),
          ),
        ),
        SheetAction(
          icon: AppIcons.delete,
          label: l10n.delete,
          destructive: true,
          onSelected: () async {
            final confirmed = await showConfirmDialog(
              context: context,
              title: l10n.deleteProjectTitle(project.name),
              message: l10n.deleteProjectMessage,
              confirmLabel: l10n.delete,
              destructive: true,
            );
            if (confirmed) await attempt(() => controller.delete(project.id));
          },
        ),
      ],
    );
  }
}
