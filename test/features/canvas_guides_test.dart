// Snapping and guides while text or a clip is moved on the preview, and
// the add-clip button pinned on the timeline, through the real editor with
// the fake engine.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/app/router.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';
import 'package:stitch/features/editor/application/editor_state.dart';
import 'package:stitch/features/editor/application/playback_controller.dart';
import 'package:stitch/features/editor/presentation/editor_screen.dart';
import 'package:stitch/features/text/presentation/text_overlay_layer.dart';

import '../helpers/app_scope.dart';
import '../helpers/pump.dart';

void main() {
  late TestEnv env;

  // The app's container: the editor may be under the media picker.
  ProviderContainer containerOf(WidgetTester tester) => env.container;

  EditorState stateOf(WidgetTester tester, String id) =>
      containerOf(tester).read(editorControllerProvider(id)).requireValue;

  Future<String> open(WidgetTester tester) async {
    env = await createEnv(tester);
    final id = await createProject(tester, env);
    await pumpApp(tester, env, location: AppRoutes.editor(id));
    await settleUntil(tester, find.byType(VideoClipTile));
    return id;
  }

  Future<void> finishEditing(WidgetTester tester) async {
    await tester.pump(autosaveDelay * 2);
    await settle(tester);
  }

  /// Haptic taps, from the platform channel.
  List<String> recordHaptics(WidgetTester tester) {
    final haptics = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add(call.arguments as String);
        }
        return null;
      },
    );
    return haptics;
  }

  /// What the overlay paints: text, then the guides over it.
  RenderObject overlayPaint(WidgetTester tester) => tester.renderObject(
    find
        .descendant(
          of: find.byType(TextOverlayLayer),
          matching: find.byType(CustomPaint),
        )
        .first,
  );

  Future<void> addText(WidgetTester tester) async {
    await tester.tap(find.text('Text'));
    await settle(tester);
    await tester.enterText(find.byType(EditableText), 'Line up');
    await settle(tester);
    await tester.tap(find.bySemanticsLabel('Done'));
    await settle(tester);
  }

  group('text', () {
    testWidgets('snaps to the centre, with a guide and a tap', (tester) async {
      final id = await open(tester);
      await addText(tester);
      final haptics = recordHaptics(tester);
      final layer = tester.getRect(find.byType(TextOverlayLayer));

      // Away from the middle, then back to 2 pixels short of it.
      final gesture = await tester.startGesture(layer.center);
      for (var i = 0; i < 6; i++) {
        await gesture.moveBy(const Offset(0, 10));
        await tester.pump(const Duration(milliseconds: 16));
      }
      final y = stateOf(tester, id).timeline.textItems.single.transform.y;
      expect(y, greaterThan(0.55));
      haptics.clear();
      await gesture.moveBy(Offset(0, (0.5 - y) * layer.height + 2));
      await tester.pump();
      expect(stateOf(tester, id).timeline.textItems.single.transform.y, 0.5);
      expect(haptics, ['HapticFeedbackType.lightImpact']);
      // Lines through the middle: it was already centred across.
      expect(
        overlayPaint(tester),
        paints
          ..line()
          ..line(),
      );

      await gesture.up();
      await settle(tester);
      expect(stateOf(tester, id).timeline.textItems.single.transform.y, 0.5);
      expect(overlayPaint(tester), isNot(paints..line()));
      // Back where it was: only adding it is undone.
      expect(stateOf(tester, id).history.undoDepth, 1);
      await finishEditing(tester);
    });

    testWidgets('twisted a little, turns back level and shows the angle', (
      tester,
    ) async {
      final id = await open(tester);
      await addText(tester);
      final c = tester.getCenter(find.byType(TextOverlayLayer));

      final a = await tester.startGesture(c - const Offset(40, 0), pointer: 1);
      final b = await tester.startGesture(c + const Offset(40, 0), pointer: 2);
      // Spread to start the pinch, then turn about 3 degrees.
      for (var i = 0; i < 4; i++) {
        await a.moveBy(const Offset(-5, 0));
        await b.moveBy(const Offset(5, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await a.moveBy(const Offset(0, -3));
      await b.moveBy(const Offset(0, 3));
      await tester.pump();
      expect(find.text('0°'), findsOneWidget);
      expect(
        stateOf(tester, id).timeline.textItems.single.transform.rotationDeg,
        0,
      );

      // Further: about 14 degrees, shown as it turns.
      await a.moveBy(const Offset(0, -12));
      await b.moveBy(const Offset(0, 12));
      await tester.pump();
      final turned = stateOf(
        tester,
        id,
      ).timeline.textItems.single.transform.rotationDeg;
      expect(turned, closeTo(14, 1));
      expect(find.text('${turned.round()}°'), findsOneWidget);

      await a.up();
      await b.up();
      await settle(tester);
      expect(find.textContaining('°'), findsNothing);
      await finishEditing(tester);
    });
  });

  group('clip', () {
    Future<void> selectFirstClip(WidgetTester tester) async {
      await tester.tap(find.byType(VideoClipTile).first);
      await settle(tester);
    }

    testWidgets('moved back near the middle, fills the frame again', (
      tester,
    ) async {
      final id = await open(tester);
      await selectFirstClip(tester);
      final layer = tester.getRect(find.byType(TextOverlayLayer));
      final white = context(tester).colors.onOverlay;

      final gesture = await tester.startGesture(layer.center);
      for (var i = 0; i < 6; i++) {
        await gesture.moveBy(const Offset(10, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      final moved = stateOf(tester, id).timeline.videoClips.first.framing;
      expect(moved.offsetX, greaterThan(0));
      // Off centre: the clip's outline, no frame border.
      expect(overlayPaint(tester), isNot(paints..rect(color: white)));

      await gesture.moveBy(Offset(-moved.offsetX * layer.width + 3, 0));
      await tester.pump();
      expect(stateOf(tester, id).timeline.videoClips.first.framing.offsetX, 0);
      // The 9:16 video fills the 9:16 frame exactly: a white border.
      expect(overlayPaint(tester), paints..rect(color: white));

      await gesture.up();
      await settle(tester);
      expect(overlayPaint(tester), isNot(paints..rect(color: white)));
      await finishEditing(tester);
    });

    testWidgets('pinched near its own size, snaps to it', (tester) async {
      final id = await open(tester);
      await selectFirstClip(tester);
      final c = tester.getCenter(find.byType(TextOverlayLayer));

      final a = await tester.startGesture(c - const Offset(40, 0), pointer: 1);
      final b = await tester.startGesture(c + const Offset(40, 0), pointer: 2);
      for (var i = 0; i < 8; i++) {
        await a.moveBy(const Offset(-5, 0));
        await b.moveBy(const Offset(5, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      final zoomed = stateOf(tester, id).timeline.videoClips.first.framing;
      expect(zoomed.scale, greaterThan(1.2));
      // The pinch counts from where it was taken up: back to 2% wider
      // than there.
      final startSpan = 160 / zoomed.scale;
      final inward = (160 - startSpan * 1.02) / 2;
      await a.moveBy(Offset(inward, 0));
      await b.moveBy(Offset(-inward, 0));
      await tester.pump();
      expect(stateOf(tester, id).timeline.videoClips.first.framing.scale, 1);

      await a.up();
      await b.up();
      await settle(tester);
      expect(stateOf(tester, id).timeline.videoClips.first.framing.scale, 1);
      await finishEditing(tester);
    });
  });

  group('add clip', () {
    testWidgets('pinned anywhere; adds at the cut nearest the playhead', (
      tester,
    ) async {
      final id = await open(tester);
      env.library.addVideo('new', seconds: 6);
      final before = [
        for (final c in stateOf(tester, id).timeline.videoClips) c.id,
      ];

      // At the start and far along, the button is on screen.
      final add = find.bySemanticsLabel('Add clip');
      final screen = tester.getRect(find.byType(EditorScreen));
      expect(screen.contains(tester.getCenter(add)), isTrue);
      await scrollTimelineTo(tester, 8000000);
      expect(screen.contains(tester.getCenter(add)), isTrue);

      // 2 s is in the second half of the first clip (0 to 3 s): the new
      // clip goes after it.
      await scrollTimelineTo(tester, 2000000);
      await tester.tap(add);
      await settle(tester);
      await tester.tap(find.byType(MediaThumbnail).last);
      await tester.pump();
      await tester.tap(find.text('Add (1)'));
      for (var i = 0; stateOf(tester, id).timeline.videoClips.length < 4; i++) {
        expect(i, lessThan(200), reason: 'the clip is added');
        await settle(tester, rounds: 1);
      }
      await settle(tester);

      final state = stateOf(tester, id);
      final clips = state.timeline.videoClips;
      expect(clips.map((c) => c.id).toList()..removeAt(1), before);
      expect(clips[1].durationUs, 6000000);
      expect(state.selection, ClipSelected(clips[1].id));
      // The playhead moves to the new clip.
      expect(
        containerOf(tester).read(playbackControllerProvider).positionUs,
        state.layout.span(clips[1].id)!.startUs,
      );
      expect(state.history.undoDepth, 1);
      await finishEditing(tester);
    });
  });
}

BuildContext context(WidgetTester tester) =>
    tester.element(find.byType(TextOverlayLayer));
