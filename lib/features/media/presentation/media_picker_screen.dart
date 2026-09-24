import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stitch/app/providers.dart';
import 'package:stitch/app/router.dart';
import 'package:stitch/core/time/time.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/features/media/application/library_controller.dart';
import 'package:stitch/features/media/domain/library_item.dart';
import 'package:stitch/features/media/presentation/library_thumbnail.dart';
import 'package:stitch/features/timeline/domain/models.dart';
import 'package:stitch/l10n/generated/app_localizations.dart';

enum PickerMode {
  /// Pick media for a new project, then choose its format.
  create,

  /// Add clips to the open project. Pops with `List<LibraryItem>`.
  add,

  /// Pick one item to replace a clip. Pops with a `LibraryItem`.
  replace,
}

/// Screens narrower than this get three columns instead of four.
const double _fourColumnMinWidth = 360;

/// Load the next page when this close to the end of the grid.
const double _loadMoreExtent = 600;

/// Photo and video picker with multi-select in tap order.
class MediaPickerScreen extends ConsumerStatefulWidget {
  const new({required this.mode, super.key});

  final PickerMode mode;

  @override
  ConsumerState<MediaPickerScreen> createState() => _MediaPickerScreenState();
}

class _MediaPickerScreenState extends ConsumerState<MediaPickerScreen> {
  LibraryFilter _filter = LibraryFilter.videos;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Coming back from system settings may have changed access.
    _lifecycle = AppLifecycleListener(
      onResume: () =>
          ref.read(libraryAccessControllerProvider.notifier).recheck(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _onTap(LibraryItem item) {
    if (widget.mode == PickerMode.replace) {
      context.pop(item);
      return;
    }
    unawaited(AppHaptics.selection());
    ref.read(mediaSelectionProvider.notifier).toggle(item);
  }

  void _onAdd() {
    final selection = ref.read(mediaSelectionProvider);
    if (selection.isEmpty) return;
    if (widget.mode == PickerMode.create) {
      context.go(AppRoutes.newProjectFormat);
    } else {
      context.pop(selection);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final access = ref.watch(libraryAccessControllerProvider);
    final count = ref.watch(mediaSelectionProvider.select((s) => s.length));
    final canBrowse = switch (access) {
      AsyncData(
        value: (
          access: LibraryAccess.granted || LibraryAccess.limited,
          asked: _,
        ),
      ) =>
        true,
      _ => false,
    };

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppHeader(
            centerTitle: true,
            title: widget.mode == PickerMode.replace
                ? l10n.replaceMediaTitle
                : l10n.addMediaTitle,
            leading: AppIconButton(
              icon: AppIcons.close,
              semanticLabel: l10n.close,
              onPressed: () => context.pop(),
            ),
          ),
          Expanded(
            child: switch (access) {
              AsyncData(value: (access: LibraryAccess.granted, asked: _)) =>
                _Library(
                  filter: _filter,
                  onFilter: (f) => setState(() => _filter = f),
                  onTap: _onTap,
                  limited: false,
                ),
              AsyncData(value: (access: LibraryAccess.limited, asked: _)) =>
                _Library(
                  filter: _filter,
                  onFilter: (f) => setState(() => _filter = f),
                  onTap: _onTap,
                  limited: true,
                ),
              AsyncData(value: (access: _, :final asked)) => _PermissionView(
                asked: asked,
              ),
              AsyncError() => const _PermissionView(asked: false),
              _ => const _LoadingGrid(),
            },
          ),
          if (canBrowse && widget.mode != PickerMode.replace)
            DecoratedBox(
              decoration: BoxDecoration(
                color: context.colors.background,
                border: Border(top: BorderSide(color: context.colors.border)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.screen),
                  child: PrimaryButton(
                    label: l10n.addCount(count),
                    expand: true,
                    onPressed: count == 0 ? null : _onAdd,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Library extends ConsumerWidget {
  const new({
    required this.filter,
    required this.onFilter,
    required this.onTap,
    required this.limited,
  });

  final LibraryFilter filter;
  final ValueChanged<LibraryFilter> onFilter;
  final ValueChanged<LibraryItem> onTap;
  final bool limited;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final page = ref.watch(libraryItemsProvider(filter));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.xs,
            AppSpacing.screen,
            AppSpacing.md,
          ),
          child: SegmentedControl<LibraryFilter>(
            segments: [
              Segment(LibraryFilter.videos, l10n.filterVideos),
              Segment(LibraryFilter.photos, l10n.filterPhotos),
              Segment(LibraryFilter.all, l10n.filterAll),
            ],
            selected: filter,
            onChanged: onFilter,
          ),
        ),
        if (limited)
          ListRow(
            title: l10n.limitedAccessNote,
            leadingIcon: AppIcons.info,
            trailing: AppTextButton(
              label: l10n.manage,
              size: ButtonSize.small,
              onPressed: () => ref
                  .read(libraryAccessControllerProvider.notifier)
                  .manageSelection(),
            ),
          ),
        Expanded(
          child: switch (page) {
            AsyncData(value: final p) when p.items.isEmpty => Center(
              child: EmptyState(
                title: switch (filter) {
                  LibraryFilter.videos => l10n.libraryEmptyVideos,
                  LibraryFilter.photos => l10n.libraryEmptyPhotos,
                  LibraryFilter.all => l10n.libraryEmptyAll,
                },
                message: l10n.libraryEmptyMessage,
              ),
            ),
            AsyncData(value: final p) => _Grid(
              page: p,
              onTap: onTap,
              onNearEnd: () =>
                  ref.read(libraryItemsProvider(filter).notifier).loadMore(),
            ),
            AsyncError() => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: ErrorBanner(
                  message: l10n.libraryLoadError,
                  onRetry: () => ref.invalidate(libraryItemsProvider(filter)),
                ),
              ),
            ),
            _ => const _LoadingGrid(),
          },
        ),
      ],
    );
  }
}

int _columnsFor(double width) => width < _fourColumnMinWidth ? 3 : 4;

class _Grid extends ConsumerWidget {
  const new({required this.page, required this.onTap, required this.onNearEnd});

