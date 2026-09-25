// Onboarding visuals: small, static mock-ups of the real app built from
// the real components, so what users see first is what they will use.
// They are decorative (the page text carries the meaning), so they are
// hidden from screen readers and ignore touches. Text is passed in so it
// is localized by the caller.
import 'package:flutter/widgets.dart';
import 'package:stitch/design/components/controls.dart';
import 'package:stitch/design/components/media.dart';
import 'package:stitch/design/components/toolbar.dart';
import 'package:stitch/design/icons.dart';
import 'package:stitch/design/mocks/sample_media.dart';
import 'package:stitch/design/timeline/timeline_chrome.dart';
import 'package:stitch/design/timeline/timeline_items.dart';
import 'package:stitch/design/tokens.dart';

/// Mock-ups ignore touches, but their controls must look enabled.
void _inert() {}

/// Width the mock-ups are laid out at; they scale down to fit.
const double _mockWidth = 360;

class _Mock extends StatelessWidget {
  const new({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: IgnorePointer(
      child: MediaQuery.withNoTextScaling(
        child: FittedBox(
          child: SizedBox(width: _mockWidth, child: child),
        ),
      ),
    ),
  );
}

class _PreviewFrame extends StatelessWidget {
  const new({this.overlay});

  final Widget? overlay;

  @override
  Widget build(BuildContext context) => Center(
    child: ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: SizedBox(
        width: 150,
        height: 200,
        child: Stack(
          fit: StackFit.expand,
          children: [sampleFrame(3), ?overlay],
        ),
      ),
    ),
  );
}

/// The editor: preview, a short timeline with a transition, and tools.
class EditorMock extends StatelessWidget {
  const new({
    required this.splitLabel,
    required this.speedLabel,
    required this.volumeLabel,
    required this.deleteLabel,
    super.key,
  });

  final String splitLabel;
  final String speedLabel;
  final String volumeLabel;
  final String deleteLabel;

  static const double _pps = 36;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return _Mock(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _PreviewFrame(),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: AppSizes.rulerHeight + AppSizes.videoTrackHeight + 8,
            child: Stack(
              children: [
                const TimeRuler(pixelsPerSecond: _pps, originX: 60),
                Positioned(
                  left: 60,
                  top: AppSizes.rulerHeight + 4,
                  child: Row(
                    children: [
                      VideoClipTile(
                        width: _pps * 3,
                        frameBuilder: (_, i) => sampleFrame(i),
                        durationLabel: '',
                        onTap: _inert,
                      ),
                      VideoClipTile(
                        width: _pps * 4,
                        frameBuilder: (_, i) => sampleFrame(i + 2),
                        durationLabel: '4.0s',
                        selected: true,
                        onTap: _inert,
                      ),
                    ],
                  ),
                ),
                const Positioned(
                  left: 60 + _pps * 3 - AppSizes.minTouchTarget / 2,
                  top: AppSizes.rulerHeight + 4 + 6,
                  child: TransitionButton(
                    semanticLabel: '',
                    hasTransition: true,
                    onPressed: _inert,
                  ),
                ),
                const Positioned(
                  left: 60 + _pps * 4.2,
                  top: 0,
                  bottom: 0,
                  child: Playhead(),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final (i, (icon, label)) in [
                  (AppIcons.split, splitLabel),
                  (AppIcons.speed, speedLabel),
                  (AppIcons.volume, volumeLabel),
                  (AppIcons.delete, deleteLabel),
                ].indexed)
                  ToolbarItem(
                    icon: icon,
                    label: label,
                    onPressed: _inert,
                    selected: i == 1,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Projects saved on the device, with where they are stored.
class OnDeviceMock extends StatelessWidget {
  const new({
    required this.firstProject,
    required this.secondProject,
    required this.editedLabel,
    required this.storageTitle,
    required this.storageValue,
    super.key,
  });

  final String firstProject;
  final String secondProject;
  final String editedLabel;
  final String storageTitle;
  final String storageValue;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return _Mock(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (i, name) in [
                  firstProject,
                  secondProject,
                ].indexed) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ProjectCard(
                      name: name,
                      durationLabel: i == 0 ? '0:42' : '1:18',
                      editedLabel: editedLabel,
                      thumbnail: sampleFrame(i == 0 ? 3 : 1),
                      onTap: _inert,
                      onMore: _inert,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: ListRow(
              title: storageTitle,
              leadingIcon: AppIcons.storage,
              value: storageValue,
            ),
          ),
        ],
      ),
    );
  }
}

/// A caption on the preview, the caption lane, and a downloaded model.
class CaptionsMock extends StatelessWidget {
  const new({
    required this.caption,
    required this.captionStart,
    required this.captionEnd,
    required this.modelTitle,
    required this.modelValue,
    super.key,
  });

  final String caption;

  /// The caption split in two, as it sits on the timeline.
  final String captionStart;
  final String captionEnd;
  final String modelTitle;
  final String modelValue;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return _Mock(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PreviewFrame(
            overlay: Align(
              alignment: const Alignment(0, 0.7),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: colors.overlay,
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: Text(
                  caption,
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.semibold.copyWith(
                    color: colors.onOverlay,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OverlayItemTile(
                kind: OverlayKind.caption,
                label: captionStart,
                width: 130,
                onTap: _inert,
              ),
              const SizedBox(width: AppSpacing.xs),
              OverlayItemTile(
                kind: OverlayKind.caption,
                label: captionEnd,
                width: 110,
                onTap: _inert,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: ListRow(
              title: modelTitle,
              leadingIcon: AppIcons.captions,
              value: modelValue,
              trailing: Icon(
                AppIcons.check,
                size: AppSizes.inlineIcon,
                color: colors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
