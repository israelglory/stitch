import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stitch/features/timeline/domain/limits.dart';

part 'models.freezed.dart';
part 'models.g.dart';

// Timeline data model. Immutable, JSON-serializable, pure Dart.
//
// Positions of text, caption, and audio items are never stored as absolute
// times. Each item holds an [Anchor] into the content of a clip, and its
// timeline position is derived (see layout.dart). Edits to earlier clips
// therefore move items with their content without any bookkeeping.

enum MediaKind { video, photo, audio }

/// Where an item starts.
@freezed
sealed class Anchor with _$Anchor {
  /// At source time [sourceUs] of clip [clipId]: the item follows that
  /// moment of content through trims, speed changes, and reordering.
  const factory clip({required String clipId, required int sourceUs}) =
      ClipAnchor;

  /// At an absolute time. Only used when there are no clips to anchor to.
  const factory time({required int startUs}) = TimeAnchor;

  factory fromJson(Map<String, dynamic> json) => _$AnchorFromJson(json);
}

/// How values move from one keyframe to the next. Applied to the progress
/// p (0 to 1) between the two; the same formulas are in the native
/// engines (see keyframes.dart).
enum KeyframeEasing { linear, easeIn, easeOut, easeInOut, hold }

/// An item's animatable values at one moment: a keyframe stores all of
/// them (a snapshot), and each is interpolated on its own.
///
/// [x] and [y] follow the item's own convention: for clips, the offset from
/// the canvas center as a fraction of the canvas (as [ClipFraming]); for
/// text, the center as a fraction of the canvas (as [ItemTransform]).
/// [volume] is used by clips and audio items. New values get defaults, so
/// older projects keep loading.
@freezed
abstract class KeyframeValues with _$KeyframeValues {
  const factory({
    @Default(0.0) double x,
    @Default(0.0) double y,
    @Default(1.0) double scale,
    @Default(0.0) double rotationDeg,
    @Default(1.0) double opacity,
    @Default(1.0) double volume,
  }) = _KeyframeValues;

  factory fromJson(Map<String, dynamic> json) => _$KeyframeValuesFromJson(json);
}

/// One keyframe of an item. [timeUs] is in source time for clips and audio
/// items, so keyframes follow their content through trims, splits, and
/// speed changes; for text, it is the offset from the item's start.
/// [easing] shapes the way to the next keyframe.
@freezed
abstract class Keyframe with _$Keyframe {
  const factory({
    required String id,
    required int timeUs,
    required KeyframeValues values,
    @Default(KeyframeEasing.linear) KeyframeEasing easing,
  }) = _Keyframe;

  factory fromJson(Map<String, dynamic> json) => _$KeyframeFromJson(json);
}

enum FramingMode { fit, fill, manual }

/// How a clip sits on the canvas. Offsets are fractions of the canvas
/// size from center; rotation is in degrees clockwise.
@freezed
abstract class ClipFraming with _$ClipFraming {
  const factory({
    @Default(FramingMode.fit) FramingMode mode,
    @Default(1.0) double scale,
    @Default(0.0) double offsetX,
    @Default(0.0) double offsetY,
    @Default(0.0) double rotationDeg,
  }) = _ClipFraming;

  factory fromJson(Map<String, dynamic> json) => _$ClipFramingFromJson(json);
}

/// A span of a video or photo on the main track.
@freezed
abstract class VideoClip with _$VideoClip {
  const factory({
    required String id,
    required String mediaId,
    required MediaKind kind,

    /// Length of the source file, or null for photos, which have no
    /// natural length.
    required int? mediaDurationUs,
    required int sourceInUs,
    required int sourceOutUs,
    @Default(1.0) double speed,
    @Default(1.0) double volume,

    /// The clip's audio was extracted to an audio item, so the clip itself
    /// plays silent.
    @Default(false) bool audioDetached,
    @Default(ClipFraming()) ClipFraming framing,

    /// 0 shows only the background, 1 the clip.
    @Default(1.0) double opacity,

    /// Sorted by time. Empty: the values above hold for the whole clip.
    @Default(<Keyframe>[]) List<Keyframe> keyframes,
  }) = _VideoClip;
  const new _();