  final LibraryPage page;
  final ValueChanged<LibraryItem> onTap;
  final VoidCallback onNearEnd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final library = ref.watch(mediaLibraryProvider);
    final selection = ref.watch(mediaSelectionProvider);
    final columns = _columnsFor(MediaQuery.sizeOf(context).width);
    final ratio = MediaQuery.devicePixelRatioOf(context);

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.extentAfter < _loadMoreExtent) onNearEnd();
        return false;
      },
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          0,
          AppSpacing.screen,
          AppSpacing.lg,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: AppSpacing.xs,
          crossAxisSpacing: AppSpacing.xs,
        ),
        itemCount: page.items.length,
        itemBuilder: (context, i) {
          final item = page.items[i];
          final order = selection.indexOf(item);
          final duration = item.durationUs == null
              ? null
              : formatDuration(item.durationUs!);
          return MediaThumbnail(
            semanticLabel: item.kind == MediaKind.video
                ? l10n.videoItemSemantics(duration ?? '')
                : l10n.photoItemSemantics,
            image: Image(
              image: LibraryThumbnail(
                library,
                item.id,
                size: (MediaQuery.sizeOf(context).width / columns * ratio)
                    .round(),
              ),
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
            durationLabel: duration,
            selectionOrder: order < 0 ? null : order + 1,
            onTap: () => onTap(item),
          );
        },
      ),
    );
  }
}

class _LoadingGrid extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final columns = _columnsFor(MediaQuery.sizeOf(context).width);
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: AppSpacing.xs,
        crossAxisSpacing: AppSpacing.xs,
      ),
      itemCount: columns * 6,
      itemBuilder: (_, _) => const MediaThumbnail.loading(),
    );
  }
}

/// Explains why access is needed. Before asking: "Allow access". After a
/// refusal the system will not ask again, so: "Open settings".
class _PermissionView extends ConsumerWidget {
  const new({required this.asked});

  final bool asked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(libraryAccessControllerProvider.notifier);
    return Center(
      child: EmptyState(
        title: l10n.photosAccessTitle,
        message: asked ? l10n.photosDeniedMessage : l10n.photosAccessMessage,
        actionLabel: asked ? l10n.openSettings : l10n.allowAccess,
        primaryAction: true,
        onAction: asked ? controller.openSettings : controller.request,
      ),
    );
  }
}
