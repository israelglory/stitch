import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stitch/core/time/time.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';
import 'package:stitch/features/editor/application/editor_state.dart';
import 'package:stitch/features/editor/presentation/editor_media.dart';
import 'package:stitch/features/projects/domain/project.dart';
import 'package:stitch/features/projects/presentation/format_screen.dart';
import 'package:stitch/features/timeline/domain/audio_ops.dart';
import 'package:stitch/features/timeline/domain/limits.dart';
import 'package:stitch/features/timeline/domain/models.dart';
import 'package:stitch/features/timeline/domain/transition_ops.dart';
import 'package:stitch/features/timeline/domain/video_ops.dart';
import 'package:stitch/l10n/generated/app_localizations.dart';

/// Opens an editor tool sheet. Tool sheets leave the preview undimmed so
/// the effect of a change stays visible.
Future<void> showToolSheet(
  BuildContext context, {
  required String title,
  required Widget child,
}) => showAppBottomSheet<void>(
  context: context,
  dimBackground: false,
  builder: (context) => AppBottomSheet(
    title: title,
    onConfirm: () => Navigator.of(context).pop(),
    child: child,
  ),
);

String _speedText(double v) => '${v.toStringAsFixed(2)}x';

String _percentText(double v) => '${(v * 100).round()}%';

String _secondsText(double us) => '${(us / usPerSecond).toStringAsFixed(1)}s';

/// A slider whose drag is one undoable edit. [value] is read from editor
/// state on every build, so undo and redo move it too.
class _EditSlider extends ConsumerWidget {
  const new({
    required this.projectId,
    required this.label,
    required this.min,
    required this.max,
    required this.value,
    required this.format,
    required this.apply,
  });

  final String projectId;
  final String label;
  final double min;
  final double max;
  final double Function(EditorState state) value;
  final String Function(double) format;
  final Timeline Function(Timeline base, double value) apply;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editorControllerProvider(projectId)).value;
    if (state == null) return const SizedBox.shrink();
    final controller = ref.read(editorControllerProvider(projectId).notifier);
    return AppSlider(
      label: label,
      value: clampDouble(value(state), min, max),
      min: min,
      max: math.max(max, min + 0.001),
      formatValue: format,
      onChangeStart: (_) => controller.beginGesture(),
      onChanged: (v) => controller.updateGesture((b) => apply(b, v)),
      onChangeEnd: (_) => controller.endGesture(),
    );
  }
}

/// Speed of a clip or an audio item.
class SpeedSheet extends StatelessWidget {
  const new({required this.projectId, required this.selection, super.key});

  final String projectId;
  final ItemSelection selection;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final id = selection.id;
    final isClip = selection is ClipSelected;
    return _EditSlider(
      projectId: projectId,
      label: l10n.toolSpeed,
      min: TimelineLimits.minSpeed,
      max: TimelineLimits.maxSpeed,
      format: _speedText,
      value: (s) => isClip
          ? s.timeline.clipById(id)?.speed ?? 1
          : s.timeline.audioById(id)?.speed ?? 1,
      apply: (b, v) => isClip ? b.setClipSpeed(id, v) : b.setAudioSpeed(id, v),
    );
  }
}

/// Volume of a clip or an audio item, 0 to 200 percent.
class VolumeSheet extends StatelessWidget {
  const new({required this.projectId, required this.selection, super.key});

  final String projectId;
  final ItemSelection selection;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final id = selection.id;
    final isClip = selection is ClipSelected;
    return _EditSlider(
      projectId: projectId,
      label: l10n.toolVolume,
      min: TimelineLimits.minVolume,
      max: TimelineLimits.maxVolume,
      format: _percentText,
      value: (s) => isClip
          ? s.timeline.clipById(id)?.volume ?? 1
          : s.timeline.audioById(id)?.volume ?? 1,
      apply: (b, v) =>
          isClip ? b.setClipVolume(id, v) : b.setAudioVolume(id, v),
    );
  }
}

/// Fade in and out of an audio item.
class FadeSheet extends ConsumerWidget {
  const new({required this.projectId, required this.audioId, super.key});

  final String projectId;
  final String audioId;

  /// Longest fade offered, whatever the item length.
  static const int _maxFadeUs = 5000000;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final item = ref.watch(
      editorControllerProvider(projectId)
          .select((s) => s.value?.timeline.audioById(audioId)),
    );
    if (item == null) return const SizedBox.shrink();
    final max = math.min(_maxFadeUs, item.durationUs).toDouble();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _EditSlider(
          projectId: projectId,
          label: l10n.fadeIn,
          min: 0,
          max: max,
          format: _secondsText,
          value: (s) =>
              (s.timeline.audioById(audioId)?.fadeInUs ?? 0).toDouble(),
          apply: (b, v) => b.setAudioFades(audioId, fadeInUs: v.round()),
        ),
        const SizedBox(height: AppSpacing.sm),
        _EditSlider(
          projectId: projectId,
          label: l10n.fadeOut,
          min: 0,
          max: max,
          format: _secondsText,
          value: (s) =>
              (s.timeline.audioById(audioId)?.fadeOutUs ?? 0).toDouble(),
          apply: (b, v) => b.setAudioFades(audioId, fadeOutUs: v.round()),
        ),
      ],
    );
  }
}

/// Transition types in the order shown.
const _transitionTypes = <TransitionType?>[
  null,
  TransitionType.crossfade,
  TransitionType.fadeToBlack,
  TransitionType.slideLeft,
  TransitionType.slideRight,
  TransitionType.wipeLeft,
  TransitionType.wipeRight,
  TransitionType.zoomIn,
];

