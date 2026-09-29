import 'dart:math' as math;

import 'package:stitch/features/timeline/domain/layout.dart';
import 'package:stitch/features/timeline/domain/limits.dart';
import 'package:stitch/features/timeline/domain/models.dart';
import 'package:stitch/features/timeline/domain/normalize.dart';

// Keyframes: values of an item that change over time.
//
// A keyframe stores all of an item's animatable values ([KeyframeValues]).
// Between two keyframes each value moves from one to the other, shaped by
// the first one's [KeyframeEasing]; before the first and after the last,
// the nearest keyframe's values hold. An item without keyframes uses its
// own fields (its "base" values).
//
// The evaluation below is the contract with the native engines, which
// repeat it exactly (Keyframes.swift, Keyframes.kt): preview, export, and
// the editor agree.

/// [p] (0 to 1, the progress between two keyframes) shaped by [easing].
/// Cubic curves; hold keeps the first keyframe's values until the next.
double easeProgress(KeyframeEasing easing, double p) => switch (easing) {
  KeyframeEasing.linear => p,
  KeyframeEasing.easeIn => p * p * p,
  KeyframeEasing.easeOut => 1 - math.pow(1 - p, 3).toDouble(),
  KeyframeEasing.easeInOut =>
    p < 0.5 ? 4 * p * p * p : 1 - math.pow(-2 * p + 2, 3).toDouble() / 2,
  KeyframeEasing.hold => 0,
};

double _lerp(double a, double b, double t) => a + (b - a) * t;

extension KeyframeValuesMath on KeyframeValues {
  /// Each value [t] (0 to 1) of the way to [to].
  KeyframeValues lerpTo(KeyframeValues to, double t) => KeyframeValues(
    x: _lerp(x, to.x, t),
    y: _lerp(y, to.y, t),
    scale: _lerp(scale, to.scale, t),
    rotationDeg: _lerp(rotationDeg, to.rotationDeg, t),
    opacity: _lerp(opacity, to.opacity, t),
    volume: _lerp(volume, to.volume, t),
  );

  /// Within the editing limits.
  KeyframeValues clamped() {
    final next = copyWith(
      scale: clampDouble(
        scale,
        TimelineLimits.minScale,
        TimelineLimits.maxScale,
      ),
      opacity: clampDouble(opacity, 0, 1),
      volume: clampDouble(
        volume,
        TimelineLimits.minVolume,
        TimelineLimits.maxVolume,
      ),
    );
    return next == this ? this : next;
  }
}

extension KeyframeListMath on List<Keyframe> {
  /// Values at [timeUs] (in this list's time base), or null when empty.
  /// The list is sorted by time.
  KeyframeValues? valuesAt(int timeUs) {
    if (isEmpty) return null;
    if (timeUs <= first.timeUs) return first.values;
    if (timeUs >= last.timeUs) return last.values;
    // The last keyframe at or before timeUs.
    var lo = 0;
    var hi = length - 1;
    while (hi - lo > 1) {
      final mid = (lo + hi) >> 1;
      if (this[mid].timeUs <= timeUs) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    final a = this[lo];
    final b = this[lo + 1];
    final p = (timeUs - a.timeUs) / (b.timeUs - a.timeUs);
    return a.values.lerpTo(b.values, easeProgress(a.easing, p));
  }

  /// The keyframe nearest [timeUs], if within [toleranceUs].
  Keyframe? near(int timeUs, int toleranceUs) {
    Keyframe? best;
    var bestDistance = toleranceUs + 1;
    for (final k in this) {
      final d = (k.timeUs - timeUs).abs();
      if (d < bestDistance) {
        best = k;
        bestDistance = d;
      }
    }
    return best;
  }

  List<Keyframe> shifted(int deltaUs) => deltaUs == 0
      ? this
      : [for (final k in this) k.copyWith(timeUs: k.timeUs + deltaUs)];

  /// The keyframes that shape [fromUs] to [toUs]: those inside, and the
  /// nearest one on each side (values inside are interpolated toward it).
  /// For the parts of a split.
  List<Keyframe> within(int fromUs, int toUs) {
    final before = lastWhere((k) => k.timeUs < fromUs, orElse: () => _none);
    final after = firstWhere((k) => k.timeUs > toUs, orElse: () => _none);
    return [
      if (!identical(before, _none)) before,
      for (final k in this)
        if (k.timeUs >= fromUs && k.timeUs <= toUs) k,
      if (!identical(after, _none)) after,
    ];
  }

  /// Sorted by time, with values within limits; this list when it already
  /// is.
  List<Keyframe> normalized() {
    var sorted = true;
    var clamped = true;
    for (var i = 0; i < length; i++) {
      if (i > 0 && this[i - 1].timeUs > this[i].timeUs) sorted = false;
      if (!identical(this[i].values.clamped(), this[i].values)) {
        clamped = false;
      }
    }
    if (sorted && clamped) return this;
    final list = [
      for (final k in this)
        clamped ? k : k.copyWith(values: k.values.clamped()),
    ];
    if (!sorted) list.sort((a, b) => a.timeUs.compareTo(b.timeUs));
    return list;
  }
}

/// Values at timeline time [timeUs] as the engines compute them, from
/// [keyframes] with their times on the timeline (a resolved item's). A
/// looping item's repeat every [loopUs] from [loopStartUs]. Null when
/// there are none: the item's own values apply.
KeyframeValues? engineValuesAt(
  List<Keyframe> keyframes,
  int timeUs, {
  int loopStartUs = 0,
  int loopUs = 0,
}) {
  final t = loopUs > 0 && timeUs >= loopStartUs
      ? loopStartUs + (timeUs - loopStartUs) % loopUs
      : timeUs;
  return keyframes.valuesAt(t);
}

const _none = Keyframe(id: '', timeUs: 0, values: KeyframeValues());

/// Timeline time at which [item]'s `sourceInUs` plays (on its first pass).
/// Before the timeline start for extracted sound whose clip was trimmed at
/// the front: it plays from later in the file to stay in sync.
int audioOriginUs(AudioItem item, TimelineLayout layout) {
  final start = layout.startOf(item.anchor);
  return item.loop
      ? start
      : math.min(start, layout.unboundedStartOf(item.anchor));
}

/// Kinds of item that hold keyframes.
enum KeyframeOwnerKind { clip, text, audio }

/// An item that holds keyframes.
typedef KeyframeOwner = ({KeyframeOwnerKind kind, String id});

/// Keyframe edits. Like every timeline operation, each returns the same
/// instance when it does not apply.
extension KeyframeOps on Timeline {
  List<Keyframe> keyframesOf(KeyframeOwner owner) => switch (owner.kind) {
    KeyframeOwnerKind.clip => clipById(owner.id)?.keyframes ?? const [],
    KeyframeOwnerKind.text => _text(owner.id)?.keyframes ?? const [],
    KeyframeOwnerKind.audio => _audio(owner.id)?.keyframes ?? const [],
  };

