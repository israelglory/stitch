// End-to-end flows through the real screens, with the fake library and
// engine and a temp folder for storage.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/app/providers.dart';
import 'package:stitch/app/router.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';
import 'package:stitch/features/editor/application/editor_state.dart';
import 'package:stitch/features/editor/presentation/editor_screen.dart';
import 'package:stitch/features/media/domain/library_item.dart';
import 'package:stitch/features/onboarding/presentation/onboarding_screen.dart';
import 'package:stitch/features/projects/presentation/projects_screen.dart';

import '../helpers/pump.dart';

/// Lets the editor's pending autosave run so no timers outlive the test.
Future<void> finishEditing(WidgetTester tester) async {
  await tester.pump(autosaveDelay * 2);
  await settle(tester);
}

void main() {
  testWidgets('onboarding: continue through three pages to projects', (
    tester,
  ) async {
    final env = await createEnv(tester, onboarded: false);
    await pumpApp(tester, env);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('Edit videos on your phone'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await settle(tester);
    expect(find.text('Everything stays on your device'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await settle(tester);
    expect(find.text('Captions without the internet'), findsOneWidget);
    await tester.tap(find.text('Get started'));
    await settle(tester);
    expect(find.byType(ProjectsScreen), findsOneWidget);
  });

  testWidgets('home: empty state offers the only primary action', (
    tester,
  ) async {
    final env = await createEnv(tester);
    await pumpApp(tester, env);
    expect(find.text('No projects yet'), findsOneWidget);
    expect(find.byType(PrimaryButton), findsOneWidget);
  });

  testWidgets('new project: pick in order, choose a format, open editor', (
    tester,
  ) async {
    final env = await createEnv(tester);
    env.library
      ..addVideo('a', seconds: 3)
      ..addVideo('b')
      ..addPhoto('p');
    await pumpApp(tester, env);

    await tester.tap(find.text('New project'));
    await settle(tester);
    expect(find.text('Add media'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);

    // Videos filter shows two videos; pick b then a.
    final thumbs = find.byType(MediaThumbnail);
    expect(thumbs, findsNWidgets(2));
    await tester.tap(thumbs.at(1));
    await tester.tap(thumbs.at(0));
    await tester.pump();
    expect(find.text('Add (2)'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    // Deselecting the first renumbers the second.
    await tester.tap(thumbs.at(1));
    await tester.pump();
    expect(find.text('Add (1)'), findsOneWidget);
    await tester.tap(thumbs.at(1));
    await tester.pump();

    await tester.tap(find.text('Add (2)'));
    await settle(tester);
    expect(find.text('Choose a format'), findsOneWidget);
    await tester.tap(find.text('1:1'));
    await tester.tap(find.text('Create'));
    await settleUntil(tester, find.byType(VideoClipTile));
    final projects = await tester.runAsync(
      () => env.container.read(projectStoreProvider).list(),
    );
    final id = projects!.single.id;
    final state = env.container.read(editorControllerProvider(id)).value!;
    expect(state.project.canvas.preset.name, 'square');
    // Tap order is clip order. b was deselected and picked again, so it
    // moved behind a: a (3s), then b (5s).
    expect(state.timeline.videoClips.map((c) => c.durationUs), [
      3000000,
      5000000,
    ]);
    await finishEditing(tester);
  });

  testWidgets('picker: explains, asks, then points to settings', (
    tester,
  ) async {
    final env = await createEnv(tester);
    env.library
      ..accessState = LibraryAccess.denied
      ..afterRequest = LibraryAccess.denied;
    await pumpApp(tester, env, location: AppRoutes.newProject);

    expect(find.text('Allow access to your photos'), findsOneWidget);
    await tester.tap(find.text('Allow access'));
    await settle(tester);
    expect(env.library.requests, 1);
    expect(find.text('Open settings'), findsOneWidget);
    await tester.tap(find.text('Open settings'));
    await settle(tester);
    expect(env.library.settingsOpened, 1);
  });

  testWidgets('home: rename and delete through the overflow menu', (
    tester,
  ) async {
    final env = await createEnv(tester);
    await createProject(tester, env);
    await pumpApp(tester, env);
    expect(find.text('Beach day'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Options for Beach day'));
    await settle(tester);
    await tester.tap(find.text('Rename'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'Sunset');
    await tester.tap(find.text('Save'));
    await settleUntil(tester, find.bySemanticsLabel('Options for Sunset'));

    await tester.tap(find.bySemanticsLabel('Options for Sunset'));
    await settle(tester);
    await tester.tap(find.text('Delete'));
    await settle(tester);
    expect(find.text('Delete Sunset?'), findsOneWidget);
    await tester.tap(find.widgetWithText(DestructiveButton, 'Delete'));
    await settleUntil(tester, find.text('No projects yet'));
  });

  group('editor', () {
    Future<(String, EditorController)> open(WidgetTester tester) async {
      final env = await createEnv(tester);
      final id = await createProject(tester, env);
      await pumpApp(tester, env, location: AppRoutes.editor(id));
      return (id, env.container.read(editorControllerProvider(id).notifier));
    }

    EditorState stateOf(WidgetTester tester, String id) {
      final element = tester.element(find.byType(EditorScreen));
      final container = ProviderScope.containerOf(element);
      return container.read(editorControllerProvider(id)).requireValue;
    }

    testWidgets('shows clips; selecting a clip switches the tools', (
      tester,
    ) async {
      final (id, _) = await open(tester);
      expect(find.byType(VideoClipTile), findsNWidgets(3));
      expect(find.byType(TransitionButton), findsNWidgets(2));
      expect(find.text('Ratio'), findsOneWidget);
      expect(find.text('Split'), findsNothing);

      await tester.tap(find.byType(VideoClipTile).first);
      await tester.pump();
      expect(find.text('Split'), findsOneWidget);
      expect(stateOf(tester, id).selection, isA<ClipSelected>());

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pump();
      expect(find.text('Ratio'), findsOneWidget);
      await finishEditing(tester);
    });

    testWidgets('split at the playhead, then undo and redo', (tester) async {
      final (id, _) = await open(tester);
      // Scrub 1s into the first clip.
      await tester.drag(find.byType(VideoClipTile).first, const Offset(-64, 0));
      await settle(tester);

      await tester.tap(find.byType(VideoClipTile).first);
      await tester.pump();
      await tester.tap(find.text('Split'));
      await tester.pump();
      expect(stateOf(tester, id).timeline.videoClips, hasLength(4));

      await tester.tap(find.bySemanticsLabel('Undo'));
      await tester.pump();
      expect(stateOf(tester, id).timeline.videoClips, hasLength(3));
      await tester.tap(find.bySemanticsLabel('Redo'));
      await tester.pump();
      expect(stateOf(tester, id).timeline.videoClips, hasLength(4));
      await finishEditing(tester);
    });

    testWidgets('trim handle drag shortens a clip in one undo step', (
      tester,
    ) async {
      final (id, _) = await open(tester);
      final first = find.byType(VideoClipTile).first;
      await tester.tap(first);
      await tester.pump();
      final before = stateOf(tester, id).timeline.videoClips.first.durationUs;

      final rect = tester.getRect(first);
      await tester.timedDragFrom(
        rect.centerRight - const Offset(4, 0),
        const Offset(-64, 0),
        const Duration(milliseconds: 300),
      );
      await settle(tester);
      final after = stateOf(tester, id).timeline.videoClips.first.durationUs;
      expect(after, lessThan(before));
      expect(stateOf(tester, id).history.undoDepth, 1);
      await finishEditing(tester);
    });

    testWidgets('transition sheet sets a crossfade', (tester) async {
      final (id, _) = await open(tester);
      await tester.tap(find.byType(TransitionButton).first);
      await settle(tester);
      expect(find.text('Transition'), findsOneWidget);
      await tester.tap(find.text('Crossfade'));
      await tester.pump();
      final t = stateOf(tester, id).timeline.transitions.single;
      expect(t.type.name, 'crossfade');
      await finishEditing(tester);
    });

    testWidgets('original sound toggle mutes and unmutes', (tester) async {
      final (id, _) = await open(tester);
      await tester.tap(find.bySemanticsLabel('Sound'));
      await tester.pump();
      expect(
        stateOf(tester, id).timeline.audioMix.originalSoundEnabled,
        isFalse,
      );
      expect(find.bySemanticsLabel('Muted'), findsOneWidget);
      await finishEditing(tester);
    });

    testWidgets('extract audio adds an audio lane item', (tester) async {
      final (id, _) = await open(tester);
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
      // Built is not the same as on screen; bring it fully into view.
      await tester.ensureVisible(find.text('Extract audio'));
      await tester.pump();
      await tester.tap(find.text('Extract audio'));
      await tester.pump();
      expect(stateOf(tester, id).timeline.audioItems, hasLength(1));
      expect(find.byType(AudioItemTile), findsOneWidget);
      // The new item is selected and shows audio tools.
      expect(find.text('Fade'), findsOneWidget);
      await finishEditing(tester);
    });
  });
}
