// End to end export through the screens, on a device or simulator: the
// export sheet, the real engine, and saving to the photo library.
//
// Uses test_media/speech.mp4 from STITCH_TEST_MEDIA (see
// editor_flow_test.dart). Grant access first, so no system prompt waits:
//
//   xcrun simctl privacy <simulator> grant photos-add xyz.gloryolaifa.stitch
//   adb shell pm grant xyz.gloryolaifa.stitch \
//     android.permission.POST_NOTIFICATIONS
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
import 'package:stitch/features/export/application/export_controller.dart';
import 'package:stitch/features/export/presentation/export_screen.dart';
import 'package:stitch/features/media/domain/library_item.dart';
import 'package:stitch/features/projects/application/import_controller.dart';
import 'package:stitch/features/projects/domain/project.dart';

import 'support/folder_library.dart';

Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 60),
}) async {
  final end = DateTime.now().add(timeout);
  while (finder.evaluate().isEmpty) {
    if (DateTime.now().isAfter(end)) {
      final texts = find
          .byType(Text)
          .evaluate()
          .map((e) => (e.widget as Text).data)
          .whereType<String>()
          .toSet();
      fail('Timed out waiting for $finder. On screen: $texts');
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('exports through the screens and saves to the gallery', (
    tester,
  ) async {
    const mediaDir = String.fromEnvironment('STITCH_TEST_MEDIA');
    expect(
      mediaDir,
      isNotEmpty,
      reason: 'Pass --dart-define=STITCH_TEST_MEDIA',
    );
    final engine = NativeEditorEngine();
    final library = FolderLibrary(Directory(mediaDir), engine);
    await bootstrap(
      installErrorHandlers: false,
      overrides: [
        editorEngineProvider.overrideWithValue(engine),
        mediaLibraryProvider.overrideWithValue(library),
      ],
    );
    await waitFor(tester, find.byType(StitchApp));
    await tester.pump(const Duration(seconds: 1));
    if (find.text('Skip').evaluate().isNotEmpty) {
      await tester.tap(find.text('Skip'));
      await tester.pump(const Duration(milliseconds: 500));
    }
    final container = ProviderScope.containerOf(
      tester.element(find.byType(StitchApp)),
    );
    final items = await library.items(LibraryFilter.videos, page: 0);
    final id = await container
        .read(importControllerProvider.notifier)
        .createProject(
          name: 'Export test',
          preset: AspectPreset.portrait9x16,
          items: [items.firstWhere((i) => i.id == 'speech.mp4')],
        );
    container.read(routerProvider).go(AppRoutes.editor(id!));
    await waitFor(tester, find.byType(VideoClipTile));

    await tester.tap(find.widgetWithText(PrimaryButton, 'Export'));
    await waitFor(tester, find.text('Resolution'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('720p'));
    await tester.pump();
    await tester.tap(find.widgetWithText(PrimaryButton, 'Export').last);
    await waitFor(tester, find.byType(ExportScreen));

    await waitFor(
      tester,
      find.textContaining('Saved to'),
      timeout: const Duration(minutes: 2),
    );
    final done = container.read(exportControllerProvider(id)) as ExportDone;
    final info = await engine.probe(done.path);
    expect((info.width, info.height), (720, 1280));
    expect(info.hasAudio, isTrue);
    expect(info.durationUs! / 1e6, closeTo(3.97, 0.2));

    // The done screen plays the export in the preview.
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(Texture), findsOneWidget);
    await tester.tap(find.text('Back to editing'));
    await waitFor(tester, find.byType(VideoClipTile));
  });
}