  /// The item's own fields, used when it has no keyframes.
  KeyframeValues? baseValuesOf(KeyframeOwner owner) {
    switch (owner.kind) {
      case KeyframeOwnerKind.clip:
        final c = clipById(owner.id);
        if (c == null) return null;
        return KeyframeValues(
          x: c.framing.offsetX,
          y: c.framing.offsetY,
          scale: c.framing.scale,
          rotationDeg: c.framing.rotationDeg,
          opacity: c.opacity,
          volume: c.volume,
        );
      case KeyframeOwnerKind.text:
        final t = _text(owner.id);
        if (t == null) return null;
        return KeyframeValues(
          x: t.transform.x,
          y: t.transform.y,
          scale: t.transform.scale,
          rotationDeg: t.transform.rotationDeg,
          opacity: t.opacity,
        );
      case KeyframeOwnerKind.audio:
        final a = _audio(owner.id);
        return a == null ? null : KeyframeValues(volume: a.volume);
    }
  }

  /// [owner]'s keyframe time at timeline time [atUs], or null when
  /// [atUs] is outside the item.
  int? keyframeTimeAt(KeyframeOwner owner, int atUs, [TimelineLayout? l]) {
    final layout = l ?? TimelineLayout.of(this);
    switch (owner.kind) {
      case KeyframeOwnerKind.clip:
        final span = layout.span(owner.id);
        if (span == null || atUs < span.startUs || atUs > span.endUs) {
          return null;
        }
        final clip = span.clip;
        return clip.sourceInUs +
            timelineToSourceUs(atUs - span.startUs, clip.speed);
      case KeyframeOwnerKind.text:
        final item = _text(owner.id);
        if (item == null) return null;
        final start = layout.startOf(item.anchor);
        if (atUs < start || atUs > start + item.durationUs) return null;
        return atUs - start;
      case KeyframeOwnerKind.audio:
        final item = _audio(owner.id);
        if (item == null) return null;
        final origin = audioOriginUs(item, layout);
        final end = item.loop
            ? audioEndUs(item, layout)
            : origin + item.durationUs;
        if (atUs < layout.startOf(item.anchor) || atUs > end) return null;
        // Looping items repeat their keyframes with each pass.
        final pass = item.durationUs;
        final into = item.loop && pass > 0
            ? (atUs - origin) % pass
            : atUs - origin;
        return item.sourceInUs + timelineToSourceUs(into, item.speed);
    }
  }

