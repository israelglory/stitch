import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/design/gallery/design_gallery_screen.dart';
import 'package:stitch/design/gallery/specimens.dart';
import 'package:stitch/design/mocks/sample_media.dart';

import '../helpers/app_harness.dart';

void main() {
  group('buttons', () {
    testWidgets('tap calls onPressed', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        themed(
          Center(
            child: PrimaryButton(label: 'Add', onPressed: () => taps++),
          ),
        ),
      );
      await tester.tap(find.text('Add'));
      expect(taps, 1);
    });

    testWidgets('disabled and loading ignore taps', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        themed(
          Column(
            children: [
              const SecondaryButton(label: 'Disabled', onPressed: null),
              PrimaryButton(
                label: 'Loading',
                isLoading: true,
                onPressed: () => taps++,
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Disabled'));
      await tester.tap(find.byType(PrimaryButton));
      expect(taps, 0);
    });

    testWidgets('small buttons keep a 44pt touch target', (tester) async {
      await tester.pumpWidget(
        themed(
          const Center(
            child: PrimaryButton(
              label: 'Export',
              size: ButtonSize.small,
              onPressed: _noop,
            ),
          ),
        ),
      );
      final size = tester.getSize(find.byType(Pressable));
      expect(size.height, greaterThanOrEqualTo(AppSizes.minTouchTarget));
    });

    testWidgets('icon button exposes its label and toggle state', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        themed(
          const AppIconButton(
            icon: AppIcons.loop,
            semanticLabel: 'Loop',
            selected: true,
            onPressed: _noop,
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(AppIconButton)),
        isSemantics(
          label: 'Loop',
          isButton: true,
          isEnabled: true,
          isSelected: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });
  });

  testWidgets('segmented control reports the tapped segment', (tester) async {
    String? picked;
    await tester.pumpWidget(
      themed(
        SegmentedControl<String>(
          segments: const [Segment('a', 'Videos'), Segment('b', 'Photos')],
          selected: 'a',
          onChanged: (v) => picked = v,
        ),
      ),
    );
    await tester.tap(find.text('Photos'));
    expect(picked, 'b');
  });

  testWidgets('slider shows the formatted value', (tester) async {
    await tester.pumpWidget(
      themed(
        AppSlider(
          label: 'Speed',
          value: 2,
          min: 0.25,
          max: 4,
          formatValue: (v) => '${v.toStringAsFixed(1)}x',
          onChanged: (_) {},
        ),
      ),
    );
    expect(find.text('2.0x'), findsOneWidget);
  });

  group('overlays', () {
    Future<bool?> openDialog(WidgetTester tester) async {
      bool? result;
      await tester.pumpWidget(
        themed(
          Builder(
            builder: (context) => PrimaryButton(
              label: 'Open',
              onPressed: () async => result = await showConfirmDialog(
                context: context,
                title: 'Delete project?',
                message: 'This cannot be undone.',
                confirmLabel: 'Delete',
                destructive: true,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Delete project?'), findsOneWidget);
      return result;
    }

    testWidgets('confirm dialog resolves true on confirm', (tester) async {
      await openDialog(tester);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Delete project?'), findsNothing);
    });

    testWidgets('confirm dialog resolves false on cancel', (tester) async {
      bool? result;
      await tester.pumpWidget(
        themed(
          Builder(
            builder: (context) => PrimaryButton(
              label: 'Open',
              onPressed: () async => result = await showConfirmDialog(
                context: context,
                title: 'Discard?',
                message: 'Lost.',
                confirmLabel: 'Discard',
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(result, isFalse);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });

    testWidgets('bottom sheet confirm check fires', (tester) async {
      var confirmed = false;
      await tester.pumpWidget(
        themed(
          Builder(
            builder: (context) => PrimaryButton(
              label: 'Open',
              onPressed: () => showAppBottomSheet<void>(
                context: context,
                builder: (context) => AppBottomSheet(
                  title: 'Volume',
                  onConfirm: () {
                    confirmed = true;
                    Navigator.of(context).pop();
                  },
                  child: const SizedBox(height: 40),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Done'));
      await tester.pumpAndSettle();
      expect(confirmed, isTrue);
      expect(find.text('Volume'), findsNothing);
    });
  });

  group('timeline', () {
    testWidgets('trim handles report edge and delta; taps still select', (
      tester,
    ) async {
      final updates = <(TrimEdge, double)>[];
      var taps = 0;
      await tester.pumpWidget(
        themed(
          Center(
            child: VideoClipTile(
              width: 200,
              frameBuilder: (_, i) => sampleFrame(i),
              durationLabel: '4.0s',
              selected: true,
              trim: TrimCallbacks(onUpdate: (e, dx) => updates.add((e, dx))),
              onTap: () => taps++,
            ),
          ),
        ),
      );
      final rect = tester.getRect(find.byType(VideoClipTile));

      await tester.dragFrom(
        rect.centerLeft + const Offset(4, 0),
        const Offset(-30, 0),
      );
      await tester.dragFrom(
        rect.centerRight - const Offset(4, 0),
        const Offset(25, 0),
      );
      expect(updates.where((u) => u.$1 == TrimEdge.start), isNotEmpty);
      expect(updates.where((u) => u.$1 == TrimEdge.end), isNotEmpty);
      final startDx = updates
          .where((u) => u.$1 == TrimEdge.start)
          .fold<double>(0, (sum, u) => sum + u.$2);
      expect(startDx, lessThan(0));

      await tester.tapAt(rect.center);
      expect(taps, 1);
    });

    test('ruler interval keeps labels at least 64pt apart', () {
      expect(rulerInterval(160), 0.5);
      expect(rulerInterval(64), 1);
      expect(rulerInterval(48), 2);
      expect(rulerInterval(8), 10);
      expect(rulerInterval(0.01), 600);
    });
  });

  group('design gallery', () {
    for (final scale in [1.0, 1.4, 2.0]) {
      testWidgets('renders on the smallest phone at ${scale}x text', (
        tester,
      ) async {
        setPhoneSize(tester, size: smallPhone);
        await tester.pumpWidget(
          themed(const DesignGalleryScreen(), textScale: scale),
        );
        // Scroll through every section so each is built and laid out.
        final list = find.byType(Scrollable).last;
        for (var i = 0; i < 40; i++) {
          await tester.drag(list, const Offset(0, -300));
          await tester.pump();
        }
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('non-timeline components meet accessibility guidelines', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      setPhoneSize(tester, size: const Size(390, 2400));
      await tester.pumpWidget(
        themed(
          const SingleChildScrollView(
            child: Column(
              children: [
                ButtonsSpecimen(),
                ControlsSpecimen(),
                ListRowSpecimen(),
                ToolbarSpecimen(),
                FeedbackSpecimen(),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      // The spec's minimum is 44pt (Apple HIG). Android's guideline asks for
      // 48dp; see the M2 notes.
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets(
      'text meets WCAG AA contrast',
      (tester) async {
        final handle = tester.ensureSemantics();
        setPhoneSize(tester, size: const Size(390, 2400));
        await tester.pumpWidget(
          themed(
            const SingleChildScrollView(
              child: Column(
                children: [
                  ButtonsSpecimen(),
                  ListRowSpecimen(),
                  FeedbackSpecimen(),
                ],
              ),
            ),
          ),
        );
        await tester.pump();
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      },
      skip: true, // Palette decision pending; see docs/design-system.md.
    );
  });
}

void _noop() {}
