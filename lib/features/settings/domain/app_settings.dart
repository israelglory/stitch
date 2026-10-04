import 'package:meta/meta.dart';
import 'package:stitch/features/export/domain/export_options.dart';
import 'package:stitch/features/projects/domain/project.dart';

enum ThemeChoice { system, dark, light }

/// The user's preferences.
@immutable
final class AppSettings {
  const new({
    this.theme = ThemeChoice.dark,
    this.export = const ExportOptions(),
    this.aspect = AspectPreset.portrait9x16,
    this.onlineSounds = true,
  });

  final ThemeChoice theme;

  /// Where the export sheet starts. HEVC and the captions file are chosen
  /// per export, so they are never stored on.
  final ExportOptions export;

  /// The format a new project starts on.
  final AspectPreset aspect;

  /// Whether the audio library offers sounds to download (the catalog is
  /// fetched from the Internet Archive). Off, the app makes no requests
  /// for it.
  final bool onlineSounds;

  AppSettings copyWith({
    ThemeChoice? theme,
    ExportOptions? export,
    AspectPreset? aspect,
    bool? onlineSounds,
  }) => AppSettings(
    theme: theme ?? this.theme,
    export: export ?? this.export,
    aspect: aspect ?? this.aspect,
    onlineSounds: onlineSounds ?? this.onlineSounds,
  );

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.theme == theme &&
      other.export == export &&
      other.aspect == aspect &&
      other.onlineSounds == onlineSounds;

  @override
  int get hashCode => Object.hash(theme, export, aspect, onlineSounds);
}
