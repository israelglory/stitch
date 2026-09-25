// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
Anchor _$AnchorFromJson(
  Map<String, dynamic> json
) {
        switch (json['runtimeType']) {
                  case 'clip':
          return ClipAnchor.fromJson(
            json
          );
                case 'time':
          return TimeAnchor.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'runtimeType',
  'Anchor',
  'Invalid union type "${json['runtimeType']}"!'
);
        }
      
}

/// @nodoc
mixin _$Anchor {



  /// Serializes this Anchor to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is Anchor);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'Anchor()';
}


}

/// @nodoc
class $AnchorCopyWith<$Res>  {
$AnchorCopyWith(Anchor _, $Res Function(Anchor) __);
}


/// Adds pattern-matching-related methods to [Anchor].
extension AnchorPatterns on Anchor {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ClipAnchor value)?  clip,TResult Function( TimeAnchor value)?  time,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ClipAnchor() when clip != null:
return clip(_that);case TimeAnchor() when time != null:
return time(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ClipAnchor value)  clip,required TResult Function( TimeAnchor value)  time,}){
final _that = this;
switch (_that) {
case ClipAnchor():
return clip(_that);case TimeAnchor():
return time(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ClipAnchor value)?  clip,TResult? Function( TimeAnchor value)?  time,}){
final _that = this;
switch (_that) {
case ClipAnchor() when clip != null:
return clip(_that);case TimeAnchor() when time != null:
return time(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String clipId,  int sourceUs)?  clip,TResult Function( int startUs)?  time,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ClipAnchor() when clip != null:
return clip(_that.clipId,_that.sourceUs);case TimeAnchor() when time != null:
return time(_that.startUs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String clipId,  int sourceUs)  clip,required TResult Function( int startUs)  time,}) {final _that = this;
switch (_that) {
case ClipAnchor():
return clip(_that.clipId,_that.sourceUs);case TimeAnchor():
return time(_that.startUs);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String clipId,  int sourceUs)?  clip,TResult? Function( int startUs)?  time,}) {final _that = this;
switch (_that) {
case ClipAnchor() when clip != null:
return clip(_that.clipId,_that.sourceUs);case TimeAnchor() when time != null:
return time(_that.startUs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class ClipAnchor implements Anchor {
  const ClipAnchor({required this.clipId, required this.sourceUs,  String? $type}): $type = $type ?? 'clip';
  factory ClipAnchor.fromJson(Map<String, dynamic> json) => _$ClipAnchorFromJson(json);

 final  String clipId;
 final  int sourceUs;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of Anchor
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClipAnchorCopyWith<ClipAnchor> get copyWith => _$ClipAnchorCopyWithImpl<ClipAnchor>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ClipAnchorToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ClipAnchor&&(identical(other.clipId, clipId) || other.clipId == clipId)&&(identical(other.sourceUs, sourceUs) || other.sourceUs == sourceUs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,clipId,sourceUs);
}

@override
String toString() {
    return 'Anchor.clip(clipId: $clipId, sourceUs: $sourceUs)';
}


}

/// @nodoc
abstract mixin class $ClipAnchorCopyWith<$Res> implements $AnchorCopyWith<$Res> {
  factory $ClipAnchorCopyWith(ClipAnchor value, $Res Function(ClipAnchor) _then) = _$ClipAnchorCopyWithImpl;
@useResult
$Res call({
 String clipId, int sourceUs
});




}
/// @nodoc
class _$ClipAnchorCopyWithImpl<$Res>
    implements $ClipAnchorCopyWith<$Res> {
  _$ClipAnchorCopyWithImpl(this._self, this._then);

  final ClipAnchor _self;
  final $Res Function(ClipAnchor) _then;

/// Create a copy of Anchor
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? clipId = null,Object? sourceUs = null,}) {
  return _then(ClipAnchor(
clipId: null == clipId ? _self.clipId : clipId // ignore: cast_nullable_to_non_nullable
as String,sourceUs: null == sourceUs ? _self.sourceUs : sourceUs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable()

class TimeAnchor implements Anchor {
  const TimeAnchor({required this.startUs,  String? $type}): $type = $type ?? 'time';
  factory TimeAnchor.fromJson(Map<String, dynamic> json) => _$TimeAnchorFromJson(json);

 final  int startUs;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of Anchor
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TimeAnchorCopyWith<TimeAnchor> get copyWith => _$TimeAnchorCopyWithImpl<TimeAnchor>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TimeAnchorToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is TimeAnchor&&(identical(other.startUs, startUs) || other.startUs == startUs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,startUs);
}

@override
String toString() {
    return 'Anchor.time(startUs: $startUs)';
}


}

/// @nodoc
abstract mixin class $TimeAnchorCopyWith<$Res> implements $AnchorCopyWith<$Res> {
  factory $TimeAnchorCopyWith(TimeAnchor value, $Res Function(TimeAnchor) _then) = _$TimeAnchorCopyWithImpl;
@useResult
$Res call({
 int startUs
});




}
/// @nodoc
class _$TimeAnchorCopyWithImpl<$Res>
    implements $TimeAnchorCopyWith<$Res> {
  _$TimeAnchorCopyWithImpl(this._self, this._then);

  final TimeAnchor _self;
  final $Res Function(TimeAnchor) _then;

/// Create a copy of Anchor
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? startUs = null,}) {
  return _then(TimeAnchor(
startUs: null == startUs ? _self.startUs : startUs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ClipFraming {

 FramingMode get mode; double get scale; double get offsetX; double get offsetY; double get rotationDeg;
/// Create a copy of ClipFraming
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClipFramingCopyWith<ClipFraming> get copyWith => _$ClipFramingCopyWithImpl<ClipFraming>(this as ClipFraming, _$identity);

  /// Serializes this ClipFraming to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ClipFraming;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClipFraming&&(identical(other.mode, _this.mode) || other.mode == _this.mode)&&(identical(other.scale, _this.scale) || other.scale == _this.scale)&&(identical(other.offsetX, _this.offsetX) || other.offsetX == _this.offsetX)&&(identical(other.offsetY, _this.offsetY) || other.offsetY == _this.offsetY)&&(identical(other.rotationDeg, _this.rotationDeg) || other.rotationDeg == _this.rotationDeg));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ClipFraming;
  return Object.hash(runtimeType,_this.mode,_this.scale,_this.offsetX,_this.offsetY,_this.rotationDeg);
}

@override
String toString() {
  final _this = this as ClipFraming;
  return 'ClipFraming(mode: ${_this.mode}, scale: ${_this.scale}, offsetX: ${_this.offsetX}, offsetY: ${_this.offsetY}, rotationDeg: ${_this.rotationDeg})';
}


}

/// @nodoc
abstract mixin class $ClipFramingCopyWith<$Res>  {
  factory $ClipFramingCopyWith(ClipFraming value, $Res Function(ClipFraming) _then) = _$ClipFramingCopyWithImpl;
@useResult
$Res call({
 FramingMode mode, double scale, double offsetX, double offsetY, double rotationDeg
});




}
/// @nodoc
class _$ClipFramingCopyWithImpl<$Res>
    implements $ClipFramingCopyWith<$Res> {
  _$ClipFramingCopyWithImpl(this._self, this._then);

  final ClipFraming _self;
  final $Res Function(ClipFraming) _then;

/// Create a copy of ClipFraming
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mode = null,Object? scale = null,Object? offsetX = null,Object? offsetY = null,Object? rotationDeg = null,}) {
  return _then(ClipFraming(
mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as FramingMode,scale: null == scale ? _self.scale : scale // ignore: cast_nullable_to_non_nullable
as double,offsetX: null == offsetX ? _self.offsetX : offsetX // ignore: cast_nullable_to_non_nullable
as double,offsetY: null == offsetY ? _self.offsetY : offsetY // ignore: cast_nullable_to_non_nullable
as double,rotationDeg: null == rotationDeg ? _self.rotationDeg : rotationDeg // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [ClipFraming].
extension ClipFramingPatterns on ClipFraming {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClipFraming value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClipFraming() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClipFraming value)  $default,){
final _that = this;
switch (_that) {
case _ClipFraming():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClipFraming value)?  $default,){
final _that = this;
switch (_that) {
case _ClipFraming() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( FramingMode mode,  double scale,  double offsetX,  double offsetY,  double rotationDeg)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClipFraming() when $default != null:
return $default(_that.mode,_that.scale,_that.offsetX,_that.offsetY,_that.rotationDeg);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( FramingMode mode,  double scale,  double offsetX,  double offsetY,  double rotationDeg)  $default,) {final _that = this;
switch (_that) {
case _ClipFraming():
return $default(_that.mode,_that.scale,_that.offsetX,_that.offsetY,_that.rotationDeg);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( FramingMode mode,  double scale,  double offsetX,  double offsetY,  double rotationDeg)?  $default,) {final _that = this;
switch (_that) {
case _ClipFraming() when $default != null:
return $default(_that.mode,_that.scale,_that.offsetX,_that.offsetY,_that.rotationDeg);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ClipFraming implements ClipFraming {
  const _ClipFraming({this.mode = FramingMode.fit, this.scale = 1.0, this.offsetX = 0.0, this.offsetY = 0.0, this.rotationDeg = 0.0});
  factory _ClipFraming.fromJson(Map<String, dynamic> json) => _$ClipFramingFromJson(json);

@override@JsonKey() final  FramingMode mode;
@override@JsonKey() final  double scale;
@override@JsonKey() final  double offsetX;
@override@JsonKey() final  double offsetY;
@override@JsonKey() final  double rotationDeg;

/// Create a copy of ClipFraming
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClipFramingCopyWith<_ClipFraming> get copyWith => __$ClipFramingCopyWithImpl<_ClipFraming>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ClipFramingToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClipFraming&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.scale, scale) || other.scale == scale)&&(identical(other.offsetX, offsetX) || other.offsetX == offsetX)&&(identical(other.offsetY, offsetY) || other.offsetY == offsetY)&&(identical(other.rotationDeg, rotationDeg) || other.rotationDeg == rotationDeg));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,mode,scale,offsetX,offsetY,rotationDeg);
}

@override
String toString() {
    return 'ClipFraming(mode: $mode, scale: $scale, offsetX: $offsetX, offsetY: $offsetY, rotationDeg: $rotationDeg)';
}


}

/// @nodoc
abstract mixin class _$ClipFramingCopyWith<$Res> implements $ClipFramingCopyWith<$Res> {
  factory _$ClipFramingCopyWith(_ClipFraming value, $Res Function(_ClipFraming) _then) = __$ClipFramingCopyWithImpl;
@override @useResult
$Res call({
 FramingMode mode, double scale, double offsetX, double offsetY, double rotationDeg
});




}
/// @nodoc
class __$ClipFramingCopyWithImpl<$Res>
    implements _$ClipFramingCopyWith<$Res> {
  __$ClipFramingCopyWithImpl(this._self, this._then);

  final _ClipFraming _self;
  final $Res Function(_ClipFraming) _then;

/// Create a copy of ClipFraming
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? mode = null,Object? scale = null,Object? offsetX = null,Object? offsetY = null,Object? rotationDeg = null,}) {
  return _then(_ClipFraming(
mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as FramingMode,scale: null == scale ? _self.scale : scale // ignore: cast_nullable_to_non_nullable
as double,offsetX: null == offsetX ? _self.offsetX : offsetX // ignore: cast_nullable_to_non_nullable
as double,offsetY: null == offsetY ? _self.offsetY : offsetY // ignore: cast_nullable_to_non_nullable
as double,rotationDeg: null == rotationDeg ? _self.rotationDeg : rotationDeg // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$VideoClip {

 String get id; String get mediaId; MediaKind get kind;/// Length of the source file, or null for photos, which have no
/// natural length.
 int? get mediaDurationUs; int get sourceInUs; int get sourceOutUs; double get speed; double get volume;/// The clip's audio was extracted to an audio item, so the clip itself
/// plays silent.
 bool get audioDetached; ClipFraming get framing;
/// Create a copy of VideoClip
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VideoClipCopyWith<VideoClip> get copyWith => _$VideoClipCopyWithImpl<VideoClip>(this as VideoClip, _$identity);

  /// Serializes this VideoClip to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as VideoClip;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VideoClip&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.mediaId, _this.mediaId) || other.mediaId == _this.mediaId)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.mediaDurationUs, _this.mediaDurationUs) || other.mediaDurationUs == _this.mediaDurationUs)&&(identical(other.sourceInUs, _this.sourceInUs) || other.sourceInUs == _this.sourceInUs)&&(identical(other.sourceOutUs, _this.sourceOutUs) || other.sourceOutUs == _this.sourceOutUs)&&(identical(other.speed, _this.speed) || other.speed == _this.speed)&&(identical(other.volume, _this.volume) || other.volume == _this.volume)&&(identical(other.audioDetached, _this.audioDetached) || other.audioDetached == _this.audioDetached)&&(identical(other.framing, _this.framing) || other.framing == _this.framing));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as VideoClip;
  return Object.hash(runtimeType,_this.id,_this.mediaId,_this.kind,_this.mediaDurationUs,_this.sourceInUs,_this.sourceOutUs,_this.speed,_this.volume,_this.audioDetached,_this.framing);
}

@override
String toString() {
  final _this = this as VideoClip;
  return 'VideoClip(id: ${_this.id}, mediaId: ${_this.mediaId}, kind: ${_this.kind}, mediaDurationUs: ${_this.mediaDurationUs}, sourceInUs: ${_this.sourceInUs}, sourceOutUs: ${_this.sourceOutUs}, speed: ${_this.speed}, volume: ${_this.volume}, audioDetached: ${_this.audioDetached}, framing: ${_this.framing})';
}


}

/// @nodoc
abstract mixin class $VideoClipCopyWith<$Res>  {
  factory $VideoClipCopyWith(VideoClip value, $Res Function(VideoClip) _then) = _$VideoClipCopyWithImpl;
@useResult
$Res call({
 String id, String mediaId, MediaKind kind, int? mediaDurationUs, int sourceInUs, int sourceOutUs, double speed, double volume, bool audioDetached, ClipFraming framing
});


$ClipFramingCopyWith<$Res> get framing;

}
/// @nodoc
class _$VideoClipCopyWithImpl<$Res>
    implements $VideoClipCopyWith<$Res> {
  _$VideoClipCopyWithImpl(this._self, this._then);

  final VideoClip _self;
  final $Res Function(VideoClip) _then;

/// Create a copy of VideoClip
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? mediaId = null,Object? kind = null,Object? mediaDurationUs = freezed,Object? sourceInUs = null,Object? sourceOutUs = null,Object? speed = null,Object? volume = null,Object? audioDetached = null,Object? framing = null,}) {
  return _then(VideoClip(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,mediaId: null == mediaId ? _self.mediaId : mediaId // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as MediaKind,mediaDurationUs: freezed == mediaDurationUs ? _self.mediaDurationUs : mediaDurationUs // ignore: cast_nullable_to_non_nullable
as int?,sourceInUs: null == sourceInUs ? _self.sourceInUs : sourceInUs // ignore: cast_nullable_to_non_nullable
as int,sourceOutUs: null == sourceOutUs ? _self.sourceOutUs : sourceOutUs // ignore: cast_nullable_to_non_nullable
as int,speed: null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,audioDetached: null == audioDetached ? _self.audioDetached : audioDetached // ignore: cast_nullable_to_non_nullable
as bool,framing: null == framing ? _self.framing : framing // ignore: cast_nullable_to_non_nullable
as ClipFraming,
  ));
}
/// Create a copy of VideoClip
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ClipFramingCopyWith<$Res> get framing {
  
  return $ClipFramingCopyWith<$Res>(_self.framing, (value) {
    return _then(_self.copyWith(framing: value));
  });
}
}


/// Adds pattern-matching-related methods to [VideoClip].
extension VideoClipPatterns on VideoClip {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VideoClip value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VideoClip() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VideoClip value)  $default,){
final _that = this;
switch (_that) {
case _VideoClip():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VideoClip value)?  $default,){
final _that = this;
switch (_that) {
case _VideoClip() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String mediaId,  MediaKind kind,  int? mediaDurationUs,  int sourceInUs,  int sourceOutUs,  double speed,  double volume,  bool audioDetached,  ClipFraming framing)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VideoClip() when $default != null:
return $default(_that.id,_that.mediaId,_that.kind,_that.mediaDurationUs,_that.sourceInUs,_that.sourceOutUs,_that.speed,_that.volume,_that.audioDetached,_that.framing);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String mediaId,  MediaKind kind,  int? mediaDurationUs,  int sourceInUs,  int sourceOutUs,  double speed,  double volume,  bool audioDetached,  ClipFraming framing)  $default,) {final _that = this;
switch (_that) {
case _VideoClip():
return $default(_that.id,_that.mediaId,_that.kind,_that.mediaDurationUs,_that.sourceInUs,_that.sourceOutUs,_that.speed,_that.volume,_that.audioDetached,_that.framing);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String mediaId,  MediaKind kind,  int? mediaDurationUs,  int sourceInUs,  int sourceOutUs,  double speed,  double volume,  bool audioDetached,  ClipFraming framing)?  $default,) {final _that = this;
switch (_that) {
case _VideoClip() when $default != null:
return $default(_that.id,_that.mediaId,_that.kind,_that.mediaDurationUs,_that.sourceInUs,_that.sourceOutUs,_that.speed,_that.volume,_that.audioDetached,_that.framing);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VideoClip extends VideoClip {
  const _VideoClip({required this.id, required this.mediaId, required this.kind, required this.mediaDurationUs, required this.sourceInUs, required this.sourceOutUs, this.speed = 1.0, this.volume = 1.0, this.audioDetached = false, this.framing = const ClipFraming()}): super._();
  factory _VideoClip.fromJson(Map<String, dynamic> json) => _$VideoClipFromJson(json);

@override final  String id;
@override final  String mediaId;
@override final  MediaKind kind;
/// Length of the source file, or null for photos, which have no
/// natural length.
@override final  int? mediaDurationUs;
@override final  int sourceInUs;
@override final  int sourceOutUs;
@override@JsonKey() final  double speed;
@override@JsonKey() final  double volume;
/// The clip's audio was extracted to an audio item, so the clip itself
/// plays silent.
@override@JsonKey() final  bool audioDetached;
@override@JsonKey() final  ClipFraming framing;

/// Create a copy of VideoClip
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VideoClipCopyWith<_VideoClip> get copyWith => __$VideoClipCopyWithImpl<_VideoClip>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VideoClipToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _VideoClip&&(identical(other.id, id) || other.id == id)&&(identical(other.mediaId, mediaId) || other.mediaId == mediaId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.mediaDurationUs, mediaDurationUs) || other.mediaDurationUs == mediaDurationUs)&&(identical(other.sourceInUs, sourceInUs) || other.sourceInUs == sourceInUs)&&(identical(other.sourceOutUs, sourceOutUs) || other.sourceOutUs == sourceOutUs)&&(identical(other.speed, speed) || other.speed == speed)&&(identical(other.volume, volume) || other.volume == volume)&&(identical(other.audioDetached, audioDetached) || other.audioDetached == audioDetached)&&(identical(other.framing, framing) || other.framing == framing));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,mediaId,kind,mediaDurationUs,sourceInUs,sourceOutUs,speed,volume,audioDetached,framing);
}

