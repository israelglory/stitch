// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProjectCanvas {

 AspectPreset get preset; int get width; int get height;
/// Create a copy of ProjectCanvas
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectCanvasCopyWith<ProjectCanvas> get copyWith => _$ProjectCanvasCopyWithImpl<ProjectCanvas>(this as ProjectCanvas, _$identity);

  /// Serializes this ProjectCanvas to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ProjectCanvas;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectCanvas&&(identical(other.preset, _this.preset) || other.preset == _this.preset)&&(identical(other.width, _this.width) || other.width == _this.width)&&(identical(other.height, _this.height) || other.height == _this.height));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ProjectCanvas;
  return Object.hash(runtimeType,_this.preset,_this.width,_this.height);
}

@override
String toString() {
  final _this = this as ProjectCanvas;
  return 'ProjectCanvas(preset: ${_this.preset}, width: ${_this.width}, height: ${_this.height})';
}


}

/// @nodoc
abstract mixin class $ProjectCanvasCopyWith<$Res>  {
  factory $ProjectCanvasCopyWith(ProjectCanvas value, $Res Function(ProjectCanvas) _then) = _$ProjectCanvasCopyWithImpl;
@useResult
$Res call({
 AspectPreset preset, int width, int height
});




}
/// @nodoc
class _$ProjectCanvasCopyWithImpl<$Res>
    implements $ProjectCanvasCopyWith<$Res> {
  _$ProjectCanvasCopyWithImpl(this._self, this._then);

  final ProjectCanvas _self;
  final $Res Function(ProjectCanvas) _then;

/// Create a copy of ProjectCanvas
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? preset = null,Object? width = null,Object? height = null,}) {
  return _then(ProjectCanvas(
preset: null == preset ? _self.preset : preset // ignore: cast_nullable_to_non_nullable
as AspectPreset,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectCanvas].
extension ProjectCanvasPatterns on ProjectCanvas {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectCanvas value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectCanvas() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectCanvas value)  $default,){
final _that = this;
switch (_that) {
case _ProjectCanvas():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectCanvas value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectCanvas() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AspectPreset preset,  int width,  int height)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectCanvas() when $default != null:
return $default(_that.preset,_that.width,_that.height);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AspectPreset preset,  int width,  int height)  $default,) {final _that = this;
switch (_that) {
case _ProjectCanvas():
return $default(_that.preset,_that.width,_that.height);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AspectPreset preset,  int width,  int height)?  $default,) {final _that = this;
switch (_that) {
case _ProjectCanvas() when $default != null:
return $default(_that.preset,_that.width,_that.height);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProjectCanvas extends ProjectCanvas {
  const _ProjectCanvas({required this.preset, required this.width, required this.height}): super._();
  factory _ProjectCanvas.fromJson(Map<String, dynamic> json) => _$ProjectCanvasFromJson(json);

@override final  AspectPreset preset;
@override final  int width;
@override final  int height;

/// Create a copy of ProjectCanvas
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectCanvasCopyWith<_ProjectCanvas> get copyWith => __$ProjectCanvasCopyWithImpl<_ProjectCanvas>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectCanvasToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectCanvas&&(identical(other.preset, preset) || other.preset == preset)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,preset,width,height);
}

@override
String toString() {
    return 'ProjectCanvas(preset: $preset, width: $width, height: $height)';
}


}

