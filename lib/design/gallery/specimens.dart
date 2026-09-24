// Specimens: every design component in all of its states. Rendered by the
// design gallery (debug and profile builds only) and by the golden tests,
// so both always show the same thing.
//
// Sample text here is developer-facing sample content, not UI copy, so it
// is not localized.
import 'package:flutter/material.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/design/mocks/editor_mocks.dart';
import 'package:stitch/design/mocks/sample_media.dart';

void _noop() {}

String _hex(Color color) {
  final rgb = color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2);
  return '#${rgb.toUpperCase()}';
}

/// Label above a group of states inside a specimen.
class SpecimenLabel extends StatelessWidget {
  const new(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
    child: Text(
      text,
      style: AppTypography.caption.copyWith(color: context.colors.textTertiary),
    ),
  );
}

class _Padded extends StatelessWidget {
  const new({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
}

class ColorsSpecimen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final swatches = <(String, Color)>[
      ('background', c.background),
      ('surface', c.surface),
      ('surfaceRaised', c.surfaceRaised),
      ('border', c.border),
      ('textPrimary', c.textPrimary),
      ('textSecondary', c.textSecondary),
      ('textTertiary', c.textTertiary),
      ('accent', c.accent),
      ('destructive', c.destructive),
      ('success', c.success),
      ('laneText', c.laneText),
      ('laneCaptions', c.laneCaptions),
      ('laneAudio', c.laneAudio),
      ('laneVoiceover', c.laneVoiceover),
    ];
    return _Padded(
      children: [
        for (final (name, color) in swatches)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: [
                Container(
                  width: AppSpacing.xxl,
                  height: AppSpacing.xxl,
                  decoration: BoxDecoration(
                    color: color,
                    border: Border.all(color: c.border),
                    borderRadius: BorderRadius.circular(AppRadius.control),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    name,
                    style: AppTypography.body.copyWith(color: c.textPrimary),
                  ),
                ),
                Text(
                  _hex(color),
                  style: AppTypography.caption.tabular.copyWith(
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class TypographySpecimen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Text line(String name, TextStyle style, [Color? color]) =>
        Text(name, style: style.copyWith(color: color ?? c.textPrimary));
    return _Padded(
      children: [
        line('Display 28', AppTypography.display),
        line('Title 20', AppTypography.title),
        line('Body large 16', AppTypography.bodyLarge),
        line('Button 16', AppTypography.button),
        line('Body 14', AppTypography.body),
        line('Body 14 secondary', AppTypography.body, c.textSecondary),
        line('Caption 12', AppTypography.caption, c.textSecondary),
        const SizedBox(height: AppSpacing.sm),
        line('0:00 1:11 8:88 (tabular)', AppTypography.body.tabular),
      ],
    );
  }
}

class IconsSpecimen extends StatelessWidget {
  const new({super.key});

  static const List<IconData> _icons = [
    AppIcons.close, AppIcons.check, AppIcons.back, AppIcons.chevronRight, //
    AppIcons.chevronDown, AppIcons.more, AppIcons.settings, AppIcons.add,
    AppIcons.undo, AppIcons.redo, AppIcons.play, AppIcons.pause,
    AppIcons.fullscreen, AppIcons.exitFullscreen, AppIcons.edit,
    AppIcons.split, AppIcons.speed, AppIcons.volume, AppIcons.muted,
    AppIcons.delete, AppIcons.duplicate, AppIcons.replace,
    AppIcons.extractAudio, AppIcons.audio, AppIcons.text, AppIcons.captions,
    AppIcons.aspectRatio, AppIcons.background, AppIcons.transition,
    AppIcons.fade, AppIcons.loop, AppIcons.microphone, AppIcons.soundEffects,
    AppIcons.folder, AppIcons.image, AppIcons.video, AppIcons.film,
    AppIcons.share, AppIcons.download, AppIcons.link, AppIcons.externalLink,
    AppIcons.storage, AppIcons.clock, AppIcons.search, AppIcons.rename,
    AppIcons.alert, AppIcons.info, AppIcons.retry,
  ];

  @override
  Widget build(BuildContext context) => _Padded(
    children: [
      Wrap(
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.lg,
        children: [
          for (final icon in _icons)
            Icon(
              icon,
              size: AppSizes.toolbarIcon,
              color: context.colors.textPrimary,
            ),
        ],
      ),
    ],
  );
}

class ButtonsSpecimen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => const _Padded(
    children: [
      SpecimenLabel('Primary'),
      PrimaryButton(label: 'Export', onPressed: _noop, expand: true),
      SizedBox(height: AppSpacing.sm),
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          PrimaryButton(
            label: 'New project',
            icon: AppIcons.add,
            onPressed: _noop,
          ),
          PrimaryButton(
            label: 'Export',
            size: ButtonSize.small,
            onPressed: _noop,
          ),
          PrimaryButton(label: 'Disabled', onPressed: null),
          PrimaryButton(label: 'Loading', onPressed: _noop, isLoading: true),
        ],
      ),
      SpecimenLabel('Secondary'),
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SecondaryButton(label: 'Retake', onPressed: _noop),
          SecondaryButton(
            label: 'Share',
            icon: AppIcons.share,
            onPressed: _noop,
          ),
          SecondaryButton(
            label: 'Small',
            size: ButtonSize.small,
            onPressed: _noop,
          ),
          SecondaryButton(label: 'Disabled', onPressed: null),
        ],
      ),
      SpecimenLabel('Text'),
      Wrap(
        spacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          AppTextButton(label: 'Apply to all', onPressed: _noop),
          AppTextButton(label: 'Skip', neutral: true, onPressed: _noop),
          AppTextButton(label: 'Disabled', onPressed: null),
        ],
      ),
      SpecimenLabel('Destructive'),
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          DestructiveButton(label: 'Delete', onPressed: _noop),
          DestructiveButton(label: 'Disabled', onPressed: null),
        ],
      ),
      SpecimenLabel('Icon'),
      Row(
        children: [
          AppIconButton(
            icon: AppIcons.undo,
            semanticLabel: 'Undo',
            onPressed: _noop,
          ),
          AppIconButton(
            icon: AppIcons.redo,
            semanticLabel: 'Redo',
            onPressed: null,
          ),
          AppIconButton(
            icon: AppIcons.fullscreen,
            semanticLabel: 'Fullscreen',
            style: IconButtonStyle.filled,
            onPressed: _noop,
          ),
          AppIconButton(
            icon: AppIcons.loop,
            semanticLabel: 'Loop',
            selected: true,
            onPressed: _noop,
          ),
          AppIconButton(
            icon: AppIcons.more,
            semanticLabel: 'More',
            iconSize: AppSizes.inlineIcon,
            onPressed: _noop,
          ),
        ],
      ),
    ],
  );
}

