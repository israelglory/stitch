import 'dart:math' as math;

import 'package:stitch/features/timeline/domain/item_timing.dart';
import 'package:stitch/features/timeline/domain/layout.dart';
import 'package:stitch/features/timeline/domain/limits.dart';
import 'package:stitch/features/timeline/domain/models.dart';
import 'package:stitch/features/timeline/domain/normalize.dart';
import 'package:stitch/features/timeline/domain/video_ops.dart';

/// Audio lane edits: music, sound effects, voiceover, extracted audio.
extension AudioOps on Timeline {
  AudioItem? audioById(String id) {
    for (final a in audioItems) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// Adds a whole audio file at [atUs] on the lowest free lane at or
  /// below [lane].
  Timeline addAudio({
    required String id,
    required String mediaId,
    required AudioKind kind,
    required String name,
    required int mediaDurationUs,
    required int atUs,
    int lane = 0,
  }) {
    if (audioById(id) != null || mediaDurationUs <= 0) return this;
    final layout = TimelineLayout.of(this);
    final start = ItemTimingMath(layout).clampStart(atUs, mediaDurationUs);
    return normalize(
      copyWith(
        audioItems: [
          ...audioItems,
          AudioItem(
            id: id,
            mediaId: mediaId,
            kind: kind,
            name: name,
            anchor: layout.anchorAt(start),
            mediaDurationUs: mediaDurationUs,
            sourceInUs: 0,
            sourceOutUs: mediaDurationUs,
            laneIndex: lane,
          ),
        ],
      ),
    );
  }

  /// Moves an item to start at [toUs], optionally onto [lane]. If the lane
  /// is taken at that time, the item goes to the next free lane.
  Timeline moveAudio(String id, int toUs, {int? lane}) {
    final item = audioById(id);
    if (item == null) return this;
    final timing = ItemTimingMath(TimelineLayout.of(this))
        .move((anchor: item.anchor, durationUs: item.durationUs), toUs);
    return normalize(
      _replaceAudio(
        id,
        (a) => a.copyWith(
          anchor: timing.anchor,
          laneIndex: lane ?? a.laneIndex,
          needsReview: false,
        ),
      ),
    );
  }

  /// Moves an edge by [deltaUs] of timeline time, trimming the source.
  /// The end of a looping item is fixed to the video end, so trimming it
  /// does nothing; turn looping off first.
  Timeline trimAudio(String id, ClipEdge edge, int deltaUs) {
    final item = audioById(id);
    if (item == null || deltaUs == 0) return this;
    if (edge == ClipEdge.end && item.loop) return this;
    final layout = TimelineLayout.of(this);
    final minSource = timelineToSourceUs(
      TimelineLimits.minDurationUs,
      item.speed,
    );
    final sourceDelta = timelineToSourceUs(deltaUs, item.speed);
    final AudioItem trimmed;
    switch (edge) {
      case ClipEdge.start:
        final start = layout.startOf(item.anchor);
        // Cannot start before zero on the timeline.
        final minIn = item.sourceInUs - timelineToSourceUs(start, item.speed);
        final sourceIn = clampInt(
          item.sourceInUs + sourceDelta,
          math.max(0, minIn),
          item.sourceOutUs - minSource,
        );
        final moved = sourceToTimelineUs(
          sourceIn - item.sourceInUs,
          item.speed,
        );
        trimmed = item.copyWith(
          sourceInUs: sourceIn,
          anchor: layout.anchorAt(start + moved),
        );
      case ClipEdge.end:
        trimmed = item.copyWith(
          sourceOutUs: clampInt(
            item.sourceOutUs + sourceDelta,
            item.sourceInUs + minSource,
            item.mediaDurationUs,
          ),
        );
    }
    if (trimmed == item) return this;
    return normalize(_replaceAudio(id, (_) => _clampFades(trimmed)));
  }

  bool canSplitAudio(String id, int atUs) {
    final item = audioById(id);
    if (item == null || item.loop) return false;
    return ItemTimingMath(TimelineLayout.of(this))
        .canSplit((anchor: item.anchor, durationUs: item.durationUs), atUs);
  }

  /// Splits at [atUs]; the second part gets [newId]. Not available while
  /// looping.
  Timeline splitAudio(String id, int atUs, {required String newId}) {
    if (!canSplitAudio(id, atUs) || audioById(newId) != null) return this;
    final layout = TimelineLayout.of(this);
    final item = audioById(id)!;
    final start = layout.startOf(item.anchor);
    final splitSource =
        item.sourceInUs + timelineToSourceUs(atUs - start, item.speed);
    final first = item.copyWith(sourceOutUs: splitSource, fadeOutUs: 0);
    final second = item.copyWith(
      id: newId,
      sourceInUs: splitSource,
      anchor: layout.anchorAt(atUs),
      fadeInUs: 0,
    );
    return normalize(
      copyWith(
        audioItems: [
          for (final a in audioItems)
            if (a.id == id) ...[_clampFades(first), _clampFades(second)] else a,
        ],
      ),
    );
  }

  Timeline setAudioVolume(String id, double volume) {
    final item = audioById(id);
    if (item == null) return this;
    final v = clampDouble(
      volume,
      TimelineLimits.minVolume,
      TimelineLimits.maxVolume,
    );
    return v == item.volume
        ? this
        : _replaceAudio(id, (a) => a.copyWith(volume: v));
  }

  /// Sets fade lengths. Each is at least zero, and together they fit in
  /// one pass of the item.
  Timeline setAudioFades(String id, {int? fadeInUs, int? fadeOutUs}) {
    final item = audioById(id);
    if (item == null) return this;
    final next = _clampFades(
      item.copyWith(
        fadeInUs: fadeInUs ?? item.fadeInUs,
        fadeOutUs: fadeOutUs ?? item.fadeOutUs,
      ),
    );
    return next == item ? this : _replaceAudio(id, (_) => next);
  }

  /// Sets speed (pitch is preserved by the engine), clamped so one pass
  /// stays at least the minimum length.
  Timeline setAudioSpeed(String id, double speed) {
    final item = audioById(id);
    if (item == null) return this;
    final maxForLength = item.sourceDurationUs / TimelineLimits.minDurationUs;
    final s = clampDouble(
      speed,
      TimelineLimits.minSpeed,
      math.min(TimelineLimits.maxSpeed, maxForLength),
    );
    if (s == item.speed) return this;
    return normalize(
      _replaceAudio(id, (a) => _clampFades(a.copyWith(speed: s))),
    );
  }

  /// Turns "loop to fill" on or off.
  Timeline setAudioLoop(String id, {required bool loop}) {
    final item = audioById(id);
    if (item == null || item.loop == loop) return this;
    return normalize(_replaceAudio(id, (a) => a.copyWith(loop: loop)));
  }

  Timeline deleteAudio(String id) {
    if (audioById(id) == null) return this;
    return copyWith(
      audioItems: [
        for (final a in audioItems)
          if (a.id != id) a,
      ],
    );
  }

  /// Whether [clipId]'s sound can be extracted. Photos have none, and
  /// sound already extracted cannot be extracted again. Whether the file
  /// has an audio track at all is checked by the caller.
  bool canExtractAudio(String clipId) {
    final clip = clipById(clipId);
    return clip != null && !clip.isPhoto && !clip.audioDetached;
  }

  /// Moves [clipId]'s sound to a new audio item under it, and silences
  /// the clip. The item is anchored to the clip, so it moves when earlier
  /// clips change, but it no longer follows this clip's trims.
  Timeline extractAudio(
    String clipId, {
    required String newId,
    required String name,
  }) {
    if (!canExtractAudio(clipId) || audioById(newId) != null) return this;
    final clip = clipById(clipId)!;
    final item = AudioItem(
      id: newId,
      mediaId: clip.mediaId,
      kind: AudioKind.extracted,
      name: name,
      anchor: Anchor.clip(clipId: clipId, sourceUs: clip.sourceInUs),
      mediaDurationUs: clip.mediaDurationUs!,
      sourceInUs: clip.sourceInUs,
      sourceOutUs: clip.sourceOutUs,
      volume: clip.volume,
      speed: clip.speed,
    );
    return normalize(
      copyWith(
        videoClips: replaceById(
          videoClips,
          clipId,
          (c) => c.id,
          (c) => c.copyWith(audioDetached: true),
        ),
        audioItems: [...audioItems, item],
      ),
    );
  }

  Timeline setAudioMix({
    bool? originalSoundEnabled,
    double? originalLevel,
    double? addedLevel,
  }) {
    double level(double? v, double current) => v == null
        ? current
        : clampDouble(v, TimelineLimits.minVolume, TimelineLimits.maxVolume);
    final next = audioMix.copyWith(
      originalSoundEnabled:
          originalSoundEnabled ?? audioMix.originalSoundEnabled,
      originalLevel: level(originalLevel, audioMix.originalLevel),
      addedLevel: level(addedLevel, audioMix.addedLevel),
    );
    return next == audioMix ? this : copyWith(audioMix: next);
  }

  Timeline _replaceAudio(String id, AudioItem Function(AudioItem) update) =>
      copyWith(audioItems: replaceById(audioItems, id, (a) => a.id, update));
}

AudioItem _clampFades(AudioItem item) {
  final length = item.durationUs;
  final fadeIn = clampInt(item.fadeInUs, 0, length);
  final fadeOut = clampInt(item.fadeOutUs, 0, length - fadeIn);
  return fadeIn == item.fadeInUs && fadeOut == item.fadeOutUs
      ? item
      : item.copyWith(fadeInUs: fadeIn, fadeOutUs: fadeOut);
}
