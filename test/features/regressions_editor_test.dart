// Regression tests for the editing fixes found in the MVP review.
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/app/router.dart';
import 'package:stitch/core/ids/ids.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/engine/engine_provider.dart';
import 'package:stitch/engine/fake_editor_engine.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';
import 'package:stitch/features/editor/application/editor_state.dart';
import 'package:stitch/features/editor/application/playback_controller.dart';
import 'package:stitch/features/editor/presentation/editor_screen.dart';
import 'package:stitch/features/projects/application/import_controller.dart';
import 'package:stitch/features/projects/data/project_store.dart';
import 'package:stitch/features/projects/domain/project.dart';
import 'package:stitch/features/timeline/domain/audio_ops.dart';
import 'package:stitch/features/timeline/domain/caption_ops.dart';
import 'package:stitch/features/timeline/domain/composition.dart';
import 'package:stitch/features/timeline/domain/models.dart';
import 'package:stitch/features/timeline/domain/snapping.dart';
import 'package:stitch/features/timeline/domain/text_ops.dart';
import 'package:stitch/features/timeline/domain/video_ops.dart';

import '../helpers/app_scope.dart';
import '../helpers/pump.dart';
import 'timeline/fixtures.dart';

/// A project with clips of [seconds], opened in its editor.
Future<String> createProjectDirect(TestEnv env, List<int> seconds) async {
  final id = await env.container
      .read(importControllerProvider.notifier)
      .createProject(
        name: 'P',
        preset: AspectPreset.portrait9x16,
        items: [
          for (final (i, sec) in seconds.indexed)
            env.library.addVideo('v$i', seconds: sec),
        ],
      );
  final sub = env.container.listen(editorControllerProvider(id!), (_, _) {});
  addTearDown(sub.close);
  await env.container.read(editorControllerProvider(id).future);
  return id;
}

