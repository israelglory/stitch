// Text and audio flows through the real screens, with the fake engine,
// audio device, and text rasterizer.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/app/router.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/engine/editor_engine.dart';
import 'package:stitch/features/audio/data/audio_device.dart';
import 'package:stitch/features/audio/presentation/audio_library_screen.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';
import 'package:stitch/features/editor/application/editor_state.dart';
import 'package:stitch/features/editor/presentation/editor_screen.dart';
import 'package:stitch/features/text/presentation/text_overlay_layer.dart';
import 'package:stitch/features/timeline/domain/models.dart' as m;

import '../helpers/app_scope.dart';
import '../helpers/pump.dart';

Future<void> finishEditing(WidgetTester tester) async {
  await tester.pump(autosaveDelay * 2);
  await settle(tester);
}

void main() {
  late TestEnv env;

  Future<String> open(WidgetTester tester) async {
    env = await createEnv(tester);
    final id = await createProject(tester, env);
    // Audio files the importer reads report sound from here on.
    env.engine.probeHandler = (path) => const MediaInfo(
      width: 0,
      height: 0,
      hasVideo: false,
      hasAudio: true,
      durationUs: 2000000,
    );
    await pumpApp(tester, env, location: AppRoutes.editor(id));
    return id;
  }

  EditorState stateOf(WidgetTester tester, String id) {
    final element = tester.element(find.byType(EditorScreen));
    return ProviderScope.containerOf(element)
        .read(editorControllerProvider(id))
        .requireValue;
  }

  List<dynamic> overlaysSent() =>
      (jsonDecode(env.engine.lastDocument!) as Map)['overlays'] as List;

  Future<void> openAudioMenu(WidgetTester tester) async {
    await tester.tap(find.text('Audio'));
    await tester.pump();
    expect(find.text('Music'), findsOneWidget);
  }

  group('text', () {
    testWidgets('type, style, and animate; undo removes it in one step', (
      tester,
    ) async {
      final id = await open(tester);
      await tester.tap(find.text('Text'));
      await settle(tester);
      await tester.enterText(find.byType(EditableText), 'Hello');
      await settle(tester);
      var text = stateOf(tester, id).timeline.textItems.single;
      expect(text.text, 'Hello');

      await tester.tap(find.text('Anton'));
      await tester.pump();
      await tester.tap(find.text('Style'));
      await settle(tester);
      await tester.tap(find.bySemanticsLabel('Yellow').first);
      await tester.pump();
      await tester.tap(find.text('Animation'));
      await settle(tester);
      await tester.tap(find.text('Fade').first);
      await tester.pump();
      text = stateOf(tester, id).timeline.textItems.single;
      expect(text.style.fontId, 'anton');
      expect(text.style.color, TextPalette.colors[2].toARGB32());
      expect(text.animationIn, m.TextAnimation.fade);

      await tester.tap(find.bySemanticsLabel('Done'));
      await settle(tester);
      // Selected: drawn by the editor, left out of the engine's document.
      expect(stateOf(tester, id).selection, isA<TextSelected>());
      expect(stateOf(tester, id).liveTexts, {text.id});
      expect(overlaysSent(), isEmpty);
      expect(find.text('Edit'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Back'));
      await settle(tester);
      // Handed back: the engine now draws it, from the rasterized image.
      expect(overlaysSent(), hasLength(1));
      expect((overlaysSent().single as Map)['animationIn'], {
        'type': 'fade',
        'durationUs': 400000,
      });
      expect(env.rasterizer.rendered, contains('Hello'));
      expect(stateOf(tester, id).liveTexts, isEmpty);

      await tester.tap(find.bySemanticsLabel('Undo'));
      await settle(tester);
      expect(stateOf(tester, id).timeline.textItems, isEmpty);
      await finishEditing(tester);
    });

    testWidgets('an empty editor adds nothing', (tester) async {
      final id = await open(tester);
      await tester.tap(find.text('Text'));
      await settle(tester);
      await tester.tap(find.bySemanticsLabel('Done'));
      await settle(tester);
      expect(stateOf(tester, id).timeline.textItems, isEmpty);
      expect(stateOf(tester, id).history.undoDepth, 0);
      await finishEditing(tester);
    });

    testWidgets('dragging selected text on the preview moves it', (
      tester,
    ) async {
      final id = await open(tester);
      await tester.tap(find.text('Text'));
      await settle(tester);
      await tester.enterText(find.byType(EditableText), 'Move me');
      await settle(tester);
      await tester.tap(find.bySemanticsLabel('Done'));
      await settle(tester);

      final layer = tester.getRect(find.byType(TextOverlayLayer));
      await tester.timedDragFrom(
        layer.center,
        const Offset(40, 0),
        const Duration(milliseconds: 300),
      );
      await settle(tester);
      final transform = stateOf(tester, id).timeline.textItems.single.transform;
      expect(transform.x, greaterThan(0.55));
      expect(transform.y, closeTo(0.5, 0.01));
      await finishEditing(tester);
    });
  });

  group('audio', () {
    testWidgets('adds bundled music at the playhead', (tester) async {
      final id = await open(tester);
      await openAudioMenu(tester);
      await tester.tap(find.text('Music'));
      await settle(tester);
      expect(find.byType(AudioLibraryScreen), findsOneWidget);
      expect(find.text('Upbeat'), findsOneWidget);

      await tester.tap(find.widgetWithText(AppTextButton, 'Add').first);
      await settleUntil(tester, find.byType(EditorScreen));
      await settle(tester);
      final item = stateOf(tester, id).timeline.audioItems.single;
      expect(item.kind, m.AudioKind.music);
      expect(item.name, 'Roller Fever');
      final asset = stateOf(tester, id).project.media[item.mediaId]!;
      expect(asset.kind, m.MediaKind.audio);
      expect(find.byType(AudioItemTile), findsOneWidget);
      await finishEditing(tester);
    });

    testWidgets('tries a sound effect with the mini player', (tester) async {
      await open(tester);
      await openAudioMenu(tester);
      await tester.tap(find.text('Sound effects'));
      await settle(tester);
      await tester.tap(find.bySemanticsLabel('Play Click'));
      await settle(tester);
      expect(env.audio.previews.single, endsWith('click.m4a'));
      expect(find.byType(MiniPlayer), findsOneWidget);
      expect(find.text('Now playing'), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(MiniPlayer),
          matching: find.byType(AppIconButton),
        ),
      );
      await settle(tester);
      expect(find.byType(MiniPlayer), findsNothing);
      await finishEditing(tester);
    });

    testWidgets('adds music from a file on the device', (tester) async {
      final id = await open(tester);
      final picked = File('${env.root.path}/picked.m4a');
      await tester.runAsync(() => picked.writeAsBytes([0, 1, 2]));
      env.audio.nextPick = PickedAudio(path: picked.path, name: 'My song');

      await openAudioMenu(tester);
      await tester.tap(find.text('Music'));
      await settle(tester);
      await tester.tap(find.text('From device'));
      await settle(tester);
      await tester.tap(find.text('Choose a file'));
      await settleUntil(tester, find.byType(EditorScreen));
      await settle(tester);
      final item = stateOf(tester, id).timeline.audioItems.single;
      expect(item.name, 'My song');
      // Moved into the project, not copied.
      expect(picked.existsSync(), isFalse);
      await finishEditing(tester);
    });

    testWidgets('voiceover: asks, counts down, records, and adds', (
      tester,
    ) async {
      final id = await open(tester);
      await openAudioMenu(tester);
      await tester.tap(find.text('Voiceover'));
      await settle(tester);
      expect(find.text('Record your voice over the video'), findsOneWidget);

      await tester.tap(find.text('Allow microphone'));
      await settle(tester);
      expect(find.bySemanticsLabel('Record'), findsOneWidget);

      await tester.tap(find.byType(RecordButton));
      await tester.pump();
      expect(find.text('3'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('2'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      await settle(tester);
      expect(env.audio.recordingPath, isNotNull);
      expect(env.engine.previewVolume, 0);
      env.audio.emitLevel(0.5);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(LevelMeter), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Stop recording'));
      await settle(tester);
      expect(env.engine.previewVolume, 1);
      expect(find.text('Retake'), findsOneWidget);

      await tester.tap(find.widgetWithText(PrimaryButton, 'Add'));
      await settle(tester);
      final item = stateOf(tester, id).timeline.audioItems.single;
      expect(item.kind, m.AudioKind.voiceover);
      expect(item.name, 'Voiceover');
      await finishEditing(tester);
    });

    testWidgets('voiceover: refused for good points to Settings', (
      tester,
    ) async {
      await open(tester);
      env.audio.access = MicAccess.permanentlyDenied;
      await openAudioMenu(tester);
      await tester.tap(find.text('Voiceover'));
      await settle(tester);
      expect(find.text('Microphone access is off'), findsOneWidget);
      await tester.tap(find.text('Open settings'));
      await settle(tester);
      expect(env.audio.settingsOpened, 1);
      await finishEditing(tester);
    });

    testWidgets('original sound opens the volume balance', (tester) async {
      await open(tester);
      await openAudioMenu(tester);
      await tester.scrollUntilVisible(
        find.text('Original sound'),
        100,
        scrollable: find.descendant(
          of: find.byType(ContextToolbar),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.ensureVisible(find.text('Original sound'));
      await tester.pump();
      await tester.tap(find.text('Original sound'));
      await settle(tester);
      expect(find.text('Volume balance'), findsOneWidget);
      expect(find.text('Added audio'), findsOneWidget);
      await finishEditing(tester);
    });
  });
}