/// @nodoc
abstract mixin class _$ProjectCanvasCopyWith<$Res> implements $ProjectCanvasCopyWith<$Res> {
  factory _$ProjectCanvasCopyWith(_ProjectCanvas value, $Res Function(_ProjectCanvas) _then) = __$ProjectCanvasCopyWithImpl;
@override @useResult
$Res call({
 AspectPreset preset, int width, int height
});




}
/// @nodoc
class __$ProjectCanvasCopyWithImpl<$Res>
    implements _$ProjectCanvasCopyWith<$Res> {
  __$ProjectCanvasCopyWithImpl(this._self, this._then);

  final _ProjectCanvas _self;
  final $Res Function(_ProjectCanvas) _then;

/// Create a copy of ProjectCanvas
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? preset = null,Object? width = null,Object? height = null,}) {
  return _then(_ProjectCanvas(
preset: null == preset ? _self.preset : preset // ignore: cast_nullable_to_non_nullable
as AspectPreset,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

CanvasBackground _$CanvasBackgroundFromJson(
  Map<String, dynamic> json
) {
        switch (json['runtimeType']) {
                  case 'solid':
          return SolidBackground.fromJson(
            json
          );
                case 'blur':
          return BlurBackground.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'runtimeType',
  'CanvasBackground',
  'Invalid union type "${json['runtimeType']}"!'
);
        }
      
}

/// @nodoc
mixin _$CanvasBackground {



  /// Serializes this CanvasBackground to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CanvasBackground);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'CanvasBackground()';
}


}

/// @nodoc
class $CanvasBackgroundCopyWith<$Res>  {
$CanvasBackgroundCopyWith(CanvasBackground _, $Res Function(CanvasBackground) __);
}


/// Adds pattern-matching-related methods to [CanvasBackground].
extension CanvasBackgroundPatterns on CanvasBackground {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SolidBackground value)?  solid,TResult Function( BlurBackground value)?  blur,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SolidBackground() when solid != null:
return solid(_that);case BlurBackground() when blur != null:
return blur(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SolidBackground value)  solid,required TResult Function( BlurBackground value)  blur,}){
final _that = this;
switch (_that) {
case SolidBackground():
return solid(_that);case BlurBackground():
return blur(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SolidBackground value)?  solid,TResult? Function( BlurBackground value)?  blur,}){
final _that = this;
switch (_that) {
case SolidBackground() when solid != null:
return solid(_that);case BlurBackground() when blur != null:
return blur(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int color)?  solid,TResult Function()?  blur,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SolidBackground() when solid != null:
return solid(_that.color);case BlurBackground() when blur != null:
return blur();case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int color)  solid,required TResult Function()  blur,}) {final _that = this;
switch (_that) {
case SolidBackground():
return solid(_that.color);case BlurBackground():
return blur();}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int color)?  solid,TResult? Function()?  blur,}) {final _that = this;
switch (_that) {
case SolidBackground() when solid != null:
return solid(_that.color);case BlurBackground() when blur != null:
return blur();case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class SolidBackground implements CanvasBackground {
  const SolidBackground({this.color = 0xFF000000,  String? $type}): $type = $type ?? 'solid';
  factory SolidBackground.fromJson(Map<String, dynamic> json) => _$SolidBackgroundFromJson(json);

@JsonKey() final  int color;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of CanvasBackground
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SolidBackgroundCopyWith<SolidBackground> get copyWith => _$SolidBackgroundCopyWithImpl<SolidBackground>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SolidBackgroundToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SolidBackground&&(identical(other.color, color) || other.color == color));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,color);
}

@override
String toString() {
    return 'CanvasBackground.solid(color: $color)';
}


}