void main() {
  group('playback', () {
    test('Play at the end starts again from the beginning', () async {
      final engine = FakeEditorEngine(durationUs: s(5));
      final container = ProviderContainer(
        overrides: [editorEngineProvider.overrideWithValue(engine)],
      );
      addTearDown(container.dispose);
      final sub = container.listen(playbackControllerProvider, (_, _) {});
      addTearDown(sub.close);
      await engine.setDocument('{"composition": {"durationUs": 5000000}}');
      await engine.seek(s(5));
      await Future<void>.delayed(Duration.zero);
      expect(container.read(playbackControllerProvider).positionUs, s(5));

      await container.read(playbackControllerProvider.notifier).play();
      await Future<void>.delayed(Duration.zero);
      final state = container.read(playbackControllerProvider);
      expect(state.isPlaying, isTrue);
      expect(state.positionUs, lessThan(s(1)));
      await container.read(playbackControllerProvider.notifier).pause();
      await engine.dispose();
    });

    test('Play takes the playhead back from a scrub left open', () async {
      final engine = FakeEditorEngine(durationUs: s(5));
      final container = ProviderContainer(
        overrides: [editorEngineProvider.overrideWithValue(engine)],
      );
      addTearDown(container.dispose);
      final sub = container.listen(playbackControllerProvider, (_, _) {});
      addTearDown(sub.close);
      await engine.setDocument('{"composition": {"durationUs": 5000000}}');
      container.read(playbackControllerProvider.notifier).beginScrub();
      await container.read(playbackControllerProvider.notifier).play();
      await engine.seek(s(2));
      await Future<void>.delayed(Duration.zero);
      expect(container.read(playbackControllerProvider).positionUs, s(2));
      await container.read(playbackControllerProvider.notifier).pause();
      await engine.dispose();
    });
  });

  group('timeline gestures', () {
    late TestEnv env;

    Future<String> openWithText(WidgetTester tester) async {
      env = await createEnv(tester);
      final id = await createProject(tester, env, seconds: [6, 6]);
      await pumpApp(tester, env, location: AppRoutes.editor(id));
      await settleUntil(tester, find.byType(VideoClipTile));
      ProviderScope.containerOf(tester.element(find.byType(EditorScreen)))
          .read(editorControllerProvider(id).notifier)
          .apply((t) => t.addText(id: 'txt', text: 'Hi', atUs: s(1)));
      await settle(tester);
      return id;
    }

    EditorState stateOf(WidgetTester tester, String id) =>
        ProviderScope.containerOf(tester.element(find.byType(EditorScreen)))
            .read(editorControllerProvider(id))
            .requireValue;

    testWidgets('a dragged item moves with the finger, no faster', (
      tester,
    ) async {
      final id = await openWithText(tester);
      final tile = find.byType(OverlayItemTile).first;
      final gesture = await tester.startGesture(tester.getCenter(tile));
      await tester.pump(const Duration(milliseconds: 600));
      // In steps, as a finger moves; the old code added each step to an
      // already moved start.
      for (var i = 0; i < 8; i++) {
        await gesture.moveBy(const Offset(8, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await settle(tester);
      final moved = stateOf(tester, id).timeline.startOfText('txt') - s(1);
      final expected = (64 / TimelineScale.defaultPixelsPerSecond * 1e6)
          .round();
      // Snapping may pull it a little.
      expect(moved, closeTo(expected, s(0.3)));
      await tester.pump(autosaveDelay * 2);
      await settle(tester);
    });

    testWidgets('a clip held a little long and let go is selected', (
      tester,
    ) async {
      final id = await openWithText(tester);
      final clip = find.byType(VideoClipTile).first;
      final gesture = await tester.startGesture(
        tester.getTopLeft(clip) + const Offset(40, 20),
      );
      await tester.pump(const Duration(milliseconds: 700));
      await gesture.up();
      await settle(tester);
      final selection = stateOf(tester, id).selection;
      expect(selection, isA<ClipSelected>());
      expect(
        (selection as ClipSelected).id,
        stateOf(tester, id).timeline.videoClips.first.id,
      );
      await tester.pump(autosaveDelay * 2);
      await settle(tester);
    });
  });

  group('editing', () {
    test('relinking keeps every clip trim and moves its sound too', () {
      final base = Timeline(
        videoClips: [
          clip('a', 20).copyWith(mediaId: 'm'),
          clip('b', 20, from: 20).copyWith(mediaId: 'm'),
        ],
      ).extractAudio('b', newId: 'x', name: 'Sound');
      final relinked = base.relinkMedia(
        'm',
        toMediaId: 'n',
        mediaDurationUs: s(60),
      );
      expect(relinked.videoClips.map((c) => (c.mediaId, c.sourceInUs)), [
        ('n', 0),
        ('n', s(20)),
      ]);
      expect(relinked.videoClips[1].audioDetached, isTrue);
      expect(relinked.audioItems.single.mediaId, 'n');
    });

    test('captions heard before a split land on the right half', () {
      final heard = track([10]);
      final split = heard.splitClip('a', s(4), newId: 'a2');
      final placed = split.withRecognizedCaptions(heard, [
        (
          id: 'late',
          text: 'Late words',
          startUs: s(6),
          endUs: s(7),
          words: const [],
        ),
        (
          id: 'early',
          text: 'Early words',
          startUs: s(1),
          endUs: s(2),
          words: const [],
        ),
      ]);
      expect(placed.startOfCaption('late'), s(6));
      expect(placed.startOfCaption('early'), s(1));
      final resolved = ResolvedComposition.resolve(placed);
      expect(resolved.captions, hasLength(2));
    });

    test('captions whose footage was deleted meanwhile are flagged', () {
      final heard = track([4, 4]);
      final now = heard.deleteClip('b');
      final placed = now.withRecognizedCaptions(heard, [
        (id: 'gone', text: 'Gone', startUs: s(5), endUs: s(6), words: const []),
      ]);
      expect(placed.captionById('gone')!.needsReview, isTrue);
    });

    test('extracted sound stays in sync after the first clip is trimmed', () {
      final base = track([10]).extractAudio('a', newId: 'x', name: 'Sound');
      final trimmed = base.trimClip('a', ClipEdge.start, s(2));
      final audio = ResolvedComposition.resolve(trimmed).audio.single;
      expect(audio.startUs, 0);
      expect(audio.sourceInUs, s(2));
    });

    test('an edit arriving during a drag waits for the drag', () async {
      final env = await TestEnv.create();
      final id = await createProjectDirect(env, [4, 4]);
      final editor = env.container.read(editorControllerProvider(id).notifier)
        ..beginGesture()
        ..updateGesture(
          (t) => t.trimClip(t.videoClips.first.id, ClipEdge.end, -s(1)),
        )
        // Like an import finishing mid-drag.
        ..apply((t) => t.addText(id: 'late', text: 'Late', atUs: 0))
        ..updateGesture(
          (t) => t.trimClip(t.videoClips.first.id, ClipEdge.end, -s(2)),
        )
        ..endGesture();
      final timeline = env.container
          .read(editorControllerProvider(id))
          .requireValue
          .timeline;
      expect(timeline.textItems.single.id, 'late');
      expect(timeline.startOfClip(timeline.videoClips.last.id), s(2));
      // The drag and the late edit are separate steps.
      editor.undo();
      expect(
        env.container
            .read(editorControllerProvider(id))
            .requireValue
            .timeline
            .textItems,
        isEmpty,
      );
    });
  });

  group('project store', () {
    late Directory root;
    late ProjectStore store;

    setUp(() {
      root = Directory.systemTemp.createTempSync('store_fix');
      store = ProjectStore(root: root, ids: SequentialIdGenerator('p'));
    });
    tearDown(() => root.deleteSync(recursive: true));

    test('many saves at once leave a whole, newest document', () async {
      final project = await store.create(
        name: 'P',
        canvas: ProjectCanvas.forPreset(AspectPreset.portrait9x16),
      );
      await Future.wait([
        for (var i = 0; i < 20; i++)
          store.save(project.copyWith(name: 'Name $i')),
      ]);
      expect((await store.load(project.id)).name, 'Name 19');
      final leftovers = store
          .projectDir(project.id)
          .listSync()
          .where((f) => f.path.endsWith('.tmp'));
      expect(leftovers, isEmpty);
    });

    test('a document never saves over a project it was copied from', () async {
      final original = await store.create(
        name: 'Original',
        canvas: ProjectCanvas.forPreset(AspectPreset.portrait9x16),
      );
      // A copied folder whose document still names the original.
      final copyDir = Directory('${root.path}/projects/stray')..createSync();
      File('${store.projectDir(original.id).path}/project.json')
          .copySync('${copyDir.path}/project.json');
      final loaded = await store.load('stray');
      expect(loaded.id, 'stray');
    });

    test(
      'an interrupted duplicate leaves nothing that looks like a project',
      () async {
        final original = await store.create(
          name: 'Original',
          canvas: ProjectCanvas.forPreset(AspectPreset.portrait9x16),
        );
        Directory('${root.path}/projects/p9.staging').createSync();
        File('${root.path}/projects/index.json').deleteSync();
        final list = await store.list();
        expect(list.map((p) => p.id), [original.id]);
        expect(
          Directory('${root.path}/projects/p9.staging').existsSync(),
          isFalse,
        );
      },
    );
  });
}
