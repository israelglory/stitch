// Keyframes through the real editor, with the fake engine: the button in
// the playback row, the markers on the selected item, the sliders and
// canvas gestures that record them, and easing.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/app/router.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';
import 'package:stitch/features/editor/application/editor_state.dart';
import 'package:stitch/features/editor/application/playback_controller.dart';
import 'package:stitch/features/editor/presentation/editor_screen.dart';
import 'package:stitch/features/editor/presentation/preview.dart';
import 'package:stitch/features/text/presentation/text_overlay_layer.dart';
import 'package:stitch/features/timeline/domain/keyframes.dart';
import 'package:stitch/features/timeline/domain/models.dart';
import 'package:stitch/features/timeline/domain/text_ops.dart';

import '../helpers/app_scope.dart';
import '../helpers/pump.dart';

Finder get addButton => find.bySemanticsLabel('Add keyframe');
Finder get removeButton => find.bySemanticsLabel('Remove keyframe');
Finder get markers => find.bySemanticsLabel(RegExp('^Keyframe at '));

void main() {
  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(EditorScreen)));

  EditorState stateOf(WidgetTester tester, String id) =>
      containerOf(tester).read(editorControllerProvider(id)).requireValue;

  VideoClip firstClip(WidgetTester tester, String id) =>
      stateOf(tester, id).timeline.videoClips.first;

  KeyframeOwner ownerOf(WidgetTester tester, String id) =>
      (kind: KeyframeOwnerKind.clip, id: firstClip(tester, id).id);

  late TestEnv env;

  Future<String> open(WidgetTester tester) async {
    env = await createEnv(tester);
    final id = await createProject(tester, env);
    await pumpApp(tester, env, location: AppRoutes.editor(id));
    await settleUntil(tester, find.byType(VideoClipTile));
    return id;
  }

  Future<void> seek(WidgetTester tester, int us) async {
    await containerOf(tester)
        .read(playbackControllerProvider.notifier)
        .seek(us);
    await settle(tester);
  }

  Future<void> selectFirstClip(WidgetTester tester) async {
    await tester.tap(find.byType(VideoClipTile).first);
    await settle(tester);
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

  Future<void> dragSlider(WidgetTester tester, double dx) async {
    await tester.drag(
      find.descendant(
        of: find.byType(AppSlider),
        matching: find.byType(Slider),
      ),
      Offset(dx, 0),
    );
    await settle(tester);
  }

  Future<void> closeSheet(WidgetTester tester) async {
    await tester.tap(find.bySemanticsLabel('Done'));
    await settle(tester);
  }

  Future<void> finishEditing(WidgetTester tester) async {
    await tester.pump(autosaveDelay * 2);
    await settle(tester);
  }

  testWidgets('the button adds and removes a keyframe at the playhead', (
    tester,
  ) async {
    final id = await open(tester);
    // Nothing selected: nothing to keyframe.
    final button = tester.widget<AppIconButton>(
      find.ancestor(of: addButton, matching: find.byType(AppIconButton)),
    );
    expect(button.onPressed, isNull);

    await selectFirstClip(tester);
    await seek(tester, 500000);
    expect(markers, findsNothing);
    final undoBefore = stateOf(tester, id).history.undoDepth;
    await tester.tap(addButton);
    await settle(tester);
    expect(firstClip(tester, id).keyframes, hasLength(1));
    expect(stateOf(tester, id).history.undoDepth, undoBefore + 1);
    expect(removeButton, findsOneWidget);
    expect(markers, findsOneWidget);

    // A second one; its marker takes the playhead back to it.
    await seek(tester, 2000000);
    expect(addButton, findsOneWidget);
    await tester.tap(addButton);
    await settle(tester);
    expect(markers, findsNWidgets(2));
    await tester.tap(markers.first);
    await settle(tester);
    expect(
      containerOf(tester).read(playbackControllerProvider).positionUs,
      500000,
    );
    expect(removeButton, findsOneWidget);

    await tester.tap(removeButton);
    await settle(tester);
    expect(firstClip(tester, id).keyframes, hasLength(1));
    await tester.tap(find.bySemanticsLabel('Undo'));
    await settle(tester);
    expect(firstClip(tester, id).keyframes, hasLength(2));
    await finishEditing(tester);
  });

  testWidgets('sliders change the clip, then record keyframes', (tester) async {
    final id = await open(tester);
    await selectFirstClip(tester);

    // No keyframes: the clip's own opacity.
    await tapTool(tester, 'Opacity');
    await dragSlider(tester, -400);
    await closeSheet(tester);
    expect(firstClip(tester, id).opacity, lessThan(1));
    expect(firstClip(tester, id).keyframes, isEmpty);

    // With a keyframe, a change elsewhere records another.
    await tester.tap(addButton);
    await settle(tester);
    await seek(tester, 2000000);
    await tapTool(tester, 'Volume');
    final undoBefore = stateOf(tester, id).history.undoDepth;
    await dragSlider(tester, -100);
    await closeSheet(tester);
    final clip = firstClip(tester, id);
    expect(clip.keyframes, hasLength(2));
    expect(clip.volume, 1, reason: 'own value untouched');
    expect(clip.keyframes.last.values.volume, lessThan(1));
    expect(stateOf(tester, id).history.undoDepth, undoBefore + 1);
    await finishEditing(tester);
  });

  testWidgets('easing is offered on a keyframe only', (tester) async {
    final id = await open(tester);
    await selectFirstClip(tester);
    expect(find.text('Easing'), findsNothing);

    await tester.tap(addButton);
    await settle(tester);
    await tapTool(tester, 'Easing');
    await tester.tap(find.text('Ease in'));
    await settle(tester);
    expect(
      firstClip(tester, id).keyframes.single.easing,
      KeyframeEasing.easeIn,
    );
    await closeSheet(tester);

    await seek(tester, 1500000);
    expect(find.text('Easing'), findsNothing);
    await finishEditing(tester);
  });

  testWidgets('dragging the selected clip on the preview moves it', (
    tester,
  ) async {
    final id = await open(tester);
    await selectFirstClip(tester);
    final layer = tester.getRect(find.byType(TextOverlayLayer));

    // No keyframes: the clip's framing moves.
    await tester.timedDragFrom(
      layer.center,
      const Offset(30, 0),
      const Duration(milliseconds: 300),
    );
    await settle(tester);
    expect(firstClip(tester, id).framing.offsetX, greaterThan(0));
    expect(firstClip(tester, id).keyframes, isEmpty);

    // With a keyframe at 0, a drag at 2 s records one there; the start
    // keeps its place.
    await seek(tester, 0);
    await tester.tap(addButton);
    await settle(tester);
    final startX = firstClip(tester, id).framing.offsetX;
    await seek(tester, 2000000);
    final undoBefore = stateOf(tester, id).history.undoDepth;
    await tester.timedDragFrom(
      layer.center,
      const Offset(0, 30),
      const Duration(milliseconds: 300),
    );
    await settle(tester);
    final t = stateOf(tester, id).timeline;
    expect(firstClip(tester, id).keyframes, hasLength(2));
    expect(t.valuesAt(ownerOf(tester, id), 0)!.x, startX);
    expect(t.valuesAt(ownerOf(tester, id), 0)!.y, 0);
    expect(t.valuesAt(ownerOf(tester, id), 2000000)!.y, greaterThan(0));
    expect(stateOf(tester, id).history.undoDepth, undoBefore + 1);
    await finishEditing(tester);
  });

  testWidgets('the preview shows the values between keyframes', (tester) async {
    final id = await open(tester);
    final owner = ownerOf(tester, id);
    containerOf(tester)
        .read(editorControllerProvider(id).notifier)
        .apply(
          (t) => t
              .addKeyframe(owner, 0, id: 'k1')
              .setValuesAt(
                owner,
                2000000,
                (v) => v.copyWith(opacity: 0, scale: 2),
                newKeyframeId: 'k2',
              ),
        );
    await seek(tester, 1000000);
    final opacity = tester.widget<Opacity>(
      find
          .descendant(
            of: find.byType(EditorPreview),
            matching: find.byType(Opacity),
          )
          .first,
    );
    expect(opacity.opacity, closeTo(0.5, 1e-9));
    final transform = tester.widget<Transform>(
      find
          .descendant(
            of: find.byType(Opacity).first,
            matching: find.byType(Transform),
          )
          .first,
    );
    expect(transform.transform.getMaxScaleOnAxis(), closeTo(1.5, 1e-9));
    await finishEditing(tester);
  });

  testWidgets('the Transform tool moves and zooms without gestures', (
    tester,
  ) async {
    final id = await open(tester);
    await selectFirstClip(tester);
    await tapTool(tester, 'Transform');
    final sliders = find.descendant(
      of: find.byType(AppSlider),
      matching: find.byType(Slider),
    );
    expect(sliders, findsNWidgets(4));
    expect(find.text('Left and right'), findsOneWidget);
    expect(find.text('Rotation'), findsOneWidget);

    // No keyframes: the clip's own framing.
    await tester.drag(sliders.at(0), const Offset(60, 0));
    await settle(tester);
    expect(firstClip(tester, id).framing.offsetX, greaterThan(0));
    await tester.drag(sliders.at(2), const Offset(60, 0));
    await settle(tester);
    expect(firstClip(tester, id).framing.scale, greaterThan(1));
    await closeSheet(tester);

    // With a keyframe at 0, turning at 2 s records one there.
    await seek(tester, 0);
    await tester.tap(addButton);
    await settle(tester);
    await seek(tester, 2000000);
    await tapTool(tester, 'Transform');
    await tester.drag(sliders.at(3), const Offset(80, 0));
    await settle(tester);
    await closeSheet(tester);
    final t = stateOf(tester, id).timeline;
    expect(firstClip(tester, id).keyframes, hasLength(2));
    expect(t.valuesAt(ownerOf(tester, id), 0)!.rotationDeg, 0);
    expect(t.valuesAt(ownerOf(tester, id), 2000000)!.rotationDeg, isNot(0));
    await finishEditing(tester);
  });

  testWidgets('screen readers hear what the keyframe button did', (
    tester,
  ) async {
    await open(tester);
    await selectFirstClip(tester);
    tester.takeAnnouncements();
    await tester.tap(addButton);
    await settle(tester);
    expect(tester.takeAnnouncements().map((a) => a.message), [
      'Keyframe added',
    ]);
    await tester.tap(removeButton);
    await settle(tester);
    expect(tester.takeAnnouncements().map((a) => a.message), [
      'Keyframe removed',
    ]);
    await finishEditing(tester);
  });

  testWidgets('keyframe controls are labeled and big enough to tap', (
    tester,
  ) async {
    await open(tester);
    await selectFirstClip(tester);
    await tester.tap(addButton);
    await settle(tester);
    await seek(tester, 1500000);
    await tester.tap(addButton);
    await settle(tester);
    expect(markers, findsNWidgets(2));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await finishEditing(tester);
  });

  testWidgets('a clip shows its frame while a Transform slider moves', (
    tester,
  ) async {
    // A 1 x 1 PNG, standing in for the engine's JPEG frames.
    final png = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAE'
      'hQGAhKmMIQAAAABJRU5ErkJggg==',
    );
    final id = await open(tester);
    env.engine.previewFrameHandler = (_, _, {required exact}) => png;
    await selectFirstClip(tester);
    await seek(tester, 1000000);
    await tapTool(tester, 'Transform');
    final frame = find.descendant(
      of: find.byType(EditorPreview),
      matching: find.byWidgetPredicate(
        (w) => w is Image && w.image is MemoryImage,
      ),
    );
    final zoom = find
        .descendant(of: find.byType(AppSlider), matching: find.byType(Slider))
        .at(2);
    final gesture = await tester.startGesture(tester.getCenter(zoom));
    for (var i = 0; i < 5; i++) {
      await gesture.moveBy(const Offset(12, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pump();
    expect(frame, findsOneWidget);
    // The frame at the playhead, from the clip's file.
    expect(env.engine.previewFrames.last.$2, 1000000);
    await gesture.up();
    await settle(tester);
    expect(frame, findsNothing);
    expect(firstClip(tester, id).framing.scale, greaterThan(1));
    await finishEditing(tester);
  });

  testWidgets('screen readers trim a clip with its labeled handles', (
    tester,
  ) async {
    final id = await open(tester);
    await selectFirstClip(tester);
    final before = firstClip(tester, id).sourceOutUs;
    tester.semantics.performAction(
      find.semantics.byLabel('Trim end'),
      SemanticsAction.decrease,
    );
    await settle(tester);
    expect(firstClip(tester, id).sourceOutUs, lessThan(before));
    expect(find.bySemanticsLabel('Trim start'), findsOneWidget);
    await finishEditing(tester);
  });

  testWidgets('text zoomed by a keyframe is drawn for its largest size', (
    tester,
  ) async {
    final id = await open(tester);
    final controller = containerOf(tester)
        .read(editorControllerProvider(id).notifier);
    const owner = (kind: KeyframeOwnerKind.text, id: 't');
    controller.apply(
      (t) => t
          .addText(id: 't', text: 'Big', atUs: 0)
          .addKeyframe(owner, 0, id: 'k1')
          .setValuesAt(
            owner,
            1000000,
            (v) => v.copyWith(scale: 3),
            newKeyframeId: 'k2',
          ),
    );
    await settle(tester);
    await tester.pump(const Duration(seconds: 1));
    await settle(tester);
    expect(env.rasterizer.zooms.last, 3);
    await finishEditing(tester);
  });
}
