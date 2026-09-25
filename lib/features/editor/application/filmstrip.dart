import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stitch/app/providers.dart';
import 'package:stitch/engine/editor_engine.dart';
import 'package:stitch/engine/engine_provider.dart';

part 'filmstrip.g.dart';

/// Largest filmstrip cache on disk; pruned at startup.
const int filmstripCacheBytes = 150 * 1024 * 1024;

/// Frames are requested on this grid so zooming and scrolling reuse them.
const int _gridUs = 250000;

/// Longest side of a filmstrip frame, in pixels.
const int _frameSize = 160;

/// Timeline filmstrip frames. Requests arriving in the same frame are
/// batched into one engine call per file; results are cached in memory
/// (futures) and on disk (JPEGs, pruned by size).
class Filmstrip {
  new(this._engine, this.dir);

  final EditorEngine _engine;
  final Directory dir;
  final _frames = <String, Future<String?>>{};
  final _pending = <String, Map<int, Completer<String?>>>{};
  Timer? _flush;

  /// Path of a frame of [mediaPath] near [timeUs], or null when none can be
  /// made (the caller shows the poster instead).
  Future<String?> frame(String mediaPath, int timeUs) {
    final t = (timeUs / _gridUs).round() * _gridUs;
    final key = '$mediaPath@$t';
    final known = _frames.remove(key);
    if (known != null) return _frames[key] = known;
    final completer = Completer<String?>();
    (_pending[mediaPath] ??= {})[t] = completer;
    _flush ??= Timer(Duration.zero, _send);
    final future = _frames[key] = completer.future;
    // A frame that could not be made (the engine busy exporting, say) is
    // asked for again next time, not remembered as missing.
    unawaited(
      future.then((path) {
        if (path == null && identical(_frames[key], future)) {
          unawaited(_frames.remove(key));
        }
      }),
    );
    // Most recent last; the oldest go past the limit.
    while (_frames.length > _memoryLimit) {
      unawaited(_frames.remove(_frames.keys.first));
    }
    return future;
  }

  /// Frames remembered in memory (their files stay on disk).
  static const _memoryLimit = 4000;

  /// Forgets frames made earlier (their files were deleted).
  void forget() => _frames.clear();

  Future<void> _send() async {
    _flush = null;
    final batch = Map.of(_pending);
    _pending.clear();
    for (final MapEntry(key: path, value: requests) in batch.entries) {
      final times = requests.keys.toList();
      List<String?> paths;
      try {
        paths = await _engine.thumbnails(
          path,
          times,
          maxSize: _frameSize,
          outDir: dir.path,
        );
      } on Object {
        paths = List.filled(times.length, null);
      }
      for (final (i, t) in times.indexed) {
        requests[t]!.complete(i < paths.length ? paths[i] : null);
      }
    }
  }
}

@Riverpod(keepAlive: true)
Filmstrip filmstrip(Ref ref) => Filmstrip(
  ref.watch(editorEngineProvider),
  Directory(p.join(ref.watch(cacheRootProvider).path, 'filmstrip')),
);
