import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/core/errors/failure.dart';
import 'package:stitch/features/audio/data/sound_library.dart';

/// A local server for [files] (path to bytes). Paths in [failing] answer
/// 500; [requests] records each request's path and Range header.
Future<HttpServer> serve(
  Map<String, List<int>> files, {
  Set<String> failing = const {},
  List<(String, String?)>? requests,
}) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) async {
    final path = request.uri.path;
    requests?.add((path, request.headers.value(HttpHeaders.rangeHeader)));
    final data = files[path];
    final response = request.response;
    if (failing.contains(path) || data == null) {
      response.statusCode = failing.contains(path) ? 500 : 404;
      await response.close();
      return;
    }
    final range = request.headers.value(HttpHeaders.rangeHeader);
    var start = 0;
    if (range != null) {
      start = int.parse(RegExp(r'bytes=(\d+)-').firstMatch(range)!.group(1)!);
      response.statusCode = HttpStatus.partialContent;
    }
    response
      ..contentLength = data.length - start
      ..add(data.sublist(start));
    await response.close();
  });
  return server;
}

Map<String, Object> entry(
  String id,
  List<int> bytes, {
  String kind = 'effect',
}) => {
  'id': id,
  'kind': kind,
  'category': 'ui',
  'title': 'Sound $id',
  'artist': 'Kenney',
  'license': 'CC0-1.0',
  'source': 'https://kenney.nl',
  'file': 'effects/$id.m4a',
  'bytes': bytes.length,
  'sha256': sha256.convert(bytes).toString(),
  'durationUs': 1000000,
  if (kind == 'music') 'preview': 'previews/$id.m4a',
};

