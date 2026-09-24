import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitch/app/providers.dart';

part 'onboarding_repository.g.dart';

/// Persists whether onboarding has been shown.
class OnboardingRepository {
  const new(this._prefs);

  static const completedKey = 'onboarding.completed';

  final SharedPreferencesWithCache _prefs;

  bool get isCompleted => _prefs.getBool(completedKey) ?? false;

  Future<void> markCompleted() => _prefs.setBool(completedKey, true);
}

@Riverpod(keepAlive: true)
OnboardingRepository onboardingRepository(Ref ref) =>
    OnboardingRepository(ref.watch(sharedPreferencesProvider));
