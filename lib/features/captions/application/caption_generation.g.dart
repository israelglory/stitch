// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'caption_generation.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Makes captions for a project in the background while editing goes on.
/// Lives while the editor shows it; closing the editor cancels it.

@ProviderFor(CaptionGeneration)
final captionGenerationProvider = CaptionGenerationFamily._();

/// Makes captions for a project in the background while editing goes on.
/// Lives while the editor shows it; closing the editor cancels it.
final class CaptionGenerationProvider
    extends $NotifierProvider<CaptionGeneration, CaptionJob> {
  /// Makes captions for a project in the background while editing goes on.
  /// Lives while the editor shows it; closing the editor cancels it.
  CaptionGenerationProvider._({
    required CaptionGenerationFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'captionGenerationProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$captionGenerationHash();

  @override
  String toString() {
    return r'captionGenerationProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CaptionGeneration create() => CaptionGeneration();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CaptionJob value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CaptionJob>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CaptionGenerationProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$captionGenerationHash() => r'4a8da1244d360ef42305b58c43ce5a48dad3c6c4';

/// Makes captions for a project in the background while editing goes on.
/// Lives while the editor shows it; closing the editor cancels it.

final class CaptionGenerationFamily extends $Family
    with
        $ClassFamilyOverride<
          CaptionGeneration,
          CaptionJob,
          CaptionJob,
          CaptionJob,
          String
        > {
  CaptionGenerationFamily._()
    : super(
        retry: null,
        name: r'captionGenerationProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Makes captions for a project in the background while editing goes on.
  /// Lives while the editor shows it; closing the editor cancels it.

  CaptionGenerationProvider call(String projectId) =>
      CaptionGenerationProvider._(argument: projectId, from: this);

  @override
  String toString() => r'captionGenerationProvider';
}

/// Makes captions for a project in the background while editing goes on.
/// Lives while the editor shows it; closing the editor cancels it.

abstract class _$CaptionGeneration extends $Notifier<CaptionJob> {
  late final _$args = ref.$arg as String;
  String get projectId => _$args;

  CaptionJob build(String projectId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CaptionJob, CaptionJob>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CaptionJob, CaptionJob>,
              CaptionJob,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
