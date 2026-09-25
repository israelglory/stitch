import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stitch/app/providers.dart';
import 'package:stitch/features/settings/data/settings_repository.dart';
import 'package:stitch/features/settings/domain/app_settings.dart';

part 'settings_controller.g.dart';

@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(Ref ref) =>
    SettingsRepository(ref.watch(sharedPreferencesProvider));

/// The user's settings. Changes apply at once and are saved.
@Riverpod(keepAlive: true)
class SettingsController extends _$SettingsController {
  @override
  AppSettings build() => ref.watch(settingsRepositoryProvider).read();

  void update(AppSettings Function(AppSettings current) change) {
    final next = change(state);
    if (next == state) return;
    state = next;
    unawaited(ref.read(settingsRepositoryProvider).write(next));
  }
}
