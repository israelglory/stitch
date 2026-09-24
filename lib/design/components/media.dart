import 'package:flutter/widgets.dart';
import 'package:stitch/design/components/buttons.dart';
import 'package:stitch/design/components/pressable.dart';
import 'package:stitch/design/components/progress.dart';
import 'package:stitch/design/icons.dart';
import 'package:stitch/design/tokens.dart';
import 'package:stitch/l10n/generated/app_localizations.dart';

const double _maxMediaLabelScale = 1.3;

/// Aspect ratio of project thumbnails on the home grid.
const double _projectThumbAspect = 4 / 5;

/// A project on the home grid: thumbnail with duration, then name and last
/// edited time, with an overflow button.
class ProjectCard extends StatelessWidget {
  const new({
    required this.name,
    required this.durationLabel,
    required this.editedLabel,
    required this.onTap,
    required this.onMore,
    this.thumbnail,
    super.key,
  }) : _loading = false;

  /// Skeleton with the same layout, for loading grids.
  const new loading({super.key})
    : name = '',
      durationLabel = '',
      editedLabel = '',
      onTap = null,
      onMore = null,
      thumbnail = null,
      _loading = true;

  final String name;
  final String durationLabel;
  final String editedLabel;
  final VoidCallback? onTap;
  final VoidCallback? onMore;

  /// Usually an Image. Null shows a neutral placeholder.
  final Widget? thumbnail;
  final bool _loading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    if (_loading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AspectRatio(
            aspectRatio: _projectThumbAspect,
            child: Skeleton(radius: AppRadius.card),
          ),
          const SizedBox(height: AppSpacing.sm),
          Skeleton.text(AppTypography.body, width: 96),
          const SizedBox(height: AppSpacing.sm),
          Skeleton.text(AppTypography.caption, width: 64),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Pressable(
          onPressed: onTap,
          semanticLabel: l10n.projectCardSemantics(name, durationLabel),
          child: AspectRatio(
            aspectRatio: _projectThumbAspect,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  thumbnail ??
                      ColoredBox(
                        color: colors.surfaceRaised,
                        child: Icon(
                          AppIcons.film,
                          size: AppSizes.toolbarIcon,
                          color: colors.textTertiary,
                        ),
                      ),
                  PositionedDirectional(
                    start: AppSpacing.sm,
                    bottom: AppSpacing.sm,
                    child: MediaLabel(durationLabel),
                  ),
                ],
              ),
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body.semibold.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        editedLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AppIconButton(
              icon: AppIcons.more,
              iconSize: AppSizes.inlineIcon,
              semanticLabel: l10n.projectOptions(name),
              onPressed: onMore,
              color: colors.textSecondary,
            ),
          ],
        ),
      ],
    );
  }
}

/// Small text on a dark backing, drawn over media (durations, speed).
class MediaLabel extends StatelessWidget {
  const new(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // Labels sit on thumbnails; unbounded growth would cover the media.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: _maxMediaLabelScale,
      child: _label(colors),
    );
  }

  Widget _label(AppColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xs / 2,
      ),
      decoration: BoxDecoration(
        color: colors.overlay,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Text(
        text,
        style: AppTypography.caption.tabular.semibold.copyWith(
          color: colors.textPrimary,
        ),
      ),
    );
  }
}

/// A photo or video in the media picker. Selected items show an accent
/// outline and their 1-based order in the selection.
class MediaThumbnail extends StatelessWidget {
  const new({
    required this.semanticLabel,
    required this.onTap,
    this.image,
    this.durationLabel,
    this.selectionOrder,
    this.isMissing = false,
    super.key,
  }) : _loading = false;

  const new loading({super.key})
    : semanticLabel = '',
      onTap = null,
      image = null,
      durationLabel = null,
      selectionOrder = null,
      isMissing = false,
      _loading = true;

  /// For example "Video, 0:12".
  final String semanticLabel;
  final VoidCallback? onTap;
  final Widget? image;

  /// Shown for videos.
  final String? durationLabel;

  /// 1-based position in the selection, or null when not selected.
  final int? selectionOrder;

  /// The source file can no longer be found.
  final bool isMissing;
  final bool _loading;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AspectRatio(aspectRatio: 1, child: Skeleton());
    }
    final colors = context.colors;
    final selected = selectionOrder != null;
    return Pressable(
      onPressed: onTap,
      semanticLabel: semanticLabel,
      selected: selected,
      minSize: Size.zero,
      child: AspectRatio(
        aspectRatio: 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.control),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: colors.surfaceRaised),
              if (image != null && !isMissing) image!,
              if (isMissing)
                Center(
                  child: Icon(
                    AppIcons.alert,
                    size: AppSizes.inlineIcon,
                    color: colors.textTertiary,
                  ),
                ),
              if (durationLabel != null)
                PositionedDirectional(
                  end: AppSpacing.xs,
                  bottom: AppSpacing.xs,
                  child: MediaLabel(durationLabel!),
                ),
              if (!isMissing)
                PositionedDirectional(
                  top: AppSpacing.xs,
                  end: AppSpacing.xs,
                  child: _OrderBadge(order: selectionOrder),
                ),
              if (selected)
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: colors.accent,
                      width: AppSizes.strokeWidth,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.control),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderBadge extends StatelessWidget {
  const new({required this.order});

  final int? order;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final selected = order != null;
    return AnimatedContainer(
      duration: AppMotion.of(context, AppMotion.fast),
      curve: AppMotion.curve,
      width: AppSizes.orderBadge,
      height: AppSizes.orderBadge,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? colors.accent : colors.overlay,
        border: Border.all(
          color: selected ? colors.accent : colors.textPrimary,
          width: AppSizes.strokeWidth,
        ),
      ),
      child: selected
          ? MediaQuery.withNoTextScaling(
              child: Text(
                '$order',
                style: AppTypography.caption.tabular.semibold.copyWith(
                  color: colors.onAccent,
                ),
              ),
            )
          : null,
    );
  }
}
