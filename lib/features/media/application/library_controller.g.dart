// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Photo library access. Asked for only when the picker opens.

@ProviderFor(LibraryAccessController)
final libraryAccessControllerProvider = LibraryAccessControllerProvider._();

/// Photo library access. Asked for only when the picker opens.
final class LibraryAccessControllerProvider
    extends
        $AsyncNotifierProvider<LibraryAccessController, LibraryAccessState> {
  /// Photo library access. Asked for only when the picker opens.
  LibraryAccessControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'libraryAccessControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$libraryAccessControllerHash();

  @$internal
  @override
  LibraryAccessController create() => LibraryAccessController();
}

String _$libraryAccessControllerHash() =>
    r'1f7ea1cb25def1b9a00bc76a91c87f5a8cf167cf';

/// Photo library access. Asked for only when the picker opens.

abstract class _$LibraryAccessController
    extends $AsyncNotifier<LibraryAccessState> {
  FutureOr<LibraryAccessState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<LibraryAccessState>, LibraryAccessState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<LibraryAccessState>, LibraryAccessState>,
              AsyncValue<LibraryAccessState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Library items for [filter], loaded a page at a time as the grid scrolls.

@ProviderFor(LibraryItems)
final libraryItemsProvider = LibraryItemsFamily._();

/// Library items for [filter], loaded a page at a time as the grid scrolls.
final class LibraryItemsProvider
    extends $AsyncNotifierProvider<LibraryItems, LibraryPage> {
  /// Library items for [filter], loaded a page at a time as the grid scrolls.
  LibraryItemsProvider._({
    required LibraryItemsFamily super.from,
    required LibraryFilter super.argument,
  }) : super(
         retry: null,
         name: r'libraryItemsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$libraryItemsHash();

  @override
  String toString() {
    return r'libraryItemsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  LibraryItems create() => LibraryItems();

  @override
  bool operator ==(Object other) {
    return other is LibraryItemsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$libraryItemsHash() => r'b2d79f42a5b24cc2dfad0f5b61013ff0560bdc93';

/// Library items for [filter], loaded a page at a time as the grid scrolls.

final class LibraryItemsFamily extends $Family
    with
        $ClassFamilyOverride<
          LibraryItems,
          AsyncValue<LibraryPage>,
          LibraryPage,
          FutureOr<LibraryPage>,
          LibraryFilter
        > {
  LibraryItemsFamily._()
    : super(
        retry: null,
        name: r'libraryItemsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Library items for [filter], loaded a page at a time as the grid scrolls.

  LibraryItemsProvider call(LibraryFilter filter) =>
      LibraryItemsProvider._(argument: filter, from: this);

  @override
  String toString() => r'libraryItemsProvider';
}

/// Library items for [filter], loaded a page at a time as the grid scrolls.

abstract class _$LibraryItems extends $AsyncNotifier<LibraryPage> {
  late final _$args = ref.$arg as LibraryFilter;
  LibraryFilter get filter => _$args;

  FutureOr<LibraryPage> build(LibraryFilter filter);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<LibraryPage>, LibraryPage>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<LibraryPage>, LibraryPage>,
              AsyncValue<LibraryPage>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// Items picked in the media picker, in the order they were tapped.

@ProviderFor(MediaSelection)
final mediaSelectionProvider = MediaSelectionProvider._();

/// Items picked in the media picker, in the order they were tapped.
final class MediaSelectionProvider
    extends $NotifierProvider<MediaSelection, List<LibraryItem>> {
  /// Items picked in the media picker, in the order they were tapped.
  MediaSelectionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mediaSelectionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mediaSelectionHash();

  @$internal
  @override
  MediaSelection create() => MediaSelection();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<LibraryItem> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<LibraryItem>>(value),
    );
  }
}

String _$mediaSelectionHash() => r'6b92ee2916bd24b956ef16bb382c94cc9fe002ea';

/// Items picked in the media picker, in the order they were tapped.

abstract class _$MediaSelection extends $Notifier<List<LibraryItem>> {
  List<LibraryItem> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<LibraryItem>, List<LibraryItem>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<LibraryItem>, List<LibraryItem>>,
              List<LibraryItem>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