  factory fromJson(Map<String, dynamic> json) => _$VideoClipFromJson(json);

  /// A photo clip with the default duration.
  factory photo({required String id, required String mediaId}) => VideoClip(
    id: id,
    mediaId: mediaId,
    kind: MediaKind.photo,
    mediaDurationUs: null,
    sourceInUs: 0,
    sourceOutUs: TimelineLimits.photoDurationUs,
  );

  /// A whole video file.
  factory video({
    required String id,
    required String mediaId,
    required int mediaDurationUs,
  }) => VideoClip(
    id: id,
    mediaId: mediaId,
    kind: MediaKind.video,
    mediaDurationUs: mediaDurationUs,
    sourceInUs: 0,
    sourceOutUs: mediaDurationUs,
  );

  int get sourceDurationUs => sourceOutUs - sourceInUs;

  /// Length on the timeline after speed.
  int get durationUs => sourceToTimelineUs(sourceDurationUs, speed);

  bool get isPhoto => kind == MediaKind.photo;
}

enum TransitionType {
  crossfade,
  fadeToBlack,
  slideLeft,
  slideRight,
  wipeLeft,
  wipeRight,
  zoomIn,
}

/// A transition in the cut after clip [afterClipId]. The two clips overlap
/// by [durationUs]. No transition means a hard cut.
@freezed
abstract class Transition with _$Transition {
  const factory({
    required String afterClipId,
    required TransitionType type,
    required int durationUs,
    @Default(<String, double>{}) Map<String, double> params,
  }) = _Transition;

  factory fromJson(Map<String, dynamic> json) => _$TransitionFromJson(json);
}

/// Position, scale, and rotation of an overlay on the canvas. [x] and [y]
/// are the center as fractions of the canvas (0.5, 0.5 is centered).
@freezed
abstract class ItemTransform with _$ItemTransform {
  const factory({
    @Default(0.5) double x,
    @Default(0.5) double y,
    @Default(1.0) double scale,
    @Default(0.0) double rotationDeg,
  }) = _ItemTransform;

  factory fromJson(Map<String, dynamic> json) => _$ItemTransformFromJson(json);
}

enum TextAlignment { start, center, end }

/// Visual style of a text item. Colors are ARGB integers.
@freezed
abstract class TextStyleSpec with _$TextStyleSpec {
  const factory({
    @Default('inter') String fontId,

    /// Font size as a fraction of the canvas height.
    @Default(0.05) double size,
    @Default(0xFFFFFFFF) int color,
    int? strokeColor,

    /// Stroke width as a fraction of the font size; 0 for none.
    @Default(0.0) double strokeWidth,

    /// Fill of a rounded box behind the text, or null for none.
    int? backgroundColor,
    @Default(TextAlignment.center) TextAlignment alignment,
  }) = _TextStyleSpec;

  factory fromJson(Map<String, dynamic> json) => _$TextStyleSpecFromJson(json);
}

enum TextAnimation { none, fade, slideUp, slideDown, scale, typewriter }

@freezed
abstract class TextItem with _$TextItem {
  const factory({
    required String id,
    required String text,
    required Anchor anchor,
    required int durationUs,
    @Default(0) int laneIndex,
    @Default(TextStyleSpec()) TextStyleSpec style,
    @Default(ItemTransform()) ItemTransform transform,
    @Default(TextAnimation.none) TextAnimation animationIn,
    @Default(TextAnimation.none) TextAnimation animationOut,
    @Default(1.0) double opacity,

    /// Sorted by time (from the item's start). Empty: [transform] and
    /// [opacity] hold for the whole item.
    @Default(<Keyframe>[]) List<Keyframe> keyframes,

    /// The clip this item was anchored to was deleted.
    @Default(false) bool needsReview,
  }) = _TextItem;

  factory fromJson(Map<String, dynamic> json) => _$TextItemFromJson(json);
}

/// One recognized word. Times are offsets from its segment's start, so
/// words move with the segment.
@freezed
abstract class CaptionWord with _$CaptionWord {
  const factory({
    required String text,
    required int startOffsetUs,
    required int endOffsetUs,
  }) = _CaptionWord;

  factory fromJson(Map<String, dynamic> json) => _$CaptionWordFromJson(json);
}

