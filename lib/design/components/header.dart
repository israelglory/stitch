import 'package:flutter/widgets.dart';
import 'package:stitch/design/tokens.dart';

/// The bar at the top of every screen: optional leading control, a title,
/// and trailing controls. Top-level screens use a start-aligned title in
/// the title style; flows and the editor center it.
class AppHeader extends StatelessWidget {
  const new({
    this.title,
    this.titleWidget,
    this.leading,
    this.trailing = const [],
    this.centerTitle = false,
    super.key,
  }) : assert(title == null || titleWidget == null, 'Pass one title');

  final String? title;

  /// Replaces [title], for a tappable title.
  final Widget? titleWidget;
  final Widget? leading;
  final List<Widget> trailing;
  final bool centerTitle;

  static const double height = 56;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final titleStyle = centerTitle
        ? AppTypography.bodyLarge.semibold
        : AppTypography.title;
    final titleContent =
        titleWidget ??
        (title == null
            ? const SizedBox.shrink()
            : Semantics(
                header: true,
                child: Text(
                  title!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: centerTitle ? TextAlign.center : TextAlign.start,
                  style: titleStyle.copyWith(color: colors.textPrimary),
                ),
              ));

    return SafeArea(
      bottom: false,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: height),
        child: Padding(
          padding: EdgeInsetsDirectional.only(
            start: leading == null ? AppSpacing.screen : AppSpacing.xs,
            end: trailing.isEmpty ? AppSpacing.screen : AppSpacing.xs,
          ),
          child: Row(
            children: [
              ?leading,
              // Centered titles center between the side controls, so they
              // never run under them.
              Expanded(child: titleContent),
              ...trailing,
            ],
          ),
        ),
      ),
    );
  }
}
