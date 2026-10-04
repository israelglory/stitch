// The online sound library through the real screens, with a fake store
// (no network): browse, search, try, download, add, fail and retry, and
// turning the library off.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/app/router.dart';
import 'package:stitch/core/errors/failure.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/engine/editor_engine.dart';
import 'package:stitch/features/audio/application/sound_library.dart';
import 'package:stitch/features/audio/data/sound_library.dart';
import 'package:stitch/features/audio/presentation/audio_library_screen.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';
import 'package:stitch/features/editor/application/editor_state.dart';
import 'package:stitch/features/editor/presentation/editor_screen.dart';
import 'package:stitch/features/settings/application/settings_controller.dart';
import 'package:stitch/features/timeline/domain/models.dart' as m;

import '../helpers/app_scope.dart';
import '../helpers/pump.dart';

void main() {
  late TestEnv env;

  Future<String> open(WidgetTester tester, {required String library}) async {
    env = await createEnv(tester);
    final id = await createProject(tester, env);
    env.engine.probeHandler = (path) => const MediaInfo(
      width: 0,
      height: 0,
      hasVideo: false,
      hasAudio: true,
      durationUs: 95000000,
    );
    await pumpApp(tester, env, location: AppRoutes.editor(id));
    await tester.tap(find.text('Audio'));
    await tester.pump();
    await tester.tap(find.text(library));
    await settle(tester);
    expect(find.byType(AudioLibraryScreen), findsOneWidget);
    await tester.tap(find.text('Online'));
    await settle(tester);
    return id;
  }

  EditorState stateOf(WidgetTester tester, String id) =>
      ProviderScope.containerOf(tester.element(find.byType(EditorScreen)))
          .read(editorControllerProvider(id))
          .requireValue;

  Finder rowOf(String title) =>
      find.ancestor(of: find.text(title), matching: find.byType(ListRow));

  Future<void> finish(WidgetTester tester) async {
    await tester.pump(autosaveDelay * 2);
    await settle(tester);
  }

  testWidgets('downloads music and adds it at the playhead', (tester) async {
    final id = await open(tester, library: 'Music');
    expect(find.text('Party time'), findsOneWidget);
    expect(find.text('Old Key'), findsOneWidget);
    expect(find.text('Rain'), findsNothing, reason: 'effects are elsewhere');

    // Not here yet: no Add, a download button.
    expect(
      find.descendant(of: rowOf('Party time'), matching: find.text('Add')),
      findsNothing,
    );
    await tester.tap(find.bySemanticsLabel('Download Party time'));
    await tester.pump(const Duration(milliseconds: 150));
    expect(
      find.descendant(
        of: rowOf('Party time'),
        matching: find.byType(ProgressRing),
      ),
      findsOneWidget,
    );
    await settle(tester);
    expect(env.sounds.downloads, ['party_time']);

    await tester.tap(
      find.descendant(of: rowOf('Party time'), matching: find.text('Add')),
    );
    await settleUntil(tester, find.byType(EditorScreen));
    await settle(tester);
    final item = stateOf(tester, id).timeline.audioItems.single;
    expect(item.name, 'Party time');
    expect(item.kind, m.AudioKind.music);
    await finish(tester);
  });

  testWidgets('tries music from its preview, without downloading it', (
    tester,
  ) async {
    await open(tester, library: 'Music');
    await tester.tap(find.bySemanticsLabel('Play Old Key'));
    await settle(tester);
    expect(env.audio.previews.single, endsWith('previews/old_key.m4a'));
    expect(find.byType(MiniPlayer), findsOneWidget);
    expect(env.sounds.downloads, isEmpty);
    await finish(tester);
  });

  testWidgets('searches and filters by mood', (tester) async {
    await open(tester, library: 'Music');
    await tester.enterText(find.byType(EditableText), 'key');
    await tester.pump();
    expect(find.text('Old Key'), findsOneWidget);
    expect(find.text('Party time'), findsNothing);
    await tester.enterText(find.byType(EditableText), '');
    await tester.tap(find.text('Upbeat'));
    await tester.pump();
    expect(find.text('Party time'), findsOneWidget);
    expect(find.text('Old Key'), findsNothing);
    await tester.enterText(find.byType(EditableText), 'nothing like it');
    await tester.pump();
    expect(find.text('No sounds match'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('a failed download says so and retries', (tester) async {
    await open(tester, library: 'Sound effects');
    expect(find.text('Rain'), findsOneWidget);
    env.sounds.failNext = const DownloadFailure(cause: 'offline');
    await tester.tap(find.bySemanticsLabel('Download Rain'));
    await settle(tester);
    expect(find.text('Download failed. Tap to try again.'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Download Rain'));
    await settle(tester);
    expect(
      find.descendant(of: rowOf('Rain'), matching: find.text('Add')),
      findsOneWidget,
    );
    expect(env.sounds.downloads, ['rain', 'rain']);
    await finish(tester);
  });

  testWidgets('a cancelled download can start again', (tester) async {
    await open(tester, library: 'Sound effects');
    await tester.tap(find.bySemanticsLabel('Download Boing'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.bySemanticsLabel(RegExp('^Downloading Boing')));
    await settle(tester);
    expect(find.bySemanticsLabel('Download Boing'), findsOneWidget);
    expect(env.sounds.isDownloaded(_boing(env)), isFalse);
    await finish(tester);
  });

  testWidgets('off in Settings, the Online tab says so', (tester) async {
    env = await createEnv(tester);
    env.container
        .read(settingsControllerProvider.notifier)
        .update((s) => s.copyWith(onlineSounds: false));
    final id = await createProject(tester, env);
    await pumpApp(tester, env, location: AppRoutes.editor(id));
    await tester.tap(find.text('Audio'));
    await tester.pump();
    await tester.tap(find.text('Music'));
    await settle(tester);
    await tester.tap(find.text('Online'));
    await settle(tester);
    expect(find.text('The online library is off'), findsOneWidget);
    expect(find.text('Party time'), findsNothing);
    await finish(tester);
  });
}

/// The Boing entry of the fake catalog, as the store sees it.
LibrarySound _boing(TestEnv env) => env.container
    .read(soundLibraryProvider)
    .catalog!
    .sounds
    .firstWhere((s) => s.id == 'boing');
