// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProjectCanvas _$ProjectCanvasFromJson(Map<String, dynamic> json) =>
    _ProjectCanvas(
      preset: $enumDecode(_$AspectPresetEnumMap, json['preset']),
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
    );

Map<String, dynamic> _$ProjectCanvasToJson(_ProjectCanvas instance) =>
    <String, dynamic>{
      'preset': _$AspectPresetEnumMap[instance.preset]!,
      'width': instance.width,
      'height': instance.height,
    };

const _$AspectPresetEnumMap = {
  AspectPreset.portrait9x16: 'portrait9x16',
  AspectPreset.landscape16x9: 'landscape16x9',
  AspectPreset.square: 'square',
  AspectPreset.portrait4x5: 'portrait4x5',
  AspectPreset.original: 'original',
};

SolidBackground _$SolidBackgroundFromJson(Map<String, dynamic> json) =>
    SolidBackground(
      color: (json['color'] as num?)?.toInt() ?? 0xFF000000,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$SolidBackgroundToJson(SolidBackground instance) =>
    <String, dynamic>{'color': instance.color, 'runtimeType': instance.$type};

BlurBackground _$BlurBackgroundFromJson(Map<String, dynamic> json) =>
    BlurBackground($type: json['runtimeType'] as String?);

Map<String, dynamic> _$BlurBackgroundToJson(BlurBackground instance) =>
    <String, dynamic>{'runtimeType': instance.$type};

_MediaAsset _$MediaAssetFromJson(Map<String, dynamic> json) => _MediaAsset(
  id: json['id'] as String,
  kind: $enumDecode(_$MediaKindEnumMap, json['kind']),
  path: json['path'] as String,
  width: (json['width'] as num?)?.toInt() ?? 0,
  height: (json['height'] as num?)?.toInt() ?? 0,
  durationUs: (json['durationUs'] as num?)?.toInt(),
  posterPath: json['posterPath'] as String?,
  displayName: json['displayName'] as String? ?? '',
  hasAudio: json['hasAudio'] as bool? ?? true,
  proxyPath: json['proxyPath'] as String?,
);

Map<String, dynamic> _$MediaAssetToJson(_MediaAsset instance) =>
    <String, dynamic>{
      'id': instance.id,
      'kind': _$MediaKindEnumMap[instance.kind]!,
      'path': instance.path,
      'width': instance.width,
      'height': instance.height,
      'durationUs': ?instance.durationUs,
      'posterPath': ?instance.posterPath,
      'displayName': instance.displayName,
      'hasAudio': instance.hasAudio,
      'proxyPath': ?instance.proxyPath,
    };

const _$MediaKindEnumMap = {
  MediaKind.video: 'video',
  MediaKind.photo: 'photo',
  MediaKind.audio: 'audio',
};

_Project _$ProjectFromJson(Map<String, dynamic> json) => _Project(
  schemaVersion: (json['schemaVersion'] as num).toInt(),
  id: json['id'] as String,
  name: json['name'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  canvas: ProjectCanvas.fromJson(json['canvas'] as Map<String, dynamic>),
  background: json['background'] == null
      ? const CanvasBackground.solid()
      : CanvasBackground.fromJson(json['background'] as Map<String, dynamic>),
  frameRate: (json['frameRate'] as num?)?.toInt() ?? 30,
  timeline: json['timeline'] == null
      ? Timeline.empty
      : Timeline.fromJson(json['timeline'] as Map<String, dynamic>),
  media:
      (json['media'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, MediaAsset.fromJson(e as Map<String, dynamic>)),
      ) ??
      const <String, MediaAsset>{},
);

Map<String, dynamic> _$ProjectToJson(_Project instance) => <String, dynamic>{
  'schemaVersion': instance.schemaVersion,
  'id': instance.id,
  'name': instance.name,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'canvas': instance.canvas.toJson(),
  'background': instance.background.toJson(),
  'frameRate': instance.frameRate,
  'timeline': instance.timeline.toJson(),
  'media': instance.media.map((k, e) => MapEntry(k, e.toJson())),
};

_ProjectSummary _$ProjectSummaryFromJson(Map<String, dynamic> json) =>
    _ProjectSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      durationUs: (json['durationUs'] as num).toInt(),
      posterPath: json['posterPath'] as String?,
    );

Map<String, dynamic> _$ProjectSummaryToJson(_ProjectSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'durationUs': instance.durationUs,
      'posterPath': ?instance.posterPath,
    };
