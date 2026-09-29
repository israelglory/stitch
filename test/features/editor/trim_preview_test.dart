import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/app/router.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';
import 'package:stitch/features/editor/presentation/editor_screen.dart';
import 'package:stitch/features/editor/presentation/preview.dart';
import 'package:stitch/features/timeline/domain/models.dart';

import '../../helpers/pump.dart';

/// A 1 x 1 PNG, standing in for the engine's JPEG frames.
final Uint8List _frame = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAE'
  'hQGAhKmMIQAAAABJRU5ErkJggg==',
);

void main() {
  testWidgets('dragging a trim handle shows the frame at the handle', (
    tester,
  ) async {
    final env = await createEnv(tester);
    env.engine.previewFrameHandler = (_, _, {required exact}) => _frame;
    final id = await createProject(tester, env);
    await pumpApp(tester, env, location: AppRoutes.editor(id));
    await settleUntil(tester, find.byType(VideoClipTile));
    VideoClip first() =>
        ProviderScope.containerOf(tester.element(find.byType(EditorScreen)))
            .read(editorControllerProvider(id))
            .requireValue
            .timeline
            .videoClips
            .first;
    final trimFrame = find.descendant(
      of: find.byType(EditorPreview),
      matching: find.byWidgetPredicate(
        (w) => w is Image && w.image is MemoryImage,
      ),
    );

    final tile = find.byType(VideoClipTile).first;
    await tester.tap(tile);
    await tester.pump();
    final rect = tester.getRect(tile);

    // Drag the end handle in; hold still, then let go.
    final gesture = await tester.startGesture(
      rect.centerRight - const Offset(4, 0),
    );
    for (var i = 0; i < 6; i++) {
      await gesture.moveBy(const Offset(-10, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pump();
    expect(trimFrame, findsOneWidget);

    // The clip's new last frame, from its file; quick while moving, then
    // exact once the finger rests.
    final lastFrameUs = first().sourceOutUs - 33333;
    expect(env.engine.previewFrames.last.$2, lastFrameUs);
    expect(env.engine.previewFrames.first.$3, isFalse);
    await tester.pump(const Duration(milliseconds: 200));
    expect(env.engine.previewFrames.last, (
      env.engine.previewFrames.last.$1,
      lastFrameUs,
      true,
    ));

    await gesture.up();
    await settle(tester);
    expect(trimFrame, findsNothing);
    await tester.pump(autosaveDelay * 2);
    await settle(tester);
  });
}
