// End to end with the native engine: an overlay added through the picker,
// moved on the preview, played over a cut; a freeze frame; and an export
// of both. Media as for editor_flow_test.dart:
//
//   flutter test integration_test/overlay_freeze_test.dart -d <device> \
//     --dart-define=STITCH_TEST_MEDIA=<folder with two or more videos>
//
// On Android, grant POST_NOTIFICATIONS first (see export_test.dart).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stitch/app/app.dart';
import 'package:stitch/app/bootstrap.dart';
import 'package:stitch/app/providers.dart';
import 'package:stitch/app/router.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/engine/editor_engine.dart';
import 'package:stitch/engine/engine_provider.dart';
import 'package:stitch/engine/native_editor_engine.dart';
import 'package:stitch/features/ads/ads.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';
import 'package:stitch/features/editor/application/editor_state.dart';
import 'package:stitch/features/editor/application/playback_controller.dart';
import 'package:stitch/features/media/domain/library_item.dart';
import 'package:stitch/features/projects/application/import_controller.dart';
import 'package:stitch/features/projects/domain/project.dart';
import 'package:stitch/features/text/presentation/text_overlay_layer.dart';
import 'package:stitch/features/timeline/domain/limits.dart';

import 'support/folder_library.dart';

Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 60),
}) async {
  final end = DateTime.now().add(timeout);
  while (finder.evaluate().isEmpty) {
    if (DateTime.now().isAfter(end)) fail('Timed out waiting for $finder');
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> waitUntil(
  WidgetTester tester,
  bool Function() done, {
  required String reason,
  Duration timeout = const Duration(seconds: 60),
}) async {
  final end = DateTime.now().add(timeout);
  while (!done()) {
    if (DateTime.now().isAfter(end)) {
      final texts = find
          .byType(Text)
          .evaluate()
          .map((e) => (e.widget as Text).data)
          .whereType<String>()
          .toSet();
      fail('Timed out: $reason. On screen: $texts');
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> wait(WidgetTester tester, Duration d) async {
  final end = DateTime.now().add(d);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('overlay and freeze frame, previewed and exported', (
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
        adsProvider.overrideWithValue(const NoAds()),
        editorEngineProvider.overrideWithValue(engine),
        mediaLibraryProvider.overrideWithValue(library),
      ],
    );
    await waitFor(tester, find.byType(StitchApp));
    await wait(tester, const Duration(seconds: 1));
    if (find.text('Skip').evaluate().isNotEmpty) {
      await tester.tap(find.text('Skip'));
      await wait(tester, const Duration(milliseconds: 500));
    }
    final container = ProviderScope.containerOf(
      tester.element(find.byType(StitchApp)),
    );
    // Files every emulator decodes (not the 1440p or HDR samples).
    final videos = [
      for (final v in await library.items(LibraryFilter.videos, page: 0))
        if (v.id == 'speech.mp4' || v.id == 'vfr.mp4') v,
    ];
    expect(videos, hasLength(2));
    final id = await container
        .read(importControllerProvider.notifier)
        .createProject(
          name: 'Overlay and freeze',
          preset: AspectPreset.portrait9x16,
          items: videos.take(2).toList(),
        );
    container.read(routerProvider).go(AppRoutes.editor(id!));
    await waitFor(tester, find.byType(VideoClipTile));
    await wait(tester, const Duration(seconds: 1));
    EditorState state() =>
        container.read(editorControllerProvider(id)).requireValue;
    final controller = container.read(editorControllerProvider(id).notifier);
    final playback = container.read(playbackControllerProvider.notifier);
    Future<void> shown() => waitUntil(
      tester,
      () =>
          container.read(playbackControllerProvider).durationUs ==
          state().layout.durationUs,
      reason: 'the engine shows the edit',
    );

    // The engine has the project (a seek before that clamps to 0).
    await shown();

    // An overlay through the picker, at 0.5 s.
    await playback.seek(500000);
    await wait(tester, const Duration(milliseconds: 300));
    await tester.tap(find.text('Overlay'));
    final thumbs = find.byWidgetPredicate(
      (w) => w is MediaThumbnail && w.onTap != null,
    );
    await waitFor(tester, thumbs);
    await wait(tester, const Duration(seconds: 1));
    await tester.tap(thumbs.last);
    await tester.pump();
    await tester.tap(find.text('Add (1)'));
    await waitUntil(
      tester,
      () => state().timeline.overlayClips.isNotEmpty,
      reason: 'the overlay is added',
    );
    await wait(tester, const Duration(seconds: 1));
    final overlay = state().timeline.overlayClips.single;
    expect(state().selection, OverlaySelected(overlay.id));
    expect(state().layout.startOf(overlay.anchor), 500000);

    // Moved right on the preview.
    final layer = tester.getRect(find.byType(TextOverlayLayer));
    final gesture = await tester.startGesture(layer.center);
    for (var i = 0; i < 8; i++) {
      await gesture.moveBy(const Offset(10, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await wait(tester, const Duration(seconds: 1));
    expect(
      state().timeline.overlayById(overlay.id)!.framing.offsetX,
      greaterThan(0),
    );

    // It plays: the engine decodes it with the clips, across the cut.
    final firstEnd = state().layout.spans.first.endUs;
    await playback.seek(firstEnd - 700000);
    await wait(tester, const Duration(milliseconds: 500));
    await playback.play();
    // Emulators decode in software: slow, but it gets there.
    await waitUntil(
      tester,
      () => container.read(playbackControllerProvider).positionUs > firstEnd,
      reason: 'it plays across the cut',
      timeout: const Duration(seconds: 30),
    );
    await playback.pause();
    await wait(tester, const Duration(milliseconds: 300));
    expect(
      container.read(playbackControllerProvider).positionUs,
      greaterThan(firstEnd),
    );

    // A freeze frame in the middle of the first clip.
    controller.select(const NoSelection());
    await wait(tester, const Duration(milliseconds: 300));
    final before = state().layout.durationUs;
    final clips = state().timeline.videoClips.length;
    final freezeAt = state().layout.spans.first.endUs ~/ 2;
    await playback.seek(freezeAt);
    await waitUntil(
      tester,
      () => container.read(playbackControllerProvider).positionUs == freezeAt,
      reason: 'the playhead is in the first clip',
    );
    await wait(tester, const Duration(milliseconds: 500));
    expect(container.read(playbackControllerProvider).positionUs, freezeAt);
    controller.select(ClipSelected(state().timeline.videoClips.first.id));
    await wait(tester, const Duration(milliseconds: 300));
    await tester.scrollUntilVisible(
      find.text('Freeze'),
      100,
      scrollable: find.descendant(
        of: find.byType(ContextToolbar),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.text('Freeze'));
    await waitUntil(
      tester,
      () => state().timeline.videoClips.length == clips + 2,
      reason: 'the clip is split around a still',
    );
    final still = state().timeline.videoClips[1];
    expect(still.isPhoto, isTrue);
    // From the moment the still is there, the playhead stays on it, even
    // while the engine swaps in the new document.
    final settled = DateTime.now().add(const Duration(seconds: 2));
    while (DateTime.now().isBefore(settled)) {
      final at = container.read(playbackControllerProvider).positionUs;
      expect(at, greaterThanOrEqualTo(freezeAt - 100000), reason: 'never back');
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(state().layout.durationUs, before + TimelineLimits.photoDurationUs);
    await shown();
    expect(
      container.read(playbackControllerProvider).positionUs,
      state().layout.span(still.id)!.startUs,
    );

    // Exported: the longer video, with the overlay drawn.
    await controller.prepareForExport();
    await shown();
    final out = File(
      '${(await getTemporaryDirectory()).path}/overlay_freeze.mp4',
    );
    if (out.existsSync()) out.deleteSync();
    final job = engine.export(
      ExportSettings(
        outputPath: out.path,
        width: 360,
        height: 640,
        frameRate: 30,
        bitrate: 2000000,
        progressTitle: 'Exporting',
      ),
    );
    String? exported;
    final done = job.events.last.then((e) {
      if (e is ExportCompleted) exported = e.outputPath;
    });
    await waitUntil(
      tester,
      () => exported != null,
      reason: 'the export ends',
      timeout: const Duration(minutes: 5),
    );
    await done;
    final probed = await engine.probe(exported!);
    expect(
      (probed.durationUs! - state().layout.durationUs).abs(),
      lessThan(200000),
    );
    await wait(tester, const Duration(seconds: 1));
  });
}
