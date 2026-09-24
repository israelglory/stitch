import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/core/async/cancellation.dart';
import 'package:stitch/core/errors/failure.dart';
import 'package:stitch/core/ids/ids.dart';
import 'package:stitch/engine/editor_engine.dart';
import 'package:stitch/engine/fake_editor_engine.dart';
import 'package:stitch/features/projects/data/media_importer.dart';
import 'package:stitch/features/projects/data/project_store.dart';
import 'package:stitch/features/projects/domain/project.dart';
import 'package:stitch/features/timeline/domain/models.dart';

import '../../helpers/fake_media_library.dart';

void main() {
  late Directory root;
  late ProjectStore store;
  var minutes = 0;

  setUp(() {
    root = Directory.systemTemp.createTempSync('store_test');
    minutes = 0;
    store = ProjectStore(
      root: root,
      ids: SequentialIdGenerator('p'),
      clock: () => DateTime.utc(2026, 9, 24).add(Duration(minutes: minutes++)),
    );
  });
  tearDown(() => root.deleteSync(recursive: true));

  final canvas = ProjectCanvas.forPreset(AspectPreset.portrait9x16);

  group('ProjectStore', () {
    test('creates, lists newest first, and loads', () async {
      final a = await store.create(name: 'A', canvas: canvas);
      final b = await store.create(name: 'B', canvas: canvas);
      final list = await store.list();
      expect(list.map((s) => s.name), ['B', 'A']);
      expect(await store.load(a.id), a);
      expect(await store.load(b.id), b);
    });

    test('save updates the summary', () async {
      final p = await store.create(name: 'A', canvas: canvas);
      await store.save(
        p.copyWith(
          media: {
            'm': const MediaAsset(
              id: 'm',
              kind: MediaKind.video,
              path: 'media/m.mp4',
              posterPath: 'posters/m.jpg',
              durationUs: 3000000,
            ),
          },
          timeline: Timeline(
            videoClips: [
              VideoClip.video(id: 'c', mediaId: 'm', mediaDurationUs: 3000000),
            ],
          ),
        ),
      );
      final summary = (await store.list()).single;
      expect(summary.durationUs, 3000000);
      expect(summary.posterPath, 'posters/m.jpg');
    });

    test('writes atomically: no temp files are left behind', () async {
      final p = await store.create(name: 'A', canvas: canvas);
      await store.save(p.copyWith(name: 'B'));
      final leftovers = root
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.tmp'));
      expect(leftovers, isEmpty);
    });

    test('rebuilds a missing or corrupt index from the documents', () async {
      await store.create(name: 'A', canvas: canvas);
      await store.create(name: 'B', canvas: canvas);
      final index = File('${root.path}/projects/index.json')..deleteSync();
      expect((await store.list()).map((s) => s.name), ['B', 'A']);

      index.writeAsStringSync('{not json');
      expect(await store.list(), hasLength(2));
      expect(index.readAsStringSync(), contains('"projects"'));
    });

    test('an unreadable project is skipped, not fatal', () async {
      final a = await store.create(name: 'A', canvas: canvas);
      await store.create(name: 'B', canvas: canvas);
      File('${root.path}/projects/${a.id}/project.json').writeAsStringSync('x');
      File('${root.path}/projects/index.json').deleteSync();
      expect((await store.list()).map((s) => s.name), ['B']);
      expect(() => store.load(a.id), throwsA(isA<ProjectCorruptedFailure>()));
    });

    test('rename, duplicate with media, delete', () async {
      final a = await store.create(name: 'A', canvas: canvas);
      File(store.resolve(a.id, 'media/x.mp4'))
        ..createSync(recursive: true)
        ..writeAsStringSync('video');

      await store.rename(a.id, 'Renamed');
      expect((await store.load(a.id)).name, 'Renamed');

      final copy = await store.duplicate(a.id, name: 'Copy');
      expect(copy.id, isNot(a.id));
      expect(
        File(store.resolve(copy.id, 'media/x.mp4')).readAsStringSync(),
        'video',
      );
      expect(await store.list(), hasLength(2));

      await store.delete(a.id);
      expect((await store.list()).map((s) => s.name), ['Copy']);
      expect(store.projectDir(a.id).existsSync(), isFalse);
    });

    test('concurrent saves keep every index entry', () async {
      final projects = [
        for (var i = 0; i < 5; i++)
          await store.create(name: '$i', canvas: canvas),
      ];
      await Future.wait([
        for (final p in projects) store.save(p.copyWith(name: '${p.name}!')),
      ]);
      final names = (await store.list()).map((s) => s.name).toSet();
      expect(names, {'0!', '1!', '2!', '3!', '4!'});
    });

    test('missingMedia reports deleted files', () async {
      final p = await store.create(name: 'A', canvas: canvas);
      final withMedia = p.copyWith(
        media: {
          'here': const MediaAsset(
            id: 'here',
            kind: MediaKind.photo,
            path: 'media/here.jpg',
          ),
          'gone': const MediaAsset(
            id: 'gone',
            kind: MediaKind.photo,
            path: 'media/gone.jpg',
          ),
        },
      );
      File(store.resolve(p.id, 'media/here.jpg'))
        ..createSync(recursive: true)
        ..writeAsStringSync('x');
      expect(store.missingMedia(withMedia), {'gone'});
    });
  });

  group('MediaImporter', () {
    late FakeMediaLibrary library;
    late FakeEditorEngine engine;
    late MediaImporter importer;
    late Project project;

    setUp(() async {
      library = FakeMediaLibrary(
        Directory('${root.path}/library')..createSync(),
      );
      engine = FakeEditorEngine();
      importer = MediaImporter(
        store: store,
        library: library,
        engine: engine,
        ids: SequentialIdGenerator('m'),
      );
      project = await store.create(name: 'A', canvas: canvas);
    });

    test('copies files and posters and reports progress', () async {
      final video = library.addVideo('v', seconds: 4, bytes: 200000);
      final photo = library.addPhoto('p');
      final progress = <double>[];

      final assets = await importer.import(project.id, [
        video,
        photo,
      ], onProgress: (p) => progress.add(p.fraction));

      expect(assets.map((a) => a.kind), [MediaKind.video, MediaKind.photo]);
      expect(assets.first.durationUs, 4000000);
      expect(assets.last.durationUs, isNull);
      for (final a in assets) {
        expect(File(store.resolve(project.id, a.path)).existsSync(), isTrue);
        expect(
          File(store.resolve(project.id, a.posterPath!)).existsSync(),
          isTrue,
        );
      }
      expect(
        File(store.resolve(project.id, assets.first.path)).lengthSync(),
        200000,
      );
      expect(progress.first, 0);
      expect(progress.last, 1);
      for (var i = 1; i < progress.length; i++) {
        expect(progress[i], greaterThanOrEqualTo(progress[i - 1]));
      }
    });

    test('uses exact values from the engine over gallery values', () async {
      final video = library.addVideo('v', seconds: 4);
      engine.probeHandler = (_) => const MediaInfo(
        durationUs: 4321000,
        width: 720,
        height: 1280,
        hasVideo: true,
        hasAudio: false,
      );
      final asset = (await importer.import(project.id, [video])).single;
      expect(asset.durationUs, 4321000);
      expect((asset.width, asset.height), (720, 1280));
      expect(asset.hasAudio, isFalse);
      expect(asset.proxyPath, isNull);
    });

    test('large videos get a preview proxy', () async {
      final video = library.addVideo('big');
      engine.probeHandler = (_) => const MediaInfo(
        durationUs: 1000000,
        width: 1440,
        height: 2560,
        hasVideo: true,
        hasAudio: true,
      );
      final asset = (await importer.import(project.id, [video])).single;
      expect(engine.proxies, hasLength(1));
      // The fake does not write a file, so no proxy is recorded.
      expect(asset.proxyPath, isNull);
    });

    test('a failed probe falls back to gallery values', () async {
      final video = library.addVideo('v', seconds: 7);
      final asset = (await importer.import(project.id, [video])).single;
      expect(asset.durationUs, 7000000);
      expect(asset.hasAudio, isTrue);
    });

    test('an unavailable item fails and cleans up what was copied', () async {
      final ok = library.addVideo('ok');
      final missing = library.addVideo('gone');
      library.unavailable.add('gone');
      await expectLater(
        importer.import(project.id, [ok, missing]),
        throwsA(isA<MissingSourceFailure>()),
      );
      final media = Directory(store.resolve(project.id, 'media'));
      expect(
        media.existsSync() ? media.listSync() : const <FileSystemEntity>[],
        isEmpty,
      );
    });

    test('cancel stops and cleans up', () async {
      final items = [
        for (var i = 0; i < 3; i++) library.addVideo('v$i', bytes: 300000),
      ];
      final cancel = CancellationToken();
      await expectLater(
        importer.import(
          project.id,
          items,
          cancel: cancel,
          onProgress: (p) {
            if (p.completed == 1) cancel.cancel();
          },
        ),
        throwsA(isA<CancelledFailure>()),
      );
      final media = Directory(store.resolve(project.id, 'media'));
      expect(media.listSync(), isEmpty);
    });
  });
}
