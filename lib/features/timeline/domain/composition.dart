import 'dart:math' as math;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stitch/features/timeline/domain/layout.dart';
import 'package:stitch/features/timeline/domain/limits.dart';
import 'package:stitch/features/timeline/domain/models.dart';
import 'package:stitch/features/timeline/domain/normalize.dart';

part 'composition.freezed.dart';
part 'composition.g.dart';

// The timeline flattened to absolute times: what the native engines play
// and export. Preview and export both consume this one document, so they
// cannot disagree. Nothing here needs anchors or layout math to interpret.

@freezed
abstract class ResolvedClip with _$ResolvedClip {
  const factory({
    required String clipId,
    required String mediaId,
    required MediaKind kind,
    required int startUs,
    required int endUs,
    required int sourceInUs,
    required int sourceOutUs,
    required double speed,

    /// Final gain for the clip's own sound, including the original sound
    /// switch and level. Zero when muted or extracted.
    required double volume,

    /// Audio ramps, equal to the transitions on either side, so the sound
    /// crossfades with the picture.
    required int audioFadeInUs,
    required int audioFadeOutUs,
    required ClipFraming framing,
  }) = _ResolvedClip;

  factory fromJson(Map<String, dynamic> json) => _$ResolvedClipFromJson(json);
}

@freezed
abstract class ResolvedTransition with _$ResolvedTransition {
  const factory({
    required TransitionType type,
    required String fromClipId,
    required String toClipId,
    required int startUs,
    required int durationUs,
    @Default(<String, double>{}) Map<String, double> params,
  }) = _ResolvedTransition;

  factory fromJson(Map<String, dynamic> json) =>
      _$ResolvedTransitionFromJson(json);
}

@freezed
abstract class ResolvedText with _$ResolvedText {
  const factory({
    required String id,
    required String text,
    required int startUs,
    required int endUs,
    required int laneIndex,
    required TextStyleSpec style,
    required ItemTransform transform,
    required TextAnimation animationIn,
    required TextAnimation animationOut,
  }) = _ResolvedText;

  factory fromJson(Map<String, dynamic> json) => _$ResolvedTextFromJson(json);
}

@freezed
abstract class ResolvedWord with _$ResolvedWord {
  const factory({
    required String text,
    required int startUs,
    required int endUs,
  }) = _ResolvedWord;

  factory fromJson(Map<String, dynamic> json) => _$ResolvedWordFromJson(json);
}

@freezed
abstract class ResolvedCaption with _$ResolvedCaption {
  const factory({
    required String id,
    required String text,
    required int startUs,
    required int endUs,
    @Default(<ResolvedWord>[]) List<ResolvedWord> words,
  }) = _ResolvedCaption;

  factory fromJson(Map<String, dynamic> json) =>
      _$ResolvedCaptionFromJson(json);
}

@freezed
abstract class ResolvedAudio with _$ResolvedAudio {
  const factory({
    required String id,
    required String mediaId,
    required AudioKind kind,
    required int startUs,
    required int endUs,
    required int sourceInUs,
    required int sourceOutUs,
    required double speed,

    /// Repeat [sourceInUs] to [sourceOutUs] until [endUs].
    required bool loop,

    /// Final gain including the added-audio level.
    required double volume,
    required int fadeInUs,
    required int fadeOutUs,

    /// The item ran past the end of the video and was cut there.
    required bool cutAtVideoEnd,
  }) = _ResolvedAudio;

  factory fromJson(Map<String, dynamic> json) => _$ResolvedAudioFromJson(json);
}

@freezed
abstract class ResolvedComposition with _$ResolvedComposition {
  const factory({
    required int durationUs,
    @Default(<ResolvedClip>[]) List<ResolvedClip> clips,
    @Default(<ResolvedTransition>[]) List<ResolvedTransition> transitions,
    @Default(<ResolvedText>[]) List<ResolvedText> texts,
    @Default(<ResolvedCaption>[]) List<ResolvedCaption> captions,
    @Default(CaptionPreset.plain) CaptionPreset captionPreset,
    @Default(CaptionPosition.bottom) CaptionPosition captionPosition,
    @Default(<ResolvedAudio>[]) List<ResolvedAudio> audio,
  }) = _ResolvedComposition;

  factory fromJson(Map<String, dynamic> json) =>
      _$ResolvedCompositionFromJson(json);

  /// Flattens [timeline].
  factory resolve(Timeline timeline) => _resolve(timeline);
}

