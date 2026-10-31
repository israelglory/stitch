import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/app/app.dart';
import 'package:stitch/app/router.dart';
import 'package:stitch/features/ads/ads.dart';
import 'package:stitch/features/analytics/analytics.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';
import 'package:stitch/features/editor/application/playback_controller.dart';
import 'package:stitch/features/projects/application/import_controller.dart';
import 'package:stitch/features/projects/domain/project.dart';
import 'package:stitch/features/updates/data/app_updates.dart';

import 'app_harness.dart';
import 'app_scope.dart';

/// Creates the test environment outside the fake-async zone.
Future<TestEnv> createEnv(
  WidgetTester tester, {
  bool onboarded = true,
  Ads ads = const NoAds(),
  Analytics analytics = const NoAnalytics(),
  AppUpdates updates = const NoAppUpdates(),
}) async => (await tester.runAsync(
  () => TestEnv.create(
    onboarded: onboarded,
    ads: ads,
    analytics: analytics,
    updates: updates,
  ),
))!;

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

/// Moves the playhead to [us], scrolling the timeline so that moment is
/// under it (the middle of the screen, clear of the pinned add button).
Future<void> scrollTimelineTo(WidgetTester tester, int us) async {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(StitchApp)),
  );
  await container.read(playbackControllerProvider.notifier).seek(us);
  await settle(tester);
}

/// Scrolls the timeline to the end of the first clip.
Future<void> scrollTimelineToFirstCut(WidgetTester tester, String id) async {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(StitchApp)),
  );
  final state = container.read(editorControllerProvider(id)).requireValue;
  await scrollTimelineTo(tester, state.layout.spans.first.endUs);
}
