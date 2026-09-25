// Auto captions through the real screens, with the fake engine, speech
// recognizer, and model store.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/app/router.dart';
import 'package:stitch/core/errors/failure.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/features/captions/data/caption_models.dart';
import 'package:stitch/features/captions/domain/transcript.dart';
import 'package:stitch/features/captions/presentation/caption_editor_sheet.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';
import 'package:stitch/features/editor/application/editor_state.dart';
import 'package:stitch/features/editor/application/playback_controller.dart';
import 'package:stitch/features/editor/presentation/editor_screen.dart';
import 'package:stitch/features/timeline/domain/caption_ops.dart';
import 'package:stitch/features/timeline/domain/models.dart';

import '../helpers/app_scope.dart';
import '../helpers/fake_captions.dart';
import '../helpers/pump.dart';

/// Two sentences, over the first two clips (3 s and 4 s).
final _speech = Transcript(
  language: 'en',
  segments: [
    [
      token(' Hello', 500, 900),
      token(' there', 900, 1400),
      token('.', 1400, 1500),
      token(' This', 3500, 3800),
      token(' is', 3800, 4000),
      token(' Stitch', 4000, 4600),
      token('.', 4600, 4700),
    ],
  ],
);

void main() {
  late TestEnv env;

  Future<String> open(WidgetTester tester) async {
    env = await createEnv(tester);
    final id = await createProject(tester, env);
    env.speech.transcript = _speech;
    await pumpApp(tester, env, location: AppRoutes.editor(id));
    return id;
  }

  EditorController controllerOf(WidgetTester tester, String id) =>
      ProviderScope.containerOf(tester.element(find.byType(EditorScreen)))
          .read(editorControllerProvider(id).notifier);

  EditorState stateOf(WidgetTester tester, String id) =>
      ProviderScope.containerOf(tester.element(find.byType(EditorScreen)))
          .read(editorControllerProvider(id))
          .requireValue;

  Future<void> finish(WidgetTester tester) async {
    await tester.pump(autosaveDelay * 2);
    await settle(tester);
  }

  Future<void> generate(WidgetTester tester) async {
    await tester.tap(find.text('Captions'));
    await settle(tester);
    await tester.tap(find.widgetWithText(PrimaryButton, 'Generate captions'));
    await settleUntil(tester, find.textContaining('Generating captions'));
  }

  Future<void> waitForCaptions(WidgetTester tester, String id) async {
    for (var i = 0; i < 100; i++) {
      if (stateOf(tester, id).timeline.captionTrack.segments.isNotEmpty) {
        return;
      }
      await settle(tester, rounds: 1);
    }
    fail('No captions');
  }

  testWidgets('downloads the model once, generates, and undoes in one step', (
    tester,
  ) async {
    final id = await open(tester);
    await tester.tap(find.text('Captions'));
    await settle(tester);
    expect(find.text('Auto detect'), findsOneWidget);
    expect(find.text('44 MB download, needed once'), findsOneWidget);

    await tester.tap(find.widgetWithText(PrimaryButton, 'Generate captions'));
    await settleUntil(tester, find.textContaining('Generating captions'));
    expect(env.models.downloads, [CaptionModel.tiny.fileName]);
    await waitForCaptions(tester, id);
    await settle(tester);

    final captions = stateOf(tester, id).timeline.sortedCaptions();
    expect(captions.map((c) => c.text), ['Hello there.', 'This is Stitch.']);
    expect(captions.first.words, hasLength(2));
    expect(stateOf(tester, id).timeline.captionTrack.language, 'en');
    expect(find.textContaining('Generating captions'), findsNothing);
    // Recognition heard the whole mix, with auto detection.
    expect(env.speech.calls.single.language, isNull);
    expect(env.engine.speechDocuments, hasLength(1));

    // The engine draws them.
    final overlays =
        (jsonDecode(env.engine.lastDocument!) as Map)['overlays'] as List;
    final ids = [for (final c in captions) '${c.id}#0'];
    expect(overlays.map((o) => (o as Map)['id']), ids);

    await tester.tap(find.bySemanticsLabel('Undo'));
    await settle(tester);
    expect(stateOf(tester, id).timeline.captionTrack.segments, isEmpty);
    await finish(tester);
  });

  testWidgets('recognizes the language chosen', (tester) async {
    await open(tester);
    env.models.installed.add(CaptionModel.tiny.fileName);
    await tester.tap(find.text('Captions'));
    await settle(tester);
    expect(find.text('Downloaded'), findsOneWidget);
    await tester.tap(find.text('Language'));
    await settle(tester);
    await tester.scrollUntilVisible(
      find.text('Español'),
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Español'));
    await settle(tester);
    expect(find.text('Español'), findsOneWidget);
    await tester.tap(find.widgetWithText(PrimaryButton, 'Generate captions'));
    await settleUntil(tester, find.textContaining('Generating captions'));
    await settle(tester, rounds: 30);
    expect(env.speech.calls.single.language, 'es');
    expect(env.models.downloads, isEmpty);
    await finish(tester);
  });

  testWidgets('cancel stops it and changes nothing', (tester) async {
    final id = await open(tester);
    await generate(tester);
    await tester.tap(find.widgetWithText(AppTextButton, 'Cancel'));
    await settle(tester);
    expect(find.textContaining('Generating captions'), findsNothing);
    await settle(tester);
    expect(stateOf(tester, id).timeline.captionTrack.segments, isEmpty);
    await finish(tester);
  });

  testWidgets('no speech says so, and Retry reopens the sheet', (tester) async {
    await open(tester);
    env.speech.transcript = const Transcript(language: 'en', segments: []);
    await generate(tester);
    await settleUntil(tester, find.text('No speech was found in this sound.'));
    await tester.tap(find.text('Retry'));
    await settle(tester);
    expect(find.text('Auto captions'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('a damaged model is removed, to download again', (tester) async {
    await open(tester);
    env.models.installed.add(CaptionModel.tiny.fileName);
    env.speech.failure = const CaptionFailure(CaptionProblem.modelDamaged);
    await generate(tester);
    await settleUntil(tester, find.textContaining('speech model was damaged'));
    expect(env.models.installed, isEmpty);
    await finish(tester);
  });

  testWidgets('without speech recognition, the sheet says so', (tester) async {
    await open(tester);
    env.speech.available = false;
    await tester.tap(find.text('Captions'));
    await settle(tester);
    expect(
      find.text('Captions are not available on this device.'),
      findsOneWidget,
    );
    expect(find.text('Generate captions'), findsNothing);
    await finish(tester);
  });

  testWidgets('the sheets fit a small screen with large text', (tester) async {
    env = await createEnv(tester);
    final id = await createProject(tester, env);
    env.speech.transcript = _speech;
    await pumpApp(
      tester,
      env,
      location: AppRoutes.editor(id),
      size: const Size(320, 568),
      textScale: 2,
    );
    await tester.tap(find.text('Captions'));
    await settle(tester);
    expect(find.text('Auto captions'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.widgetWithText(PrimaryButton, 'Generate captions'));
    await settleUntil(tester, find.textContaining('Generating captions'));
    await settle(tester, rounds: 2);
    expect(tester.takeException(), isNull);
    await waitForCaptions(tester, id);
    await settle(tester);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Captions'));
    await settle(tester);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Style'));
    await settle(tester);
    expect(tester.takeException(), isNull);
    await finish(tester);
  });

  group('caption editor', () {
    Future<String> withCaptions(WidgetTester tester) async {
      final id = await open(tester);
      await generate(tester);
      await waitForCaptions(tester, id);
      await settle(tester);
      return id;
    }

    testWidgets('edits text in one step, seeks, splits, merges, deletes', (
      tester,
    ) async {
      final id = await withCaptions(tester);
      await tester.tap(find.text('Captions'));
      await settle(tester);
      expect(
        find.descendant(
          of: find.byType(CaptionEditorPanel),
          matching: find.text('Hello there.'),
        ),
        findsOneWidget,
      );

      // Seek from the time.
      expect(find.bySemanticsLabel('Go to 0:03.5'), findsOneWidget);
      await tester.tap(find.text('0:03.5'));
      await settle(tester);
      expect(
        ProviderScope.containerOf(tester.element(find.byType(EditorScreen)))
            .read(playbackControllerProvider)
            .positionUs,
        3500000,
      );

      // Edit the first: one undo step for the whole visit.
      final first = find.byType(EditableText).first;
      await tester.tap(first);
      await settle(tester);
      await tester.enterText(first, 'Hello there');
      await tester.enterText(first, 'Hi there');
      await settle(tester);
      expect(
        stateOf(tester, id).timeline.sortedCaptions().first.text,
        'Hi there',
      );

      // Split before "there".
      final field = tester.widget<EditableText>(first);
      field.controller.selection = const TextSelection.collapsed(offset: 3);
      await tester.pump();
      await tester.tap(find.text('Split at cursor'));
      await settle(tester);
      var captions = stateOf(tester, id).timeline.sortedCaptions();
      expect(captions.map((c) => c.text), ['Hi', 'there', 'This is Stitch.']);

      // Merge them back.
      await tester.tap(find.byType(EditableText).first);
      await settle(tester);
      await tester.tap(find.text('Merge with next'));
      await settle(tester);
      captions = stateOf(tester, id).timeline.sortedCaptions();
      expect(captions.map((c) => c.text), ['Hi there', 'This is Stitch.']);

      // Delete the second.
      await tester.tap(find.byType(EditableText).last);
      await settle(tester);
      await tester.tap(find.widgetWithText(AppTextButton, 'Delete'));
      await settle(tester);
      expect(stateOf(tester, id).timeline.captionTrack.segments, hasLength(1));

      // Undo walks back delete, merge, split, then the text edit.
      final controller = controllerOf(tester, id);
      for (var i = 0; i < 4; i++) {
        controller.undo();
      }
      await settle(tester);
      expect(stateOf(tester, id).timeline.sortedCaptions().map((c) => c.text), [
        'Hello there.',
        'This is Stitch.',
      ]);
      await finish(tester);
    });

    testWidgets('style and position apply to every caption', (tester) async {
      final id = await withCaptions(tester);
      await tester.tap(find.text('Captions'));
      await settle(tester);
      await tester.tap(find.text('Style'));
      await settle(tester);
      await tester.tap(find.text('Highlight'));
      await tester.pump();
      await tester.tap(find.text('Top'));
      await settle(tester);
      final track = stateOf(tester, id).timeline.captionTrack;
      expect(track.preset, CaptionPreset.highlightWord);
      expect(track.position, CaptionPosition.top);

      // Each word gets its own image, with that word highlighted.
      await settle(tester);
      final overlays =
          (jsonDecode(env.engine.lastDocument!) as Map)['overlays'] as List;
      expect(overlays, hasLength(5));
      expect((overlays.first as Map)['y'], 0.18);
      expect(env.rasterizer.highlights.nonNulls, isNotEmpty);
      await finish(tester);
    });

    testWidgets('a caption selected on the timeline splits at the playhead', (
      tester,
    ) async {
      final id = await withCaptions(tester);
      final caption = stateOf(tester, id).timeline.sortedCaptions().last;
      final container = ProviderScope.containerOf(
        tester.element(find.byType(EditorScreen)),
      );
      await container.read(playbackControllerProvider.notifier).seek(3700000);
      controllerOf(tester, id).select(CaptionSelected(caption.id));
      await settle(tester);
      expect(find.text('Style'), findsOneWidget);
      await tester.tap(find.text('Split'));
      await settle(tester);
      expect(stateOf(tester, id).timeline.sortedCaptions().map((c) => c.text), [
        'Hello there.',
        'This',
        'is Stitch.',
      ]);
      await finish(tester);
    });
  });
}
