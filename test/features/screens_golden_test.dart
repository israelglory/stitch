@Tags(['golden'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/app/app.dart';
import 'package:stitch/app/router.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/features/captions/domain/transcript.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';
import 'package:stitch/features/editor/application/playback_controller.dart';
import 'package:stitch/features/media/domain/library_item.dart';
import 'package:stitch/features/settings/application/settings_controller.dart';
import 'package:stitch/features/settings/domain/app_settings.dart';

import '../helpers/app_scope.dart';
import '../helpers/fake_captions.dart';
import '../helpers/pump.dart';

/// Captures the whole app screen as `goldens/screens/<name>.png`.
Future<void> _golden(
  WidgetTester tester,
  String name, {
  bool settleFirst = true,
  bool precache = true,
}) async {
  // Let state-change animations (150 to 250ms) finish first.
  if (settleFirst) await tester.pump(const Duration(milliseconds: 300));
  if (precache) await precacheImages(tester);
  await expectLater(
    find.byType(StitchApp),
    matchesGoldenFile('goldens/screens/$name.png'),
  );
}

/// Lets pending editor saves finish so no timers outlive the test.
Future<void> _finish(WidgetTester tester) async {
  await tester.pump(autosaveDelay * 2);
  await settle(tester);
}

void main() {
  group('onboarding', () {
    for (final (i, name) in ['edit', 'private', 'captions'].indexed) {
      testWidgets(name, (tester) async {
        final env = await createEnv(tester, onboarded: false);
        await pumpApp(tester, env);
        for (var p = 0; p < i; p++) {
          await tester.tap(find.byType(PrimaryButton));
          await settle(tester);
        }
        await _golden(tester, 'onboarding_$name');
      });
    }
  });

  testWidgets('home empty', (tester) async {
    final env = await createEnv(tester);
    await pumpApp(tester, env);
    await _golden(tester, 'home_empty');
  });

  testWidgets('home with projects', (tester) async {
    final env = await createEnv(tester);
    await createProject(tester, env);
    await createProject(tester, env, name: 'Birthday', seconds: [12, 30]);
    await createProject(
      tester,
      env,
      name: 'A long project name that will not fit',
      seconds: [2],
    );
    await pumpApp(tester, env);
    await _golden(tester, 'home_projects');
  });

  testWidgets('picker with selection', (tester) async {
    final env = await createEnv(tester);
    for (var i = 0; i < 10; i++) {
      env.library.addVideo('v$i', seconds: 3 + i * 7);
    }
    await pumpApp(tester, env, location: AppRoutes.newProject);
    await tester.tap(find.byType(MediaThumbnail).at(2));
    await tester.tap(find.byType(MediaThumbnail).at(0));
    await tester.pump();
    await _golden(tester, 'picker_selection');
  });

  testWidgets('picker permission', (tester) async {
    final env = await createEnv(tester);
    env.library
      ..accessState = LibraryAccess.denied
      ..afterRequest = LibraryAccess.denied;
    await pumpApp(tester, env, location: AppRoutes.newProject);
    await _golden(tester, 'picker_permission');
  });

  testWidgets('format', (tester) async {
    final env = await createEnv(tester);
    env.library.addVideo('v');
    await pumpApp(tester, env, location: AppRoutes.newProject);
    await tester.tap(find.byType(MediaThumbnail).first);
    await tester.pump();
    await tester.tap(find.text('Add (1)'));
    await settle(tester);
    await _golden(tester, 'format');
  });

  group('editor', () {
    Future<void> openEditor(WidgetTester tester) async {
      final env = await createEnv(tester);
      final id = await createProject(tester, env);
      await pumpApp(tester, env, location: AppRoutes.editor(id));
      await settleUntil(tester, find.byType(VideoClipTile));
    }

    testWidgets('nothing selected', (tester) async {
      await openEditor(tester);
      await _golden(tester, 'editor');
      await _finish(tester);
    });

    testWidgets('clip selected', (tester) async {
      await openEditor(tester);
      await tester.tap(find.byType(VideoClipTile).at(1));
      await tester.pump();
      await _golden(tester, 'editor_clip_selected');
      await _finish(tester);
    });

    testWidgets('extracted audio selected', (tester) async {
      await openEditor(tester);
      await tester.tap(find.byType(VideoClipTile).first);
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('Extract audio'),
        100,
        scrollable: find.descendant(
          of: find.byType(ContextToolbar),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.ensureVisible(find.text('Extract audio'));
      await tester.pump();
      await tester.tap(find.text('Extract audio'));
      await tester.pump();
      await _golden(tester, 'editor_audio_selected');
      await _finish(tester);
    });

    testWidgets('audio menu', (tester) async {
      await openEditor(tester);
      await tester.tap(find.text('Audio'));
      await tester.pump();
      await _golden(tester, 'editor_audio_menu');
      await _finish(tester);
    });

    testWidgets('text editor', (tester) async {
      await openEditor(tester);
      await tester.tap(find.text('Text'));
      await settle(tester);
      await tester.enterText(find.byType(EditableText), 'Summer 2026');
      await settle(tester);
      await _golden(tester, 'editor_text_editor');
      await tester.tap(find.text('Style'));
      await settle(tester);
      await _golden(tester, 'editor_text_style');
      await tester.tap(find.bySemanticsLabel('Done'));
      await settle(tester);
      await _golden(tester, 'editor_text_selected');
      await _finish(tester);
    });

    testWidgets('music library', (tester) async {
      await openEditor(tester);
      await tester.tap(find.text('Audio'));
      await tester.pump();
      await tester.tap(find.text('Music'));
      await settle(tester);
      await _golden(tester, 'music_library');
      await _finish(tester);
    });

    testWidgets('voiceover', (tester) async {
      await openEditor(tester);
      await tester.tap(find.text('Audio'));
      await tester.pump();
      await tester.tap(find.text('Voiceover'));
      await settle(tester);
      await _golden(tester, 'voiceover_access');
      await tester.tap(find.text('Allow microphone'));
      await settle(tester);
      await _golden(tester, 'voiceover_ready');
      await tester.tap(
        find.bySemanticsLabel('Close').last,
        warnIfMissed: false,
      );
      await _finish(tester);
    });

    testWidgets('captions', (tester) async {
      final env = await createEnv(tester);
      final id = await createProject(tester, env);
      env.speech.transcript = Transcript(
        language: 'en',
        segments: [
          [
            token(' Summer', 500, 900),
            token(' at', 900, 1100),
            token(' the', 1100, 1300),
            token(' beach', 1300, 1800),
            token(',', 1800, 1900),
            token(' finally', 2000, 2600),
            token('.', 2600, 2700),
            token(' Look', 3500, 3800),
            token(' at', 3800, 4000),
            token(' those', 4000, 4400),
            token(' waves', 4400, 5000),
            token('.', 5000, 5100),
          ],
        ],
      );
      await pumpApp(tester, env, location: AppRoutes.editor(id));
      await settleUntil(tester, find.byType(VideoClipTile));
      await tester.tap(find.text('Captions'));
      await settle(tester);
      await _golden(tester, 'captions_sheet');

      await tester.tap(find.widgetWithText(PrimaryButton, 'Generate captions'));
      await tester.pump(const Duration(milliseconds: 120));
      await _golden(tester, 'captions_downloading', settleFirst: false);

      await settleUntil(tester, find.textContaining('Generating captions'));
      await _golden(tester, 'editor_captions_progress');

      await settleUntil(tester, find.byType(OverlayItemTile));
      await settle(tester);
      final container = env.container;
      await container.read(playbackControllerProvider.notifier).seek(1000000);
      await settle(tester);
      await _golden(tester, 'editor_captions');

      await tester.tap(find.text('Captions'));
      await settle(tester);
      await _golden(tester, 'caption_editor');
      await tester.tap(find.text('Style'));
      await settle(tester);
      await tester.tap(find.text('Highlight'));
      await settle(tester);
      await _golden(tester, 'caption_style');
      await _finish(tester);
    });

    testWidgets('export', (tester) async {
      final env = await createEnv(tester);
      final id = await createProject(tester, env);
      env.engine.exportStep = const Duration(seconds: 1);
      await pumpApp(tester, env, location: AppRoutes.editor(id));
      await settleUntil(tester, find.byType(VideoClipTile));
      await tester.tap(find.widgetWithText(PrimaryButton, 'Export'));
      await settle(tester);
      await _golden(tester, 'export_sheet');

      await tester.tap(find.widgetWithText(PrimaryButton, 'Export').last);
      await settleUntil(tester, find.text('40%'), maxRounds: 400);
      // Its poster is decoded already, on the editor screen.
      await _golden(tester, 'exporting', precache: false);

      await settleUntil(tester, find.text('Saved to Photos'), maxRounds: 400);
      await _golden(tester, 'export_done');
      await tester.tap(find.text('Back to editing'));
      await _finish(tester);
    });

    testWidgets('export failed', (tester) async {
      final env = await createEnv(tester);
      final id = await createProject(tester, env);
      env.system.free = 1000;
      await pumpApp(tester, env, location: AppRoutes.editor(id));
      await settleUntil(tester, find.byType(VideoClipTile));
      await tester.tap(find.widgetWithText(PrimaryButton, 'Export'));
      await settle(tester);
      await tester.tap(find.widgetWithText(PrimaryButton, 'Export').last);
      await settleUntil(tester, find.text('There is not enough free space.'));
      await _golden(tester, 'export_failed');
      await tester.tap(find.text('Back to editing'));
      await _finish(tester);
    });

    testWidgets('transition sheet', (tester) async {
      await openEditor(tester);
      await tester.tap(find.byType(TransitionButton).first);
      await settle(tester);
      await tester.tap(find.text('Crossfade'));
      await tester.pump();
      await _golden(tester, 'editor_transition_sheet');
      await _finish(tester);
    });
  });

  group('settings', () {
    Future<TestEnv> open(WidgetTester tester, {ThemeChoice? theme}) async {
      final env = await createEnv(tester);
      if (theme != null) {
        env.container
            .read(settingsControllerProvider.notifier)
            .update((s) => s.copyWith(theme: theme));
      }
      await pumpApp(tester, env, location: AppRoutes.settings);
      await settle(tester);
      return env;
    }

    testWidgets('dark', (tester) async {
      await open(tester);
      await _golden(tester, 'settings');
    });

    testWidgets('light', (tester) async {
      await open(tester, theme: ThemeChoice.light);
      await _golden(tester, 'settings_light');
    });

    testWidgets('home in light', (tester) async {
      final env = await createEnv(tester);
      env.container
          .read(settingsControllerProvider.notifier)
          .update((s) => s.copyWith(theme: ThemeChoice.light));
      await createProject(tester, env);
      await pumpApp(tester, env);
      await _golden(tester, 'home_light');
    });

    testWidgets('editor in light', (tester) async {
      final env = await createEnv(tester);
      env.container
          .read(settingsControllerProvider.notifier)
          .update((s) => s.copyWith(theme: ThemeChoice.light));
      final id = await createProject(tester, env);
      await pumpApp(tester, env, location: AppRoutes.editor(id));
      await settleUntil(tester, find.byType(VideoClipTile));
      await _golden(tester, 'editor_light');
      await _finish(tester);
    });
  });
}
