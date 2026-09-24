// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'composition.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ResolvedClip {

 String get clipId; String get mediaId; MediaKind get kind; int get startUs; int get endUs; int get sourceInUs; int get sourceOutUs; double get speed;/// Final gain for the clip's own sound, including the original sound
/// switch and level. Zero when muted or extracted.
 double get volume;/// Audio ramps, equal to the transitions on either side, so the sound
/// crossfades with the picture.
 int get audioFadeInUs; int get audioFadeOutUs; ClipFraming get framing;
/// Create a copy of ResolvedClip
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResolvedClipCopyWith<ResolvedClip> get copyWith => _$ResolvedClipCopyWithImpl<ResolvedClip>(this as ResolvedClip, _$identity);

  /// Serializes this ResolvedClip to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ResolvedClip;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResolvedClip&&(identical(other.clipId, _this.clipId) || other.clipId == _this.clipId)&&(identical(other.mediaId, _this.mediaId) || other.mediaId == _this.mediaId)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.startUs, _this.startUs) || other.startUs == _this.startUs)&&(identical(other.endUs, _this.endUs) || other.endUs == _this.endUs)&&(identical(other.sourceInUs, _this.sourceInUs) || other.sourceInUs == _this.sourceInUs)&&(identical(other.sourceOutUs, _this.sourceOutUs) || other.sourceOutUs == _this.sourceOutUs)&&(identical(other.speed, _this.speed) || other.speed == _this.speed)&&(identical(other.volume, _this.volume) || other.volume == _this.volume)&&(identical(other.audioFadeInUs, _this.audioFadeInUs) || other.audioFadeInUs == _this.audioFadeInUs)&&(identical(other.audioFadeOutUs, _this.audioFadeOutUs) || other.audioFadeOutUs == _this.audioFadeOutUs)&&(identical(other.framing, _this.framing) || other.framing == _this.framing));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ResolvedClip;
  return Object.hash(runtimeType,_this.clipId,_this.mediaId,_this.kind,_this.startUs,_this.endUs,_this.sourceInUs,_this.sourceOutUs,_this.speed,_this.volume,_this.audioFadeInUs,_this.audioFadeOutUs,_this.framing);
}

@override
String toString() {
  final _this = this as ResolvedClip;
  return 'ResolvedClip(clipId: ${_this.clipId}, mediaId: ${_this.mediaId}, kind: ${_this.kind}, startUs: ${_this.startUs}, endUs: ${_this.endUs}, sourceInUs: ${_this.sourceInUs}, sourceOutUs: ${_this.sourceOutUs}, speed: ${_this.speed}, volume: ${_this.volume}, audioFadeInUs: ${_this.audioFadeInUs}, audioFadeOutUs: ${_this.audioFadeOutUs}, framing: ${_this.framing})';
}


}

/// @nodoc
abstract mixin class $ResolvedClipCopyWith<$Res>  {
  factory $ResolvedClipCopyWith(ResolvedClip value, $Res Function(ResolvedClip) _then) = _$ResolvedClipCopyWithImpl;
@useResult
$Res call({
 String clipId, String mediaId, MediaKind kind, int startUs, int endUs, int sourceInUs, int sourceOutUs, double speed, double volume, int audioFadeInUs, int audioFadeOutUs, ClipFraming framing
});


$ClipFramingCopyWith<$Res> get framing;

}
/// @nodoc
class _$ResolvedClipCopyWithImpl<$Res>
    implements $ResolvedClipCopyWith<$Res> {
  _$ResolvedClipCopyWithImpl(this._self, this._then);

  final ResolvedClip _self;
  final $Res Function(ResolvedClip) _then;

/// Create a copy of ResolvedClip
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? clipId = null,Object? mediaId = null,Object? kind = null,Object? startUs = null,Object? endUs = null,Object? sourceInUs = null,Object? sourceOutUs = null,Object? speed = null,Object? volume = null,Object? audioFadeInUs = null,Object? audioFadeOutUs = null,Object? framing = null,}) {
  return _then(ResolvedClip(
clipId: null == clipId ? _self.clipId : clipId // ignore: cast_nullable_to_non_nullable
as String,mediaId: null == mediaId ? _self.mediaId : mediaId // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as MediaKind,startUs: null == startUs ? _self.startUs : startUs // ignore: cast_nullable_to_non_nullable
as int,endUs: null == endUs ? _self.endUs : endUs // ignore: cast_nullable_to_non_nullable
as int,sourceInUs: null == sourceInUs ? _self.sourceInUs : sourceInUs // ignore: cast_nullable_to_non_nullable
as int,sourceOutUs: null == sourceOutUs ? _self.sourceOutUs : sourceOutUs // ignore: cast_nullable_to_non_nullable
as int,speed: null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,audioFadeInUs: null == audioFadeInUs ? _self.audioFadeInUs : audioFadeInUs // ignore: cast_nullable_to_non_nullable
as int,audioFadeOutUs: null == audioFadeOutUs ? _self.audioFadeOutUs : audioFadeOutUs // ignore: cast_nullable_to_non_nullable
as int,framing: null == framing ? _self.framing : framing // ignore: cast_nullable_to_non_nullable
as ClipFraming,
  ));
}
/// Create a copy of ResolvedClip
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ClipFramingCopyWith<$Res> get framing {
  
  return $ClipFramingCopyWith<$Res>(_self.framing, (value) {
    return _then(_self.copyWith(framing: value));
  });
}
}


/// Adds pattern-matching-related methods to [ResolvedClip].
extension ResolvedClipPatterns on ResolvedClip {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResolvedClip value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResolvedClip() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResolvedClip value)  $default,){
final _that = this;
switch (_that) {
case _ResolvedClip():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResolvedClip value)?  $default,){
final _that = this;
switch (_that) {
case _ResolvedClip() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String clipId,  String mediaId,  MediaKind kind,  int startUs,  int endUs,  int sourceInUs,  int sourceOutUs,  double speed,  double volume,  int audioFadeInUs,  int audioFadeOutUs,  ClipFraming framing)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResolvedClip() when $default != null:
return $default(_that.clipId,_that.mediaId,_that.kind,_that.startUs,_that.endUs,_that.sourceInUs,_that.sourceOutUs,_that.speed,_that.volume,_that.audioFadeInUs,_that.audioFadeOutUs,_that.framing);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String clipId,  String mediaId,  MediaKind kind,  int startUs,  int endUs,  int sourceInUs,  int sourceOutUs,  double speed,  double volume,  int audioFadeInUs,  int audioFadeOutUs,  ClipFraming framing)  $default,) {final _that = this;
switch (_that) {
case _ResolvedClip():
return $default(_that.clipId,_that.mediaId,_that.kind,_that.startUs,_that.endUs,_that.sourceInUs,_that.sourceOutUs,_that.speed,_that.volume,_that.audioFadeInUs,_that.audioFadeOutUs,_that.framing);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String clipId,  String mediaId,  MediaKind kind,  int startUs,  int endUs,  int sourceInUs,  int sourceOutUs,  double speed,  double volume,  int audioFadeInUs,  int audioFadeOutUs,  ClipFraming framing)?  $default,) {final _that = this;
switch (_that) {
case _ResolvedClip() when $default != null:
return $default(_that.clipId,_that.mediaId,_that.kind,_that.startUs,_that.endUs,_that.sourceInUs,_that.sourceOutUs,_that.speed,_that.volume,_that.audioFadeInUs,_that.audioFadeOutUs,_that.framing);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ResolvedClip implements ResolvedClip {
  const _ResolvedClip({required this.clipId, required this.mediaId, required this.kind, required this.startUs, required this.endUs, required this.sourceInUs, required this.sourceOutUs, required this.speed, required this.volume, required this.audioFadeInUs, required this.audioFadeOutUs, required this.framing});
  factory _ResolvedClip.fromJson(Map<String, dynamic> json) => _$ResolvedClipFromJson(json);

@override final  String clipId;
@override final  String mediaId;
@override final  MediaKind kind;
@override final  int startUs;
@override final  int endUs;
@override final  int sourceInUs;
@override final  int sourceOutUs;
@override final  double speed;
/// Final gain for the clip's own sound, including the original sound
/// switch and level. Zero when muted or extracted.
@override final  double volume;
/// Audio ramps, equal to the transitions on either side, so the sound
/// crossfades with the picture.
@override final  int audioFadeInUs;
@override final  int audioFadeOutUs;
@override final  ClipFraming framing;

/// Create a copy of ResolvedClip
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResolvedClipCopyWith<_ResolvedClip> get copyWith => __$ResolvedClipCopyWithImpl<_ResolvedClip>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ResolvedClipToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResolvedClip&&(identical(other.clipId, clipId) || other.clipId == clipId)&&(identical(other.mediaId, mediaId) || other.mediaId == mediaId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.startUs, startUs) || other.startUs == startUs)&&(identical(other.endUs, endUs) || other.endUs == endUs)&&(identical(other.sourceInUs, sourceInUs) || other.sourceInUs == sourceInUs)&&(identical(other.sourceOutUs, sourceOutUs) || other.sourceOutUs == sourceOutUs)&&(identical(other.speed, speed) || other.speed == speed)&&(identical(other.volume, volume) || other.volume == volume)&&(identical(other.audioFadeInUs, audioFadeInUs) || other.audioFadeInUs == audioFadeInUs)&&(identical(other.audioFadeOutUs, audioFadeOutUs) || other.audioFadeOutUs == audioFadeOutUs)&&(identical(other.framing, framing) || other.framing == framing));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,clipId,mediaId,kind,startUs,endUs,sourceInUs,sourceOutUs,speed,volume,audioFadeInUs,audioFadeOutUs,framing);
}

