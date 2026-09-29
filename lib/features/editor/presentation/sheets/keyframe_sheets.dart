import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/features/editor/application/clip_frame_preview.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';
import 'package:stitch/features/editor/application/keyframing.dart';
import 'package:stitch/features/editor/application/playback_controller.dart';
import 'package:stitch/features/timeline/domain/keyframes.dart';
import 'package:stitch/features/timeline/domain/limits.dart';
import 'package:stitch/features/timeline/domain/models.dart';
import 'package:stitch/l10n/generated/app_localizations.dart';

/// A value of [owner] at the playhead, set with a slider. Without
/// keyframes it is the item's own value; once the item has keyframes, a
/// change records one at the playhead. One drag is one undo step.
///
/// The engine gets the edit when the drag ends, so with [showFrame] a
/// clip's frame is drawn over the preview meanwhile, placed by the values
/// as they change (as when it is dragged on the canvas).
class KeyframedSlider extends ConsumerStatefulWidget {
  const new({
    required this.projectId,
    required this.owner,
    required this.label,
    required this.min,
    required this.max,
    required this.format,
    required this.read,
    required this.write,
    this.showFrame = false,
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
  final bool showFrame;

  @override
  ConsumerState<KeyframedSlider> createState() => _KeyframedSliderState();
}

class _KeyframedSliderState extends ConsumerState<KeyframedSlider> {
  /// The clip's frame is showing for this drag.
  bool _following = false;

  /// Starts showing the clip's frame at the playhead, when there is one.
  bool _follow() {
    final owner = widget.owner;
    if (!widget.showFrame || owner.kind != KeyframeOwnerKind.clip) {
      return false;
    }
    final state = ref.read(editorControllerProvider(widget.projectId)).value;
    final playback = ref.read(playbackControllerProvider);
    final sourceUs = state?.timeline.keyframeTimeAt(
      owner,
      playback.positionUs,
      state.layout,
    );
    if (sourceUs == null) return false;
    if (playback.isPlaying) {
      unawaited(ref.read(playbackControllerProvider.notifier).pause());
    }
    ref
        .read(clipFramePreviewProvider(widget.projectId).notifier)
        .follow(owner.id, sourceUs);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final owner = widget.owner;
    final values = ref.watch(
      valuesAtPlayheadProvider(widget.projectId, owner.kind, owner.id),
    );
    if (values == null) return const SizedBox.shrink();
    final controller = ref.read(
      editorControllerProvider(widget.projectId).notifier,
    );
    return AppSlider(
      label: widget.label,
      value: widget.read(values).clamp(widget.min, widget.max),
      min: widget.min,
      max: widget.max,
      formatValue: widget.format,
      onChangeStart: (_) {
        _following = _follow();
        controller.beginGesture();
      },
      onChanged: (v) {
        final at = ref.read(playbackControllerProvider).positionUs;
        controller.updateGesture(
          (t) => t.setValuesAt(
            owner,
            at,
            (current) => widget.write(current, v),
            newKeyframeId: controller.gestureKeyframeId,
          ),
        );
      },
      onChangeEnd: (_) {
        controller.endGesture();
        // After the edit is sent: the frame stays until the engine shows it.
        if (_following) {
          ref.read(clipFramePreviewProvider(widget.projectId).notifier).end();
        }
        _following = false;
      },
    );
  }
}

/// Where a clip or text sits: across, down, zoom, and turn. The same as
/// dragging, pinching, and twisting it on the preview, for exact values
/// and for screen readers; keyframed like them.
class TransformSheet extends StatelessWidget {
  const new({required this.projectId, required this.owner, super.key});

  final String projectId;
  final KeyframeOwner owner;

  static double _log2(double v) => math.log(v) / math.ln2;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String percent(double v) => l10n.valuePercent((v * 100).round());
    // A clip's place is an offset from the center; text's is its center.
    final (double low, double high) = owner.kind == KeyframeOwnerKind.clip
        ? (-1, 1)
        : (0, 1);
    KeyframedSlider slider({
      required String label,
      required double min,
      required double max,
      required String Function(double value) format,
      required double Function(KeyframeValues values) read,
      required KeyframeValues Function(KeyframeValues values, double v) write,
    }) => KeyframedSlider(
      projectId: projectId,
      owner: owner,
      label: label,
      min: min,
      max: max,
      format: format,
      read: read,
      write: write,
      showFrame: true,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        slider(
          label: l10n.transformHorizontal,
          min: low,
          max: high,
          format: percent,
          read: (v) => v.x,
          write: (v, x) => v.copyWith(x: x),
        ),
        slider(
          label: l10n.transformVertical,
          min: low,
          max: high,
          format: percent,
          read: (v) => v.y,
          write: (v, y) => v.copyWith(y: y),
        ),
        // On a doubling scale, so 50 to 200 percent gets as much of the
        // slider as 200 to 800.
        slider(
          label: l10n.transformZoom,
          min: _log2(TimelineLimits.minScale),
          max: _log2(TimelineLimits.maxScale),
          format: (v) => percent(math.pow(2, v).toDouble()),
          read: (v) => _log2(v.scale),
          write: (v, s) => v.copyWith(scale: math.pow(2, s).toDouble()),
        ),
        slider(
          label: l10n.transformRotation,
          min: -180,
          max: 180,
          format: (v) => l10n.valueDegrees(v.round()),
          read: (v) => v.rotationDeg,
          write: (v, r) => v.copyWith(rotationDeg: r),
        ),
      ],
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
      showFrame: true,
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
