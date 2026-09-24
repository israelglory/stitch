import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stitch/features/onboarding/data/onboarding_repository.dart';

part 'onboarding_controller.g.dart';

/// Whether the user has finished or skipped onboarding. Drives the router
/// redirect, so onboarding is shown exactly once.
@Riverpod(keepAlive: true)
class OnboardingController extends _$OnboardingController {
  @override
  bool build() => ref.watch(onboardingRepositoryProvider).isCompleted;

  Future<void> complete() async {
    await ref.read(onboardingRepositoryProvider).markCompleted();
    state = true;
  }
}