@override
String toString() {
    return 'VideoClip(id: $id, mediaId: $mediaId, kind: $kind, mediaDurationUs: $mediaDurationUs, sourceInUs: $sourceInUs, sourceOutUs: $sourceOutUs, speed: $speed, volume: $volume, audioDetached: $audioDetached, framing: $framing)';
}


}

/// @nodoc
abstract mixin class _$VideoClipCopyWith<$Res> implements $VideoClipCopyWith<$Res> {
  factory _$VideoClipCopyWith(_VideoClip value, $Res Function(_VideoClip) _then) = __$VideoClipCopyWithImpl;
@override @useResult
$Res call({
 String id, String mediaId, MediaKind kind, int? mediaDurationUs, int sourceInUs, int sourceOutUs, double speed, double volume, bool audioDetached, ClipFraming framing
});


@override $ClipFramingCopyWith<$Res> get framing;

}
/// @nodoc
class __$VideoClipCopyWithImpl<$Res>
    implements _$VideoClipCopyWith<$Res> {
  __$VideoClipCopyWithImpl(this._self, this._then);

  final _VideoClip _self;
  final $Res Function(_VideoClip) _then;

/// Create a copy of VideoClip
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? mediaId = null,Object? kind = null,Object? mediaDurationUs = freezed,Object? sourceInUs = null,Object? sourceOutUs = null,Object? speed = null,Object? volume = null,Object? audioDetached = null,Object? framing = null,}) {
  return _then(_VideoClip(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,mediaId: null == mediaId ? _self.mediaId : mediaId // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as MediaKind,mediaDurationUs: freezed == mediaDurationUs ? _self.mediaDurationUs : mediaDurationUs // ignore: cast_nullable_to_non_nullable
as int?,sourceInUs: null == sourceInUs ? _self.sourceInUs : sourceInUs // ignore: cast_nullable_to_non_nullable
as int,sourceOutUs: null == sourceOutUs ? _self.sourceOutUs : sourceOutUs // ignore: cast_nullable_to_non_nullable
as int,speed: null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,audioDetached: null == audioDetached ? _self.audioDetached : audioDetached // ignore: cast_nullable_to_non_nullable
as bool,framing: null == framing ? _self.framing : framing // ignore: cast_nullable_to_non_nullable
as ClipFraming,
  ));
}

/// Create a copy of VideoClip
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ClipFramingCopyWith<$Res> get framing {
  
  return $ClipFramingCopyWith<$Res>(_self.framing, (value) {
    return _then(_self.copyWith(framing: value));
  });
}
}


/// @nodoc
mixin _$Transition {

 String get afterClipId; TransitionType get type; int get durationUs; Map<String, double> get params;
/// Create a copy of Transition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransitionCopyWith<Transition> get copyWith => _$TransitionCopyWithImpl<Transition>(this as Transition, _$identity);

  /// Serializes this Transition to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Transition;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Transition&&(identical(other.afterClipId, _this.afterClipId) || other.afterClipId == _this.afterClipId)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.durationUs, _this.durationUs) || other.durationUs == _this.durationUs)&&const DeepCollectionEquality().equals(other.params, _this.params));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Transition;
  return Object.hash(runtimeType,_this.afterClipId,_this.type,_this.durationUs,const DeepCollectionEquality().hash(_this.params));
}

@override
String toString() {
  final _this = this as Transition;
  return 'Transition(afterClipId: ${_this.afterClipId}, type: ${_this.type}, durationUs: ${_this.durationUs}, params: ${_this.params})';
}


}

/// @nodoc
abstract mixin class $TransitionCopyWith<$Res>  {
  factory $TransitionCopyWith(Transition value, $Res Function(Transition) _then) = _$TransitionCopyWithImpl;
@useResult
$Res call({
 String afterClipId, TransitionType type, int durationUs, Map<String, double> params
});




}
/// @nodoc
class _$TransitionCopyWithImpl<$Res>
    implements $TransitionCopyWith<$Res> {
  _$TransitionCopyWithImpl(this._self, this._then);

  final Transition _self;
  final $Res Function(Transition) _then;

/// Create a copy of Transition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? afterClipId = null,Object? type = null,Object? durationUs = null,Object? params = null,}) {
  return _then(Transition(
afterClipId: null == afterClipId ? _self.afterClipId : afterClipId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TransitionType,durationUs: null == durationUs ? _self.durationUs : durationUs // ignore: cast_nullable_to_non_nullable
as int,params: null == params ? _self.params : params // ignore: cast_nullable_to_non_nullable
as Map<String, double>,
  ));
}

}


