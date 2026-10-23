// What analytics records: screens as route patterns (never a project's
// id), and an event for each feature used, with counts and settings only.
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/app/router.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/features/analytics/analytics.dart';
import 'package:stitch/features/captions/domain/transcript.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';

import '../helpers/fake_captions.dart';
import '../helpers/fake_media_library.dart';
import '../helpers/pump.dart';

final class RecordingAnalytics implements Analytics {
  final screens = <String>[];
  final events = <(String, Map<String, Object>)>[];
  int consentGranted = 0;

  Map<String, Object>? last(String event) =>
      events.lastWhere((e) => e.$1 == event, orElse: () => ('', {})).$2;

  bool logged(String event) => events.any((e) => e.$1 == event);

  @override
  void screen(String screen) => screens.add(screen);

  @override
  void log(String event, [Map<String, Object> parameters = const {}]) =>
      events.add((event, parameters));

  @override
  Future<void> consentNotRequired() async => consentGranted++;
}

void main() {
  testWidgets('screens are route patterns, without ids', (tester) async {
    final analytics = RecordingAnalytics();
    final env = await createEnv(tester, analytics: analytics);
    final id = await createProject(tester, env);
    await pumpApp(tester, env);
    expect(analytics.screens.last, '/');
    env.container.read(routerProvider).go(AppRoutes.editor(id));
    await settleUntil(tester, find.byType(VideoClipTile));
    expect(analytics.screens.last, isNot(contains(id)));
    expect(analytics.screens.last, contains(':'));
    await tester.pump(autosaveDelay * 2);
    await settle(tester);
  });

  testWidgets('the first screen of a new install is onboarding', (
    tester,
  ) async {
    final analytics = RecordingAnalytics();
    final env = await createEnv(
      tester,
      onboarded: false,
      analytics: analytics,
    );
    await pumpApp(tester, env);
    expect(analytics.screens, contains('/onboarding'));
    expect(analytics.screens.last, '/onboarding');
  });

  testWidgets('a new project, text, an overlay, and a freeze', (tester) async {
    final analytics = RecordingAnalytics();
    final env = await createEnv(tester, analytics: analytics);
    final id = await createProject(tester, env, seconds: [3, 4]);
    expect(analytics.last(AppEvents.projectCreated), {
      'clips': 2,
      'format': 'portrait9x16',
    });
    await pumpApp(tester, env, location: AppRoutes.editor(id));
    await settleUntil(tester, find.byType(VideoClipTile));
    final controller = env.container.read(
      editorControllerProvider(id).notifier,
    );

    final textId = controller.addText('Hi', atUs: 0);
    expect(textId, isNotEmpty);
    expect(analytics.logged(AppEvents.textAdded), isTrue);

    final pip = env.library.addVideo('pip', seconds: 2);
    await tester.runAsync(() => controller.addOverlays([pip], atUs: 0));
    expect(analytics.last(AppEvents.overlayAdded), {'count': 1});

    env.engine.previewFrameHandler = (_, _, {required exact}) => tinyPng;
    final clip = env.container
        .read(editorControllerProvider(id))
        .requireValue
        .timeline
        .videoClips
        .first;
    await tester.runAsync(() => controller.freezeFrame(clip.id, 1000000));
    expect(analytics.logged(AppEvents.freezeFrame), isTrue);
    await tester.pump(autosaveDelay * 2);
    await settle(tester);
  });

  testWidgets('captions made, with their language and model', (tester) async {
    final analytics = RecordingAnalytics();
    final env = await createEnv(tester, analytics: analytics);
    final id = await createProject(tester, env);
    env.speech.transcript = Transcript(
      language: 'en',
      segments: [
        [token(' Hello', 500, 900), token(' there', 900, 1400)],
      ],
    );
    await pumpApp(tester, env, location: AppRoutes.editor(id));
    await settleUntil(tester, find.byType(VideoClipTile));
    await tester.tap(find.text('Captions'));
    await settle(tester);
    await tester.tap(find.widgetWithText(PrimaryButton, 'Generate captions'));
    for (var i = 0; !analytics.logged(AppEvents.captionsGenerated); i++) {
      expect(i, lessThan(200), reason: 'captions are made');
      await settle(tester, rounds: 1);
    }
    expect(analytics.last(AppEvents.captionsGenerated), {
      'segments': 1,
      'language': 'auto',
      'model': 'tiny',
    });
    await tester.pump(autosaveDelay * 2);
    await settle(tester);
  });

  testWidgets('an export, with its settings', (tester) async {
    final analytics = RecordingAnalytics();
    final env = await createEnv(tester, analytics: analytics);
    final id = await createProject(tester, env);
    await pumpApp(tester, env, location: AppRoutes.editor(id));
    await settleUntil(tester, find.byType(VideoClipTile));
    await tester.tap(find.widgetWithText(PrimaryButton, 'Export'));
    await settle(tester);
    await tester.tap(find.widgetWithText(PrimaryButton, 'Export').last);
    await settleUntil(tester, find.text('Saved to Photos'));
    expect(analytics.last(AppEvents.exportCompleted), {
      'resolution': 1080,
      'fps': 30,
      'seconds': 9,
      'hevc': 0,
    });
    await tester.tap(find.text('Back to editing'));
    await settle(tester);
    await tester.pump(autosaveDelay * 2);
    await settle(tester);
  });
}
