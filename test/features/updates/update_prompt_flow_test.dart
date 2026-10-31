// The update prompt: on the projects screen when the store has a newer
// version. "Update" opens the store page; "Later" keeps it away for a few
// days, but a newer release asks again.
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/app/router.dart';
import 'package:stitch/features/updates/application/update_providers.dart';
import 'package:stitch/features/updates/data/app_updates.dart';
import 'package:stitch/features/updates/domain/store_update.dart';

import '../../helpers/pump.dart';

final class FakeAppUpdates implements AppUpdates {
  new([this.update]);

  StoreUpdate? update;
  int checks = 0;

  @override
  Future<StoreUpdate?> check() async {
    checks++;
    return update;
  }
}

const _release = StoreUpdate(
  id: 'ios:1.2.0',
  storeUrl: 'https://apps.apple.com/app/id123',
  version: '1.2.0',
);

void main() {
  testWidgets('offers a newer version and opens the store', (tester) async {
    final env = await createEnv(tester, updates: FakeAppUpdates(_release));
    await pumpApp(tester, env);

    expect(find.text('Update available'), findsOneWidget);
    expect(
      find.text('Stitch 1.2.0 is ready, with fixes and improvements.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Update'));
    await settle(tester);

    expect(find.text('Update available'), findsNothing);
    expect(env.system.opened, [_release.storeUrl]);
  });

  testWidgets('Later closes it and keeps it away for a few days', (
    tester,
  ) async {
    final env = await createEnv(tester, updates: FakeAppUpdates(_release));
    await pumpApp(tester, env);
    await tester.tap(find.text('Later'));
    await settle(tester);

    expect(find.text('Update available'), findsNothing);
    expect(env.system.opened, isEmpty);
    final snoozes = env.container.read(updateSnoozesProvider);
    expect(snoozes.isSnoozed(_release), isTrue);

    // Next launch: still put off.
    env.container.invalidate(pendingUpdateProvider);
    await settle(tester);
    expect(find.text('Update available'), findsNothing);

    // A newer release asks again.
    expect(
      snoozes.isSnoozed(
        const StoreUpdate(id: 'ios:1.3.0', storeUrl: 'https://x.test'),
      ),
      isFalse,
    );
  });

  testWidgets('without a version number, says a new version is ready', (
    tester,
  ) async {
    const play = StoreUpdate(id: 'android:7', storeUrl: playStoreUrl);
    final env = await createEnv(tester, updates: FakeAppUpdates(play));
    await pumpApp(tester, env);
    expect(
      find.text(
        'A new version of Stitch is ready, with fixes and improvements.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('nothing shows when the app is up to date', (tester) async {
    final updates = FakeAppUpdates();
    final env = await createEnv(tester, updates: updates);
    await pumpApp(tester, env);
    expect(updates.checks, 1);
    expect(find.text('Update available'), findsNothing);
  });

  testWidgets('it does not interrupt other screens', (tester) async {
    final env = await createEnv(tester, updates: FakeAppUpdates(_release));
    await pumpApp(tester, env, location: AppRoutes.settings);
    expect(find.text('Update available'), findsNothing);
  });

  testWidgets('it stays put off across launches', (tester) async {
    final env = await createEnv(tester, updates: FakeAppUpdates(_release));
    await env.container
        .read(updateSnoozesProvider)
        .snooze(_release, PendingUpdate.laterFor);
    await pumpApp(tester, env);
    expect(find.text('Update available'), findsNothing);
  });
}
