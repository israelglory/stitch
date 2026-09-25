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
  });

  final ThemeChoice theme;

  /// Where the export sheet starts. HEVC and the captions file are chosen
  /// per export, so they are never stored on.
  final ExportOptions export;

  /// The format a new project starts on.
  final AspectPreset aspect;

  AppSettings copyWith({
    ThemeChoice? theme,
    ExportOptions? export,
    AspectPreset? aspect,
  }) => AppSettings(
    theme: theme ?? this.theme,
    export: export ?? this.export,
    aspect: aspect ?? this.aspect,
  );

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.theme == theme &&
      other.export == export &&
      other.aspect == aspect;

  @override
  int get hashCode => Object.hash(theme, export, aspect);
}
