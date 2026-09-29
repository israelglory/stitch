// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'keyframing.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The keyframe button's target; null (disabled) with nothing selected or
/// with the playhead outside the selected item. Changes only when the
/// target does, not with every playback tick.

@ProviderFor(keyframeTarget)
final keyframeTargetProvider = KeyframeTargetFamily._();

/// The keyframe button's target; null (disabled) with nothing selected or
/// with the playhead outside the selected item. Changes only when the
/// target does, not with every playback tick.

final class KeyframeTargetProvider
    extends
        $FunctionalProvider<KeyframeTarget?, KeyframeTarget?, KeyframeTarget?>
    with $Provider<KeyframeTarget?> {
  /// The keyframe button's target; null (disabled) with nothing selected or
  /// with the playhead outside the selected item. Changes only when the
  /// target does, not with every playback tick.
  KeyframeTargetProvider._({
    required KeyframeTargetFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'keyframeTargetProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$keyframeTargetHash();

  @override
  String toString() {
    return r'keyframeTargetProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<KeyframeTarget?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  KeyframeTarget? create(Ref ref) {
    final argument = this.argument as String;
    return keyframeTarget(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(KeyframeTarget? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<KeyframeTarget?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is KeyframeTargetProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$keyframeTargetHash() => r'1fef0f358e6667d5035bc618c0d6cdfc9e9dbde0';

/// The keyframe button's target; null (disabled) with nothing selected or
/// with the playhead outside the selected item. Changes only when the
/// target does, not with every playback tick.

final class KeyframeTargetFamily extends $Family
    with $FunctionalFamilyOverride<KeyframeTarget?, String> {
  KeyframeTargetFamily._()
    : super(
        retry: null,
        name: r'keyframeTargetProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The keyframe button's target; null (disabled) with nothing selected or
  /// with the playhead outside the selected item. Changes only when the
  /// target does, not with every playback tick.

  KeyframeTargetProvider call(String projectId) =>
      KeyframeTargetProvider._(argument: projectId, from: this);

  @override
  String toString() => r'keyframeTargetProvider';
}

/// Values of the selected item at the playhead: what sliders and canvas
/// gestures start from.

@ProviderFor(valuesAtPlayhead)
final valuesAtPlayheadProvider = ValuesAtPlayheadFamily._();

/// Values of the selected item at the playhead: what sliders and canvas
/// gestures start from.

final class ValuesAtPlayheadProvider
    extends
        $FunctionalProvider<KeyframeValues?, KeyframeValues?, KeyframeValues?>
    with $Provider<KeyframeValues?> {
  /// Values of the selected item at the playhead: what sliders and canvas
  /// gestures start from.
  ValuesAtPlayheadProvider._({
    required ValuesAtPlayheadFamily super.from,
    required (String, KeyframeOwnerKind, String) super.argument,
  }) : super(
         retry: null,
         name: r'valuesAtPlayheadProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$valuesAtPlayheadHash();

  @override
  String toString() {
    return r'valuesAtPlayheadProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<KeyframeValues?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  KeyframeValues? create(Ref ref) {
    final argument = this.argument as (String, KeyframeOwnerKind, String);
    return valuesAtPlayhead(ref, argument.$1, argument.$2, argument.$3);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(KeyframeValues? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<KeyframeValues?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ValuesAtPlayheadProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$valuesAtPlayheadHash() => r'ef7cf9e801b8412b4b7ab2f25d69029535f1353b';

/// Values of the selected item at the playhead: what sliders and canvas
/// gestures start from.

final class ValuesAtPlayheadFamily extends $Family
    with
        $FunctionalFamilyOverride<
          KeyframeValues?,
          (String, KeyframeOwnerKind, String)
        > {
  ValuesAtPlayheadFamily._()
    : super(
        retry: null,
        name: r'valuesAtPlayheadProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Values of the selected item at the playhead: what sliders and canvas
  /// gestures start from.

  ValuesAtPlayheadProvider call(
    String projectId,
    KeyframeOwnerKind kind,
    String id,
  ) => ValuesAtPlayheadProvider._(argument: (projectId, kind, id), from: this);

  @override
  String toString() => r'valuesAtPlayheadProvider';
}
