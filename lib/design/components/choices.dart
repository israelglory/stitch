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
              decoration: BoxDecoration(
                shape: BoxShape.circle,
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
class ColorSwatchButton extends StatelessWidget {
  const new({
    required this.color,
    required this.semanticLabel,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final Color color;
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
              color: color,
              borderRadius: BorderRadius.circular(
                AppRadius.control - AppSizes.strokeWidth * 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