/// @nodoc
abstract mixin class $SolidBackgroundCopyWith<$Res> implements $CanvasBackgroundCopyWith<$Res> {
  factory $SolidBackgroundCopyWith(SolidBackground value, $Res Function(SolidBackground) _then) = _$SolidBackgroundCopyWithImpl;
@useResult
$Res call({
 int color
});




}
/// @nodoc
class _$SolidBackgroundCopyWithImpl<$Res>
    implements $SolidBackgroundCopyWith<$Res> {
  _$SolidBackgroundCopyWithImpl(this._self, this._then);

  final SolidBackground _self;
  final $Res Function(SolidBackground) _then;

/// Create a copy of CanvasBackground
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? color = null,}) {
  return _then(SolidBackground(
color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable()

class BlurBackground implements CanvasBackground {
  const BlurBackground({ String? $type}): $type = $type ?? 'blur';
  factory BlurBackground.fromJson(Map<String, dynamic> json) => _$BlurBackgroundFromJson(json);



@JsonKey(name: 'runtimeType')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$BlurBackgroundToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BlurBackground);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'CanvasBackground.blur()';
}


}





/// @nodoc
mixin _$MediaAsset {

 String get id; MediaKind get kind;/// Path of the imported copy, relative to the project folder.
 String get path;/// Display size after rotation, in pixels. Zero for audio.
 int get width; int get height;/// Null for photos.
 int? get durationUs;/// A still frame, relative to the project folder.
 String? get posterPath;/// Name shown for audio items, from the source file.
 String get displayName;/// False for videos without a sound track and for photos.
 bool get hasAudio;/// A 720p copy for preview, relative to the project folder, when the
/// source is larger than 1080p. Export always uses [path].
 String? get proxyPath;
/// Create a copy of MediaAsset
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MediaAssetCopyWith<MediaAsset> get copyWith => _$MediaAssetCopyWithImpl<MediaAsset>(this as MediaAsset, _$identity);

  /// Serializes this MediaAsset to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MediaAsset;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MediaAsset&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.path, _this.path) || other.path == _this.path)&&(identical(other.width, _this.width) || other.width == _this.width)&&(identical(other.height, _this.height) || other.height == _this.height)&&(identical(other.durationUs, _this.durationUs) || other.durationUs == _this.durationUs)&&(identical(other.posterPath, _this.posterPath) || other.posterPath == _this.posterPath)&&(identical(other.displayName, _this.displayName) || other.displayName == _this.displayName)&&(identical(other.hasAudio, _this.hasAudio) || other.hasAudio == _this.hasAudio)&&(identical(other.proxyPath, _this.proxyPath) || other.proxyPath == _this.proxyPath));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MediaAsset;
  return Object.hash(runtimeType,_this.id,_this.kind,_this.path,_this.width,_this.height,_this.durationUs,_this.posterPath,_this.displayName,_this.hasAudio,_this.proxyPath);
}

@override
String toString() {
  final _this = this as MediaAsset;
  return 'MediaAsset(id: ${_this.id}, kind: ${_this.kind}, path: ${_this.path}, width: ${_this.width}, height: ${_this.height}, durationUs: ${_this.durationUs}, posterPath: ${_this.posterPath}, displayName: ${_this.displayName}, hasAudio: ${_this.hasAudio}, proxyPath: ${_this.proxyPath})';
}


}

