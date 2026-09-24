// End to end on a device or simulator with the native engine: pick videos
// from Photos, create a project, preview and play it, and export it.
//
// Media comes from the test_media folder on the host (simulators can read
// host files), not from Photos, whose permission resets on every reinstall:
//
//   flutter test integration_test -d <simulator id> \
//     --dart-define=STITCH_TEST_MEDIA=$PWD/test_media
//
// Android emulators cannot read host files, and cannot decode the 10-bit
// HDR sample, so push a few files to a device folder the debug app can read
// (the app's own folders are wiped on every reinstall):
//
//   D=/data/local/tmp/stitch_media
//   adb shell mkdir -p $D
//   adb push test_media/{large_1440p,rotated_portrait,vfr}.mp4 $D
//   adb shell chmod -R a+rX $D
//   flutter test integration_test -d emulator-5554 \
//     --dart-define=STITCH_TEST_MEDIA=$D
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stitch/app/bootstrap.dart';
import 'package:stitch/app/providers.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/engine/editor_engine.dart';
import 'package:stitch/engine/engine_provider.dart';
import 'package:stitch/engine/native_editor_engine.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';
import 'package:stitch/features/editor/application/playback_controller.dart';
import 'package:stitch/features/editor/presentation/editor_screen.dart';
import 'package:stitch/features/editor/presentation/preview.dart';

import 'support/folder_library.dart';

/// Pumps real frames until [finder] matches, or fails after [timeout].
Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
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

Future<void> wait(WidgetTester tester, Duration d) async {
  final end = DateTime.now().add(d);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('import, preview, play, and export', (tester) async {
    const mediaDir = String.fromEnvironment('STITCH_TEST_MEDIA');
    expect(
      mediaDir,
      isNotEmpty,
      reason: 'Pass --dart-define=STITCH_TEST_MEDIA',
    );
    final engine = NativeEditorEngine();
    await bootstrap(
      installErrorHandlers: false,
      overrides: [
        editorEngineProvider.overrideWithValue(engine),
        mediaLibraryProvider.overrideWithValue(
          FolderLibrary(Directory(mediaDir), engine),
        ),
      ],
    );
    await wait(tester, const Duration(seconds: 1));

    // Fresh install shows onboarding; later runs start at home.
    if (find.text('Skip').evaluate().isNotEmpty) {
      await tester.tap(find.text('Skip'));
      await wait(tester, const Duration(milliseconds: 500));
    }

    await waitFor(tester, find.text('New project'));
    await tester.tap(find.text('New project').first);
    // Loading placeholders are MediaThumbnails too; wait for real ones.
    final thumbs = find.byWidgetPredicate(
      (w) => w is MediaThumbnail && w.onTap != null,
    );
    await waitFor(tester, thumbs);
    await wait(tester, const Duration(seconds: 1));

    expect(thumbs.evaluate().length, greaterThanOrEqualTo(2));
    await tester.tap(thumbs.at(0));
    await tester.tap(thumbs.at(1));
    await tester.pump();
    await tester.tap(find.text('Add (2)'));
    await waitFor(tester, find.text('Create'));
    await tester.tap(find.text('Create'));

    await waitFor(
      tester,
      find.byType(VideoClipTile),
      timeout: const Duration(minutes: 1),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(EditorScreen)),
    );
    final editorScreen = tester.widget<EditorScreen>(find.byType(EditorScreen));
    final state = container
        .read(editorControllerProvider(editorScreen.projectId))
        .requireValue;
    final durationUs = state.layout.durationUs;
    expect(state.timeline.videoClips, hasLength(2));
    // Stored durations are the engine's exact ones for each imported copy,
    // not the gallery's whole seconds.
    final store = container.read(projectStoreProvider);
    for (final asset in state.project.media.values) {
      final probed = await engine.probe(
        store.resolve(state.project.id, asset.path),
      );
      expect(asset.durationUs, probed.durationUs);
    }

    // Native preview is showing, and the engine knows the length.
    await waitFor(tester, find.byType(Texture));
    final engineDuration = await _until(
      () => container.read(playbackControllerProvider).durationUs,
      (d) => d > 0,
    );
    expect((engineDuration - durationUs).abs(), lessThan(50000));

    // Play; the playhead moves. Emulators can take ten seconds to start
    // their decoders, so allow time.
    await tester.tap(find.byType(PlayButton).last);
    final end = DateTime.now().add(const Duration(seconds: 30));
    while (container.read(playbackControllerProvider).positionUs < 1200000 &&
        DateTime.now().isBefore(end)) {
      await wait(tester, const Duration(milliseconds: 100));
    }
    final position = container.read(playbackControllerProvider).positionUs;
    expect(position, greaterThan(500000));
    await tester.tap(find.byType(PlayButton).last);
    await wait(tester, const Duration(milliseconds: 300));

    // Signal an external screenshot of the editor, then give it time.
    final tmp = await getTemporaryDirectory();
    File('${tmp.path}/stitch_ready_for_screenshot').writeAsStringSync('1');
    await wait(tester, const Duration(seconds: 4));

    // Export through the native engine and check the file.
    final out = '${tmp.path}/export_test.mp4';
    final events = <ExportEvent>[];
    await engine
        .export(
          ExportSettings(
            outputPath: out,
            width: 540,
            height: 960,
            frameRate: 30,
            bitrate: 4000000,
          ),
        )
        .events
        .forEach(events.add);
    expect(events.last, isA<ExportCompleted>());
    expect(events.whereType<ExportProgress>(), isNotEmpty);
    final info = await engine.probe(out);
    expect((info.durationUs! - durationUs).abs(), lessThan(100000));
    expect((info.width, info.height), (540, 960));
    expect(info.hasVideo, isTrue);
  });
}

/// Polls [read] until [done] accepts its value (up to 10 seconds).
Future<T> _until<T>(T Function() read, bool Function(T) done) async {
  final end = DateTime.now().add(const Duration(seconds: 10));
  while (true) {
    final value = read();
    if (done(value) || DateTime.now().isAfter(end)) return value;
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}
