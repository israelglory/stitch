import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stitch/core/time/time.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/engine/engine_provider.dart';
import 'package:stitch/features/editor/application/current_clip.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';
import 'package:stitch/features/editor/application/playback_controller.dart';
import 'package:stitch/features/editor/presentation/editor_media.dart';
import 'package:stitch/features/projects/domain/project.dart';
import 'package:stitch/features/timeline/domain/models.dart';
import 'package:stitch/l10n/generated/app_localizations.dart';

/// Blur applied to the "blurred copy" canvas background.
const double _backgroundBlur = 24;

/// The video canvas at the project's aspect ratio. With the fake engine
/// it shows the poster of the clip under the playhead; the native engines
/// render real frames here (M5, M6). Tapping toggles playback.
class EditorPreview extends ConsumerWidget {
  const new({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final project = ref.watch(
      editorControllerProvider(projectId).select((s) => s.value?.project),
    );
    final clip = ref.watch(clipAtPlayheadProvider(projectId));
    final texture = ref.watch(previewTextureProvider).value;
    final playing = ref.watch(
      playbackControllerProvider.select((p) => p.isPlaying),
    );
    if (project == null) return const SizedBox.shrink();

    return Semantics(
      button: true,
      label: playing ? l10n.pause : l10n.play,
      onTap: () => ref.read(playbackControllerProvider.notifier).toggle(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () =>
            unawaited(ref.read(playbackControllerProvider.notifier).toggle()),
        child: Center(
          child: AspectRatio(
            aspectRatio: project.canvas.aspectRatio,
            child: ClipRect(
              // The native engine renders the full composition; the fake
              // engine has no frames, so show the clip's poster.
              child: texture != null
                  ? Texture(
                      textureId: texture,
                      filterQuality: FilterQuality.medium,
                    )
                  : _Canvas(project: project, clip: clip),
            ),
          ),
        ),
      ),
    );
  }
}

class _Canvas extends StatelessWidget {
  const new({required this.project, required this.clip});

  final Project project;
  final VideoClip? clip;

  @override
  Widget build(BuildContext context) {
    final clip = this.clip;
    final background = switch (project.background) {
      SolidBackground(:final color) => ColoredBox(
        color: CanvasPalette.fromArgb(color),
      ),
      BlurBackground() when clip != null => ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: _backgroundBlur,
          sigmaY: _backgroundBlur,
        ),
        child: MediaPoster(project: project, mediaId: clip.mediaId),
      ),
      BlurBackground() => ColoredBox(color: context.colors.background),
    };
    if (clip == null) return background;

    final framing = clip.framing;
    return Stack(
      fit: StackFit.expand,
      children: [
        background,
        LayoutBuilder(
          builder: (context, box) => Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..translateByDouble(
                framing.offsetX * box.maxWidth,
                framing.offsetY * box.maxHeight,
                0,
                1,
              )
              ..rotateZ(framing.rotationDeg * math.pi / 180)
              ..scaleByDouble(framing.scale, framing.scale, 1, 1),
            child: MediaPoster(
              project: project,
              mediaId: clip.mediaId,
              fit: framing.mode == FramingMode.fill
                  ? BoxFit.cover
                  : BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }
}

/// Current time and total length, with tabular figures so the text does
/// not jitter. Rebuilds with the playhead; it is a small leaf.
class TimeReadout extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final (position, duration) = ref.watch(
      playbackControllerProvider.select((p) => (p.positionUs, p.durationUs)),
    );
    final now = formatDuration(position);
    final total = formatDuration(duration);
    return Semantics(
      label: l10n.playheadSemantics(now, total),
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: now,
              style: AppTypography.body.tabular.copyWith(
                color: colors.textPrimary,
              ),
            ),
            TextSpan(text: ' / $total'),
          ],
        ),
        style: AppTypography.body.tabular.copyWith(color: colors.textSecondary),
      ),
    );
  }
}

/// Play or pause.
class PlayButton extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final playing = ref.watch(
      playbackControllerProvider.select((p) => p.isPlaying),
    );
    return AppIconButton(
      icon: playing ? AppIcons.pause : AppIcons.play,
      semanticLabel: playing ? l10n.pause : l10n.play,
      onPressed: () => ref.read(playbackControllerProvider.notifier).toggle(),
    );
  }
}
