import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/features/media/application/library_controller.dart';
import 'package:stitch/features/media/domain/library_item.dart';

import '../../helpers/app_scope.dart';

void main() {
  test('returning to the app reloads the gallery', () async {
    // Found on Android: a query made while access was being granted came
    // back empty, and media added while the picker was open never showed.
    final env = await TestEnv.create();
    final c = env.container;
    final sub = c.listen(libraryItemsProvider(LibraryFilter.videos), (_, _) {});
    addTearDown(sub.close);
    await c.read(libraryAccessControllerProvider.future);
    expect(
      (await c.read(libraryItemsProvider(LibraryFilter.videos).future)).items,
      isEmpty,
    );

    env.library.addVideo('new');
    await c.read(libraryAccessControllerProvider.notifier).recheck();
    final page = await c.read(
      libraryItemsProvider(LibraryFilter.videos).future,
    );
    expect(page.items.map((i) => i.id), ['new']);
  });

  test('granting access reloads the gallery', () async {
    final env = await TestEnv.create();
    env.library.accessState = LibraryAccess.denied;
    final c = env.container;
    final sub = c.listen(libraryItemsProvider(LibraryFilter.videos), (_, _) {});
    addTearDown(sub.close);
    await c.read(libraryAccessControllerProvider.future);
    await c.read(libraryItemsProvider(LibraryFilter.videos).future);

    env.library.addVideo('v');
    await c.read(libraryAccessControllerProvider.notifier).request();
    final state = c.read(libraryAccessControllerProvider).requireValue;
    expect(state.access, LibraryAccess.granted);
    expect(state.asked, isTrue);
    final page = await c.read(
      libraryItemsProvider(LibraryFilter.videos).future,
    );
    expect(page.items, hasLength(1));
  });

  test('selection keeps tap order and renumbers', () async {
    final env = await TestEnv.create();
    final a = env.library.addVideo('a');
    final b = env.library.addVideo('b');
    final c = env.library.addPhoto('c');
    final sub = env.container.listen(mediaSelectionProvider, (_, _) {});
    addTearDown(sub.close);
    env.container.read(mediaSelectionProvider.notifier)
      ..toggle(b)
      ..toggle(a)
      ..toggle(c)
      ..toggle(a);
    final n = env.container.read(mediaSelectionProvider.notifier);
    expect(env.container.read(mediaSelectionProvider), [b, c]);
    expect(n.orderOf(b), 1);
    expect(n.orderOf(c), 2);
    expect(n.orderOf(a), isNull);
  });
}