@override
String toString() {
    return 'ResolvedClip(clipId: $clipId, mediaId: $mediaId, kind: $kind, startUs: $startUs, endUs: $endUs, sourceInUs: $sourceInUs, sourceOutUs: $sourceOutUs, speed: $speed, volume: $volume, audioFadeInUs: $audioFadeInUs, audioFadeOutUs: $audioFadeOutUs, framing: $framing)';
}


}

/// @nodoc
abstract mixin class _$ResolvedClipCopyWith<$Res> implements $ResolvedClipCopyWith<$Res> {
  factory _$ResolvedClipCopyWith(_ResolvedClip value, $Res Function(_ResolvedClip) _then) = __$ResolvedClipCopyWithImpl;
@override @useResult
$Res call({
 String clipId, String mediaId, MediaKind kind, int startUs, int endUs, int sourceInUs, int sourceOutUs, double speed, double volume, int audioFadeInUs, int audioFadeOutUs, ClipFraming framing
});


@override $ClipFramingCopyWith<$Res> get framing;

}
/// @nodoc
class __$ResolvedClipCopyWithImpl<$Res>
    implements _$ResolvedClipCopyWith<$Res> {
  __$ResolvedClipCopyWithImpl(this._self, this._then);

  final _ResolvedClip _self;
  final $Res Function(_ResolvedClip) _then;

/// Create a copy of ResolvedClip
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? clipId = null,Object? mediaId = null,Object? kind = null,Object? startUs = null,Object? endUs = null,Object? sourceInUs = null,Object? sourceOutUs = null,Object? speed = null,Object? volume = null,Object? audioFadeInUs = null,Object? audioFadeOutUs = null,Object? framing = null,}) {
  return _then(_ResolvedClip(
clipId: null == clipId ? _self.clipId : clipId // ignore: cast_nullable_to_non_nullable
as String,mediaId: null == mediaId ? _self.mediaId : mediaId // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as MediaKind,startUs: null == startUs ? _self.startUs : startUs // ignore: cast_nullable_to_non_nullable
as int,endUs: null == endUs ? _self.endUs : endUs // ignore: cast_nullable_to_non_nullable
as int,sourceInUs: null == sourceInUs ? _self.sourceInUs : sourceInUs // ignore: cast_nullable_to_non_nullable
as int,sourceOutUs: null == sourceOutUs ? _self.sourceOutUs : sourceOutUs // ignore: cast_nullable_to_non_nullable
as int,speed: null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,audioFadeInUs: null == audioFadeInUs ? _self.audioFadeInUs : audioFadeInUs // ignore: cast_nullable_to_non_nullable
as int,audioFadeOutUs: null == audioFadeOutUs ? _self.audioFadeOutUs : audioFadeOutUs // ignore: cast_nullable_to_non_nullable
as int,framing: null == framing ? _self.framing : framing // ignore: cast_nullable_to_non_nullable
as ClipFraming,
  ));
}

/// Create a copy of ResolvedClip
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
mixin _$ResolvedTransition {

 TransitionType get type; String get fromClipId; String get toClipId; int get startUs; int get durationUs; Map<String, double> get params;
/// Create a copy of ResolvedTransition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResolvedTransitionCopyWith<ResolvedTransition> get copyWith => _$ResolvedTransitionCopyWithImpl<ResolvedTransition>(this as ResolvedTransition, _$identity);

  /// Serializes this ResolvedTransition to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ResolvedTransition;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResolvedTransition&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.fromClipId, _this.fromClipId) || other.fromClipId == _this.fromClipId)&&(identical(other.toClipId, _this.toClipId) || other.toClipId == _this.toClipId)&&(identical(other.startUs, _this.startUs) || other.startUs == _this.startUs)&&(identical(other.durationUs, _this.durationUs) || other.durationUs == _this.durationUs)&&const DeepCollectionEquality().equals(other.params, _this.params));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ResolvedTransition;
  return Object.hash(runtimeType,_this.type,_this.fromClipId,_this.toClipId,_this.startUs,_this.durationUs,const DeepCollectionEquality().hash(_this.params));
}

@override
String toString() {
  final _this = this as ResolvedTransition;
  return 'ResolvedTransition(type: ${_this.type}, fromClipId: ${_this.fromClipId}, toClipId: ${_this.toClipId}, startUs: ${_this.startUs}, durationUs: ${_this.durationUs}, params: ${_this.params})';
}


}

/// @nodoc
abstract mixin class $ResolvedTransitionCopyWith<$Res>  {
  factory $ResolvedTransitionCopyWith(ResolvedTransition value, $Res Function(ResolvedTransition) _then) = _$ResolvedTransitionCopyWithImpl;
@useResult
$Res call({
 TransitionType type, String fromClipId, String toClipId, int startUs, int durationUs, Map<String, double> params
});




}
/// @nodoc
class _$ResolvedTransitionCopyWithImpl<$Res>
    implements $ResolvedTransitionCopyWith<$Res> {
  _$ResolvedTransitionCopyWithImpl(this._self, this._then);

  final ResolvedTransition _self;
  final $Res Function(ResolvedTransition) _then;

/// Create a copy of ResolvedTransition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? fromClipId = null,Object? toClipId = null,Object? startUs = null,Object? durationUs = null,Object? params = null,}) {
  return _then(ResolvedTransition(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TransitionType,fromClipId: null == fromClipId ? _self.fromClipId : fromClipId // ignore: cast_nullable_to_non_nullable
as String,toClipId: null == toClipId ? _self.toClipId : toClipId // ignore: cast_nullable_to_non_nullable
as String,startUs: null == startUs ? _self.startUs : startUs // ignore: cast_nullable_to_non_nullable
as int,durationUs: null == durationUs ? _self.durationUs : durationUs // ignore: cast_nullable_to_non_nullable
as int,params: null == params ? _self.params : params // ignore: cast_nullable_to_non_nullable
as Map<String, double>,
  ));
}

}


