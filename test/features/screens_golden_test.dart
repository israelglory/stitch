@Tags(['golden'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/app/app.dart';
import 'package:stitch/app/router.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';
import 'package:stitch/features/media/domain/library_item.dart';

import '../helpers/pump.dart';

/// Captures the whole app screen as `goldens/screens/<name>.png`.
Future<void> _golden(WidgetTester tester, String name) async {
  // Let state-change animations (150 to 250ms) finish first.
  await tester.pump(const Duration(milliseconds: 300));
  await precacheImages(tester);
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
}