/// @nodoc
abstract mixin class $MediaAssetCopyWith<$Res>  {
  factory $MediaAssetCopyWith(MediaAsset value, $Res Function(MediaAsset) _then) = _$MediaAssetCopyWithImpl;
@useResult
$Res call({
 String id, MediaKind kind, String path, int width, int height, int? durationUs, String? posterPath, String displayName, bool hasAudio, String? proxyPath
});




}
/// @nodoc
class _$MediaAssetCopyWithImpl<$Res>
    implements $MediaAssetCopyWith<$Res> {
  _$MediaAssetCopyWithImpl(this._self, this._then);

  final MediaAsset _self;
  final $Res Function(MediaAsset) _then;

/// Create a copy of MediaAsset
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? path = null,Object? width = null,Object? height = null,Object? durationUs = freezed,Object? posterPath = freezed,Object? displayName = null,Object? hasAudio = null,Object? proxyPath = freezed,}) {
  return _then(MediaAsset(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as MediaKind,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,durationUs: freezed == durationUs ? _self.durationUs : durationUs // ignore: cast_nullable_to_non_nullable
as int?,posterPath: freezed == posterPath ? _self.posterPath : posterPath // ignore: cast_nullable_to_non_nullable
as String?,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,hasAudio: null == hasAudio ? _self.hasAudio : hasAudio // ignore: cast_nullable_to_non_nullable
as bool,proxyPath: freezed == proxyPath ? _self.proxyPath : proxyPath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MediaAsset].
extension MediaAssetPatterns on MediaAsset {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MediaAsset value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MediaAsset() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MediaAsset value)  $default,){
final _that = this;
switch (_that) {
case _MediaAsset():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MediaAsset value)?  $default,){
final _that = this;
switch (_that) {
case _MediaAsset() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  MediaKind kind,  String path,  int width,  int height,  int? durationUs,  String? posterPath,  String displayName,  bool hasAudio,  String? proxyPath)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MediaAsset() when $default != null:
return $default(_that.id,_that.kind,_that.path,_that.width,_that.height,_that.durationUs,_that.posterPath,_that.displayName,_that.hasAudio,_that.proxyPath);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  MediaKind kind,  String path,  int width,  int height,  int? durationUs,  String? posterPath,  String displayName,  bool hasAudio,  String? proxyPath)  $default,) {final _that = this;
switch (_that) {
case _MediaAsset():
return $default(_that.id,_that.kind,_that.path,_that.width,_that.height,_that.durationUs,_that.posterPath,_that.displayName,_that.hasAudio,_that.proxyPath);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  MediaKind kind,  String path,  int width,  int height,  int? durationUs,  String? posterPath,  String displayName,  bool hasAudio,  String? proxyPath)?  $default,) {final _that = this;
switch (_that) {
case _MediaAsset() when $default != null:
return $default(_that.id,_that.kind,_that.path,_that.width,_that.height,_that.durationUs,_that.posterPath,_that.displayName,_that.hasAudio,_that.proxyPath);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MediaAsset implements MediaAsset {
  const _MediaAsset({required this.id, required this.kind, required this.path, this.width = 0, this.height = 0, this.durationUs, this.posterPath, this.displayName = '', this.hasAudio = true, this.proxyPath});
  factory _MediaAsset.fromJson(Map<String, dynamic> json) => _$MediaAssetFromJson(json);

@override final  String id;
@override final  MediaKind kind;
/// Path of the imported copy, relative to the project folder.
@override final  String path;
/// Display size after rotation, in pixels. Zero for audio.
@override@JsonKey() final  int width;
@override@JsonKey() final  int height;
/// Null for photos.
@override final  int? durationUs;
/// A still frame, relative to the project folder.
@override final  String? posterPath;
/// Name shown for audio items, from the source file.
@override@JsonKey() final  String displayName;
/// False for videos without a sound track and for photos.
@override@JsonKey() final  bool hasAudio;
/// A 720p copy for preview, relative to the project folder, when the
/// source is larger than 1080p. Export always uses [path].
@override final  String? proxyPath;

/// Create a copy of MediaAsset
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MediaAssetCopyWith<_MediaAsset> get copyWith => __$MediaAssetCopyWithImpl<_MediaAsset>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MediaAssetToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MediaAsset&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.path, path) || other.path == path)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.durationUs, durationUs) || other.durationUs == durationUs)&&(identical(other.posterPath, posterPath) || other.posterPath == posterPath)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.hasAudio, hasAudio) || other.hasAudio == hasAudio)&&(identical(other.proxyPath, proxyPath) || other.proxyPath == proxyPath));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,kind,path,width,height,durationUs,posterPath,displayName,hasAudio,proxyPath);
}

@override
String toString() {
    return 'MediaAsset(id: $id, kind: $kind, path: $path, width: $width, height: $height, durationUs: $durationUs, posterPath: $posterPath, displayName: $displayName, hasAudio: $hasAudio, proxyPath: $proxyPath)';
}


}

