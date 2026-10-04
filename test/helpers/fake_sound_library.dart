import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:stitch/core/errors/failure.dart';
import 'package:stitch/core/network/file_download.dart';
import 'package:stitch/features/audio/data/sound_library.dart';

/// The bytes the fake serves for sound [id].
List<int> fakeSoundBytes(String id) => utf8.encode('sound:$id' * 40);

/// A small catalog: two music tracks and two effects.
String fakeSoundCatalog() {
  Map<String, Object> entry(
    String id,
    String kind,
    String category,
    String title,
    String artist,
  ) {
    final bytes = fakeSoundBytes(id);
    return {
      'id': id,
      'kind': kind,
      'category': category,
      'title': title,
      'artist': artist,
      'license': 'CC0-1.0',
      'source': 'https://archive.org/details/$id',
      'file': '$kind/$id.m4a',
      'bytes': bytes.length,
      'sha256': sha256.convert(bytes).toString(),
      'durationUs': 95000000,
      if (kind == 'music') 'preview': 'previews/$id.m4a',
    };
  }

  return jsonEncode({
    'version': 1,
    'baseUrl': 'https://archive.org/download/stitch-sound-library/',
    'sounds': [
      entry(
        'party_time',
        'music',
        'upbeat',
        'Party time',
        'Loyalty Freak Music',
      ),
      entry('old_key', 'music', 'calm', 'Old Key', 'Loyalty Freak Music'),
      entry('rain', 'effect', 'nature', 'Rain', 'Anthousai'),
      entry('boing', 'effect', 'funny', 'Boing', 'juicyarmstrong'),
    ],
  });
}

/// Downloads that write [fakeSoundBytes] after a short wait, on disk in
/// the test's folder. Never touches the network; the newest catalog is
/// never found.
class FakeSoundLibraryStore extends SoundLibraryStore {
  new(super.directory);

  /// Ids downloaded, in order.
  final downloads = <String>[];

  /// The next download fails with this.
  Object? failNext;

  @override
  FileDownload download(SoundCatalog catalog, LibrarySound sound) {
    downloads.add(sound.id);
    final progress = StreamController<double>();
    final done = Completer<void>();
    final failure = failNext;
    failNext = null;
    unawaited(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (done.isCompleted) return;
      progress.add(0.5);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (done.isCompleted) return;
      if (failure != null) {
        done.completeError(failure);
      } else {
        file(sound)
          ..createSync(recursive: true)
          ..writeAsBytesSync(fakeSoundBytes(sound.id));
        progress.add(1);
        done.complete();
      }
      await progress.close();
    }());
    return FileDownload(
      progress: progress.stream,
      done: done.future,
      cancel: () async {
        if (!done.isCompleted) done.completeError(const CancelledFailure());
        await progress.close();
      },
    );
  }

  @override
  Future<File> previewFile(SoundCatalog catalog, LibrarySound sound) async {
    if (sound.preview == null) {
      if (!isDownloaded(sound)) await download(catalog, sound).done;
      return file(sound);
    }
    return File('${directory.path}/previews/${sound.id}.m4a')
      ..createSync(recursive: true)
      ..writeAsBytesSync(fakeSoundBytes('preview'));
  }

  @override
  Future<SoundCatalog?> fetchCatalog(SoundCatalog known) async => null;
}
