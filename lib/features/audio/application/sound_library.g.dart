// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sound_library.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Downloaded library sounds, kept when the cache is cleared (see
/// storage.dart).

@ProviderFor(soundLibraryStore)
final soundLibraryStoreProvider = SoundLibraryStoreProvider._();

/// Downloaded library sounds, kept when the cache is cleared (see
/// storage.dart).

final class SoundLibraryStoreProvider
    extends
        $FunctionalProvider<
          SoundLibraryStore,
          SoundLibraryStore,
          SoundLibraryStore
        >
    with $Provider<SoundLibraryStore> {
  /// Downloaded library sounds, kept when the cache is cleared (see
  /// storage.dart).
  SoundLibraryStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'soundLibraryStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$soundLibraryStoreHash();

  @$internal
  @override
  $ProviderElement<SoundLibraryStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SoundLibraryStore create(Ref ref) {
    return soundLibraryStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SoundLibraryStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SoundLibraryStore>(value),
    );
  }
}

String _$soundLibraryStoreHash() => r'675f000e5f6482d269a93aeaf7e4ea66d205894a';

/// The catalog the app ships, used until a newer one is fetched (and
/// offline). Tests override it.

@ProviderFor(shippedSoundCatalog)
final shippedSoundCatalogProvider = ShippedSoundCatalogProvider._();

/// The catalog the app ships, used until a newer one is fetched (and
/// offline). Tests override it.

final class ShippedSoundCatalogProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// The catalog the app ships, used until a newer one is fetched (and
  /// offline). Tests override it.
  ShippedSoundCatalogProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shippedSoundCatalogProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shippedSoundCatalogHash();

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    return shippedSoundCatalog(ref);
  }
}

String _$shippedSoundCatalogHash() =>
    r'b2727858135aa336a61d90d170573bedf33f9986';

/// The online library: its catalog (the newest is fetched once per run of
/// the app) and downloads, at most [_parallel] at a time.

@ProviderFor(SoundLibrary)
final soundLibraryProvider = SoundLibraryProvider._();

/// The online library: its catalog (the newest is fetched once per run of
/// the app) and downloads, at most [_parallel] at a time.
final class SoundLibraryProvider
    extends $NotifierProvider<SoundLibrary, SoundLibraryState> {
  /// The online library: its catalog (the newest is fetched once per run of
  /// the app) and downloads, at most [_parallel] at a time.
  SoundLibraryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'soundLibraryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$soundLibraryHash();

  @$internal
  @override
  SoundLibrary create() => SoundLibrary();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SoundLibraryState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SoundLibraryState>(value),
    );
  }
}

String _$soundLibraryHash() => r'd61085509275e7e47274f4552f76d1d8c2676b41';

/// The online library: its catalog (the newest is fetched once per run of
/// the app) and downloads, at most [_parallel] at a time.

abstract class _$SoundLibrary extends $Notifier<SoundLibraryState> {
  SoundLibraryState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SoundLibraryState, SoundLibraryState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SoundLibraryState, SoundLibraryState>,
              SoundLibraryState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