/// @nodoc
abstract mixin class _$MediaAssetCopyWith<$Res> implements $MediaAssetCopyWith<$Res> {
  factory _$MediaAssetCopyWith(_MediaAsset value, $Res Function(_MediaAsset) _then) = __$MediaAssetCopyWithImpl;
@override @useResult
$Res call({
 String id, MediaKind kind, String path, int width, int height, int? durationUs, String? posterPath, String displayName, bool hasAudio, String? proxyPath
});




}
/// @nodoc
class __$MediaAssetCopyWithImpl<$Res>
    implements _$MediaAssetCopyWith<$Res> {
  __$MediaAssetCopyWithImpl(this._self, this._then);

  final _MediaAsset _self;
  final $Res Function(_MediaAsset) _then;

/// Create a copy of MediaAsset
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? path = null,Object? width = null,Object? height = null,Object? durationUs = freezed,Object? posterPath = freezed,Object? displayName = null,Object? hasAudio = null,Object? proxyPath = freezed,}) {
  return _then(_MediaAsset(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as MediaKind,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,durationUs: freezed == durationUs ? _self.durationUs : durationUs // ignore: cast_nullable_to_non_nullable
as int?,posterPath: freezed == posterPath ? _self.posterPath : posterPath // ignore: cast_nullable_to_non_nullable
as String?,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,hasAudio: null == hasAudio ? _self.hasAudio : hasAudio // ignore: cast_nullable_to_non_nullable
as bool,proxyPath: freezed == proxyPath ? _self.proxyPath : proxyPath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Project {

 int get schemaVersion; String get id; String get name; DateTime get createdAt; DateTime get updatedAt; ProjectCanvas get canvas; CanvasBackground get background;/// Frame rate sources are conformed to; chosen again at export.
 int get frameRate; Timeline get timeline;/// Every file the timeline refers to, by media id.
 Map<String, MediaAsset> get media;
/// Create a copy of Project
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectCopyWith<Project> get copyWith => _$ProjectCopyWithImpl<Project>(this as Project, _$identity);

  /// Serializes this Project to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Project;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Project&&(identical(other.schemaVersion, _this.schemaVersion) || other.schemaVersion == _this.schemaVersion)&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt)&&(identical(other.canvas, _this.canvas) || other.canvas == _this.canvas)&&(identical(other.background, _this.background) || other.background == _this.background)&&(identical(other.frameRate, _this.frameRate) || other.frameRate == _this.frameRate)&&(identical(other.timeline, _this.timeline) || other.timeline == _this.timeline)&&const DeepCollectionEquality().equals(other.media, _this.media));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Project;
  return Object.hash(runtimeType,_this.schemaVersion,_this.id,_this.name,_this.createdAt,_this.updatedAt,_this.canvas,_this.background,_this.frameRate,_this.timeline,const DeepCollectionEquality().hash(_this.media));
}

@override
String toString() {
  final _this = this as Project;
  return 'Project(schemaVersion: ${_this.schemaVersion}, id: ${_this.id}, name: ${_this.name}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt}, canvas: ${_this.canvas}, background: ${_this.background}, frameRate: ${_this.frameRate}, timeline: ${_this.timeline}, media: ${_this.media})';
}


}

/// @nodoc
abstract mixin class $ProjectCopyWith<$Res>  {
  factory $ProjectCopyWith(Project value, $Res Function(Project) _then) = _$ProjectCopyWithImpl;
@useResult
$Res call({
 int schemaVersion, String id, String name, DateTime createdAt, DateTime updatedAt, ProjectCanvas canvas, CanvasBackground background, int frameRate, Timeline timeline, Map<String, MediaAsset> media
});


$ProjectCanvasCopyWith<$Res> get canvas;$CanvasBackgroundCopyWith<$Res> get background;$TimelineCopyWith<$Res> get timeline;

}
/// @nodoc
class _$ProjectCopyWithImpl<$Res>
    implements $ProjectCopyWith<$Res> {
  _$ProjectCopyWithImpl(this._self, this._then);

  final Project _self;
  final $Res Function(Project) _then;

/// Create a copy of Project
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? schemaVersion = null,Object? id = null,Object? name = null,Object? createdAt = null,Object? updatedAt = null,Object? canvas = null,Object? background = null,Object? frameRate = null,Object? timeline = null,Object? media = null,}) {
  return _then(Project(
schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,canvas: null == canvas ? _self.canvas : canvas // ignore: cast_nullable_to_non_nullable
as ProjectCanvas,background: null == background ? _self.background : background // ignore: cast_nullable_to_non_nullable
as CanvasBackground,frameRate: null == frameRate ? _self.frameRate : frameRate // ignore: cast_nullable_to_non_nullable
as int,timeline: null == timeline ? _self.timeline : timeline // ignore: cast_nullable_to_non_nullable
as Timeline,media: null == media ? _self.media : media // ignore: cast_nullable_to_non_nullable
as Map<String, MediaAsset>,
  ));
}
/// Create a copy of Project
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectCanvasCopyWith<$Res> get canvas {
  
  return $ProjectCanvasCopyWith<$Res>(_self.canvas, (value) {
    return _then(_self.copyWith(canvas: value));
  });
}/// Create a copy of Project
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CanvasBackgroundCopyWith<$Res> get background {
  
  return $CanvasBackgroundCopyWith<$Res>(_self.background, (value) {
    return _then(_self.copyWith(background: value));
  });
}/// Create a copy of Project
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TimelineCopyWith<$Res> get timeline {
  
  return $TimelineCopyWith<$Res>(_self.timeline, (value) {
    return _then(_self.copyWith(timeline: value));
  });
}
}


