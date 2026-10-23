// Where ads show: a banner pinned under the projects, and a full-screen
// ad before captions are made and before an export, each going on once
// the ad is closed. A fake stands in for AdMob.
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/app/router.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/features/ads/ads.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';
import 'package:stitch/features/export/presentation/export_screen.dart';

import '../helpers/pump.dart';

/// Records what the app asks of the ads; full-screen ads stay open until
/// [close].
final class FakeAds implements Ads {
  int starts = 0;
  int interstitials = 0;
  int privacyShown = 0;
  bool privacyRequired = false;
  Completer<void>? _open;

  void close() => _open?.complete();

  @override
  Future<void> start() async => starts++;

  @override
  Widget banner() =>
      const SizedBox(key: Key('ad-banner'), height: 50, width: 320);

  @override
  Future<void> showInterstitial() {
    interstitials++;
    return (_open = Completer<void>()).future;
  }

  @override
  Future<bool> privacyChoicesRequired() async => privacyRequired;

  @override
  Future<void> showPrivacyChoices() async => privacyShown++;
}

void main() {
  testWidgets('a banner is pinned under the projects', (tester) async {
    final ads = FakeAds();
    final env = await createEnv(tester, ads: ads);
    await createProject(tester, env);
    await pumpApp(tester, env);
    final banner = tester.getRect(find.byKey(const Key('ad-banner')));
    expect(banner.bottom, 844, reason: 'at the bottom of the screen');
    final project = tester.getRect(find.text('Beach day'));
    expect(project.bottom, lessThan(banner.top));
  });

  testWidgets('an export starts once its full-screen ad is closed', (
    tester,
  ) async {
    final ads = FakeAds();
    final env = await createEnv(tester, ads: ads);
    final id = await createProject(tester, env);
    await pumpApp(tester, env, location: AppRoutes.editor(id));
    await settleUntil(tester, find.byType(VideoClipTile));
    await tester.tap(find.widgetWithText(PrimaryButton, 'Export'));
    await settle(tester);
    await tester.tap(find.widgetWithText(PrimaryButton, 'Export').last);
    await settle(tester);
    expect(ads.interstitials, 1);
    expect(find.byType(ExportScreen), findsNothing);

    ads.close();
    await settleUntil(tester, find.byType(ExportScreen));
    await settleUntil(tester, find.text('Saved to Photos'));
    await tester.tap(find.text('Back to editing'));
    await settle(tester);
    await tester.pump(autosaveDelay * 2);
    await settle(tester);
  });

  testWidgets('captions start once their full-screen ad is closed', (
    tester,
  ) async {
    final ads = FakeAds();
    final env = await createEnv(tester, ads: ads);
    final id = await createProject(tester, env);
    await pumpApp(tester, env, location: AppRoutes.editor(id));
    await settleUntil(tester, find.byType(VideoClipTile));
    await tester.ensureVisible(find.text('Captions'));
    await tester.pump();
    await tester.tap(find.text('Captions'));
    await settle(tester);
    await tester.tap(find.widgetWithText(PrimaryButton, 'Generate captions'));
    await settle(tester);
    expect(ads.interstitials, 1);
    expect(find.textContaining('Generating captions'), findsNothing);

    ads.close();
    await settleUntil(tester, find.textContaining('Generating captions'));
    for (var i = 0; i < 100; i++) {
      if (find.textContaining('Generating captions').evaluate().isEmpty) {
        break;
      }
      await settle(tester, rounds: 1);
    }
    await tester.pump(const Duration(seconds: 1));
    await settle(tester);
  });

  testWidgets('settings offers ad privacy choices where required', (
    tester,
  ) async {
    final ads = FakeAds()..privacyRequired = true;
    final env = await createEnv(tester, ads: ads);
    await pumpApp(tester, env, location: AppRoutes.settings);
    await tester.scrollUntilVisible(find.text('Ad privacy choices'), 200);
    await tester.tap(find.text('Ad privacy choices'));
    await settle(tester);
    expect(ads.privacyShown, 1);
  });

  testWidgets('without the requirement, settings has no such row', (
    tester,
  ) async {
    final env = await createEnv(tester, ads: FakeAds());
    await pumpApp(tester, env, location: AppRoutes.settings);
    await tester.scrollUntilVisible(find.text('Version'), 200);
    expect(find.text('Ad privacy choices'), findsNothing);
  });
}