class ControlsSpecimen extends StatefulWidget {
  const new({super.key});

  @override
  State<ControlsSpecimen> createState() => _ControlsSpecimenState();
}

class _ControlsSpecimenState extends State<ControlsSpecimen> {
  double _volume = 0.8;
  double _duration = 0.5;
  String _segment = 'Videos';
  final _text = TextEditingController(text: 'Beach day');
  final _empty = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    _empty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _Padded(
    children: [
      const SpecimenLabel('Slider'),
      AppSlider(
        label: 'Volume',
        value: _volume,
        onChanged: (v) => setState(() => _volume = v),
      ),
      AppSlider(
        label: 'Duration',
        value: _duration,
        min: 0.2,
        max: 1.5,
        divisions: 13,
        formatValue: (v) => '${v.toStringAsFixed(1)}s',
        onChanged: (v) => setState(() => _duration = v),
      ),
      const AppSlider(label: 'Disabled', value: 0.3, onChanged: null),
      const SpecimenLabel('Segmented control'),
      SegmentedControl<String>(
        segments: const [
          Segment('Videos', 'Videos'),
          Segment('Photos', 'Photos'),
          Segment('All', 'All'),
        ],
        selected: _segment,
        onChanged: (v) => setState(() => _segment = v),
      ),
      const SpecimenLabel('Text field'),
      AppTextField(controller: _text, semanticLabel: 'Project name'),
      const SizedBox(height: AppSpacing.sm),
      AppTextField(controller: _empty, hint: 'Enter text'),
    ],
  );
}

class ListRowSpecimen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ListRow(
        title: 'Default export quality',
        value: '1080p',
        showChevron: true,
        onTap: _noop,
      ),
      ListRow(
        title: 'Cache',
        subtitle: 'Thumbnails and waveforms',
        value: '184 MB',
        leadingIcon: AppIcons.storage,
      ),
      ListRow(
        title: 'Source code',
        leadingIcon: AppIcons.externalLink,
        onTap: _noop,
      ),
      ListRow(
        title: 'Delete',
        leadingIcon: AppIcons.delete,
        destructive: true,
        onTap: _noop,
      ),
      ListRow(
        title: 'Base model',
        subtitle: '142 MB',
        trailing: SecondaryButton(
          label: 'Download',
          size: ButtonSize.small,
          onPressed: _noop,
        ),
      ),
    ],
  );
}