  /// [owner]'s keyframes with their times on the timeline (the first
  /// pass of a looping item), for the engines. Only those that shape the
  /// item while it shows: the ones inside it and the nearest on each side.
  List<Keyframe> keyframesOnTimeline(KeyframeOwner owner, [TimelineLayout? l]) {
    final keyframes = keyframesOf(owner);
    if (keyframes.isEmpty) return const [];
    final layout = l ?? TimelineLayout.of(this);
    final (int from, int to) = switch (owner.kind) {
      KeyframeOwnerKind.clip => switch (layout.span(owner.id)) {
        null => (0, -1),
        final span => (span.startUs, span.endUs),
      },
      KeyframeOwnerKind.text => switch (_text(owner.id)) {
        null => (0, -1),
        final t => (
          layout.startOf(t.anchor),
          layout.startOf(t.anchor) + t.durationUs,
        ),
      },
      KeyframeOwnerKind.audio => switch (_audio(owner.id)) {
        null => (0, -1),
        final a => (
          audioOriginUs(a, layout),
          audioOriginUs(a, layout) + a.durationUs,
        ),
      },
    };
    if (to < from) return const [];
    return [
      for (final k in keyframes)
        k.copyWith(timeUs: timelineTimeOfKeyframe(owner, k.timeUs, layout)!),
    ].within(from, to);
  }

  /// Timeline time of [owner]'s keyframe time [timeUs] (the first pass of
  /// a looping item), or null for an unknown item.
  int? timelineTimeOfKeyframe(
    KeyframeOwner owner,
    int timeUs, [
    TimelineLayout? l,
  ]) {
    final layout = l ?? TimelineLayout.of(this);
    switch (owner.kind) {
      case KeyframeOwnerKind.clip:
        final span = layout.span(owner.id);
        if (span == null) return null;
        return span.startUs +
            sourceToTimelineUs(timeUs - span.clip.sourceInUs, span.clip.speed);
      case KeyframeOwnerKind.text:
        final item = _text(owner.id);
        return item == null ? null : layout.startOf(item.anchor) + timeUs;
      case KeyframeOwnerKind.audio:
        final item = _audio(owner.id);
        if (item == null) return null;
        return audioOriginUs(item, layout) +
            sourceToTimelineUs(timeUs - item.sourceInUs, item.speed);
    }
  }

  /// [owner]'s values at timeline time [atUs] (its base values outside
  /// the item), or null for an unknown item. Pass [l], this timeline's
  /// layout, when it is at hand: at every playback tick, building it is
  /// the expensive part.
  KeyframeValues? valuesAt(KeyframeOwner owner, int atUs, [TimelineLayout? l]) {
    final base = baseValuesOf(owner);
    if (base == null) return null;
    final time = keyframeTimeAt(owner, atUs, l);
    if (time == null) return base;
    return keyframesOf(owner).valuesAt(time) ?? base;
  }

  /// The keyframe of [owner] under timeline time [atUs] (within the
  /// keyframe spacing), if any.
  Keyframe? keyframeAt(KeyframeOwner owner, int atUs, [TimelineLayout? l]) {
    final time = keyframeTimeAt(owner, atUs, l);
    if (time == null) return null;
    return keyframesOf(owner).near(time, _localUs(owner, _onKeyframeUs));
  }

  /// Adds a keyframe of [owner] at timeline time [atUs] holding its
  /// current values there. Not within the keyframe spacing of another.
  Timeline addKeyframe(KeyframeOwner owner, int atUs, {required String id}) {
    final layout = TimelineLayout.of(this);
    final time = keyframeTimeAt(owner, atUs, layout);
    final values = valuesAt(owner, atUs, layout);
    if (time == null || values == null) return this;
    final keyframes = keyframesOf(owner);
    final spacing = _localUs(owner, TimelineLimits.keyframeSpacingUs);
    if (keyframes.near(time, spacing - 1) != null ||
        keyframes.any((k) => k.id == id)) {
      return this;
    }
    return _withKeyframes(owner, [
      ...keyframes,
      Keyframe(id: id, timeUs: time, values: values),
    ]);
  }

  /// Removes keyframe [keyframeId] of [owner]. Removing the last one keeps
  /// its values as the item's own, so nothing jumps.
  Timeline removeKeyframe(KeyframeOwner owner, String keyframeId) {
    final keyframes = keyframesOf(owner);
    final removed = keyframes.where((k) => k.id == keyframeId).firstOrNull;
    if (removed == null) return this;
    final rest = [
      for (final k in keyframes)
        if (k.id != keyframeId) k,
    ];
    final next = _withKeyframes(owner, rest);
    return rest.isEmpty ? next._withBase(owner, removed.values) : next;
  }

