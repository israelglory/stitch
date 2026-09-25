import 'package:flutter/material.dart';

/// Design tokens. The only place raw colors, sizes, and durations may be
/// written. A test fails the build if feature code hardcodes values.
///
/// Colors are a theme extension with a dark and a light palette under the
/// same names; read them with `context.colors`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const new({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.accent,
    required this.onAccent,
    required this.destructive,
    required this.success,
    required this.scrim,
    required this.overlay,
    required this.onOverlay,
    required this.shadow,
    required this.laneText,
    required this.laneCaptions,
    required this.laneAudio,
    required this.laneVoiceover,
  });

  static const dark = AppColors(
    background: Color(0xFF0B0B0C),
    surface: Color(0xFF151517),
    surfaceRaised: Color(0xFF1E1E21),
    border: Color(0xFF2A2A2E),
    textPrimary: Color(0xFFF2F2F3),
    textSecondary: Color(0xFFA1A1A8),
    textTertiary: Color(0xFF6B6B73),
    accent: Color(0xFF4C8DFF),
    onAccent: Color(0xFFFFFFFF),
    destructive: Color(0xFFE5484D),
    success: Color(0xFF3DB47A),
    scrim: Color(0x99000000),
    overlay: Color(0x8C000000),
    onOverlay: Color(0xFFFFFFFF),
    shadow: Color(0x66000000),
    laneText: Color(0xFFD9A441),
    laneCaptions: Color(0xFF4FB3B0),
    laneAudio: Color(0xFF6CC08B),
    laneVoiceover: Color(0xFFC98A5B),
  );

  /// The same roles on light surfaces. The accent is a shade deeper, so
  /// white labels on it stay readable.
  static const light = AppColors(
    background: Color(0xFFF6F6F7),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFEDEDF0),
    border: Color(0xFFDDDDE2),
    textPrimary: Color(0xFF111114),
    textSecondary: Color(0xFF5B5B64),
    textTertiary: Color(0xFF8C8C95),
    accent: Color(0xFF2F6FE8),
    onAccent: Color(0xFFFFFFFF),
    destructive: Color(0xFFD5353B),
    success: Color(0xFF218456),
    scrim: Color(0x66000000),
    overlay: Color(0x8C000000),
    onOverlay: Color(0xFFFFFFFF),
    shadow: Color(0x24000000),
    laneText: Color(0xFFD9A441),
    laneCaptions: Color(0xFF4FB3B0),
    laneAudio: Color(0xFF6CC08B),
    laneVoiceover: Color(0xFFC98A5B),
  );

  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  /// The only accent: primary buttons, selection outlines, playhead, active
  /// states.
  final Color accent;
  final Color onAccent;
  final Color destructive;
  final Color success;

  /// Barrier behind sheets and dialogs.
  final Color scrim;

  /// Backing for small labels drawn on top of media (durations, badges), so
  /// they stay legible on any frame.
  final Color overlay;

  /// Text and marks on [overlay]: light in both themes, since it sits on
  /// media.
  final Color onOverlay;

  /// The single shadow, used by bottom sheets only.
  final Color shadow;

  // Timeline lanes only.
  final Color laneText;
  final Color laneCaptions;
  final Color laneAudio;
  final Color laneVoiceover;

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceRaised,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? accent,
    Color? onAccent,
    Color? destructive,
    Color? success,
    Color? scrim,
    Color? overlay,
    Color? onOverlay,
    Color? shadow,
    Color? laneText,
    Color? laneCaptions,
    Color? laneAudio,
    Color? laneVoiceover,
  }) => AppColors(
    background: background ?? this.background,
    surface: surface ?? this.surface,
    surfaceRaised: surfaceRaised ?? this.surfaceRaised,
    border: border ?? this.border,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    textTertiary: textTertiary ?? this.textTertiary,
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
    destructive: destructive ?? this.destructive,
    success: success ?? this.success,
    scrim: scrim ?? this.scrim,
    overlay: overlay ?? this.overlay,
    onOverlay: onOverlay ?? this.onOverlay,
    shadow: shadow ?? this.shadow,
    laneText: laneText ?? this.laneText,
    laneCaptions: laneCaptions ?? this.laneCaptions,
    laneAudio: laneAudio ?? this.laneAudio,
    laneVoiceover: laneVoiceover ?? this.laneVoiceover,
  );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      destructive: Color.lerp(destructive, other.destructive, t)!,
      success: Color.lerp(success, other.success, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      overlay: Color.lerp(overlay, other.overlay, t)!,
      onOverlay: Color.lerp(onOverlay, other.onOverlay, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      laneText: Color.lerp(laneText, other.laneText, t)!,
      laneCaptions: Color.lerp(laneCaptions, other.laneCaptions, t)!,
      laneAudio: Color.lerp(laneAudio, other.laneAudio, t)!,
      laneVoiceover: Color.lerp(laneVoiceover, other.laneVoiceover, t)!,
    );
  }
}

