import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:stitch/engine/editor_engine.dart';
import 'package:stitch/features/media/data/media_library.dart';
import 'package:stitch/features/media/domain/library_item.dart';
import 'package:stitch/features/timeline/domain/models.dart';

/// A media library over a folder of files, for integration tests: the
/// Photos permission resets each time `flutter test` reinstalls the app,
/// so tests cannot rely on it. Everything after the picker is real.
class FolderLibrary implements MediaLibrary {
  new(this.dir, this.engine);

  final Directory dir;
  final EditorEngine engine;
  List<(LibraryItem, File)>? _items;

  static const _videos = {'.mp4', '.mov', '.m4v'};
  static const _photos = {'.jpg', '.jpeg', '.png', '.heic'};

  Future<List<(LibraryItem, File)>> _load() async {
    if (_items != null) return _items!;
    final files = dir.listSync().whereType<File>().where((f) {
      final ext = p.extension(f.path).toLowerCase();
      return _videos.contains(ext) || _photos.contains(ext);
    }).toList()..sort((a, b) => a.path.compareTo(b.path));
    final items = <(LibraryItem, File)>[];
    for (final f in files) {
      final info = await engine.probe(f.path);
      final isPhoto = _photos.contains(p.extension(f.path).toLowerCase());
      items.add((
        LibraryItem(
          id: p.basename(f.path),
          kind: isPhoto ? MediaKind.photo : MediaKind.video,
          width: info.width,
          height: info.height,
          durationUs: info.durationUs,
        ),
        f,
      ));
    }
    return _items = items;
  }

  @override
  Future<LibraryAccess> access() async => LibraryAccess.granted;

  @override
  Future<LibraryAccess> requestAccess() async => LibraryAccess.granted;

  @override
  Future<void> openSystemSettings() async {}

  @override
  Future<void> manageLimitedSelection() async {}

  @override
  Future<List<LibraryItem>> items(
    LibraryFilter filter, {
    required int page,
    int pageSize = 60,
  }) async {
    if (page > 0) return const [];
    return [
      for (final (item, _) in await _load())
        if (filter == LibraryFilter.all ||
            (filter == LibraryFilter.videos && item.kind == MediaKind.video) ||
            (filter == LibraryFilter.photos && item.kind == MediaKind.photo))
          item,
    ];
  }

  @override
  Future<Uint8List?> thumbnail(
    String id, {
    int width = 256,
    int height = 256,
  }) async {
    final file = await originalFile(id);
    if (file == null) return null;
    final out = await Directory.systemTemp.createTemp('thumb');
    final paths = await engine.thumbnails(
      file.path,
      [0],
      maxSize: width > height ? width : height,
      outDir: out.path,
    );
    final path = paths.firstOrNull;
    return path == null ? null : await File(path).readAsBytes();
  }

  @override
  Future<File?> originalFile(String id) async {
    for (final (item, file) in await _load()) {
      if (item.id == id) return file;
    }
    return null;
  }
}
