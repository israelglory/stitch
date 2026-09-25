import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:stitch/features/audio/data/bundled_audio.dart';

/// [sound] as a file in [cacheDir], copied out of the app bundle once: the
/// native players and the importer read files, not assets.
Future<File> bundledSoundFile(BundledSound sound, Directory cacheDir) async {
  final file = File(
    p.join(cacheDir.path, 'bundled', '${sound.id}${p.extension(sound.asset)}'),
  );
  if (file.existsSync()) return file;
  await file.parent.create(recursive: true);
  final data = await rootBundle.load(sound.asset);
  final temp = File('${file.path}.part');
  await temp.writeAsBytes(
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    flush: true,
  );
  return await temp.rename(file.path);
}
