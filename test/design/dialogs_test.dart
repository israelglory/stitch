import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/design/design.dart';

import '../helpers/app_harness.dart';

/// Dialog routes have no Material above them. Without one of their own,
/// text falls back to the app's error style: yellow, double underlined.
void _expectStyledText(WidgetTester tester, String text) {
  final style = DefaultTextStyle.of(tester.element(find.text(text))).style;
  expect(
    style.decorationStyle,
    isNot(TextDecorationStyle.double),
    reason: text,
  );
  expect(style.decoration, isNot(TextDecoration.underline), reason: text);
}

void main() {
  testWidgets('confirm and notice dialogs have a text style of their own', (
    tester,
  ) async {
    await tester.pumpWidget(
      themed(
        Builder(
          builder: (context) => Column(
            children: [
              TextButton(
                onPressed: () => showConfirmDialog(
                  context: context,
                  title: 'Delete project?',
                  message: 'This cannot be undone.',
                  confirmLabel: 'Delete',
                  destructive: true,
                ),
                child: const Text('confirm'),
              ),
              TextButton(
                onPressed: () => showNoticeDialog(
                  context: context,
                  title: 'Import failed',
                  message: 'Try again.',
                  buttonLabel: 'OK',
                ),
                child: const Text('notice'),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('confirm'));
    await tester.pumpAndSettle();
    for (final text in ['Delete project?', 'This cannot be undone.']) {
      _expectStyledText(tester, text);
    }
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('notice'));
    await tester.pumpAndSettle();
    for (final text in ['Import failed', 'Try again.']) {
      _expectStyledText(tester, text);
    }
  });
}
