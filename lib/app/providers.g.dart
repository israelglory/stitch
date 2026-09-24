// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Key-value store for small app preferences. Loaded once in bootstrap and
/// injected with an override, so reads are synchronous everywhere else.

@ProviderFor(sharedPreferences)
final sharedPreferencesProvider = SharedPreferencesProvider._();

/// Key-value store for small app preferences. Loaded once in bootstrap and
/// injected with an override, so reads are synchronous everywhere else.

final class SharedPreferencesProvider
    extends
        $FunctionalProvider<
          SharedPreferencesWithCache,
          SharedPreferencesWithCache,
          SharedPreferencesWithCache
        >
    with $Provider<SharedPreferencesWithCache> {
  /// Key-value store for small app preferences. Loaded once in bootstrap and
  /// injected with an override, so reads are synchronous everywhere else.
  SharedPreferencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sharedPreferencesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sharedPreferencesHash();

  @$internal
  @override
  $ProviderElement<SharedPreferencesWithCache> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SharedPreferencesWithCache create(Ref ref) {
    return sharedPreferences(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SharedPreferencesWithCache value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SharedPreferencesWithCache>(value),
    );
  }
}

String _$sharedPreferencesHash() => r'1beefc55cd3fd5808086989fa8f93b6f6ed001a4';

/// App-private folder holding all projects. Overridden in bootstrap with
/// the documents directory, and in tests with a temp directory.

@ProviderFor(storageRoot)
final storageRootProvider = StorageRootProvider._();

/// App-private folder holding all projects. Overridden in bootstrap with
/// the documents directory, and in tests with a temp directory.

final class StorageRootProvider
    extends $FunctionalProvider<Directory, Directory, Directory>
    with $Provider<Directory> {
  /// App-private folder holding all projects. Overridden in bootstrap with
  /// the documents directory, and in tests with a temp directory.
  StorageRootProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'storageRootProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$storageRootHash();

  @$internal
  @override
  $ProviderElement<Directory> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Directory create(Ref ref) {
    return storageRoot(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Directory value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Directory>(value),
    );
  }
}

String _$storageRootHash() => r'69bb08ba0ac3057160a3e1774353dddfa396eaee';

@ProviderFor(idGenerator)
final idGeneratorProvider = IdGeneratorProvider._();

final class IdGeneratorProvider
    extends $FunctionalProvider<IdGenerator, IdGenerator, IdGenerator>
    with $Provider<IdGenerator> {
  IdGeneratorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'idGeneratorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$idGeneratorHash();

  @$internal
  @override
  $ProviderElement<IdGenerator> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  IdGenerator create(Ref ref) {
    return idGenerator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IdGenerator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IdGenerator>(value),
    );
  }
}

String _$idGeneratorHash() => r'33d878f6e343af1c672e0184b3b113cc4ea75cb3';

@ProviderFor(clock)
final clockProvider = ClockProvider._();

final class ClockProvider extends $FunctionalProvider<Clock, Clock, Clock>
    with $Provider<Clock> {
  ClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clockProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clockHash();

  @$internal
  @override
  $ProviderElement<Clock> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Clock create(Ref ref) {
    return clock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Clock value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Clock>(value),
    );
  }
}

String _$clockHash() => r'b2969fc7f5261f62137e0cfbaf5eccd68cd4516e';

@ProviderFor(projectStore)
final projectStoreProvider = ProjectStoreProvider._();

final class ProjectStoreProvider
    extends $FunctionalProvider<ProjectStore, ProjectStore, ProjectStore>
    with $Provider<ProjectStore> {
  ProjectStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'projectStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$projectStoreHash();

  @$internal
  @override
  $ProviderElement<ProjectStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ProjectStore create(Ref ref) {
    return projectStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProjectStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProjectStore>(value),
    );
  }
}

String _$projectStoreHash() => r'f0602ab456edbf2a7003f9306021a8540b9b5956';

@ProviderFor(mediaLibrary)
final mediaLibraryProvider = MediaLibraryProvider._();

final class MediaLibraryProvider
    extends $FunctionalProvider<MediaLibrary, MediaLibrary, MediaLibrary>
    with $Provider<MediaLibrary> {
  MediaLibraryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mediaLibraryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mediaLibraryHash();

  @$internal
  @override
  $ProviderElement<MediaLibrary> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MediaLibrary create(Ref ref) {
    return mediaLibrary(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MediaLibrary value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MediaLibrary>(value),
    );
  }
}

String _$mediaLibraryHash() => r'6fb2e2c1dbf87a531842a81c5c25390ae34e605d';

@ProviderFor(mediaImporter)
final mediaImporterProvider = MediaImporterProvider._();

final class MediaImporterProvider
    extends $FunctionalProvider<MediaImporter, MediaImporter, MediaImporter>
    with $Provider<MediaImporter> {
  MediaImporterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mediaImporterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mediaImporterHash();

  @$internal
  @override
  $ProviderElement<MediaImporter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MediaImporter create(Ref ref) {
    return mediaImporter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MediaImporter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MediaImporter>(value),
    );
  }
}

String _$mediaImporterHash() => r'59fc5888359dfcb0596f923640e7220000cff805';

/// App cache folder (thumbnails, filmstrips). Overridden in bootstrap and
/// in tests. Everything in it can be deleted and regenerated.

@ProviderFor(cacheRoot)
final cacheRootProvider = CacheRootProvider._();

/// App cache folder (thumbnails, filmstrips). Overridden in bootstrap and
/// in tests. Everything in it can be deleted and regenerated.

final class CacheRootProvider
    extends $FunctionalProvider<Directory, Directory, Directory>
    with $Provider<Directory> {
  /// App cache folder (thumbnails, filmstrips). Overridden in bootstrap and
  /// in tests. Everything in it can be deleted and regenerated.
  CacheRootProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cacheRootProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cacheRootHash();

  @$internal
  @override
  $ProviderElement<Directory> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Directory create(Ref ref) {
    return cacheRoot(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Directory value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Directory>(value),
    );
  }
}

String _$cacheRootHash() => r'6d18022b9e263bf1084535ee1ebb4baa461ffb18';
