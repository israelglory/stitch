import 'dart:io';
import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:stitch/core/errors/failure.dart';
import 'package:stitch/core/platform/system_services.dart';
import 'package:stitch/core/storage/bytes.dart';
import 'package:stitch/engine/editor_engine.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';
import 'package:stitch/features/export/application/export_controller.dart';
import 'package:stitch/features/export/domain/export_options.dart';
import 'package:stitch/features/projects/application/import_controller.dart';
import 'package:stitch/features/projects/domain/project.dart';
import 'package:stitch/features/settings/data/settings_repository.dart';
import 'package:stitch/features/settings/domain/app_settings.dart';
import 'package:stitch/features/timeline/domain/caption_ops.dart';
import 'package:stitch/l10n/generated/app_localizations.dart';

import '../../helpers/app_scope.dart';
import '../../helpers/prefs.dart';

Future<(TestEnv, String)> _project() async {
  final env = await TestEnv.create();
  final id = await env.container
      .read(importControllerProvider.notifier)
      .createProject(
        name: 'Beach: day/1',
        preset: AspectPreset.portrait9x16,
        items: [env.library.addVideo('v', seconds: 10)],
      );
  final editor = env.container.listen(editorControllerProvider(id!), (_, _) {});
  addTearDown(editor.close);
  await env.container.read(editorControllerProvider(id).future);
  final export = env.container.listen(exportControllerProvider(id), (_, _) {});
  addTearDown(export.close);
  return (env, id);
}

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));
  group('options', () {
    test('size keeps the canvas shape, in even pixels', () {
      expect(exportSize(1080, 1920, ExportResolution.hd), (
        width: 720,
        height: 1280,
      ));
      expect(exportSize(1920, 1080, ExportResolution.uhd), (
        width: 3840,
        height: 2160,
      ));
      // 4:5 at 720p: 720 x 900.
      expect(exportSize(1080, 1350, ExportResolution.hd), (
        width: 720,
        height: 900,
      ));
      // An odd original shape rounds to even numbers.
      final odd = exportSize(1001, 1777, ExportResolution.fullHd);
      expect(odd.width.isEven && odd.height.isEven, isTrue);
      expect(odd.width, 1080);
    });

    test('bitrates follow the targets', () {
      const o = ExportOptions();
      expect(videoBitrate(o), 10000000);
      expect(
        videoBitrate(o.copyWith(resolution: ExportResolution.hd)),
        5000000,
      );
      expect(
        videoBitrate(o.copyWith(resolution: ExportResolution.uhd)),
        35000000,
      );
      expect(videoBitrate(o.copyWith(frameRate: 60)), 15000000);
      expect(videoBitrate(o.copyWith(frameRate: 24)), 8000000);
      expect(videoBitrate(o.copyWith(quality: ExportQuality.smaller)), 6000000);
      expect(videoBitrate(o.copyWith(hevc: true)), 7000000);
    });

    test('a minute at 1080p is about 78 MB', () {
      final bytes = estimatedExportBytes(const ExportOptions(), 60000000);
      expect(bytes, closeTo(78.0e6, 0.5e6));
      expect(formatBytes(l10n, bytes), '78 MB');
      expect(exportSpaceNeeded(bytes), bytes * 2 + 100000000);
    });

    test('file names are safe and dated', () {
      expect(
        exportFileName('Beach: day/1', DateTime(2026, 9, 25, 14, 3, 7)),
        'Beach day 1 2026-09-25 14.03.07',
      );
      expect(exportFileName('  ', DateTime(2026)), startsWith('Stitch 2026'));
    });

    test('bytes read like a phone shows them', () {
      expect(formatBytes(l10n, 0), '0 KB');
      expect(formatBytes(l10n, 820000), '820 KB');
      expect(formatBytes(l10n, 43537433), '44 MB');
      expect(formatBytes(l10n, 1234000000), '1.2 GB');
      expect(formatBytes(l10n, 12400000000), '12 GB');
    });
  });

  group('settings', () {
    test('read the defaults, then what was written', () async {
      final repo = SettingsRepository(await inMemoryPrefs());
      expect(repo.read(), const AppSettings());
      const changed = AppSettings(
        theme: ThemeChoice.light,
        export: ExportOptions(
          resolution: ExportResolution.hd,
          frameRate: 60,
          quality: ExportQuality.smaller,
        ),
        aspect: AspectPreset.square,
      );
      await repo.write(changed);
      expect(repo.read(), changed);
    });

    test('unknown stored values fall back to defaults', () async {
      final repo = SettingsRepository(
        await inMemoryPrefs({
          'settings.theme': 'purple',
          'settings.export.frameRate': 25,
        }),
      );
      expect(repo.read(), const AppSettings());
    });
  });

  group('export', () {
    test('exports at the chosen size, saves it, and writes captions', () async {
      final (env, id) = await _project();
      env.container
          .read(editorControllerProvider(id).notifier)
          .apply(
            (t) => t.setCaptions([
              (
                id: 'c',
                text: 'Hello',
                startUs: 0,
                endUs: 1000000,
                words: const [],
              ),
            ]),
          );
      await env.container
          .read(exportControllerProvider(id).notifier)
          .start(
            const ExportOptions(
              resolution: ExportResolution.hd,
              frameRate: 60,
              hevc: true,
              captionsFile: true,
            ),
            progressTitle: 'Exporting video',
          );

      final state = env.container.read(exportControllerProvider(id));
      expect(state, isA<ExportDone>());
      final done = state as ExportDone;
      expect(done.saved, GallerySave.saved);
      expect(env.system.saved, [done.path]);
      expect(p.basename(done.path), startsWith('Beach day 1 '));
      expect(File(done.captionsPath!).readAsStringSync(), contains('Hello'));

      final settings = env.engine.lastExport!;
      expect((settings.width, settings.height), (720, 1280));
      expect(settings.frameRate, 60);
      expect(settings.codec, VideoCodec.hevc);
      expect(settings.bitrate, 5250000);
      expect(settings.progressTitle, 'Exporting video');
      expect(env.system.screenKeptOn, isFalse);
    });

    test('not enough space stops it before it starts', () async {
      final (env, id) = await _project();
      env.system.free = 50 * 1000 * 1000;
      await env.container
          .read(exportControllerProvider(id).notifier)
          .start(const ExportOptions(), progressTitle: '');
      final state = env.container.read(exportControllerProvider(id));
      expect(
        (state as ExportFailed).failure,
        isA<InsufficientStorageFailure>(),
      );
      expect(env.engine.lastExport, isNull);
    });

    test('an engine failure can be retried', () async {
      final (env, id) = await _project();
      env.engine.exportFailure = const EngineFailure('export_failed');
      final export = env.container.read(exportControllerProvider(id).notifier);
      await export.start(const ExportOptions(), progressTitle: '');
      expect(
        env.container.read(exportControllerProvider(id)),
        isA<ExportFailed>(),
      );
      await export.retry();
      expect(
        env.container.read(exportControllerProvider(id)),
        isA<ExportDone>(),
      );
    });

    test(
      'cancel goes back to idle, with the screen allowed to sleep',
      () async {
        final (env, id) = await _project();
        final export = env.container.read(
          exportControllerProvider(id).notifier,
        );
        final running = export.start(const ExportOptions(), progressTitle: '');
        await Future<void>.delayed(const Duration(milliseconds: 120));
        expect(env.system.screenKeptOn, isTrue);
        await export.cancel();
        await running;
        expect(
          env.container.read(exportControllerProvider(id)),
          isA<ExportIdle>(),
        );
        expect(env.system.screenKeptOn, isFalse);
      },
    );

    test('refused access says so; saving again works once allowed', () async {
      final (env, id) = await _project();
      env.system.saveResult = GallerySave.denied;
      final export = env.container.read(exportControllerProvider(id).notifier);
      await export.start(const ExportOptions(), progressTitle: '');
      expect(
        (env.container.read(exportControllerProvider(id)) as ExportDone).saved,
        GallerySave.denied,
      );
      env.system.saveResult = GallerySave.saved;
      await export.saveAgain();
      expect(
        (env.container.read(exportControllerProvider(id)) as ExportDone).saved,
        GallerySave.saved,
      );
    });
  });
}
