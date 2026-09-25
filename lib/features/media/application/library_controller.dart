import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stitch/app/providers.dart';
import 'package:stitch/features/media/domain/library_item.dart';

part 'library_controller.g.dart';

/// Library access, and whether the system prompt was already shown this
/// session (after a refusal only the system settings can change it).
typedef LibraryAccessState = ({LibraryAccess access, bool asked});

/// Photo library access. Asked for only when the picker opens.
@riverpod
class LibraryAccessController extends _$LibraryAccessController {
  @override
  Future<LibraryAccessState> build() async {
    final library = ref.watch(mediaLibraryProvider);
    final current = await library.access();
    if (current != LibraryAccess.notDetermined) {
      return (access: current, asked: false);
    }
    return (access: await library.requestAccess(), asked: true);
  }

  /// Shows the system prompt ("Allow access").
  Future<void> request() async {
    final access = await ref.read(mediaLibraryProvider).requestAccess();
    state = AsyncData((access: access, asked: true));
    _reloadItems();
  }

  /// Re-checks when the app returns to the foreground: after the system
  /// permission dialog, the system settings, or the camera. Also reloads
  /// the items, since a query made while access was being granted can come
  /// back empty on Android, and new media may have been added meanwhile.
  Future<void> recheck() async {
    final asked = state.value?.asked ?? false;
    final access = await ref.read(mediaLibraryProvider).access();
    state = AsyncData((access: access, asked: asked));
    _reloadItems();
  }

  void _reloadItems() => ref.invalidate(libraryItemsProvider);

  Future<void> openSettings() =>
      ref.read(mediaLibraryProvider).openSystemSettings();

  Future<void> manageSelection() async {
    await ref.read(mediaLibraryProvider).manageLimitedSelection();
    ref.invalidate(libraryItemsProvider);
  }
}

/// A loaded run of library items.
final class LibraryPage {
  const new({
    required this.items,
    required this.hasMore,
    this.loadingMore = false,
  });

  final List<LibraryItem> items;
  final bool hasMore;
  final bool loadingMore;
}

/// Library items for [filter], loaded a page at a time as the grid scrolls.
@riverpod
class LibraryItems extends _$LibraryItems {
  int _page = 0;

  @override
  Future<LibraryPage> build(LibraryFilter filter) async {
    _page = 0;
    final items = await ref.watch(mediaLibraryProvider).items(filter, page: 0);
    return LibraryPage(items: items, hasMore: items.isNotEmpty);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(
      LibraryPage(items: current.items, hasMore: true, loadingMore: true),
    );
    final page = _page;
    final List<LibraryItem> next;
    try {
      next = await ref.read(mediaLibraryProvider).items(filter, page: page + 1);
    } on Object {
      // Scrolling to the end again tries again.
      if (ref.mounted && identical(state.value?.items, current.items)) {
        state = AsyncData(LibraryPage(items: current.items, hasMore: true));
      }
      return;
    }
    // Reloaded meanwhile (back from the background): this page is stale.
    if (!ref.mounted || _page != page) return;
    _page += 1;
    state = AsyncData(
      LibraryPage(items: [...current.items, ...next], hasMore: next.isNotEmpty),
    );
  }
}

/// Items picked in the media picker, in the order they were tapped.
@riverpod
class MediaSelection extends _$MediaSelection {
  @override
  List<LibraryItem> build() => const [];

  /// Adds [item] at the end, or removes it (later items renumber).
  void toggle(LibraryItem item) {
    state = state.contains(item)
        ? [
            for (final i in state)
              if (i != item) i,
          ]
        : [...state, item];
  }

  void clear() => state = const [];

  /// 1-based position of [item], or null when not selected.
  int? orderOf(LibraryItem item) {
    final i = state.indexOf(item);
    return i < 0 ? null : i + 1;
  }
}
