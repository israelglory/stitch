// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'caption_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(speechRecognizer)
final speechRecognizerProvider = SpeechRecognizerProvider._();

final class SpeechRecognizerProvider
    extends
        $FunctionalProvider<
          SpeechRecognizer,
          SpeechRecognizer,
          SpeechRecognizer
        >
    with $Provider<SpeechRecognizer> {
  SpeechRecognizerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'speechRecognizerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$speechRecognizerHash();

  @$internal
  @override
  $ProviderElement<SpeechRecognizer> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SpeechRecognizer create(Ref ref) {
    return speechRecognizer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SpeechRecognizer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SpeechRecognizer>(value),
    );
  }
}

String _$speechRecognizerHash() => r'796d433048f3d315296ebe82d574cc05c10ff389';

/// Models live in the cache folder: kept out of backups, and downloaded
/// again if the system clears them.

@ProviderFor(captionModelStore)
final captionModelStoreProvider = CaptionModelStoreProvider._();

/// Models live in the cache folder: kept out of backups, and downloaded
/// again if the system clears them.

final class CaptionModelStoreProvider
    extends
        $FunctionalProvider<
          CaptionModelStore,
          CaptionModelStore,
          CaptionModelStore
        >
    with $Provider<CaptionModelStore> {
  /// Models live in the cache folder: kept out of backups, and downloaded
  /// again if the system clears them.
  CaptionModelStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'captionModelStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$captionModelStoreHash();

  @$internal
  @override
  $ProviderElement<CaptionModelStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CaptionModelStore create(Ref ref) {
    return captionModelStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CaptionModelStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CaptionModelStore>(value),
    );
  }
}

String _$captionModelStoreHash() => r'854ede547ffad18c1691f1c6575f819d2b12ed68';

/// Each caption model's status, and its download. Downloads carry on
/// while the captions sheet is closed.

@ProviderFor(CaptionModels)
final captionModelsProvider = CaptionModelsProvider._();

/// Each caption model's status, and its download. Downloads carry on
/// while the captions sheet is closed.
final class CaptionModelsProvider
    extends $NotifierProvider<CaptionModels, Map<CaptionModel, ModelStatus>> {
  /// Each caption model's status, and its download. Downloads carry on
  /// while the captions sheet is closed.
  CaptionModelsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'captionModelsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$captionModelsHash();

  @$internal
  @override
  CaptionModels create() => CaptionModels();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<CaptionModel, ModelStatus> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<CaptionModel, ModelStatus>>(
        value,
      ),
    );
  }
}

String _$captionModelsHash() => r'cfc1e55a3f9f8722f0d5924bc29221410b397174';

/// Each caption model's status, and its download. Downloads carry on
/// while the captions sheet is closed.

abstract class _$CaptionModels
    extends $Notifier<Map<CaptionModel, ModelStatus>> {
  Map<CaptionModel, ModelStatus> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              Map<CaptionModel, ModelStatus>,
              Map<CaptionModel, ModelStatus>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                Map<CaptionModel, ModelStatus>,
                Map<CaptionModel, ModelStatus>
              >,
              Map<CaptionModel, ModelStatus>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
