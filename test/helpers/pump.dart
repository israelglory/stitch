import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/app/app.dart';
import 'package:stitch/app/router.dart';
import 'package:stitch/features/projects/application/import_controller.dart';
import 'package:stitch/features/projects/domain/project.dart';

import 'app_harness.dart';
import 'app_scope.dart';

/// Creates the test environment outside the fake-async zone.
Future<TestEnv> createEnv(WidgetTester tester, {bool onboarded = true}) async =>
    (await tester.runAsync(() => TestEnv.create(onboarded: onboarded)))!;

/// Pumps the whole app at [location].
Future<void> pumpApp(
  WidgetTester tester,
  TestEnv env, {
  String location = AppRoutes.projects,
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  setPhoneSize(tester, size: size);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  env.container.read(routerProvider).go(location);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: env.container,
      child: const StitchApp(),
    ),
  );
  await settle(tester);
}

/// Lets real IO (files, the fake library) and frames alternate until the
/// UI is stable. Never waits for endless animations.
Future<void> settle(WidgetTester tester, {int rounds = 12}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 15)),
    );
    await tester.pump(const Duration(milliseconds: 60));
  }
}

/// Decodes every image on screen so goldens show them.
Future<void> precacheImages(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate()) {
      final image = element.widget as Image;
      await precacheImage(image.image, element);
    }
  });
  await tester.pump();
}

/// A project with one video per entry in [seconds], created through the
/// real import path.
Future<String> createProject(
  WidgetTester tester,
  TestEnv env, {
  List<int> seconds = const [3, 4, 2],
  String name = 'Beach day',
}) async {
  final id = await tester.runAsync(() async {
    final items = [
      for (final (i, s) in seconds.indexed)
        env.library.addVideo('seed$i', seconds: s),
    ];
    return await env.container
        .read(importControllerProvider.notifier)
        .createProject(
          name: name,
          preset: AspectPreset.portrait9x16,
          items: items,
        );
  });
  return id!;
}

/// Settles until [finder] finds something, failing after [maxRounds].
Future<void> settleUntil(
  WidgetTester tester,
  Finder finder, {
  int maxRounds = 200,
}) async {
  for (var i = 0; i < maxRounds; i++) {
    if (finder.evaluate().isNotEmpty) return;
    await settle(tester, rounds: 1);
  }
  fail('Timed out waiting for $finder');
}
