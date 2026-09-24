import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:stitch/core/time/time.dart';
import 'package:stitch/design/components/pressable.dart';
import 'package:stitch/design/timeline/timeline_frame.dart';
import 'package:stitch/design/tokens.dart';

/// Time labels above the tracks. Picks a label interval that keeps labels
/// at least [_minLabelSpacing] apart at the current zoom, with dots between.
class TimeRuler extends StatelessWidget {
  const new({
    required this.pixelsPerSecond,
    required this.originX,
    this.durationUs,
    super.key,
  });

  final double pixelsPerSecond;

  /// X position of time zero within the ruler. Changes as the timeline
  /// scrolls.
  final double originX;

  /// Stops drawing after this time when set.
  final int? durationUs;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ExcludeSemantics(
      child: SizedBox(
        height: AppSizes.rulerHeight,
        width: double.infinity,
        child: CustomPaint(
          painter: _RulerPainter(
            pixelsPerSecond: pixelsPerSecond,
            originX: originX,
            durationUs: durationUs,
            color: colors.textTertiary,
            textScaler: MediaQuery.textScalerOf(context)
                .clamp(maxScaleFactor: kTimelineMaxTextScale),
          ),
        ),
      ),
    );
  }
}

const double _minLabelSpacing = 64;

/// Candidate label intervals, in seconds.
const _intervals = <double>[0.5, 1, 2, 5, 10, 15, 30, 60, 120, 300, 600];

/// Picks the smallest interval whose labels are at least
/// [_minLabelSpacing] apart. Exposed for tests.
double rulerInterval(double pixelsPerSecond) => _intervals.firstWhere(
  (s) => s * pixelsPerSecond >= _minLabelSpacing,
  orElse: () => _intervals.last,
);

class _RulerPainter extends CustomPainter {
  const new({
    required this.pixelsPerSecond,
    required this.originX,
    required this.durationUs,
    required this.color,
    required this.textScaler,
  });

  final double pixelsPerSecond;
  final double originX;
  final int? durationUs;
  final Color color;
  final TextScaler textScaler;

  static const int _dotsPerInterval = 2;
  static const double _dotRadius = 1;

  @override
  void paint(Canvas canvas, Size size) {
    if (pixelsPerSecond <= 0) return;
    final interval = rulerInterval(pixelsPerSecond);
    final step = interval * pixelsPerSecond;
    final endSeconds = durationUs == null
        ? double.infinity
        : usToSeconds(durationUs!);

    final first = math.max(0, ((-originX) / step).floor());
    final last = ((size.width - originX) / step).ceil();
    final dot = Paint()..color = color;
    final style = AppTypography.caption.tabular.copyWith(color: color);

    for (var i = first; i <= last; i++) {
      final seconds = i * interval;
      if (seconds > endSeconds) break;
      final x = originX + i * step;

      final label = TextPainter(
        text: TextSpan(
          text: interval < 1
              ? formatPreciseDuration(secondsToUs(seconds))
              : formatDuration(secondsToUs(seconds)),
          style: style,
        ),
        textDirection: TextDirection.ltr,
        textScaler: textScaler,
      )..layout();
      label.paint(
        canvas,
        Offset(x - label.width / 2, (size.height - label.height) / 2),
      );
      label.dispose();

      for (var d = 1; d <= _dotsPerInterval; d++) {
        final t = seconds + interval * d / (_dotsPerInterval + 1);
        if (t > endSeconds) break;
        canvas.drawCircle(
          Offset(x + step * d / (_dotsPerInterval + 1), size.height / 2),
          _dotRadius,
          dot,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_RulerPainter old) =>
      old.pixelsPerSecond != pixelsPerSecond ||
      old.originX != originX ||
      old.durationUs != durationUs ||
      old.color != color ||
      old.textScaler != textScaler;
}

/// The fixed center line marking the current time.
class Playhead extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: AppSizes.strokeWidth,
        decoration: BoxDecoration(
          color: context.colors.accent,
          borderRadius: BorderRadius.circular(AppSizes.strokeWidth / 2),
        ),
      ),
    );
  }
}

/// The fixed column at the start of a lane. On the main track it holds the
/// original sound toggle; on other lanes it labels the lane.
class LaneHeader extends StatelessWidget {
  const new({
    required this.icon,
    required this.label,
    this.height = AppSizes.laneHeight,
    this.onPressed,
    this.active = true,
    super.key,
  });

  final IconData icon;

  /// Shown under the icon on tall lanes; always the accessibility label.
  final String label;
  final double height;
  final VoidCallback? onPressed;

  /// False draws the header muted, for example when original sound is off.
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = active ? colors.textPrimary : colors.textTertiary;
    final showLabel = height >= AppSizes.videoTrackHeight;
    final content = SizedBox(
      width: AppSizes.laneHeaderWidth,
      height: height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: AppSizes.inlineIcon, color: color),
          if (showLabel) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(color: color),
            ),
          ],
        ],
      ),
    );
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: kTimelineMaxTextScale,
      child: onPressed == null
          ? Semantics(
              label: label,
              child: ExcludeSemantics(child: content),
            )
          : Pressable(
              onPressed: onPressed,
              semanticLabel: label,
              selected: active,
              minSize: Size.zero,
              child: content,
            ),
    );
  }
}