/// Adds pattern-matching-related methods to [ResolvedTransition].
extension ResolvedTransitionPatterns on ResolvedTransition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResolvedTransition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResolvedTransition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResolvedTransition value)  $default,){
final _that = this;
switch (_that) {
case _ResolvedTransition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResolvedTransition value)?  $default,){
final _that = this;
switch (_that) {
case _ResolvedTransition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TransitionType type,  String fromClipId,  String toClipId,  int startUs,  int durationUs,  Map<String, double> params)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResolvedTransition() when $default != null:
return $default(_that.type,_that.fromClipId,_that.toClipId,_that.startUs,_that.durationUs,_that.params);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TransitionType type,  String fromClipId,  String toClipId,  int startUs,  int durationUs,  Map<String, double> params)  $default,) {final _that = this;
switch (_that) {
case _ResolvedTransition():
return $default(_that.type,_that.fromClipId,_that.toClipId,_that.startUs,_that.durationUs,_that.params);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TransitionType type,  String fromClipId,  String toClipId,  int startUs,  int durationUs,  Map<String, double> params)?  $default,) {final _that = this;
switch (_that) {
case _ResolvedTransition() when $default != null:
return $default(_that.type,_that.fromClipId,_that.toClipId,_that.startUs,_that.durationUs,_that.params);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ResolvedTransition implements ResolvedTransition {
  const _ResolvedTransition({required this.type, required this.fromClipId, required this.toClipId, required this.startUs, required this.durationUs,  Map<String, double> params = const <String, double>{}}): _params = params;
  factory _ResolvedTransition.fromJson(Map<String, dynamic> json) => _$ResolvedTransitionFromJson(json);

@override final  TransitionType type;
@override final  String fromClipId;
@override final  String toClipId;
@override final  int startUs;
@override final  int durationUs;
 final  Map<String, double> _params;
@override@JsonKey() Map<String, double> get params {
  if (_params is EqualUnmodifiableMapView) return _params;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_params);
}


/// Create a copy of ResolvedTransition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResolvedTransitionCopyWith<_ResolvedTransition> get copyWith => __$ResolvedTransitionCopyWithImpl<_ResolvedTransition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ResolvedTransitionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResolvedTransition&&(identical(other.type, type) || other.type == type)&&(identical(other.fromClipId, fromClipId) || other.fromClipId == fromClipId)&&(identical(other.toClipId, toClipId) || other.toClipId == toClipId)&&(identical(other.startUs, startUs) || other.startUs == startUs)&&(identical(other.durationUs, durationUs) || other.durationUs == durationUs)&&const DeepCollectionEquality().equals(other.params, _params));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,type,fromClipId,toClipId,startUs,durationUs,const DeepCollectionEquality().hash(_params));
}

@override
String toString() {
    return 'ResolvedTransition(type: $type, fromClipId: $fromClipId, toClipId: $toClipId, startUs: $startUs, durationUs: $durationUs, params: $params)';
}


}

/// @nodoc
abstract mixin class _$ResolvedTransitionCopyWith<$Res> implements $ResolvedTransitionCopyWith<$Res> {
  factory _$ResolvedTransitionCopyWith(_ResolvedTransition value, $Res Function(_ResolvedTransition) _then) = __$ResolvedTransitionCopyWithImpl;
@override @useResult
$Res call({
 TransitionType type, String fromClipId, String toClipId, int startUs, int durationUs, Map<String, double> params
});




}
/// @nodoc
class __$ResolvedTransitionCopyWithImpl<$Res>
    implements _$ResolvedTransitionCopyWith<$Res> {
  __$ResolvedTransitionCopyWithImpl(this._self, this._then);

  final _ResolvedTransition _self;
  final $Res Function(_ResolvedTransition) _then;

/// Create a copy of ResolvedTransition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? fromClipId = null,Object? toClipId = null,Object? startUs = null,Object? durationUs = null,Object? params = null,}) {
  return _then(_ResolvedTransition(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TransitionType,fromClipId: null == fromClipId ? _self.fromClipId : fromClipId // ignore: cast_nullable_to_non_nullable
as String,toClipId: null == toClipId ? _self.toClipId : toClipId // ignore: cast_nullable_to_non_nullable
as String,startUs: null == startUs ? _self.startUs : startUs // ignore: cast_nullable_to_non_nullable
as int,durationUs: null == durationUs ? _self.durationUs : durationUs // ignore: cast_nullable_to_non_nullable
as int,params: null == params ? _self._params : params // ignore: cast_nullable_to_non_nullable
as Map<String, double>,
  ));
}


}


/// @nodoc
mixin _$ResolvedText {

 String get id; String get text; int get startUs; int get endUs; int get laneIndex; TextStyleSpec get style; ItemTransform get transform; TextAnimation get animationIn; TextAnimation get animationOut;
/// Create a copy of ResolvedText
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResolvedTextCopyWith<ResolvedText> get copyWith => _$ResolvedTextCopyWithImpl<ResolvedText>(this as ResolvedText, _$identity);

  /// Serializes this ResolvedText to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ResolvedText;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResolvedText&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.text, _this.text) || other.text == _this.text)&&(identical(other.startUs, _this.startUs) || other.startUs == _this.startUs)&&(identical(other.endUs, _this.endUs) || other.endUs == _this.endUs)&&(identical(other.laneIndex, _this.laneIndex) || other.laneIndex == _this.laneIndex)&&(identical(other.style, _this.style) || other.style == _this.style)&&(identical(other.transform, _this.transform) || other.transform == _this.transform)&&(identical(other.animationIn, _this.animationIn) || other.animationIn == _this.animationIn)&&(identical(other.animationOut, _this.animationOut) || other.animationOut == _this.animationOut));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ResolvedText;
  return Object.hash(runtimeType,_this.id,_this.text,_this.startUs,_this.endUs,_this.laneIndex,_this.style,_this.transform,_this.animationIn,_this.animationOut);
}

@override
String toString() {
  final _this = this as ResolvedText;
  return 'ResolvedText(id: ${_this.id}, text: ${_this.text}, startUs: ${_this.startUs}, endUs: ${_this.endUs}, laneIndex: ${_this.laneIndex}, style: ${_this.style}, transform: ${_this.transform}, animationIn: ${_this.animationIn}, animationOut: ${_this.animationOut})';
}


}

/// @nodoc
abstract mixin class $ResolvedTextCopyWith<$Res>  {
  factory $ResolvedTextCopyWith(ResolvedText value, $Res Function(ResolvedText) _then) = _$ResolvedTextCopyWithImpl;
@useResult
$Res call({
 String id, String text, int startUs, int endUs, int laneIndex, TextStyleSpec style, ItemTransform transform, TextAnimation animationIn, TextAnimation animationOut
});


$TextStyleSpecCopyWith<$Res> get style;$ItemTransformCopyWith<$Res> get transform;

}
/// @nodoc
class _$ResolvedTextCopyWithImpl<$Res>
    implements $ResolvedTextCopyWith<$Res> {
  _$ResolvedTextCopyWithImpl(this._self, this._then);

  final ResolvedText _self;
  final $Res Function(ResolvedText) _then;

/// Create a copy of ResolvedText
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? text = null,Object? startUs = null,Object? endUs = null,Object? laneIndex = null,Object? style = null,Object? transform = null,Object? animationIn = null,Object? animationOut = null,}) {
  return _then(ResolvedText(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,startUs: null == startUs ? _self.startUs : startUs // ignore: cast_nullable_to_non_nullable
as int,endUs: null == endUs ? _self.endUs : endUs // ignore: cast_nullable_to_non_nullable
as int,laneIndex: null == laneIndex ? _self.laneIndex : laneIndex // ignore: cast_nullable_to_non_nullable
as int,style: null == style ? _self.style : style // ignore: cast_nullable_to_non_nullable
as TextStyleSpec,transform: null == transform ? _self.transform : transform // ignore: cast_nullable_to_non_nullable
as ItemTransform,animationIn: null == animationIn ? _self.animationIn : animationIn // ignore: cast_nullable_to_non_nullable
as TextAnimation,animationOut: null == animationOut ? _self.animationOut : animationOut // ignore: cast_nullable_to_non_nullable
as TextAnimation,
  ));
}
/// Create a copy of ResolvedText
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TextStyleSpecCopyWith<$Res> get style {
  
  return $TextStyleSpecCopyWith<$Res>(_self.style, (value) {
    return _then(_self.copyWith(style: value));
  });
}/// Create a copy of ResolvedText
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ItemTransformCopyWith<$Res> get transform {
  
  return $ItemTransformCopyWith<$Res>(_self.transform, (value) {
    return _then(_self.copyWith(transform: value));
  });
}
}


