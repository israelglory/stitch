@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/design/gallery/specimens.dart';
import 'package:stitch/design/tokens.dart';

import '../helpers/app_harness.dart';

const double _width = 390;
const Key _boundaryKey = ValueKey('golden');

/// Renders [specimen] at phone width and compares it with
/// `goldens/<name>.png`. The image is cropped to the specimen's height.
Future<void> _expectGolden(
  WidgetTester tester,
  String name,
  Widget specimen, {
  double textScale = 1,
}) async {
  setPhoneSize(tester, size: const Size(_width, 2400));
  await tester.pumpWidget(
    themed(
      SingleChildScrollView(
        child: RepaintBoundary(
          key: _boundaryKey,
          child: Builder(
            builder: (context) => ColoredBox(
              color: context.colors.background,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: specimen,
              ),
            ),
          ),
        ),
      ),
      textScale: textScale,
    ),
  );
  // Indeterminate progress and skeletons animate forever; capture the first
  // frame instead of settling.
  await tester.pump();
  await expectLater(
    find.byKey(_boundaryKey),
    matchesGoldenFile('goldens/$name.png'),
  );
}

void main() {
  final specimens = <String, Widget Function()>{
    'colors': ColorsSpecimen.new,
    'typography': TypographySpecimen.new,
    'icons': IconsSpecimen.new,
    'buttons': ButtonsSpecimen.new,
    'controls': ControlsSpecimen.new,
    'list_rows': ListRowSpecimen.new,
    'toolbar': ToolbarSpecimen.new,
    'media': MediaSpecimen.new,
    'progress': ProgressSpecimen.new,
    'feedback': FeedbackSpecimen.new,
    'bottom_sheet': SheetSpecimen.new,
    'confirm_dialog': DialogSpecimen.new,
    'timeline': TimelineSpecimen.new,
    'headers': HeaderSpecimen.new,
    'choices': ChoicesSpecimen.new,
    'audio': AudioSpecimen.new,
    'transition_previews': () =>
        const TransitionPreviewSpecimen(animate: false),
    'mocks': MocksSpecimen.new,
  };

  for (final MapEntry(key: name, value: build) in specimens.entries) {
    testWidgets(name, (tester) => _expectGolden(tester, name, build()));
  }

  // Large system text on the components that carry text.
  const largeText = [
    'buttons',
    'controls',
    'list_rows',
    'toolbar',
    'media',
    'feedback',
    'bottom_sheet',
    'confirm_dialog',
    'timeline',
    'headers',
    'choices',
  ];
  for (final name in largeText) {
    testWidgets(
      '$name at 200% text',
      (tester) => _expectGolden(
        tester,
        '${name}_text200',
        specimens[name]!(),
        textScale: 2,
      ),
    );
  }
}
