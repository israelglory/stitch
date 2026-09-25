import 'dart:math' as math;

import 'package:stitch/features/timeline/domain/layout.dart';
import 'package:stitch/features/timeline/domain/limits.dart';
import 'package:stitch/features/timeline/domain/models.dart';
import 'package:stitch/features/timeline/domain/normalize.dart';

enum ClipEdge { start, end }

/// Upper bound for photo clips, which have no source length.
const int _unbounded = 1 << 50;

/// Main track edits. The track is magnetic: clips are always back to back,
/// so removing or shortening a clip closes the gap.
///
/// Every operation returns the same instance when it does not apply (an
/// unknown id, a split too close to an edge); callers use that to skip
/// pushing undo history. `can*` methods let the UI disable tools.
extension VideoTrackOps on Timeline {
  Timeline insertClips(int index, List<VideoClip> clips) {
    if (clips.isEmpty) return this;
    final at = index.clamp(0, videoClips.length);
    return normalize(
      copyWith(
        videoClips: [...videoClips.take(at), ...clips, ...videoClips.skip(at)],
      ),
    );
  }

  Timeline appendClips(List<VideoClip> clips) =>
      insertClips(videoClips.length, clips);

  Timeline deleteClip(String clipId) {
    if (clipById(clipId) == null) return this;
    final before = TimelineLayout.of(this);
    final removed = copyWith(
      videoClips: [
        for (final c in videoClips)
          if (c.id != clipId) c,
      ],
    );
    return normalize(reanchorOrphans(removed, clipId: clipId, before: before));
  }

  /// Inserts a copy right after the original. Items anchored to the
  /// original are not copied. The original's transition stays in the cut
  /// after it.
  Timeline duplicateClip(String clipId, {required String newId}) {
    final index = indexOfClip(clipId);
    if (index < 0 || clipById(newId) != null) return this;
    return insertClips(index + 1, [videoClips[index].copyWith(id: newId)]);
  }

  /// Whether [clipId] can be split at timeline time [atUs]: both parts
  /// must be at least the minimum length.
  bool canSplitClip(String clipId, int atUs) {
    final span = TimelineLayout.of(this).span(clipId);
    if (span == null) return false;
    return atUs - span.startUs >= TimelineLimits.minDurationUs &&
        span.endUs - atUs >= TimelineLimits.minDurationUs;
  }

  /// Splits [clipId] at timeline time [atUs]. The second part gets
  /// [newId], the transition after the original, and every item anchored
  /// at or after the split point.
  Timeline splitClip(String clipId, int atUs, {required String newId}) {
    if (!canSplitClip(clipId, atUs) || clipById(newId) != null) return this;
    final layout = TimelineLayout.of(this);
    final span = layout.span(clipId)!;
    final clip = span.clip;
    final splitSource =
        clip.sourceInUs + timelineToSourceUs(atUs - span.startUs, clip.speed);

    final first = clip.copyWith(sourceOutUs: splitSource);
    final second = clip.copyWith(id: newId, sourceInUs: splitSource);

    final split = copyWith(
      videoClips: [
        for (final c in videoClips)
          if (c.id == clipId) ...[first, second] else c,
      ],
      transitions: [
        for (final t in transitions)
          t.afterClipId == clipId ? t.copyWith(afterClipId: newId) : t,
      ],
    );
    return normalize(
      mapAnchors(split, (a) {
        if (a is ClipAnchor &&
            a.clipId == clipId &&
            a.sourceUs >= splitSource) {
          return a.copyWith(clipId: newId);
        }
        return a;
      }),
    );
  }

  /// Moves an edge of [clipId] by [deltaUs] of timeline time. Positive
  /// moves right. Clamped to the source bounds and the minimum length.
  /// Later clips ripple.
  Timeline trimClip(String clipId, ClipEdge edge, int deltaUs) {
    final clip = clipById(clipId);
    if (clip == null || deltaUs == 0) return this;
    final minSource = timelineToSourceUs(
      TimelineLimits.minDurationUs,
      clip.speed,
    );
    final sourceDelta = timelineToSourceUs(deltaUs, clip.speed);

    final VideoClip trimmed;
    switch (edge) {
      case ClipEdge.start:
        final sourceIn = clampInt(
          clip.sourceInUs + sourceDelta,
          0,
          clip.sourceOutUs - minSource,
        );
        trimmed = clip.copyWith(sourceInUs: sourceIn);
      case ClipEdge.end:
        final maxOut = clip.mediaDurationUs ?? _unbounded;
        final sourceOut = clampInt(
          clip.sourceOutUs + sourceDelta,
          clip.sourceInUs + minSource,
          maxOut,
        );
        trimmed = clip.copyWith(sourceOutUs: sourceOut);
    }
    if (trimmed == clip) return this;
    return normalize(_replaceClip(clipId, (_) => trimmed));
  }

  /// Moves [clipId] to [toIndex] in the track. The transition after the
  /// clip moves with it.
  Timeline moveClip(String clipId, int toIndex) {
    final from = indexOfClip(clipId);
    if (from < 0) return this;
    final to = toIndex.clamp(0, videoClips.length - 1);
    if (from == to) return this;
    final clips = [...videoClips];
    final clip = clips.removeAt(from);
    clips.insert(to, clip);
    return normalize(copyWith(videoClips: clips));
  }