ResolvedComposition _resolve(Timeline timeline) {
  final layout = TimelineLayout.of(timeline);
  final duration = layout.durationUs;
  final mix = timeline.audioMix;
  final spans = layout.spans;

  final clips = <ResolvedClip>[
    for (final (i, span) in spans.indexed)
      ResolvedClip(
        clipId: span.clip.id,
        mediaId: span.clip.mediaId,
        kind: span.clip.kind,
        startUs: span.startUs,
        endUs: span.endUs,
        sourceInUs: span.clip.sourceInUs,
        sourceOutUs: span.clip.sourceOutUs,
        speed: span.clip.speed,
        volume:
            span.clip.isPhoto ||
                span.clip.audioDetached ||
                !mix.originalSoundEnabled
            ? 0
            : span.clip.volume * mix.originalLevel,
        audioFadeInUs: i == 0 ? 0 : layout.transitionUs(spans[i - 1].clip.id),
        audioFadeOutUs: layout.transitionUs(span.clip.id),
        framing: span.clip.framing,
      ),
  ];

  final transitions = <ResolvedTransition>[
    for (var i = 0; i + 1 < spans.length; i++)
      if (timeline.transitionAfter(spans[i].clip.id) case final t?)
        if (layout.transitionUs(t.afterClipId) > 0)
          ResolvedTransition(
            type: t.type,
            fromClipId: t.afterClipId,
            toClipId: spans[i + 1].clip.id,
            startUs: spans[i + 1].startUs,
            durationUs: layout.transitionUs(t.afterClipId),
            params: t.params,
          ),
  ];

  final texts = <ResolvedText>[
    for (final item in timeline.textItems)
      if (_window(layout.startOf(item.anchor), item.durationUs, duration) case (
        final start,
        final end,
      ))
        ResolvedText(
          id: item.id,
          text: item.text,
          startUs: start,
          endUs: end,
          laneIndex: item.laneIndex,
          style: item.style,
          transform: item.transform,
          animationIn: item.animationIn,
          animationOut: item.animationOut,
        ),
  ];

  final captions = <ResolvedCaption>[
    for (final s in timeline.captionTrack.segments)
      if (layout.resolve(s.anchor) case final pos when pos.inRange)
        if (_window(pos.startUs, s.durationUs, duration) case (
          final start,
          final end,
        ))
          ResolvedCaption(
            id: s.id,
            text: s.text,
            startUs: start,
            endUs: end,
            words: [
              for (final w in s.words)
                if (pos.startUs + w.startOffsetUs < end)
                  ResolvedWord(
                    text: w.text,
                    startUs: pos.startUs + w.startOffsetUs,
                    endUs: math.min(end, pos.startUs + w.endOffsetUs),
                  ),
            ],
          ),
  ]..sort((a, b) => a.startUs.compareTo(b.startUs));

  final audio = <ResolvedAudio>[
    for (final item in timeline.audioItems) ?_resolveAudio(item, layout, mix),
  ];

  return ResolvedComposition(
    durationUs: duration,
    clips: clips,
    transitions: transitions,
    texts: texts,
    captions: captions,
    captionPreset: timeline.captionTrack.preset,
    captionPosition: timeline.captionTrack.position,
    audio: audio,
  );
}

/// The part of [start, start + length) inside the video, or null when none
/// of it is.
(int, int)? _window(int start, int length, int videoDurationUs) {
  final end = math.min(start + length, videoDurationUs);
  return end > start ? (start, end) : null;
}

ResolvedAudio? _resolveAudio(
  AudioItem item,
  TimelineLayout layout,
  AudioMix mix,
) {
  final start = layout.startOf(item.anchor);
  final naturalEnd = audioEndUs(item, layout);
  final window = _window(start, naturalEnd - start, layout.durationUs);
  if (window == null) return null;
  final (_, end) = window;
  final length = end - start;
  final fadeIn = clampInt(item.fadeInUs, 0, length);
  return ResolvedAudio(
    id: item.id,
    mediaId: item.mediaId,
    kind: item.kind,
    startUs: start,
    endUs: end,
    sourceInUs: item.sourceInUs,
    sourceOutUs: item.sourceOutUs,
    speed: item.speed,
    loop: item.loop,
    volume: item.volume * mix.addedLevel,
    fadeInUs: fadeIn,
    fadeOutUs: clampInt(item.fadeOutUs, 0, length - fadeIn),
    cutAtVideoEnd: end < naturalEnd,
  );
}
