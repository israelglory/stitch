// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'composition.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ResolvedClip _$ResolvedClipFromJson(Map<String, dynamic> json) =>
    _ResolvedClip(
      clipId: json['clipId'] as String,
      mediaId: json['mediaId'] as String,
      kind: $enumDecode(_$MediaKindEnumMap, json['kind']),
      startUs: (json['startUs'] as num).toInt(),
      endUs: (json['endUs'] as num).toInt(),
      sourceInUs: (json['sourceInUs'] as num).toInt(),
      sourceOutUs: (json['sourceOutUs'] as num).toInt(),
      speed: (json['speed'] as num).toDouble(),
      volume: (json['volume'] as num).toDouble(),
      audioFadeInUs: (json['audioFadeInUs'] as num).toInt(),
      audioFadeOutUs: (json['audioFadeOutUs'] as num).toInt(),
      framing: ClipFraming.fromJson(json['framing'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ResolvedClipToJson(_ResolvedClip instance) =>
    <String, dynamic>{
      'clipId': instance.clipId,
      'mediaId': instance.mediaId,
      'kind': _$MediaKindEnumMap[instance.kind]!,
      'startUs': instance.startUs,
      'endUs': instance.endUs,
      'sourceInUs': instance.sourceInUs,
      'sourceOutUs': instance.sourceOutUs,
      'speed': instance.speed,
      'volume': instance.volume,
      'audioFadeInUs': instance.audioFadeInUs,
      'audioFadeOutUs': instance.audioFadeOutUs,
      'framing': instance.framing.toJson(),
    };

const _$MediaKindEnumMap = {
  MediaKind.video: 'video',
  MediaKind.photo: 'photo',
  MediaKind.audio: 'audio',
};

_ResolvedTransition _$ResolvedTransitionFromJson(Map<String, dynamic> json) =>
    _ResolvedTransition(
      type: $enumDecode(_$TransitionTypeEnumMap, json['type']),
      fromClipId: json['fromClipId'] as String,
      toClipId: json['toClipId'] as String,
      startUs: (json['startUs'] as num).toInt(),
      durationUs: (json['durationUs'] as num).toInt(),
      params:
          (json['params'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toDouble()),
          ) ??
          const <String, double>{},
    );

Map<String, dynamic> _$ResolvedTransitionToJson(_ResolvedTransition instance) =>
    <String, dynamic>{
      'type': _$TransitionTypeEnumMap[instance.type]!,
      'fromClipId': instance.fromClipId,
      'toClipId': instance.toClipId,
      'startUs': instance.startUs,
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

_ResolvedText _$ResolvedTextFromJson(Map<String, dynamic> json) =>
    _ResolvedText(
      id: json['id'] as String,
      text: json['text'] as String,
      startUs: (json['startUs'] as num).toInt(),
      endUs: (json['endUs'] as num).toInt(),
      laneIndex: (json['laneIndex'] as num).toInt(),
      style: TextStyleSpec.fromJson(json['style'] as Map<String, dynamic>),
      transform: ItemTransform.fromJson(
        json['transform'] as Map<String, dynamic>,
      ),
      animationIn: $enumDecode(_$TextAnimationEnumMap, json['animationIn']),
      animationOut: $enumDecode(_$TextAnimationEnumMap, json['animationOut']),
    );

Map<String, dynamic> _$ResolvedTextToJson(_ResolvedText instance) =>
    <String, dynamic>{
      'id': instance.id,
      'text': instance.text,
      'startUs': instance.startUs,
      'endUs': instance.endUs,
      'laneIndex': instance.laneIndex,
      'style': instance.style.toJson(),
      'transform': instance.transform.toJson(),
      'animationIn': _$TextAnimationEnumMap[instance.animationIn]!,
      'animationOut': _$TextAnimationEnumMap[instance.animationOut]!,
    };

const _$TextAnimationEnumMap = {
  TextAnimation.none: 'none',
  TextAnimation.fade: 'fade',
  TextAnimation.slideUp: 'slideUp',
  TextAnimation.slideDown: 'slideDown',
  TextAnimation.scale: 'scale',
  TextAnimation.typewriter: 'typewriter',
};

_ResolvedWord _$ResolvedWordFromJson(Map<String, dynamic> json) =>
    _ResolvedWord(
      text: json['text'] as String,
      startUs: (json['startUs'] as num).toInt(),
      endUs: (json['endUs'] as num).toInt(),
    );

Map<String, dynamic> _$ResolvedWordToJson(_ResolvedWord instance) =>
    <String, dynamic>{
      'text': instance.text,
      'startUs': instance.startUs,
      'endUs': instance.endUs,
    };

_ResolvedCaption _$ResolvedCaptionFromJson(Map<String, dynamic> json) =>
    _ResolvedCaption(
      id: json['id'] as String,
      text: json['text'] as String,
      startUs: (json['startUs'] as num).toInt(),
      endUs: (json['endUs'] as num).toInt(),
      words:
          (json['words'] as List<dynamic>?)
              ?.map((e) => ResolvedWord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <ResolvedWord>[],
    );

Map<String, dynamic> _$ResolvedCaptionToJson(_ResolvedCaption instance) =>
    <String, dynamic>{
      'id': instance.id,
      'text': instance.text,
      'startUs': instance.startUs,
      'endUs': instance.endUs,
      'words': instance.words.map((e) => e.toJson()).toList(),
    };

_ResolvedAudio _$ResolvedAudioFromJson(Map<String, dynamic> json) =>
    _ResolvedAudio(
      id: json['id'] as String,
      mediaId: json['mediaId'] as String,
      kind: $enumDecode(_$AudioKindEnumMap, json['kind']),
      startUs: (json['startUs'] as num).toInt(),
      endUs: (json['endUs'] as num).toInt(),
      sourceInUs: (json['sourceInUs'] as num).toInt(),
      sourceOutUs: (json['sourceOutUs'] as num).toInt(),
      speed: (json['speed'] as num).toDouble(),
      loop: json['loop'] as bool,
      volume: (json['volume'] as num).toDouble(),
      fadeInUs: (json['fadeInUs'] as num).toInt(),
      fadeOutUs: (json['fadeOutUs'] as num).toInt(),
      cutAtVideoEnd: json['cutAtVideoEnd'] as bool,
    );

Map<String, dynamic> _$ResolvedAudioToJson(_ResolvedAudio instance) =>
    <String, dynamic>{
      'id': instance.id,
      'mediaId': instance.mediaId,
      'kind': _$AudioKindEnumMap[instance.kind]!,
      'startUs': instance.startUs,
      'endUs': instance.endUs,
      'sourceInUs': instance.sourceInUs,
      'sourceOutUs': instance.sourceOutUs,
      'speed': instance.speed,
      'loop': instance.loop,
      'volume': instance.volume,
      'fadeInUs': instance.fadeInUs,
      'fadeOutUs': instance.fadeOutUs,
      'cutAtVideoEnd': instance.cutAtVideoEnd,
    };

const _$AudioKindEnumMap = {
  AudioKind.music: 'music',
  AudioKind.soundEffect: 'soundEffect',
  AudioKind.voiceover: 'voiceover',
  AudioKind.extracted: 'extracted',
};

_ResolvedComposition _$ResolvedCompositionFromJson(
  Map<String, dynamic> json,
) => _ResolvedComposition(
  durationUs: (json['durationUs'] as num).toInt(),
  clips:
      (json['clips'] as List<dynamic>?)
          ?.map((e) => ResolvedClip.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ResolvedClip>[],
  transitions:
      (json['transitions'] as List<dynamic>?)
          ?.map((e) => ResolvedTransition.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ResolvedTransition>[],
  texts:
      (json['texts'] as List<dynamic>?)
          ?.map((e) => ResolvedText.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ResolvedText>[],
  captions:
      (json['captions'] as List<dynamic>?)
          ?.map((e) => ResolvedCaption.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ResolvedCaption>[],
  captionPreset:
      $enumDecodeNullable(_$CaptionPresetEnumMap, json['captionPreset']) ??
      CaptionPreset.plain,
  captionPosition:
      $enumDecodeNullable(_$CaptionPositionEnumMap, json['captionPosition']) ??
      CaptionPosition.bottom,
  audio:
      (json['audio'] as List<dynamic>?)
          ?.map((e) => ResolvedAudio.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ResolvedAudio>[],
);

Map<String, dynamic> _$ResolvedCompositionToJson(
  _ResolvedComposition instance,
) => <String, dynamic>{
  'durationUs': instance.durationUs,
  'clips': instance.clips.map((e) => e.toJson()).toList(),
  'transitions': instance.transitions.map((e) => e.toJson()).toList(),
  'texts': instance.texts.map((e) => e.toJson()).toList(),
  'captions': instance.captions.map((e) => e.toJson()).toList(),
  'captionPreset': _$CaptionPresetEnumMap[instance.captionPreset]!,
  'captionPosition': _$CaptionPositionEnumMap[instance.captionPosition]!,
  'audio': instance.audio.map((e) => e.toJson()).toList(),
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
