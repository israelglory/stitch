import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/design/theme.dart';
import 'package:stitch/l10n/generated/app_localizations.dart';

/// Wraps [child] in the app theme and localizations.
Widget themed(Widget child, {double textScale = 1}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.dark(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: Scaffold(body: child),
);

/// Sets the test surface to a phone size. iPhone 15 by default.
void setPhoneSize(WidgetTester tester, {Size size = const Size(390, 844)}) {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// iPhone SE (1st gen), the smallest supported screen.
const smallPhone = Size(320, 568);