/// Adds pattern-matching-related methods to [Transition].
extension TransitionPatterns on Transition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Transition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Transition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Transition value)  $default,){
final _that = this;
switch (_that) {
case _Transition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Transition value)?  $default,){
final _that = this;
switch (_that) {
case _Transition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String afterClipId,  TransitionType type,  int durationUs,  Map<String, double> params)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Transition() when $default != null:
return $default(_that.afterClipId,_that.type,_that.durationUs,_that.params);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String afterClipId,  TransitionType type,  int durationUs,  Map<String, double> params)  $default,) {final _that = this;
switch (_that) {
case _Transition():
return $default(_that.afterClipId,_that.type,_that.durationUs,_that.params);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String afterClipId,  TransitionType type,  int durationUs,  Map<String, double> params)?  $default,) {final _that = this;
switch (_that) {
case _Transition() when $default != null:
return $default(_that.afterClipId,_that.type,_that.durationUs,_that.params);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Transition implements Transition {
  const _Transition({required this.afterClipId, required this.type, required this.durationUs,  Map<String, double> params = const <String, double>{}}): _params = params;
  factory _Transition.fromJson(Map<String, dynamic> json) => _$TransitionFromJson(json);

@override final  String afterClipId;
@override final  TransitionType type;
@override final  int durationUs;
 final  Map<String, double> _params;
@override@JsonKey() Map<String, double> get params {
  if (_params is EqualUnmodifiableMapView) return _params;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_params);
}


/// Create a copy of Transition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransitionCopyWith<_Transition> get copyWith => __$TransitionCopyWithImpl<_Transition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TransitionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Transition&&(identical(other.afterClipId, afterClipId) || other.afterClipId == afterClipId)&&(identical(other.type, type) || other.type == type)&&(identical(other.durationUs, durationUs) || other.durationUs == durationUs)&&const DeepCollectionEquality().equals(other.params, _params));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,afterClipId,type,durationUs,const DeepCollectionEquality().hash(_params));
}

@override
String toString() {
    return 'Transition(afterClipId: $afterClipId, type: $type, durationUs: $durationUs, params: $params)';
}


}

/// @nodoc
abstract mixin class _$TransitionCopyWith<$Res> implements $TransitionCopyWith<$Res> {
  factory _$TransitionCopyWith(_Transition value, $Res Function(_Transition) _then) = __$TransitionCopyWithImpl;
@override @useResult
$Res call({
 String afterClipId, TransitionType type, int durationUs, Map<String, double> params
});




}
/// @nodoc
class __$TransitionCopyWithImpl<$Res>
    implements _$TransitionCopyWith<$Res> {
  __$TransitionCopyWithImpl(this._self, this._then);

  final _Transition _self;
  final $Res Function(_Transition) _then;

/// Create a copy of Transition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? afterClipId = null,Object? type = null,Object? durationUs = null,Object? params = null,}) {
  return _then(_Transition(
afterClipId: null == afterClipId ? _self.afterClipId : afterClipId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TransitionType,durationUs: null == durationUs ? _self.durationUs : durationUs // ignore: cast_nullable_to_non_nullable
as int,params: null == params ? _self._params : params // ignore: cast_nullable_to_non_nullable
as Map<String, double>,
  ));
}


}


/// @nodoc
mixin _$ItemTransform {

 double get x; double get y; double get scale; double get rotationDeg;
/// Create a copy of ItemTransform
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ItemTransformCopyWith<ItemTransform> get copyWith => _$ItemTransformCopyWithImpl<ItemTransform>(this as ItemTransform, _$identity);

  /// Serializes this ItemTransform to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ItemTransform;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ItemTransform&&(identical(other.x, _this.x) || other.x == _this.x)&&(identical(other.y, _this.y) || other.y == _this.y)&&(identical(other.scale, _this.scale) || other.scale == _this.scale)&&(identical(other.rotationDeg, _this.rotationDeg) || other.rotationDeg == _this.rotationDeg));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ItemTransform;
  return Object.hash(runtimeType,_this.x,_this.y,_this.scale,_this.rotationDeg);
}

@override
String toString() {
  final _this = this as ItemTransform;
  return 'ItemTransform(x: ${_this.x}, y: ${_this.y}, scale: ${_this.scale}, rotationDeg: ${_this.rotationDeg})';
}


}

/// @nodoc
abstract mixin class $ItemTransformCopyWith<$Res>  {
  factory $ItemTransformCopyWith(ItemTransform value, $Res Function(ItemTransform) _then) = _$ItemTransformCopyWithImpl;
@useResult
$Res call({
 double x, double y, double scale, double rotationDeg
});




}
/// @nodoc
class _$ItemTransformCopyWithImpl<$Res>
    implements $ItemTransformCopyWith<$Res> {
  _$ItemTransformCopyWithImpl(this._self, this._then);

  final ItemTransform _self;
  final $Res Function(ItemTransform) _then;

/// Create a copy of ItemTransform
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? x = null,Object? y = null,Object? scale = null,Object? rotationDeg = null,}) {
  return _then(ItemTransform(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,scale: null == scale ? _self.scale : scale // ignore: cast_nullable_to_non_nullable
as double,rotationDeg: null == rotationDeg ? _self.rotationDeg : rotationDeg // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [ItemTransform].
extension ItemTransformPatterns on ItemTransform {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ItemTransform value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ItemTransform() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ItemTransform value)  $default,){
final _that = this;
switch (_that) {
case _ItemTransform():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ItemTransform value)?  $default,){
final _that = this;
switch (_that) {
case _ItemTransform() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double x,  double y,  double scale,  double rotationDeg)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ItemTransform() when $default != null:
return $default(_that.x,_that.y,_that.scale,_that.rotationDeg);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double x,  double y,  double scale,  double rotationDeg)  $default,) {final _that = this;
switch (_that) {
case _ItemTransform():
return $default(_that.x,_that.y,_that.scale,_that.rotationDeg);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double x,  double y,  double scale,  double rotationDeg)?  $default,) {final _that = this;
switch (_that) {
case _ItemTransform() when $default != null:
return $default(_that.x,_that.y,_that.scale,_that.rotationDeg);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ItemTransform implements ItemTransform {
  const _ItemTransform({this.x = 0.5, this.y = 0.5, this.scale = 1.0, this.rotationDeg = 0.0});
  factory _ItemTransform.fromJson(Map<String, dynamic> json) => _$ItemTransformFromJson(json);

@override@JsonKey() final  double x;
@override@JsonKey() final  double y;
@override@JsonKey() final  double scale;
@override@JsonKey() final  double rotationDeg;

/// Create a copy of ItemTransform
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ItemTransformCopyWith<_ItemTransform> get copyWith => __$ItemTransformCopyWithImpl<_ItemTransform>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ItemTransformToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ItemTransform&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.scale, scale) || other.scale == scale)&&(identical(other.rotationDeg, rotationDeg) || other.rotationDeg == rotationDeg));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,x,y,scale,rotationDeg);
}

@override
String toString() {
    return 'ItemTransform(x: $x, y: $y, scale: $scale, rotationDeg: $rotationDeg)';
}


}

/// @nodoc
abstract mixin class _$ItemTransformCopyWith<$Res> implements $ItemTransformCopyWith<$Res> {
  factory _$ItemTransformCopyWith(_ItemTransform value, $Res Function(_ItemTransform) _then) = __$ItemTransformCopyWithImpl;
@override @useResult
$Res call({
 double x, double y, double scale, double rotationDeg
});




}
/// @nodoc
class __$ItemTransformCopyWithImpl<$Res>
    implements _$ItemTransformCopyWith<$Res> {
  __$ItemTransformCopyWithImpl(this._self, this._then);

  final _ItemTransform _self;
  final $Res Function(_ItemTransform) _then;

/// Create a copy of ItemTransform
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? x = null,Object? y = null,Object? scale = null,Object? rotationDeg = null,}) {
  return _then(_ItemTransform(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,scale: null == scale ? _self.scale : scale // ignore: cast_nullable_to_non_nullable
as double,rotationDeg: null == rotationDeg ? _self.rotationDeg : rotationDeg // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$TextStyleSpec {

 String get fontId;/// Font size as a fraction of the canvas height.
 double get size; int get color; int? get strokeColor;/// Stroke width as a fraction of the font size; 0 for none.
 double get strokeWidth;/// Fill of a rounded box behind the text, or null for none.
 int? get backgroundColor; TextAlignment get alignment;
/// Create a copy of TextStyleSpec
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TextStyleSpecCopyWith<TextStyleSpec> get copyWith => _$TextStyleSpecCopyWithImpl<TextStyleSpec>(this as TextStyleSpec, _$identity);

  /// Serializes this TextStyleSpec to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TextStyleSpec;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TextStyleSpec&&(identical(other.fontId, _this.fontId) || other.fontId == _this.fontId)&&(identical(other.size, _this.size) || other.size == _this.size)&&(identical(other.color, _this.color) || other.color == _this.color)&&(identical(other.strokeColor, _this.strokeColor) || other.strokeColor == _this.strokeColor)&&(identical(other.strokeWidth, _this.strokeWidth) || other.strokeWidth == _this.strokeWidth)&&(identical(other.backgroundColor, _this.backgroundColor) || other.backgroundColor == _this.backgroundColor)&&(identical(other.alignment, _this.alignment) || other.alignment == _this.alignment));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TextStyleSpec;
  return Object.hash(runtimeType,_this.fontId,_this.size,_this.color,_this.strokeColor,_this.strokeWidth,_this.backgroundColor,_this.alignment);
}

@override
String toString() {
  final _this = this as TextStyleSpec;
  return 'TextStyleSpec(fontId: ${_this.fontId}, size: ${_this.size}, color: ${_this.color}, strokeColor: ${_this.strokeColor}, strokeWidth: ${_this.strokeWidth}, backgroundColor: ${_this.backgroundColor}, alignment: ${_this.alignment})';
}


}

/// @nodoc
abstract mixin class $TextStyleSpecCopyWith<$Res>  {
  factory $TextStyleSpecCopyWith(TextStyleSpec value, $Res Function(TextStyleSpec) _then) = _$TextStyleSpecCopyWithImpl;
@useResult
$Res call({
 String fontId, double size, int color, int? strokeColor, double strokeWidth, int? backgroundColor, TextAlignment alignment
});




}
/// @nodoc
class _$TextStyleSpecCopyWithImpl<$Res>
    implements $TextStyleSpecCopyWith<$Res> {
  _$TextStyleSpecCopyWithImpl(this._self, this._then);

  final TextStyleSpec _self;
  final $Res Function(TextStyleSpec) _then;

/// Create a copy of TextStyleSpec
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fontId = null,Object? size = null,Object? color = null,Object? strokeColor = freezed,Object? strokeWidth = null,Object? backgroundColor = freezed,Object? alignment = null,}) {
  return _then(TextStyleSpec(
fontId: null == fontId ? _self.fontId : fontId // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as double,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as int,strokeColor: freezed == strokeColor ? _self.strokeColor : strokeColor // ignore: cast_nullable_to_non_nullable
as int?,strokeWidth: null == strokeWidth ? _self.strokeWidth : strokeWidth // ignore: cast_nullable_to_non_nullable
as double,backgroundColor: freezed == backgroundColor ? _self.backgroundColor : backgroundColor // ignore: cast_nullable_to_non_nullable
as int?,alignment: null == alignment ? _self.alignment : alignment // ignore: cast_nullable_to_non_nullable
as TextAlignment,
  ));
}

}


