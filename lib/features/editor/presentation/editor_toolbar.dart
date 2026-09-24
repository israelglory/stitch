import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stitch/app/providers.dart';
import 'package:stitch/app/router.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';
import 'package:stitch/features/editor/application/editor_state.dart';
import 'package:stitch/features/editor/application/playback_controller.dart';
import 'package:stitch/features/editor/presentation/sheets/tool_sheets.dart';
import 'package:stitch/features/media/domain/library_item.dart';
import 'package:stitch/features/projects/presentation/import_progress_sheet.dart';
import 'package:stitch/features/timeline/domain/audio_ops.dart';
import 'package:stitch/features/timeline/domain/caption_ops.dart';
import 'package:stitch/features/timeline/domain/text_ops.dart';
import 'package:stitch/features/timeline/domain/video_ops.dart';
import 'package:stitch/l10n/generated/app_localizations.dart';

/// Tools for the current selection. Only tools that work are shown; text,
/// audio library, and captions tools arrive with their features.
class EditorToolbar extends ConsumerWidget {
  const new({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(editorControllerProvider(projectId)).value;
    if (state == null) return const SizedBox.shrink();
    final controller = ref.read(editorControllerProvider(projectId).notifier);
    final selection = state.selection;
    void deselect() => controller.select(const NoSelection());

    return switch (selection) {
      NoSelection() => ContextToolbar(
        items: [
          ToolbarItem(
            icon: AppIcons.edit,
            label: l10n.toolEdit,
            onPressed: state.timeline.videoClips.isEmpty
                ? null
                : () {
                    final position = ref
                        .read(playbackControllerProvider)
                        .positionUs;
                    final span = state.layout.spanAt(position);
                    if (span != null) {
                      controller.select(ClipSelected(span.clip.id));
                    }
                  },
          ),
          ToolbarItem(
            icon: AppIcons.aspectRatio,
            label: l10n.toolRatio,
            onPressed: () => showToolSheet(
              context,
              title: l10n.aspectRatioTitle,
              child: AspectSheet(projectId: projectId),
            ),
          ),
          ToolbarItem(
            icon: AppIcons.background,
            label: l10n.toolBackground,
            onPressed: () => showToolSheet(
              context,
              title: l10n.backgroundTitle,
              child: BackgroundSheet(projectId: projectId),
            ),
          ),
        ],
      ),
      ClipSelected(:final id) => _ClipTools(
        projectId: projectId,
        clipId: id,
        onBack: deselect,
      ),
      AudioSelected(:final id) => _AudioTools(
        projectId: projectId,
        audioId: id,
        onBack: deselect,
      ),
      TextSelected(:final id) => ContextToolbar(
        onBack: deselect,
        items: [
          ToolbarItem(
            icon: AppIcons.delete,
            label: l10n.delete,
            destructive: true,
            onPressed: () => controller.apply((t) => t.deleteText(id)),
          ),
        ],
      ),
      CaptionSelected(:final id) => ContextToolbar(
        onBack: deselect,
        items: [
          ToolbarItem(
            icon: AppIcons.delete,
            label: l10n.delete,
            destructive: true,
            onPressed: () => controller.apply((t) => t.deleteCaption(id)),
          ),
        ],
      ),
    };
  }
}

class _ClipTools extends ConsumerWidget {
  const new({
    required this.projectId,
    required this.clipId,
    required this.onBack,
  });

  final String projectId;
  final String clipId;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(editorControllerProvider(projectId)).requireValue;
    final controller = ref.read(editorControllerProvider(projectId).notifier);
    final clip = state.timeline.clipById(clipId);
    if (clip == null) return const SizedBox.shrink();
    final canSplit = ref.watch(
      playbackControllerProvider.select(
        (p) => state.timeline.canSplitClip(clipId, p.positionUs),
      ),
    );
    final hasSound =
        !clip.isPhoto &&
        !clip.audioDetached &&
        (state.project.media[clip.mediaId]?.hasAudio ?? true);

