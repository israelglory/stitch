// Every screen on the smallest supported phone with large system text,
// failing on any layout overflow or exception.
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/app/router.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';

import '../helpers/app_harness.dart';
import '../helpers/pump.dart';

void main() {
  for (final scale in [1.0, 2.0]) {
    group('iPhone SE at ${scale}x text', () {
      testWidgets('onboarding', (tester) async {
        final env = await createEnv(tester, onboarded: false);
        await pumpApp(tester, env, size: smallPhone, textScale: scale);
        for (var i = 0; i < 2; i++) {
          await tester.tap(find.byType(PrimaryButton));
          await settle(tester);
        }
        expect(tester.takeException(), isNull);
      });

      testWidgets('home, empty', (tester) async {
        final env = await createEnv(tester);
        await pumpApp(tester, env, size: smallPhone, textScale: scale);
        expect(find.text('No projects yet'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('home, with projects', (tester) async {
        // Projects are created before the app starts: file work from the
        // test and from the app must not interleave across test zones.
        final env = await createEnv(tester);
        await createProject(tester, env, name: 'A long project name');
        await createProject(tester, env, name: 'Short');
        await pumpApp(tester, env, size: smallPhone, textScale: scale);
        expect(find.byType(ProjectCard), findsNWidgets(2));
        expect(tester.takeException(), isNull);
      });

      testWidgets('picker and format', (tester) async {
        final env = await createEnv(tester);
        for (var i = 0; i < 6; i++) {
          env.library.addVideo('v$i', seconds: 90 + i);
        }
        await pumpApp(
          tester,
          env,
          location: AppRoutes.newProject,
          size: smallPhone,
          textScale: scale,
        );
        await tester.tap(find.byType(MediaThumbnail).first);
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.tap(find.byType(PrimaryButton));
        await settle(tester);
        expect(tester.takeException(), isNull);
      });

      testWidgets('editor with a selection and a sheet', (tester) async {
        final env = await createEnv(tester);
        final id = await createProject(tester, env);
        await pumpApp(
          tester,
          env,
          location: AppRoutes.editor(id),
          size: smallPhone,
          textScale: scale,
        );
        await settleUntil(tester, find.byType(VideoClipTile));
        await tester.tap(find.byType(VideoClipTile).first);
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Speed'));
        await settle(tester);
        expect(tester.takeException(), isNull);
        await tester.pump(autosaveDelay * 2);
        await settle(tester);
      });
    });
  }
}
