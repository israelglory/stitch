// Builds the online sound library from tool/sound_catalog/sources.json.
//
//   dart run tool/sound_catalog/build.dart
//
// For each sound it downloads the original (cached in
// build/sound_catalog/cache), takes it out of its zip when it is in one,
// trims silence at both ends, evens out loudness, and encodes AAC: 128 kbps
// stereo for music, 96 kbps for effects. Music also gets a 15-second
// preview (64 kbps) from a third of the way in. Needs ffmpeg and ffprobe.
//
// Writes build/sound_catalog/out/ (the files to publish, plus catalog.json)
// and the copy of the catalog the app ships
// (assets/sound_library/catalog.json). Publish with
// tool/sound_catalog/publish.sh.
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

/// Where the files are published (tool/sound_catalog/publish.sh uploads
/// there).
const _item = 'stitch-sound-library';
const _baseUrl = 'https://archive.org/download/$_item/';

/// Music is evened out to this loudness (LUFS), with true peaks under
/// [_truePeak] dB; effects are peak-normalized to [_effectPeak] dB.
const _musicLoudness = -14.0;
const _truePeak = -1.5;
const _effectPeak = -1.0;

/// Longest a piece of music may be, in seconds.
const _maxMusicSeconds = 300;
const _previewSeconds = 15;

final _out = Directory('build/sound_catalog/out');
final _cache = Directory('build/sound_catalog/cache');

