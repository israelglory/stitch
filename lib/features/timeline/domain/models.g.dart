// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClipAnchor _$ClipAnchorFromJson(Map<String, dynamic> json) => ClipAnchor(
  clipId: json['clipId'] as String,
  sourceUs: (json['sourceUs'] as num).toInt(),
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$ClipAnchorToJson(ClipAnchor instance) =>
    <String, dynamic>{
      'clipId': instance.clipId,
      'sourceUs': instance.sourceUs,
      'runtimeType': instance.$type,
    };

TimeAnchor _$TimeAnchorFromJson(Map<String, dynamic> json) => TimeAnchor(
  startUs: (json['startUs'] as num).toInt(),
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$TimeAnchorToJson(TimeAnchor instance) =>
    <String, dynamic>{
      'startUs': instance.startUs,
      'runtimeType': instance.$type,
    };

_ClipFraming _$ClipFramingFromJson(Map<String, dynamic> json) => _ClipFraming(
  mode:
      $enumDecodeNullable(_$FramingModeEnumMap, json['mode']) ??
      FramingMode.fit,
  scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
  offsetX: (json['offsetX'] as num?)?.toDouble() ?? 0.0,
  offsetY: (json['offsetY'] as num?)?.toDouble() ?? 0.0,
  rotationDeg: (json['rotationDeg'] as num?)?.toDouble() ?? 0.0,
);

Map<String, dynamic> _$ClipFramingToJson(_ClipFraming instance) =>
    <String, dynamic>{
      'mode': _$FramingModeEnumMap[instance.mode]!,
      'scale': instance.scale,
      'offsetX': instance.offsetX,
      'offsetY': instance.offsetY,
      'rotationDeg': instance.rotationDeg,
    };

const _$FramingModeEnumMap = {
  FramingMode.fit: 'fit',
  FramingMode.fill: 'fill',
  FramingMode.manual: 'manual',
};

_VideoClip _$VideoClipFromJson(Map<String, dynamic> json) => _VideoClip(
  id: json['id'] as String,
  mediaId: json['mediaId'] as String,
  kind: $enumDecode(_$MediaKindEnumMap, json['kind']),
  mediaDurationUs: (json['mediaDurationUs'] as num?)?.toInt(),
  sourceInUs: (json['sourceInUs'] as num).toInt(),
  sourceOutUs: (json['sourceOutUs'] as num).toInt(),
  speed: (json['speed'] as num?)?.toDouble() ?? 1.0,
  volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
  audioDetached: json['audioDetached'] as bool? ?? false,
  framing: json['framing'] == null
      ? const ClipFraming()
      : ClipFraming.fromJson(json['framing'] as Map<String, dynamic>),
);

Map<String, dynamic> _$VideoClipToJson(_VideoClip instance) =>
    <String, dynamic>{
      'id': instance.id,
      'mediaId': instance.mediaId,
      'kind': _$MediaKindEnumMap[instance.kind]!,
      'mediaDurationUs': ?instance.mediaDurationUs,
      'sourceInUs': instance.sourceInUs,
      'sourceOutUs': instance.sourceOutUs,
      'speed': instance.speed,
      'volume': instance.volume,
      'audioDetached': instance.audioDetached,
      'framing': instance.framing.toJson(),
    };

const _$MediaKindEnumMap = {
  MediaKind.video: 'video',
  MediaKind.photo: 'photo',
  MediaKind.audio: 'audio',
};

_Transition _$TransitionFromJson(Map<String, dynamic> json) => _Transition(
  afterClipId: json['afterClipId'] as String,
  type: $enumDecode(_$TransitionTypeEnumMap, json['type']),
  durationUs: (json['durationUs'] as num).toInt(),
  params:
      (json['params'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ) ??
      const <String, double>{},
);

Map<String, dynamic> _$TransitionToJson(_Transition instance) =>
    <String, dynamic>{
      'afterClipId': instance.afterClipId,
      'type': _$TransitionTypeEnumMap[instance.type]!,
      'durationUs': instance.durationUs,
      'params': instance.params,
    };

const _$TransitionTypeEnumMap = {
  TransitionType.crossfade: 'crossfade',
  TransitionType.fadeToBlack: 'fadeToBlack',
  TransitionType.slideLeft: 'slideLeft',
  TransitionType.slideRight: 'slideRight',
  TransitionType.wipeLeft: 'wipeLeft',
  TransitionType.wipeRight: 'wipeRight',
  TransitionType.zoomIn: 'zoomIn',
};

_ItemTransform _$ItemTransformFromJson(Map<String, dynamic> json) =>
    _ItemTransform(
      x: (json['x'] as num?)?.toDouble() ?? 0.5,
      y: (json['y'] as num?)?.toDouble() ?? 0.5,
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      rotationDeg: (json['rotationDeg'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$ItemTransformToJson(_ItemTransform instance) =>
    <String, dynamic>{
      'x': instance.x,
      'y': instance.y,
      'scale': instance.scale,
      'rotationDeg': instance.rotationDeg,
    };

_TextStyleSpec _$TextStyleSpecFromJson(Map<String, dynamic> json) =>
    _TextStyleSpec(
      fontId: json['fontId'] as String? ?? 'inter',
      size: (json['size'] as num?)?.toDouble() ?? 0.05,
      color: (json['color'] as num?)?.toInt() ?? 0xFFFFFFFF,
      strokeColor: (json['strokeColor'] as num?)?.toInt(),
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 0.0,
      backgroundColor: (json['backgroundColor'] as num?)?.toInt(),
      alignment:
          $enumDecodeNullable(_$TextAlignmentEnumMap, json['alignment']) ??
          TextAlignment.center,
    );

Map<String, dynamic> _$TextStyleSpecToJson(_TextStyleSpec instance) =>
    <String, dynamic>{
      'fontId': instance.fontId,
      'size': instance.size,
      'color': instance.color,
      'strokeColor': ?instance.strokeColor,
      'strokeWidth': instance.strokeWidth,
      'backgroundColor': ?instance.backgroundColor,
      'alignment': _$TextAlignmentEnumMap[instance.alignment]!,
    };

const _$TextAlignmentEnumMap = {
  TextAlignment.start: 'start',
  TextAlignment.center: 'center',
  TextAlignment.end: 'end',
};

_TextItem _$TextItemFromJson(Map<String, dynamic> json) => _TextItem(
  id: json['id'] as String,
  text: json['text'] as String,
  anchor: Anchor.fromJson(json['anchor'] as Map<String, dynamic>),
  durationUs: (json['durationUs'] as num).toInt(),
  laneIndex: (json['laneIndex'] as num?)?.toInt() ?? 0,
  style: json['style'] == null
      ? const TextStyleSpec()
      : TextStyleSpec.fromJson(json['style'] as Map<String, dynamic>),
  transform: json['transform'] == null
      ? const ItemTransform()
      : ItemTransform.fromJson(json['transform'] as Map<String, dynamic>),
  animationIn:
      $enumDecodeNullable(_$TextAnimationEnumMap, json['animationIn']) ??
      TextAnimation.none,
  animationOut:
      $enumDecodeNullable(_$TextAnimationEnumMap, json['animationOut']) ??
      TextAnimation.none,
  needsReview: json['needsReview'] as bool? ?? false,
);

Map<String, dynamic> _$TextItemToJson(_TextItem instance) => <String, dynamic>{
  'id': instance.id,
  'text': instance.text,
  'anchor': instance.anchor.toJson(),
  'durationUs': instance.durationUs,
  'laneIndex': instance.laneIndex,
  'style': instance.style.toJson(),
  'transform': instance.transform.toJson(),
  'animationIn': _$TextAnimationEnumMap[instance.animationIn]!,
  'animationOut': _$TextAnimationEnumMap[instance.animationOut]!,
  'needsReview': instance.needsReview,
};

const _$TextAnimationEnumMap = {
  TextAnimation.none: 'none',
  TextAnimation.fade: 'fade',
  TextAnimation.slideUp: 'slideUp',
  TextAnimation.slideDown: 'slideDown',
  TextAnimation.scale: 'scale',
  TextAnimation.typewriter: 'typewriter',
};

_CaptionWord _$CaptionWordFromJson(Map<String, dynamic> json) => _CaptionWord(
  text: json['text'] as String,
  startOffsetUs: (json['startOffsetUs'] as num).toInt(),
  endOffsetUs: (json['endOffsetUs'] as num).toInt(),
);

Map<String, dynamic> _$CaptionWordToJson(_CaptionWord instance) =>
    <String, dynamic>{
      'text': instance.text,
      'startOffsetUs': instance.startOffsetUs,
      'endOffsetUs': instance.endOffsetUs,
    };

_CaptionSegment _$CaptionSegmentFromJson(Map<String, dynamic> json) =>
    _CaptionSegment(
      id: json['id'] as String,
      text: json['text'] as String,
      anchor: Anchor.fromJson(json['anchor'] as Map<String, dynamic>),
      durationUs: (json['durationUs'] as num).toInt(),
      words:
          (json['words'] as List<dynamic>?)
              ?.map((e) => CaptionWord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <CaptionWord>[],
      needsReview: json['needsReview'] as bool? ?? false,
    );

Map<String, dynamic> _$CaptionSegmentToJson(_CaptionSegment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'text': instance.text,
      'anchor': instance.anchor.toJson(),
      'durationUs': instance.durationUs,
      'words': instance.words.map((e) => e.toJson()).toList(),
      'needsReview': instance.needsReview,
    };

_CaptionTrack _$CaptionTrackFromJson(Map<String, dynamic> json) =>
    _CaptionTrack(
      segments:
          (json['segments'] as List<dynamic>?)
              ?.map((e) => CaptionSegment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <CaptionSegment>[],
      preset:
          $enumDecodeNullable(_$CaptionPresetEnumMap, json['preset']) ??
          CaptionPreset.plain,
      position:
          $enumDecodeNullable(_$CaptionPositionEnumMap, json['position']) ??
          CaptionPosition.bottom,
      language: json['language'] as String?,
    );

Map<String, dynamic> _$CaptionTrackToJson(_CaptionTrack instance) =>
    <String, dynamic>{
      'segments': instance.segments.map((e) => e.toJson()).toList(),
      'preset': _$CaptionPresetEnumMap[instance.preset]!,
      'position': _$CaptionPositionEnumMap[instance.position]!,
      'language': ?instance.language,
    };

const _$CaptionPresetEnumMap = {
  CaptionPreset.plain: 'plain',
  CaptionPreset.boxed: 'boxed',
  CaptionPreset.highlightWord: 'highlightWord',
  CaptionPreset.outline: 'outline',
};

const _$CaptionPositionEnumMap = {
  CaptionPosition.top: 'top',
  CaptionPosition.middle: 'middle',
  CaptionPosition.bottom: 'bottom',
};

_AudioItem _$AudioItemFromJson(Map<String, dynamic> json) => _AudioItem(
  id: json['id'] as String,
  mediaId: json['mediaId'] as String,
  kind: $enumDecode(_$AudioKindEnumMap, json['kind']),
  name: json['name'] as String,
  anchor: Anchor.fromJson(json['anchor'] as Map<String, dynamic>),
  mediaDurationUs: (json['mediaDurationUs'] as num).toInt(),
  sourceInUs: (json['sourceInUs'] as num).toInt(),
  sourceOutUs: (json['sourceOutUs'] as num).toInt(),
  laneIndex: (json['laneIndex'] as num?)?.toInt() ?? 0,
  volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
  fadeInUs: (json['fadeInUs'] as num?)?.toInt() ?? 0,
  fadeOutUs: (json['fadeOutUs'] as num?)?.toInt() ?? 0,
  speed: (json['speed'] as num?)?.toDouble() ?? 1.0,
  loop: json['loop'] as bool? ?? false,
  needsReview: json['needsReview'] as bool? ?? false,
);

Map<String, dynamic> _$AudioItemToJson(_AudioItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'mediaId': instance.mediaId,
      'kind': _$AudioKindEnumMap[instance.kind]!,
      'name': instance.name,
      'anchor': instance.anchor.toJson(),
      'mediaDurationUs': instance.mediaDurationUs,
      'sourceInUs': instance.sourceInUs,
      'sourceOutUs': instance.sourceOutUs,
      'laneIndex': instance.laneIndex,
      'volume': instance.volume,
      'fadeInUs': instance.fadeInUs,
      'fadeOutUs': instance.fadeOutUs,
      'speed': instance.speed,
      'loop': instance.loop,
      'needsReview': instance.needsReview,
    };

const _$AudioKindEnumMap = {
  AudioKind.music: 'music',
  AudioKind.soundEffect: 'soundEffect',
  AudioKind.voiceover: 'voiceover',
  AudioKind.extracted: 'extracted',
};

_AudioMix _$AudioMixFromJson(Map<String, dynamic> json) => _AudioMix(
  originalSoundEnabled: json['originalSoundEnabled'] as bool? ?? true,
  originalLevel: (json['originalLevel'] as num?)?.toDouble() ?? 1.0,
  addedLevel: (json['addedLevel'] as num?)?.toDouble() ?? 1.0,
);

Map<String, dynamic> _$AudioMixToJson(_AudioMix instance) => <String, dynamic>{
  'originalSoundEnabled': instance.originalSoundEnabled,
  'originalLevel': instance.originalLevel,
  'addedLevel': instance.addedLevel,
};

_Timeline _$TimelineFromJson(Map<String, dynamic> json) => _Timeline(
  videoClips:
      (json['videoClips'] as List<dynamic>?)
          ?.map((e) => VideoClip.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <VideoClip>[],
  transitions:
      (json['transitions'] as List<dynamic>?)
          ?.map((e) => Transition.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <Transition>[],
  textItems:
      (json['textItems'] as List<dynamic>?)
          ?.map((e) => TextItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <TextItem>[],
  captionTrack: json['captionTrack'] == null
      ? const CaptionTrack()
      : CaptionTrack.fromJson(json['captionTrack'] as Map<String, dynamic>),
  audioItems:
      (json['audioItems'] as List<dynamic>?)
          ?.map((e) => AudioItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <AudioItem>[],
  audioMix: json['audioMix'] == null
      ? const AudioMix()
      : AudioMix.fromJson(json['audioMix'] as Map<String, dynamic>),
);

Map<String, dynamic> _$TimelineToJson(_Timeline instance) => <String, dynamic>{
  'videoClips': instance.videoClips.map((e) => e.toJson()).toList(),
  'transitions': instance.transitions.map((e) => e.toJson()).toList(),
  'textItems': instance.textItems.map((e) => e.toJson()).toList(),
  'captionTrack': instance.captionTrack.toJson(),
  'audioItems': instance.audioItems.map((e) => e.toJson()).toList(),
  'audioMix': instance.audioMix.toJson(),
};
