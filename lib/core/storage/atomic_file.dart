import 'dart:io';

var _tempCounter = 0;

/// Writes [contents] to [file] so readers only ever see the old or the new
/// version: write a sibling temp file of its own, flush it to disk, then
/// rename over the target. A crash mid-write leaves the previous file
/// intact, and two writes at once never share a temp file.
Future<void> writeFileAtomically(File file, String contents) async {
  await file.parent.create(recursive: true);
  final temp = File('${file.path}.${pid}_${_tempCounter++}.tmp');
  try {
    await temp.writeAsString(contents, flush: true);
    await temp.rename(file.path);
  } on Object {
    if (temp.existsSync()) await temp.delete();
    rethrow;
  }
}
