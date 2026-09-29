// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preview_copies.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Makes the missing preview copies of the open project, one at a time,
/// in the background. The state is how many are still to make.
///
/// Import makes a copy only when the device decodes the source in
/// hardware; others (4K at 60 fps on a mid-range phone, say) need a
/// software decoder and take minutes, so they are made here instead, as
/// are copies an older import could not make. Until a copy is ready,
/// preview reads the original, which such a device may not play.
///
/// A copy that could not be made is recorded on the media
/// ([MediaAsset.previewCopyFailed]) and not tried again until [retry].

@ProviderFor(PreviewCopies)
final previewCopiesProvider = PreviewCopiesFamily._();

/// Makes the missing preview copies of the open project, one at a time,
/// in the background. The state is how many are still to make.
///
/// Import makes a copy only when the device decodes the source in
/// hardware; others (4K at 60 fps on a mid-range phone, say) need a
/// software decoder and take minutes, so they are made here instead, as
/// are copies an older import could not make. Until a copy is ready,
/// preview reads the original, which such a device may not play.
///
/// A copy that could not be made is recorded on the media
/// ([MediaAsset.previewCopyFailed]) and not tried again until [retry].
final class PreviewCopiesProvider
    extends $NotifierProvider<PreviewCopies, int> {
  /// Makes the missing preview copies of the open project, one at a time,
  /// in the background. The state is how many are still to make.
  ///
  /// Import makes a copy only when the device decodes the source in
  /// hardware; others (4K at 60 fps on a mid-range phone, say) need a
  /// software decoder and take minutes, so they are made here instead, as
  /// are copies an older import could not make. Until a copy is ready,
  /// preview reads the original, which such a device may not play.
  ///
  /// A copy that could not be made is recorded on the media
  /// ([MediaAsset.previewCopyFailed]) and not tried again until [retry].
  PreviewCopiesProvider._({
    required PreviewCopiesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'previewCopiesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$previewCopiesHash();

  @override
  String toString() {
    return r'previewCopiesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PreviewCopies create() => PreviewCopies();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PreviewCopiesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$previewCopiesHash() => r'6724aa5ebcd50fa2d1a6494c3dac4e438790aaae';

/// Makes the missing preview copies of the open project, one at a time,
/// in the background. The state is how many are still to make.
///
/// Import makes a copy only when the device decodes the source in
/// hardware; others (4K at 60 fps on a mid-range phone, say) need a
/// software decoder and take minutes, so they are made here instead, as
/// are copies an older import could not make. Until a copy is ready,
/// preview reads the original, which such a device may not play.
///
/// A copy that could not be made is recorded on the media
/// ([MediaAsset.previewCopyFailed]) and not tried again until [retry].

final class PreviewCopiesFamily extends $Family
    with $ClassFamilyOverride<PreviewCopies, int, int, int, String> {
  PreviewCopiesFamily._()
    : super(
        retry: null,
        name: r'previewCopiesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Makes the missing preview copies of the open project, one at a time,
  /// in the background. The state is how many are still to make.
  ///
  /// Import makes a copy only when the device decodes the source in
  /// hardware; others (4K at 60 fps on a mid-range phone, say) need a
  /// software decoder and take minutes, so they are made here instead, as
  /// are copies an older import could not make. Until a copy is ready,
  /// preview reads the original, which such a device may not play.
  ///
  /// A copy that could not be made is recorded on the media
  /// ([MediaAsset.previewCopyFailed]) and not tried again until [retry].

  PreviewCopiesProvider call(String projectId) =>
      PreviewCopiesProvider._(argument: projectId, from: this);

  @override
  String toString() => r'previewCopiesProvider';
}

/// Makes the missing preview copies of the open project, one at a time,
/// in the background. The state is how many are still to make.
///
/// Import makes a copy only when the device decodes the source in
/// hardware; others (4K at 60 fps on a mid-range phone, say) need a
/// software decoder and take minutes, so they are made here instead, as
/// are copies an older import could not make. Until a copy is ready,
/// preview reads the original, which such a device may not play.
///
/// A copy that could not be made is recorded on the media
/// ([MediaAsset.previewCopyFailed]) and not tried again until [retry].

abstract class _$PreviewCopies extends $Notifier<int> {
  late final _$args = ref.$arg as String;
  String get projectId => _$args;

  int build(String projectId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