/// Adds pattern-matching-related methods to [Project].
extension ProjectPatterns on Project {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Project value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Project() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Project value)  $default,){
final _that = this;
switch (_that) {
case _Project():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Project value)?  $default,){
final _that = this;
switch (_that) {
case _Project() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int schemaVersion,  String id,  String name,  DateTime createdAt,  DateTime updatedAt,  ProjectCanvas canvas,  CanvasBackground background,  int frameRate,  Timeline timeline,  Map<String, MediaAsset> media)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Project() when $default != null:
return $default(_that.schemaVersion,_that.id,_that.name,_that.createdAt,_that.updatedAt,_that.canvas,_that.background,_that.frameRate,_that.timeline,_that.media);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int schemaVersion,  String id,  String name,  DateTime createdAt,  DateTime updatedAt,  ProjectCanvas canvas,  CanvasBackground background,  int frameRate,  Timeline timeline,  Map<String, MediaAsset> media)  $default,) {final _that = this;
switch (_that) {
case _Project():
return $default(_that.schemaVersion,_that.id,_that.name,_that.createdAt,_that.updatedAt,_that.canvas,_that.background,_that.frameRate,_that.timeline,_that.media);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int schemaVersion,  String id,  String name,  DateTime createdAt,  DateTime updatedAt,  ProjectCanvas canvas,  CanvasBackground background,  int frameRate,  Timeline timeline,  Map<String, MediaAsset> media)?  $default,) {final _that = this;
switch (_that) {
case _Project() when $default != null:
return $default(_that.schemaVersion,_that.id,_that.name,_that.createdAt,_that.updatedAt,_that.canvas,_that.background,_that.frameRate,_that.timeline,_that.media);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Project implements Project {
  const _Project({required this.schemaVersion, required this.id, required this.name, required this.createdAt, required this.updatedAt, required this.canvas, this.background = const CanvasBackground.solid(), this.frameRate = 30, this.timeline = Timeline.empty,  Map<String, MediaAsset> media = const <String, MediaAsset>{}}): _media = media;
  factory _Project.fromJson(Map<String, dynamic> json) => _$ProjectFromJson(json);

@override final  int schemaVersion;
@override final  String id;
@override final  String name;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  ProjectCanvas canvas;
@override@JsonKey() final  CanvasBackground background;
/// Frame rate sources are conformed to; chosen again at export.
@override@JsonKey() final  int frameRate;
@override@JsonKey() final  Timeline timeline;
/// Every file the timeline refers to, by media id.
 final  Map<String, MediaAsset> _media;
/// Every file the timeline refers to, by media id.
@override@JsonKey() Map<String, MediaAsset> get media {
  if (_media is EqualUnmodifiableMapView) return _media;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_media);
}


/// Create a copy of Project
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectCopyWith<_Project> get copyWith => __$ProjectCopyWithImpl<_Project>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Project&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion)&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.canvas, canvas) || other.canvas == canvas)&&(identical(other.background, background) || other.background == background)&&(identical(other.frameRate, frameRate) || other.frameRate == frameRate)&&(identical(other.timeline, timeline) || other.timeline == timeline)&&const DeepCollectionEquality().equals(other.media, _media));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,schemaVersion,id,name,createdAt,updatedAt,canvas,background,frameRate,timeline,const DeepCollectionEquality().hash(_media));
}

