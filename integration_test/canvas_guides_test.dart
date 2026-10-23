// End to end with the native engine: snapping a clip and text on the
// preview, and adding a clip with the pinned button at the cut nearest the
// playhead. Media as for editor_flow_test.dart:
//
//   flutter test integration_test/canvas_guides_test.dart -d <device> \
//     --dart-define=STITCH_TEST_MEDIA=<folder with two or more videos>
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
import 'package:stitch/features/ads/ads.dart';
import 'package:stitch/features/analytics/analytics.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';
import 'package:stitch/features/editor/application/editor_state.dart';
import 'package:stitch/features/editor/application/playback_controller.dart';
import 'package:stitch/features/media/domain/library_item.dart';
import 'package:stitch/features/projects/application/import_controller.dart';
import 'package:stitch/features/projects/domain/project.dart';
import 'package:stitch/features/text/presentation/text_overlay_layer.dart';

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

Future<void> wait(WidgetTester tester, Duration d) async {
  final end = DateTime.now().add(d);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// A one-finger drag on the preview from its centre, in steps.
Future<TestGesture> dragFromCentre(
  WidgetTester tester,
  Offset by, {
  int steps = 6,
}) async {
  final layer = tester.getRect(find.byType(TextOverlayLayer));
  final gesture = await tester.startGesture(layer.center);
  for (var i = 0; i < steps; i++) {
    await gesture.moveBy(by / steps.toDouble());
    await tester.pump(const Duration(milliseconds: 16));
  }
  return gesture;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('snap guides and adding at the playhead', (tester) async {
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
        analyticsProvider.overrideWithValue(const NoAnalytics()),
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
    final videos = await library.items(LibraryFilter.videos, page: 0);
    expect(videos.length, greaterThanOrEqualTo(2));
    final id = await container
        .read(importControllerProvider.notifier)
        .createProject(
          name: 'Guides',
          preset: AspectPreset.portrait9x16,
          items: videos.take(2).toList(),
        );
    container.read(routerProvider).go(AppRoutes.editor(id!));
    await waitFor(tester, find.byType(VideoClipTile));
    await wait(tester, const Duration(seconds: 1));
    // A project opens at its start.
    expect(container.read(playbackControllerProvider).positionUs, 0);
    EditorState state() =>
        container.read(editorControllerProvider(id)).requireValue;

    // A clip moved off and back near the middle sits exactly centred.
    // Just after the playhead: a long clip's middle is off screen.
    await tester.tapAt(
      Offset(
        tester.getCenter(find.byType(Playhead)).dx + 20,
        tester.getCenter(find.byType(VideoClipTile).first).dy,
      ),
    );
    await wait(tester, const Duration(milliseconds: 300));
    final layer = tester.getRect(find.byType(TextOverlayLayer));
    var gesture = await dragFromCentre(tester, const Offset(60, 0));
    final moved = state().timeline.videoClips.first.framing.offsetX;
    expect(moved, greaterThan(0));
    await gesture.moveBy(Offset(-moved * layer.width + 3, 0));
    await tester.pump();
    await gesture.up();
    await wait(tester, const Duration(milliseconds: 500));
    expect(state().timeline.videoClips.first.framing.offsetX, 0);

    // Text dragged down and back near the middle sits exactly there.
    await tester.tap(find.bySemanticsLabel('Back'));
    await wait(tester, const Duration(milliseconds: 300));
    await tester.tap(find.text('Text'));
    await waitFor(tester, find.byType(EditableText));
    await tester.enterText(find.byType(EditableText), 'Centred');
    await wait(tester, const Duration(milliseconds: 300));
    await tester.tap(find.bySemanticsLabel('Done'));
    // The preview grows back as the keyboard goes; slow on emulators.
    // Wait until it has kept its full size for a second.
    final settled = DateTime.now().add(const Duration(seconds: 20));
    for (var still = 0; still < 10;) {
      expect(DateTime.now().isBefore(settled), isTrue, reason: 'keyboard');
      await tester.pump(const Duration(milliseconds: 100));
      still = tester.getRect(find.byType(TextOverlayLayer)) == layer
          ? still + 1
          : 0;
    }
    await wait(tester, const Duration(milliseconds: 300));
    gesture = await dragFromCentre(tester, const Offset(0, 60));
    final y = state().timeline.textItems.single.transform.y;
    expect(y, greaterThan(0.55));
    await gesture.moveBy(Offset(0, (0.5 - y) * layer.height - 3));
    await tester.pump();
    await gesture.up();
    await wait(tester, const Duration(milliseconds: 500));
    expect(state().timeline.textItems.single.transform.y, 0.5);

    // Three quarters into the first clip: the new clip goes after it.
    final before = [for (final c in state().timeline.videoClips) c.id];
    final first = state().layout.spans.first;
    final playback = container.read(playbackControllerProvider.notifier);
    await playback.seek(first.startUs + first.clip.durationUs * 3 ~/ 4);
    await wait(tester, const Duration(milliseconds: 500));
    await tester.tap(find.bySemanticsLabel('Add clip'));
    final thumbs = find.byWidgetPredicate(
      (w) => w is MediaThumbnail && w.onTap != null,
    );
    await waitFor(tester, thumbs);
    await wait(tester, const Duration(seconds: 1));
    await tester.tap(thumbs.first);
    await tester.pump();
    await tester.tap(find.text('Add (1)'));
    final end = DateTime.now().add(const Duration(minutes: 1));
    while (state().timeline.videoClips.length < 3) {
      expect(DateTime.now().isBefore(end), isTrue, reason: 'clip added');
      await tester.pump(const Duration(milliseconds: 100));
    }
    await wait(tester, const Duration(seconds: 1));
    final clips = state().timeline.videoClips;
    expect([clips[0].id, clips[2].id], before);
    expect(state().selection, ClipSelected(clips[1].id));
    expect(
      container.read(playbackControllerProvider).positionUs,
      state().layout.span(clips[1].id)!.startUs,
    );

    // It plays from there.
    await playback.toggle();
    await wait(tester, const Duration(seconds: 2));
    await playback.toggle();
    expect(
      container.read(playbackControllerProvider).positionUs,
      greaterThan(state().layout.span(clips[1].id)!.startUs),
    );
    await wait(tester, const Duration(seconds: 1));
  });
}