/// Adds pattern-matching-related methods to [TextStyleSpec].
extension TextStyleSpecPatterns on TextStyleSpec {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TextStyleSpec value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TextStyleSpec() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TextStyleSpec value)  $default,){
final _that = this;
switch (_that) {
case _TextStyleSpec():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TextStyleSpec value)?  $default,){
final _that = this;
switch (_that) {
case _TextStyleSpec() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String fontId,  double size,  int color,  int? strokeColor,  double strokeWidth,  int? backgroundColor,  TextAlignment alignment)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TextStyleSpec() when $default != null:
return $default(_that.fontId,_that.size,_that.color,_that.strokeColor,_that.strokeWidth,_that.backgroundColor,_that.alignment);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String fontId,  double size,  int color,  int? strokeColor,  double strokeWidth,  int? backgroundColor,  TextAlignment alignment)  $default,) {final _that = this;
switch (_that) {
case _TextStyleSpec():
return $default(_that.fontId,_that.size,_that.color,_that.strokeColor,_that.strokeWidth,_that.backgroundColor,_that.alignment);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String fontId,  double size,  int color,  int? strokeColor,  double strokeWidth,  int? backgroundColor,  TextAlignment alignment)?  $default,) {final _that = this;
switch (_that) {
case _TextStyleSpec() when $default != null:
return $default(_that.fontId,_that.size,_that.color,_that.strokeColor,_that.strokeWidth,_that.backgroundColor,_that.alignment);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TextStyleSpec implements TextStyleSpec {
  const _TextStyleSpec({this.fontId = 'inter', this.size = 0.05, this.color = 0xFFFFFFFF, this.strokeColor, this.strokeWidth = 0.0, this.backgroundColor, this.alignment = TextAlignment.center});
  factory _TextStyleSpec.fromJson(Map<String, dynamic> json) => _$TextStyleSpecFromJson(json);

@override@JsonKey() final  String fontId;
/// Font size as a fraction of the canvas height.
@override@JsonKey() final  double size;
@override@JsonKey() final  int color;
@override final  int? strokeColor;
/// Stroke width as a fraction of the font size; 0 for none.
@override@JsonKey() final  double strokeWidth;
/// Fill of a rounded box behind the text, or null for none.
@override final  int? backgroundColor;
@override@JsonKey() final  TextAlignment alignment;

/// Create a copy of TextStyleSpec
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TextStyleSpecCopyWith<_TextStyleSpec> get copyWith => __$TextStyleSpecCopyWithImpl<_TextStyleSpec>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TextStyleSpecToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TextStyleSpec&&(identical(other.fontId, fontId) || other.fontId == fontId)&&(identical(other.size, size) || other.size == size)&&(identical(other.color, color) || other.color == color)&&(identical(other.strokeColor, strokeColor) || other.strokeColor == strokeColor)&&(identical(other.strokeWidth, strokeWidth) || other.strokeWidth == strokeWidth)&&(identical(other.backgroundColor, backgroundColor) || other.backgroundColor == backgroundColor)&&(identical(other.alignment, alignment) || other.alignment == alignment));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,fontId,size,color,strokeColor,strokeWidth,backgroundColor,alignment);
}

@override
String toString() {
    return 'TextStyleSpec(fontId: $fontId, size: $size, color: $color, strokeColor: $strokeColor, strokeWidth: $strokeWidth, backgroundColor: $backgroundColor, alignment: $alignment)';
}


}

/// @nodoc
abstract mixin class _$TextStyleSpecCopyWith<$Res> implements $TextStyleSpecCopyWith<$Res> {
  factory _$TextStyleSpecCopyWith(_TextStyleSpec value, $Res Function(_TextStyleSpec) _then) = __$TextStyleSpecCopyWithImpl;
@override @useResult
$Res call({
 String fontId, double size, int color, int? strokeColor, double strokeWidth, int? backgroundColor, TextAlignment alignment
});




}
/// @nodoc
class __$TextStyleSpecCopyWithImpl<$Res>
    implements _$TextStyleSpecCopyWith<$Res> {
  __$TextStyleSpecCopyWithImpl(this._self, this._then);

  final _TextStyleSpec _self;
  final $Res Function(_TextStyleSpec) _then;

/// Create a copy of TextStyleSpec
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fontId = null,Object? size = null,Object? color = null,Object? strokeColor = freezed,Object? strokeWidth = null,Object? backgroundColor = freezed,Object? alignment = null,}) {
  return _then(_TextStyleSpec(
fontId: null == fontId ? _self.fontId : fontId // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as double,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as int,strokeColor: freezed == strokeColor ? _self.strokeColor : strokeColor // ignore: cast_nullable_to_non_nullable
as int?,strokeWidth: null == strokeWidth ? _self.strokeWidth : strokeWidth // ignore: cast_nullable_to_non_nullable
as double,backgroundColor: freezed == backgroundColor ? _self.backgroundColor : backgroundColor // ignore: cast_nullable_to_non_nullable
as int?,alignment: null == alignment ? _self.alignment : alignment // ignore: cast_nullable_to_non_nullable
as TextAlignment,
  ));
}


}


/// @nodoc
mixin _$TextItem {

 String get id; String get text; Anchor get anchor; int get durationUs; int get laneIndex; TextStyleSpec get style; ItemTransform get transform; TextAnimation get animationIn; TextAnimation get animationOut;/// The clip this item was anchored to was deleted.
 bool get needsReview;
/// Create a copy of TextItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TextItemCopyWith<TextItem> get copyWith => _$TextItemCopyWithImpl<TextItem>(this as TextItem, _$identity);

  /// Serializes this TextItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TextItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TextItem&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.text, _this.text) || other.text == _this.text)&&(identical(other.anchor, _this.anchor) || other.anchor == _this.anchor)&&(identical(other.durationUs, _this.durationUs) || other.durationUs == _this.durationUs)&&(identical(other.laneIndex, _this.laneIndex) || other.laneIndex == _this.laneIndex)&&(identical(other.style, _this.style) || other.style == _this.style)&&(identical(other.transform, _this.transform) || other.transform == _this.transform)&&(identical(other.animationIn, _this.animationIn) || other.animationIn == _this.animationIn)&&(identical(other.animationOut, _this.animationOut) || other.animationOut == _this.animationOut)&&(identical(other.needsReview, _this.needsReview) || other.needsReview == _this.needsReview));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TextItem;
  return Object.hash(runtimeType,_this.id,_this.text,_this.anchor,_this.durationUs,_this.laneIndex,_this.style,_this.transform,_this.animationIn,_this.animationOut,_this.needsReview);
}

@override
String toString() {
  final _this = this as TextItem;
  return 'TextItem(id: ${_this.id}, text: ${_this.text}, anchor: ${_this.anchor}, durationUs: ${_this.durationUs}, laneIndex: ${_this.laneIndex}, style: ${_this.style}, transform: ${_this.transform}, animationIn: ${_this.animationIn}, animationOut: ${_this.animationOut}, needsReview: ${_this.needsReview})';
}


}

/// @nodoc
abstract mixin class $TextItemCopyWith<$Res>  {
  factory $TextItemCopyWith(TextItem value, $Res Function(TextItem) _then) = _$TextItemCopyWithImpl;
@useResult
$Res call({
 String id, String text, Anchor anchor, int durationUs, int laneIndex, TextStyleSpec style, ItemTransform transform, TextAnimation animationIn, TextAnimation animationOut, bool needsReview
});


$AnchorCopyWith<$Res> get anchor;$TextStyleSpecCopyWith<$Res> get style;$ItemTransformCopyWith<$Res> get transform;

}
/// @nodoc
class _$TextItemCopyWithImpl<$Res>
    implements $TextItemCopyWith<$Res> {
  _$TextItemCopyWithImpl(this._self, this._then);

  final TextItem _self;
  final $Res Function(TextItem) _then;

/// Create a copy of TextItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? text = null,Object? anchor = null,Object? durationUs = null,Object? laneIndex = null,Object? style = null,Object? transform = null,Object? animationIn = null,Object? animationOut = null,Object? needsReview = null,}) {
  return _then(TextItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,anchor: null == anchor ? _self.anchor : anchor // ignore: cast_nullable_to_non_nullable
as Anchor,durationUs: null == durationUs ? _self.durationUs : durationUs // ignore: cast_nullable_to_non_nullable
as int,laneIndex: null == laneIndex ? _self.laneIndex : laneIndex // ignore: cast_nullable_to_non_nullable
as int,style: null == style ? _self.style : style // ignore: cast_nullable_to_non_nullable
as TextStyleSpec,transform: null == transform ? _self.transform : transform // ignore: cast_nullable_to_non_nullable
as ItemTransform,animationIn: null == animationIn ? _self.animationIn : animationIn // ignore: cast_nullable_to_non_nullable
as TextAnimation,animationOut: null == animationOut ? _self.animationOut : animationOut // ignore: cast_nullable_to_non_nullable
as TextAnimation,needsReview: null == needsReview ? _self.needsReview : needsReview // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of TextItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AnchorCopyWith<$Res> get anchor {
  
  return $AnchorCopyWith<$Res>(_self.anchor, (value) {
    return _then(_self.copyWith(anchor: value));
  });
}/// Create a copy of TextItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TextStyleSpecCopyWith<$Res> get style {
  
  return $TextStyleSpecCopyWith<$Res>(_self.style, (value) {
    return _then(_self.copyWith(style: value));
  });
}/// Create a copy of TextItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ItemTransformCopyWith<$Res> get transform {
  
  return $ItemTransformCopyWith<$Res>(_self.transform, (value) {
    return _then(_self.copyWith(transform: value));
  });
}
}


/// Adds pattern-matching-related methods to [TextItem].
extension TextItemPatterns on TextItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TextItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TextItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TextItem value)  $default,){
final _that = this;
switch (_that) {
case _TextItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TextItem value)?  $default,){
final _that = this;
switch (_that) {
case _TextItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String text,  Anchor anchor,  int durationUs,  int laneIndex,  TextStyleSpec style,  ItemTransform transform,  TextAnimation animationIn,  TextAnimation animationOut,  bool needsReview)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TextItem() when $default != null:
return $default(_that.id,_that.text,_that.anchor,_that.durationUs,_that.laneIndex,_that.style,_that.transform,_that.animationIn,_that.animationOut,_that.needsReview);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String text,  Anchor anchor,  int durationUs,  int laneIndex,  TextStyleSpec style,  ItemTransform transform,  TextAnimation animationIn,  TextAnimation animationOut,  bool needsReview)  $default,) {final _that = this;
switch (_that) {
case _TextItem():
return $default(_that.id,_that.text,_that.anchor,_that.durationUs,_that.laneIndex,_that.style,_that.transform,_that.animationIn,_that.animationOut,_that.needsReview);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String text,  Anchor anchor,  int durationUs,  int laneIndex,  TextStyleSpec style,  ItemTransform transform,  TextAnimation animationIn,  TextAnimation animationOut,  bool needsReview)?  $default,) {final _that = this;
switch (_that) {
case _TextItem() when $default != null:
return $default(_that.id,_that.text,_that.anchor,_that.durationUs,_that.laneIndex,_that.style,_that.transform,_that.animationIn,_that.animationOut,_that.needsReview);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TextItem implements TextItem {
  const _TextItem({required this.id, required this.text, required this.anchor, required this.durationUs, this.laneIndex = 0, this.style = const TextStyleSpec(), this.transform = const ItemTransform(), this.animationIn = TextAnimation.none, this.animationOut = TextAnimation.none, this.needsReview = false});
  factory _TextItem.fromJson(Map<String, dynamic> json) => _$TextItemFromJson(json);

@override final  String id;
@override final  String text;
@override final  Anchor anchor;
@override final  int durationUs;
@override@JsonKey() final  int laneIndex;
@override@JsonKey() final  TextStyleSpec style;
@override@JsonKey() final  ItemTransform transform;
@override@JsonKey() final  TextAnimation animationIn;
@override@JsonKey() final  TextAnimation animationOut;
/// The clip this item was anchored to was deleted.
@override@JsonKey() final  bool needsReview;

/// Create a copy of TextItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TextItemCopyWith<_TextItem> get copyWith => __$TextItemCopyWithImpl<_TextItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TextItemToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TextItem&&(identical(other.id, id) || other.id == id)&&(identical(other.text, text) || other.text == text)&&(identical(other.anchor, anchor) || other.anchor == anchor)&&(identical(other.durationUs, durationUs) || other.durationUs == durationUs)&&(identical(other.laneIndex, laneIndex) || other.laneIndex == laneIndex)&&(identical(other.style, style) || other.style == style)&&(identical(other.transform, transform) || other.transform == transform)&&(identical(other.animationIn, animationIn) || other.animationIn == animationIn)&&(identical(other.animationOut, animationOut) || other.animationOut == animationOut)&&(identical(other.needsReview, needsReview) || other.needsReview == needsReview));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,text,anchor,durationUs,laneIndex,style,transform,animationIn,animationOut,needsReview);
}

@override
String toString() {
    return 'TextItem(id: $id, text: $text, anchor: $anchor, durationUs: $durationUs, laneIndex: $laneIndex, style: $style, transform: $transform, animationIn: $animationIn, animationOut: $animationOut, needsReview: $needsReview)';
}


}

/// @nodoc
abstract mixin class _$TextItemCopyWith<$Res> implements $TextItemCopyWith<$Res> {
  factory _$TextItemCopyWith(_TextItem value, $Res Function(_TextItem) _then) = __$TextItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String text, Anchor anchor, int durationUs, int laneIndex, TextStyleSpec style, ItemTransform transform, TextAnimation animationIn, TextAnimation animationOut, bool needsReview
});


