import 'dart:io';
import 'dart:ui' show PlatformDispatcher;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitch/app/providers.dart';
import 'package:stitch/core/time/clock.dart';
import 'package:stitch/features/updates/data/app_updates.dart';
import 'package:stitch/features/updates/domain/store_update.dart';

part 'update_providers.g.dart';

@Riverpod(keepAlive: true)
AppUpdates appUpdates(Ref ref) => StoreAppUpdates(
  system: ref.watch(systemServicesProvider),
  isIOS: Platform.isIOS,
  country: PlatformDispatcher.instance.locale.countryCode,
);

/// Remembers the user's answer to the update prompt, so it stays away for
/// a while. A newer release asks again at once.
class UpdateSnoozes {
  const new(this._prefs, this._clock);

  static const releaseKey = 'updates.snoozedRelease';
  static const untilKey = 'updates.snoozedUntil';

  final SharedPreferencesWithCache _prefs;
  final Clock _clock;

  bool isSnoozed(StoreUpdate update) =>
      _prefs.getString(releaseKey) == update.id &&
      _clock().millisecondsSinceEpoch < (_prefs.getInt(untilKey) ?? 0);

  Future<void> snooze(StoreUpdate update, Duration duration) async {
    await _prefs.setString(releaseKey, update.id);
    await _prefs.setInt(
      untilKey,
      _clock().add(duration).millisecondsSinceEpoch,
    );
  }
}

@Riverpod(keepAlive: true)
UpdateSnoozes updateSnoozes(Ref ref) => UpdateSnoozes(
  ref.watch(sharedPreferencesProvider),
  ref.watch(clockProvider),
);

/// A newer release to offer the user, looked for once per launch. Null
/// when there is none, or the user put it off recently.
@Riverpod(keepAlive: true)
class PendingUpdate extends _$PendingUpdate {
  /// "Later" puts the prompt off this long.
  static const laterFor = Duration(days: 3);

  /// After "Update" opens the store, ask again after this long if the app
  /// is still not updated.
  static const updatingFor = Duration(days: 1);

  @override
  Future<StoreUpdate?> build() async {
    // After the ad consent form and the tracking question at launch, so
    // the prompt never stacks on them. Never fails: no ads, still checks.
    await ref.read(adsProvider).start().catchError((Object _) {});
    final update = await ref.read(appUpdatesProvider).check();
    if (update == null || ref.read(updateSnoozesProvider).isSnoozed(update)) {
      return null;
    }
    return update;
  }

  /// The user's answer: [update] opens the store page. Either way the
  /// prompt is put off.
  Future<void> answer({required bool update}) async {
    final pending = state.value;
    if (pending == null) return;
    state = const AsyncData(null);
    await ref
        .read(updateSnoozesProvider)
        .snooze(pending, update ? updatingFor : laterFor);
    if (update) {
      await ref.read(systemServicesProvider).openUrl(pending.storeUrl);
    }
  }
}
