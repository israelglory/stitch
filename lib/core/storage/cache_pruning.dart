import 'dart:io';

/// Deletes the least recently modified files in [dir] until its total size
/// is at most [maxBytes]. Returns the bytes freed.
Future<int> pruneDirectory(Directory dir, int maxBytes) async {
  if (!dir.existsSync()) return 0;
  final files = <(File, int, DateTime)>[];
  var total = 0;
  await for (final entity in dir.list(recursive: true)) {
    if (entity is! File) continue;
    final stat = entity.statSync();
    files.add((entity, stat.size, stat.modified));
    total += stat.size;
  }
  if (total <= maxBytes) return 0;
  files.sort((a, b) => a.$3.compareTo(b.$3));
  var freed = 0;
  for (final (file, size, _) in files) {
    if (total - freed <= maxBytes) break;
    try {
      await file.delete();
      freed += size;
    } on FileSystemException {
      // In use or already gone; skip it.
    }
  }
  return freed;
}
