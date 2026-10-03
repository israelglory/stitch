import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stitch/core/time/time.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';
import 'package:stitch/features/editor/application/editor_state.dart';
import 'package:stitch/features/editor/presentation/editor_media.dart';
import 'package:stitch/features/editor/presentation/sheets/keyframe_sheets.dart';
import 'package:stitch/features/editor/presentation/transition_names.g.dart';
import 'package:stitch/features/projects/domain/project.dart';
import 'package:stitch/features/projects/presentation/format_screen.dart';
import 'package:stitch/features/timeline/domain/audio_ops.dart';
import 'package:stitch/features/timeline/domain/limits.dart';
import 'package:stitch/features/timeline/domain/models.dart';
import 'package:stitch/features/timeline/domain/transition_catalog.g.dart';
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
    // Scrolls where the tool is taller than the screen allows (a phone
    // held sideways).
    child: SingleChildScrollView(child: child),
  ),
);

String _speedText(AppLocalizations l10n, double v) =>
    l10n.valueSpeed(v.toStringAsFixed(2));

String _percentText(AppLocalizations l10n, double v) =>
    l10n.valuePercent((v * 100).round());

String _secondsText(AppLocalizations l10n, double us) =>
    l10n.valueSeconds((us / usPerSecond).toStringAsFixed(1));

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
    this.enabled = true,
  });

  final String projectId;
  final String label;
  final double min;
  final double max;
  final double Function(EditorState state) value;
  final String Function(double) format;
  final Timeline Function(Timeline base, double value) apply;

  /// Shown but not adjustable when false.
  final bool enabled;

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
      onChangeStart: enabled ? (_) => controller.beginGesture() : null,
      onChanged: enabled
          ? (v) => controller.updateGesture((b) => apply(b, v))
          : null,
      onChangeEnd: enabled ? (_) => controller.endGesture() : null,
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
      format: (v) => _speedText(l10n, v),
      value: (s) => isClip
          ? s.timeline.clipById(id)?.speed ?? 1
          : s.timeline.audioById(id)?.speed ?? 1,
      apply: (b, v) => isClip ? b.setClipSpeed(id, v) : b.setAudioSpeed(id, v),
    );
  }
}

/// Volume of a clip or an audio item, 0 to 200 percent, at the playhead
/// (a keyframe there once the item has keyframes).
class VolumeSheet extends StatelessWidget {
  const new({required this.projectId, required this.selection, super.key});

  final String projectId;
  final ItemSelection selection;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final owner = keyframeOwnerOf(selection);
    if (owner == null) return const SizedBox.shrink();
    return KeyframedSlider(
      projectId: projectId,
      owner: owner,
      label: l10n.toolVolume,
      min: TimelineLimits.minVolume,
      max: TimelineLimits.maxVolume,
      format: (v) => _percentText(l10n, v),
      read: (v) => v.volume,
      write: (v, x) => v.copyWith(volume: x),
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
          format: (v) => _secondsText(l10n, v),
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
          format: (v) => _secondsText(l10n, v),
          value: (s) =>
              (s.timeline.audioById(audioId)?.fadeOutUs ?? 0).toDouble(),
          apply: (b, v) => b.setAudioFades(audioId, fadeOutUs: v.round()),
        ),
      ],
    );
  }
}

/// Size of each transition preview tile.
const double _transitionTile = 64;

/// Width of a tile with its label: long names take two lines.
const double _transitionTileWidth = _transitionTile + AppSpacing.md;

/// Tiles in the fullest category (Basic also has None).
final int _largestCategory = TransitionCategory.values
    .map(
      (c) =>
          transitionCatalog.where((t) => t.category == c).length +
          (c == TransitionCategory.basic ? 1 : 0),
    )
    .reduce(math.max);

/// Transition for the cut after [clipId]: type grid with previews using
/// the two clips, duration, and apply to all.
class TransitionSheet extends ConsumerStatefulWidget {
  const new({required this.projectId, required this.clipId, super.key});

  final String projectId;
  final String clipId;

  @override
  ConsumerState<TransitionSheet> createState() => _TransitionSheetState();
}

