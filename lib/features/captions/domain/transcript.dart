import 'dart:convert';
import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:stitch/features/timeline/domain/caption_ops.dart';
import 'package:stitch/features/timeline/domain/limits.dart';

/// Part of a word as speech recognition reports it, with its raw UTF-8
/// bytes: a token can end in the middle of a character.
@immutable
final class SpeechToken {
  const new({required this.bytes, required this.startUs, required this.endUs});

  final List<int> bytes;
  final int startUs;
  final int endUs;

  bool get startsWord => bytes.isNotEmpty && bytes.first == 0x20;
}

/// What speech recognition heard: the language and, per recognized
/// segment, its tokens. Times are from the start of the audio, which is
/// the start of the timeline.
@immutable
final class Transcript {
  const new({required this.language, required this.segments});

  /// Reads the JSON that `stitch_whisper_transcribe` returns without an
  /// error: token text carries one byte per character.
  factory fromWhisperJson(Map<String, dynamic> json) => Transcript(
    language: json['language'] as String? ?? '',
    segments: [
      for (final segment in json['segments'] as List? ?? const [])
        [
          for (final token in (segment as Map)['tokens'] as List? ?? const [])
            if (token case {
              'text': final String text,
              'start': final num start,
              'end': final num end,
            })
              SpeechToken(
                bytes: text.codeUnits,
                startUs: start.toInt() * 1000,
                endUs: end.toInt() * 1000,
              ),
        ],
    ],
  );

  /// A whisper language code, like `en`.
  final String language;
  final List<List<SpeechToken>> segments;

  /// Written without spaces between words.
  bool get unspaced => isUnspacedLanguage(language);

  /// Words, in order, with times that never go backwards.
  List<RecognizedWord> words() {
    final words = <RecognizedWord>[];
    var lastStart = 0;
    void add(List<SpeechToken> tokens) {
      if (tokens.isEmpty) return;
      final text = utf8.decode([
        for (final t in tokens) ...t.bytes,
      ], allowMalformed: true).trim();
      if (text.isEmpty || text == '�') return;
      final start = math.max(lastStart, tokens.first.startUs);
      final end = math.max(start, tokens.last.endUs);
      lastStart = start;
      words.add((text: text, startUs: start, endUs: end));
    }

    for (final segment in segments) {
      var pending = <SpeechToken>[];
      for (final token in segment) {
        // A new word starts at a space (or, without spaces, at every
        // token), but never inside a character.
        if (pending.isNotEmpty &&
            (token.startsWord || unspaced) &&
            _completeUtf8(pending)) {
          add(pending);
          pending = [];
        }
        pending.add(token);
      }
      add(pending);
    }
    return words;
  }

  /// Captions short enough to read at a glance, with fresh ids from
  /// [newId]. See [captionGroups].
  List<RecognizedSegment> captions({required String Function() newId}) {
    final groups = captionGroups(words(), spaced: !unspaced);
    return [
      for (final (i, group) in groups.indexed)
        () {
          final start = group.first.startUs;
          final spoken = math.max(
            group.last.endUs,
            start + TimelineLimits.minDurationUs,
          );
          // Stay up a little after the last word, until the next caption.
          final next = i + 1 < groups.length
              ? groups[i + 1].first.startUs
              : null;
          // Never into the next caption, even when the words' own times
          // overlap it: two captions would show at once, one over the other.
          final held = spoken + captionHoldUs;
          final end = next == null
              ? held
              : math.max(
                  start + TimelineLimits.minDurationUs,
                  math.min(held, next),
                );
          return (
            id: newId(),
            text: joinWords(group, spaced: !unspaced),
            startUs: start,
            endUs: end,
            words: group,
          );
        }(),
    ];
  }

  static bool _completeUtf8(List<SpeechToken> tokens) {
    try {
      utf8.decode([for (final t in tokens) ...t.bytes]);
      return true;
    } on FormatException {
      return false;
    }
  }
}

/// How long a caption stays after its last word, unless the next starts.
const captionHoldUs = 400000;

String joinWords(List<RecognizedWord> words, {required bool spaced}) =>
    words.map((w) => w.text).join(spaced ? ' ' : '');

/// Groups [words] into captions. A caption ends after a sentence, at a
/// pause of [pauseUs], before it grows past [maxChars] or [maxUs], or
/// after a comma once it is half full.
List<List<RecognizedWord>> captionGroups(
  List<RecognizedWord> words, {
  bool spaced = true,
  int maxChars = 42,
  int maxUs = 5000000,
  int pauseUs = 700000,
}) {
  final groups = <List<RecognizedWord>>[];
  var current = <RecognizedWord>[];
  for (final word in words) {
    if (current.isNotEmpty) {
      final last = current.last;
      final length = joinWords([...current, word], spaced: spaced).length;
      final lastText = last.text;
      final breaks =
          word.startUs - last.endUs > pauseUs ||
          length > maxChars ||
          word.endUs - current.first.startUs > maxUs ||
          _sentenceEnd.hasMatch(lastText) ||
          (_clauseEnd.hasMatch(lastText) &&
              joinWords(current, spaced: spaced).length >= maxChars / 2);
      if (breaks) {
        groups.add(current);
        current = [];
      }
    }
    current.add(word);
  }
  if (current.isNotEmpty) groups.add(current);
  return groups;
}

final _sentenceEnd = RegExp(r'[.?!。？！…]["”’)]*$');
final _clauseEnd = RegExp(r'[,;:，、；：]$');
