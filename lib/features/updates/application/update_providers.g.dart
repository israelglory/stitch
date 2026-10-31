// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appUpdates)
final appUpdatesProvider = AppUpdatesProvider._();

final class AppUpdatesProvider
    extends $FunctionalProvider<AppUpdates, AppUpdates, AppUpdates>
    with $Provider<AppUpdates> {
  AppUpdatesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appUpdatesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appUpdatesHash();

  @$internal
  @override
  $ProviderElement<AppUpdates> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppUpdates create(Ref ref) {
    return appUpdates(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppUpdates value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppUpdates>(value),
    );
  }
}

String _$appUpdatesHash() => r'3f7b5c31a83530431ef44c795a03f577b24eb483';

@ProviderFor(updateSnoozes)
final updateSnoozesProvider = UpdateSnoozesProvider._();

final class UpdateSnoozesProvider
    extends $FunctionalProvider<UpdateSnoozes, UpdateSnoozes, UpdateSnoozes>
    with $Provider<UpdateSnoozes> {
  UpdateSnoozesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateSnoozesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateSnoozesHash();

  @$internal
  @override
  $ProviderElement<UpdateSnoozes> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UpdateSnoozes create(Ref ref) {
    return updateSnoozes(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UpdateSnoozes value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UpdateSnoozes>(value),
    );
  }
}

String _$updateSnoozesHash() => r'71a78ae67db91dbe8a367736f3220ec848b7c152';

/// A newer release to offer the user, looked for once per launch. Null
/// when there is none, or the user put it off recently.

@ProviderFor(PendingUpdate)
final pendingUpdateProvider = PendingUpdateProvider._();

/// A newer release to offer the user, looked for once per launch. Null
/// when there is none, or the user put it off recently.
final class PendingUpdateProvider
    extends $AsyncNotifierProvider<PendingUpdate, StoreUpdate?> {
  /// A newer release to offer the user, looked for once per launch. Null
  /// when there is none, or the user put it off recently.
  PendingUpdateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingUpdateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingUpdateHash();

  @$internal
  @override
  PendingUpdate create() => PendingUpdate();
}

String _$pendingUpdateHash() => r'39708928dda41a83d617a37342a0de403cacb017';

/// A newer release to offer the user, looked for once per launch. Null
/// when there is none, or the user put it off recently.

abstract class _$PendingUpdate extends $AsyncNotifier<StoreUpdate?> {
  FutureOr<StoreUpdate?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<StoreUpdate?>, StoreUpdate?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<StoreUpdate?>, StoreUpdate?>,
              AsyncValue<StoreUpdate?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
