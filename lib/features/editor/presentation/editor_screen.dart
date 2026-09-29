import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stitch/app/failure_messages.dart';
import 'package:stitch/app/router.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/features/captions/presentation/caption_progress.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';
import 'package:stitch/features/editor/application/editor_state.dart';
import 'package:stitch/features/editor/application/playback_controller.dart';
import 'package:stitch/features/editor/application/preview_copies.dart';
import 'package:stitch/features/editor/presentation/editor_toolbar.dart';
import 'package:stitch/features/editor/presentation/preview.dart';
import 'package:stitch/features/editor/presentation/sheets/tool_sheets.dart';
import 'package:stitch/features/editor/presentation/timeline_view.dart';
import 'package:stitch/features/export/presentation/export_sheet.dart';
import 'package:stitch/features/media/domain/library_item.dart';
import 'package:stitch/features/projects/presentation/import_progress_sheet.dart';
import 'package:stitch/l10n/generated/app_localizations.dart';

/// How the height left after the fixed rows is shared: 3 parts preview,
/// 2 parts timeline. The timeline keeps room to work in (several lanes
/// without scrolling) instead of shrinking to its content; full screen
/// shows the preview large.
const int _previewFlex = 3;
const int _timelineFlex = 2;

/// The editor: top bar, preview, playback row, timeline, tools.
class EditorScreen extends ConsumerStatefulWidget {
  const new({required this.projectId, super.key});

  final String projectId;

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  late final AppLifecycleListener _lifecycle;

  EditorController get _controller =>
      ref.read(editorControllerProvider(widget.projectId).notifier);

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      // Out of sight: stop playing (sound would go on in the background).
      onHide: () =>
          unawaited(ref.read(playbackControllerProvider.notifier).pause()),
      // Save before the system may stop the app.
      onPause: () => _controller.flush(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    await _controller.flush();
    if (mounted) context.go(AppRoutes.projects);
  }

  Future<void> _rename(String current) async {
    final l10n = AppLocalizations.of(context);
    final name = await showTextInputDialog(
      context: context,
      title: l10n.renameProjectTitle,
      confirmLabel: l10n.save,
      initialValue: current,
    );
    if (name != null) await _controller.rename(name);
  }

  Future<void> _addMedia() async {
    final items = await context.push<List<LibraryItem>>(
      AppRoutes.editorAdd(widget.projectId),
    );
    if (items == null || items.isEmpty || !mounted) return;
    await runWithImportProgress(context, () => _controller.addMedia(items));
  }

  /// The export sheet, then the export screen with what was chosen.
  Future<void> _export() async {
    final options = await showExportSheet(context, widget.projectId);
    if (options == null || !mounted) return;
    await context.push(
      AppRoutes.editorExport(widget.projectId),
      extra: options,
    );
  }

