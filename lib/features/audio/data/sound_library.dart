import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:stitch/core/network/file_download.dart';

/// Music and sound effects to download: the online library, published on
/// the Internet Archive by tool/sound_catalog/. Everything in it is CC0.

/// Kinds of sound in the library.
enum LibraryKind { music, effect }

/// One sound in the library.
@immutable
final class LibrarySound {
  const new({
    required this.id,
    required this.kind,
    required this.category,
    required this.title,
    required this.artist,
    required this.license,
    required this.source,
    required this.file,
    required this.bytes,
    required this.sha256,
    required this.durationUs,
    this.preview,
  });

  final String id;
  final LibraryKind kind;

  /// A mood for music (upbeat, calm, ...), a group for effects.
  final String category;
  final String title;
  final String artist;

  /// An SPDX id; CC0-1.0 throughout.
  final String license;

  /// Page the sound came from, for credits.
  final String source;

  /// Path under the catalog's base address.
  final String file;
  final int bytes;
  final String sha256;
  final int durationUs;

  /// A short clip to try before downloading (music only).
  final String? preview;

  /// Null for an entry this version cannot use.
  static LibrarySound? fromJson(Map<String, dynamic> json) {
    try {
      final kind = switch (json['kind']) {
        'music' => LibraryKind.music,
        'effect' => LibraryKind.effect,
        _ => null,
      };
      final id = json['id'] as String;
      final file = json['file'] as String;
      // Ids and paths become file names: nothing that leaves the folder.
      if (kind == null ||
          !RegExp(r'^[a-z0-9_]+$').hasMatch(id) ||
          file.contains('..') ||
          file.startsWith('/')) {
        return null;
      }
      return LibrarySound(
        id: id,
        kind: kind,
        category: json['category'] as String,
        title: json['title'] as String,
        artist: json['artist'] as String,
        license: json['license'] as String,
        source: json['source'] as String,
        file: file,
        bytes: json['bytes'] as int,
        sha256: json['sha256'] as String,
        durationUs: json['durationUs'] as int,
        preview: json['preview'] as String?,
      );
    } on Object {
      return null;
    }
  }
}

/// The library's contents and where its files are.
@immutable
final class SoundCatalog {
  const new({
    required this.version,
    required this.baseUrls,
    required this.sounds,
  });

  final int version;

  /// The base address, then mirrors: each file is tried at each in turn.
  final List<Uri> baseUrls;
  final List<LibrarySound> sounds;

  /// Catalog formats this version reads.
  static const supportedVersion = 1;

  static SoundCatalog? parse(String text) {
    try {
      final json = jsonDecode(text) as Map<String, dynamic>;
      final version = json['version'] as int;
      if (version > supportedVersion) return null;
      final bases = [json['baseUrl'] as String, ...?(json['mirrors'] as List?)];
      final urls = [
        for (final b in bases.cast<String>())
          if (Uri.tryParse(b) case final u?
              when b.endsWith('/') &&
                  (u.scheme == 'https' ||
                      // Plain HTTP only to this device (tests).
                      (u.scheme == 'http' &&
                          (u.host == 'localhost' || u.host == '127.0.0.1'))))
            u,
      ];
      if (urls.isEmpty) return null;
      return SoundCatalog(
        version: version,
        baseUrls: urls,
        sounds: [
          for (final s in (json['sounds'] as List).cast<Map<String, dynamic>>())
            ?LibrarySound.fromJson(s),
        ],
      );
    } on Object {
      return null;
    }
  }

  RemoteFile remote(LibrarySound sound) => RemoteFile(
    urls: [for (final b in baseUrls) b.resolve(sound.file)],
    bytes: sound.bytes,
    sha256: sound.sha256,
  );

  RemoteFile? previewOf(LibrarySound sound) => switch (sound.preview) {
    null => null,
    final path => RemoteFile(urls: [for (final b in baseUrls) b.resolve(path)]),
  };

  /// Where the newest catalog is fetched from.
  List<Uri> get catalogUrls => [
    for (final b in baseUrls) b.resolve('catalog.json'),
  ];
}

/// Downloaded library sounds on disk, in [directory]: `<id>.m4a`, the
/// catalog last fetched (`catalog.json`), and previews (`previews/`).
class SoundLibraryStore {
  new(this.directory, {HttpClient Function()? client})
    : _client = client ?? HttpClient.new;

  final Directory directory;
  final HttpClient Function() _client;

  File file(LibrarySound sound) =>
      File(p.join(directory.path, '${sound.id}${p.extension(sound.file)}'));

  File _previewFile(LibrarySound sound) => File(
    p.join(
      directory.path,
      'previews',
      '${sound.id}${p.extension(sound.preview ?? '')}',
    ),
  );

  bool isDownloaded(LibrarySound sound) {
    final f = file(sound);
    return f.existsSync() && f.lengthSync() == sound.bytes;
  }

  /// Downloads [sound]; an interrupted download resumes.
  FileDownload download(SoundCatalog catalog, LibrarySound sound) =>
      downloadFile(catalog.remote(sound), file(sound), client: _client);

  /// A file to try [sound] with: its preview (music), or the sound itself
  /// (effects, which are small).
  Future<File> previewFile(SoundCatalog catalog, LibrarySound sound) async {
    final remote = catalog.previewOf(sound);
    if (remote == null) {
      if (!isDownloaded(sound)) await download(catalog, sound).done;
      return file(sound);
    }
    final target = _previewFile(sound);
    if (!target.existsSync()) {
      await downloadFile(remote, target, client: _client).done;
    }
    return target;
  }

  Future<void> delete(LibrarySound sound) async {
    for (final f in [file(sound), File('${file(sound).path}.part')]) {
      if (f.existsSync()) await f.delete();
    }
  }

  /// Deletes every downloaded sound and preview; keeps the catalog.
  Future<void> deleteAll() async {
    if (!directory.existsSync()) return;
    for (final entry in directory.listSync(followLinks: false)) {
      if (p.basename(entry.path) == _catalogName) continue;
      await entry.delete(recursive: true);
    }
  }

  /// Space downloaded sounds and previews take.
  int downloadedBytes() {
    if (!directory.existsSync()) return 0;
    var total = 0;
    for (final entry in directory.listSync(
      recursive: true,
      followLinks: false,
    )) {
      if (entry is File && p.basename(entry.path) != _catalogName) {
        total += entry.lengthSync();
      }
    }
    return total;
  }

  static const _catalogName = 'catalog.json';

  File get _catalogFile => File(p.join(directory.path, _catalogName));

  /// The catalog fetched last, if any.
  SoundCatalog? savedCatalog() {
    final f = _catalogFile;
    return f.existsSync() ? SoundCatalog.parse(f.readAsStringSync()) : null;
  }

  /// Fetches the newest catalog from [known]'s addresses and keeps it.
  /// Null when none answers with one this version can read.
  Future<SoundCatalog?> fetchCatalog(SoundCatalog known) async {
    final target = File(p.join(directory.path, 'catalog.next.json'));
    try {
      await downloadFile(
        RemoteFile(urls: known.catalogUrls),
        target,
        client: _client,
      ).done;
      final text = await target.readAsString();
      final fresh = SoundCatalog.parse(text);
      if (fresh == null) return null;
      await target.rename(_catalogFile.path);
      return fresh;
    } on Object {
      return null;
    } finally {
      if (target.existsSync()) await target.delete();
    }
  }
}
