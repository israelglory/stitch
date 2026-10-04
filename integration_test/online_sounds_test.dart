// End to end against the real online sound library on the Internet
// Archive, on a device or simulator: open the Online tab, try a track from
// its preview, download a sound effect (checked against the catalog's
// SHA-256), and add it to a project. Needs a network connection.
//
//   flutter test integration_test/online_sounds_test.dart -d <device> \
//     --dart-define=STITCH_TEST_MEDIA=<folder with speech.mp4>
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
import 'package:stitch/features/audio/application/audio_providers.dart';
import 'package:stitch/features/audio/application/sound_library.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';
import 'package:stitch/features/media/domain/library_item.dart';
import 'package:stitch/features/projects/application/import_controller.dart';
import 'package:stitch/features/projects/domain/project.dart';
import 'package:stitch/features/timeline/domain/models.dart' as m;

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

  testWidgets('tries, downloads, and adds sounds from the online library', (
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
    // A clean start: no sounds from an earlier run.
    await container.read(soundLibraryStoreProvider).deleteAll();
    final items = await library.items(LibraryFilter.videos, page: 0);
    final id = await container
        .read(importControllerProvider.notifier)
        .createProject(
          name: 'Online sounds',
          preset: AspectPreset.portrait9x16,
          items: [items.firstWhere((i) => i.id == 'speech.mp4')],
        );
    container.read(routerProvider).go(AppRoutes.editor(id!));
    await waitFor(tester, find.byType(VideoClipTile));

    // Music: the catalog lists 60 tracks; a preview plays without
    // downloading the track.
    await tester.tap(find.text('Audio'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Music'));
    await waitFor(tester, find.text('Online'));
    await tester.tap(find.text('Online'));
    await waitFor(tester, find.text('Party time'));
    final catalog = container.read(soundLibraryProvider).catalog!;
    expect(catalog.sounds.where((s) => s.kind.name == 'music'), hasLength(60));
    await tester.tap(find.bySemanticsLabel('Play Party time'));
    await waitFor(tester, find.byType(MiniPlayer));
    final previewing = DateTime.now().add(const Duration(seconds: 20));
    var played = false;
    while (!played && DateTime.now().isBefore(previewing)) {
      await tester.pump(const Duration(milliseconds: 200));
      final state = await container
          .read(audioDeviceProvider)
          .previewState
          .first;
      played = state.isPlaying && state.positionUs > 0;
    }
    expect(played, isTrue, reason: 'the preview plays');
    expect(
      container
          .read(soundLibraryStoreProvider)
          .isDownloaded(catalog.sounds.firstWhere((s) => s.id == 'party_time')),
      isFalse,
    );
    await container.read(audioDeviceProvider).stopPreview();
    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pump(const Duration(milliseconds: 500));

    // An effect: download it from the Archive, then add it. Back from the
    // library, the editor still shows the audio tools.
    await waitFor(tester, find.text('Sound effects'));
    await tester.tap(find.text('Sound effects'));
    await waitFor(tester, find.text('Online'));
    await tester.tap(find.text('Online'));
    await waitFor(tester, find.text('Clicks and UI'));
    await tester.enterText(find.byType(EditableText), 'soft click');
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Download Soft click'));
    final row = find.ancestor(
      of: find.text('Soft click'),
      matching: find.byType(ListRow),
    );
    await waitFor(
      tester,
      find.descendant(of: row, matching: find.text('Add')),
      timeout: const Duration(minutes: 2),
    );
    final click = catalog.sounds.firstWhere((s) => s.id == 'soft_click');
    final store = container.read(soundLibraryStoreProvider);
    expect(store.isDownloaded(click), isTrue);
    expect(store.file(click).lengthSync(), click.bytes);

    await tester.tap(find.descendant(of: row, matching: find.text('Add')));
    await waitFor(tester, find.byType(AudioItemTile));
    final state = container.read(editorControllerProvider(id)).requireValue;
    final item = state.timeline.audioItems.single;
    expect(item.name, 'Soft click');
    expect(item.kind, m.AudioKind.soundEffect);
    final asset = state.project.media[item.mediaId]!;
    expect(asset.kind, m.MediaKind.audio);
    final probed = await engine.probe(
      container.read(projectStoreProvider).resolve(id, asset.path),
    );
    expect(probed.hasAudio, isTrue);
  });
}