  /// Clips being prepared for this device, and clips it cannot play.
  List<Widget> _previewCopyBanners(EditorState state) {
    final l10n = AppLocalizations.of(context);
    final preparing = ref.watch(previewCopiesProvider(widget.projectId));
    final inUse = {for (final c in state.timeline.videoClips) c.mediaId};
    final failed = state.project.media.values
        .where((m) => m.previewCopyFailed && inUse.contains(m.id))
        .length;
    Widget padded(Widget banner) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: banner,
    );
    return [
      if (preparing > 0)
        padded(
          NoticeBanner(
            message: l10n.previewCopiesPreparing(preparing),
            busy: true,
          ),
        ),
      if (failed > 0)
        padded(
          ErrorBanner(
            message: l10n.previewCopyFailedNote(failed),
            onRetry: ref
                .read(previewCopiesProvider(widget.projectId).notifier)
                .retry,
          ),
        ),
    ];
  }

  /// Picks a file to stand in for the first missing one.
  Future<void> _relink() async {
    final mediaId = _controller.relinkableMedia;
    if (mediaId == null) return;
    final item = await context.push<LibraryItem>(
      AppRoutes.editorReplace(widget.projectId),
    );
    if (item == null || !mounted) return;
    await runWithImportProgress(
      context,
      () => _controller.relinkMedia(mediaId, item),
    );
  }

  void _openTransition(String clipId) {
    final l10n = AppLocalizations.of(context);
    unawaited(
      showToolSheet(
        context,
        title: l10n.transitionTitle,
        child: TransitionSheet(projectId: widget.projectId, clipId: clipId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final editor = ref.watch(editorControllerProvider(widget.projectId));

    // Back (Android's button or gesture) saves and goes to Projects, like
    // the close button; the editor is not stacked on Projects.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_close());
      },
      child: Scaffold(
        body: switch (editor) {
          AsyncData(value: final state) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppHeader(
                centerTitle: true,
                leading: AppIconButton(
                  icon: AppIcons.close,
                  semanticLabel: l10n.close,
                  onPressed: _close,
                ),
                titleWidget: Semantics(
                  button: true,
                  label: l10n.renameProjectSemantics(state.project.name),
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: () => _rename(state.project.name),
                    child: Text(
                      state.project.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyLarge.semibold.copyWith(
                        color: context.colors.textPrimary,
                      ),
                    ),
                  ),
                ),
                trailing: [
                  AppIconButton(
                    icon: AppIcons.undo,
                    semanticLabel: l10n.undo,
                    onPressed: state.canUndo ? _controller.undo : null,
                  ),
                  AppIconButton(
                    icon: AppIcons.redo,
                    semanticLabel: l10n.redo,
                    onPressed: state.canRedo ? _controller.redo : null,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  PrimaryButton(
                    label: l10n.export,
                    size: ButtonSize.small,
                    // Nothing to export, or files to relink first (the
                    // banner below says so).
                    onPressed:
                        state.timeline.videoClips.isEmpty ||
                            state.missingInUse.isNotEmpty
                        ? null
                        : () => unawaited(_export()),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
              ),
              if (state.saveFailed)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screen,
                  ),
                  child: ErrorBanner(
                    message: l10n.saveFailed,
                    onRetry: () => unawaited(_controller.flush()),
                  ),
                ),
              ..._previewCopyBanners(state),
              if (state.missingInUse.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screen,
                  ),
                  child: ErrorBanner(
                    message: l10n.missingMediaNote,
                    retryLabel: l10n.relink,
                    onRetry: _controller.relinkableMedia == null
                        ? null
                        : () => unawaited(_relink()),
                  ),
                ),
              Expanded(
                flex: _previewFlex,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.screen),
                  child: EditorPreview(projectId: widget.projectId),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screen,
                ),
                child: Row(
                  children: [
                    const Expanded(child: TimeReadout()),
                    const PlayButton(),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          KeyframeButton(projectId: widget.projectId),
                          AppIconButton(
                            icon: AppIcons.fullscreen,
                            semanticLabel: l10n.fullScreen,
                            onPressed: () => context.push(
                              AppRoutes.editorPreview(widget.projectId),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              CaptionProgress(projectId: widget.projectId),
              Expanded(
                flex: _timelineFlex,
                child: TimelineView(
                  projectId: widget.projectId,
                  onAddMedia: _addMedia,
                  onTransition: _openTransition,
                ),
              ),
              EditorToolbar(projectId: widget.projectId),
            ],
          ),
          AsyncError(:final error) => SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                EmptyState(
                  title: failureMessage(l10n, error) ?? l10n.failureGeneric,
                  message: l10n.editorLoadError,
                  actionLabel: l10n.retry,
                  primaryAction: true,
                  onAction: () => ref.invalidate(
                    editorControllerProvider(widget.projectId),
                  ),
                ),
                AppTextButton(
                  label: l10n.backToProjects,
                  onPressed: () => context.go(AppRoutes.projects),
                ),
              ],
            ),
          ),
          _ => const _EditorSkeleton(),
        },
      ),
    );
  }
}

/// Loading layout matching the editor.
class _EditorSkeleton extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: AppHeader.height),
          Expanded(
            flex: _previewFlex,
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xxl),
              child: Skeleton(),
            ),
          ),
          Expanded(
            flex: _timelineFlex,
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.screen),
                child: Skeleton(height: AppSizes.videoTrackHeight),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(AppSpacing.screen),
            child: Skeleton(height: AppSizes.toolbarHeight),
          ),
        ],
      ),
    );
  }
}
