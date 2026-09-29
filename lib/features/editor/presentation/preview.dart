import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stitch/core/time/time.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/engine/engine_provider.dart';
import 'package:stitch/features/captions/presentation/caption_preview_layer.dart';
import 'package:stitch/features/editor/application/clip_frame_preview.dart';
import 'package:stitch/features/editor/application/current_clip.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';
import 'package:stitch/features/editor/application/keyframing.dart';
import 'package:stitch/features/editor/application/playback_controller.dart';
import 'package:stitch/features/editor/presentation/editor_media.dart';
import 'package:stitch/features/projects/domain/project.dart';
import 'package:stitch/features/text/presentation/text_overlay_layer.dart';
import 'package:stitch/features/timeline/domain/keyframes.dart';
import 'package:stitch/features/timeline/domain/models.dart';
import 'package:stitch/l10n/generated/app_localizations.dart';

/// Blur applied to the "blurred copy" canvas background.
const double _backgroundBlur = 24;

/// The video canvas at the project's aspect ratio. The native engines
/// render the composition here; with the fake engine it shows the poster
/// of the clip under the playhead. Text being edited is drawn on top by
/// [TextOverlayLayer], which also handles taps on the canvas; tapping
/// elsewhere toggles playback.
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
    final frame = ref.watch(clipFramePreviewProvider(projectId));
    if (project == null) return const SizedBox.shrink();
    final framed = frame == null
        ? null
        : project.timeline.clipById(frame.clipId);

    return Semantics(
      button: true,
      label: playing ? l10n.pause : l10n.play,
      onTap: () => ref.read(playbackControllerProvider.notifier).toggle(),
      child: GestureDetector(
        // The Semantics above already offers the tap.
        excludeFromSemantics: true,
        behavior: HitTestBehavior.opaque,
        onTap: () =>
            unawaited(ref.read(playbackControllerProvider.notifier).toggle()),
        child: Center(
          child: AspectRatio(
            aspectRatio: project.canvas.aspectRatio,
            child: ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // The native engine renders the full composition; the
                  // fake engine has no frames, so show the clip's poster.
                  if (texture != null)
                    Texture(
                      textureId: texture,
                      filterQuality: FilterQuality.medium,
                    )
                  else
                    _PlayheadCanvas(
                      projectId: projectId,
                      project: project,
                      clip: clip,
                    ),
                  if (texture == null)
                    CaptionPreviewLayer(projectId: projectId),
                  TextOverlayLayer(
                    projectId: projectId,
                    drawAll: texture == null,
                  ),
                  // While a clip is edited by hand: its frame, placed by
                  // its values at that moment.
                  if (frame != null && framed != null)
                    _Canvas(
                      project: project,
                      clip: framed,
                      values: project.timeline.valuesAt((
                        kind: KeyframeOwnerKind.clip,
                        id: framed.id,
                      ), frame.atUs),
                      image: MemoryImage(frame.image),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// [_Canvas] for the clip under the playhead, placed by its values there.
class _PlayheadCanvas extends ConsumerWidget {
  const new({
    required this.projectId,
    required this.project,
    required this.clip,
  });

  final String projectId;
  final Project project;
  final VideoClip? clip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clip = this.clip;
    final values = clip == null
        ? null
        : ref.watch(
            valuesAtPlayheadProvider(
              projectId,
              KeyframeOwnerKind.clip,
              clip.id,
            ),
          );
    return _Canvas(project: project, clip: clip, values: values);
  }
}

/// One clip drawn as the engine would: its framing (moved, zoomed, and
/// turned by [values] when given) and opacity over the project's
/// background. Shows the clip's poster, or [image] (a frame of it).
class _Canvas extends StatelessWidget {
  const new({
    required this.project,
    required this.clip,
    this.values,
    this.image,
  });

  final Project project;
  final VideoClip? clip;
  final KeyframeValues? values;
  final ImageProvider? image;

  Widget _picture(VideoClip clip, {BoxFit fit = BoxFit.cover}) =>
      switch (image) {
        final image? => Image(image: image, fit: fit, gaplessPlayback: true),
        null => MediaPoster(project: project, mediaId: clip.mediaId, fit: fit),
      };

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
        child: _picture(clip),
      ),
      BlurBackground() => ColoredBox(color: context.colors.background),
    };
    if (clip == null) return background;

    final framing = clip.framing;
    final v =
        values ??
        KeyframeValues(
          x: framing.offsetX,
          y: framing.offsetY,
          scale: framing.scale,
          rotationDeg: framing.rotationDeg,
          opacity: clip.opacity,
        );
    return Stack(
      fit: StackFit.expand,
      children: [
        background,
        LayoutBuilder(
          builder: (context, box) => Opacity(
            opacity: v.opacity.clamp(0.0, 1.0),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..translateByDouble(
                  v.x * box.maxWidth,
                  v.y * box.maxHeight,
                  0,
                  1,
                )
                ..rotateZ(v.rotationDeg * math.pi / 180)
                ..scaleByDouble(v.scale, v.scale, 1, 1),
              child: _picture(
                clip,
                fit: framing.mode == FramingMode.fill
                    ? BoxFit.cover
                    : BoxFit.contain,
              ),
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

/// Adds a keyframe to the selected clip, text, or sound at the playhead,
/// or removes the one there. Disabled with nothing selected, or with the
/// playhead outside the selected item.
class KeyframeButton extends ConsumerWidget {
  const new({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final target = ref.watch(keyframeTargetProvider(projectId));
    final onKeyframe = target?.current != null;
    return AppIconButton(
      icon: onKeyframe ? AppIcons.keyframeRemove : AppIcons.keyframeAdd,
      semanticLabel: onKeyframe ? l10n.keyframeRemove : l10n.keyframeAdd,
      color: onKeyframe ? context.colors.accent : null,
      onPressed: target == null
          ? null
          : () {
              unawaited(AppHaptics.selection());
              ref
                  .read(editorControllerProvider(projectId).notifier)
                  .toggleKeyframe(
                    ref.read(playbackControllerProvider).positionUs,
                  );
              // The button's new label is not read out on its own.
              unawaited(
                SemanticsService.sendAnnouncement(
                  View.of(context),
                  onKeyframe ? l10n.keyframeRemoved : l10n.keyframeAdded,
                  Directionality.of(context),
                ),
              );
            },
    );
  }
}
