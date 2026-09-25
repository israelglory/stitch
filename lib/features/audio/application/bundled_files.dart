import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:stitch/features/audio/data/bundled_audio.dart';

/// [sound] as a file in [cacheDir], copied out of the app bundle once: the
/// native players and the importer read files, not assets.
/// Two requests for the same sound (trying it, then adding it) share one
/// copy.
Future<File> bundledSoundFile(BundledSound sound, Directory cacheDir) {
  final file = File(
    p.join(cacheDir.path, 'bundled', '${sound.id}${p.extension(sound.asset)}'),
  );
  if (file.existsSync()) return Future.value(file);
  return _copying[file.path] ??= _copy(sound, file).whenComplete(() {
    // A block body: returning the removed future would make this one
    // wait for itself.
    unawaited(_copying.remove(file.path));
  });
}

final _copying = <String, Future<File>>{};

Future<File> _copy(BundledSound sound, File file) async {
  await file.parent.create(recursive: true);
  final data = await rootBundle.load(sound.asset);
  final temp = File('${file.path}.part');
  await temp.writeAsBytes(
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    flush: true,
  );
  return await temp.rename(file.path);
}
