import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/app/providers.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';
import 'package:stitch/features/editor/application/editor_state.dart';
import 'package:stitch/features/projects/application/import_controller.dart';
import 'package:stitch/features/projects/domain/project.dart';
import 'package:stitch/features/timeline/domain/limits.dart';
import 'package:stitch/features/timeline/domain/video_ops.dart';

import '../../helpers/app_scope.dart';

Future<(TestEnv, String)> _projectWithClips(List<int> seconds) async {
  final env = await TestEnv.create();
  final items = [
    for (final (i, s) in seconds.indexed)
      env.library.addVideo('v$i', seconds: s),
  ];
  final id = await env.container
      .read(importControllerProvider.notifier)
      .createProject(
        name: 'Test',
        preset: AspectPreset.portrait9x16,
        items: items,
      );
  return (env, id!);
}

/// Opens the editor and keeps it alive, as the editor screen does.
Future<EditorState> _open(TestEnv env, String id) {
  final sub = env.container.listen(editorControllerProvider(id), (_, _) {});
  addTearDown(sub.close);
  return env.container.read(editorControllerProvider(id).future);
}

void main() {
  test('opens a project and sends its composition to the engine', () async {
    final (env, id) = await _projectWithClips([3, 2]);
    final state = await _open(env, id);
    expect(state.timeline.videoClips, hasLength(2));
    expect(state.project.media, hasLength(2));
    final sent = jsonDecode(env.engine.lastDocument!) as Map<String, dynamic>;
    expect((sent['composition'] as Map)['durationUs'], 5000000);
    expect((sent['canvas'] as Map)['width'], 1080);
    final media = (sent['media'] as Map).values.cast<Map<String, dynamic>>();
    expect(media, hasLength(2));
    // Absolute paths, so the engine can open them.
    for (final m in media) {
      expect(File(m['path'] as String).existsSync(), isTrue);
    }
  });

  test('edits are undoable steps; no-op edits add none', () async {
    final (env, id) = await _projectWithClips([3, 2]);
    await _open(env, id);
    final c = env.container.read(editorControllerProvider(id).notifier);
    EditorState read() =>
        env.container.read(editorControllerProvider(id)).requireValue;

    final clipId = read().timeline.videoClips.first.id;
    c.apply((t) => t.deleteClip('nope'));
    expect(read().canUndo, isFalse);

    c.apply((t) => t.splitClip(clipId, 1000000, newId: 'x'));
    expect(read().timeline.videoClips, hasLength(3));
    c.undo();
    expect(read().timeline.videoClips, hasLength(2));
    c.redo();
    expect(read().timeline.videoClips, hasLength(3));
  });

  test('a gesture is one undo step', () async {
    final (env, id) = await _projectWithClips([4]);
    await _open(env, id);
    final c = env.container.read(editorControllerProvider(id).notifier);
    EditorState read() =>
        env.container.read(editorControllerProvider(id)).requireValue;
    final clipId = read().timeline.videoClips.single.id;

    c.beginGesture();
    for (final delta in [-100000, -500000, -1000000]) {
      c.updateGesture((b) => b.trimClip(clipId, ClipEdge.end, delta));
    }
    c.endGesture();

    expect(read().timeline.clipById(clipId)!.durationUs, 3000000);
    expect(read().history.undoDepth, 1);
    c.undo();
    expect(read().timeline.clipById(clipId)!.durationUs, 4000000);
  });

  test('selection clears when its clip disappears', () async {
    final (env, id) = await _projectWithClips([2, 2]);
    await _open(env, id);
    final c = env.container.read(editorControllerProvider(id).notifier);
    EditorState read() =>
        env.container.read(editorControllerProvider(id)).requireValue;
    final clipId = read().timeline.videoClips.first.id;

    c
      ..select(ClipSelected(clipId))
      ..apply((t) => t.deleteClip(clipId));
    expect(read().selection, const NoSelection());
  });

  test('flush saves; reopening shows the edit', () async {
    final (env, id) = await _projectWithClips([3, 2]);
    await _open(env, id);
    final c = env.container.read(editorControllerProvider(id).notifier);
    final clipId = env.container
        .read(editorControllerProvider(id))
        .requireValue
        .timeline
        .videoClips
        .first
        .id;
    c.apply((t) => t.deleteClip(clipId));
    await c.flush();

    final saved = await env.container.read(projectStoreProvider).load(id);
    expect(saved.timeline.videoClips, hasLength(1));
    expect(saved.updatedAt, TestEnv.now);
  });

  test('autosave runs after the delay without an explicit flush', () async {
    final (env, id) = await _projectWithClips([3]);
    await _open(env, id);
    env.container
        .read(editorControllerProvider(id).notifier)
        .setCanvas(AspectPreset.square);
    await Future<void>.delayed(autosaveDelay * 2);
    final saved = await env.container.read(projectStoreProvider).load(id);
    expect(saved.canvas.preset, AspectPreset.square);
  });

  test('canvas and background changes are undoable', () async {
    final (env, id) = await _projectWithClips([3]);
    await _open(env, id);
    final c = env.container.read(editorControllerProvider(id).notifier);
    Project read() =>
        env.container.read(editorControllerProvider(id)).requireValue.project;

    c
      ..setCanvas(AspectPreset.landscape16x9)
      ..setBackground(const CanvasBackground.blur());
    expect(read().canvas.width, 1920);
    expect(read().background, const CanvasBackground.blur());
    c.undo();
    expect(read().background, const CanvasBackground.solid());
    c.undo();
    expect(read().canvas.preset, AspectPreset.portrait9x16);
  });

  test('rename keeps undo history and does not undo', () async {
    final (env, id) = await _projectWithClips([3]);
    await _open(env, id);
    final c = env.container.read(editorControllerProvider(id).notifier)
      ..setCanvas(AspectPreset.square);
    await c.rename('New name');
    EditorState read() =>
        env.container.read(editorControllerProvider(id)).requireValue;
    expect(read().canUndo, isTrue);
    c.undo();
    expect(read().project.name, 'New name');
    expect(read().project.canvas.preset, AspectPreset.portrait9x16);
  });

  test('adding media imports and appends clips', () async {
    final (env, id) = await _projectWithClips([3]);
    await _open(env, id);
    final extra = env.library.addPhoto('photo');
    final ok = await env.container
        .read(editorControllerProvider(id).notifier)
        .addMedia([extra]);
    expect(ok, isTrue);
    final state = env.container.read(editorControllerProvider(id)).requireValue;
    expect(state.timeline.videoClips, hasLength(2));
    expect(
      state.timeline.videoClips.last.durationUs,
      TimelineLimits.photoDurationUs,
    );
    expect(state.selection, isA<ClipSelected>());
  });

  test('a cancelled new project leaves nothing behind', () async {
    final env = await TestEnv.create();
    final item = env.library.addVideo('v');
    env.library.unavailable.add('v');
    final id = await env.container
        .read(importControllerProvider.notifier)
        .createProject(name: 'X', preset: AspectPreset.square, items: [item]);
    expect(id, isNull);
    expect(env.container.read(importControllerProvider), isA<ImportFailed>());
    expect(await env.container.read(projectStoreProvider).list(), isEmpty);
  });
}
