// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storage.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Measured on a background isolate; refresh by invalidating.

@ProviderFor(storageUse)
final storageUseProvider = StorageUseProvider._();

/// Measured on a background isolate; refresh by invalidating.

final class StorageUseProvider
    extends
        $FunctionalProvider<
          AsyncValue<StorageUse>,
          StorageUse,
          FutureOr<StorageUse>
        >
    with $FutureModifier<StorageUse>, $FutureProvider<StorageUse> {
  /// Measured on a background isolate; refresh by invalidating.
  StorageUseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'storageUseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$storageUseHash();

  @$internal
  @override
  $FutureProviderElement<StorageUse> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<StorageUse> create(Ref ref) {
    return storageUse(ref);
  }
}

String _$storageUseHash() => r'dc30b7ec7466a6699f63c10e0fdc431e86911646';

@ProviderFor(cacheCleaner)
final cacheCleanerProvider = CacheCleanerProvider._();

final class CacheCleanerProvider
    extends $FunctionalProvider<CacheCleaner, CacheCleaner, CacheCleaner>
    with $Provider<CacheCleaner> {
  CacheCleanerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cacheCleanerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cacheCleanerHash();

  @$internal
  @override
  $ProviderElement<CacheCleaner> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CacheCleaner create(Ref ref) {
    return cacheCleaner(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CacheCleaner value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CacheCleaner>(value),
    );
  }
}

String _$cacheCleanerHash() => r'a2dda30432279b35d5417d05f04034e7aa3f5964';