@freezed
abstract class CaptionSegment with _$CaptionSegment {
  const factory({
    required String id,
    required String text,
    required Anchor anchor,
    required int durationUs,
    @Default(<CaptionWord>[]) List<CaptionWord> words,
    @Default(false) bool needsReview,
  }) = _CaptionSegment;

  factory fromJson(Map<String, dynamic> json) => _$CaptionSegmentFromJson(json);
}

enum CaptionPreset { plain, boxed, highlightWord, outline }

enum CaptionPosition { top, middle, bottom }

@freezed
abstract class CaptionTrack with _$CaptionTrack {
  const factory({
    @Default(<CaptionSegment>[]) List<CaptionSegment> segments,
    @Default(CaptionPreset.plain) CaptionPreset preset,
    @Default(CaptionPosition.bottom) CaptionPosition position,

    /// BCP 47 language of the recognized speech, if known.
    String? language,
  }) = _CaptionTrack;

  factory fromJson(Map<String, dynamic> json) => _$CaptionTrackFromJson(json);
}

enum AudioKind { music, soundEffect, voiceover, extracted }

@freezed
abstract class AudioItem with _$AudioItem {
  const factory({
    required String id,
    required String mediaId,
    required AudioKind kind,
    required String name,
    required Anchor anchor,

    /// Length of the source file.
    required int mediaDurationUs,
    required int sourceInUs,
    required int sourceOutUs,
    @Default(0) int laneIndex,
    @Default(1.0) double volume,
    @Default(0) int fadeInUs,
    @Default(0) int fadeOutUs,
    @Default(1.0) double speed,

    /// Repeats the source span until the end of the video.
    @Default(false) bool loop,
    @Default(false) bool needsReview,

    /// Sorted by source time; only volume is used.
    @Default(<Keyframe>[]) List<Keyframe> keyframes,
  }) = _AudioItem;
  const new _();

  factory fromJson(Map<String, dynamic> json) => _$AudioItemFromJson(json);

  int get sourceDurationUs => sourceOutUs - sourceInUs;

  /// Length of one pass of the source span on the timeline. Looping items
  /// repeat this until the video ends.
  int get durationUs => sourceToTimelineUs(sourceDurationUs, speed);
}

/// Relative levels of the two audio groups, set in the volume balance
/// sheet. Multiplies each clip's or item's own volume.
@freezed
abstract class AudioMix with _$AudioMix {
  const factory({
    @Default(true) bool originalSoundEnabled,
    @Default(1.0) double originalLevel,
    @Default(1.0) double addedLevel,
  }) = _AudioMix;

  factory fromJson(Map<String, dynamic> json) => _$AudioMixFromJson(json);
}

@freezed
abstract class Timeline with _$Timeline {
  const factory({
    @Default(<VideoClip>[]) List<VideoClip> videoClips,
    @Default(<Transition>[]) List<Transition> transitions,
    @Default(<TextItem>[]) List<TextItem> textItems,
    @Default(CaptionTrack()) CaptionTrack captionTrack,
    @Default(<AudioItem>[]) List<AudioItem> audioItems,
    @Default(AudioMix()) AudioMix audioMix,
  }) = _Timeline;
  const new _();

  factory fromJson(Map<String, dynamic> json) => _$TimelineFromJson(json);

  static const empty = Timeline();

  /// Audio items grouped by lane, lane 0 first. Empty lanes in between are
  /// kept so indices match [AudioItem.laneIndex].
  List<List<AudioItem>> get audioLanes {
    if (audioItems.isEmpty) return const [];
    final count =
        audioItems.map((a) => a.laneIndex).reduce((a, b) => a > b ? a : b) + 1;
    return [
      for (var lane = 0; lane < count; lane++)
        [
          for (final item in audioItems)
            if (item.laneIndex == lane) item,
        ],
    ];
  }

  VideoClip? clipById(String id) {
    for (final clip in videoClips) {
      if (clip.id == id) return clip;
    }
    return null;
  }

  int indexOfClip(String id) => videoClips.indexWhere((c) => c.id == id);

  Transition? transitionAfter(String clipId) {
    for (final t in transitions) {
      if (t.afterClipId == clipId) return t;
    }
    return null;
  }
}