@override $AnchorCopyWith<$Res> get anchor;@override $TextStyleSpecCopyWith<$Res> get style;@override $ItemTransformCopyWith<$Res> get transform;

}
/// @nodoc
class __$TextItemCopyWithImpl<$Res>
    implements _$TextItemCopyWith<$Res> {
  __$TextItemCopyWithImpl(this._self, this._then);

  final _TextItem _self;
  final $Res Function(_TextItem) _then;

/// Create a copy of TextItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? text = null,Object? anchor = null,Object? durationUs = null,Object? laneIndex = null,Object? style = null,Object? transform = null,Object? animationIn = null,Object? animationOut = null,Object? needsReview = null,}) {
  return _then(_TextItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,anchor: null == anchor ? _self.anchor : anchor // ignore: cast_nullable_to_non_nullable
as Anchor,durationUs: null == durationUs ? _self.durationUs : durationUs // ignore: cast_nullable_to_non_nullable
as int,laneIndex: null == laneIndex ? _self.laneIndex : laneIndex // ignore: cast_nullable_to_non_nullable
as int,style: null == style ? _self.style : style // ignore: cast_nullable_to_non_nullable
as TextStyleSpec,transform: null == transform ? _self.transform : transform // ignore: cast_nullable_to_non_nullable
as ItemTransform,animationIn: null == animationIn ? _self.animationIn : animationIn // ignore: cast_nullable_to_non_nullable
as TextAnimation,animationOut: null == animationOut ? _self.animationOut : animationOut // ignore: cast_nullable_to_non_nullable
as TextAnimation,needsReview: null == needsReview ? _self.needsReview : needsReview // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of TextItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AnchorCopyWith<$Res> get anchor {
  
  return $AnchorCopyWith<$Res>(_self.anchor, (value) {
    return _then(_self.copyWith(anchor: value));
  });
}/// Create a copy of TextItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TextStyleSpecCopyWith<$Res> get style {
  
  return $TextStyleSpecCopyWith<$Res>(_self.style, (value) {
    return _then(_self.copyWith(style: value));
  });
}/// Create a copy of TextItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ItemTransformCopyWith<$Res> get transform {
  
  return $ItemTransformCopyWith<$Res>(_self.transform, (value) {
    return _then(_self.copyWith(transform: value));
  });
}
}


/// @nodoc
mixin _$CaptionWord {

 String get text; int get startOffsetUs; int get endOffsetUs;
/// Create a copy of CaptionWord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CaptionWordCopyWith<CaptionWord> get copyWith => _$CaptionWordCopyWithImpl<CaptionWord>(this as CaptionWord, _$identity);

  /// Serializes this CaptionWord to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CaptionWord;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CaptionWord&&(identical(other.text, _this.text) || other.text == _this.text)&&(identical(other.startOffsetUs, _this.startOffsetUs) || other.startOffsetUs == _this.startOffsetUs)&&(identical(other.endOffsetUs, _this.endOffsetUs) || other.endOffsetUs == _this.endOffsetUs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CaptionWord;
  return Object.hash(runtimeType,_this.text,_this.startOffsetUs,_this.endOffsetUs);
}

@override
String toString() {
  final _this = this as CaptionWord;
  return 'CaptionWord(text: ${_this.text}, startOffsetUs: ${_this.startOffsetUs}, endOffsetUs: ${_this.endOffsetUs})';
}


}

/// @nodoc
abstract mixin class $CaptionWordCopyWith<$Res>  {
  factory $CaptionWordCopyWith(CaptionWord value, $Res Function(CaptionWord) _then) = _$CaptionWordCopyWithImpl;
@useResult
$Res call({
 String text, int startOffsetUs, int endOffsetUs
});




}
/// @nodoc
class _$CaptionWordCopyWithImpl<$Res>
    implements $CaptionWordCopyWith<$Res> {
  _$CaptionWordCopyWithImpl(this._self, this._then);

  final CaptionWord _self;
  final $Res Function(CaptionWord) _then;

/// Create a copy of CaptionWord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? text = null,Object? startOffsetUs = null,Object? endOffsetUs = null,}) {
  return _then(CaptionWord(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,startOffsetUs: null == startOffsetUs ? _self.startOffsetUs : startOffsetUs // ignore: cast_nullable_to_non_nullable
as int,endOffsetUs: null == endOffsetUs ? _self.endOffsetUs : endOffsetUs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CaptionWord].
extension CaptionWordPatterns on CaptionWord {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CaptionWord value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CaptionWord() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CaptionWord value)  $default,){
final _that = this;
switch (_that) {
case _CaptionWord():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CaptionWord value)?  $default,){
final _that = this;
switch (_that) {
case _CaptionWord() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String text,  int startOffsetUs,  int endOffsetUs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CaptionWord() when $default != null:
return $default(_that.text,_that.startOffsetUs,_that.endOffsetUs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String text,  int startOffsetUs,  int endOffsetUs)  $default,) {final _that = this;
switch (_that) {
case _CaptionWord():
return $default(_that.text,_that.startOffsetUs,_that.endOffsetUs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String text,  int startOffsetUs,  int endOffsetUs)?  $default,) {final _that = this;
switch (_that) {
case _CaptionWord() when $default != null:
return $default(_that.text,_that.startOffsetUs,_that.endOffsetUs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CaptionWord implements CaptionWord {
  const _CaptionWord({required this.text, required this.startOffsetUs, required this.endOffsetUs});
  factory _CaptionWord.fromJson(Map<String, dynamic> json) => _$CaptionWordFromJson(json);

@override final  String text;
@override final  int startOffsetUs;
@override final  int endOffsetUs;

/// Create a copy of CaptionWord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CaptionWordCopyWith<_CaptionWord> get copyWith => __$CaptionWordCopyWithImpl<_CaptionWord>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CaptionWordToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CaptionWord&&(identical(other.text, text) || other.text == text)&&(identical(other.startOffsetUs, startOffsetUs) || other.startOffsetUs == startOffsetUs)&&(identical(other.endOffsetUs, endOffsetUs) || other.endOffsetUs == endOffsetUs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,text,startOffsetUs,endOffsetUs);
}

@override
String toString() {
    return 'CaptionWord(text: $text, startOffsetUs: $startOffsetUs, endOffsetUs: $endOffsetUs)';
}


}

/// @nodoc
abstract mixin class _$CaptionWordCopyWith<$Res> implements $CaptionWordCopyWith<$Res> {
  factory _$CaptionWordCopyWith(_CaptionWord value, $Res Function(_CaptionWord) _then) = __$CaptionWordCopyWithImpl;
@override @useResult
$Res call({
 String text, int startOffsetUs, int endOffsetUs
});




}
/// @nodoc
class __$CaptionWordCopyWithImpl<$Res>
    implements _$CaptionWordCopyWith<$Res> {
  __$CaptionWordCopyWithImpl(this._self, this._then);

  final _CaptionWord _self;
  final $Res Function(_CaptionWord) _then;

/// Create a copy of CaptionWord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = null,Object? startOffsetUs = null,Object? endOffsetUs = null,}) {
  return _then(_CaptionWord(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,startOffsetUs: null == startOffsetUs ? _self.startOffsetUs : startOffsetUs // ignore: cast_nullable_to_non_nullable
as int,endOffsetUs: null == endOffsetUs ? _self.endOffsetUs : endOffsetUs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$CaptionSegment {

 String get id; String get text; Anchor get anchor; int get durationUs; List<CaptionWord> get words; bool get needsReview;
/// Create a copy of CaptionSegment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CaptionSegmentCopyWith<CaptionSegment> get copyWith => _$CaptionSegmentCopyWithImpl<CaptionSegment>(this as CaptionSegment, _$identity);

  /// Serializes this CaptionSegment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CaptionSegment;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CaptionSegment&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.text, _this.text) || other.text == _this.text)&&(identical(other.anchor, _this.anchor) || other.anchor == _this.anchor)&&(identical(other.durationUs, _this.durationUs) || other.durationUs == _this.durationUs)&&const DeepCollectionEquality().equals(other.words, _this.words)&&(identical(other.needsReview, _this.needsReview) || other.needsReview == _this.needsReview));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CaptionSegment;
  return Object.hash(runtimeType,_this.id,_this.text,_this.anchor,_this.durationUs,const DeepCollectionEquality().hash(_this.words),_this.needsReview);
}

@override
String toString() {
  final _this = this as CaptionSegment;
  return 'CaptionSegment(id: ${_this.id}, text: ${_this.text}, anchor: ${_this.anchor}, durationUs: ${_this.durationUs}, words: ${_this.words}, needsReview: ${_this.needsReview})';
}


}

/// @nodoc
abstract mixin class $CaptionSegmentCopyWith<$Res>  {
  factory $CaptionSegmentCopyWith(CaptionSegment value, $Res Function(CaptionSegment) _then) = _$CaptionSegmentCopyWithImpl;
@useResult
$Res call({
 String id, String text, Anchor anchor, int durationUs, List<CaptionWord> words, bool needsReview
});


$AnchorCopyWith<$Res> get anchor;

}
/// @nodoc
class _$CaptionSegmentCopyWithImpl<$Res>
    implements $CaptionSegmentCopyWith<$Res> {
  _$CaptionSegmentCopyWithImpl(this._self, this._then);

  final CaptionSegment _self;
  final $Res Function(CaptionSegment) _then;

/// Create a copy of CaptionSegment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? text = null,Object? anchor = null,Object? durationUs = null,Object? words = null,Object? needsReview = null,}) {
  return _then(CaptionSegment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,anchor: null == anchor ? _self.anchor : anchor // ignore: cast_nullable_to_non_nullable
as Anchor,durationUs: null == durationUs ? _self.durationUs : durationUs // ignore: cast_nullable_to_non_nullable
as int,words: null == words ? _self.words : words // ignore: cast_nullable_to_non_nullable
as List<CaptionWord>,needsReview: null == needsReview ? _self.needsReview : needsReview // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of CaptionSegment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AnchorCopyWith<$Res> get anchor {
  
  return $AnchorCopyWith<$Res>(_self.anchor, (value) {
    return _then(_self.copyWith(anchor: value));
  });
}
}


/// Adds pattern-matching-related methods to [CaptionSegment].
extension CaptionSegmentPatterns on CaptionSegment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CaptionSegment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CaptionSegment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CaptionSegment value)  $default,){
final _that = this;
switch (_that) {
case _CaptionSegment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CaptionSegment value)?  $default,){
final _that = this;
switch (_that) {
case _CaptionSegment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String text,  Anchor anchor,  int durationUs,  List<CaptionWord> words,  bool needsReview)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CaptionSegment() when $default != null:
return $default(_that.id,_that.text,_that.anchor,_that.durationUs,_that.words,_that.needsReview);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String text,  Anchor anchor,  int durationUs,  List<CaptionWord> words,  bool needsReview)  $default,) {final _that = this;
switch (_that) {
case _CaptionSegment():
return $default(_that.id,_that.text,_that.anchor,_that.durationUs,_that.words,_that.needsReview);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String text,  Anchor anchor,  int durationUs,  List<CaptionWord> words,  bool needsReview)?  $default,) {final _that = this;
switch (_that) {
case _CaptionSegment() when $default != null:
return $default(_that.id,_that.text,_that.anchor,_that.durationUs,_that.words,_that.needsReview);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CaptionSegment implements CaptionSegment {
  const _CaptionSegment({required this.id, required this.text, required this.anchor, required this.durationUs,  List<CaptionWord> words = const <CaptionWord>[], this.needsReview = false}): _words = words;
  factory _CaptionSegment.fromJson(Map<String, dynamic> json) => _$CaptionSegmentFromJson(json);

@override final  String id;
@override final  String text;
@override final  Anchor anchor;
@override final  int durationUs;
 final  List<CaptionWord> _words;
@override@JsonKey() List<CaptionWord> get words {
  if (_words is EqualUnmodifiableListView) return _words;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_words);
}

@override@JsonKey() final  bool needsReview;

/// Create a copy of CaptionSegment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CaptionSegmentCopyWith<_CaptionSegment> get copyWith => __$CaptionSegmentCopyWithImpl<_CaptionSegment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CaptionSegmentToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CaptionSegment&&(identical(other.id, id) || other.id == id)&&(identical(other.text, text) || other.text == text)&&(identical(other.anchor, anchor) || other.anchor == anchor)&&(identical(other.durationUs, durationUs) || other.durationUs == durationUs)&&const DeepCollectionEquality().equals(other.words, _words)&&(identical(other.needsReview, needsReview) || other.needsReview == needsReview));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,text,anchor,durationUs,const DeepCollectionEquality().hash(_words),needsReview);
}

@override
String toString() {
    return 'CaptionSegment(id: $id, text: $text, anchor: $anchor, durationUs: $durationUs, words: $words, needsReview: $needsReview)';
}


}

/// @nodoc
abstract mixin class _$CaptionSegmentCopyWith<$Res> implements $CaptionSegmentCopyWith<$Res> {
  factory _$CaptionSegmentCopyWith(_CaptionSegment value, $Res Function(_CaptionSegment) _then) = __$CaptionSegmentCopyWithImpl;
@override @useResult
$Res call({
 String id, String text, Anchor anchor, int durationUs, List<CaptionWord> words, bool needsReview
});


@override $AnchorCopyWith<$Res> get anchor;

}
/// @nodoc
class __$CaptionSegmentCopyWithImpl<$Res>
    implements _$CaptionSegmentCopyWith<$Res> {
  __$CaptionSegmentCopyWithImpl(this._self, this._then);

  final _CaptionSegment _self;
  final $Res Function(_CaptionSegment) _then;

/// Create a copy of CaptionSegment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? text = null,Object? anchor = null,Object? durationUs = null,Object? words = null,Object? needsReview = null,}) {
  return _then(_CaptionSegment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,anchor: null == anchor ? _self.anchor : anchor // ignore: cast_nullable_to_non_nullable
as Anchor,durationUs: null == durationUs ? _self.durationUs : durationUs // ignore: cast_nullable_to_non_nullable
as int,words: null == words ? _self._words : words // ignore: cast_nullable_to_non_nullable
as List<CaptionWord>,needsReview: null == needsReview ? _self.needsReview : needsReview // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of CaptionSegment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AnchorCopyWith<$Res> get anchor {
  
  return $AnchorCopyWith<$Res>(_self.anchor, (value) {
    return _then(_self.copyWith(anchor: value));
  });
}
}


/// @nodoc
mixin _$CaptionTrack {

 List<CaptionSegment> get segments; CaptionPreset get preset; CaptionPosition get position;/// BCP 47 language of the recognized speech, if known.
 String? get language;
/// Create a copy of CaptionTrack
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CaptionTrackCopyWith<CaptionTrack> get copyWith => _$CaptionTrackCopyWithImpl<CaptionTrack>(this as CaptionTrack, _$identity);

  /// Serializes this CaptionTrack to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CaptionTrack;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CaptionTrack&&const DeepCollectionEquality().equals(other.segments, _this.segments)&&(identical(other.preset, _this.preset) || other.preset == _this.preset)&&(identical(other.position, _this.position) || other.position == _this.position)&&(identical(other.language, _this.language) || other.language == _this.language));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CaptionTrack;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.segments),_this.preset,_this.position,_this.language);
}

@override
String toString() {
  final _this = this as CaptionTrack;
  return 'CaptionTrack(segments: ${_this.segments}, preset: ${_this.preset}, position: ${_this.position}, language: ${_this.language})';
}


}

/// @nodoc
abstract mixin class $CaptionTrackCopyWith<$Res>  {
  factory $CaptionTrackCopyWith(CaptionTrack value, $Res Function(CaptionTrack) _then) = _$CaptionTrackCopyWithImpl;
@useResult
$Res call({
 List<CaptionSegment> segments, CaptionPreset preset, CaptionPosition position, String? language
});




}
/// @nodoc
class _$CaptionTrackCopyWithImpl<$Res>
    implements $CaptionTrackCopyWith<$Res> {
  _$CaptionTrackCopyWithImpl(this._self, this._then);

  final CaptionTrack _self;
  final $Res Function(CaptionTrack) _then;

/// Create a copy of CaptionTrack
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? segments = null,Object? preset = null,Object? position = null,Object? language = freezed,}) {
  return _then(CaptionTrack(
segments: null == segments ? _self.segments : segments // ignore: cast_nullable_to_non_nullable
as List<CaptionSegment>,preset: null == preset ? _self.preset : preset // ignore: cast_nullable_to_non_nullable
as CaptionPreset,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as CaptionPosition,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CaptionTrack].
extension CaptionTrackPatterns on CaptionTrack {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CaptionTrack value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CaptionTrack() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CaptionTrack value)  $default,){
final _that = this;
switch (_that) {
case _CaptionTrack():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CaptionTrack value)?  $default,){
final _that = this;
switch (_that) {
case _CaptionTrack() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<CaptionSegment> segments,  CaptionPreset preset,  CaptionPosition position,  String? language)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CaptionTrack() when $default != null:
return $default(_that.segments,_that.preset,_that.position,_that.language);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<CaptionSegment> segments,  CaptionPreset preset,  CaptionPosition position,  String? language)  $default,) {final _that = this;
switch (_that) {
case _CaptionTrack():
return $default(_that.segments,_that.preset,_that.position,_that.language);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<CaptionSegment> segments,  CaptionPreset preset,  CaptionPosition position,  String? language)?  $default,) {final _that = this;
switch (_that) {
case _CaptionTrack() when $default != null:
return $default(_that.segments,_that.preset,_that.position,_that.language);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CaptionTrack implements CaptionTrack {
  const _CaptionTrack({ List<CaptionSegment> segments = const <CaptionSegment>[], this.preset = CaptionPreset.plain, this.position = CaptionPosition.bottom, this.language}): _segments = segments;
  factory _CaptionTrack.fromJson(Map<String, dynamic> json) => _$CaptionTrackFromJson(json);

 final  List<CaptionSegment> _segments;
@override@JsonKey() List<CaptionSegment> get segments {
  if (_segments is EqualUnmodifiableListView) return _segments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_segments);
}

@override@JsonKey() final  CaptionPreset preset;
@override@JsonKey() final  CaptionPosition position;
/// BCP 47 language of the recognized speech, if known.
@override final  String? language;

/// Create a copy of CaptionTrack
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CaptionTrackCopyWith<_CaptionTrack> get copyWith => __$CaptionTrackCopyWithImpl<_CaptionTrack>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CaptionTrackToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CaptionTrack&&const DeepCollectionEquality().equals(other.segments, _segments)&&(identical(other.preset, preset) || other.preset == preset)&&(identical(other.position, position) || other.position == position)&&(identical(other.language, language) || other.language == language));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_segments),preset,position,language);
}

