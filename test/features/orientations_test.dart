// Every main screen on iPads (both ways, and in Split View) and in short
// wide windows (Android split screen), failing on any layout overflow or
// exception. iPads follow the device's orientation; phones stay upright.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/app/router.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';

import '../helpers/pump.dart';

const _sizes = <String, Size>{
  'iPhone SE (1st) landscape': Size(568, 320),
  'iPhone SE landscape': Size(667, 375),
  'iPhone 16 landscape': Size(844, 390),
  'iPad portrait': Size(820, 1180),
  'iPad landscape': Size(1180, 820),
  'iPad Pro 12.9 landscape': Size(1366, 1024),
  'iPad Split View, a third': Size(320, 1024),
  'iPad Split View, a half landscape': Size(678, 820),
};

void main() {
  for (final MapEntry(key: name, value: size) in _sizes.entries) {
    group(name, () {
      testWidgets('onboarding', (tester) async {
        final env = await createEnv(tester, onboarded: false);
        await pumpApp(tester, env, size: size);
        for (var i = 0; i < 2; i++) {
          await tester.tap(find.byType(PrimaryButton));
          await settle(tester);
        }
        expect(tester.takeException(), isNull);
      });

      testWidgets('home, picker, and format', (tester) async {
        final env = await createEnv(tester);
        await createProject(tester, env, name: 'A long project name');
        await createProject(tester, env, name: 'Short');
        for (var i = 0; i < 12; i++) {
          env.library.addVideo('v$i', seconds: 90 + i);
        }
        await pumpApp(tester, env, size: size);
        expect(find.byType(ProjectCard), findsNWidgets(2));
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('New project'));
        await settle(tester);
        await tester.tap(find.byType(MediaThumbnail).first);
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.tap(find.byType(PrimaryButton));
        await settle(tester);
        expect(tester.takeException(), isNull);
      });

      testWidgets('editor, tools, and sheets', (tester) async {
        final env = await createEnv(tester);
        final id = await createProject(tester, env);
        await pumpApp(tester, env, location: AppRoutes.editor(id), size: size);
        await settleUntil(tester, find.byType(VideoClipTile));
        expect(tester.takeException(), isNull);
        await tester.tap(find.byType(VideoClipTile).first);
        await tester.pump();
        expect(tester.takeException(), isNull);
        // The tallest tool sheet: four sliders.
        await tester.tap(find.text('Transform'));
        await settle(tester);
        expect(tester.takeException(), isNull);
        await tester.tap(find.bySemanticsLabel('Done'));
        await settle(tester);

        await tester.tap(find.bySemanticsLabel('Back'));
        await settle(tester);
        await tester.tap(find.text('Text'));
        await settle(tester);
        await tester.enterText(find.byType(EditableText), 'Hello there');
        await settle(tester);
        expect(tester.takeException(), isNull);
        await tester.tap(find.bySemanticsLabel('Done'));
        await settle(tester);
        expect(tester.takeException(), isNull);
        await tester.pump(autosaveDelay * 2);
        await settle(tester);
      });

      testWidgets('export', (tester) async {
        final env = await createEnv(tester);
        final id = await createProject(tester, env);
        await pumpApp(tester, env, location: AppRoutes.editor(id), size: size);
        await settleUntil(tester, find.byType(VideoClipTile));
        await tester.tap(find.widgetWithText(PrimaryButton, 'Export'));
        await settle(tester);
        expect(tester.takeException(), isNull);
        // Short screens scroll the sheet to its button.
        final start = find.widgetWithText(PrimaryButton, 'Export').last;
        await tester.ensureVisible(start);
        await tester.pump();
        await tester.tap(start);
        await settleUntil(tester, find.text('Back to editing'));
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Back to editing'));
        await settle(tester);
        await tester.pump(autosaveDelay * 2);
        await settle(tester);
      });

      testWidgets('settings', (tester) async {
        final env = await createEnv(tester);
        await pumpApp(tester, env, size: size);
        await tester.tap(find.bySemanticsLabel('Settings'));
        await settle(tester);
        expect(tester.takeException(), isNull);
      });
    });
  }
}
