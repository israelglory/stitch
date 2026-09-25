import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:stitch/core/hash/stable_key.dart';
import 'package:stitch/engine/editor_engine.dart';

/// Disk budget for waveforms; pruned at startup.
const int waveformCacheBytes = 20 * 1024 * 1024;

/// Peaks per second of source kept for each file.
const waveformPeaksPerSecond = 20;

/// Waveforms of sound files, from the engine, cached in memory and on
/// disk by file and modification time.
class WaveformCache {
  new(this.engine, this.directory);

  final EditorEngine engine;
  final Directory directory;

  // Insertion ordered: the first key is the least recently used.
  final _memory = <String, List<double>>{};
  final _inFlight = <String, Future<List<double>>>{};
  static const _memoryLimit = 64;

  /// Peaks of [path], [waveformPeaksPerSecond] a second; empty when it has
  /// no sound.
  Future<List<double>> peaks(String path) {
    final file = File(path);
    final stat = file.statSync();
    final key = stableKey(
      '$path|${stat.size}|${stat.modified.toIso8601String()}',
    );
    final cached = _memory.remove(key);
    if (cached != null) {
      _memory[key] = cached;
      return Future.value(cached);
    }
    // A block body: returning the removed future would make this one wait
    // for itself.
    return _inFlight[key] ??= _load(key, path).whenComplete(() {
      unawaited(_inFlight.remove(key));
    });
  }

  Future<List<double>> _load(String key, String path) async {
    final disk = File(p.join(directory.path, '$key.json'));
    List<double>? peaks;
    if (disk.existsSync()) {
      try {
        peaks = (jsonDecode(await disk.readAsString()) as List)
            .map((e) => (e as num).toDouble())
            .toList();
      } on FormatException {
        peaks = null;
      }
    }
    if (peaks == null) {
      peaks = await engine.waveform(
        path,
        peaksPerSecond: waveformPeaksPerSecond,
      );
      await directory.create(recursive: true);
      final temp = File('${disk.path}.part');
      await temp.writeAsString(
        jsonEncode([for (final v in peaks) (v * 1000).round() / 1000]),
      );
      await temp.rename(disk.path);
    }
    _memory[key] = peaks;
    while (_memory.length > _memoryLimit) {
      _memory.remove(_memory.keys.first);
    }
    return peaks;
  }
}