class ToolbarSpecimen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _Padded(children: [SpecimenLabel('Nothing selected')]),
      ContextToolbar(
        items: [
          ToolbarItem(icon: AppIcons.edit, label: 'Edit', onPressed: _noop),
          ToolbarItem(icon: AppIcons.audio, label: 'Audio', onPressed: _noop),
          ToolbarItem(icon: AppIcons.text, label: 'Text', onPressed: _noop),
          ToolbarItem(
            icon: AppIcons.captions,
            label: 'Captions',
            onPressed: _noop,
          ),
          ToolbarItem(
            icon: AppIcons.aspectRatio,
            label: 'Ratio',
            onPressed: _noop,
          ),
          ToolbarItem(
            icon: AppIcons.background,
            label: 'Background',
            onPressed: _noop,
          ),
        ],
      ),
      _Padded(children: [SpecimenLabel('Clip selected')]),
      ContextToolbar(
        onBack: _noop,
        items: [
          ToolbarItem(icon: AppIcons.split, label: 'Split', onPressed: _noop),
          ToolbarItem(
            icon: AppIcons.speed,
            label: 'Speed',
            selected: true,
            onPressed: _noop,
          ),
          ToolbarItem(icon: AppIcons.volume, label: 'Volume', onPressed: _noop),
          ToolbarItem(
            icon: AppIcons.delete,
            label: 'Delete',
            destructive: true,
            onPressed: _noop,
          ),
          ToolbarItem(
            icon: AppIcons.duplicate,
            label: 'Duplicate',
            onPressed: _noop,
          ),
          ToolbarItem(
            icon: AppIcons.replace,
            label: 'Replace',
            onPressed: null,
          ),
          ToolbarItem(
            icon: AppIcons.extractAudio,
            label: 'Extract audio',
            onPressed: _noop,
          ),
        ],
      ),
    ],
  );
}

class MediaSpecimen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => _Padded(
    children: [
      const SpecimenLabel('Project card: content, no thumbnail, loading'),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ProjectCard(
              name: 'Beach day',
              durationLabel: '0:42',
              editedLabel: 'Edited 2 hours ago',
              thumbnail: sampleFrame(3),
              onTap: _noop,
              onMore: _noop,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          const Expanded(
            child: ProjectCard(
              name: 'A project with a very long name that truncates',
              durationLabel: '12:05',
              editedLabel: 'Edited yesterday',
              onTap: _noop,
              onMore: _noop,
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
      const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: ProjectCard.loading()),
          SizedBox(width: AppSpacing.md),
          Expanded(child: ProjectCard.loading()),
        ],
      ),
      const SpecimenLabel(
        'Media thumbnail: video, selected 1 and 2, photo, missing, loading',
      ),
      GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: AppSpacing.xs,
        crossAxisSpacing: AppSpacing.xs,
        children: [
          MediaThumbnail(
            semanticLabel: 'Video, 0:12',
            image: sampleFrame(0),
            durationLabel: '0:12',
            onTap: _noop,
          ),
          MediaThumbnail(
            semanticLabel: 'Video, 1:03',
            image: sampleFrame(1),
            durationLabel: '1:03',
            selectionOrder: 1,
            onTap: _noop,
          ),
          MediaThumbnail(
            semanticLabel: 'Photo',
            image: sampleFrame(2),
            selectionOrder: 2,
            onTap: _noop,
          ),
          MediaThumbnail(
            semanticLabel: 'Photo',
            image: sampleFrame(4),
            onTap: _noop,
          ),
          const MediaThumbnail(
            semanticLabel: 'Missing video',
            isMissing: true,
            durationLabel: '0:08',
            onTap: _noop,
          ),
          const MediaThumbnail.loading(),
        ],
      ),
    ],
  );
}

