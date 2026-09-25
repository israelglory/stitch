import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stitch/app/failure_messages.dart';
import 'package:stitch/app/providers.dart';
import 'package:stitch/core/platform/system_services.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/engine/engine_provider.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';
import 'package:stitch/features/editor/application/filmstrip.dart';
import 'package:stitch/features/editor/application/playback_controller.dart';
import 'package:stitch/features/editor/presentation/editor_media.dart';
import 'package:stitch/features/export/application/export_controller.dart';
import 'package:stitch/features/export/domain/export_options.dart';
import 'package:stitch/features/timeline/domain/models.dart';
import 'package:stitch/l10n/generated/app_localizations.dart';

/// Exports with [options], showing progress with a frame of the video,
/// then the result: playback, where it was saved, Share, and Back to
/// editing. Or why it failed, with Retry.
class ExportScreen extends ConsumerStatefulWidget {
  const new({required this.projectId, required this.options, super.key});

  final String projectId;
  final ExportOptions options;

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  // Read up front: dispose may not use ref.
  late final ExportController _export;
  late final EditorController _editor;

  /// Whether the preview shows the export (so the editor must send its
  /// document again on leaving).
  bool _showingExport = false;

  @override
  void initState() {
    super.initState();
    _export = ref.read(exportControllerProvider(widget.projectId).notifier);
    _editor = ref.read(editorControllerProvider(widget.projectId).notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        _export.start(
          widget.options,
          progressTitle: AppLocalizations.of(context).exportingTitle,
        ),
      );
    });
  }

  @override
  void dispose() {
    if (_showingExport) _editor.resync();
    super.dispose();
  }

  Future<void> _confirmStop() async {
    final l10n = AppLocalizations.of(context);
    final stop = await showConfirmDialog(
      context: context,
      title: l10n.stopExportTitle,
      message: l10n.stopExportMessage,
      confirmLabel: l10n.stopExport,
      cancelLabel: l10n.keepExporting,
      destructive: true,
    );
    if (!stop || !mounted) return;
    // It may have finished while the question was open: then there is
    // nothing to stop, and the result stays on screen.
    final now = ref.read(exportControllerProvider(widget.projectId));
    if (now is! ExportRunning && now is! ExportIdle) return;
    if (now case ExportRunning(saving: true)) return;
    await _export.cancel();
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exportControllerProvider(widget.projectId));
    final running = state is ExportRunning || state is ExportIdle;
    return PopScope(
      canPop: !running,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // Saving to the gallery cannot be stopped; it takes a moment.
        if (state case ExportRunning(saving: true)) return;
        unawaited(_confirmStop());
      },
      child: Scaffold(
        body: SafeArea(
          child: switch (state) {
            ExportIdle() => _Progress(
              projectId: widget.projectId,
              fraction: 0,
              saving: false,
              onCancel: _confirmStop,
            ),
            ExportRunning(:final fraction, :final saving) => _Progress(
              projectId: widget.projectId,
              fraction: fraction,
              saving: saving,
              onCancel: _confirmStop,
            ),
            ExportDone() => _Done(
              projectId: widget.projectId,
              done: state,
              onShowing: () => _showingExport = true,
            ),
            ExportFailed(:final failure) => _Failed(
              failure: failure,
              onRetry: () => unawaited(_export.retry()),
            ),
          },
        ),
      ),
    );
  }
}

/// A frame of the video where the export is, the ring, and Cancel.
class _Progress extends ConsumerWidget {
  const new({
    required this.projectId,
    required this.fraction,
    required this.saving,
    required this.onCancel,
  });

