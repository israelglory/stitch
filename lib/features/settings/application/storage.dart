import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stitch/app/providers.dart';
import 'package:stitch/features/captions/application/caption_providers.dart';
import 'package:stitch/features/editor/application/filmstrip.dart';
import 'package:stitch/features/text/application/text_providers.dart';

part 'storage.g.dart';

/// Space the app uses, in bytes.
typedef StorageUse = ({int projects, int cache, int models});

/// Cache folders Clear cache keeps: caption models (downloaded, not made
/// again), and the sound of a caption job that may be running.
const _keptInCache = {'models', 'speech'};

/// Measured on a background isolate; refresh by invalidating.
@riverpod
Future<StorageUse> storageUse(Ref ref) async {
  final projects = p.join(ref.watch(storageRootProvider).path, 'projects');
  final cache = ref.watch(cacheRootProvider).path;
  final models = ref.watch(captionModelStoreProvider).directory.path;
  return await Isolate.run(
    () => (
      projects: _size(projects),
      cache: _size(cache, skip: _keptInCache),
      models: _size(models),
    ),
  );
}

int _size(String path, {Set<String> skip = const {}}) {
  final dir = Directory(path);
  if (!dir.existsSync()) return 0;
  var total = 0;
  for (final entry in dir.listSync(followLinks: false)) {
    if (skip.contains(p.basename(entry.path))) continue;
    if (entry is File) {
      total += entry.lengthSync();
    } else if (entry is Directory) {
      total += _size(entry.path);
    }
  }
  return total;
}

/// Deletes what the app can make again: thumbnails, waveforms, drawn
/// text, and exported copies (saved videos stay in the gallery). Keeps
/// caption models.
class CacheCleaner {
  const new(this._cache, this._forget);

  final Directory _cache;

  /// Drops what is kept in memory about files that are gone now.
  final void Function() _forget;

  Future<void> clear() async {
    if (_cache.existsSync()) {
      for (final entry in _cache.listSync(followLinks: false)) {
        if (_keptInCache.contains(p.basename(entry.path))) continue;
        try {
          await entry.delete(recursive: true);
        } on FileSystemException {
          // In use or already gone; the rest still clears.
        }
      }
    }
    _forget();
  }
}

@Riverpod(keepAlive: true)
CacheCleaner cacheCleaner(Ref ref) {
  final filmstrip = ref.watch(filmstripProvider);
  final rasterizer = ref.watch(textRasterizerProvider);
  return CacheCleaner(ref.watch(cacheRootProvider), () {
    filmstrip.forget();
    rasterizer.forget();
  });
}
