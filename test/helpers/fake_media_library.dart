import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:stitch/features/media/data/media_library.dart';
import 'package:stitch/features/media/domain/library_item.dart';
import 'package:stitch/features/timeline/domain/models.dart';

/// A 1x1 gray PNG, a valid image for thumbnails in tests.
final Uint8List tinyPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAAAAAA6fptVAAAACklEQVR4nGNoAAAAggCBd8'
  '1ytgAAAABJRU5ErkJggg==',
);

/// In-memory photo library. Each item is backed by a small real file in
/// [dir] so importing copies actual bytes.
class FakeMediaLibrary implements MediaLibrary {
  new(this.dir, {this.accessState = LibraryAccess.granted});

  final Directory dir;
  LibraryAccess accessState;

  /// What [requestAccess] turns into.
  LibraryAccess afterRequest = LibraryAccess.granted;
  int requests = 0;
  int settingsOpened = 0;
  final all = <LibraryItem>[];

  /// Ids whose original file is unavailable (deleted, offline).
  final unavailable = <String>{};

  LibraryItem addVideo(String id, {int seconds = 5, int bytes = 4096}) => _add(
    LibraryItem(
      id: id,
      kind: MediaKind.video,
      width: 1080,
      height: 1920,
      durationUs: seconds * 1000000,
    ),
    '.mp4',
    bytes,
  );

  LibraryItem addPhoto(String id) => _add(
    LibraryItem(id: id, kind: MediaKind.photo, width: 1200, height: 1600),
    '.jpg',
    256,
  );

  LibraryItem _add(LibraryItem item, String ext, int bytes) {
    File('${dir.path}/${item.id}$ext')
      ..createSync(recursive: true)
      ..writeAsBytesSync(List<int>.filled(bytes, 7));
    all.add(item);
    return item;
  }

  @override
  Future<LibraryAccess> access() async => accessState;

  @override
  Future<LibraryAccess> requestAccess() async {
    requests++;
    return accessState = afterRequest;
  }

  @override
  Future<void> openSystemSettings() async => settingsOpened++;

  @override
  Future<void> manageLimitedSelection() async {}

  @override
  Future<List<LibraryItem>> items(
    LibraryFilter filter, {
    required int page,
    int pageSize = 60,
  }) async {
    final matching = [
      for (final i in all)
        if (filter == LibraryFilter.all ||
            (filter == LibraryFilter.videos && i.kind == MediaKind.video) ||
            (filter == LibraryFilter.photos && i.kind == MediaKind.photo))
          i,
    ];
    return matching.skip(page * pageSize).take(pageSize).toList();
  }

  @override
  Future<Uint8List?> thumbnail(
    String id, {
    int width = 256,
    int height = 256,
  }) async => tinyPng;

  @override
  Future<File?> originalFile(String id) async {
    if (unavailable.contains(id)) return null;
    for (final f in dir.listSync().whereType<File>()) {
      if (f.uri.pathSegments.last.startsWith('$id.')) return f;
    }
    return null;
  }
}
