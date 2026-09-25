import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/app/splash.dart';

void main() {
  testWidgets('the logo shows, then fades to the app', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: SplashOverlay(child: Text('Home')),
      ),
    );
    // Real image decoding happens outside the fake clock.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsNothing);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('the logo follows the system dark mode', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(platformBrightness: Brightness.dark),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SplashOverlay(child: SizedBox()),
        ),
      ),
    );
    final image = tester.widget<Image>(find.byType(Image)).image;
    expect((image as AssetImage).assetName, 'assets/splash/logo_dark.png');
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  });
}