  /// Sets playback speed, clamped to the allowed range and so the clip
  /// stays at least the minimum length. Anchored items keep their content
  /// moment.
  Timeline setClipSpeed(String clipId, double speed) {
    final clip = clipById(clipId);
    if (clip == null) return this;
    final maxForLength = clip.sourceDurationUs / TimelineLimits.minDurationUs;
    final clamped = clampDouble(
      speed,
      TimelineLimits.minSpeed,
      math.min(TimelineLimits.maxSpeed, maxForLength),
    );
    if (clamped == clip.speed) return this;
    // Captions on this clip follow its speech: their lengths and word
    // times (in timeline time) scale with it.
    final ratio = clip.speed / clamped;
    int scaled(int us) => (us * ratio).round();
    final withCaptions = copyWith(
      captionTrack: captionTrack.copyWith(
        segments: [
          for (final seg in captionTrack.segments)
            if (seg.anchor case ClipAnchor(clipId: final id) when id == clipId)
              seg.copyWith(
                durationUs: math.max(
                  TimelineLimits.minDurationUs,
                  scaled(seg.durationUs),
                ),
                words: [
                  for (final w in seg.words)
                    w.copyWith(
                      startOffsetUs: scaled(w.startOffsetUs),
                      endOffsetUs: scaled(w.endOffsetUs),
                    ),
                ],
              )
            else
              seg,
        ],
      ),
    );
    return normalize(
      withCaptions._replaceClip(clipId, (c) => c.copyWith(speed: clamped)),
    );
  }

  Timeline setClipVolume(String clipId, double volume) {
    final clip = clipById(clipId);
    if (clip == null) return this;
    final clamped = clampDouble(
      volume,
      TimelineLimits.minVolume,
      TimelineLimits.maxVolume,
    );
    if (clamped == clip.volume) return this;
    return _replaceClip(clipId, (c) => c.copyWith(volume: clamped));
  }

  Timeline setClipFraming(String clipId, ClipFraming framing) {
    final clip = clipById(clipId);
    if (clip == null || clip.framing == framing) return this;
    return _replaceClip(clipId, (c) => c.copyWith(framing: framing));
  }

  /// Points everything that used [fromMediaId] (clips, and sound taken
  /// from them) at [toMediaId]: the same footage, found again. Trims,
  /// speed, and detached sound are kept; ranges past the end of a shorter
  /// file are cut back.
  Timeline relinkMedia(
    String fromMediaId, {
    required String toMediaId,
    required int? mediaDurationUs,
  }) {
    final uses =
        videoClips.any((c) => c.mediaId == fromMediaId) ||
        audioItems.any((a) => a.mediaId == fromMediaId);
    if (!uses) return this;
    final limit = mediaDurationUs ?? _unbounded;
    (int, int) fit(int sourceIn, int sourceOut) {
      final out = math.min(sourceOut, limit);
      final inUs = math.min(
        sourceIn,
        math.max(0, out - TimelineLimits.minDurationUs),
      );
      return (inUs, math.max(out, inUs + TimelineLimits.minDurationUs));
    }

    return normalize(
      copyWith(
        videoClips: [
          for (final c in videoClips)
            if (c.mediaId != fromMediaId)
              c
            else
              () {
                final (sourceIn, sourceOut) = fit(c.sourceInUs, c.sourceOutUs);
                return c.copyWith(
                  mediaId: toMediaId,
                  mediaDurationUs: mediaDurationUs,
                  sourceInUs: sourceIn,
                  sourceOutUs: sourceOut,
                );
              }(),
        ],
        audioItems: [
          for (final a in audioItems)
            if (a.mediaId != fromMediaId)
              a
            else
              () {
                final (sourceIn, sourceOut) = fit(a.sourceInUs, a.sourceOutUs);
                return a.copyWith(
                  mediaId: toMediaId,
                  mediaDurationUs: mediaDurationUs ?? a.mediaDurationUs,
                  sourceInUs: sourceIn,
                  sourceOutUs: sourceOut,
                );
              }(),
        ],
      ),
    );
  }

  /// Swaps the media of [clipId], keeping its timeline length when the new
  /// source is long enough (otherwise the clip shortens). Speed, volume,
  /// and framing are kept. Anchored items keep their offset into the clip.
  Timeline replaceClipMedia(
    String clipId, {
    required String mediaId,
    required MediaKind kind,
    required int? mediaDurationUs,
  }) {
    final clip = clipById(clipId);
    if (clip == null) return this;
    final wanted = clip.sourceDurationUs;
    final available = mediaDurationUs ?? wanted;
    final length = math.max(
      TimelineLimits.minDurationUs,
      math.min(wanted, available),
    );
    final replaced = clip.copyWith(
      mediaId: mediaId,
      kind: kind,
      mediaDurationUs: mediaDurationUs,
      sourceInUs: 0,
      sourceOutUs: length,
      audioDetached: false,
    );
    final oldIn = clip.sourceInUs;
    return normalize(
      mapAnchors(_replaceClip(clipId, (_) => replaced), (a) {
        if (a is ClipAnchor && a.clipId == clipId) {
          return a.copyWith(sourceUs: clampInt(a.sourceUs - oldIn, 0, length));
        }
        return a;
      }),
    );
  }

  Timeline _replaceClip(String id, VideoClip Function(VideoClip) update) =>
      copyWith(videoClips: replaceById(videoClips, id, (c) => c.id, update));
}