String _transitionName(AppLocalizations l10n, TransitionType? type) =>
    switch (type) {
      null => l10n.transitionNone,
      TransitionType.crossfade => l10n.transitionCrossfade,
      TransitionType.fadeToBlack => l10n.transitionFadeToBlack,
      TransitionType.slideLeft => l10n.transitionSlideLeft,
      TransitionType.slideRight => l10n.transitionSlideRight,
      TransitionType.wipeLeft => l10n.transitionWipeLeft,
      TransitionType.wipeRight => l10n.transitionWipeRight,
      TransitionType.zoomIn => l10n.transitionZoomIn,
    };

TransitionLook _look(TransitionType? type) => switch (type) {
  null => TransitionLook.none,
  TransitionType.crossfade => TransitionLook.crossfade,
  TransitionType.fadeToBlack => TransitionLook.fadeToBlack,
  TransitionType.slideLeft => TransitionLook.slideLeft,
  TransitionType.slideRight => TransitionLook.slideRight,
  TransitionType.wipeLeft => TransitionLook.wipeLeft,
  TransitionType.wipeRight => TransitionLook.wipeRight,
  TransitionType.zoomIn => TransitionLook.zoomIn,
};

/// Size of each transition preview tile.
const double _transitionTile = 64;

/// Transition for the cut after [clipId]: type grid with previews using
/// the two clips, duration, and apply to all.
class TransitionSheet extends ConsumerWidget {
  const new({required this.projectId, required this.clipId, super.key});

  final String projectId;
  final String clipId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(editorControllerProvider(projectId)).value;
    if (state == null) return const SizedBox.shrink();
    final controller = ref.read(editorControllerProvider(projectId).notifier);
    final timeline = state.timeline;
    final index = timeline.indexOfClip(clipId);
    if (index < 0 || index + 1 >= timeline.videoClips.length) {
      return const SizedBox.shrink();
    }
    final from = timeline.videoClips[index];
    final to = timeline.videoClips[index + 1];
    final current = timeline.transitionAfter(clipId);
    final maxUs = timeline.maxTransitionUs(clipId);
    final minUs = math.min(TimelineLimits.minTransitionUs, maxUs);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.md,
          alignment: WrapAlignment.center,
          children: [
            for (final type in _transitionTypes)
              ChoiceTile(
                label: _transitionName(l10n, type),
                selected: current?.type == type,
                onTap: () =>
                    controller.apply((t) => t.setTransition(clipId, type)),
                visual: SizedBox.square(
                  dimension: _transitionTile,
                  child: TransitionPreview(
                    look: _look(type),
                    from: MediaPoster(
                      project: state.project,
                      mediaId: from.mediaId,
                    ),
                    to: MediaPoster(
                      project: state.project,
                      mediaId: to.mediaId,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (current != null && maxUs > minUs)
          _EditSlider(
            projectId: projectId,
            label: l10n.durationLabel,
            min: minUs.toDouble(),
            max: maxUs.toDouble(),
            format: _secondsText,
            value: (s) =>
                (s.timeline.transitionAfter(clipId)?.durationUs ?? minUs)
                    .toDouble(),
            apply: (b, v) =>
                b.setTransition(clipId, current.type, durationUs: v.round()),
          ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: AppTextButton(
            label: l10n.applyToAll,
            onPressed: () => controller.apply(
              (t) => t.applyTransitionToAll(
                current?.type,
                durationUs: current?.durationUs,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The project's aspect ratio.
class AspectSheet extends ConsumerWidget {
  const new({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preset = ref.watch(
      editorControllerProvider(projectId)
          .select((s) => s.value?.project.canvas.preset),
    );
    if (preset == null) return const SizedBox.shrink();
    return AspectRatioGrid(
      selected: preset,
      onSelected: (p) =>
          ref.read(editorControllerProvider(projectId).notifier).setCanvas(p),
    );
  }
}

/// What fills the canvas outside the video: a solid color or a blur.
class BackgroundSheet extends ConsumerWidget {
  const new({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final background = ref.watch(
      editorControllerProvider(projectId)
          .select((s) => s.value?.project.background),
    );
    if (background == null) return const SizedBox.shrink();
    final controller = ref.read(editorControllerProvider(projectId).notifier);
    final names = [
      l10n.colorBlack,
      l10n.colorCharcoal,
      l10n.colorGray,
      l10n.colorLightGray,
      l10n.colorWhite,
    ];
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final (i, color) in CanvasPalette.colors.indexed)
          ColorSwatchButton(
            color: color,
            semanticLabel: names[i],
            selected:
                background is SolidBackground &&
                background.color == color.toARGB32(),
            onTap: () => controller.setBackground(
              CanvasBackground.solid(color: color.toARGB32()),
            ),
          ),
        AppTextButton(
          label: l10n.backgroundBlur,
          neutral: background is! BlurBackground,
          onPressed: () =>
              controller.setBackground(const CanvasBackground.blur()),
        ),
      ],
    );
  }
}

/// Volume of the videos' own sound against added audio (music, effects,
/// voiceovers).
class BalanceSheet extends StatelessWidget {
  const new({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _EditSlider(
          projectId: projectId,
          label: l10n.originalSoundLevel,
          min: 0,
          max: TimelineLimits.maxVolume,
          format: _percentText,
          value: (s) => s.timeline.audioMix.originalLevel,
          apply: (b, v) => b.setAudioMix(originalLevel: v),
        ),
        const SizedBox(height: AppSpacing.md),
        _EditSlider(
          projectId: projectId,
          label: l10n.addedAudioLevel,
          min: 0,
          max: TimelineLimits.maxVolume,
          format: _percentText,
          value: (s) => s.timeline.audioMix.addedLevel,
          apply: (b, v) => b.setAudioMix(addedLevel: v),
        ),
      ],
    );
  }
}