class _TransitionSheetState extends ConsumerState<TransitionSheet> {
  /// The category shown; starts at the current transition's.
  TransitionCategory? _category;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(editorControllerProvider(widget.projectId)).value;
    if (state == null) return const SizedBox.shrink();
    final controller = ref.read(
      editorControllerProvider(widget.projectId).notifier,
    );
    final clipId = widget.clipId;
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

    if (maxUs <= 0 && current == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Text(
          l10n.transitionTooShort,
          style: AppTypography.body.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
      );
    }

    final category =
        _category ??
        transitionCatalog
            .where((t) => t.id == current?.type)
            .firstOrNull
            ?.category ??
        TransitionCategory.basic;
    final fromFrame = TransitionFrame(
      color: context.colors.surfaceRaised,
      image: MediaPoster.image(ref, state.project, from.mediaId),
    );
    // Until there are posters, two tones so the movement still shows.
    final toFrame = TransitionFrame(
      color: context.colors.textTertiary,
      image: MediaPoster.image(ref, state.project, to.mediaId),
    );
    Widget tile(String? type) => SizedBox(
      width: _transitionTileWidth,
      child: ChoiceTile(
        label: type == null ? l10n.transitionNone : transitionName(l10n, type),
        selected: current?.type == type,
        labelLines: 2,
        onTap: () => controller.apply((t) => t.setTransition(clipId, type)),
        visual: SizedBox.square(
          dimension: _transitionTile,
          child: TransitionPreview(
            transition: type,
            from: fromFrame,
            to: toFrame,
          ),
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final c in TransitionCategory.values)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
                  child: OptionChip(
                    label: transitionCategoryName(l10n, c),
                    selected: c == category,
                    onTap: () => setState(() => _category = c),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // As tall as the largest category, so switching categories never
        // moves the chips (a tap meant for the next one would land outside
        // the sheet and close it).
        Stack(
          children: [
            ExcludeSemantics(
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0,
                  child: Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.md,
                    children: [
                      for (var i = 0; i < _largestCategory; i++)
                        const SizedBox(
                          width: _transitionTileWidth,
                          child: ChoiceTile(
                            label: '\n',
                            labelLines: 2,
                            selected: false,
                            onTap: null,
                            visual: SizedBox.square(dimension: _transitionTile),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.md,
                alignment: WrapAlignment.center,
                children: [
                  if (category == TransitionCategory.basic) tile(null),
                  for (final t in transitionCatalog)
                    if (t.category == category) tile(t.id),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        // Always there (disabled with None chosen), so choosing the first
        // transition does not grow the sheet under the finger.
        if (maxUs > minUs)
          _EditSlider(
            projectId: widget.projectId,
            label: l10n.durationLabel,
            min: minUs.toDouble(),
            max: maxUs.toDouble(),
            format: (v) => _secondsText(l10n, v),
            enabled: current != null,
            value: (s) =>
                (s.timeline.transitionAfter(clipId)?.durationUs ??
                        TimelineLimits.defaultTransitionUs)
                    .toDouble(),
            apply: (b, v) => current == null
                ? b
                : b.setTransition(clipId, current.type, durationUs: v.round()),
          ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: AppTextButton(
            label: l10n.applyToAll,
            // With None chosen it would quietly remove every transition.
            onPressed: current == null
                ? null
                : () => controller.apply(
                    (t) => t.applyTransitionToAll(
                      current.type,
                      durationUs: current.durationUs,
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
          format: (v) => _percentText(l10n, v),
          value: (s) => s.timeline.audioMix.originalLevel,
          apply: (b, v) => b.setAudioMix(originalLevel: v),
        ),
        const SizedBox(height: AppSpacing.md),
        _EditSlider(
          projectId: projectId,
          label: l10n.addedAudioLevel,
          min: 0,
          max: TimelineLimits.maxVolume,
          format: (v) => _percentText(l10n, v),
          value: (s) => s.timeline.audioMix.addedLevel,
          apply: (b, v) => b.setAudioMix(addedLevel: v),
        ),
      ],
    );
  }
}
