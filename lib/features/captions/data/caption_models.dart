import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:stitch/core/errors/failure.dart';

/// Speech recognition models, downloaded on first use. whisper.cpp's
/// multilingual models, 8-bit quantized: about half the size of the full
/// ones with nearly the same accuracy. MIT licensed.
enum CaptionModel {
  /// Faster; good for clear speech.
  tiny(
    fileName: 'ggml-tiny-q8_0.bin',
    bytes: 43537433,
    sha256: 'c2085835d3f50733e2ff6e4b41ae8a2b8d8110461e18821b09a15c40c42d1cca',
  ),

  /// Slower; better with accents and noise.
  base(
    fileName: 'ggml-base-q8_0.bin',
    bytes: 81768585,
    sha256: 'c577b9a86e7e048a0b7eada054f4dd79a56bbfa911fbdacf900ac5b567cbb7d9',
  );

  new({required this.fileName, required this.bytes, required this.sha256});

  final String fileName;
  final int bytes;
  final String sha256;

  /// Pinned to one revision of the model repository; the hash is checked
  /// after every download all the same.
  static const _revision = '5359861c739e955e79d9a303bcbc70fb988958b1';

  ModelFile get file => ModelFile(
    fileName: fileName,
    bytes: bytes,
    sha256: sha256,
    url: Uri.https(
      'huggingface.co',
      '/ggerganov/whisper.cpp/resolve/$_revision/$fileName',
    ),
  );
}

/// A file to download: where from, and what it must be.
final class ModelFile {
  const new({
    required this.fileName,
    required this.bytes,
    required this.sha256,
    required this.url,
  });

  final String fileName;
  final int bytes;
  final String sha256;
  final Uri url;
}

/// A running model download. [done] fails with [CancelledFailure] after
/// [cancel] (once what arrived is saved), or [DownloadFailure].
final class ModelDownload {
  const new({required this.progress, required this.done, required this.cancel});

  /// 0 to 1; closes when done.
  final Stream<double> progress;
  final Future<void> done;
  final Future<void> Function() cancel;
}

/// Caption models on disk, and their downloads: the app's only network
/// use. An interrupted download resumes where it stopped.
class CaptionModelStore {
  new(this.directory, {HttpClient Function()? client})
    : _client = client ?? HttpClient.new;

  final Directory directory;
  final HttpClient Function() _client;

  File file(ModelFile model) => File(p.join(directory.path, model.fileName));

  File _part(ModelFile model) => File('${file(model).path}.part');

  bool isInstalled(ModelFile model) {
    final f = file(model);
    return f.existsSync() && f.lengthSync() == model.bytes;
  }

  /// Space the installed models take.
  int installedBytes() => [
    for (final m in CaptionModel.values)
      if (isInstalled(m.file)) m.bytes,
  ].fold(0, (a, b) => a + b);

  Future<void> delete(ModelFile model) async {
    for (final f in [file(model), _part(model)]) {
      if (f.existsSync()) await f.delete();
    }
  }

  ModelDownload download(ModelFile model) {
    final progress = StreamController<double>();
    var cancelled = false;
    HttpClient? client;
    StreamSubscription<List<int>>? body;
    Completer<void>? receiving;
    final finished = Completer<void>();

    Future<void> run() async {
      await directory.create(recursive: true);
      final part = _part(model);
      var have = part.existsSync() ? part.lengthSync() : 0;
      if (have > model.bytes) {
        await part.delete();
        have = 0;
      }
      if (have < model.bytes) {
        client = _client();
        final request = await client!.getUrl(model.url);
        if (have > 0) {
          request.headers.set(HttpHeaders.rangeHeader, 'bytes=$have-');
        }
        final response = await request.close();
        if (cancelled) throw const CancelledFailure();
        final resumed = response.statusCode == HttpStatus.partialContent;
        if (!resumed && response.statusCode != HttpStatus.ok) {
          throw DownloadFailure(cause: 'HTTP ${response.statusCode}');
        }
        if (!resumed) have = 0;
        final sink = part.openWrite(
          mode: resumed ? FileMode.append : FileMode.write,
        );
        var reported = -1;
        try {
          final received = receiving = Completer<void>();
          body = response.listen(
            (chunk) {
              sink.add(chunk);
              have += chunk.length;
              final percent = have * 100 ~/ model.bytes;
              if (percent > reported) {
                reported = percent;
                progress.add(have / model.bytes);
              }
            },
            onError: received.completeError,
            onDone: received.complete,
            cancelOnError: true,
          );
          await received.future;
        } finally {
          await sink.close();
        }
        if (cancelled) throw const CancelledFailure();
      }
      final digest = await sha256.bind(part.openRead()).first;
      if (digest.toString() != model.sha256) {
        await part.delete();
        throw const DownloadFailure(cause: 'Checksum mismatch');
      }
      await part.rename(file(model).path);
      progress.add(1);
    }

    unawaited(
      run()
          .then((_) {
            if (!finished.isCompleted) finished.complete();
          })
          .catchError((Object e, StackTrace st) {
            if (finished.isCompleted) return;
            finished.completeError(switch (e) {
              _ when cancelled => const CancelledFailure(),
              Failure() => e,
              _ => DownloadFailure(cause: e, stackTrace: st),
            }, st);
          })
          .whenComplete(() {
            client?.close(force: true);
            unawaited(progress.close());
          }),
    );

    return ModelDownload(
      progress: progress.stream,
      done: finished.future,
      cancel: () async {
        if (cancelled || finished.isCompleted) return;
        cancelled = true;
        // What arrived so far stays, to resume from.
        await body?.cancel();
        client?.close(force: true);
        // The download then closes its file and reports the cancel.
        if (receiving case final r? when !r.isCompleted) r.complete();
      },
    );
  }
}