/// Adds pattern-matching-related methods to [ResolvedText].
extension ResolvedTextPatterns on ResolvedText {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResolvedText value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResolvedText() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResolvedText value)  $default,){
final _that = this;
switch (_that) {
case _ResolvedText():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResolvedText value)?  $default,){
final _that = this;
switch (_that) {
case _ResolvedText() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String text,  int startUs,  int endUs,  int laneIndex,  TextStyleSpec style,  ItemTransform transform,  TextAnimation animationIn,  TextAnimation animationOut)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResolvedText() when $default != null:
return $default(_that.id,_that.text,_that.startUs,_that.endUs,_that.laneIndex,_that.style,_that.transform,_that.animationIn,_that.animationOut);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String text,  int startUs,  int endUs,  int laneIndex,  TextStyleSpec style,  ItemTransform transform,  TextAnimation animationIn,  TextAnimation animationOut)  $default,) {final _that = this;
switch (_that) {
case _ResolvedText():
return $default(_that.id,_that.text,_that.startUs,_that.endUs,_that.laneIndex,_that.style,_that.transform,_that.animationIn,_that.animationOut);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String text,  int startUs,  int endUs,  int laneIndex,  TextStyleSpec style,  ItemTransform transform,  TextAnimation animationIn,  TextAnimation animationOut)?  $default,) {final _that = this;
switch (_that) {
case _ResolvedText() when $default != null:
return $default(_that.id,_that.text,_that.startUs,_that.endUs,_that.laneIndex,_that.style,_that.transform,_that.animationIn,_that.animationOut);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ResolvedText implements ResolvedText {
  const _ResolvedText({required this.id, required this.text, required this.startUs, required this.endUs, required this.laneIndex, required this.style, required this.transform, required this.animationIn, required this.animationOut});
  factory _ResolvedText.fromJson(Map<String, dynamic> json) => _$ResolvedTextFromJson(json);

@override final  String id;
@override final  String text;
@override final  int startUs;
@override final  int endUs;
@override final  int laneIndex;
@override final  TextStyleSpec style;
@override final  ItemTransform transform;
@override final  TextAnimation animationIn;
@override final  TextAnimation animationOut;

/// Create a copy of ResolvedText
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResolvedTextCopyWith<_ResolvedText> get copyWith => __$ResolvedTextCopyWithImpl<_ResolvedText>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ResolvedTextToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResolvedText&&(identical(other.id, id) || other.id == id)&&(identical(other.text, text) || other.text == text)&&(identical(other.startUs, startUs) || other.startUs == startUs)&&(identical(other.endUs, endUs) || other.endUs == endUs)&&(identical(other.laneIndex, laneIndex) || other.laneIndex == laneIndex)&&(identical(other.style, style) || other.style == style)&&(identical(other.transform, transform) || other.transform == transform)&&(identical(other.animationIn, animationIn) || other.animationIn == animationIn)&&(identical(other.animationOut, animationOut) || other.animationOut == animationOut));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,text,startUs,endUs,laneIndex,style,transform,animationIn,animationOut);
}

@override
String toString() {
    return 'ResolvedText(id: $id, text: $text, startUs: $startUs, endUs: $endUs, laneIndex: $laneIndex, style: $style, transform: $transform, animationIn: $animationIn, animationOut: $animationOut)';
}


}

/// @nodoc
abstract mixin class _$ResolvedTextCopyWith<$Res> implements $ResolvedTextCopyWith<$Res> {
  factory _$ResolvedTextCopyWith(_ResolvedText value, $Res Function(_ResolvedText) _then) = __$ResolvedTextCopyWithImpl;
@override @useResult
$Res call({
 String id, String text, int startUs, int endUs, int laneIndex, TextStyleSpec style, ItemTransform transform, TextAnimation animationIn, TextAnimation animationOut
});


@override $TextStyleSpecCopyWith<$Res> get style;@override $ItemTransformCopyWith<$Res> get transform;

}
/// @nodoc
class __$ResolvedTextCopyWithImpl<$Res>
    implements _$ResolvedTextCopyWith<$Res> {
  __$ResolvedTextCopyWithImpl(this._self, this._then);

  final _ResolvedText _self;
  final $Res Function(_ResolvedText) _then;

/// Create a copy of ResolvedText
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? text = null,Object? startUs = null,Object? endUs = null,Object? laneIndex = null,Object? style = null,Object? transform = null,Object? animationIn = null,Object? animationOut = null,}) {
  return _then(_ResolvedText(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,startUs: null == startUs ? _self.startUs : startUs // ignore: cast_nullable_to_non_nullable
as int,endUs: null == endUs ? _self.endUs : endUs // ignore: cast_nullable_to_non_nullable
as int,laneIndex: null == laneIndex ? _self.laneIndex : laneIndex // ignore: cast_nullable_to_non_nullable
as int,style: null == style ? _self.style : style // ignore: cast_nullable_to_non_nullable
as TextStyleSpec,transform: null == transform ? _self.transform : transform // ignore: cast_nullable_to_non_nullable
as ItemTransform,animationIn: null == animationIn ? _self.animationIn : animationIn // ignore: cast_nullable_to_non_nullable
as TextAnimation,animationOut: null == animationOut ? _self.animationOut : animationOut // ignore: cast_nullable_to_non_nullable
as TextAnimation,
  ));
}

/// Create a copy of ResolvedText
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TextStyleSpecCopyWith<$Res> get style {
  
  return $TextStyleSpecCopyWith<$Res>(_self.style, (value) {
    return _then(_self.copyWith(style: value));
  });
}/// Create a copy of ResolvedText
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
mixin _$ResolvedWord {

 String get text; int get startUs; int get endUs;
/// Create a copy of ResolvedWord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResolvedWordCopyWith<ResolvedWord> get copyWith => _$ResolvedWordCopyWithImpl<ResolvedWord>(this as ResolvedWord, _$identity);

  /// Serializes this ResolvedWord to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ResolvedWord;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResolvedWord&&(identical(other.text, _this.text) || other.text == _this.text)&&(identical(other.startUs, _this.startUs) || other.startUs == _this.startUs)&&(identical(other.endUs, _this.endUs) || other.endUs == _this.endUs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ResolvedWord;
  return Object.hash(runtimeType,_this.text,_this.startUs,_this.endUs);
}

@override
String toString() {
  final _this = this as ResolvedWord;
  return 'ResolvedWord(text: ${_this.text}, startUs: ${_this.startUs}, endUs: ${_this.endUs})';
}


}

