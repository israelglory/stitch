import 'package:flutter/widgets.dart';
import 'package:stitch/design/components/pressable.dart';
import 'package:stitch/design/tokens.dart';

/// Page indicator for short paged flows (onboarding).
class PageDots extends StatelessWidget {
  const new({required this.count, required this.index, super.key});

  final int count;
  final int index;

  static const double _dot = 6;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: AppMotion.of(context, AppMotion.standard),
              curve: AppMotion.curve,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              width: _dot,
              height: _dot,
              // Softened squares: only icon buttons and the record button
              // are fully round.
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.hairline),
                color: i == index ? colors.accent : colors.border,
              ),
            ),
        ],
      ),
    );
  }
}

/// A choice in a grid of options: a visual with a short label under it.
/// Selected tiles get the accent outline and label.
class ChoiceTile extends StatelessWidget {
  const new({
    required this.label,
    required this.visual,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final Widget visual;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Pressable(
      onPressed: onTap,
      semanticLabel: label,
      selected: selected,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: AppMotion.of(context, AppMotion.fast),
            curve: AppMotion.curve,
            decoration: BoxDecoration(
              color: colors.surfaceRaised,
              borderRadius: BorderRadius.circular(AppRadius.control),
              border: Border.all(
                color: selected ? colors.accent : colors.surfaceRaised,
                width: AppSizes.strokeWidth,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                AppRadius.control - AppSizes.strokeWidth,
              ),
              child: visual,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: selected ? colors.accent : colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Visual for an aspect ratio choice: an outlined frame of that shape.
/// A null [ratio] (original size) shows a square with a small inner mark.
class AspectRatioGlyph extends StatelessWidget {
  const new({required this.ratio, this.size = 40, super.key});

  /// Width over height, or null for "original".
  final double? ratio;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final r = ratio ?? 1;
    final w = r >= 1 ? size : size * r;
    final h = r >= 1 ? size / r : size;
    return SizedBox.square(
      dimension: size + AppSpacing.lg * 2,
      child: Center(
        child: Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            border: Border.all(
              color: colors.textSecondary,
              width: AppSizes.strokeWidth,
            ),
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
          child: ratio == null
              ? Center(
                  child: Container(
                    width: w / 3,
                    height: h / 3,
                    decoration: BoxDecoration(
                      color: colors.textSecondary,
                      borderRadius: BorderRadius.circular(AppRadius.small / 2),
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

/// A color option: a rounded square of [color], outlined when selected.
/// A null [color] is the "none" option, crossed out.
class ColorSwatchButton extends StatelessWidget {
  const new({
    required this.color,
    required this.semanticLabel,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final Color? color;
  final String semanticLabel;
  final bool selected;
  final VoidCallback? onTap;

  static const double _size = 36;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Pressable(
      onPressed: onTap,
      semanticLabel: semanticLabel,
      selected: selected,
      child: Center(
        child: AnimatedContainer(
          duration: AppMotion.of(context, AppMotion.fast),
          padding: const EdgeInsets.all(AppSizes.strokeWidth),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.control),
            border: Border.all(
              color: selected ? colors.accent : colors.border,
              width: AppSizes.strokeWidth,
            ),
          ),
          child: Container(
            width: _size,
            height: _size,
            decoration: BoxDecoration(
              color: color ?? colors.surfaceRaised,
              borderRadius: BorderRadius.circular(
                AppRadius.control - AppSizes.strokeWidth * 2,
              ),
            ),
            child: color == null
                ? CustomPaint(painter: _NonePainter(colors.textSecondary))
                : null,
          ),
        ),
      ),
    );
  }
}

class _NonePainter extends CustomPainter {
  const new(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = size.width * 0.25;
    canvas.drawLine(
      Offset(inset, size.height - inset),
      Offset(size.width - inset, inset),
      Paint()
        ..color = color
        ..strokeWidth = AppSizes.strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_NonePainter old) => old.color != color;
}

/// A compact choice among several short labels, in a wrapping row.
class OptionChip extends StatelessWidget {
  const new({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Pressable(
      onPressed: onTap,
      semanticLabel: label,
      selected: selected,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
        child: Center(
          widthFactor: 1,
          child: AnimatedContainer(
            duration: AppMotion.of(context, AppMotion.fast),
            curve: AppMotion.curve,
            height: AppSizes.buttonHeightSmall,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.surfaceRaised,
              borderRadius: BorderRadius.circular(AppRadius.control),
              border: Border.all(
                color: selected ? colors.accent : colors.surfaceRaised,
                width: AppSizes.strokeWidth,
              ),
            ),
            child: Text(
              label,
              style: AppTypography.body.copyWith(
                color: selected ? colors.accent : colors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