  Timeline setKeyframeEasing(
    KeyframeOwner owner,
    String keyframeId,
    KeyframeEasing easing,
  ) {
    final keyframes = keyframesOf(owner);
    if (!keyframes.any((k) => k.id == keyframeId && k.easing != easing)) {
      return this;
    }
    return _withKeyframes(owner, [
      for (final k in keyframes)
        k.id == keyframeId ? k.copyWith(easing: easing) : k,
    ]);
  }

  /// Changes [owner]'s values at timeline time [atUs] (a drag on the
  /// canvas, a slider). Without keyframes this sets the item's own values;
  /// with keyframes it records one at [atUs]: the keyframe there changes,
  /// or a new one ([newKeyframeId]) is added holding the current values
  /// with the change.
  Timeline setValuesAt(
    KeyframeOwner owner,
    int atUs,
    KeyframeValues Function(KeyframeValues current) change, {
    required String newKeyframeId,
  }) {
    final layout = TimelineLayout.of(this);
    final current = valuesAt(owner, atUs, layout);
    if (current == null) return this;
    final next = change(current).clamped();
    final keyframes = keyframesOf(owner);
    if (keyframes.isEmpty) return _withBase(owner, next);
    final time = keyframeTimeAt(owner, atUs, layout);
    if (time == null) return this;
    final existing = keyframeAt(owner, atUs, layout);
    if (existing != null) {
      if (existing.values == next) return this;
      return _withKeyframes(owner, [
        for (final k in keyframes)
          k.id == existing.id ? k.copyWith(values: next) : k,
      ]);
    }
    if (keyframes.any((k) => k.id == newKeyframeId)) return this;
    return _withKeyframes(owner, [
      ...keyframes,
      Keyframe(id: newKeyframeId, timeUs: time, values: next),
    ]);
  }

  /// Within this of a keyframe the playhead is on it: the window in which
  /// [addKeyframe] refuses a new one, so the keyframe button never offers
  /// an add that would do nothing. (The playhead rarely lands exactly on
  /// a keyframe: players report frame times, a few milliseconds off.)
  static const int _onKeyframeUs = TimelineLimits.keyframeSpacingUs - 1;

  /// [timelineUs] in [owner]'s time base (source time runs faster at
  /// higher speed).
  int _localUs(KeyframeOwner owner, int timelineUs) => switch (owner.kind) {
    KeyframeOwnerKind.clip => timelineToSourceUs(
      timelineUs,
      clipById(owner.id)?.speed ?? 1,
    ),
    KeyframeOwnerKind.text => timelineUs,
    KeyframeOwnerKind.audio => timelineToSourceUs(
      timelineUs,
      _audio(owner.id)?.speed ?? 1,
    ),
  };

  TextItem? _text(String id) => textItems.where((t) => t.id == id).firstOrNull;

  AudioItem? _audio(String id) =>
      audioItems.where((a) => a.id == id).firstOrNull;

  Timeline _withKeyframes(KeyframeOwner owner, List<Keyframe> keyframes) {
    final sorted = keyframes.normalized();
    return switch (owner.kind) {
      KeyframeOwnerKind.clip => copyWith(
        videoClips: replaceById(
          videoClips,
          owner.id,
          (c) => c.id,
          (c) => c.copyWith(keyframes: sorted),
        ),
      ),
      KeyframeOwnerKind.text => copyWith(
        textItems: replaceById(
          textItems,
          owner.id,
          (t) => t.id,
          (t) => t.copyWith(keyframes: sorted),
        ),
      ),
      KeyframeOwnerKind.audio => copyWith(
        audioItems: replaceById(
          audioItems,
          owner.id,
          (a) => a.id,
          (a) => a.copyWith(keyframes: sorted),
        ),
      ),
    };
  }

  Timeline _withBase(KeyframeOwner owner, KeyframeValues values) {
    final v = values.clamped();
    return switch (owner.kind) {
      KeyframeOwnerKind.clip => copyWith(
        videoClips: replaceById(
          videoClips,
          owner.id,
          (c) => c.id,
          (c) => c.copyWith(
            framing: c.framing.copyWith(
              offsetX: v.x,
              offsetY: v.y,
              scale: v.scale,
              rotationDeg: v.rotationDeg,
            ),
            opacity: v.opacity,
            volume: v.volume,
          ),
        ),
      ),
      KeyframeOwnerKind.text => copyWith(
        textItems: replaceById(
          textItems,
          owner.id,
          (t) => t.id,
          (t) => t.copyWith(
            transform: t.transform.copyWith(
              x: v.x,
              y: v.y,
              scale: v.scale,
              rotationDeg: v.rotationDeg,
            ),
            opacity: v.opacity,
          ),
        ),
      ),
      KeyframeOwnerKind.audio => copyWith(
        audioItems: replaceById(
          audioItems,
          owner.id,
          (a) => a.id,
          (a) => a.copyWith(volume: v.volume),
        ),
      ),
    };
  }
}
