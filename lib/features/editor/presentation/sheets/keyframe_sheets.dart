import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';
import 'package:stitch/features/editor/application/keyframing.dart';
import 'package:stitch/features/editor/application/playback_controller.dart';
import 'package:stitch/features/timeline/domain/keyframes.dart';
import 'package:stitch/features/timeline/domain/models.dart';
import 'package:stitch/l10n/generated/app_localizations.dart';

/// A value of [owner] at the playhead, set with a slider. Without
/// keyframes it is the item's own value; once the item has keyframes, a
/// change records one at the playhead. One drag is one undo step.
class KeyframedSlider extends ConsumerWidget {
  const new({
    required this.projectId,
    required this.owner,
    required this.label,
    required this.min,
    required this.max,
    required this.format,
    required this.read,
    required this.write,
    super.key,
  });

  final String projectId;
  final KeyframeOwner owner;
  final String label;
  final double min;
  final double max;
  final String Function(double value) format;
  final double Function(KeyframeValues values) read;
  final KeyframeValues Function(KeyframeValues values, double value) write;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final values = ref.watch(
      valuesAtPlayheadProvider(projectId, owner.kind, owner.id),
    );
    if (values == null) return const SizedBox.shrink();
    final controller = ref.read(editorControllerProvider(projectId).notifier);
    return AppSlider(
      label: label,
      value: read(values).clamp(min, max),
      min: min,
      max: max,
      formatValue: format,
      onChangeStart: (_) => controller.beginGesture(),
      onChanged: (v) {
        final at = ref.read(playbackControllerProvider).positionUs;
        controller.updateGesture(
          (t) => t.setValuesAt(
            owner,
            at,
            (current) => write(current, v),
            newKeyframeId: controller.gestureKeyframeId,
          ),
        );
      },
      onChangeEnd: (_) => controller.endGesture(),
    );
  }
}

/// How see-through a clip or text is, 0 to 100 percent.
class OpacitySheet extends StatelessWidget {
  const new({required this.projectId, required this.owner, super.key});

  final String projectId;
  final KeyframeOwner owner;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return KeyframedSlider(
      projectId: projectId,
      owner: owner,
      label: l10n.toolOpacity,
      min: 0,
      max: 1,
      format: (v) => l10n.valuePercent((v * 100).round()),
      read: (v) => v.opacity,
      write: (v, x) => v.copyWith(opacity: x),
    );
  }
}

/// How values move from the keyframe under the playhead to the next one.
class EasingSheet extends ConsumerWidget {
  const new({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final target = ref.watch(keyframeTargetProvider(projectId));
    final keyframe = target?.current;
    if (target == null || keyframe == null) return const SizedBox.shrink();
    final controller = ref.read(editorControllerProvider(projectId).notifier);
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final easing in KeyframeEasing.values)
          OptionChip(
            label: _label(l10n, easing),
            selected: keyframe.easing == easing,
            onTap: () => controller.apply(
              (t) => t.setKeyframeEasing(target.owner, keyframe.id, easing),
            ),
          ),
      ],
    );
  }

  static String _label(AppLocalizations l10n, KeyframeEasing easing) =>
      switch (easing) {
        KeyframeEasing.linear => l10n.easingLinear,
        KeyframeEasing.easeIn => l10n.easingIn,
        KeyframeEasing.easeOut => l10n.easingOut,
        KeyframeEasing.easeInOut => l10n.easingInOut,
        KeyframeEasing.hold => l10n.easingHold,
      };
}