  final String projectId;
  final double fraction;
  final bool saving;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final percent = (fraction * 100).floor();
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screen),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          Expanded(
            child: _CurrentFrame(projectId: projectId, fraction: fraction),
          ),
          const SizedBox(height: AppSpacing.xl),
          Semantics(
            label: l10n.exportProgressSemantics(percent),
            excludeSemantics: true,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ProgressRing(
                  value: saving ? null : fraction,
                  size: AppSizes.exportRing,
                ),
                Text(
                  l10n.valuePercent(percent),
                  style: AppTypography.title.semibold.tabular.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            saving
                ? (Platform.isIOS ? l10n.savingToPhotos : l10n.savingToGallery)
                : l10n.exportingTitle,
            textAlign: TextAlign.center,
            style: AppTypography.bodyLarge.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SecondaryButton(
            label: l10n.cancel,
            onPressed: saving ? null : onCancel,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

/// The source frame at the export's position: the clip under that time,
/// from the filmstrip cache (a photo shows its poster).
class _CurrentFrame extends ConsumerWidget {
  const new({required this.projectId, required this.fraction});

  final String projectId;
  final double fraction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editorControllerProvider(projectId)).value;
    if (state == null) return const SizedBox.shrink();
    final project = state.project;
    final at = (state.layout.durationUs * fraction).round();
    final anchor = state.layout.anchorAt(at);
    final clip = anchor is ClipAnchor
        ? state.timeline.videoClips
              .where((c) => c.id == anchor.clipId)
              .firstOrNull
        : null;
    final media = clip == null ? null : project.media[clip.mediaId];
    final Widget frame;
    if (clip == null || media == null) {
      frame = ColoredBox(color: context.colors.surfaceRaised);
    } else if (media.kind != MediaKind.video) {
      frame = MediaPoster(project: project, mediaId: media.id);
    } else {
      final path = ref
          .watch(projectStoreProvider)
          .resolve(project.id, media.path);
      frame = _FilmstripFrame(
        mediaPath: path,
        timeUs: (anchor as ClipAnchor).sourceUs,
        fallback: MediaPoster(project: project, mediaId: media.id),
      );
    }
    return Center(
      child: AspectRatio(
        aspectRatio: project.canvas.aspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: frame,
        ),
      ),
    );
  }
}

class _FilmstripFrame extends ConsumerWidget {
  const new({
    required this.mediaPath,
    required this.timeUs,
    required this.fallback,
  });

  final String mediaPath;
  final int timeUs;
  final Widget fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) => FutureBuilder<String?>(
    future: ref.watch(filmstripProvider).frame(mediaPath, timeUs),
    builder: (context, snapshot) {
      final path = snapshot.data;
      if (path == null) return fallback;
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => fallback,
      );
    },
  );
}

/// The exported video playing in the preview, where it was saved, and
/// what to do with it.
class _Done extends ConsumerStatefulWidget {
  const new({
    required this.projectId,
    required this.done,
    required this.onShowing,
  });

  final String projectId;
  final ExportDone done;
  final VoidCallback onShowing;

  @override
  ConsumerState<_Done> createState() => _DoneState();
}

class _DoneState extends ConsumerState<_Done> {
  late final SystemServices _system = ref.read(systemServicesProvider);
  double? _aspect;

  @override
  void initState() {
    super.initState();
    unawaited(_play());
  }