Future<void> main() async {
  final sources = jsonDecode(
    File('tool/sound_catalog/sources.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final sounds = (sources['sounds'] as List).cast<Map<String, dynamic>>();
  for (final dir in [_out, _cache]) {
    dir.createSync(recursive: true);
  }
  for (final sub in ['music', 'effects', 'previews']) {
    Directory('${_out.path}/$sub').createSync(recursive: true);
  }

  final entries = <Map<String, Object>>[];
  final failures = <String>[];
  for (final (i, s) in sounds.indexed) {
    final id = s['id'] as String;
    stdout.write('[${i + 1}/${sounds.length}] $id ... ');
    try {
      entries.add(await _build(s));
      stdout.writeln('ok');
    } on Object catch (e) {
      failures.add('$id: $e');
      stdout.writeln('FAILED: $e');
    }
  }
  if (failures.isNotEmpty) {
    stderr.writeln('\n${failures.length} failed:\n${failures.join('\n')}');
    exit(1);
  }

  final catalog = const JsonEncoder.withIndent(' ').convert({
    'version': 1,
    'baseUrl': _baseUrl,
    // Other places holding the same files, tried in order if baseUrl fails.
    'mirrors': <String>[],
    'sounds': entries,
  });
  File('${_out.path}/catalog.json').writeAsStringSync('$catalog\n');
  final shipped = File('assets/sound_library/catalog.json')
    ..parent.createSync(recursive: true)
    ..writeAsStringSync('$catalog\n');
  final bytes = entries.fold<int>(0, (sum, e) => sum + (e['bytes']! as int));
  stdout.writeln(
    '\n${entries.length} sounds, ${(bytes / 1e6).toStringAsFixed(1)} MB. '
    'Catalog: ${_out.path}/catalog.json and ${shipped.path}.',
  );
}

Future<Map<String, Object>> _build(Map<String, dynamic> s) async {
  final id = s['id'] as String;
  final music = s['kind'] == 'music';
  final original = await _original(s);
  final file = '${music ? 'music' : 'effects'}/$id.m4a';
  final target = File('${_out.path}/$file');
  if (!target.existsSync()) {
    await _encode(original, target, music: music);
  }
  String? preview;
  if (music) {
    preview = 'previews/$id.m4a';
    final previewFile = File('${_out.path}/$preview');
    if (!previewFile.existsSync()) await _preview(target, previewFile);
  }
  final duration = await _durationUs(target);
  return {
    'id': id,
    'kind': s['kind'] as String,
    'category': s['category'] as String,
    'title': s['title'] as String,
    'artist': s['artist'] as String,
    'license': s['license'] as String,
    'source': s['source'] as String,
    'file': file,
    'bytes': target.lengthSync(),
    'sha256': sha256.convert(target.readAsBytesSync()).toString(),
    'durationUs': duration,
    'preview': ?preview,
  };
}

/// The original file, downloaded once (and taken out of its zip).
Future<File> _original(Map<String, dynamic> s) async {
  final url = s['url'] as String;
  final member = s['member'] as String?;
  final name = sha256.convert(utf8.encode(url)).toString().substring(0, 16);
  final download = File('${_cache.path}/$name${_extension(url)}');
  if (!download.existsSync()) {
    await _run('curl', [
      '-sSfL',
      '--retry',
      '4',
      '--max-time',
      '600',
      '-A',
      'Stitch sound library builder',
      '-o',
      download.path,
      url,
    ]);
  }
  if (member == null) return download;
  final extracted = Directory('${_cache.path}/$name');
  final inside = File('${extracted.path}/$member');
  if (!inside.existsSync()) {
    await _run('unzip', ['-qo', download.path, '-d', extracted.path]);
  }
  if (!inside.existsSync()) throw StateError('$member not in $url');
  return inside;
}

String _extension(String url) {
  final match = RegExp(r'\.([a-z0-9]{2,4})$')
      .firstMatch(Uri.parse(url).path.toLowerCase());
  return match == null ? '' : '.${match.group(1)}';
}

/// Trims silence at both ends, sets loudness, encodes AAC.
Future<void> _encode(File input, File output, {required bool music}) async {
  const trim =
      'silenceremove=start_periods=1:start_threshold=-60dB,areverse,'
      'silenceremove=start_periods=1:start_threshold=-60dB,areverse';
  final String gain;
  if (music) {
    // Two passes: measure, then apply linearly (no pumping).
    final measured = await _run('ffmpeg', [
      '-hide_banner',
      '-i',
      input.path,
      '-t',
      '$_maxMusicSeconds',
      '-af',
      '$trim,loudnorm=I=$_musicLoudness:TP=$_truePeak:print_format=json',
      '-f',
      'null',
      '-',
    ]);
    final json = jsonDecode(
      measured.substring(
        measured.lastIndexOf('{'),
        measured.lastIndexOf('}') + 1,
      ),
    ) as Map<String, dynamic>;
    gain =
        'loudnorm=I=$_musicLoudness:TP=$_truePeak:linear=true'
        ':measured_I=${json['input_i']}:measured_TP=${json['input_tp']}'
        ':measured_LRA=${json['input_lra']}'
        ':measured_thresh=${json['input_thresh']}'
        ':offset=${json['target_offset']}';
  } else {
    final measured = await _run('ffmpeg', [
      '-hide_banner',
      '-i',
      input.path,
      '-af',
      '$trim,volumedetect',
      '-f',
      'null',
      '-',
    ]);
    final peak = double.parse(
      RegExp(r'max_volume: (-?[\d.]+) dB').firstMatch(measured)!.group(1)!,
    );
    gain = 'volume=${(_effectPeak - peak).toStringAsFixed(2)}dB';
  }
  await _run('ffmpeg', [
    '-hide_banner',
    '-y',
    '-i',
    input.path,
    if (music) ...['-t', '$_maxMusicSeconds'],
    '-af',
    '$trim,$gain,aresample=48000',
    '-ac',
    '2',
    '-c:a',
    'aac',
    '-b:a',
    music ? '128k' : '96k',
    '-movflags',
    '+faststart',
    '-map_metadata',
    '-1',
    '-vn',
    output.path,
  ]);
}

/// A [_previewSeconds] clip from a third of the way in, faded at both ends.
Future<void> _preview(File music, File output) async {
  final total = await _durationUs(music) / 1e6;
  final start = (total / 3).clamp(0, total - _previewSeconds).toDouble();
  await _run('ffmpeg', [
    '-hide_banner',
    '-y',
    '-ss',
    start.toStringAsFixed(2),
    '-t',
    '$_previewSeconds',
    '-i',
    music.path,
    '-af',
    'afade=t=in:d=0.5,afade=t=out:st=${_previewSeconds - 1.5}:d=1.5',
    '-c:a',
    'aac',
    '-b:a',
    '64k',
    '-movflags',
    '+faststart',
    output.path,
  ]);
}

Future<int> _durationUs(File file) async {
  final out = await _run('ffprobe', [
    '-v',
    'error',
    '-show_entries',
    'format=duration',
    '-of',
    'csv=p=0',
    file.path,
  ]);
  return (double.parse(out.trim()) * 1e6).round();
}

/// Runs [command], returning stdout and stderr together; throws on failure.
Future<String> _run(String command, List<String> args) async {
  final result = await Process.run(command, args);
  final output = '${result.stdout}${result.stderr}';
  if (result.exitCode != 0) {
    final tail = output.length > 400
        ? output.substring(output.length - 400)
        : output;
    throw ProcessException(command, args, tail, result.exitCode);
  }
  return output;
}
