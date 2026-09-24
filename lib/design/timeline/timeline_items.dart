import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:stitch/design/components/media.dart';
import 'package:stitch/design/components/pressable.dart';
import 'package:stitch/design/icons.dart';
import 'package:stitch/design/timeline/timeline_frame.dart';
import 'package:stitch/design/tokens.dart';

/// Below this width a clip has no room for its duration and speed labels.
const double _minLabelledClipWidth = 72;

/// A clip on the main video track: a strip of square thumbnails. When
/// selected, shows the accent frame with trim handles and its duration.
class VideoClipTile extends StatelessWidget {
  const new({
    required this.width,
    required this.frameBuilder,
    required this.durationLabel,
    required this.onTap,
    this.selected = false,
    this.speedLabel,
    this.isMissing = false,
    this.trim,
    super.key,
  });

  final double width;

  /// Builds thumbnail `index` of the strip (usually an Image). The strip
  /// has one square frame per [AppSizes.videoTrackHeight] of width.
  final Widget Function(BuildContext context, int index) frameBuilder;
  final String durationLabel;
  final VoidCallback? onTap;
  final bool selected;

  /// Shown when the clip's speed is not 1x, for example "2x".
  final String? speedLabel;

  /// The source file can no longer be found.
  final bool isMissing;
  final TrimCallbacks? trim;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final frameCount = math.max(1, (width / AppSizes.videoTrackHeight).ceil());
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: kTimelineMaxTextScale,
      child: SizedBox(
        width: width,
        height: AppSizes.videoTrackHeight,
        child: Pressable(
          onPressed: onTap,
          semanticLabel: durationLabel,
          selected: selected,
          minSize: Size.zero,
          child: TimelineItemFrame(
            selected: selected,
            trim: trim,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.control),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (isMissing)
                    ColoredBox(
                      color: colors.surfaceRaised,
                      child: Icon(
                        AppIcons.alert,
                        size: AppSizes.inlineIcon,
                        color: colors.destructive,
                      ),
                    )
                  else
                    ClipRect(
                      child: OverflowBox(
                        alignment: AlignmentDirectional.centerStart,
                        maxWidth: frameCount * AppSizes.videoTrackHeight,
                        child: Row(
                          children: [
                            for (var i = 0; i < frameCount; i++)
                              SizedBox.square(
                                dimension: AppSizes.videoTrackHeight,
                                child: frameBuilder(context, i),
                              ),
                          ],
                        ),
                      ),
                    ),
                  if ((speedLabel != null || selected) &&
                      width >= _minLabelledClipWidth)
                    PositionedDirectional(
                      start: selected
                          ? AppSizes.trimHandleWidth + AppSpacing.xs
                          : AppSpacing.xs,
                      top: AppSpacing.xs,
                      end: AppSpacing.xs,
                      child: ClipRect(
                        child: Row(
                          children: [
                            if (selected) MediaLabel(durationLabel),
                            if (selected && speedLabel != null)
                              const SizedBox(width: AppSpacing.xs),
                            if (speedLabel != null) MediaLabel(speedLabel!),
                          ],
                        ),
                      ),
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

/// The control between two clips that opens the transitions sheet. A
/// circular icon button, filled with the accent when a transition is set.
class TransitionButton extends StatelessWidget {
  const new({
    required this.semanticLabel,
    required this.onPressed,
    this.hasTransition = false,
    this.selected = false,
    super.key,
  });

  /// For example "Transition between clip 1 and 2".
  final String semanticLabel;
  final VoidCallback? onPressed;
  final bool hasTransition;

  /// True while its sheet is open.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Pressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      selected: selected,
      child: SizedBox.square(
        dimension: AppSizes.minTouchTarget,
        child: Center(
          child: Container(
            width: AppSizes.transitionButton,
            height: AppSizes.transitionButton,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hasTransition ? colors.accent : colors.surfaceRaised,
              border: Border.all(
                color: selected
                    ? colors.textPrimary
                    : hasTransition
                    ? colors.accent
                    : colors.border,
                width: selected ? AppSizes.strokeWidth : AppSizes.borderWidth,
              ),
            ),
            child: Icon(
              AppIcons.transition,
              size: AppSizes.microIcon,
              color: hasTransition ? colors.onAccent : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

enum OverlayKind { text, caption }

/// A text or caption item on its lane.
class OverlayItemTile extends StatelessWidget {
  const new({
    required this.kind,
    required this.label,
    required this.width,
    required this.onTap,
    this.selected = false,
    this.needsReview = false,
    this.trim,
    super.key,
  });

  final OverlayKind kind;
  final String label;
  final double width;
  final VoidCallback? onTap;
  final bool selected;

  /// The clip this item was anchored to was deleted; the user should check
  /// its position.
  final bool needsReview;
  final TrimCallbacks? trim;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final lane = kind == OverlayKind.text
        ? colors.laneText
        : colors.laneCaptions;
    return _LaneItem(
      width: width,
      laneColor: lane,
      onTap: onTap,
      semanticLabel: label,
      selected: selected,
      trim: trim,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: selected
              ? AppSizes.trimHandleWidth + AppSpacing.xs
              : AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(
              needsReview
                  ? AppIcons.alert
                  : kind == OverlayKind.text
                  ? AppIcons.text
                  : AppIcons.captions,
              size: AppSizes.microIcon,
              color: needsReview ? colors.destructive : lane,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.clip,
                softWrap: false,
                style: AppTypography.caption.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum AudioKind { music, soundEffect, voiceover, extracted }

/// An audio item on an audio lane, with its waveform and fades.
class AudioItemTile extends StatelessWidget {
  const new({
    required this.kind,
    required this.label,
    required this.width,
    required this.onTap,
    this.waveform,
    this.fadeInPx = 0,
    this.fadeOutPx = 0,
    this.overflowStartPx,
    this.selected = false,
    this.needsReview = false,
    this.trim,
    super.key,
  });

  final AudioKind kind;
  final String label;
  final double width;
  final VoidCallback? onTap;

  /// Peak amplitudes from 0 to 1, evenly spaced across the item. Null
  /// while the waveform is being generated.
  final List<double>? waveform;

  /// Widths of the fade ramps in pixels.
  final double fadeInPx;
  final double fadeOutPx;

  /// Where the video ends, in pixels from the item's start, when the item
  /// runs past it. That part is dimmed because export trims it.
  final double? overflowStartPx;
  final bool selected;
  final bool needsReview;
  final TrimCallbacks? trim;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final lane = kind == AudioKind.voiceover
        ? colors.laneVoiceover
        : colors.laneAudio;
    return _LaneItem(
      width: width,
      laneColor: lane,
      onTap: onTap,
      semanticLabel: label,
      selected: selected,
      trim: trim,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _WaveformPainter(
              samples: waveform,
              color: lane,
              fadeInPx: fadeInPx,
              fadeOutPx: fadeOutPx,
              fadeColor: colors.overlay,
              overflowStartPx: overflowStartPx,
              overflowColor: colors.overlay,
              markerColor: colors.textSecondary,
            ),
          ),
          PositionedDirectional(
            start: selected
                ? AppSizes.trimHandleWidth + AppSpacing.xs / 2
                : AppSpacing.xs,
            end: AppSpacing.sm,
            top: 0,
            bottom: 0,
            child: Row(
              children: [
                if (needsReview) ...[
                  Icon(
                    AppIcons.alert,
                    size: AppSizes.microIcon,
                    color: colors.destructive,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: _LaneItem.fill(lane, colors),
                      borderRadius: BorderRadius.circular(AppRadius.small),
                    ),
                    child: Text(
                      label,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.clip,
                      style: AppTypography.caption.semibold.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared shape of items on the small lanes: tinted lane color over the
/// surface, radius 8, selection frame.
class _LaneItem extends StatelessWidget {
  const new({
    required this.width,
    required this.laneColor,
    required this.onTap,
    required this.semanticLabel,
    required this.selected,
    required this.trim,
    required this.child,
  });

  final double width;
  final Color laneColor;
  final VoidCallback? onTap;
  final String semanticLabel;
  final bool selected;
  final TrimCallbacks? trim;
  final Widget child;

  static const double _tint = 0.24;

  /// Background of a lane item: the lane color tinted over the surface.
  static Color fill(Color lane, AppColors colors) =>
      Color.alphaBlend(lane.withValues(alpha: _tint), colors.surface);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: kTimelineMaxTextScale,
      child: SizedBox(
        width: width,
        height: AppSizes.laneHeight,
        child: Pressable(
          onPressed: onTap,
          semanticLabel: semanticLabel,
          selected: selected,
          minSize: Size.zero,
          child: TimelineItemFrame(
            selected: selected,
            trim: trim,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.control),
              child: ColoredBox(color: fill(laneColor, colors), child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  const new({
    required this.samples,
    required this.color,
    required this.fadeInPx,
    required this.fadeOutPx,
    required this.fadeColor,
    required this.overflowStartPx,
    required this.overflowColor,
    required this.markerColor,
  });

  final List<double>? samples;
  final Color color;
  final double fadeInPx;
  final double fadeOutPx;
  final Color fadeColor;
  final double? overflowStartPx;
  final Color overflowColor;
  final Color markerColor;

  static const double _bar = 2;
  static const double _gap = 1;

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.height / 2;
    final maxAmp = size.height / 2 - AppSpacing.xs;
    final paint = Paint()..color = color.withValues(alpha: 0.7);

    final data = samples;
    if (data == null || data.isEmpty) {
      canvas.drawRect(Rect.fromLTWH(0, mid - 0.5, size.width, 1), paint);
    } else {
      final bars = (size.width / (_bar + _gap)).floor();
      for (var i = 0; i < bars; i++) {
        final sample = data[(i * data.length / bars).floor()].clamp(0.0, 1.0);
        final h = math.max(1, sample * maxAmp);
        canvas.drawRect(
          Rect.fromLTWH(i * (_bar + _gap), mid - h, _bar, h * 2),
          paint,
        );
      }
    }

    final fade = Paint()..color = fadeColor;
    if (fadeInPx > 0) {
      canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..lineTo(fadeInPx, 0)
          ..lineTo(0, size.height)
          ..close(),
        fade,
      );
    }
    if (fadeOutPx > 0) {
      canvas.drawPath(
        Path()
          ..moveTo(size.width, 0)
          ..lineTo(size.width - fadeOutPx, 0)
          ..lineTo(size.width, size.height)
          ..close(),
        fade,
      );
    }

    if (overflowStartPx case final x? when x < size.width) {
      canvas
        ..drawRect(
          Rect.fromLTRB(x, 0, size.width, size.height),
          Paint()..color = overflowColor,
        )
        ..drawRect(
          Rect.fromLTWH(x, 0, AppSizes.borderWidth, size.height),
          Paint()..color = markerColor,
        );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.samples != samples ||
      old.color != color ||
      old.fadeInPx != fadeInPx ||
      old.fadeOutPx != fadeOutPx ||
      old.overflowStartPx != overflowStartPx ||
      old.fadeColor != fadeColor ||
      old.overflowColor != overflowColor ||
      old.markerColor != markerColor;
}
