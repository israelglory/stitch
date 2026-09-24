import 'package:flutter/widgets.dart';
import 'package:stitch/design/components/buttons.dart';
import 'package:stitch/design/icons.dart';
import 'package:stitch/design/tokens.dart';
import 'package:stitch/l10n/generated/app_localizations.dart';

/// Shown when a list or screen has no content: a short title, one line of
/// text, and at most one action. No illustration.
class EmptyState extends StatelessWidget {
  const new({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.primaryAction = false,
    super.key,
  }) : assert(
         (actionLabel == null) == (onAction == null),
         'actionLabel and onAction go together',
       );

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Uses PrimaryButton for the action. Leave false when the screen already
  /// has a primary action.
  final bool primaryAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.bodyLarge.semibold.copyWith(
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: colors.textSecondary),
          ),
          if (actionLabel case final label?) ...[
            const SizedBox(height: AppSpacing.lg),
            if (primaryAction)
              PrimaryButton(label: label, onPressed: onAction)
            else
              SecondaryButton(label: label, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}

/// Inline error with an optional retry. Neutral surface; only the icon
/// carries the destructive color.
class ErrorBanner extends StatelessWidget {
  const new({required this.message, this.onRetry, this.retryLabel, super.key});

  final String message;
  final VoidCallback? onRetry;

  /// Defaults to "Retry".
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsetsDirectional.only(
          start: AppSpacing.md,
          end: AppSpacing.xs,
          top: AppSpacing.xs,
          bottom: AppSpacing.xs,
        ),
        constraints: const BoxConstraints(minHeight: AppSizes.buttonHeight),
        decoration: BoxDecoration(
          color: colors.surfaceRaised,
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        child: Row(
          children: [
            Icon(
              AppIcons.alert,
              size: scaledIconSize(context),
              color: colors.destructive,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(
                  message,
                  style: AppTypography.body.copyWith(color: colors.textPrimary),
                ),
              ),
            ),
            if (onRetry != null)
              AppTextButton(
                label: retryLabel ?? l10n.retry,
                onPressed: onRetry,
                size: ButtonSize.small,
              )
            else
              const SizedBox(width: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}
