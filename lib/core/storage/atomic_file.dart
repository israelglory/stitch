import 'dart:io';

/// Writes [contents] to [file] so readers only ever see the old or the new
/// version: write a sibling temp file, flush it, then rename over the
/// target. A crash mid-write leaves the previous file intact.
Future<void> writeFileAtomically(File file, String contents) async {
  await file.parent.create(recursive: true);
  final temp = File('${file.path}.tmp');
  final sink = temp.openWrite();
  try {
    sink.write(contents);
    await sink.flush();
  } finally {
    await sink.close();
  }
  await temp.rename(file.path);
}