@override
String toString() {
    return 'CaptionTrack(segments: $segments, preset: $preset, position: $position, language: $language)';
}


}

/// @nodoc
abstract mixin class _$CaptionTrackCopyWith<$Res> implements $CaptionTrackCopyWith<$Res> {
  factory _$CaptionTrackCopyWith(_CaptionTrack value, $Res Function(_CaptionTrack) _then) = __$CaptionTrackCopyWithImpl;
@override @useResult
$Res call({
 List<CaptionSegment> segments, CaptionPreset preset, CaptionPosition position, String? language
});




}
/// @nodoc
class __$CaptionTrackCopyWithImpl<$Res>
    implements _$CaptionTrackCopyWith<$Res> {
  __$CaptionTrackCopyWithImpl(this._self, this._then);

  final _CaptionTrack _self;
  final $Res Function(_CaptionTrack) _then;

/// Create a copy of CaptionTrack
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? segments = null,Object? preset = null,Object? position = null,Object? language = freezed,}) {
  return _then(_CaptionTrack(
segments: null == segments ? _self._segments : segments // ignore: cast_nullable_to_non_nullable
as List<CaptionSegment>,preset: null == preset ? _self.preset : preset // ignore: cast_nullable_to_non_nullable
as CaptionPreset,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as CaptionPosition,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$AudioItem {

 String get id; String get mediaId; AudioKind get kind; String get name; Anchor get anchor;/// Length of the source file.
 int get mediaDurationUs; int get sourceInUs; int get sourceOutUs; int get laneIndex; double get volume; int get fadeInUs; int get fadeOutUs; double get speed;/// Repeats the source span until the end of the video.
 bool get loop; bool get needsReview;
/// Create a copy of AudioItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AudioItemCopyWith<AudioItem> get copyWith => _$AudioItemCopyWithImpl<AudioItem>(this as AudioItem, _$identity);

  /// Serializes this AudioItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AudioItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AudioItem&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.mediaId, _this.mediaId) || other.mediaId == _this.mediaId)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.anchor, _this.anchor) || other.anchor == _this.anchor)&&(identical(other.mediaDurationUs, _this.mediaDurationUs) || other.mediaDurationUs == _this.mediaDurationUs)&&(identical(other.sourceInUs, _this.sourceInUs) || other.sourceInUs == _this.sourceInUs)&&(identical(other.sourceOutUs, _this.sourceOutUs) || other.sourceOutUs == _this.sourceOutUs)&&(identical(other.laneIndex, _this.laneIndex) || other.laneIndex == _this.laneIndex)&&(identical(other.volume, _this.volume) || other.volume == _this.volume)&&(identical(other.fadeInUs, _this.fadeInUs) || other.fadeInUs == _this.fadeInUs)&&(identical(other.fadeOutUs, _this.fadeOutUs) || other.fadeOutUs == _this.fadeOutUs)&&(identical(other.speed, _this.speed) || other.speed == _this.speed)&&(identical(other.loop, _this.loop) || other.loop == _this.loop)&&(identical(other.needsReview, _this.needsReview) || other.needsReview == _this.needsReview));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AudioItem;
  return Object.hash(runtimeType,_this.id,_this.mediaId,_this.kind,_this.name,_this.anchor,_this.mediaDurationUs,_this.sourceInUs,_this.sourceOutUs,_this.laneIndex,_this.volume,_this.fadeInUs,_this.fadeOutUs,_this.speed,_this.loop,_this.needsReview);
}

@override
String toString() {
  final _this = this as AudioItem;
  return 'AudioItem(id: ${_this.id}, mediaId: ${_this.mediaId}, kind: ${_this.kind}, name: ${_this.name}, anchor: ${_this.anchor}, mediaDurationUs: ${_this.mediaDurationUs}, sourceInUs: ${_this.sourceInUs}, sourceOutUs: ${_this.sourceOutUs}, laneIndex: ${_this.laneIndex}, volume: ${_this.volume}, fadeInUs: ${_this.fadeInUs}, fadeOutUs: ${_this.fadeOutUs}, speed: ${_this.speed}, loop: ${_this.loop}, needsReview: ${_this.needsReview})';
}


}

/// @nodoc
abstract mixin class $AudioItemCopyWith<$Res>  {
  factory $AudioItemCopyWith(AudioItem value, $Res Function(AudioItem) _then) = _$AudioItemCopyWithImpl;
@useResult
$Res call({
 String id, String mediaId, AudioKind kind, String name, Anchor anchor, int mediaDurationUs, int sourceInUs, int sourceOutUs, int laneIndex, double volume, int fadeInUs, int fadeOutUs, double speed, bool loop, bool needsReview
});


$AnchorCopyWith<$Res> get anchor;

}
/// @nodoc
class _$AudioItemCopyWithImpl<$Res>
    implements $AudioItemCopyWith<$Res> {
  _$AudioItemCopyWithImpl(this._self, this._then);

  final AudioItem _self;
  final $Res Function(AudioItem) _then;

/// Create a copy of AudioItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? mediaId = null,Object? kind = null,Object? name = null,Object? anchor = null,Object? mediaDurationUs = null,Object? sourceInUs = null,Object? sourceOutUs = null,Object? laneIndex = null,Object? volume = null,Object? fadeInUs = null,Object? fadeOutUs = null,Object? speed = null,Object? loop = null,Object? needsReview = null,}) {
  return _then(AudioItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,mediaId: null == mediaId ? _self.mediaId : mediaId // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as AudioKind,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,anchor: null == anchor ? _self.anchor : anchor // ignore: cast_nullable_to_non_nullable
as Anchor,mediaDurationUs: null == mediaDurationUs ? _self.mediaDurationUs : mediaDurationUs // ignore: cast_nullable_to_non_nullable
as int,sourceInUs: null == sourceInUs ? _self.sourceInUs : sourceInUs // ignore: cast_nullable_to_non_nullable
as int,sourceOutUs: null == sourceOutUs ? _self.sourceOutUs : sourceOutUs // ignore: cast_nullable_to_non_nullable
as int,laneIndex: null == laneIndex ? _self.laneIndex : laneIndex // ignore: cast_nullable_to_non_nullable
as int,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,fadeInUs: null == fadeInUs ? _self.fadeInUs : fadeInUs // ignore: cast_nullable_to_non_nullable
as int,fadeOutUs: null == fadeOutUs ? _self.fadeOutUs : fadeOutUs // ignore: cast_nullable_to_non_nullable
as int,speed: null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double,loop: null == loop ? _self.loop : loop // ignore: cast_nullable_to_non_nullable
as bool,needsReview: null == needsReview ? _self.needsReview : needsReview // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of AudioItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AnchorCopyWith<$Res> get anchor {
  
  return $AnchorCopyWith<$Res>(_self.anchor, (value) {
    return _then(_self.copyWith(anchor: value));
  });
}
}


/// Adds pattern-matching-related methods to [AudioItem].
extension AudioItemPatterns on AudioItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AudioItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AudioItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AudioItem value)  $default,){
final _that = this;
switch (_that) {
case _AudioItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AudioItem value)?  $default,){
final _that = this;
switch (_that) {
case _AudioItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String mediaId,  AudioKind kind,  String name,  Anchor anchor,  int mediaDurationUs,  int sourceInUs,  int sourceOutUs,  int laneIndex,  double volume,  int fadeInUs,  int fadeOutUs,  double speed,  bool loop,  bool needsReview)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AudioItem() when $default != null:
return $default(_that.id,_that.mediaId,_that.kind,_that.name,_that.anchor,_that.mediaDurationUs,_that.sourceInUs,_that.sourceOutUs,_that.laneIndex,_that.volume,_that.fadeInUs,_that.fadeOutUs,_that.speed,_that.loop,_that.needsReview);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String mediaId,  AudioKind kind,  String name,  Anchor anchor,  int mediaDurationUs,  int sourceInUs,  int sourceOutUs,  int laneIndex,  double volume,  int fadeInUs,  int fadeOutUs,  double speed,  bool loop,  bool needsReview)  $default,) {final _that = this;
switch (_that) {
case _AudioItem():
return $default(_that.id,_that.mediaId,_that.kind,_that.name,_that.anchor,_that.mediaDurationUs,_that.sourceInUs,_that.sourceOutUs,_that.laneIndex,_that.volume,_that.fadeInUs,_that.fadeOutUs,_that.speed,_that.loop,_that.needsReview);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String mediaId,  AudioKind kind,  String name,  Anchor anchor,  int mediaDurationUs,  int sourceInUs,  int sourceOutUs,  int laneIndex,  double volume,  int fadeInUs,  int fadeOutUs,  double speed,  bool loop,  bool needsReview)?  $default,) {final _that = this;
switch (_that) {
case _AudioItem() when $default != null:
return $default(_that.id,_that.mediaId,_that.kind,_that.name,_that.anchor,_that.mediaDurationUs,_that.sourceInUs,_that.sourceOutUs,_that.laneIndex,_that.volume,_that.fadeInUs,_that.fadeOutUs,_that.speed,_that.loop,_that.needsReview);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AudioItem extends AudioItem {
  const _AudioItem({required this.id, required this.mediaId, required this.kind, required this.name, required this.anchor, required this.mediaDurationUs, required this.sourceInUs, required this.sourceOutUs, this.laneIndex = 0, this.volume = 1.0, this.fadeInUs = 0, this.fadeOutUs = 0, this.speed = 1.0, this.loop = false, this.needsReview = false}): super._();
  factory _AudioItem.fromJson(Map<String, dynamic> json) => _$AudioItemFromJson(json);

@override final  String id;
@override final  String mediaId;
@override final  AudioKind kind;
@override final  String name;
@override final  Anchor anchor;
/// Length of the source file.
@override final  int mediaDurationUs;
@override final  int sourceInUs;
@override final  int sourceOutUs;
@override@JsonKey() final  int laneIndex;
@override@JsonKey() final  double volume;
@override@JsonKey() final  int fadeInUs;
@override@JsonKey() final  int fadeOutUs;
@override@JsonKey() final  double speed;
/// Repeats the source span until the end of the video.
@override@JsonKey() final  bool loop;
@override@JsonKey() final  bool needsReview;

/// Create a copy of AudioItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AudioItemCopyWith<_AudioItem> get copyWith => __$AudioItemCopyWithImpl<_AudioItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AudioItemToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AudioItem&&(identical(other.id, id) || other.id == id)&&(identical(other.mediaId, mediaId) || other.mediaId == mediaId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.name, name) || other.name == name)&&(identical(other.anchor, anchor) || other.anchor == anchor)&&(identical(other.mediaDurationUs, mediaDurationUs) || other.mediaDurationUs == mediaDurationUs)&&(identical(other.sourceInUs, sourceInUs) || other.sourceInUs == sourceInUs)&&(identical(other.sourceOutUs, sourceOutUs) || other.sourceOutUs == sourceOutUs)&&(identical(other.laneIndex, laneIndex) || other.laneIndex == laneIndex)&&(identical(other.volume, volume) || other.volume == volume)&&(identical(other.fadeInUs, fadeInUs) || other.fadeInUs == fadeInUs)&&(identical(other.fadeOutUs, fadeOutUs) || other.fadeOutUs == fadeOutUs)&&(identical(other.speed, speed) || other.speed == speed)&&(identical(other.loop, loop) || other.loop == loop)&&(identical(other.needsReview, needsReview) || other.needsReview == needsReview));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,mediaId,kind,name,anchor,mediaDurationUs,sourceInUs,sourceOutUs,laneIndex,volume,fadeInUs,fadeOutUs,speed,loop,needsReview);
}

@override
String toString() {
    return 'AudioItem(id: $id, mediaId: $mediaId, kind: $kind, name: $name, anchor: $anchor, mediaDurationUs: $mediaDurationUs, sourceInUs: $sourceInUs, sourceOutUs: $sourceOutUs, laneIndex: $laneIndex, volume: $volume, fadeInUs: $fadeInUs, fadeOutUs: $fadeOutUs, speed: $speed, loop: $loop, needsReview: $needsReview)';
}


}

/// @nodoc
abstract mixin class _$AudioItemCopyWith<$Res> implements $AudioItemCopyWith<$Res> {
  factory _$AudioItemCopyWith(_AudioItem value, $Res Function(_AudioItem) _then) = __$AudioItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String mediaId, AudioKind kind, String name, Anchor anchor, int mediaDurationUs, int sourceInUs, int sourceOutUs, int laneIndex, double volume, int fadeInUs, int fadeOutUs, double speed, bool loop, bool needsReview
});


