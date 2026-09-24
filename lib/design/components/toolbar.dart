import 'package:flutter/widgets.dart';
import 'package:stitch/design/components/pressable.dart';
import 'package:stitch/design/icons.dart';
import 'package:stitch/design/tokens.dart';
import 'package:stitch/l10n/generated/app_localizations.dart';

/// Labels in fixed-height toolbars stop growing here so they are not
/// clipped; everything else in the app scales freely.
const double _maxToolbarTextScale = 1.3;

/// One tool: a 24pt icon with a short label underneath.
class ToolbarItem extends StatelessWidget {
  const new({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected = false,
    this.destructive = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  /// Accent color, for a tool whose panel is open or whose mode is on.
  final bool selected;

  /// Destructive color for the icon and label (Delete).
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = destructive
        ? colors.destructive
        : selected
        ? colors.accent
        : colors.textPrimary;
    return Pressable(
      onPressed: onPressed,
      semanticLabel: label,
      selected: selected ? true : null,
      minSize: const Size(AppSizes.toolbarHeight, AppSizes.toolbarHeight),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: AppSizes.toolbarIcon, color: color),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              maxLines: 1,
              style: AppTypography.caption.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

/// The bottom tool bar of the editor. Scrolls horizontally when the tools
/// do not fit. With [onBack], shows a leading back control that returns to
/// the parent tool set (for example, deselecting a clip).
class ContextToolbar extends StatelessWidget {
  const new({required this.items, this.onBack, super.key});

  final List<ToolbarItem> items;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: _maxToolbarTextScale,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(top: BorderSide(color: colors.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: AppSizes.toolbarHeight + AppSpacing.md,
            child: Row(
              children: [
                if (onBack != null) ...[
                  Pressable(
                    onPressed: onBack,
                    semanticLabel: l10n.back,
                    minSize: const Size(
                      AppSizes.minTouchTarget + AppSpacing.sm,
                      AppSizes.toolbarHeight,
                    ),
                    child: Center(
                      child: Icon(
                        AppIcons.back,
                        size: AppSizes.toolbarIcon,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: AppSizes.toolbarIcon,
                    child: _Rule(color: colors.border),
                  ),
                ],
                Expanded(
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppSpacing.xs),
                    itemBuilder: (context, i) => Center(child: items[i]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A 1px vertical rule.
class _Rule extends StatelessWidget {
  const new({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: AppSizes.borderWidth,
    child: ColoredBox(color: color),
  );
}
