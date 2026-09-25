import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stitch/app/providers.dart';
import 'package:stitch/core/errors/failure.dart';
import 'package:stitch/core/platform/system_services.dart';
import 'package:stitch/engine/editor_engine.dart';
import 'package:stitch/engine/engine_provider.dart';
import 'package:stitch/features/captions/domain/srt.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';
import 'package:stitch/features/export/domain/export_options.dart';
import 'package:stitch/features/timeline/domain/composition.dart';

part 'export_controller.g.dart';

/// Where an export stands.
sealed class ExportState {
  const new();
}

final class ExportIdle extends ExportState {
  const new();
}

final class ExportRunning extends ExportState {
  const new(this.fraction, {this.saving = false});

  /// 0 to 1.
  final double fraction;

  /// Encoding is done; the video is being copied to the photo library.
  final bool saving;
}

final class ExportDone extends ExportState {
  const new({required this.path, required this.saved, this.captionsPath});

  final String path;
  final GallerySave saved;

  /// The SRT file, when captions were exported too.
  final String? captionsPath;
}

final class ExportFailed extends ExportState {
  const new(this.failure);

  final Object failure;
}

/// Exports a project: checks space, keeps the screen on, renders, writes
/// the captions file if asked, then saves to the photo library. Lives
/// while the export screen shows it; leaving cancels.
@riverpod
class ExportController extends _$ExportController {
  ExportJob? _job;
  ExportOptions? _options;
  String _progressTitle = '';

  late SystemServices _system;

  @override
  ExportState build(String projectId) {
    final system = _system = ref.watch(systemServicesProvider);
    ref.onDispose(() {
      unawaited(_job?.cancel());
      unawaited(system.keepScreenOn(on: false));
    });
    return const ExportIdle();
  }

  /// [progressTitle] labels Android's progress notification.
  Future<void> start(
    ExportOptions options, {
    required String progressTitle,
  }) async {
    if (state is ExportRunning) return;
    _options = options;
    _progressTitle = progressTitle;
    state = const ExportRunning(0);
    try {
      final project = await ref
          .read(editorControllerProvider(projectId).notifier)
          .prepareForExport();
      final composition = ResolvedComposition.resolve(project.timeline);
      final size = exportSize(
        project.canvas.width,
        project.canvas.height,
        options.resolution,
      );
      final dir = Directory(
        p.join(ref.read(cacheRootProvider).path, 'exports'),
      );
      await dir.create(recursive: true);
      await ensureSpace(
        _system,
        dir.path,
        exportSpaceNeeded(
          estimatedExportBytes(options, composition.durationUs),
        ),
      );
      // Android shows progress in a notification; asked for once, here.
      await _system.requestNotifications();
      await _system.keepScreenOn(on: true);

      final path = p.join(
        dir.path,
        '${exportFileName(project.name, DateTime.now())}.mp4',
      );
      final job = _job = ref
          .read(editorEngineProvider)
          .export(
            ExportSettings(
              outputPath: path,
              width: size.width,
              height: size.height,
              frameRate: options.frameRate,
              bitrate: videoBitrate(options),
              codec: options.hevc ? VideoCodec.hevc : VideoCodec.h264,
              progressTitle: _progressTitle,
            ),
          );
      await for (final event in job.events) {
        if (event is ExportProgress && ref.mounted) {
          state = ExportRunning(event.fraction);
        }
      }
      _job = null;
      if (!ref.mounted) return;

      String? captionsPath;
      if (options.captionsFile && composition.captions.isNotEmpty) {
        captionsPath = p.setExtension(path, '.srt');
        await File(captionsPath).writeAsString(srtOf(composition.captions));
      }
      state = const ExportRunning(1, saving: true);
      final saved = await _system.saveVideo(path);
      if (ref.mounted) {
        state = ExportDone(
          path: path,
          saved: saved,
          captionsPath: captionsPath,
        );
      }
    } on CancelledFailure {
      if (ref.mounted) state = const ExportIdle();
    } on Object catch (e) {
      if (ref.mounted) state = ExportFailed(e);
    } finally {
      _job = null;
      await _system.keepScreenOn(on: false);
    }
  }

  /// Runs the last export again.
  Future<void> retry() async {
    final options = _options;
    if (options == null) return;
    state = const ExportIdle();
    await start(options, progressTitle: _progressTitle);
  }

  Future<void> cancel() async {
    await _job?.cancel();
  }

  /// Tries saving to the photo library again (after access was given).
  Future<void> saveAgain() async {
    final done = state;
    if (done is! ExportDone) return;
    final saved = await _system.saveVideo(done.path);
    if (ref.mounted) {
      state = ExportDone(
        path: done.path,
        saved: saved,
        captionsPath: done.captionsPath,
      );
    }
  }
}

/// A file name from the project's name and [time], safe everywhere:
/// "Beach day 2026-09-25 14.03.07".
String exportFileName(String projectName, DateTime time) {
  final name = projectName
      .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1f]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  String two(int n) => n.toString().padLeft(2, '0');
  final stamp =
      '${time.year}-${two(time.month)}-${two(time.day)} '
      '${two(time.hour)}.${two(time.minute)}.${two(time.second)}';
  return '${name.isEmpty ? 'Stitch' : name} $stamp';
}
