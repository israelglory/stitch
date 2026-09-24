import 'package:flutter/widgets.dart';
import 'package:stitch/design/components/pressable.dart';
import 'package:stitch/design/components/progress.dart';
import 'package:stitch/design/tokens.dart';

enum ButtonSize {
  /// 48pt tall. Default for screens and sheets.
  regular,

  /// 32pt tall with a 44pt touch area. For dense bars such as the editor's
  /// top bar.
  small,
}

enum _ButtonVariant { primary, secondary, text, destructive }

/// Solid accent button. Use at most one per screen.
class PrimaryButton extends StatelessWidget {
  const new({
    required this.label,
    required this.onPressed,
    this.icon,
    this.size = ButtonSize.regular,
    this.expand = false,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ButtonSize size;
  final bool expand;
  final bool isLoading;

  @override
  Widget build(BuildContext context) => _AppButton(
    variant: _ButtonVariant.primary,
    label: label,
    onPressed: onPressed,
    icon: icon,
    size: size,
    expand: expand,
    isLoading: isLoading,
  );
}

/// Neutral filled button for secondary actions.
class SecondaryButton extends StatelessWidget {
  const new({
    required this.label,
    required this.onPressed,
    this.icon,
    this.size = ButtonSize.regular,
    this.expand = false,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ButtonSize size;
  final bool expand;
  final bool isLoading;

  @override
  Widget build(BuildContext context) => _AppButton(
    variant: _ButtonVariant.secondary,
    label: label,
    onPressed: onPressed,
    icon: icon,
    size: size,
    expand: expand,
    isLoading: isLoading,
  );
}

/// Unfilled button in the accent color, for low-emphasis actions.
class AppTextButton extends StatelessWidget {
  const new({
    required this.label,
    required this.onPressed,
    this.icon,
    this.size = ButtonSize.regular,
    this.neutral = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ButtonSize size;

  /// Uses the primary text color instead of the accent, for actions that
  /// sit next to content (for example "Skip").
  final bool neutral;

  @override
  Widget build(BuildContext context) => _AppButton(
    variant: _ButtonVariant.text,
    label: label,
    onPressed: onPressed,
    icon: icon,
    size: size,
    neutral: neutral,
  );
}

/// Solid destructive button. Only for confirming irreversible actions.
class DestructiveButton extends StatelessWidget {
  const new({
    required this.label,
    required this.onPressed,
    this.icon,
    this.size = ButtonSize.regular,
    this.expand = false,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ButtonSize size;
  final bool expand;
  final bool isLoading;

  @override
  Widget build(BuildContext context) => _AppButton(
    variant: _ButtonVariant.destructive,
    label: label,
    onPressed: onPressed,
    icon: icon,
    size: size,
    expand: expand,
    isLoading: isLoading,
  );
}

class _AppButton extends StatelessWidget {
  const new({
    required this.variant,
    required this.label,
    required this.onPressed,
    required this.icon,
    required this.size,
    this.expand = false,
    this.isLoading = false,
    this.neutral = false,
  });

  final _ButtonVariant variant;
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ButtonSize size;
  final bool expand;
  final bool isLoading;
  final bool neutral;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (Color? fill, Color foreground) = switch (variant) {
      _ButtonVariant.primary => (colors.accent, colors.onAccent),
      _ButtonVariant.secondary => (colors.surfaceRaised, colors.textPrimary),
      _ButtonVariant.text => (
        null,
        neutral ? colors.textPrimary : colors.accent,
      ),
      _ButtonVariant.destructive => (colors.destructive, colors.onAccent),
    };
    final small = size == ButtonSize.small;
    final height = small ? AppSizes.buttonHeightSmall : AppSizes.buttonHeight;
    final horizontalPadding = switch ((variant, small)) {
      (_ButtonVariant.text, _) => AppSpacing.sm,
      (_, true) => AppSpacing.md,
      (_, false) => AppSpacing.xl,
    };
    final baseStyle = small
        ? AppTypography.body.semibold
        : AppTypography.button;
    final textStyle = baseStyle.copyWith(color: foreground);

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          ProgressRing(
            size: AppSizes.inlineIcon,
            color: foreground,
            semanticLabel: label,
          )
        else ...[
          if (icon != null) ...[
            Icon(icon, size: scaledIconSize(context), color: foreground),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Text(
              label,
              style: textStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );

    final visual = Container(
      constraints: BoxConstraints(minHeight: height),
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: small ? AppSpacing.xs : AppSpacing.sm,
      ),
      decoration: fill == null
          ? null
          : BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
      child: content,
    );

    return Pressable(
      onPressed: onPressed,
      busy: isLoading,
      semanticLabel: label,
      minSize: Size(
        expand ? double.infinity : AppSizes.minTouchTarget,
        AppSizes.minTouchTarget,
      ),
      child: Center(
        widthFactor: expand ? null : 1,
        heightFactor: 1,
        child: visual,
      ),
    );
  }
}

enum IconButtonStyle {
  /// Icon only.
  plain,

  /// Circular surfaceRaised background, for buttons over content.
  filled,
}

/// Circular icon button with a required accessibility label.
class AppIconButton extends StatelessWidget {
  const new({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.style = IconButtonStyle.plain,
    this.selected,
    this.iconSize = AppSizes.toolbarIcon,
    this.color,
    super.key,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final IconButtonStyle style;

  /// Non-null makes this a toggle; true draws the icon in the accent color.
  final bool? selected;
  final double iconSize;

  /// Overrides the icon color. Use sparingly (for example destructive).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground =
        color ?? ((selected ?? false) ? colors.accent : colors.textPrimary);
    return Pressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      selected: selected,
      child: SizedBox.square(
        dimension: AppSizes.minTouchTarget,
        child: Center(
          child: Container(
            width: iconSize + AppSpacing.md,
            height: iconSize + AppSpacing.md,
            decoration: style == IconButtonStyle.filled
                ? BoxDecoration(
                    color: colors.surfaceRaised,
                    shape: BoxShape.circle,
                  )
                : null,
            alignment: Alignment.center,
            child: Icon(icon, size: iconSize, color: foreground),
          ),
        ),
      ),
    );
  }
}

/// Inline icons next to text grow with large text, up to 1.5x, so they
/// stay in proportion with their labels.
double scaledIconSize(
  BuildContext context, [
  double base = AppSizes.inlineIcon,
]) => MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.5).scale(base);