/// @nodoc
abstract mixin class $ResolvedWordCopyWith<$Res>  {
  factory $ResolvedWordCopyWith(ResolvedWord value, $Res Function(ResolvedWord) _then) = _$ResolvedWordCopyWithImpl;
@useResult
$Res call({
 String text, int startUs, int endUs
});




}
/// @nodoc
class _$ResolvedWordCopyWithImpl<$Res>
    implements $ResolvedWordCopyWith<$Res> {
  _$ResolvedWordCopyWithImpl(this._self, this._then);

  final ResolvedWord _self;
  final $Res Function(ResolvedWord) _then;

/// Create a copy of ResolvedWord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? text = null,Object? startUs = null,Object? endUs = null,}) {
  return _then(ResolvedWord(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,startUs: null == startUs ? _self.startUs : startUs // ignore: cast_nullable_to_non_nullable
as int,endUs: null == endUs ? _self.endUs : endUs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ResolvedWord].
extension ResolvedWordPatterns on ResolvedWord {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResolvedWord value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResolvedWord() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResolvedWord value)  $default,){
final _that = this;
switch (_that) {
case _ResolvedWord():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResolvedWord value)?  $default,){
final _that = this;
switch (_that) {
case _ResolvedWord() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String text,  int startUs,  int endUs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResolvedWord() when $default != null:
return $default(_that.text,_that.startUs,_that.endUs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String text,  int startUs,  int endUs)  $default,) {final _that = this;
switch (_that) {
case _ResolvedWord():
return $default(_that.text,_that.startUs,_that.endUs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String text,  int startUs,  int endUs)?  $default,) {final _that = this;
switch (_that) {
case _ResolvedWord() when $default != null:
return $default(_that.text,_that.startUs,_that.endUs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ResolvedWord implements ResolvedWord {
  const _ResolvedWord({required this.text, required this.startUs, required this.endUs});
  factory _ResolvedWord.fromJson(Map<String, dynamic> json) => _$ResolvedWordFromJson(json);

@override final  String text;
@override final  int startUs;
@override final  int endUs;

/// Create a copy of ResolvedWord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResolvedWordCopyWith<_ResolvedWord> get copyWith => __$ResolvedWordCopyWithImpl<_ResolvedWord>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ResolvedWordToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResolvedWord&&(identical(other.text, text) || other.text == text)&&(identical(other.startUs, startUs) || other.startUs == startUs)&&(identical(other.endUs, endUs) || other.endUs == endUs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,text,startUs,endUs);
}

@override
String toString() {
    return 'ResolvedWord(text: $text, startUs: $startUs, endUs: $endUs)';
}


}

/// @nodoc
abstract mixin class _$ResolvedWordCopyWith<$Res> implements $ResolvedWordCopyWith<$Res> {
  factory _$ResolvedWordCopyWith(_ResolvedWord value, $Res Function(_ResolvedWord) _then) = __$ResolvedWordCopyWithImpl;
@override @useResult
$Res call({
 String text, int startUs, int endUs
});




}
/// @nodoc
class __$ResolvedWordCopyWithImpl<$Res>
    implements _$ResolvedWordCopyWith<$Res> {
  __$ResolvedWordCopyWithImpl(this._self, this._then);

  final _ResolvedWord _self;
  final $Res Function(_ResolvedWord) _then;

/// Create a copy of ResolvedWord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = null,Object? startUs = null,Object? endUs = null,}) {
  return _then(_ResolvedWord(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,startUs: null == startUs ? _self.startUs : startUs // ignore: cast_nullable_to_non_nullable
as int,endUs: null == endUs ? _self.endUs : endUs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ResolvedCaption {

 String get id; String get text; int get startUs; int get endUs; List<ResolvedWord> get words;
/// Create a copy of ResolvedCaption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResolvedCaptionCopyWith<ResolvedCaption> get copyWith => _$ResolvedCaptionCopyWithImpl<ResolvedCaption>(this as ResolvedCaption, _$identity);

  /// Serializes this ResolvedCaption to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ResolvedCaption;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResolvedCaption&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.text, _this.text) || other.text == _this.text)&&(identical(other.startUs, _this.startUs) || other.startUs == _this.startUs)&&(identical(other.endUs, _this.endUs) || other.endUs == _this.endUs)&&const DeepCollectionEquality().equals(other.words, _this.words));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ResolvedCaption;
  return Object.hash(runtimeType,_this.id,_this.text,_this.startUs,_this.endUs,const DeepCollectionEquality().hash(_this.words));
}

@override
String toString() {
  final _this = this as ResolvedCaption;
  return 'ResolvedCaption(id: ${_this.id}, text: ${_this.text}, startUs: ${_this.startUs}, endUs: ${_this.endUs}, words: ${_this.words})';
}


}

/// @nodoc
abstract mixin class $ResolvedCaptionCopyWith<$Res>  {
  factory $ResolvedCaptionCopyWith(ResolvedCaption value, $Res Function(ResolvedCaption) _then) = _$ResolvedCaptionCopyWithImpl;
@useResult
$Res call({
 String id, String text, int startUs, int endUs, List<ResolvedWord> words
});




}
/// @nodoc
class _$ResolvedCaptionCopyWithImpl<$Res>
    implements $ResolvedCaptionCopyWith<$Res> {
  _$ResolvedCaptionCopyWithImpl(this._self, this._then);

  final ResolvedCaption _self;
  final $Res Function(ResolvedCaption) _then;

/// Create a copy of ResolvedCaption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? text = null,Object? startUs = null,Object? endUs = null,Object? words = null,}) {
  return _then(ResolvedCaption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,startUs: null == startUs ? _self.startUs : startUs // ignore: cast_nullable_to_non_nullable
as int,endUs: null == endUs ? _self.endUs : endUs // ignore: cast_nullable_to_non_nullable
as int,words: null == words ? _self.words : words // ignore: cast_nullable_to_non_nullable
as List<ResolvedWord>,
  ));
}

}


/// Adds pattern-matching-related methods to [ResolvedCaption].
extension ResolvedCaptionPatterns on ResolvedCaption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResolvedCaption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResolvedCaption() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResolvedCaption value)  $default,){
final _that = this;
switch (_that) {
case _ResolvedCaption():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResolvedCaption value)?  $default,){
final _that = this;
switch (_that) {
case _ResolvedCaption() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String text,  int startUs,  int endUs,  List<ResolvedWord> words)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResolvedCaption() when $default != null:
return $default(_that.id,_that.text,_that.startUs,_that.endUs,_that.words);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String text,  int startUs,  int endUs,  List<ResolvedWord> words)  $default,) {final _that = this;
switch (_that) {
case _ResolvedCaption():
return $default(_that.id,_that.text,_that.startUs,_that.endUs,_that.words);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String text,  int startUs,  int endUs,  List<ResolvedWord> words)?  $default,) {final _that = this;
switch (_that) {
case _ResolvedCaption() when $default != null:
return $default(_that.id,_that.text,_that.startUs,_that.endUs,_that.words);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ResolvedCaption implements ResolvedCaption {
  const _ResolvedCaption({required this.id, required this.text, required this.startUs, required this.endUs,  List<ResolvedWord> words = const <ResolvedWord>[]}): _words = words;
  factory _ResolvedCaption.fromJson(Map<String, dynamic> json) => _$ResolvedCaptionFromJson(json);

@override final  String id;
@override final  String text;
@override final  int startUs;
@override final  int endUs;
 final  List<ResolvedWord> _words;
@override@JsonKey() List<ResolvedWord> get words {
  if (_words is EqualUnmodifiableListView) return _words;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_words);
}


/// Create a copy of ResolvedCaption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResolvedCaptionCopyWith<_ResolvedCaption> get copyWith => __$ResolvedCaptionCopyWithImpl<_ResolvedCaption>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ResolvedCaptionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResolvedCaption&&(identical(other.id, id) || other.id == id)&&(identical(other.text, text) || other.text == text)&&(identical(other.startUs, startUs) || other.startUs == startUs)&&(identical(other.endUs, endUs) || other.endUs == endUs)&&const DeepCollectionEquality().equals(other.words, _words));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,text,startUs,endUs,const DeepCollectionEquality().hash(_words));
}

@override
String toString() {
    return 'ResolvedCaption(id: $id, text: $text, startUs: $startUs, endUs: $endUs, words: $words)';
}


}

/// @nodoc
abstract mixin class _$ResolvedCaptionCopyWith<$Res> implements $ResolvedCaptionCopyWith<$Res> {
  factory _$ResolvedCaptionCopyWith(_ResolvedCaption value, $Res Function(_ResolvedCaption) _then) = __$ResolvedCaptionCopyWithImpl;
@override @useResult
$Res call({
 String id, String text, int startUs, int endUs, List<ResolvedWord> words
});




}
/// @nodoc
class __$ResolvedCaptionCopyWithImpl<$Res>
    implements _$ResolvedCaptionCopyWith<$Res> {
  __$ResolvedCaptionCopyWithImpl(this._self, this._then);

  final _ResolvedCaption _self;
  final $Res Function(_ResolvedCaption) _then;

/// Create a copy of ResolvedCaption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? text = null,Object? startUs = null,Object? endUs = null,Object? words = null,}) {
  return _then(_ResolvedCaption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,startUs: null == startUs ? _self.startUs : startUs // ignore: cast_nullable_to_non_nullable
as int,endUs: null == endUs ? _self.endUs : endUs // ignore: cast_nullable_to_non_nullable
as int,words: null == words ? _self._words : words // ignore: cast_nullable_to_non_nullable
as List<ResolvedWord>,
  ));
}


}


