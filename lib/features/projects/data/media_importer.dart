import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:path/path.dart' as p;
import 'package:stitch/core/async/cancellation.dart';
import 'package:stitch/core/errors/failure.dart';
import 'package:stitch/core/ids/ids.dart';
import 'package:stitch/core/logging/logger.dart';
import 'package:stitch/engine/editor_engine.dart';
import 'package:stitch/features/media/data/media_library.dart';
import 'package:stitch/features/media/domain/library_item.dart';
import 'package:stitch/features/projects/data/project_store.dart';
import 'package:stitch/features/projects/domain/project.dart';
import 'package:stitch/features/timeline/domain/models.dart';

/// Progress of an import.
final class ImportProgress {
  const new({required this.completed, required this.total, this.fraction = 0});

  /// Items fully imported.
  final int completed;
  final int total;

  /// Overall progress, 0 to 1.
  final double fraction;
}

const _log = Logger('import');

/// Sources with a longer side above this get a preview proxy.
const int _proxyAbove = 1920;

/// Longest side of stored posters, in pixels.
const int _posterSize = 720;

/// Copies picked library items into a project folder, so the project keeps
/// working when the gallery changes, and saves a poster frame for each.
///
/// The engine reads each copy for exact duration, size, and sound (the
/// gallery only knows whole seconds), and sources larger than 1080p get a
/// 720p proxy for smooth preview.
class MediaImporter {
  new({
    required this.store,
    required this.library,
    required this.engine,
    IdGenerator? ids,
    this.freeSpace,
  }) : ids = ids ?? RandomIdGenerator();

  final ProjectStore store;
  final MediaLibrary library;
  final EditorEngine engine;
  final IdGenerator ids;

  /// Bytes free where a path is; each copy checks first. Null skips the
  /// check.
  final Future<int> Function(String path)? freeSpace;

  /// Room to leave free after a copy, for the project and the system.
  static const int _spareBytes = 100 * 1000 * 1000;

  /// Imports [items] into [projectId] in order. Returns the new assets in
  /// the same order. On cancel or failure, files copied so far are removed
  /// and the error is rethrown ([CancelledFailure] on cancel).
  Future<List<MediaAsset>> import(
    String projectId,
    List<LibraryItem> items, {
    CancellationToken? cancel,
    void Function(ImportProgress progress)? onProgress,
  }) async {
    final created = <File>[];
    final assets = <MediaAsset>[];
    void report(int completed, double current) => onProgress?.call(
      ImportProgress(
        completed: completed,
        total: items.length,
        fraction: items.isEmpty ? 1 : (completed + current) / items.length,
      ),
    );

    try {
      report(0, 0);
      for (final (i, item) in items.indexed) {
        cancel?.throwIfCancelled();
        final source = await library.originalFile(item.id);
        if (source == null || !source.existsSync()) {
          throw MissingSourceFailure(item.id);
        }
        cancel?.throwIfCancelled();

        final mediaId = ids.next();
        final ext = p.extension(source.path).toLowerCase();
        final mediaPath = p.join('media', '$mediaId$ext');
        final target = File(store.resolve(projectId, mediaPath));
        if (freeSpace case final space?) {
          final needed = source.lengthSync() + _spareBytes;
          final free = await space(target.parent.path);
          if (free < needed) {
            throw InsufficientStorageFailure(
              requiredBytes: needed,
              availableBytes: free,
            );
          }
        }
        created.add(target);
        await _copy(
          source,
          target,
          cancel: cancel,
          onProgress: (f) => report(i, f * 0.8),
        );
        cancel?.throwIfCancelled();

        // Exact facts from the file; the gallery's are the fallback.
        MediaInfo? info;
        try {
          info = await engine.probe(target.path);
        } on Failure catch (e) {
          _log.warning('Probe failed for ${item.id}; using gallery values', e);
        }
        final width = info?.width ?? item.width;
        final height = info?.height ?? item.height;

        String? proxyPath;
        if (item.kind == MediaKind.video &&
            math.max(width, height) > _proxyAbove) {
          final path = p.join('proxies', '$mediaId.mp4');
          final file = File(store.resolve(projectId, path));
          created.add(file);
          await file.parent.create(recursive: true);
          try {
            await engine.createProxy(target.path, file.path);
            if (file.existsSync()) proxyPath = path;
          } on Failure catch (e) {
            // Preview falls back to the original; slower but correct.
            _log.warning('Proxy failed for ${item.id}', e);
          }
        }
        report(i, 0.95);

        String? posterPath;
        final poster = await library.thumbnail(
          item.id,
          width: _fit(item.width, item.height).$1,
          height: _fit(item.width, item.height).$2,
        );
        if (poster != null) {
          posterPath = p.join('posters', '$mediaId.jpg');
          final file = File(store.resolve(projectId, posterPath));
          created.add(file);
          await file.parent.create(recursive: true);
          await file.writeAsBytes(poster);
        }

        assets.add(
          MediaAsset(
            id: mediaId,
            kind: item.kind,
            path: mediaPath,
            width: width,
            height: height,
            durationUs: item.kind == MediaKind.photo
                ? null
                : info?.durationUs ?? item.durationUs,
            posterPath: posterPath,
            proxyPath: proxyPath,
            hasAudio: item.kind == MediaKind.video && (info?.hasAudio ?? true),
            displayName: p.basenameWithoutExtension(source.path),
          ),
        );
        report(i + 1, 0);
      }
      return assets;
    } on Object {
      for (final file in created) {
        if (file.existsSync()) await file.delete();
      }
      rethrow;
    }
  }