@override $AnchorCopyWith<$Res> get anchor;

}
/// @nodoc
class __$AudioItemCopyWithImpl<$Res>
    implements _$AudioItemCopyWith<$Res> {
  __$AudioItemCopyWithImpl(this._self, this._then);

  final _AudioItem _self;
  final $Res Function(_AudioItem) _then;

/// Create a copy of AudioItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? mediaId = null,Object? kind = null,Object? name = null,Object? anchor = null,Object? mediaDurationUs = null,Object? sourceInUs = null,Object? sourceOutUs = null,Object? laneIndex = null,Object? volume = null,Object? fadeInUs = null,Object? fadeOutUs = null,Object? speed = null,Object? loop = null,Object? needsReview = null,}) {
  return _then(_AudioItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,mediaId: null == mediaId ? _self.mediaId : mediaId // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as AudioKind,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,anchor: null == anchor ? _self.anchor : anchor // ignore: cast_nullable_to_non_nullable
as Anchor,mediaDurationUs: null == mediaDurationUs ? _self.mediaDurationUs : mediaDurationUs // ignore: cast_nullable_to_non_nullable
as int,sourceInUs: null == sourceInUs ? _self.sourceInUs : sourceInUs // ignore: cast_nullable_to_non_nullable
as int,sourceOutUs: null == sourceOutUs ? _self.sourceOutUs : sourceOutUs // ignore: cast_nullable_to_non_nullable
as int,laneIndex: null == laneIndex ? _self.laneIndex : laneIndex // ignore: cast_nullable_to_non_nullable
as int,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,fadeInUs: null == fadeInUs ? _self.fadeInUs : fadeInUs // ignore: cast_nullable_to_non_nullable
as int,fadeOutUs: null == fadeOutUs ? _self.fadeOutUs : fadeOutUs // ignore: cast_nullable_to_non_nullable
as int,speed: null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double,loop: null == loop ? _self.loop : loop // ignore: cast_nullable_to_non_nullable
as bool,needsReview: null == needsReview ? _self.needsReview : needsReview // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of AudioItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AnchorCopyWith<$Res> get anchor {
  
  return $AnchorCopyWith<$Res>(_self.anchor, (value) {
    return _then(_self.copyWith(anchor: value));
  });
}
}


/// @nodoc
mixin _$AudioMix {

 bool get originalSoundEnabled; double get originalLevel; double get addedLevel;
/// Create a copy of AudioMix
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AudioMixCopyWith<AudioMix> get copyWith => _$AudioMixCopyWithImpl<AudioMix>(this as AudioMix, _$identity);

  /// Serializes this AudioMix to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AudioMix;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AudioMix&&(identical(other.originalSoundEnabled, _this.originalSoundEnabled) || other.originalSoundEnabled == _this.originalSoundEnabled)&&(identical(other.originalLevel, _this.originalLevel) || other.originalLevel == _this.originalLevel)&&(identical(other.addedLevel, _this.addedLevel) || other.addedLevel == _this.addedLevel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AudioMix;
  return Object.hash(runtimeType,_this.originalSoundEnabled,_this.originalLevel,_this.addedLevel);
}

@override
String toString() {
  final _this = this as AudioMix;
  return 'AudioMix(originalSoundEnabled: ${_this.originalSoundEnabled}, originalLevel: ${_this.originalLevel}, addedLevel: ${_this.addedLevel})';
}


}

