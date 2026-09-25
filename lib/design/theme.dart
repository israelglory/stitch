import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stitch/design/tokens.dart';

/// App theme built only from tokens.
///
/// Components in design/ style themselves; this theme exists so that the
/// few Material widgets used underneath (TextField, Slider, Scaffold, route
/// transitions) match, and so Material 3 defaults that conflict with the
/// design direction are off: surface tint, ripples and splashes, dynamic
/// color, elevation shadows.
abstract final class AppTheme {
  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);

  static ThemeData light() => _build(AppColors.light, Brightness.light);

  static ThemeData _build(AppColors c, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.accent,
      onPrimary: c.onAccent,
      secondary: c.accent,
      onSecondary: c.onAccent,
      error: c.destructive,
      onError: c.onAccent,
      surface: c.surface,
      onSurface: c.textPrimary,
      onSurfaceVariant: c.textSecondary,
      surfaceContainerLowest: c.background,
      surfaceContainerLow: c.surface,
      surfaceContainer: c.surface,
      surfaceContainerHigh: c.surfaceRaised,
      surfaceContainerHighest: c.surfaceRaised,
      outline: c.border,
      outlineVariant: c.border,
      shadow: c.shadow,
      scrim: c.scrim,
      surfaceTint: Colors.transparent,
    );

    TextStyle colored(TextStyle s, Color color) => s.copyWith(color: color);
    final textTheme = TextTheme(
      displaySmall: colored(AppTypography.display, c.textPrimary),
      titleLarge: colored(AppTypography.title, c.textPrimary),
      titleMedium: colored(AppTypography.bodyLarge.semibold, c.textPrimary),
      titleSmall: colored(AppTypography.body.semibold, c.textPrimary),
      bodyLarge: colored(AppTypography.bodyLarge, c.textPrimary),
      bodyMedium: colored(AppTypography.body, c.textPrimary),
      bodySmall: colored(AppTypography.caption, c.textSecondary),
      labelLarge: colored(AppTypography.button, c.textPrimary),
      labelMedium: colored(AppTypography.caption.semibold, c.textPrimary),
      labelSmall: colored(AppTypography.caption, c.textSecondary),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: AppTypography.fontFamily,
      textTheme: textTheme,
      extensions: [c],
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      dividerColor: c.border,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      iconTheme: IconThemeData(
        color: c.textPrimary,
        size: AppSizes.toolbarIcon,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: AppSpacing.screen,
        titleTextStyle: colored(AppTypography.title, c.textPrimary),
      ),
      dividerTheme: DividerThemeData(
        color: c.border,
        thickness: AppSizes.borderWidth,
        space: AppSizes.borderWidth,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.accent,
        selectionColor: c.accent.withValues(alpha: 0.35),
        selectionHandleColor: c.accent,
      ),
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: c.accent,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(c.textTertiary),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: AppPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}

/// Screens fade in with a short rise: 250 ms, eased out, and none at all
/// when the system asks for reduced motion. (iOS keeps its own transition
/// and the back swipe that goes with it.)
class AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const new();

  @override
  Duration get transitionDuration => AppMotion.slow;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return child;
    final curved = CurvedAnimation(parent: animation, curve: AppMotion.curve);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.02),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
