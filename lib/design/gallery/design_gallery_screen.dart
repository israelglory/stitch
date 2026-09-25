// Developer screen, only routable in debug and profile builds. Text here
// is not user-facing and is not localized.
import 'package:flutter/material.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/design/gallery/specimens.dart';

/// Every design component in every state, for review.
class DesignGalleryScreen extends StatefulWidget {
  const new({super.key});

  @override
  State<DesignGalleryScreen> createState() => _DesignGalleryScreenState();
}

enum _TextSize { normal, large, largest }

class _DesignGalleryScreenState extends State<DesignGalleryScreen> {
  _TextSize _textSize = _TextSize.normal;

  static const Map<_TextSize, double> _scales = {
    _TextSize.normal: 1.0,
    _TextSize.large: 1.4,
    _TextSize.largest: 2.0,
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sections = <(String, Widget)>[
      ('Colors', const ColorsSpecimen()),
      ('Typography', const TypographySpecimen()),
      ('Icons', const IconsSpecimen()),
      ('Buttons', const ButtonsSpecimen()),
      ('Controls', const ControlsSpecimen()),
      ('List rows', const ListRowSpecimen()),
      ('Context toolbar', const ToolbarSpecimen()),
      ('Media', const MediaSpecimen()),
      ('Progress and loading', const ProgressSpecimen()),
      ('Empty and error', const FeedbackSpecimen()),
      ('Bottom sheet', const _SheetSection()),
      ('Confirm dialog', const _DialogSection()),
      ('Headers', const HeaderSpecimen()),
      ('Choices', const ChoicesSpecimen()),
      ('Audio', const AudioSpecimen()),
      ('Transition previews', const TransitionPreviewSpecimen()),
      ('Timeline', const TimelineSpecimen()),
      ('Onboarding mock-ups', const MocksSpecimen()),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: AppSpacing.xs,
                end: AppSpacing.screen,
              ),
              child: Row(
                children: [
                  AppIconButton(
                    icon: AppIcons.back,
                    semanticLabel: 'Back',
                    onPressed: Navigator.of(context).canPop()
                        ? () => Navigator.of(context).pop()
                        : null,
                  ),
                  Expanded(
                    child: Text(
                      'Design gallery',
                      style: AppTypography.title.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.sm,
                AppSpacing.screen,
                AppSpacing.sm,
              ),
              child: SegmentedControl<_TextSize>(
                segments: const [
                  Segment(_TextSize.normal, 'Text 100%'),
                  Segment(_TextSize.large, '140%'),
                  Segment(_TextSize.largest, '200%'),
                ],
                selected: _textSize,
                onChanged: (v) => setState(() => _textSize = v),
              ),
            ),
            Divider(color: colors.border),
            Expanded(
              child: MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(_scales[_textSize]!)),
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                  itemCount: sections.length,
                  itemBuilder: (context, i) {
                    final (title, child) = sections[i];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.screen,
                            AppSpacing.xl,
                            AppSpacing.screen,
                            AppSpacing.xs,
                          ),
                          child: Semantics(
                            header: true,
                            child: Text(
                              title,
                              style: AppTypography.bodyLarge.semibold.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        child,
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetSection extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SheetSpecimen(),
      Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.md,
          AppSpacing.screen,
          0,
        ),
        child: SecondaryButton(
          label: 'Open sheet',
          expand: true,
          onPressed: () => showAppBottomSheet<void>(
            context: context,
            builder: (context) => AppBottomSheet(
              title: 'Volume',
              onConfirm: () => Navigator.of(context).pop(),
              child: const _VolumeSheetBody(),
            ),
          ),
        ),
      ),
    ],
  );
}

class _VolumeSheetBody extends StatefulWidget {
  const new();

  @override
  State<_VolumeSheetBody> createState() => _VolumeSheetBodyState();
}

class _VolumeSheetBodyState extends State<_VolumeSheetBody> {
  double _original = 1;
  double _added = 0.6;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      AppSlider(
        label: 'Original sound',
        value: _original,
        onChanged: (v) => setState(() => _original = v),
      ),
      const SizedBox(height: AppSpacing.sm),
      AppSlider(
        label: 'Added audio',
        value: _added,
        onChanged: (v) => setState(() => _added = v),
      ),
    ],
  );
}

class _DialogSection extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
    child: Row(
      children: [
        Expanded(
          child: SecondaryButton(
            label: 'Confirm',
            expand: true,
            onPressed: () => showConfirmDialog(
              context: context,
              title: 'Discard recording?',
              message: 'The voiceover you just recorded will be lost.',
              confirmLabel: 'Discard',
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: SecondaryButton(
            label: 'Destructive',
            expand: true,
            onPressed: () => showConfirmDialog(
              context: context,
              title: 'Delete project?',
              message: 'This removes the project and its imported media.',
              confirmLabel: 'Delete',
              destructive: true,
            ),
          ),
        ),
      ],
    ),
  );
}
