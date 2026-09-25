import 'dart:math' as math;

import 'package:stitch/features/timeline/domain/item_timing.dart';
import 'package:stitch/features/timeline/domain/layout.dart';
import 'package:stitch/features/timeline/domain/limits.dart';
import 'package:stitch/features/timeline/domain/models.dart';
import 'package:stitch/features/timeline/domain/normalize.dart';
import 'package:stitch/features/timeline/domain/video_ops.dart';

/// A word from speech recognition, in absolute timeline time.
typedef RecognizedWord = ({String text, int startUs, int endUs});

/// A segment from speech recognition, in absolute timeline time.
typedef RecognizedSegment = ({
  String id,
  String text,
  int startUs,
  int endUs,
  List<RecognizedWord> words,
});

/// Whisper codes of languages written without spaces between words.
const unspacedLanguages = {'zh', 'yue', 'ja', 'th', 'lo', 'km', 'my', 'bo'};

bool isUnspacedLanguage(String? code) => unspacedLanguages.contains(code);

/// Caption edits.
extension CaptionOps on Timeline {
  /// What goes between words of the captions' language.
  String get _wordGap => isUnspacedLanguage(captionTrack.language) ? '' : ' ';

  List<CaptionSegment> get _segments => captionTrack.segments;

  CaptionSegment? captionById(String id) {
    for (final s in _segments) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// Segments ordered by start time.
  List<CaptionSegment> sortedCaptions() {
    final layout = TimelineLayout.of(this);
    return [..._segments]..sort(
      (a, b) => layout.startOf(a.anchor).compareTo(layout.startOf(b.anchor)),
    );
  }

  /// Replaces all captions with freshly recognized [segments]. Each
  /// segment is anchored to the content under its start, so it stays in
  /// sync with the speech through later edits.
  Timeline setCaptions(List<RecognizedSegment> segments, {String? language}) {
    final layout = TimelineLayout.of(this);
    return copyWith(
      captionTrack: captionTrack.copyWith(
        language: language,
        segments: [
          for (final s in segments)
            if (s.endUs - s.startUs > 0)
              CaptionSegment(
                id: s.id,
                text: s.text.trim(),
                anchor: layout.anchorAt(s.startUs),
                durationUs: s.endUs - s.startUs,
                words: [
                  for (final w in s.words)
                    CaptionWord(
                      text: w.text,
                      startOffsetUs: clampInt(
                        w.startUs - s.startUs,
                        0,
                        s.endUs - s.startUs,
                      ),
                      endOffsetUs: clampInt(
                        w.endUs - s.startUs,
                        0,
                        s.endUs - s.startUs,
                      ),
                    ),
                ],
              ),
        ],
      ),
    );
  }

  /// Replaces all captions with [segments], recognized from the sound of
  /// [heard]: this timeline as it was when recognition started. Each is
  /// anchored where it was heard, then placed on this timeline: on the
  /// same clip when that still holds the moment, on the clip that holds it
  /// now (after a split), or, when the footage was deleted, at its old
  /// time and flagged for review. Keeps the caption style.
  Timeline withRecognizedCaptions(
    Timeline heard,
    List<RecognizedSegment> segments, {
    String? language,
  }) {
    final heardLayout = TimelineLayout.of(heard);
    final nowLayout = TimelineLayout.of(this);
    final placed = heard.setCaptions(segments, language: language).captionTrack;

    CaptionSegment place(CaptionSegment s) {
      final anchor = s.anchor;
      if (anchor is! ClipAnchor) return s;
      bool holds(VideoClip c) =>
          anchor.sourceUs >= c.sourceInUs && anchor.sourceUs < c.sourceOutUs;
      final same = clipById(anchor.clipId);
      if (same != null && holds(same)) return s;
      final mediaId = heard.clipById(anchor.clipId)?.mediaId;
      for (final c in videoClips) {
        if (c.mediaId == mediaId && holds(c)) {
          return s.copyWith(anchor: anchor.copyWith(clipId: c.id));
        }
      }
      final t = heardLayout.startOf(anchor);
      return s.copyWith(
        anchor: nowLayout.anchorAt(math.min(t, nowLayout.durationUs)),
        needsReview: true,
      );
    }

    return copyWith(
      captionTrack: placed.copyWith(
        segments: [for (final s in placed.segments) place(s)],
        preset: captionTrack.preset,
        position: captionTrack.position,
      ),
    );
  }

  /// Replaces a segment's text. Word timings are kept when the word count
  /// is unchanged (a typo fix); otherwise the new words are spread evenly
  /// over the segment.
  Timeline editCaptionText(String id, String text) {
    final segment = captionById(id);
    final trimmed = text.trim();
    if (segment == null || trimmed == segment.text) return this;
    final List<String> newWords;
    if (_wordGap.isEmpty) {
      // No spaces to split on: keep each word's share of the text, so a
      // typo fix keeps its timings; otherwise a word per character.
      final oldLengths = [for (final w in segment.words) w.text.length];
      final sameLength =
          oldLengths.fold(0, (a, b) => a + b) == trimmed.length &&
          oldLengths.isNotEmpty;
      if (sameLength) {
        var at = 0;
        newWords = [for (final n in oldLengths) trimmed.substring(at, at += n)];
      } else {
        newWords = [for (final r in trimmed.runes) String.fromCharCode(r)];
      }
    } else {
      newWords = _splitWords(trimmed);
    }
    final List<CaptionWord> words;
    if (newWords.length == segment.words.length) {
      words = [
        for (final (i, w) in segment.words.indexed)
          w.copyWith(text: newWords[i]),
      ];
    } else {
      words = _evenWords(newWords, segment.durationUs);
    }
    return _replaceCaption(id, (s) => s.copyWith(text: trimmed, words: words));
  }

  /// Sets a segment's start and end, in timeline time.
  Timeline setCaptionTiming(String id, int startUs, int endUs) {
    final segment = captionById(id);
    if (segment == null) return this;
    final layout = TimelineLayout.of(this);
    final start = math.max(0, startUs);
    final end = math.max(start + TimelineLimits.minDurationUs, endUs);
    final duration = end - start;
    return _replaceCaption(
      id,
      (s) => s.copyWith(
        anchor: layout.anchorAt(start),
        durationUs: duration,
        needsReview: false,
        words: [
          for (final w in s.words)
            w.copyWith(
              startOffsetUs: clampInt(w.startOffsetUs, 0, duration),
              endOffsetUs: clampInt(w.endOffsetUs, 0, duration),
            ),
        ],
      ),
    );
  }

  /// Whether [firstId] is directly followed by [secondId].
  bool canMergeCaptions(String firstId, String secondId) {
    final sorted = sortedCaptions();
    final i = sorted.indexWhere((s) => s.id == firstId);
    return i >= 0 && i + 1 < sorted.length && sorted[i + 1].id == secondId;
  }

  /// Joins two consecutive segments into the first.
  Timeline mergeCaptions(String firstId, String secondId) {
    if (!canMergeCaptions(firstId, secondId)) return this;
    final layout = TimelineLayout.of(this);
    final a = captionById(firstId)!;
    final b = captionById(secondId)!;
    final aStart = layout.startOf(a.anchor);
    final bStart = layout.startOf(b.anchor);
    final end = math.max(aStart + a.durationUs, bStart + b.durationUs);
    final shift = bStart - aStart;
    final merged = a.copyWith(
      text: '${a.text}$_wordGap${b.text}'.trim(),
      durationUs: end - aStart,
      needsReview: a.needsReview || b.needsReview,
      words: [
        ...a.words,
        for (final w in b.words)
          w.copyWith(
            startOffsetUs: w.startOffsetUs + shift,
            endOffsetUs: w.endOffsetUs + shift,
          ),
      ],
    );
    return copyWith(
      captionTrack: captionTrack.copyWith(
        segments: [
          for (final s in _segments)
            if (s.id == firstId) merged else if (s.id != secondId) s,
        ],
      ),
    );
  }

  /// Whether a segment can be split before word [wordIndex].
  bool canSplitCaption(String id, int wordIndex) {
    final s = captionById(id);
    if (s == null || wordIndex < 1 || wordIndex >= s.words.length) {
      return false;
    }
    final at = s.words[wordIndex].startOffsetUs;
    return at >= TimelineLimits.minDurationUs &&
        s.durationUs - at >= TimelineLimits.minDurationUs;
  }

  /// Splits a segment before word [wordIndex]; the second part gets
  /// [newId].
  Timeline splitCaption(String id, int wordIndex, {required String newId}) {
    if (!canSplitCaption(id, wordIndex) || captionById(newId) != null) {
      return this;
    }
    final layout = TimelineLayout.of(this);
    final s = captionById(id)!;
    final at = s.words[wordIndex].startOffsetUs;
    final firstWords = s.words.sublist(0, wordIndex);
    final secondWords = [
      for (final w in s.words.sublist(wordIndex))
        w.copyWith(
          startOffsetUs: w.startOffsetUs - at,
          endOffsetUs: w.endOffsetUs - at,
        ),
    ];
    final first = s.copyWith(
      text: firstWords.map((w) => w.text).join(_wordGap),
      durationUs: at,
      words: firstWords,
    );
    final second = s.copyWith(
      id: newId,
      text: secondWords.map((w) => w.text).join(_wordGap),
      anchor: layout.anchorAt(layout.startOf(s.anchor) + at),
      durationUs: s.durationUs - at,
      words: secondWords,
    );
    return copyWith(
      captionTrack: captionTrack.copyWith(
        segments: [
          for (final seg in _segments)
            if (seg.id == id) ...[first, second] else seg,
        ],
      ),
    );
  }

  /// Moves a segment to start at [toUs], keeping its length.
  Timeline moveCaption(String id, int toUs) {
    final s = captionById(id);
    if (s == null) return this;
    final timing = ItemTimingMath(TimelineLayout.of(this))
        .move((anchor: s.anchor, durationUs: s.durationUs), toUs);
    return _replaceCaption(
      id,
      (seg) => seg.copyWith(anchor: timing.anchor, needsReview: false),
    );
  }

  Timeline trimCaption(String id, ClipEdge edge, int deltaUs) {
    final s = captionById(id);
    if (s == null || deltaUs == 0) return this;
    final layout = TimelineLayout.of(this);
    final timing = ItemTimingMath(layout)
        .trim((anchor: s.anchor, durationUs: s.durationUs), edge, deltaUs);
    final shift = edge == ClipEdge.start
        ? layout.startOf(timing.anchor) - layout.startOf(s.anchor)
        : 0;
    return _replaceCaption(
      id,
      (seg) => seg.copyWith(
        anchor: timing.anchor,
        durationUs: timing.durationUs,
        words: [
          for (final w in seg.words)
            w.copyWith(
              startOffsetUs: clampInt(
                w.startOffsetUs - shift,
                0,
                timing.durationUs,
              ),
              endOffsetUs: clampInt(
                w.endOffsetUs - shift,
                0,
                timing.durationUs,
              ),
            ),
        ],
      ),
    );
  }

  Timeline deleteCaption(String id) {
    if (captionById(id) == null) return this;
    return copyWith(
      captionTrack: captionTrack.copyWith(
        segments: [
          for (final s in _segments)
            if (s.id != id) s,
        ],
      ),
    );
  }

  Timeline clearCaptions() => _segments.isEmpty
      ? this
      : copyWith(captionTrack: captionTrack.copyWith(segments: const []));

  Timeline setCaptionStyle({CaptionPreset? preset, CaptionPosition? position}) {
    final next = captionTrack.copyWith(
      preset: preset ?? captionTrack.preset,
      position: position ?? captionTrack.position,
    );
    return next == captionTrack ? this : copyWith(captionTrack: next);
  }

  Timeline _replaceCaption(
    String id,
    CaptionSegment Function(CaptionSegment) update,
  ) => copyWith(
    captionTrack: captionTrack.copyWith(
      segments: replaceById(_segments, id, (s) => s.id, update),
    ),
  );
}

List<String> _splitWords(String text) =>
    text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

List<CaptionWord> _evenWords(List<String> words, int durationUs) {
  if (words.isEmpty) return const [];
  final each = durationUs / words.length;
  return [
    for (final (i, w) in words.indexed)
      CaptionWord(
        text: w,
        startOffsetUs: (each * i).round(),
        endOffsetUs: (each * (i + 1)).round(),
      ),
  ];
}
