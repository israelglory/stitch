import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:stitch/core/errors/failure.dart';

/// A file to download: where from, and what it must be. [bytes] and
/// [sha256] are checked when known.
final class RemoteFile {
  const new({required this.urls, this.bytes, this.sha256});

  /// Tried in order: the first that answers is used (mirrors after it).
  final List<Uri> urls;
  final int? bytes;
  final String? sha256;
}

/// A running download. [done] fails with [CancelledFailure] after [cancel]
/// (once what arrived is saved), or [DownloadFailure].
final class FileDownload {
  const new({required this.progress, required this.done, required this.cancel});

  /// 0 to 1, in whole percents (when the size is known); closes when done.
  final Stream<double> progress;
  final Future<void> done;
  final Future<void> Function() cancel;
}

/// Downloads [remote] to [target]: into `<target>.part` first, which an
/// interrupted download resumes from, then checked and renamed into place.
FileDownload downloadFile(
  RemoteFile remote,
  File target, {
  HttpClient Function() client = HttpClient.new,
}) {
  final progress = StreamController<double>();
  var cancelled = false;
  HttpClient? http;
  StreamSubscription<List<int>>? body;
  Completer<void>? receiving;
  final finished = Completer<void>();
  final part = File('${target.path}.part');
  final expected = remote.bytes;

  Future<HttpClientResponse> open(int have) async {
    Object? last;
    for (final url in remote.urls) {
      try {
        http?.close(force: true);
        http = client()..connectionTimeout = const Duration(seconds: 20);
        final request = await http!.getUrl(url);
        if (have > 0) {
          request.headers.set(HttpHeaders.rangeHeader, 'bytes=$have-');
        }
        final response = await request.close();
        if (response.statusCode == HttpStatus.ok ||
            response.statusCode == HttpStatus.partialContent) {
          return response;
        }
        last = 'HTTP ${response.statusCode}';
        await response.drain<void>();
      } on Object catch (e) {
        if (cancelled) rethrow;
        last = e;
      }
    }
    throw DownloadFailure(cause: last ?? 'No address');
  }

  Future<void> run() async {
    await target.parent.create(recursive: true);
    var have = part.existsSync() ? part.lengthSync() : 0;
    if (expected != null && have > expected) {
      await part.delete();
      have = 0;
    }
    if (expected == null || have < expected) {
      final response = await open(have);
      if (cancelled) throw const CancelledFailure();
      final resumed = response.statusCode == HttpStatus.partialContent;
      if (!resumed) have = 0;
      final total =
          expected ??
          (response.contentLength >= 0 ? have + response.contentLength : null);
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
            if (total == null || total == 0) return;
            final percent = have * 100 ~/ total;
            if (percent > reported) {
              reported = percent;
              progress.add((have / total).clamp(0, 1).toDouble());
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
    if (expected != null && part.lengthSync() != expected) {
      await part.delete();
      throw const DownloadFailure(cause: 'Size mismatch');
    }
    if (remote.sha256 case final want?) {
      final digest = await sha256.bind(part.openRead()).first;
      if (digest.toString() != want) {
        await part.delete();
        throw const DownloadFailure(cause: 'Checksum mismatch');
      }
    }
    await part.rename(target.path);
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
          http?.close(force: true);
          unawaited(progress.close());
        }),
  );

  return FileDownload(
    progress: progress.stream,
    done: finished.future,
    cancel: () async {
      if (cancelled || finished.isCompleted) return;
      cancelled = true;
      // What arrived so far stays, to resume from.
      await body?.cancel();
      http?.close(force: true);
      // The download then closes its file and reports the cancel.
      if (receiving case final r? when !r.isCompleted) r.complete();
    },
  );
}