@override
String toString() {
    return 'Project(schemaVersion: $schemaVersion, id: $id, name: $name, createdAt: $createdAt, updatedAt: $updatedAt, canvas: $canvas, background: $background, frameRate: $frameRate, timeline: $timeline, media: $media)';
}


}

/// @nodoc
abstract mixin class _$ProjectCopyWith<$Res> implements $ProjectCopyWith<$Res> {
  factory _$ProjectCopyWith(_Project value, $Res Function(_Project) _then) = __$ProjectCopyWithImpl;
@override @useResult
$Res call({
 int schemaVersion, String id, String name, DateTime createdAt, DateTime updatedAt, ProjectCanvas canvas, CanvasBackground background, int frameRate, Timeline timeline, Map<String, MediaAsset> media
});


@override $ProjectCanvasCopyWith<$Res> get canvas;@override $CanvasBackgroundCopyWith<$Res> get background;@override $TimelineCopyWith<$Res> get timeline;

}
/// @nodoc
class __$ProjectCopyWithImpl<$Res>
    implements _$ProjectCopyWith<$Res> {
  __$ProjectCopyWithImpl(this._self, this._then);

  final _Project _self;
  final $Res Function(_Project) _then;

/// Create a copy of Project
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? schemaVersion = null,Object? id = null,Object? name = null,Object? createdAt = null,Object? updatedAt = null,Object? canvas = null,Object? background = null,Object? frameRate = null,Object? timeline = null,Object? media = null,}) {
  return _then(_Project(
schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,canvas: null == canvas ? _self.canvas : canvas // ignore: cast_nullable_to_non_nullable
as ProjectCanvas,background: null == background ? _self.background : background // ignore: cast_nullable_to_non_nullable
as CanvasBackground,frameRate: null == frameRate ? _self.frameRate : frameRate // ignore: cast_nullable_to_non_nullable
as int,timeline: null == timeline ? _self.timeline : timeline // ignore: cast_nullable_to_non_nullable
as Timeline,media: null == media ? _self._media : media // ignore: cast_nullable_to_non_nullable
as Map<String, MediaAsset>,
  ));
}

/// Create a copy of Project
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectCanvasCopyWith<$Res> get canvas {
  
  return $ProjectCanvasCopyWith<$Res>(_self.canvas, (value) {
    return _then(_self.copyWith(canvas: value));
  });
}/// Create a copy of Project
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CanvasBackgroundCopyWith<$Res> get background {
  
  return $CanvasBackgroundCopyWith<$Res>(_self.background, (value) {
    return _then(_self.copyWith(background: value));
  });
}/// Create a copy of Project
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TimelineCopyWith<$Res> get timeline {
  
  return $TimelineCopyWith<$Res>(_self.timeline, (value) {
    return _then(_self.copyWith(timeline: value));
  });
}
}


/// @nodoc
mixin _$ProjectSummary {

 String get id; String get name; DateTime get createdAt; DateTime get updatedAt; int get durationUs;/// Poster of the first clip, relative to the project folder.
 String? get posterPath;
/// Create a copy of ProjectSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectSummaryCopyWith<ProjectSummary> get copyWith => _$ProjectSummaryCopyWithImpl<ProjectSummary>(this as ProjectSummary, _$identity);

  /// Serializes this ProjectSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ProjectSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectSummary&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt)&&(identical(other.durationUs, _this.durationUs) || other.durationUs == _this.durationUs)&&(identical(other.posterPath, _this.posterPath) || other.posterPath == _this.posterPath));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ProjectSummary;
  return Object.hash(runtimeType,_this.id,_this.name,_this.createdAt,_this.updatedAt,_this.durationUs,_this.posterPath);
}

@override
String toString() {
  final _this = this as ProjectSummary;
  return 'ProjectSummary(id: ${_this.id}, name: ${_this.name}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt}, durationUs: ${_this.durationUs}, posterPath: ${_this.posterPath})';
}


}

