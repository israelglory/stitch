// Freeze through the real editor with the fake engine: the frame under the
// playhead held as a still between the clip's two parts.
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/app/providers.dart';
import 'package:stitch/app/router.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';
import 'package:stitch/features/editor/application/editor_state.dart';
import 'package:stitch/features/editor/application/playback_controller.dart';
import 'package:stitch/features/timeline/domain/limits.dart';

import '../helpers/app_scope.dart';
import '../helpers/fake_media_library.dart';
import '../helpers/pump.dart';

void main() {
  late TestEnv env;

  EditorState stateOf(String id) =>
      env.container.read(editorControllerProvider(id)).requireValue;

  Future<String> open(WidgetTester tester) async {
    env = await createEnv(tester);
    final id = await createProject(tester, env);
    await pumpApp(tester, env, location: AppRoutes.editor(id));
    await settleUntil(tester, find.byType(VideoClipTile));
    return id;
  }

  Future<void> tapTool(WidgetTester tester, String label) async {
    final tools = find.descendant(
      of: find.byType(ContextToolbar),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(find.text(label), 100, scrollable: tools);
    await tester.pump();
    await tester.tap(find.text(label));
  }

  Future<void> waitFor(WidgetTester tester, bool Function() done) async {
    for (var i = 0; !done(); i++) {
      expect(i, lessThan(200));
      await settle(tester, rounds: 1);
    }
    await settle(tester);
  }

  Future<void> finishEditing(WidgetTester tester) async {
    await tester.pump(autosaveDelay * 2);
    await settle(tester);
  }

  testWidgets('holds the frame at the playhead between the two parts', (
    tester,
  ) async {
    final id = await open(tester);
    env.engine.previewFrameHandler = (_, _, {required exact}) => tinyPng;
    await scrollTimelineTo(tester, 1000000);
    await tester.tapAt(
      Offset(
        tester.getCenter(find.byType(Playhead)).dx + 10,
        tester.getCenter(find.bySemanticsLabel(RegExp('^Clip 1 of'))).dy,
      ),
    );
    await settle(tester);
    final first = stateOf(id).timeline.videoClips.first;
    expect(stateOf(id).selection, ClipSelected(first.id));

    await tapTool(tester, 'Freeze');
    await waitFor(tester, () => stateOf(id).timeline.videoClips.length == 5);
    final state = stateOf(id);
    final clips = state.timeline.videoClips;
    final still = clips[1];
    expect(still.isPhoto, isTrue);
    expect(still.durationUs, TimelineLimits.photoDurationUs);
    expect(clips[0].durationUs, 1000000);
    expect(clips[2].sourceInUs, 1000000);
    // A still of the exact frame, read from the file at full size.
    final asked = env.engine.previewFrames.last;
    expect(asked.$2, 1000000);
    expect(asked.$3, isTrue);
    final asset = state.project.media[still.mediaId]!;
    expect(
      File(env.container.read(projectStoreProvider).resolve(id, asset.path))
          .existsSync(),
      isTrue,
    );
    // Selected, under the playhead, and one undo step.
    expect(state.selection, ClipSelected(still.id));
    expect(
      env.container.read(playbackControllerProvider).positionUs,
      state.layout.span(still.id)!.startUs,
    );
    expect(state.history.undoDepth, 1);
    await finishEditing(tester);
  });

  testWidgets('a second tap while freezing freezes once', (tester) async {
    final id = await open(tester);
    env.engine.previewFrameHandler = (_, _, {required exact}) => tinyPng;
    await scrollTimelineTo(tester, 1000000);
    final controller = env.container.read(
      editorControllerProvider(id).notifier,
    );
    final first = stateOf(id).timeline.videoClips.first.id;
    final results = await tester.runAsync(
      () => Future.wait([
        controller.freezeFrame(first, 1000000),
        controller.freezeFrame(first, 1000000),
      ]),
    );
    expect(results!.nonNulls, hasLength(1));
    expect(stateOf(id).timeline.videoClips, hasLength(5));
    await finishEditing(tester);
  });

  testWidgets('a frame that cannot be read says so and changes nothing', (
    tester,
  ) async {
    final id = await open(tester);
    env.engine.previewFrameHandler = (_, _, {required exact}) => null;
    await tester.tap(find.byType(VideoClipTile).first);
    await settle(tester);
    await tapTool(tester, 'Freeze');
    await settleUntil(tester, find.text("Couldn't freeze this frame"));
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(stateOf(id).timeline.videoClips, hasLength(3));
    expect(stateOf(id).history.undoDepth, 0);
    await finishEditing(tester);
  });
}
