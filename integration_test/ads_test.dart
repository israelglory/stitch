// Live ads on a device or simulator, with Google's test ad units (debug
// builds): the banner under the projects loads, and a full-screen ad
// loads and shows. Needs a network connection. The ad is left open; the
// host can screenshot it when the log says "ADS: interstitial showing".
//
//   flutter test integration_test/ads_test.dart -d <device>
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:integration_test/integration_test.dart';
import 'package:stitch/app/app.dart';
import 'package:stitch/app/bootstrap.dart';
import 'package:stitch/app/providers.dart';
import 'package:stitch/features/ads/admob_ads.dart';
import 'package:stitch/features/analytics/analytics.dart';
import 'package:stitch/features/projects/presentation/projects_screen.dart';

Future<void> waitUntil(
  WidgetTester tester,
  bool Function() done, {
  required String reason,
  Duration timeout = const Duration(seconds: 90),
}) async {
  final end = DateTime.now().add(timeout);
  while (!done()) {
    if (DateTime.now().isAfter(end)) fail('Timed out: $reason');
    await tester.pump(const Duration(milliseconds: 200));
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // A screenshot of the banner, where an iOS simulator can write it (pass
  // --dart-define=STITCH_ADS_SHOT=/tmp/banner.png).
  const shot = String.fromEnvironment('STITCH_ADS_SHOT');

  testWidgets('the banner loads and a full-screen ad shows', (tester) async {
    await bootstrap(
      installErrorHandlers: false,
      overrides: [analyticsProvider.overrideWithValue(const NoAnalytics())],
    );
    await waitUntil(
      tester,
      () => find.byType(StitchApp).evaluate().isNotEmpty,
      reason: 'the app starts',
    );
    await tester.pump(const Duration(seconds: 2));
    if (find.text('Skip').evaluate().isNotEmpty) {
      await tester.tap(find.text('Skip'));
      await tester.pump(const Duration(seconds: 1));
    }
    await waitUntil(
      tester,
      () => find.byType(ProjectsScreen).evaluate().isNotEmpty,
      reason: 'the projects screen',
    );
    await waitUntil(
      tester,
      () => find.byType(AdWidget).evaluate().isNotEmpty,
      reason: 'the banner loads',
    );
    final banner = tester.getRect(find.byType(AdWidget));
    final screen = tester.getRect(find.byType(ProjectsScreen));
    expect(banner.height, greaterThan(40));
    expect(
      screen.bottom - banner.bottom,
      lessThan(60),
      reason: 'at the bottom',
    );
    // The host screenshots on this line.
    // ignore: avoid_print
    print('ADS: banner showing');
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    // On iOS only: Android screenshots need the driver.
    if (shot.isNotEmpty && Platform.isIOS) {
      File(shot).writeAsBytesSync(await binding.takeScreenshot('banner'));
    }

    final ads = ProviderScope.containerOf(
      tester.element(find.byType(StitchApp)),
    ).read(adsProvider) as AdMobAds;
    await waitUntil(
      tester,
      () => ads.interstitialReady,
      reason: 'a full-screen ad loads',
    );
    var closed = false;
    ads.showInterstitial().then((_) => closed = true).ignore();
    await tester.pump(const Duration(seconds: 3));
    expect(ads.interstitialReady, isFalse, reason: 'it is showing');
    expect(closed, isFalse);
    // The host screenshots on this line.
    // ignore: avoid_print
    print('ADS: interstitial showing');
    await tester.pump(const Duration(seconds: 15));
  });
}