/// @nodoc
abstract mixin class $ProjectSummaryCopyWith<$Res>  {
  factory $ProjectSummaryCopyWith(ProjectSummary value, $Res Function(ProjectSummary) _then) = _$ProjectSummaryCopyWithImpl;
@useResult
$Res call({
 String id, String name, DateTime createdAt, DateTime updatedAt, int durationUs, String? posterPath
});




}
/// @nodoc
class _$ProjectSummaryCopyWithImpl<$Res>
    implements $ProjectSummaryCopyWith<$Res> {
  _$ProjectSummaryCopyWithImpl(this._self, this._then);

  final ProjectSummary _self;
  final $Res Function(ProjectSummary) _then;

/// Create a copy of ProjectSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? createdAt = null,Object? updatedAt = null,Object? durationUs = null,Object? posterPath = freezed,}) {
  return _then(ProjectSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,durationUs: null == durationUs ? _self.durationUs : durationUs // ignore: cast_nullable_to_non_nullable
as int,posterPath: freezed == posterPath ? _self.posterPath : posterPath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectSummary].
extension ProjectSummaryPatterns on ProjectSummary {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectSummary() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectSummary value)  $default,){
final _that = this;
switch (_that) {
case _ProjectSummary():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectSummary value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectSummary() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  DateTime createdAt,  DateTime updatedAt,  int durationUs,  String? posterPath)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectSummary() when $default != null:
return $default(_that.id,_that.name,_that.createdAt,_that.updatedAt,_that.durationUs,_that.posterPath);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  DateTime createdAt,  DateTime updatedAt,  int durationUs,  String? posterPath)  $default,) {final _that = this;
switch (_that) {
case _ProjectSummary():
return $default(_that.id,_that.name,_that.createdAt,_that.updatedAt,_that.durationUs,_that.posterPath);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  DateTime createdAt,  DateTime updatedAt,  int durationUs,  String? posterPath)?  $default,) {final _that = this;
switch (_that) {
case _ProjectSummary() when $default != null:
return $default(_that.id,_that.name,_that.createdAt,_that.updatedAt,_that.durationUs,_that.posterPath);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProjectSummary implements ProjectSummary {
  const _ProjectSummary({required this.id, required this.name, required this.createdAt, required this.updatedAt, required this.durationUs, this.posterPath});
  factory _ProjectSummary.fromJson(Map<String, dynamic> json) => _$ProjectSummaryFromJson(json);

@override final  String id;
@override final  String name;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  int durationUs;
/// Poster of the first clip, relative to the project folder.
@override final  String? posterPath;

/// Create a copy of ProjectSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectSummaryCopyWith<_ProjectSummary> get copyWith => __$ProjectSummaryCopyWithImpl<_ProjectSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.durationUs, durationUs) || other.durationUs == durationUs)&&(identical(other.posterPath, posterPath) || other.posterPath == posterPath));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,createdAt,updatedAt,durationUs,posterPath);
}

@override
String toString() {
    return 'ProjectSummary(id: $id, name: $name, createdAt: $createdAt, updatedAt: $updatedAt, durationUs: $durationUs, posterPath: $posterPath)';
}


}

/// @nodoc
abstract mixin class _$ProjectSummaryCopyWith<$Res> implements $ProjectSummaryCopyWith<$Res> {
  factory _$ProjectSummaryCopyWith(_ProjectSummary value, $Res Function(_ProjectSummary) _then) = __$ProjectSummaryCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, DateTime createdAt, DateTime updatedAt, int durationUs, String? posterPath
});




}
/// @nodoc
class __$ProjectSummaryCopyWithImpl<$Res>
    implements _$ProjectSummaryCopyWith<$Res> {
  __$ProjectSummaryCopyWithImpl(this._self, this._then);

  final _ProjectSummary _self;
  final $Res Function(_ProjectSummary) _then;

/// Create a copy of ProjectSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? createdAt = null,Object? updatedAt = null,Object? durationUs = null,Object? posterPath = freezed,}) {
  return _then(_ProjectSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,durationUs: null == durationUs ? _self.durationUs : durationUs // ignore: cast_nullable_to_non_nullable
as int,posterPath: freezed == posterPath ? _self.posterPath : posterPath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