class ProgressSpecimen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => _Padded(
    children: [
      const SpecimenLabel('Linear: 0%, 40%, 100%, indeterminate'),
      const LinearProgress(value: 0),
      const SizedBox(height: AppSpacing.md),
      const LinearProgress(value: 0.4),
      const SizedBox(height: AppSpacing.md),
      const LinearProgress(value: 1),
      const SizedBox(height: AppSpacing.md),
      const LinearProgress(),
      const SpecimenLabel('Ring: small, export, indeterminate'),
      Row(
        children: [
          const ProgressRing(value: 0.25),
          const SizedBox(width: AppSpacing.xl),
          ProgressRing(
            value: 0.62,
            size: 96,
            child: Text(
              '62%',
              style: AppTypography.title.tabular.copyWith(
                color: context.colors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xl),
          const ProgressRing(size: AppSizes.minTouchTarget),
        ],
      ),
      const SpecimenLabel('Skeleton'),
      const Row(
        children: [
          Skeleton(width: 48, height: 48),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(height: AppFontSizes.body, width: 160),
                SizedBox(height: AppSpacing.sm),
                Skeleton(height: AppFontSizes.caption, width: 96),
              ],
            ),
          ),
        ],
      ),
    ],
  );
}

class FeedbackSpecimen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => const _Padded(
    children: [
      SpecimenLabel('Empty state'),
      EmptyState(
        title: 'No projects yet',
        message: 'Projects you create appear here.',
        actionLabel: 'New project',
        onAction: _noop,
      ),
      SpecimenLabel('Error banner'),
      ErrorBanner(message: 'Could not load this video.', onRetry: _noop),
      SizedBox(height: AppSpacing.sm),
      ErrorBanner(message: 'Not enough storage to export.'),
    ],
  );
}

class SheetSpecimen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => AppBottomSheet(
    title: 'Speed',
    onConfirm: _noop,
    child: AppSlider(
      label: 'Speed',
      value: 1,
      min: 0.25,
      max: 4,
      formatValue: (v) => '${v.toStringAsFixed(2)}x',
      onChanged: (_) {},
    ),
  );
}

class DialogSpecimen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => const Column(
    children: [
      ConfirmDialog(
        title: 'Delete project?',
        message:
            'This removes the project and its imported media. '
            'The originals in your gallery are not affected.',
        confirmLabel: 'Delete',
        destructive: true,
        onCancel: _noop,
        onConfirm: _noop,
      ),
      ConfirmDialog(
        title: 'Discard recording?',
        message: 'The voiceover you just recorded will be lost.',
        confirmLabel: 'Discard',
        onCancel: _noop,
        onConfirm: _noop,
      ),
    ],
  );
}

class TimelineSpecimen extends StatelessWidget {
  const new({super.key});

