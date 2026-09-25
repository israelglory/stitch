import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/core/errors/failure.dart';
import 'package:stitch/features/captions/data/caption_models.dart';

/// Serves [content] with support for ranges, like the model host.
class _Server {
  new(this.content);

  final Uint8List content;
  late final HttpServer server;
  final ranges = <String?>[];

  /// Stops after this many bytes of the next response, then hangs.
  int? stallAfter;
  int status = HttpStatus.ok;

  Future<void> start() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final range = request.headers.value(HttpHeaders.rangeHeader);
      ranges.add(range);
      final response = request.response;
      if (status != HttpStatus.ok) {
        response.statusCode = status;
        await response.close();
        return;
      }
      var from = 0;
      if (range != null) {
        from = int.parse(RegExp(r'bytes=(\d+)-').firstMatch(range)!.group(1)!);
        response.statusCode = HttpStatus.partialContent;
      }
      final body = content.sublist(from);
      response.contentLength = body.length;
      final stall = stallAfter;
      if (stall != null) {
        stallAfter = null;
        response.add(body.sublist(0, stall));
        await response.flush();
        return; // never finishes
      }
      response.add(body);
      await response.close();
    });
  }

  ModelFile file({String? sha}) => ModelFile(
    fileName: 'model.bin',
    bytes: content.length,
    sha256: sha ?? sha256.convert(content).toString(),
    url: Uri.parse('http://127.0.0.1:${server.port}/model.bin'),
  );
}

void main() {
  late Directory dir;
  late _Server server;
  late CaptionModelStore store;

  setUp(() async {
    // flutter_test answers every request with 400 unless this is cleared;
    // these requests go to a local server.
    HttpOverrides.global = null;
    dir = Directory.systemTemp.createTempSync('models');
    final random = Random(1);
    server = _Server(
      Uint8List.fromList([
        for (var i = 0; i < 300000; i++) random.nextInt(256),
      ]),
    );
    await server.start();
    store = CaptionModelStore(dir);
  });

  tearDown(() async {
    await server.server.close(force: true);
    dir.deleteSync(recursive: true);
  });

  test('downloads, checks, and installs', () async {
    final model = server.file();
    expect(store.isInstalled(model), isFalse);
    final download = store.download(model);
    final progress = <double>[];
    download.progress.listen(progress.add);
    await download.done;
    expect(store.isInstalled(model), isTrue);
    expect(store.file(model).readAsBytesSync(), server.content);
    expect(progress.last, 1);
    expect(progress, orderedEquals([...progress]..sort()));
  });

  test('a download that does not match its checksum is thrown away', () async {
    final model = server.file(sha: '0' * 64);
    await expectLater(
      store.download(model).done,
      throwsA(isA<DownloadFailure>()),
    );
    expect(store.isInstalled(model), isFalse);
    expect(dir.listSync(), isEmpty);
  });

  test('cancel keeps what arrived, and the next download resumes', () async {
    final model = server.file();
    server.stallAfter = 100000;
    final first = store.download(model);
    await first.progress.firstWhere((p) => p > 0.3);
    await first.cancel();
    await expectLater(first.done, throwsA(isA<CancelledFailure>()));
    expect(File('${store.file(model).path}.part').lengthSync(), 100000);

    await store.download(model).done;
    expect(server.ranges.last, 'bytes=100000-');
    expect(store.file(model).readAsBytesSync(), server.content);
  });

  test('a server error fails the download', () async {
    server.status = HttpStatus.notFound;
    await expectLater(
      store.download(server.file()).done,
      throwsA(isA<DownloadFailure>()),
    );
  });

  test('delete removes the model and any partial download', () async {
    final model = server.file();
    await store.download(model).done;
    await store.delete(model);
    expect(store.isInstalled(model), isFalse);
    expect(dir.listSync(), isEmpty);
  });
}
