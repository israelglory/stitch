import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/app/not_found_screen.dart';
import 'package:stitch/app/router.dart';
import 'package:stitch/features/editor/presentation/editor_screen.dart';
import 'package:stitch/features/onboarding/application/onboarding_controller.dart';
import 'package:stitch/features/onboarding/data/onboarding_repository.dart';
import 'package:stitch/features/onboarding/presentation/onboarding_screen.dart';
import 'package:stitch/features/projects/presentation/projects_screen.dart';
import 'package:stitch/features/settings/presentation/settings_screen.dart';

import '../helpers/pump.dart';

void main() {
  testWidgets('first launch shows onboarding', (tester) async {
    final env = await createEnv(tester, onboarded: false);
    await pumpApp(tester, env);
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('onboarding cannot be skipped by deep link', (tester) async {
    final env = await createEnv(tester, onboarded: false);
    await pumpApp(tester, env, location: AppRoutes.settings);
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('completing onboarding lands on projects and persists', (
    tester,
  ) async {
    final env = await createEnv(tester, onboarded: false);
    await pumpApp(tester, env);
    await tester.runAsync(
      () =>
          env.container.read(onboardingControllerProvider.notifier).complete(),
    );
    await settle(tester);
    expect(find.byType(ProjectsScreen), findsOneWidget);
    expect(
      env.container.read(onboardingRepositoryProvider).isCompleted,
      isTrue,
    );
  });

  testWidgets('returning user starts on projects, not onboarding', (
    tester,
  ) async {
    final env = await createEnv(tester);
    await pumpApp(tester, env, location: AppRoutes.onboarding);
    expect(find.byType(ProjectsScreen), findsOneWidget);
    expect(find.text('No projects yet'), findsOneWidget);
  });

  testWidgets('settings opens from projects and goes back', (tester) async {
    final env = await createEnv(tester);
    await pumpApp(tester, env);
    await tester.tap(find.bySemanticsLabel('Settings'));
    await settle(tester);
    expect(find.byType(SettingsScreen), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Back'));
    await settle(tester);
    expect(find.byType(ProjectsScreen), findsOneWidget);
  });

  testWidgets('editor route receives the project id', (tester) async {
    final env = await createEnv(tester);
    final id = await createProject(tester, env);
    await pumpApp(tester, env, location: AppRoutes.editor(id));
    final editor = tester.widget<EditorScreen>(find.byType(EditorScreen));
    expect(editor.projectId, id);
    await tester.pump(const Duration(seconds: 1));
    await settle(tester);
  });

  testWidgets('unknown route shows not found and goes home', (tester) async {
    final env = await createEnv(tester);
    await pumpApp(tester, env, location: '/nope');
    expect(find.byType(NotFoundScreen), findsOneWidget);
    await tester.tap(find.text('Back to projects'));
    await settle(tester);
    expect(find.byType(ProjectsScreen), findsOneWidget);
  });

  test('editor paths encode the id', () {
    expect(AppRoutes.editor('x/y'), '/editor/x%2Fy');
    expect(AppRoutes.editorAdd('p'), '/editor/p/add');
  });
}