/// Solid colors offered for the empty areas of the video canvas. Content
/// colors, not UI colors: they appear in the user's video.
abstract final class CanvasPalette {
  static const colors = <Color>[
    Color(0xFF000000),
    Color(0xFF2B2B2E),
    Color(0xFF6B6B70),
    Color(0xFFC8C8CC),
    Color(0xFFFFFFFF),
  ];

  /// The color stored in a project as ARGB.
  static Color fromArgb(int argb) => Color(argb);
}

/// 4pt grid. These six values are the only allowed spacings.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Horizontal padding for every screen.
  static const double screen = lg;
}

abstract final class AppRadius {
  /// Tiny elements only: labels on media, text skeletons.
  static const double small = 4;

  /// Buttons, inputs, thumbnails, timeline items.
  static const double control = 8;

  /// Cards.
  static const double card = 12;

  /// Top corners of bottom sheets.
  static const double sheet = 16;
}

abstract final class AppSizes {
  static const double minTouchTarget = 44;
  static const double toolbarIcon = 24;
  static const double inlineIcon = 20;

  /// Only inside the 24pt transition button on the timeline.
  static const double microIcon = 16;
  static const double borderWidth = 1;

  /// Selection outlines and the playhead.
  static const double strokeWidth = 2;

  static const double buttonHeight = 48;
  static const double buttonHeightSmall = 32;
  static const double listRowHeight = 48;
  static const double toolbarHeight = 64;
  static const double sheetHandleWidth = 36;
  static const double sheetHandleHeight = 4;
  static const double sliderThumb = 20;
  static const double sliderTrack = 4;
  static const double progressTrack = 4;
  static const double orderBadge = 24;

  /// The voiceover record button, the one round control besides icon
  /// buttons.
  static const double recordButton = 72;

  /// Height of the live recording level meter.
  static const double levelMeter = 48;

  /// Width of a caption's time in the caption editor.
  static const double captionTime = 56;

  /// Width of a loading value at the end of a list row.
  static const double skeletonValue = 48;

  /// The export progress ring.
  static const double exportRing = 96;

  /// Play mark over the exported video.
  static const double exportPlayIcon = 48;

  // Timeline.
  static const double rulerHeight = 24;
  static const double videoTrackHeight = 56;
  static const double laneHeight = 32;
  static const double laneHeaderWidth = 56;
  static const double trimHandleWidth = 12;
  static const double transitionButton = 24;
}

abstract final class AppFontSizes {
  static const double caption = 12;
  static const double body = 14;
  static const double bodyLarge = 16;
  static const double title = 20;
  static const double display = 28;
}

/// Text styles without color; components apply colors from [AppColors].
abstract final class AppTypography {
  static const fontFamily = 'Inter';
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight semibold = FontWeight.w600;

  static const caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppFontSizes.caption,
    fontWeight: regular,
    height: 16 / 12,
  );
  static const body = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppFontSizes.body,
    fontWeight: regular,
    height: 20 / 14,
  );
  static const bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppFontSizes.bodyLarge,
    fontWeight: regular,
    height: 24 / 16,
  );
  static const button = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppFontSizes.bodyLarge,
    fontWeight: semibold,
    height: 24 / 16,
  );
  static const title = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppFontSizes.title,
    fontWeight: semibold,
    height: 28 / 20,
    letterSpacing: -0.2,
  );
  static const display = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppFontSizes.display,
    fontWeight: semibold,
    height: 36 / 28,
    letterSpacing: -0.4,
  );
}

extension TabularFigures on TextStyle {
  /// Fixed-width digits, for timecodes and values that change while visible.
  TextStyle get tabular =>
      copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  TextStyle get semibold => copyWith(fontWeight: AppTypography.semibold);
}

abstract final class AppMotion {
  static const fast = Duration(milliseconds: 150);
  static const standard = Duration(milliseconds: 200);
  static const slow = Duration(milliseconds: 250);
  static const Curve curve = Curves.easeOut;

  /// [duration], or zero when the system asks for reduced motion.
  static Duration of(BuildContext context, Duration duration) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false
      ? Duration.zero
      : duration;
}

/// Opacity of disabled controls.
const double kDisabledOpacity = 0.4;

/// Opacity of a control while pressed.
const double kPressedOpacity = 0.6;

extension AppThemeContext on BuildContext {
  AppColors get colors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.dark;
}
