// Export, settings, licenses, and relinking missing media, through the
// real screens with the fake engine and system services.
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/app/providers.dart';
import 'package:stitch/app/router.dart';
import 'package:stitch/core/platform/system_services.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/features/captions/data/caption_models.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';
import 'package:stitch/features/editor/presentation/editor_screen.dart';
import 'package:stitch/features/export/presentation/export_screen.dart';
import 'package:stitch/features/settings/application/settings_controller.dart';
import 'package:stitch/features/settings/application/storage.dart';
import 'package:stitch/features/settings/domain/app_settings.dart';

import '../helpers/app_scope.dart';
import '../helpers/pump.dart';

void main() {
  late TestEnv env;

  Future<String> openEditor(WidgetTester tester) async {
    env = await createEnv(tester);
    final id = await createProject(tester, env);
    await pumpApp(tester, env, location: AppRoutes.editor(id));
    await settleUntil(tester, find.byType(VideoClipTile));
    return id;
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.pump(autosaveDelay * 2);
    await settle(tester);
  }

  Future<void> openExportSheet(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(PrimaryButton, 'Export'));
    await settle(tester);
    expect(find.text('Resolution'), findsOneWidget);
  }

  Future<void> startExport(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(PrimaryButton, 'Export').last);
    await settle(tester);
    expect(find.byType(ExportScreen), findsOneWidget);
  }

  group('export', () {
    testWidgets('exports, saves, shares, and goes back to editing', (
      tester,
    ) async {
      await openEditor(tester);
      await openExportSheet(tester);
      // 9 s at 1080p30, better quality.
      expect(find.text('About 12 MB'), findsOneWidget);
      await tester.tap(find.text('720p'));
      await tester.pump();
      expect(find.text('About 6 MB'), findsOneWidget);

      await startExport(tester);
      expect(find.text('Exporting video'), findsOneWidget);
      await settleUntil(tester, find.text('Saved to Photos'));
      expect(env.engine.lastExport!.width, 720);
      expect(env.system.saved, hasLength(1));

      await tester.tap(find.widgetWithText(PrimaryButton, 'Share'));
      await settle(tester);
      expect(env.system.shared, env.system.saved);

      await tester.tap(find.text('Back to editing'));
      await settle(tester);
      expect(find.byType(ExportScreen), findsNothing);
      expect(find.byType(EditorScreen), findsOneWidget);
      await finish(tester);
    });

    testWidgets('low storage says so; Retry works once there is room', (
      tester,
    ) async {
      await openEditor(tester);
      env.system.free = 1000;
      await openExportSheet(tester);
      await startExport(tester);
      await settleUntil(tester, find.text('There is not enough free space.'));
      env.system.free = 64 * 1000 * 1000 * 1000;
      await tester.tap(find.text('Retry'));
      await settleUntil(tester, find.text('Saved to Photos'));
      await finish(tester);
    });

    testWidgets('Cancel asks first, then stops and goes back', (tester) async {
      await openEditor(tester);
      env.engine.exportStep = const Duration(seconds: 2);
      await openExportSheet(tester);
      await startExport(tester);
      await tester.tap(find.widgetWithText(SecondaryButton, 'Cancel'));
      await settle(tester, rounds: 2);
      expect(find.text('Stop exporting?'), findsOneWidget);
      await tester.tap(find.text('Keep exporting'));
      await settle(tester, rounds: 2);
      expect(find.byType(ExportScreen), findsOneWidget);

      await tester.tap(find.widgetWithText(SecondaryButton, 'Cancel'));
      await settle(tester, rounds: 2);
      await tester.tap(find.text('Stop'));
      await settle(tester);
      expect(find.byType(ExportScreen), findsNothing);
      expect(env.system.saved, isEmpty);
      await finish(tester);
    });

    testWidgets('refused photo access offers to allow it', (tester) async {
      await openEditor(tester);
      env.system.saveResult = GallerySave.denied;
      await openExportSheet(tester);
      await startExport(tester);
      await settleUntil(
        tester,
        find.text('Stitch cannot save to your photos without access.'),
      );
      env.system.saveResult = GallerySave.saved;
      await tester.tap(find.text('Allow access'));
      await settle(tester);
      expect(find.text('Saved to Photos'), findsOneWidget);
      await finish(tester);
    });
  });

  group('settings', () {
    Future<void> openSettings(WidgetTester tester) async {
      env = await createEnv(tester);
      await pumpApp(tester, env);
      await tester.tap(find.bySemanticsLabel('Settings'));
      await settle(tester);
    }

    ProviderContainer containerOf(WidgetTester tester) =>
        ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));

    testWidgets('theme and defaults apply and are kept', (tester) async {
      await openSettings(tester);
      await tester.tap(find.text('Theme'));
      await settle(tester);
      await tester.tap(find.text('Light'));
      await settle(tester);
      final context = tester.element(find.text('Theme'));
      expect(Theme.of(context).brightness, Brightness.light);

      await tester.tap(find.text('Format'));
      await settle(tester);
      await tester.tap(find.text('1:1'));
      await settle(tester);
      await tester.tap(find.text('Quality'));
      await settle(tester);
      await tester.tap(find.text('Smaller file').last);
      await settle(tester);

      final settings = containerOf(tester).read(settingsControllerProvider);
      expect(settings.theme, ThemeChoice.light);
      expect(settings.aspect.name, 'square');
      expect(settings.export.quality.name, 'smaller');
      // Stored: a fresh read gives the same.
      expect(
        containerOf(tester).read(settingsRepositoryProvider).read(),
        settings,
      );
    });

    testWidgets('clear cache asks, then deletes what can be made again', (
      tester,
    ) async {
      await openSettings(tester);
      final cache = containerOf(tester).read(cacheRootProvider);
      final thumb = File('${cache.path}/filmstrip/a.jpg');
      final model = File('${cache.path}/models/keep.bin');
      await tester.runAsync(() async {
        await thumb.create(recursive: true);
        await thumb.writeAsBytes(List.filled(5000, 1));
        await model.create(recursive: true);
      });
      containerOf(tester).invalidate(storageUseProvider);
      await settle(tester);
      await tester.scrollUntilVisible(find.text('Clear cache'), 200);
      await tester.tap(find.text('Clear cache'));
      await settle(tester, rounds: 2);
      expect(find.text('Clear the cache?'), findsOneWidget);
      await tester.tap(find.text('Clear'));
      await settle(tester);
      expect(thumb.existsSync(), isFalse);
      expect(model.existsSync(), isTrue);
    });

    testWidgets('caption models download and delete', (tester) async {
      await openSettings(tester);
      await tester.scrollUntilVisible(find.text('44 MB, not downloaded'), 200);
      await tester.tap(find.widgetWithText(AppTextButton, 'Download').first);
      await settleUntil(tester, find.text('44 MB, downloaded'));
      expect(env.models.installed, {CaptionModel.tiny.fileName});
      await tester.tap(find.widgetWithText(AppTextButton, 'Delete'));
      await settle(tester, rounds: 2);
      await tester.tap(find.widgetWithText(DestructiveButton, 'Delete'));
      await settle(tester);
      expect(env.models.installed, isEmpty);
      expect(find.text('44 MB, not downloaded'), findsOneWidget);
    });

    testWidgets('licenses list packages; the source link opens', (
      tester,
    ) async {
      LicenseRegistry.addLicense(
        () => Stream.value(
          const LicenseEntryWithLineBreaks(['stitch_test_pkg'], 'Test text'),
        ),
      );
      await openSettings(tester);
      await tester.scrollUntilVisible(find.text('Source code'), 200);
      await tester.tap(find.text('Source code'));
      await settle(tester);
      expect(env.system.opened, ['https://github.com/israelglory/stitch']);

      await tester.tap(find.text('Open source licenses'));
      await settle(tester);
      await tester.scrollUntilVisible(find.text('stitch_test_pkg'), 300);
      await tester.tap(find.text('stitch_test_pkg'));
      await settle(tester);
      expect(find.text('Test text'), findsOneWidget);
    });
  });

  testWidgets('export and settings fit a small screen with large text', (
    tester,
  ) async {
    env = await createEnv(tester);
    final id = await createProject(tester, env);
    await pumpApp(
      tester,
      env,
      location: AppRoutes.editor(id),
      size: const Size(320, 568),
      textScale: 2,
    );
    await settleUntil(tester, find.byType(VideoClipTile));
    await tester.tap(find.widgetWithText(PrimaryButton, 'Export'));
    await settle(tester);
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.widgetWithText(PrimaryButton, 'Export').last,
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.widgetWithText(PrimaryButton, 'Export').last);
    await settleUntil(tester, find.textContaining('Saved to'));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Back to editing'));
    await settle(tester);

    env.container.read(routerProvider).go(AppRoutes.settings);
    await settle(tester);
    await tester.scrollUntilVisible(find.text('Source code'), 300);
    expect(tester.takeException(), isNull);
    await finish(tester);
  });

  testWidgets('a missing clip file can be relinked', (tester) async {
    env = await createEnv(tester);
    final id = await createProject(tester, env, seconds: [3, 2]);
    // The first clip's copy disappears.
    final project = (await tester.runAsync(
      () => env.container.read(projectStoreProvider).load(id),
    ))!;
    final media = project.media[project.timeline.videoClips.first.mediaId]!;
    await tester.runAsync(
      () =>
          File(env.container.read(projectStoreProvider).resolve(id, media.path))
              .delete(),
    );
    final replacement = env.library.addVideo('new', seconds: 3);

    await pumpApp(tester, env, location: AppRoutes.editor(id));
    await settleUntil(tester, find.text('Some media files are missing.'));
    await tester.tap(find.text('Relink'));
    await settle(tester);
    final thumb = find.byWidgetPredicate(
      (w) => w is MediaThumbnail && w.onTap != null,
    );
    await settleUntil(tester, thumb);
    await tester.tap(thumb.first);
    await settleUntil(tester, find.byType(EditorScreen));
    await settle(tester);
    expect(find.text('Some media files are missing.'), findsNothing);
    final state = ProviderScope.containerOf(
      tester.element(find.byType(EditorScreen)),
    ).read(editorControllerProvider(id)).requireValue;
    expect(state.missingMedia, isEmpty);
    expect(replacement.id, isNotEmpty);
    await finish(tester);
  });
}