/// @nodoc
mixin _$ResolvedAudio {

 String get id; String get mediaId; AudioKind get kind; int get startUs; int get endUs; int get sourceInUs; int get sourceOutUs; double get speed;/// Repeat [sourceInUs] to [sourceOutUs] until [endUs].
 bool get loop;/// Final gain including the added-audio level.
 double get volume; int get fadeInUs; int get fadeOutUs;/// The item ran past the end of the video and was cut there.
 bool get cutAtVideoEnd;
/// Create a copy of ResolvedAudio
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResolvedAudioCopyWith<ResolvedAudio> get copyWith => _$ResolvedAudioCopyWithImpl<ResolvedAudio>(this as ResolvedAudio, _$identity);

  /// Serializes this ResolvedAudio to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ResolvedAudio;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResolvedAudio&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.mediaId, _this.mediaId) || other.mediaId == _this.mediaId)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.startUs, _this.startUs) || other.startUs == _this.startUs)&&(identical(other.endUs, _this.endUs) || other.endUs == _this.endUs)&&(identical(other.sourceInUs, _this.sourceInUs) || other.sourceInUs == _this.sourceInUs)&&(identical(other.sourceOutUs, _this.sourceOutUs) || other.sourceOutUs == _this.sourceOutUs)&&(identical(other.speed, _this.speed) || other.speed == _this.speed)&&(identical(other.loop, _this.loop) || other.loop == _this.loop)&&(identical(other.volume, _this.volume) || other.volume == _this.volume)&&(identical(other.fadeInUs, _this.fadeInUs) || other.fadeInUs == _this.fadeInUs)&&(identical(other.fadeOutUs, _this.fadeOutUs) || other.fadeOutUs == _this.fadeOutUs)&&(identical(other.cutAtVideoEnd, _this.cutAtVideoEnd) || other.cutAtVideoEnd == _this.cutAtVideoEnd));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ResolvedAudio;
  return Object.hash(runtimeType,_this.id,_this.mediaId,_this.kind,_this.startUs,_this.endUs,_this.sourceInUs,_this.sourceOutUs,_this.speed,_this.loop,_this.volume,_this.fadeInUs,_this.fadeOutUs,_this.cutAtVideoEnd);
}

@override
String toString() {
  final _this = this as ResolvedAudio;
  return 'ResolvedAudio(id: ${_this.id}, mediaId: ${_this.mediaId}, kind: ${_this.kind}, startUs: ${_this.startUs}, endUs: ${_this.endUs}, sourceInUs: ${_this.sourceInUs}, sourceOutUs: ${_this.sourceOutUs}, speed: ${_this.speed}, loop: ${_this.loop}, volume: ${_this.volume}, fadeInUs: ${_this.fadeInUs}, fadeOutUs: ${_this.fadeOutUs}, cutAtVideoEnd: ${_this.cutAtVideoEnd})';
}


}

/// @nodoc
abstract mixin class $ResolvedAudioCopyWith<$Res>  {
  factory $ResolvedAudioCopyWith(ResolvedAudio value, $Res Function(ResolvedAudio) _then) = _$ResolvedAudioCopyWithImpl;
@useResult
$Res call({
 String id, String mediaId, AudioKind kind, int startUs, int endUs, int sourceInUs, int sourceOutUs, double speed, bool loop, double volume, int fadeInUs, int fadeOutUs, bool cutAtVideoEnd
});




}
/// @nodoc
class _$ResolvedAudioCopyWithImpl<$Res>
    implements $ResolvedAudioCopyWith<$Res> {
  _$ResolvedAudioCopyWithImpl(this._self, this._then);

  final ResolvedAudio _self;
  final $Res Function(ResolvedAudio) _then;

/// Create a copy of ResolvedAudio
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? mediaId = null,Object? kind = null,Object? startUs = null,Object? endUs = null,Object? sourceInUs = null,Object? sourceOutUs = null,Object? speed = null,Object? loop = null,Object? volume = null,Object? fadeInUs = null,Object? fadeOutUs = null,Object? cutAtVideoEnd = null,}) {
  return _then(ResolvedAudio(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,mediaId: null == mediaId ? _self.mediaId : mediaId // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as AudioKind,startUs: null == startUs ? _self.startUs : startUs // ignore: cast_nullable_to_non_nullable
as int,endUs: null == endUs ? _self.endUs : endUs // ignore: cast_nullable_to_non_nullable
as int,sourceInUs: null == sourceInUs ? _self.sourceInUs : sourceInUs // ignore: cast_nullable_to_non_nullable
as int,sourceOutUs: null == sourceOutUs ? _self.sourceOutUs : sourceOutUs // ignore: cast_nullable_to_non_nullable
as int,speed: null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double,loop: null == loop ? _self.loop : loop // ignore: cast_nullable_to_non_nullable
as bool,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,fadeInUs: null == fadeInUs ? _self.fadeInUs : fadeInUs // ignore: cast_nullable_to_non_nullable
as int,fadeOutUs: null == fadeOutUs ? _self.fadeOutUs : fadeOutUs // ignore: cast_nullable_to_non_nullable
as int,cutAtVideoEnd: null == cutAtVideoEnd ? _self.cutAtVideoEnd : cutAtVideoEnd // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ResolvedAudio].
extension ResolvedAudioPatterns on ResolvedAudio {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResolvedAudio value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResolvedAudio() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResolvedAudio value)  $default,){
final _that = this;
switch (_that) {
case _ResolvedAudio():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResolvedAudio value)?  $default,){
final _that = this;
switch (_that) {
case _ResolvedAudio() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String mediaId,  AudioKind kind,  int startUs,  int endUs,  int sourceInUs,  int sourceOutUs,  double speed,  bool loop,  double volume,  int fadeInUs,  int fadeOutUs,  bool cutAtVideoEnd)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResolvedAudio() when $default != null:
return $default(_that.id,_that.mediaId,_that.kind,_that.startUs,_that.endUs,_that.sourceInUs,_that.sourceOutUs,_that.speed,_that.loop,_that.volume,_that.fadeInUs,_that.fadeOutUs,_that.cutAtVideoEnd);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String mediaId,  AudioKind kind,  int startUs,  int endUs,  int sourceInUs,  int sourceOutUs,  double speed,  bool loop,  double volume,  int fadeInUs,  int fadeOutUs,  bool cutAtVideoEnd)  $default,) {final _that = this;
switch (_that) {
case _ResolvedAudio():
return $default(_that.id,_that.mediaId,_that.kind,_that.startUs,_that.endUs,_that.sourceInUs,_that.sourceOutUs,_that.speed,_that.loop,_that.volume,_that.fadeInUs,_that.fadeOutUs,_that.cutAtVideoEnd);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String mediaId,  AudioKind kind,  int startUs,  int endUs,  int sourceInUs,  int sourceOutUs,  double speed,  bool loop,  double volume,  int fadeInUs,  int fadeOutUs,  bool cutAtVideoEnd)?  $default,) {final _that = this;
switch (_that) {
case _ResolvedAudio() when $default != null:
return $default(_that.id,_that.mediaId,_that.kind,_that.startUs,_that.endUs,_that.sourceInUs,_that.sourceOutUs,_that.speed,_that.loop,_that.volume,_that.fadeInUs,_that.fadeOutUs,_that.cutAtVideoEnd);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ResolvedAudio implements ResolvedAudio {
  const _ResolvedAudio({required this.id, required this.mediaId, required this.kind, required this.startUs, required this.endUs, required this.sourceInUs, required this.sourceOutUs, required this.speed, required this.loop, required this.volume, required this.fadeInUs, required this.fadeOutUs, required this.cutAtVideoEnd});
  factory _ResolvedAudio.fromJson(Map<String, dynamic> json) => _$ResolvedAudioFromJson(json);

@override final  String id;
@override final  String mediaId;
@override final  AudioKind kind;
@override final  int startUs;
@override final  int endUs;
@override final  int sourceInUs;
@override final  int sourceOutUs;
@override final  double speed;
/// Repeat [sourceInUs] to [sourceOutUs] until [endUs].
@override final  bool loop;
/// Final gain including the added-audio level.
@override final  double volume;
@override final  int fadeInUs;
@override final  int fadeOutUs;
/// The item ran past the end of the video and was cut there.
@override final  bool cutAtVideoEnd;

/// Create a copy of ResolvedAudio
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResolvedAudioCopyWith<_ResolvedAudio> get copyWith => __$ResolvedAudioCopyWithImpl<_ResolvedAudio>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ResolvedAudioToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResolvedAudio&&(identical(other.id, id) || other.id == id)&&(identical(other.mediaId, mediaId) || other.mediaId == mediaId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.startUs, startUs) || other.startUs == startUs)&&(identical(other.endUs, endUs) || other.endUs == endUs)&&(identical(other.sourceInUs, sourceInUs) || other.sourceInUs == sourceInUs)&&(identical(other.sourceOutUs, sourceOutUs) || other.sourceOutUs == sourceOutUs)&&(identical(other.speed, speed) || other.speed == speed)&&(identical(other.loop, loop) || other.loop == loop)&&(identical(other.volume, volume) || other.volume == volume)&&(identical(other.fadeInUs, fadeInUs) || other.fadeInUs == fadeInUs)&&(identical(other.fadeOutUs, fadeOutUs) || other.fadeOutUs == fadeOutUs)&&(identical(other.cutAtVideoEnd, cutAtVideoEnd) || other.cutAtVideoEnd == cutAtVideoEnd));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,mediaId,kind,startUs,endUs,sourceInUs,sourceOutUs,speed,loop,volume,fadeInUs,fadeOutUs,cutAtVideoEnd);
}

