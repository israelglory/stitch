// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'current_clip.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The clip under the playhead. Recomputed as the playhead moves, but only
/// notifies when the clip changes, so the preview does not rebuild every
/// frame.

@ProviderFor(clipAtPlayhead)
final clipAtPlayheadProvider = ClipAtPlayheadFamily._();

/// The clip under the playhead. Recomputed as the playhead moves, but only
/// notifies when the clip changes, so the preview does not rebuild every
/// frame.

final class ClipAtPlayheadProvider
    extends $FunctionalProvider<VideoClip?, VideoClip?, VideoClip?>
    with $Provider<VideoClip?> {
  /// The clip under the playhead. Recomputed as the playhead moves, but only
  /// notifies when the clip changes, so the preview does not rebuild every
  /// frame.
  ClipAtPlayheadProvider._({
    required ClipAtPlayheadFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'clipAtPlayheadProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$clipAtPlayheadHash();

  @override
  String toString() {
    return r'clipAtPlayheadProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<VideoClip?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  VideoClip? create(Ref ref) {
    final argument = this.argument as String;
    return clipAtPlayhead(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VideoClip? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VideoClip?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ClipAtPlayheadProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$clipAtPlayheadHash() => r'b2980fb257eb0f5b16c84070cda42e2313edf504';

/// The clip under the playhead. Recomputed as the playhead moves, but only
/// notifies when the clip changes, so the preview does not rebuild every
/// frame.

final class ClipAtPlayheadFamily extends $Family
    with $FunctionalFamilyOverride<VideoClip?, String> {
  ClipAtPlayheadFamily._()
    : super(
        retry: null,
        name: r'clipAtPlayheadProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The clip under the playhead. Recomputed as the playhead moves, but only
  /// notifies when the clip changes, so the preview does not rebuild every
  /// frame.

  ClipAtPlayheadProvider call(String projectId) =>
      ClipAtPlayheadProvider._(argument: projectId, from: this);

  @override
  String toString() => r'clipAtPlayheadProvider';
}
