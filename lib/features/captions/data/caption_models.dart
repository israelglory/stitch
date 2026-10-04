import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:stitch/core/network/file_download.dart';

/// Speech recognition models, downloaded on first use. whisper.cpp's
/// multilingual models, 8-bit quantized: about half the size of the full
/// ones with nearly the same accuracy. MIT licensed.
enum CaptionModel {
  /// Faster; good for clear speech.
  tiny(
    fileName: 'ggml-tiny-q8_0.bin',
    bytes: 43537433,
    sha256: 'c2085835d3f50733e2ff6e4b41ae8a2b8d8110461e18821b09a15c40c42d1cca',
  ),

  /// Slower; better with accents and noise.
  base(
    fileName: 'ggml-base-q8_0.bin',
    bytes: 81768585,
    sha256: 'c577b9a86e7e048a0b7eada054f4dd79a56bbfa911fbdacf900ac5b567cbb7d9',
  );

  new({required this.fileName, required this.bytes, required this.sha256});

  final String fileName;
  final int bytes;
  final String sha256;

  /// Pinned to one revision of the model repository; the hash is checked
  /// after every download all the same.
  static const _revision = '5359861c739e955e79d9a303bcbc70fb988958b1';

  ModelFile get file => ModelFile(
    fileName: fileName,
    bytes: bytes,
    sha256: sha256,
    url: Uri.https(
      'huggingface.co',
      '/ggerganov/whisper.cpp/resolve/$_revision/$fileName',
    ),
  );
}

/// A file to download: where from, and what it must be.
final class ModelFile {
  const new({
    required this.fileName,
    required this.bytes,
    required this.sha256,
    required this.url,
  });

  final String fileName;
  final int bytes;
  final String sha256;
  final Uri url;
}

/// A running model download (see [FileDownload]).
typedef ModelDownload = FileDownload;

/// Caption models on disk, and their downloads. An interrupted download
/// resumes where it stopped.
class CaptionModelStore {
  new(this.directory, {HttpClient Function()? client})
    : _client = client ?? HttpClient.new;

  final Directory directory;
  final HttpClient Function() _client;

  File file(ModelFile model) => File(p.join(directory.path, model.fileName));

  File _part(ModelFile model) => File('${file(model).path}.part');

  bool isInstalled(ModelFile model) {
    final f = file(model);
    return f.existsSync() && f.lengthSync() == model.bytes;
  }

  /// Space the installed models take.
  int installedBytes() => [
    for (final m in CaptionModel.values)
      if (isInstalled(m.file)) m.bytes,
  ].fold(0, (a, b) => a + b);

  Future<void> delete(ModelFile model) async {
    for (final f in [file(model), _part(model)]) {
      if (f.existsSync()) await f.delete();
    }
  }

  ModelDownload download(ModelFile model) => downloadFile(
    RemoteFile(urls: [model.url], bytes: model.bytes, sha256: model.sha256),
    file(model),
    client: _client,
  );
}