@override
String toString() {
    return 'ResolvedAudio(id: $id, mediaId: $mediaId, kind: $kind, startUs: $startUs, endUs: $endUs, sourceInUs: $sourceInUs, sourceOutUs: $sourceOutUs, speed: $speed, loop: $loop, volume: $volume, fadeInUs: $fadeInUs, fadeOutUs: $fadeOutUs, cutAtVideoEnd: $cutAtVideoEnd)';
}


}

/// @nodoc
abstract mixin class _$ResolvedAudioCopyWith<$Res> implements $ResolvedAudioCopyWith<$Res> {
  factory _$ResolvedAudioCopyWith(_ResolvedAudio value, $Res Function(_ResolvedAudio) _then) = __$ResolvedAudioCopyWithImpl;
@override @useResult
$Res call({
 String id, String mediaId, AudioKind kind, int startUs, int endUs, int sourceInUs, int sourceOutUs, double speed, bool loop, double volume, int fadeInUs, int fadeOutUs, bool cutAtVideoEnd
});




}
/// @nodoc
class __$ResolvedAudioCopyWithImpl<$Res>
    implements _$ResolvedAudioCopyWith<$Res> {
  __$ResolvedAudioCopyWithImpl(this._self, this._then);

  final _ResolvedAudio _self;
  final $Res Function(_ResolvedAudio) _then;

/// Create a copy of ResolvedAudio
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? mediaId = null,Object? kind = null,Object? startUs = null,Object? endUs = null,Object? sourceInUs = null,Object? sourceOutUs = null,Object? speed = null,Object? loop = null,Object? volume = null,Object? fadeInUs = null,Object? fadeOutUs = null,Object? cutAtVideoEnd = null,}) {
  return _then(_ResolvedAudio(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,mediaId: null == mediaId ? _self.mediaId : mediaId // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as AudioKind,startUs: null == startUs ? _self.startUs : startUs // ignore: cast_nullable_to_non_nullable
as int,endUs: null == endUs ? _self.endUs : endUs // ignore: cast_nullable_to_non_nullable
as int,sourceInUs: null == sourceInUs ? _self.sourceInUs : sourceInUs // ignore: cast_nullable_to_non_nullable
as int,sourceOutUs: null == sourceOutUs ? _self.sourceOutUs : sourceOutUs // ignore: cast_nullable_to_non_nullable
as int,speed: null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double,loop: null == loop ? _self.loop : loop // ignore: cast_nullable_to_non_nullable
as bool,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,fadeInUs: null == fadeInUs ? _self.fadeInUs : fadeInUs // ignore: cast_nullable_to_non_nullable
as int,fadeOutUs: null == fadeOutUs ? _self.fadeOutUs : fadeOutUs // ignore: cast_nullable_to_non_nullable
as int,cutAtVideoEnd: null == cutAtVideoEnd ? _self.cutAtVideoEnd : cutAtVideoEnd // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$ResolvedComposition {

 int get durationUs; List<ResolvedClip> get clips; List<ResolvedTransition> get transitions; List<ResolvedText> get texts; List<ResolvedCaption> get captions; CaptionPreset get captionPreset; CaptionPosition get captionPosition; List<ResolvedAudio> get audio;
/// Create a copy of ResolvedComposition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResolvedCompositionCopyWith<ResolvedComposition> get copyWith => _$ResolvedCompositionCopyWithImpl<ResolvedComposition>(this as ResolvedComposition, _$identity);

  /// Serializes this ResolvedComposition to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ResolvedComposition;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResolvedComposition&&(identical(other.durationUs, _this.durationUs) || other.durationUs == _this.durationUs)&&const DeepCollectionEquality().equals(other.clips, _this.clips)&&const DeepCollectionEquality().equals(other.transitions, _this.transitions)&&const DeepCollectionEquality().equals(other.texts, _this.texts)&&const DeepCollectionEquality().equals(other.captions, _this.captions)&&(identical(other.captionPreset, _this.captionPreset) || other.captionPreset == _this.captionPreset)&&(identical(other.captionPosition, _this.captionPosition) || other.captionPosition == _this.captionPosition)&&const DeepCollectionEquality().equals(other.audio, _this.audio));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ResolvedComposition;
  return Object.hash(runtimeType,_this.durationUs,const DeepCollectionEquality().hash(_this.clips),const DeepCollectionEquality().hash(_this.transitions),const DeepCollectionEquality().hash(_this.texts),const DeepCollectionEquality().hash(_this.captions),_this.captionPreset,_this.captionPosition,const DeepCollectionEquality().hash(_this.audio));
}

@override
String toString() {
  final _this = this as ResolvedComposition;
  return 'ResolvedComposition(durationUs: ${_this.durationUs}, clips: ${_this.clips}, transitions: ${_this.transitions}, texts: ${_this.texts}, captions: ${_this.captions}, captionPreset: ${_this.captionPreset}, captionPosition: ${_this.captionPosition}, audio: ${_this.audio})';
}


}

/// @nodoc
abstract mixin class $ResolvedCompositionCopyWith<$Res>  {
  factory $ResolvedCompositionCopyWith(ResolvedComposition value, $Res Function(ResolvedComposition) _then) = _$ResolvedCompositionCopyWithImpl;
@useResult
$Res call({
 int durationUs, List<ResolvedClip> clips, List<ResolvedTransition> transitions, List<ResolvedText> texts, List<ResolvedCaption> captions, CaptionPreset captionPreset, CaptionPosition captionPosition, List<ResolvedAudio> audio
});




}
/// @nodoc
class _$ResolvedCompositionCopyWithImpl<$Res>
    implements $ResolvedCompositionCopyWith<$Res> {
  _$ResolvedCompositionCopyWithImpl(this._self, this._then);

  final ResolvedComposition _self;
  final $Res Function(ResolvedComposition) _then;

/// Create a copy of ResolvedComposition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? durationUs = null,Object? clips = null,Object? transitions = null,Object? texts = null,Object? captions = null,Object? captionPreset = null,Object? captionPosition = null,Object? audio = null,}) {
  return _then(ResolvedComposition(
durationUs: null == durationUs ? _self.durationUs : durationUs // ignore: cast_nullable_to_non_nullable
as int,clips: null == clips ? _self.clips : clips // ignore: cast_nullable_to_non_nullable
as List<ResolvedClip>,transitions: null == transitions ? _self.transitions : transitions // ignore: cast_nullable_to_non_nullable
as List<ResolvedTransition>,texts: null == texts ? _self.texts : texts // ignore: cast_nullable_to_non_nullable
as List<ResolvedText>,captions: null == captions ? _self.captions : captions // ignore: cast_nullable_to_non_nullable
as List<ResolvedCaption>,captionPreset: null == captionPreset ? _self.captionPreset : captionPreset // ignore: cast_nullable_to_non_nullable
as CaptionPreset,captionPosition: null == captionPosition ? _self.captionPosition : captionPosition // ignore: cast_nullable_to_non_nullable
as CaptionPosition,audio: null == audio ? _self.audio : audio // ignore: cast_nullable_to_non_nullable
as List<ResolvedAudio>,
  ));
}

}


