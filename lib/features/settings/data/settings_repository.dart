import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitch/features/export/domain/export_options.dart';
import 'package:stitch/features/projects/domain/project.dart';
import 'package:stitch/features/settings/domain/app_settings.dart';

/// Stores [AppSettings] in the app's preferences. Unknown or missing
/// values read as the defaults.
class SettingsRepository {
  const new(this._prefs);

  static const _theme = 'settings.theme';
  static const _resolution = 'settings.export.resolution';
  static const _frameRate = 'settings.export.frameRate';
  static const _quality = 'settings.export.quality';
  static const _aspect = 'settings.aspect';

  final SharedPreferencesWithCache _prefs;

  AppSettings read() {
    const defaults = AppSettings();
    T pick<T extends Enum>(List<T> values, String key, T fallback) {
      final name = _prefs.getString(key);
      return values.where((v) => v.name == name).firstOrNull ?? fallback;
    }

    final frameRate = _prefs.getInt(_frameRate);
    return AppSettings(
      theme: pick(ThemeChoice.values, _theme, defaults.theme),
      export: ExportOptions(
        resolution: pick(
          ExportResolution.values,
          _resolution,
          defaults.export.resolution,
        ),
        frameRate: exportFrameRates.contains(frameRate)
            ? frameRate!
            : defaults.export.frameRate,
        quality: pick(ExportQuality.values, _quality, defaults.export.quality),
      ),
      aspect: pick(AspectPreset.values, _aspect, defaults.aspect),
    );
  }

  Future<void> write(AppSettings settings) async {
    await _prefs.setString(_theme, settings.theme.name);
    await _prefs.setString(_resolution, settings.export.resolution.name);
    await _prefs.setInt(_frameRate, settings.export.frameRate);
    await _prefs.setString(_quality, settings.export.quality.name);
    await _prefs.setString(_aspect, settings.aspect.name);
  }
}