  static const double _pps = 48;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Padded(children: [SpecimenLabel('Ruler at three zoom levels')]),
        const TimeRuler(pixelsPerSecond: 160, originX: AppSpacing.screen),
        const TimeRuler(pixelsPerSecond: _pps, originX: AppSpacing.screen),
        const TimeRuler(pixelsPerSecond: 8, originX: AppSpacing.screen),
        const _Padded(children: [SpecimenLabel('Composition with playhead')]),
        SizedBox(
          height:
              AppSizes.rulerHeight +
              AppSizes.laneHeight * 3 +
              AppSizes.videoTrackHeight +
              AppSpacing.xs * 4,
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: AppSizes.laneHeaderWidth),
                    child: TimeRuler(pixelsPerSecond: _pps, originX: 0),
                  ),
                  _lane(
                    const LaneHeader(icon: AppIcons.text, label: 'Text'),
                    const [
                      (
                        _pps * 0.5,
                        OverlayItemTile(
                          kind: OverlayKind.text,
                          label: 'Summer',
                          width: _pps * 2,
                          onTap: _noop,
                        ),
                      ),
                    ],
                  ),
                  _lane(
                    const LaneHeader(
                      icon: AppIcons.captions,
                      label: 'Captions',
                    ),
                    const [
                      (
                        0,
                        OverlayItemTile(
                          kind: OverlayKind.caption,
                          label: 'We finally made it',
                          width: _pps * 2.4,
                          onTap: _noop,
                        ),
                      ),
                      (
                        _pps * 2.5,
                        OverlayItemTile(
                          kind: OverlayKind.caption,
                          label: 'to the coast',
                          width: _pps * 1.6,
                          onTap: _noop,
                        ),
                      ),
                    ],
                  ),
                  _lane(
                    const LaneHeader(
                      icon: AppIcons.volume,
                      label: 'Sound',
                      height: AppSizes.videoTrackHeight,
                      onPressed: _noop,
                    ),
                    [
                      (
                        0,
                        VideoClipTile(
                          width: _pps * 2.5,
                          frameBuilder: (_, i) => sampleFrame(i),
                          durationLabel: '2.5s',
                          onTap: _noop,
                        ),
                      ),
                      (
                        _pps * 2.5,
                        VideoClipTile(
                          width: _pps * 3,
                          frameBuilder: (_, i) => sampleFrame(i + 2),
                          durationLabel: '3.0s',
                          speedLabel: '2x',
                          onTap: _noop,
                        ),
                      ),
                    ],
                    height: AppSizes.videoTrackHeight,
                    overlay: const [
                      (
                        _pps * 2.5 - AppSizes.minTouchTarget / 2,
                        TransitionButton(
                          semanticLabel: 'Transition',
                          hasTransition: true,
                          onPressed: _noop,
                        ),
                      ),
                    ],
                  ),
                  _lane(
                    const LaneHeader(icon: AppIcons.audio, label: 'Audio'),
                    [
                      (
                        0,
                        AudioItemTile(
                          kind: AudioKind.music,
                          label: 'Morning light',
                          width: _pps * 6,
                          waveform: sampleWaveform(96),
                          fadeInPx: _pps * 0.8,
                          overflowStartPx: _pps * 5.5,
                          onTap: _noop,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Positioned(
                left: AppSizes.laneHeaderWidth + _pps * 1.5,
                top: 0,
                bottom: 0,
                child: Playhead(),
              ),
            ],
          ),
        ),
        const _Padded(children: [SpecimenLabel('Video clips')]),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              VideoClipTile(
                width: 160,
                frameBuilder: (_, i) => sampleFrame(i),
                durationLabel: '3.3s',
                selected: true,
                trim: TrimCallbacks(onUpdate: (_, _) {}),
                onTap: _noop,
              ),
              VideoClipTile(
                width: 120,
                frameBuilder: (_, i) => sampleFrame(i),
                durationLabel: '2.5s',
                isMissing: true,
                onTap: _noop,
              ),
              VideoClipTile(
                width: 40,
                frameBuilder: (_, i) => sampleFrame(i + 1),
                durationLabel: '0.8s',
                selected: true,
                trim: TrimCallbacks(onUpdate: (_, _) {}),
                onTap: _noop,
              ),
            ],
          ),
        ),
        const _Padded(
          children: [SpecimenLabel('Transition: none, applied, open')],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          child: Row(
            children: [
              TransitionButton(
                semanticLabel: 'Add transition',
                onPressed: _noop,
              ),
              TransitionButton(
                semanticLabel: 'Crossfade',
                hasTransition: true,
                onPressed: _noop,
              ),
              TransitionButton(
                semanticLabel: 'Crossfade',
                hasTransition: true,
                selected: true,
                onPressed: _noop,
              ),
            ],
          ),
        ),
        const _Padded(children: [SpecimenLabel('Lane items')]),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              OverlayItemTile(
                kind: OverlayKind.text,
                label: 'Selected text',
                width: 160,
                selected: true,
                trim: TrimCallbacks(onUpdate: (_, _) {}),
                onTap: _noop,
              ),
              const OverlayItemTile(
                kind: OverlayKind.caption,
                label: 'Needs review',
                width: 140,
                needsReview: true,
                onTap: _noop,
              ),
              AudioItemTile(
                kind: AudioKind.voiceover,
                label: 'Voiceover 1',
                width: 200,
                waveform: sampleWaveform(64, seed: 3),
                fadeOutPx: 32,
                selected: true,
                trim: TrimCallbacks(onUpdate: (_, _) {}),
                onTap: _noop,
              ),
              const AudioItemTile(
                kind: AudioKind.soundEffect,
                label: 'Loading waveform',
                width: 140,
                onTap: _noop,
              ),
            ],
          ),
        ),
        const _Padded(children: [SpecimenLabel('Lane headers')]),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          child: Row(
            children: [
              LaneHeader(
                icon: AppIcons.volume,
                label: 'Sound',
                height: AppSizes.videoTrackHeight,
                onPressed: _noop,
              ),
              LaneHeader(
                icon: AppIcons.muted,
                label: 'Muted',
                height: AppSizes.videoTrackHeight,
                active: false,
                onPressed: _noop,
              ),
              LaneHeader(icon: AppIcons.microphone, label: 'Voiceover'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _lane(
    Widget header,
    List<(double, Widget)> items, {
    double height = AppSizes.laneHeight,
    List<(double, Widget)> overlay = const [],
  }) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xs),
    child: SizedBox(
      height: height,
      child: Row(
        children: [
          header,
          Expanded(
            child: ClipRect(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final (x, item) in items)
                    Positioned(left: x, top: 0, child: item),
                  for (final (x, item) in overlay)
                    Positioned(
                      left: x,
                      top: (height - AppSizes.minTouchTarget) / 2,
                      child: item,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class HeaderSpecimen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _Padded(children: [SpecimenLabel('Top level')]),
      AppHeader(
        title: 'Projects',
        trailing: [
          AppIconButton(
            icon: AppIcons.settings,
            semanticLabel: 'Settings',
            onPressed: _noop,
          ),
        ],
      ),
      _Padded(children: [SpecimenLabel('Flow, centered')]),
      AppHeader(
        centerTitle: true,
        title: 'Add media',
        leading: AppIconButton(
          icon: AppIcons.close,
          semanticLabel: 'Close',
          onPressed: _noop,
        ),
      ),
      _Padded(children: [SpecimenLabel('Editor')]),
      AppHeader(
        centerTitle: true,
        title: 'A long project name that does not fit',
        leading: AppIconButton(
          icon: AppIcons.close,
          semanticLabel: 'Close',
          onPressed: _noop,
        ),
        trailing: [
          AppIconButton(
            icon: AppIcons.undo,
            semanticLabel: 'Undo',
            onPressed: _noop,
          ),
          AppIconButton(
            icon: AppIcons.redo,
            semanticLabel: 'Redo',
            onPressed: null,
          ),
          SizedBox(width: AppSpacing.xs),
          PrimaryButton(
            label: 'Export',
            size: ButtonSize.small,
            onPressed: _noop,
          ),
          SizedBox(width: AppSpacing.sm),
        ],
      ),
    ],
  );
}

class ChoicesSpecimen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => _Padded(
    children: [
      const SpecimenLabel('Page dots'),
      const Center(child: PageDots(count: 3, index: 1)),
      const SpecimenLabel('Aspect ratio tiles'),
      Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        children: [
          for (final (label, ratio, selected) in [
            ('9:16', 9 / 16, true),
            ('16:9', 16 / 9, false),
            ('1:1', 1.0, false),
            ('4:5', 4 / 5, false),
            ('Original', null, false),
          ])
            ChoiceTile(
              label: label,
              visual: AspectRatioGlyph(ratio: ratio),
              selected: selected,
              onTap: _noop,
            ),
        ],
      ),
      const SpecimenLabel('Color swatches'),
      Wrap(
        spacing: AppSpacing.xs,
        children: [
          for (final (i, color) in CanvasPalette.colors.indexed)
            ColorSwatchButton(
              color: color,
              semanticLabel: 'Color $i',
              selected: i == 0,
              onTap: _noop,
            ),
        ],
      ),
    ],
  );
}

class TransitionPreviewSpecimen extends StatelessWidget {
  const new({this.animate = true, super.key});

  /// False freezes every preview at its midpoint, for goldens.
  final bool animate;

  @override
  Widget build(BuildContext context) => _Padded(
    children: [
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.md,
        children: [
          for (final look in TransitionLook.values)
            ChoiceTile(
              label: look.name,
              selected: look == TransitionLook.crossfade,
              onTap: _noop,
              visual: SizedBox.square(
                dimension: 64,
                child: TransitionPreview(
                  look: look,
                  animate: animate,
                  from: sampleFrame(0),
                  to: sampleFrame(2),
                ),
              ),
            ),
        ],
      ),
    ],
  );
}

class MocksSpecimen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => const _Padded(
    children: [
      SpecimenLabel('Editor'),
      EditorMock(
        splitLabel: 'Split',
        speedLabel: 'Speed',
        volumeLabel: 'Volume',
        deleteLabel: 'Delete',
      ),
      SpecimenLabel('On device'),
      OnDeviceMock(
        firstProject: 'Beach day',
        secondProject: 'Birthday',
        editedLabel: 'Edited today',
        storageTitle: 'Saved on this device',
        storageValue: '1.2 GB',
      ),
      SpecimenLabel('Captions'),
      CaptionsMock(
        caption: 'We finally made it',
        captionStart: 'We finally',
        captionEnd: 'made it',
        modelTitle: 'Speech model',
        modelValue: 'Downloaded',
      ),
    ],
  );
}