  /// Shows the exported file in the preview, as a one-clip document.
  Future<void> _play() async {
    final engine = ref.read(editorEngineProvider);
    try {
      final info = await engine.probe(widget.done.path);
      if (!mounted) return;
      widget.onShowing();
      setState(() => _aspect = info.width / math.max(1, info.height));
      await engine.setDocument(
        jsonEncode({
          'canvas': {
            'width': info.width,
            'height': info.height,
            'frameRate': math.max(1, info.frameRate.round()),
          },
          'background': {'type': 'solid', 'color': 0xFF000000},
          'media': {
            'export': {
              'path': widget.done.path,
              'kind': 'video',
              'durationUs': info.durationUs,
              'hasAudio': info.hasAudio,
            },
          },
          'composition': {
            'durationUs': info.durationUs,
            'clips': [
              {
                'clipId': 'export',
                'mediaId': 'export',
                'kind': 'video',
                'startUs': 0,
                'endUs': info.durationUs,
                'sourceInUs': 0,
                'sourceOutUs': info.durationUs,
                'speed': 1,
                'volume': 1,
                'audioFadeInUs': 0,
                'audioFadeOutUs': 0,
                'framing': {
                  'mode': 'fit',
                  'scale': 1,
                  'offsetX': 0,
                  'offsetY': 0,
                  'rotationDeg': 0,
                },
              },
            ],
          },
          'overlays': const <Object>[],
        }),
      );
      await ref.read(playbackControllerProvider.notifier).seek(0);
    } on Object {
      // No preview; the rest of the screen still works.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final done = widget.done;
    final texture = ref.watch(previewTextureProvider).value;
    final playing = ref.watch(
      playbackControllerProvider.select((p) => p.isPlaying),
    );
    final aspect = _aspect;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppHeader(
          title: l10n.exportDoneTitle,
          leading: AppIconButton(
            icon: AppIcons.close,
            semanticLabel: l10n.backToEditing,
            onPressed: () => context.pop(),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: Center(
              child: aspect == null
                  // Not playable here: the video's first frame instead.
                  ? _CurrentFrame(projectId: widget.projectId, fraction: 0)
                  : AspectRatio(
                      aspectRatio: aspect,
                      child: Semantics(
                        button: true,
                        label: l10n.playExport,
                        child: GestureDetector(
                          onTap: () => unawaited(
                            ref
                                .read(playbackControllerProvider.notifier)
                                .toggle(),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (texture != null)
                                  Texture(textureId: texture)
                                else
                                  ColoredBox(color: colors.surfaceRaised),
                                if (!playing)
                                  Center(
                                    child: Icon(
                                      AppIcons.play,
                                      size: AppSizes.exportPlayIcon,
                                      color: colors.onAccent,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SavedNote(
                saved: done.saved,
                onAllow: () => unawaited(
                  ref
                      .read(exportControllerProvider(widget.projectId).notifier)
                      .saveAgain(),
                ),
                onOpenSettings: () => unawaited(_system.openAppSettings()),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: l10n.share,
                icon: AppIcons.share,
                onPressed: () =>
                    unawaited(_system.share(done.path, mimeType: 'video/mp4')),
              ),
              if (done.captionsPath case final srt?) ...[
                const SizedBox(height: AppSpacing.xs),
                AppTextButton(
                  label: l10n.shareCaptions,
                  onPressed: () => unawaited(
                    _system.share(srt, mimeType: 'application/x-subrip'),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              SecondaryButton(
                label: l10n.backToEditing,
                onPressed: () => context.pop(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Where the export went, or why it could not be saved there.
class _SavedNote extends StatelessWidget {
  const new({
    required this.saved,
    required this.onAllow,
    required this.onOpenSettings,
  });

  final GallerySave saved;
  final VoidCallback onAllow;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return switch (saved) {
      GallerySave.saved => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            AppIcons.check,
            size: AppSizes.inlineIcon,
            color: colors.success,
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              Platform.isAndroid ? l10n.savedToGallery : l10n.savedToPhotos,
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            ),
          ),
        ],
      ),
      GallerySave.denied => ErrorBanner(
        message: l10n.saveDenied,
        retryLabel: l10n.allowAccess,
        onRetry: onAllow,
      ),
      GallerySave.permanentlyDenied => ErrorBanner(
        message: l10n.saveDenied,
        retryLabel: l10n.openSettings,
        onRetry: onOpenSettings,
      ),
    };
  }
}

/// Why the export failed, with Retry and Back to editing.
class _Failed extends StatelessWidget {
  const new({required this.failure, required this.onRetry});

  final Object failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Center(
              child: EmptyState(
                title: l10n.failureExport,
                message: switch (failureMessage(l10n, failure)) {
                  final m? when m != l10n.failureExport => m,
                  _ => l10n.exportFailedHint,
                },
              ),
            ),
          ),
          PrimaryButton(label: l10n.retry, onPressed: onRetry),
          const SizedBox(height: AppSpacing.sm),
          SecondaryButton(
            label: l10n.backToEditing,
            onPressed: () => context.pop(),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
