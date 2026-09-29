import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/app/providers.dart';
import 'package:stitch/app/router.dart';
import 'package:stitch/core/errors/failure.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/engine/editor_engine.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';
import 'package:stitch/features/editor/application/preview_copies.dart';
import 'package:stitch/features/projects/application/import_controller.dart';
import 'package:stitch/features/projects/domain/project.dart';
import 'package:stitch/features/timeline/domain/models.dart';

import '../../helpers/app_scope.dart';
import '../../helpers/pump.dart' as pump;

/// 4K at 60 fps, which the (fake) phone decodes only in software.
const _tooBigForHardware = MediaInfo(
  durationUs: 3000000,
  width: 2160,
  height: 3840,
  frameRate: 60,
  hasVideo: true,
  hasAudio: true,
  hardwareDecodable: false,
);

void main() {
  late TestEnv env;

  setUp(() async {
    env = await TestEnv.create();
    env.engine.probeHandler = (_) => _tooBigForHardware;
  });

  Future<String> createProject() async {
    final id = await env.container
        .read(importControllerProvider.notifier)
        .createProject(
          name: 'Big',
          preset: AspectPreset.portrait9x16,
          items: [env.library.addVideo('big', seconds: 3)],
        );
    return id!;
  }

  /// Opens the editor and its preview copies, as the editor screen does.
  Future<void> open(String id) async {
    final editor = env.container.listen(
      editorControllerProvider(id),
      (_, _) {},
    );
    addTearDown(editor.close);
    await env.container.read(editorControllerProvider(id).future);
    final copies = env.container.listen(previewCopiesProvider(id), (_, _) {});
    addTearDown(copies.close);
  }

  MediaAsset asset(String id) => env.container
      .read(editorControllerProvider(id))
      .requireValue
      .project
      .media
      .values
      .single;

  Future<void> until(bool Function() done) async {
    for (var i = 0; i < 200 && !done(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(done(), isTrue);
  }

  test('a copy the import skipped is made once the project opens', () async {
    final id = await createProject();
    expect(env.engine.proxies, isEmpty);
    env.engine.writeProxies = true;
    await open(id);

    await until(() => asset(id).proxyPath != null);
    expect(asset(id).proxyPath, asset(id).previewCopyPath);
    expect(env.engine.proxies, hasLength(1));
    expect(env.container.read(previewCopiesProvider(id)), 0);

    // Not an edit: nothing to undo, and undoing an edit keeps the copy.
    final controller = env.container.read(
      editorControllerProvider(id).notifier,
    );
    expect(
      env.container.read(editorControllerProvider(id)).requireValue.canUndo,
      isFalse,
    );
    controller
      ..apply(
        (t) => t.copyWith(
          videoClips: [for (final c in t.videoClips) c.copyWith(volume: 0.5)],
        ),
      )
      ..undo();
    expect(asset(id).proxyPath, isNotNull);

    // Saved with the project.
    await controller.flush();
    final saved = await env.container.read(projectStoreProvider).load(id);
    expect(saved.media.values.single.proxyPath, isNotNull);
  });

  test(
    'a clip the phone cannot play is recorded, and can be retried',
    () async {
      final id = await createProject();
      env.engine.proxyFailure = const EngineFailure('export_failed');
      await open(id);

      await until(() => asset(id).previewCopyFailed);
      expect(asset(id).proxyPath, isNull);
      // Not tried again on its own.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(env.engine.proxies, hasLength(1));

      env.engine
        ..proxyFailure = null
        ..writeProxies = true;
      env.container.read(previewCopiesProvider(id).notifier).retry();
      await until(() => asset(id).proxyPath != null);
      expect(asset(id).previewCopyFailed, isFalse);
    },
  );

  test('a copy finished after the editor closed is picked up', () async {
    final id = await createProject();
    final store = env.container.read(projectStoreProvider);
    final project = await store.load(id);
    final media = project.media.values.single;
    File(store.resolve(id, media.previewCopyPath))
      ..createSync(recursive: true)
      ..writeAsBytesSync(const [0]);
    await open(id);

    await until(() => asset(id).proxyPath != null);
    expect(env.engine.proxies, isEmpty);
  });

  test('clips the hardware plays are not waited on here', () async {
    env.engine.probeHandler = (_) => const MediaInfo(
      durationUs: 3000000,
      width: 720,
      height: 1280,
      hasVideo: true,
      hasAudio: true,
    );
    final id = await createProject();
    await open(id);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(env.engine.proxies, isEmpty);
    expect(asset(id).wantsPreviewCopy, isFalse);
    expect(asset(id).kind, MediaKind.video);
  });

  testWidgets('the editor says which clips this phone cannot play', (
    tester,
  ) async {
    final env = await pump.createEnv(tester);
    env.engine.probeHandler = (_) => _tooBigForHardware;
    env.engine.proxyFailure = const EngineFailure('export_failed');
    final id = await pump.createProject(tester, env, seconds: [3]);
    await pump.pumpApp(tester, env, location: AppRoutes.editor(id));
    await pump.settleUntil(tester, find.byType(VideoClipTile));
    await pump.settleUntil(
      tester,
      find.textContaining("This phone can't play one of the clips"),
    );
    expect(find.text('Retry'), findsOneWidget);
    await tester.pump(autosaveDelay * 2);
    await pump.settle(tester);
  });
}