/// Adds pattern-matching-related methods to [ResolvedComposition].
extension ResolvedCompositionPatterns on ResolvedComposition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResolvedComposition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResolvedComposition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResolvedComposition value)  $default,){
final _that = this;
switch (_that) {
case _ResolvedComposition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResolvedComposition value)?  $default,){
final _that = this;
switch (_that) {
case _ResolvedComposition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int durationUs,  List<ResolvedClip> clips,  List<ResolvedTransition> transitions,  List<ResolvedText> texts,  List<ResolvedCaption> captions,  CaptionPreset captionPreset,  CaptionPosition captionPosition,  List<ResolvedAudio> audio)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResolvedComposition() when $default != null:
return $default(_that.durationUs,_that.clips,_that.transitions,_that.texts,_that.captions,_that.captionPreset,_that.captionPosition,_that.audio);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int durationUs,  List<ResolvedClip> clips,  List<ResolvedTransition> transitions,  List<ResolvedText> texts,  List<ResolvedCaption> captions,  CaptionPreset captionPreset,  CaptionPosition captionPosition,  List<ResolvedAudio> audio)  $default,) {final _that = this;
switch (_that) {
case _ResolvedComposition():
return $default(_that.durationUs,_that.clips,_that.transitions,_that.texts,_that.captions,_that.captionPreset,_that.captionPosition,_that.audio);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int durationUs,  List<ResolvedClip> clips,  List<ResolvedTransition> transitions,  List<ResolvedText> texts,  List<ResolvedCaption> captions,  CaptionPreset captionPreset,  CaptionPosition captionPosition,  List<ResolvedAudio> audio)?  $default,) {final _that = this;
switch (_that) {
case _ResolvedComposition() when $default != null:
return $default(_that.durationUs,_that.clips,_that.transitions,_that.texts,_that.captions,_that.captionPreset,_that.captionPosition,_that.audio);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ResolvedComposition implements ResolvedComposition {
  const _ResolvedComposition({required this.durationUs,  List<ResolvedClip> clips = const <ResolvedClip>[],  List<ResolvedTransition> transitions = const <ResolvedTransition>[],  List<ResolvedText> texts = const <ResolvedText>[],  List<ResolvedCaption> captions = const <ResolvedCaption>[], this.captionPreset = CaptionPreset.plain, this.captionPosition = CaptionPosition.bottom,  List<ResolvedAudio> audio = const <ResolvedAudio>[]}): _clips = clips,_transitions = transitions,_texts = texts,_captions = captions,_audio = audio;
  factory _ResolvedComposition.fromJson(Map<String, dynamic> json) => _$ResolvedCompositionFromJson(json);

@override final  int durationUs;
 final  List<ResolvedClip> _clips;
@override@JsonKey() List<ResolvedClip> get clips {
  if (_clips is EqualUnmodifiableListView) return _clips;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_clips);
}

 final  List<ResolvedTransition> _transitions;
@override@JsonKey() List<ResolvedTransition> get transitions {
  if (_transitions is EqualUnmodifiableListView) return _transitions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_transitions);
}

 final  List<ResolvedText> _texts;
@override@JsonKey() List<ResolvedText> get texts {
  if (_texts is EqualUnmodifiableListView) return _texts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_texts);
}

 final  List<ResolvedCaption> _captions;
@override@JsonKey() List<ResolvedCaption> get captions {
  if (_captions is EqualUnmodifiableListView) return _captions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_captions);
}

@override@JsonKey() final  CaptionPreset captionPreset;
@override@JsonKey() final  CaptionPosition captionPosition;
 final  List<ResolvedAudio> _audio;
@override@JsonKey() List<ResolvedAudio> get audio {
  if (_audio is EqualUnmodifiableListView) return _audio;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_audio);
}


/// Create a copy of ResolvedComposition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResolvedCompositionCopyWith<_ResolvedComposition> get copyWith => __$ResolvedCompositionCopyWithImpl<_ResolvedComposition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ResolvedCompositionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResolvedComposition&&(identical(other.durationUs, durationUs) || other.durationUs == durationUs)&&const DeepCollectionEquality().equals(other.clips, _clips)&&const DeepCollectionEquality().equals(other.transitions, _transitions)&&const DeepCollectionEquality().equals(other.texts, _texts)&&const DeepCollectionEquality().equals(other.captions, _captions)&&(identical(other.captionPreset, captionPreset) || other.captionPreset == captionPreset)&&(identical(other.captionPosition, captionPosition) || other.captionPosition == captionPosition)&&const DeepCollectionEquality().equals(other.audio, _audio));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,durationUs,const DeepCollectionEquality().hash(_clips),const DeepCollectionEquality().hash(_transitions),const DeepCollectionEquality().hash(_texts),const DeepCollectionEquality().hash(_captions),captionPreset,captionPosition,const DeepCollectionEquality().hash(_audio));
}

@override
String toString() {
    return 'ResolvedComposition(durationUs: $durationUs, clips: $clips, transitions: $transitions, texts: $texts, captions: $captions, captionPreset: $captionPreset, captionPosition: $captionPosition, audio: $audio)';
}


}

/// @nodoc
abstract mixin class _$ResolvedCompositionCopyWith<$Res> implements $ResolvedCompositionCopyWith<$Res> {
  factory _$ResolvedCompositionCopyWith(_ResolvedComposition value, $Res Function(_ResolvedComposition) _then) = __$ResolvedCompositionCopyWithImpl;
@override @useResult
$Res call({
 int durationUs, List<ResolvedClip> clips, List<ResolvedTransition> transitions, List<ResolvedText> texts, List<ResolvedCaption> captions, CaptionPreset captionPreset, CaptionPosition captionPosition, List<ResolvedAudio> audio
});




}
/// @nodoc
class __$ResolvedCompositionCopyWithImpl<$Res>
    implements _$ResolvedCompositionCopyWith<$Res> {
  __$ResolvedCompositionCopyWithImpl(this._self, this._then);

  final _ResolvedComposition _self;
  final $Res Function(_ResolvedComposition) _then;

/// Create a copy of ResolvedComposition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? durationUs = null,Object? clips = null,Object? transitions = null,Object? texts = null,Object? captions = null,Object? captionPreset = null,Object? captionPosition = null,Object? audio = null,}) {
  return _then(_ResolvedComposition(
durationUs: null == durationUs ? _self.durationUs : durationUs // ignore: cast_nullable_to_non_nullable
as int,clips: null == clips ? _self._clips : clips // ignore: cast_nullable_to_non_nullable
as List<ResolvedClip>,transitions: null == transitions ? _self._transitions : transitions // ignore: cast_nullable_to_non_nullable
as List<ResolvedTransition>,texts: null == texts ? _self._texts : texts // ignore: cast_nullable_to_non_nullable
as List<ResolvedText>,captions: null == captions ? _self._captions : captions // ignore: cast_nullable_to_non_nullable
as List<ResolvedCaption>,captionPreset: null == captionPreset ? _self.captionPreset : captionPreset // ignore: cast_nullable_to_non_nullable
as CaptionPreset,captionPosition: null == captionPosition ? _self.captionPosition : captionPosition // ignore: cast_nullable_to_non_nullable
as CaptionPosition,audio: null == audio ? _self._audio : audio // ignore: cast_nullable_to_non_nullable
as List<ResolvedAudio>,
  ));
}


}

// dart format on
