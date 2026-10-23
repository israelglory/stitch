// Overlays through the real editor with the fake engine: adding one from
// the toolbar, its lane and tools, and moving it on the preview.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/app/router.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';
import 'package:stitch/features/editor/application/editor_state.dart';
import 'package:stitch/features/editor/application/playback_controller.dart';
import 'package:stitch/features/editor/presentation/overlay_picture.dart';
import 'package:stitch/features/text/presentation/text_overlay_layer.dart';
import 'package:stitch/features/timeline/domain/composition.dart';
import 'package:stitch/features/timeline/domain/models.dart';
import 'package:stitch/features/timeline/domain/overlay_ops.dart';

import '../helpers/app_scope.dart';
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
    tester.state<ScrollableState>(tools).position.jumpTo(0);
    await tester.pump();
    await tester.scrollUntilVisible(find.text(label), 100, scrollable: tools);
    await tester.pump();
    await tester.tap(find.text(label));
    await settle(tester);
  }

  Future<void> finishEditing(WidgetTester tester) async {
    await tester.pump(autosaveDelay * 2);
    await settle(tester);
  }

  /// Adds the newest library video as an overlay at 1 s, through the
  /// toolbar and the picker.
  Future<OverlayClip> addOverlay(WidgetTester tester, String id) async {
    env.library.addVideo('pip', seconds: 2);
    await scrollTimelineTo(tester, 1000000);
    await tester.tap(find.text('Overlay'));
    await settle(tester);
    expect(find.text('Add overlay'), findsOneWidget);
    await tester.tap(find.byType(MediaThumbnail).last);
    await tester.pump();
    await tester.tap(find.text('Add (1)'));
    for (var i = 0; stateOf(id).timeline.overlayClips.isEmpty; i++) {
      expect(i, lessThan(200), reason: 'the overlay is added');
      await settle(tester, rounds: 1);
    }
    await settle(tester);
    return stateOf(id).timeline.overlayClips.single;
  }

  testWidgets('adds a video over the picture at the playhead', (tester) async {
    final id = await open(tester);
    final overlay = await addOverlay(tester, id);
    final state = stateOf(id);
    expect(state.layout.startOf(overlay.anchor), 1000000);
    expect(overlay.durationUs, 2000000);
    expect(overlay.framing.scale, newOverlayScale);
    expect(state.selection, OverlaySelected(overlay.id));
    expect(state.history.undoDepth, 1);
    // Its lane, its tools, and on the preview.
    expect(find.bySemanticsLabel('Overlay, 2.0s'), findsOneWidget);
    expect(find.text('Opacity'), findsOneWidget);
    expect(find.byType(OverlayPicture), findsOneWidget);
    // In the document the engine gets.
    expect(
      ResolvedComposition.resolve(state.timeline).overlayClips.single.id,
      overlay.id,
    );
    await finishEditing(tester);
  });

  testWidgets('tapped on the preview, it is selected; dragged, it moves', (
    tester,
  ) async {
    final id = await open(tester);
    final overlay = await addOverlay(tester, id);
    await tester.tap(find.bySemanticsLabel('Back'));
    await settle(tester);
    expect(stateOf(id).selection, const NoSelection());

    final layer = tester.getRect(find.byType(TextOverlayLayer));
    await tester.tapAt(layer.center);
    await settle(tester);
    expect(stateOf(id).selection, OverlaySelected(overlay.id));

    final undo = stateOf(id).history.undoDepth;
    await tester.timedDragFrom(
      layer.center,
      Offset(layer.width * 0.3, 0),
      const Duration(milliseconds: 300),
    );
    await settle(tester);
    final moved = stateOf(id).timeline.overlayById(overlay.id)!;
    expect(moved.framing.offsetX, greaterThan(0.1));
    expect(moved.framing.offsetY, 0, reason: 'snapped level with the centre');
    expect(stateOf(id).history.undoDepth, undo + 1);
    await finishEditing(tester);
  });

  testWidgets('a tap outside it on the preview plays, as before', (
    tester,
  ) async {
    final id = await open(tester);
    await addOverlay(tester, id);
    await tester.tap(find.bySemanticsLabel('Back'));
    await settle(tester);
    final layer = tester.getRect(find.byType(TextOverlayLayer));
    // A corner, clear of the overlay in the middle.
    await tester.tapAt(layer.topLeft + const Offset(4, 4));
    await tester.pump();
    expect(stateOf(id).selection, const NoSelection());
    final playback = env.container.read(playbackControllerProvider);
    expect(playback.isPlaying, isTrue);
    await env.container.read(playbackControllerProvider.notifier).pause();
    await finishEditing(tester);
  });

  testWidgets('split, duplicate, and delete from its tools', (tester) async {
    final id = await open(tester);
    final overlay = await addOverlay(tester, id);
    await scrollTimelineTo(tester, 2000000);

    await tapTool(tester, 'Split');
    expect(stateOf(id).timeline.overlayClips, hasLength(2));

    await tapTool(tester, 'Duplicate');
    expect(stateOf(id).timeline.overlayClips, hasLength(3));
    final copy = (stateOf(id).selection as OverlaySelected).id;
    expect(copy, isNot(overlay.id));

    await tapTool(tester, 'Delete');
    expect(stateOf(id).timeline.overlayById(copy), isNull);
    expect(stateOf(id).selection, const NoSelection());
    await finishEditing(tester);
  });

  testWidgets('the overlay lane shows above the main track', (tester) async {
    final id = await open(tester);
    await addOverlay(tester, id);
    final lane = tester.getCenter(find.bySemanticsLabel('Overlay, 2.0s'));
    final clip = tester.getCenter(find.bySemanticsLabel(RegExp('^Clip 1 of')));
    expect(lane.dy, lessThan(clip.dy));
    // Tapping its tile on the timeline selects it.
    await tester.tap(find.bySemanticsLabel('Back'));
    await settle(tester);
    await tester.tap(find.bySemanticsLabel('Overlay, 2.0s'));
    await settle(tester);
    expect(stateOf(id).selection, isA<OverlaySelected>());
    await finishEditing(tester);
  });
}