/// @nodoc
abstract mixin class $AudioMixCopyWith<$Res>  {
  factory $AudioMixCopyWith(AudioMix value, $Res Function(AudioMix) _then) = _$AudioMixCopyWithImpl;
@useResult
$Res call({
 bool originalSoundEnabled, double originalLevel, double addedLevel
});




}
/// @nodoc
class _$AudioMixCopyWithImpl<$Res>
    implements $AudioMixCopyWith<$Res> {
  _$AudioMixCopyWithImpl(this._self, this._then);

  final AudioMix _self;
  final $Res Function(AudioMix) _then;

/// Create a copy of AudioMix
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? originalSoundEnabled = null,Object? originalLevel = null,Object? addedLevel = null,}) {
  return _then(AudioMix(
originalSoundEnabled: null == originalSoundEnabled ? _self.originalSoundEnabled : originalSoundEnabled // ignore: cast_nullable_to_non_nullable
as bool,originalLevel: null == originalLevel ? _self.originalLevel : originalLevel // ignore: cast_nullable_to_non_nullable
as double,addedLevel: null == addedLevel ? _self.addedLevel : addedLevel // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [AudioMix].
extension AudioMixPatterns on AudioMix {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AudioMix value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AudioMix() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AudioMix value)  $default,){
final _that = this;
switch (_that) {
case _AudioMix():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AudioMix value)?  $default,){
final _that = this;
switch (_that) {
case _AudioMix() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool originalSoundEnabled,  double originalLevel,  double addedLevel)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AudioMix() when $default != null:
return $default(_that.originalSoundEnabled,_that.originalLevel,_that.addedLevel);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool originalSoundEnabled,  double originalLevel,  double addedLevel)  $default,) {final _that = this;
switch (_that) {
case _AudioMix():
return $default(_that.originalSoundEnabled,_that.originalLevel,_that.addedLevel);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool originalSoundEnabled,  double originalLevel,  double addedLevel)?  $default,) {final _that = this;
switch (_that) {
case _AudioMix() when $default != null:
return $default(_that.originalSoundEnabled,_that.originalLevel,_that.addedLevel);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AudioMix implements AudioMix {
  const _AudioMix({this.originalSoundEnabled = true, this.originalLevel = 1.0, this.addedLevel = 1.0});
  factory _AudioMix.fromJson(Map<String, dynamic> json) => _$AudioMixFromJson(json);

@override@JsonKey() final  bool originalSoundEnabled;
@override@JsonKey() final  double originalLevel;
@override@JsonKey() final  double addedLevel;

/// Create a copy of AudioMix
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AudioMixCopyWith<_AudioMix> get copyWith => __$AudioMixCopyWithImpl<_AudioMix>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AudioMixToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AudioMix&&(identical(other.originalSoundEnabled, originalSoundEnabled) || other.originalSoundEnabled == originalSoundEnabled)&&(identical(other.originalLevel, originalLevel) || other.originalLevel == originalLevel)&&(identical(other.addedLevel, addedLevel) || other.addedLevel == addedLevel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,originalSoundEnabled,originalLevel,addedLevel);
}

@override
String toString() {
    return 'AudioMix(originalSoundEnabled: $originalSoundEnabled, originalLevel: $originalLevel, addedLevel: $addedLevel)';
}


}

/// @nodoc
abstract mixin class _$AudioMixCopyWith<$Res> implements $AudioMixCopyWith<$Res> {
  factory _$AudioMixCopyWith(_AudioMix value, $Res Function(_AudioMix) _then) = __$AudioMixCopyWithImpl;
@override @useResult
$Res call({
 bool originalSoundEnabled, double originalLevel, double addedLevel
});




}
/// @nodoc
class __$AudioMixCopyWithImpl<$Res>
    implements _$AudioMixCopyWith<$Res> {
  __$AudioMixCopyWithImpl(this._self, this._then);

  final _AudioMix _self;
  final $Res Function(_AudioMix) _then;

/// Create a copy of AudioMix
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? originalSoundEnabled = null,Object? originalLevel = null,Object? addedLevel = null,}) {
  return _then(_AudioMix(
originalSoundEnabled: null == originalSoundEnabled ? _self.originalSoundEnabled : originalSoundEnabled // ignore: cast_nullable_to_non_nullable
as bool,originalLevel: null == originalLevel ? _self.originalLevel : originalLevel // ignore: cast_nullable_to_non_nullable
as double,addedLevel: null == addedLevel ? _self.addedLevel : addedLevel // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$Timeline {

 List<VideoClip> get videoClips; List<Transition> get transitions; List<TextItem> get textItems; CaptionTrack get captionTrack; List<AudioItem> get audioItems; AudioMix get audioMix;
/// Create a copy of Timeline
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TimelineCopyWith<Timeline> get copyWith => _$TimelineCopyWithImpl<Timeline>(this as Timeline, _$identity);

  /// Serializes this Timeline to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Timeline;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Timeline&&const DeepCollectionEquality().equals(other.videoClips, _this.videoClips)&&const DeepCollectionEquality().equals(other.transitions, _this.transitions)&&const DeepCollectionEquality().equals(other.textItems, _this.textItems)&&(identical(other.captionTrack, _this.captionTrack) || other.captionTrack == _this.captionTrack)&&const DeepCollectionEquality().equals(other.audioItems, _this.audioItems)&&(identical(other.audioMix, _this.audioMix) || other.audioMix == _this.audioMix));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Timeline;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.videoClips),const DeepCollectionEquality().hash(_this.transitions),const DeepCollectionEquality().hash(_this.textItems),_this.captionTrack,const DeepCollectionEquality().hash(_this.audioItems),_this.audioMix);
}

@override
String toString() {
  final _this = this as Timeline;
  return 'Timeline(videoClips: ${_this.videoClips}, transitions: ${_this.transitions}, textItems: ${_this.textItems}, captionTrack: ${_this.captionTrack}, audioItems: ${_this.audioItems}, audioMix: ${_this.audioMix})';
}


}

/// @nodoc
abstract mixin class $TimelineCopyWith<$Res>  {
  factory $TimelineCopyWith(Timeline value, $Res Function(Timeline) _then) = _$TimelineCopyWithImpl;
@useResult
$Res call({
 List<VideoClip> videoClips, List<Transition> transitions, List<TextItem> textItems, CaptionTrack captionTrack, List<AudioItem> audioItems, AudioMix audioMix
});


$CaptionTrackCopyWith<$Res> get captionTrack;$AudioMixCopyWith<$Res> get audioMix;

}
/// @nodoc
class _$TimelineCopyWithImpl<$Res>
    implements $TimelineCopyWith<$Res> {
  _$TimelineCopyWithImpl(this._self, this._then);

  final Timeline _self;
  final $Res Function(Timeline) _then;

/// Create a copy of Timeline
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? videoClips = null,Object? transitions = null,Object? textItems = null,Object? captionTrack = null,Object? audioItems = null,Object? audioMix = null,}) {
  return _then(Timeline(
videoClips: null == videoClips ? _self.videoClips : videoClips // ignore: cast_nullable_to_non_nullable
as List<VideoClip>,transitions: null == transitions ? _self.transitions : transitions // ignore: cast_nullable_to_non_nullable
as List<Transition>,textItems: null == textItems ? _self.textItems : textItems // ignore: cast_nullable_to_non_nullable
as List<TextItem>,captionTrack: null == captionTrack ? _self.captionTrack : captionTrack // ignore: cast_nullable_to_non_nullable
as CaptionTrack,audioItems: null == audioItems ? _self.audioItems : audioItems // ignore: cast_nullable_to_non_nullable
as List<AudioItem>,audioMix: null == audioMix ? _self.audioMix : audioMix // ignore: cast_nullable_to_non_nullable
as AudioMix,
  ));
}
/// Create a copy of Timeline
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CaptionTrackCopyWith<$Res> get captionTrack {
  
  return $CaptionTrackCopyWith<$Res>(_self.captionTrack, (value) {
    return _then(_self.copyWith(captionTrack: value));
  });
}/// Create a copy of Timeline
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AudioMixCopyWith<$Res> get audioMix {
  
  return $AudioMixCopyWith<$Res>(_self.audioMix, (value) {
    return _then(_self.copyWith(audioMix: value));
  });
}
}


/// Adds pattern-matching-related methods to [Timeline].
extension TimelinePatterns on Timeline {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Timeline value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Timeline() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Timeline value)  $default,){
final _that = this;
switch (_that) {
case _Timeline():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Timeline value)?  $default,){
final _that = this;
switch (_that) {
case _Timeline() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<VideoClip> videoClips,  List<Transition> transitions,  List<TextItem> textItems,  CaptionTrack captionTrack,  List<AudioItem> audioItems,  AudioMix audioMix)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Timeline() when $default != null:
return $default(_that.videoClips,_that.transitions,_that.textItems,_that.captionTrack,_that.audioItems,_that.audioMix);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<VideoClip> videoClips,  List<Transition> transitions,  List<TextItem> textItems,  CaptionTrack captionTrack,  List<AudioItem> audioItems,  AudioMix audioMix)  $default,) {final _that = this;
switch (_that) {
case _Timeline():
return $default(_that.videoClips,_that.transitions,_that.textItems,_that.captionTrack,_that.audioItems,_that.audioMix);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<VideoClip> videoClips,  List<Transition> transitions,  List<TextItem> textItems,  CaptionTrack captionTrack,  List<AudioItem> audioItems,  AudioMix audioMix)?  $default,) {final _that = this;
switch (_that) {
case _Timeline() when $default != null:
return $default(_that.videoClips,_that.transitions,_that.textItems,_that.captionTrack,_that.audioItems,_that.audioMix);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Timeline extends Timeline {
  const _Timeline({ List<VideoClip> videoClips = const <VideoClip>[],  List<Transition> transitions = const <Transition>[],  List<TextItem> textItems = const <TextItem>[], this.captionTrack = const CaptionTrack(),  List<AudioItem> audioItems = const <AudioItem>[], this.audioMix = const AudioMix()}): _videoClips = videoClips,_transitions = transitions,_textItems = textItems,_audioItems = audioItems,super._();
  factory _Timeline.fromJson(Map<String, dynamic> json) => _$TimelineFromJson(json);

 final  List<VideoClip> _videoClips;
@override@JsonKey() List<VideoClip> get videoClips {
  if (_videoClips is EqualUnmodifiableListView) return _videoClips;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_videoClips);
}

 final  List<Transition> _transitions;
@override@JsonKey() List<Transition> get transitions {
  if (_transitions is EqualUnmodifiableListView) return _transitions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_transitions);
}

 final  List<TextItem> _textItems;
@override@JsonKey() List<TextItem> get textItems {
  if (_textItems is EqualUnmodifiableListView) return _textItems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_textItems);
}

@override@JsonKey() final  CaptionTrack captionTrack;
 final  List<AudioItem> _audioItems;
@override@JsonKey() List<AudioItem> get audioItems {
  if (_audioItems is EqualUnmodifiableListView) return _audioItems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_audioItems);
}

@override@JsonKey() final  AudioMix audioMix;

/// Create a copy of Timeline
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TimelineCopyWith<_Timeline> get copyWith => __$TimelineCopyWithImpl<_Timeline>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TimelineToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Timeline&&const DeepCollectionEquality().equals(other.videoClips, _videoClips)&&const DeepCollectionEquality().equals(other.transitions, _transitions)&&const DeepCollectionEquality().equals(other.textItems, _textItems)&&(identical(other.captionTrack, captionTrack) || other.captionTrack == captionTrack)&&const DeepCollectionEquality().equals(other.audioItems, _audioItems)&&(identical(other.audioMix, audioMix) || other.audioMix == audioMix));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_videoClips),const DeepCollectionEquality().hash(_transitions),const DeepCollectionEquality().hash(_textItems),captionTrack,const DeepCollectionEquality().hash(_audioItems),audioMix);
}

@override
String toString() {
    return 'Timeline(videoClips: $videoClips, transitions: $transitions, textItems: $textItems, captionTrack: $captionTrack, audioItems: $audioItems, audioMix: $audioMix)';
}


}

/// @nodoc
abstract mixin class _$TimelineCopyWith<$Res> implements $TimelineCopyWith<$Res> {
  factory _$TimelineCopyWith(_Timeline value, $Res Function(_Timeline) _then) = __$TimelineCopyWithImpl;
@override @useResult
$Res call({
 List<VideoClip> videoClips, List<Transition> transitions, List<TextItem> textItems, CaptionTrack captionTrack, List<AudioItem> audioItems, AudioMix audioMix
});


@override $CaptionTrackCopyWith<$Res> get captionTrack;@override $AudioMixCopyWith<$Res> get audioMix;

}
/// @nodoc
class __$TimelineCopyWithImpl<$Res>
    implements _$TimelineCopyWith<$Res> {
  __$TimelineCopyWithImpl(this._self, this._then);

  final _Timeline _self;
  final $Res Function(_Timeline) _then;

/// Create a copy of Timeline
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? videoClips = null,Object? transitions = null,Object? textItems = null,Object? captionTrack = null,Object? audioItems = null,Object? audioMix = null,}) {
  return _then(_Timeline(
videoClips: null == videoClips ? _self._videoClips : videoClips // ignore: cast_nullable_to_non_nullable
as List<VideoClip>,transitions: null == transitions ? _self._transitions : transitions // ignore: cast_nullable_to_non_nullable
as List<Transition>,textItems: null == textItems ? _self._textItems : textItems // ignore: cast_nullable_to_non_nullable
as List<TextItem>,captionTrack: null == captionTrack ? _self.captionTrack : captionTrack // ignore: cast_nullable_to_non_nullable
as CaptionTrack,audioItems: null == audioItems ? _self._audioItems : audioItems // ignore: cast_nullable_to_non_nullable
as List<AudioItem>,audioMix: null == audioMix ? _self.audioMix : audioMix // ignore: cast_nullable_to_non_nullable
as AudioMix,
  ));
}

/// Create a copy of Timeline
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CaptionTrackCopyWith<$Res> get captionTrack {
  
  return $CaptionTrackCopyWith<$Res>(_self.captionTrack, (value) {
    return _then(_self.copyWith(captionTrack: value));
  });
}/// Create a copy of Timeline
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AudioMixCopyWith<$Res> get audioMix {
  
  return $AudioMixCopyWith<$Res>(_self.audioMix, (value) {
    return _then(_self.copyWith(audioMix: value));
  });
}
}

// dart format on