  /// Adds an audio file (picked, bundled, or recorded) to [projectId] as
  /// [name]. A file the app made for this ([move]) is moved in; anything
  /// else is copied. The engine measures it; a file without sound is
  /// refused with [UnsupportedMediaFailure].
  Future<MediaAsset> importAudio(
    String projectId, {
    required File source,
    required String name,
    bool move = false,
  }) async {
    if (!source.existsSync()) throw MissingSourceFailure(source.path);
    final mediaId = ids.next();
    final ext = p.extension(source.path).toLowerCase();
    final mediaPath = p.join('media', '$mediaId$ext');
    final target = File(store.resolve(projectId, mediaPath));
    await target.parent.create(recursive: true);
    if (move) {
      await source.rename(target.path);
    } else {
      await _copy(source, target, onProgress: (_) {});
    }
    try {
      final info = await engine.probe(target.path);
      if (!info.hasAudio || (info.durationUs ?? 0) <= 0) {
        throw UnsupportedMediaFailure(name);
      }
      return MediaAsset(
        id: mediaId,
        kind: MediaKind.audio,
        path: mediaPath,
        durationUs: info.durationUs,
        displayName: name,
      );
    } on Object {
      if (target.existsSync()) await target.delete();
      rethrow;
    }
  }

  static Future<void> _copy(
    File from,
    File to, {
    required void Function(double fraction) onProgress,
    CancellationToken? cancel,
  }) async {
    await to.parent.create(recursive: true);
    final total = await from.length();
    final sink = to.openWrite();
    var copied = 0;
    try {
      await for (final chunk in from.openRead()) {
        cancel?.throwIfCancelled();
        sink.add(chunk);
        copied += chunk.length;
        onProgress(total == 0 ? 1 : copied / total);
      }
      await sink.flush();
    } finally {
      await sink.close();
    }
  }

  /// [w] x [h] scaled so the longest side is at most [_posterSize].
  static (int, int) _fit(int w, int h) {
    if (w <= 0 || h <= 0) return (_posterSize, _posterSize);
    final scale = math.min(1, _posterSize / math.max(w, h));
    return ((w * scale).round(), (h * scale).round());
  }
}