void main() {
  // The test binding answers every request with 400; these talk to a
  // server on this machine.
  setUpAll(() => HttpOverrides.global = null);
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('stitch_sounds'));
  tearDown(() => dir.deleteSync(recursive: true));

  group('catalog', () {
    test('reads sounds and skips what it cannot use', () {
      final catalog = SoundCatalog.parse(
        jsonEncode({
          'version': 1,
          'baseUrl': 'https://archive.org/download/stitch-sound-library/',
          'mirrors': ['https://example.org/mirror/'],
          'sounds': [
            entry('pop', [1, 2, 3]),
            {
              ...entry('bad', [1]),
              'id': '../escape',
            },
            {
              ...entry('weird', [1]),
              'kind': 'video',
            },
            {
              ...entry('path', [1]),
              'file': '../../etc/passwd',
            },
          ],
        }),
      )!;
      expect(catalog.sounds.map((s) => s.id), ['pop']);
      expect(
        catalog.remote(catalog.sounds.single).urls.map((u) => u.toString()),
        [
          'https://archive.org/download/stitch-sound-library/effects/pop.m4a',
          'https://example.org/mirror/effects/pop.m4a',
        ],
      );
    });

    test('rejects newer formats and insecure addresses', () {
      String doc(int version, String base) => jsonEncode({
        'version': version,
        'baseUrl': base,
        'sounds': <Object>[],
      });
      expect(SoundCatalog.parse(doc(2, 'https://a.org/x/')), isNull);
      expect(SoundCatalog.parse(doc(1, 'http://a.org/x/')), isNull);
      expect(SoundCatalog.parse(doc(1, 'http://localhost:1/x/')), isNotNull);
      expect(SoundCatalog.parse('not json'), isNull);
    });
  });

  group('store', () {
    final pop = List<int>.generate(50000, (i) => i % 251);
    final song = List<int>.generate(80000, (i) => i % 241);
    final clip = List<int>.generate(9000, (i) => i % 239);
    late HttpServer server;
    late SoundCatalog catalog;
    late List<(String, String?)> requests;

    Future<void> start({Set<String> failing = const {}}) async {
      requests = [];
      server = await serve(
        {
          '/lib/effects/pop.m4a': pop,
          '/lib/effects/song.m4a': song,
          '/lib/previews/song.m4a': clip,
          '/mirror/effects/pop.m4a': pop,
        },
        failing: failing,
        requests: requests,
      );
      final base = 'http://127.0.0.1:${server.port}';
      catalog = SoundCatalog.parse(
        jsonEncode({
          'version': 1,
          'baseUrl': '$base/lib/',
          'mirrors': ['$base/mirror/'],
          'sounds': [entry('pop', pop), entry('song', song, kind: 'music')],
        }),
      )!;
    }

    tearDown(() => server.close(force: true));

    test('downloads, checks, and deletes a sound', () async {
      await start();
      final store = SoundLibraryStore(dir);
      final sound = catalog.sounds.first;
      expect(store.isDownloaded(sound), isFalse);
      final download = store.download(catalog, sound);
      final progress = <double>[];
      download.progress.listen(progress.add);
      await download.done;
      expect(store.isDownloaded(sound), isTrue);
      expect(store.file(sound).readAsBytesSync(), pop);
      expect(progress.last, 1);
      expect(store.downloadedBytes(), pop.length);
      await store.delete(sound);
      expect(store.isDownloaded(sound), isFalse);
    });

    test('resumes from what arrived before', () async {
      await start();
      final store = SoundLibraryStore(dir);
      final sound = catalog.sounds.first;
      File('${store.file(sound).path}.part')
        ..createSync(recursive: true)
        ..writeAsBytesSync(pop.sublist(0, 20000));
      await store.download(catalog, sound).done;
      expect(store.file(sound).readAsBytesSync(), pop);
      expect(requests.single.$2, 'bytes=20000-');
    });

    test('falls back to a mirror', () async {
      await start(failing: {'/lib/effects/pop.m4a'});
      final store = SoundLibraryStore(dir);
      await store.download(catalog, catalog.sounds.first).done;
      expect(store.isDownloaded(catalog.sounds.first), isTrue);
      expect(requests.map((r) => r.$1), [
        '/lib/effects/pop.m4a',
        '/mirror/effects/pop.m4a',
      ]);
    });

    test('a damaged file is thrown away', () async {
      await start();
      final store = SoundLibraryStore(dir);
      final wrong = SoundCatalog.parse(
        jsonEncode({
          'version': 1,
          'baseUrl': catalog.baseUrls.first.toString(),
          'sounds': [
            {...entry('pop', pop), 'sha256': '0' * 64},
          ],
        }),
      )!;
      await expectLater(
        store.download(wrong, wrong.sounds.single).done,
        throwsA(isA<DownloadFailure>()),
      );
      expect(store.isDownloaded(wrong.sounds.single), isFalse);
      expect(
        File('${store.file(wrong.sounds.single).path}.part').existsSync(),
        isFalse,
      );
    });

    test('music previews with its clip; effects with themselves', () async {
      await start();
      final store = SoundLibraryStore(dir);
      final song = catalog.sounds.last;
      final preview = await store.previewFile(catalog, song);
      expect(preview.readAsBytesSync(), clip);
      expect(store.isDownloaded(song), isFalse);
      final effect = await store.previewFile(catalog, catalog.sounds.first);
      expect(effect.path, store.file(catalog.sounds.first).path);
      expect(store.isDownloaded(catalog.sounds.first), isTrue);
      await store.deleteAll();
      expect(store.downloadedBytes(), 0);
    });

    test('fetches and keeps the newest catalog', () async {
      await start();
      final store = SoundLibraryStore(dir);
      expect(store.savedCatalog(), isNull);
      // Nothing published at /lib/catalog.json or the mirror: none.
      expect(await store.fetchCatalog(catalog), isNull);
      await server.close(force: true);
      final next = jsonEncode({
        'version': 1,
        'baseUrl': catalog.baseUrls.first.toString().replaceFirst(
          RegExp(r':\d+/'),
          ':0/',
        ),
        'sounds': [entry('pop', pop)],
      });
      server = await serve({});
      final served = await serve({'/lib/catalog.json': utf8.encode(next)});
      final known = SoundCatalog.parse(
        jsonEncode({
          'version': 1,
          'baseUrl': 'http://127.0.0.1:${served.port}/lib/',
          'sounds': <Object>[],
        }),
      )!;
      final fresh = await store.fetchCatalog(known);
      expect(fresh?.sounds.single.id, 'pop');
      expect(store.savedCatalog()?.sounds.single.id, 'pop');
      await served.close(force: true);
    });
  });
}
