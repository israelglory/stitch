import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:stitch/design/components/buttons.dart';
import 'package:stitch/design/components/progress.dart';
import 'package:stitch/design/icons.dart';
import 'package:stitch/design/tokens.dart';

/// A strip at the bottom of a screen while a sound plays on its own:
/// what is playing, how far along, and a stop button.
class MiniPlayer extends StatelessWidget {
  const new({
    required this.title,
    required this.progress,
    required this.stopLabel,
    required this.onStop,
    this.caption,
    super.key,
  });

  final String title;

  /// Small line above the title, such as "Now playing".
  final String? caption;

  /// 0 to 1.
  final double progress;
  final String stopLabel;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ColoredBox(
      color: colors.surfaceRaised,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(
            start: AppSpacing.screen,
            end: AppSpacing.xs,
            top: AppSpacing.sm,
            bottom: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (caption case final caption?)
                      Text(
                        caption,
                        style: AppTypography.caption.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body.semibold.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    LinearProgress(value: progress.clamp(0.0, 1.0)),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppIconButton(
                icon: AppIcons.stop,
                semanticLabel: stopLabel,
                onPressed: onStop,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum RecordButtonState { ready, countdown, recording }

/// The voiceover button: a red dot to record, a count while it starts, a
/// square to stop.
class RecordButton extends StatelessWidget {
  const new({
    required this.state,
    required this.semanticLabel,
    required this.onPressed,
    this.count = 0,
    super.key,
  });

  final RecordButtonState state;

  /// Seconds left, shown during [RecordButtonState.countdown].
  final int count;
  final String semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final duration = AppMotion.of(context, AppMotion.standard);
    final recording = state == RecordButtonState.recording;
    final inner = recording
        ? AppSizes.recordButton * 0.36
        : AppSizes.recordButton - AppSpacing.md;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: SizedBox.square(
          dimension: AppSizes.recordButton,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: colors.textPrimary,
                width: AppSizes.strokeWidth,
              ),
            ),
            child: Center(
              child: state == RecordButtonState.countdown
                  ? ExcludeSemantics(
                      child: Text(
                        '$count',
                        style: AppTypography.title.tabular.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    )
                  : AnimatedContainer(
                      duration: duration,
                      curve: AppMotion.curve,
                      width: inner,
                      height: inner,
                      decoration: BoxDecoration(
                        color: colors.destructive,
                        borderRadius: BorderRadius.circular(
                          recording ? AppRadius.small : inner / 2,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Recent microphone levels as bars, newest on the right.
class LevelMeter extends StatelessWidget {
  const new({required this.levels, super.key});

  /// 0 to 1, oldest first.
  final List<double> levels;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      height: AppSizes.levelMeter,
      width: double.infinity,
      child: CustomPaint(painter: _LevelPainter(levels, colors.laneVoiceover)),
    );
  }
}

class _LevelPainter extends CustomPainter {
  const new(this.levels, this.color);

  final List<double> levels;
  final Color color;

  static const double _bar = 2;
  static const double _gap = 2;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final mid = size.height / 2;
    final bars = (size.width / (_bar + _gap)).floor();
    for (var i = 0; i < math.min(bars, levels.length); i++) {
      final level = levels[levels.length - 1 - i].clamp(0.0, 1.0);
      // Speech sits low on a linear scale; a square root spreads it out.
      final h = math.max(1, math.sqrt(level) * mid);
      final x = size.width - (i + 1) * (_bar + _gap);
      canvas.drawRect(Rect.fromLTWH(x, mid - h, _bar, h * 2), paint);
    }
  }

  @override
  bool shouldRepaint(_LevelPainter old) => old.levels != levels;
}
