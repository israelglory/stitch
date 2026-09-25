// End to end captions on a device or simulator: the real engine renders
// the sound, whisper.cpp (built by the hook) recognizes it with the tiny
// model downloaded for real, and the captions reach the engine.
//
// Uses test_media/speech.mp4 from the folder given as STITCH_TEST_MEDIA
// (see editor_flow_test.dart; on Android, push speech.mp4 there too).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:stitch/app/app.dart';
import 'package:stitch/app/bootstrap.dart';
import 'package:stitch/app/providers.dart';
import 'package:stitch/app/router.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/engine/engine_provider.dart';
import 'package:stitch/engine/native_editor_engine.dart';
import 'package:stitch/features/captions/application/caption_providers.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';
import 'package:stitch/features/editor/presentation/editor_screen.dart';
import 'package:stitch/features/media/domain/library_item.dart';
import 'package:stitch/features/projects/application/import_controller.dart';
import 'package:stitch/features/projects/domain/project.dart';
import 'package:stitch/features/timeline/domain/caption_ops.dart';

import 'support/folder_library.dart';

Future<void> waitFor(
  WidgetTester tester,
  bool Function() done, {
  required String what,
  Duration timeout = const Duration(seconds: 30),
}) async {
  final end = DateTime.now().add(timeout);
  while (!done()) {
    if (DateTime.now().isAfter(end)) fail('Timed out waiting for $what');
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Records the documents sent to the engine.
class _RecordingEngine extends NativeEditorEngine {
  String? lastDocument;

  @override
  Future<void> setDocument(String documentJson) {
    lastDocument = documentJson;
    return super.setDocument(documentJson);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('generates captions from speech, on the device', (tester) async {
    const mediaDir = String.fromEnvironment('STITCH_TEST_MEDIA');
    expect(
      mediaDir,
      isNotEmpty,
      reason: 'Pass --dart-define=STITCH_TEST_MEDIA',
    );
    final engine = _RecordingEngine();
    final library = FolderLibrary(Directory(mediaDir), engine);
    await bootstrap(
      installErrorHandlers: false,
      overrides: [
        editorEngineProvider.overrideWithValue(engine),
        mediaLibraryProvider.overrideWithValue(library),
      ],
    );
    await waitFor(
      tester,
      () => find.byType(StitchApp).evaluate().isNotEmpty,
      what: 'the app',
    );
    await tester.pump(const Duration(seconds: 1));
    // A fresh install shows onboarding first.
    if (find.text('Skip').evaluate().isNotEmpty) {
      await tester.tap(find.text('Skip'));
      await tester.pump(const Duration(milliseconds: 500));
    }
    final container = ProviderScope.containerOf(
      tester.element(find.byType(StitchApp)),
    );
    expect(container.read(speechRecognizerProvider).isAvailable, isTrue);

    // A project with the speech clip, made through the real import.
    final items = await library.items(LibraryFilter.videos, page: 0);
    final speech = items.firstWhere((i) => i.id == 'speech.mp4');
    final id = await container
        .read(importControllerProvider.notifier)
        .createProject(
          name: 'Speech',
          preset: AspectPreset.portrait9x16,
          items: [speech],
        );
    container.read(routerProvider).go(AppRoutes.editor(id!));
    await waitFor(
      tester,
      () =>
          find.byType(EditorScreen).evaluate().isNotEmpty &&
          find.text('Captions').evaluate().isNotEmpty,
      what: 'the editor',
    );

    await tester.tap(find.text('Captions'));
    final generate = find.widgetWithText(PrimaryButton, 'Generate captions');
    await waitFor(
      tester,
      () => generate.evaluate().isNotEmpty,
      what: 'the captions sheet',
    );
    // Let the sheet finish sliding in.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(generate);

    // Downloads the model (44 MB), renders the sound, recognizes it.
    final editor = find.byType(EditorScreen);
    List<String> captions() => container
        .read(editorControllerProvider(id))
        .requireValue
        .timeline
        .sortedCaptions()
        .map((c) => c.text)
        .toList();
    await waitFor(
      tester,
      () => editor.evaluate().isNotEmpty && captions().isNotEmpty,
      what: 'captions',
      timeout: const Duration(minutes: 5),
    );
    final text = captions().join(' ').toLowerCase();
    debugPrint('Captions: ${captions()}');
    expect(text, contains('captions on your phone'));
    expect(text, contains('device'));

    // The engine gets them as images.
    await waitFor(
      tester,
      () =>
          ((jsonDecode(engine.lastDocument ?? '{}') as Map)['overlays']
                      as List? ??
                  const [])
              .isNotEmpty,
      what: 'caption overlays',
    );
    final overlays =
        (jsonDecode(engine.lastDocument!) as Map)['overlays'] as List;
    for (final o in overlays.cast<Map<String, dynamic>>()) {
      for (final image in (o['images'] as List).cast<String>()) {
        expect(File(image).existsSync(), isTrue);
      }
    }
    await tester.pump(const Duration(seconds: 2));
  });
}
