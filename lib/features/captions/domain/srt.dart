import 'package:stitch/features/timeline/domain/composition.dart';

/// [captions] as a SubRip (.srt) file, in time order.
String srtOf(List<ResolvedCaption> captions) {
  final sorted = [...captions]..sort((a, b) => a.startUs.compareTo(b.startUs));
  final out = StringBuffer();
  for (final (i, c) in sorted.indexed) {
    out
      ..writeln(i + 1)
      ..writeln('${_time(c.startUs)} --> ${_time(c.endUs)}')
      ..writeln(c.text)
      ..writeln();
  }
  return out.toString();
}

/// `HH:MM:SS,mmm`.
String _time(int us) {
  final ms = (us / 1000).round();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(ms ~/ 3600000)}:${two(ms ~/ 60000 % 60)}:'
      '${two(ms ~/ 1000 % 60)},${(ms % 1000).toString().padLeft(3, '0')}';
}