    return ContextToolbar(
      onBack: onBack,
      items: [
        ToolbarItem(
          icon: AppIcons.split,
          label: l10n.toolSplit,
          onPressed: canSplit
              ? () {
                  unawaited(AppHaptics.split());
                  final at = ref.read(playbackControllerProvider).positionUs;
                  final newId = ref.read(idGeneratorProvider).next();
                  controller.apply(
                    (t) => t.splitClip(clipId, at, newId: newId),
                  );
                }
              : null,
        ),
        ToolbarItem(
          icon: AppIcons.speed,
          label: l10n.toolSpeed,
          onPressed: () => showToolSheet(
            context,
            title: l10n.toolSpeed,
            child: SpeedSheet(
              projectId: projectId,
              selection: ClipSelected(clipId),
            ),
          ),
        ),
        ToolbarItem(
          icon: AppIcons.volume,
          label: l10n.toolVolume,
          onPressed: hasSound
              ? () => showToolSheet(
                  context,
                  title: l10n.toolVolume,
                  child: VolumeSheet(
                    projectId: projectId,
                    selection: ClipSelected(clipId),
                  ),
                )
              : null,
        ),
        ToolbarItem(
          icon: AppIcons.delete,
          label: l10n.delete,
          destructive: true,
          onPressed: () => controller.apply((t) => t.deleteClip(clipId)),
        ),
        ToolbarItem(
          icon: AppIcons.duplicate,
          label: l10n.duplicate,
          onPressed: () {
            final newId = ref.read(idGeneratorProvider).next();
            controller.apply((t) => t.duplicateClip(clipId, newId: newId));
          },
        ),
        ToolbarItem(
          icon: AppIcons.replace,
          label: l10n.toolReplace,
          onPressed: () async {
            final item = await context.push<LibraryItem>(
              AppRoutes.editorReplace(projectId),
            );
            if (item == null || !context.mounted) return;
            await runWithImportProgress(
              context,
              () => controller.replaceClip(clipId, item),
            );
          },
        ),
        ToolbarItem(
          icon: AppIcons.extractAudio,
          label: l10n.toolExtractAudio,
          onPressed: hasSound && state.timeline.canExtractAudio(clipId)
              ? () {
                  final newId = ref.read(idGeneratorProvider).next();
                  final name = l10n.extractedAudioName;
                  controller
                    ..apply(
                      (t) => t.extractAudio(clipId, newId: newId, name: name),
                    )
                    ..select(AudioSelected(newId));
                }
              : null,
        ),
      ],
    );
  }
}

class _AudioTools extends ConsumerWidget {
  const new({
    required this.projectId,
    required this.audioId,
    required this.onBack,
  });

  final String projectId;
  final String audioId;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(editorControllerProvider(projectId)).requireValue;
    final controller = ref.read(editorControllerProvider(projectId).notifier);
    final item = state.timeline.audioById(audioId);
    if (item == null) return const SizedBox.shrink();
    final canSplit = ref.watch(
      playbackControllerProvider.select(
        (p) => state.timeline.canSplitAudio(audioId, p.positionUs),
      ),
    );

    return ContextToolbar(
      onBack: onBack,
      items: [
        ToolbarItem(
          icon: AppIcons.volume,
          label: l10n.toolVolume,
          onPressed: () => showToolSheet(
            context,
            title: l10n.toolVolume,
            child: VolumeSheet(
              projectId: projectId,
              selection: AudioSelected(audioId),
            ),
          ),
        ),
        ToolbarItem(
          icon: AppIcons.fade,
          label: l10n.toolFade,
          onPressed: () => showToolSheet(
            context,
            title: l10n.toolFade,
            child: FadeSheet(projectId: projectId, audioId: audioId),
          ),
        ),
        ToolbarItem(
          icon: AppIcons.split,
          label: l10n.toolSplit,
          onPressed: canSplit
              ? () {
                  unawaited(AppHaptics.split());
                  final at = ref.read(playbackControllerProvider).positionUs;
                  final newId = ref.read(idGeneratorProvider).next();
                  controller.apply(
                    (t) => t.splitAudio(audioId, at, newId: newId),
                  );
                }
              : null,
        ),
        ToolbarItem(
          icon: AppIcons.speed,
          label: l10n.toolSpeed,
          onPressed: () => showToolSheet(
            context,
            title: l10n.toolSpeed,
            child: SpeedSheet(
              projectId: projectId,
              selection: AudioSelected(audioId),
            ),
          ),
        ),
        ToolbarItem(
          icon: AppIcons.loop,
          label: l10n.toolLoop,
          selected: item.loop,
          onPressed: () => controller.apply(
            (t) => t.setAudioLoop(audioId, loop: !item.loop),
          ),
        ),
        ToolbarItem(
          icon: AppIcons.delete,
          label: l10n.delete,
          destructive: true,
          onPressed: () => controller.apply((t) => t.deleteAudio(audioId)),
        ),
      ],
    );
  }
}
