import 'package:flutter/material.dart';
import 'package:stitch/design/components/buttons.dart';
import 'package:stitch/design/components/controls.dart';
import 'package:stitch/design/icons.dart';
import 'package:stitch/design/tokens.dart';
import 'package:stitch/l10n/generated/app_localizations.dart';

const double _dialogMaxWidth = 320;

/// Bottom sheet body: drag handle, header with the title on the left and an
/// optional confirm check on the right, then [child].
///
/// Show it with [showAppBottomSheet]. The widget is public so the editor
/// can also host sheet content inline above the timeline.
class AppBottomSheet extends StatelessWidget {
  const new({
    required this.title,
    required this.child,
    this.onConfirm,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.screen,
      0,
      AppSpacing.screen,
      AppSpacing.lg,
    ),
    super.key,
  });

  final String title;
  final Widget child;

  /// Shows the confirm check when non-null.
  final VoidCallback? onConfirm;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: AppSpacing.xl,
            offset: const Offset(0, -AppSpacing.xs),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Container(
                width: AppSizes.sheetHandleWidth,
                height: AppSizes.sheetHandleHeight,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(
                    AppSizes.sheetHandleHeight / 2,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: AppSpacing.screen,
                end: AppSpacing.xs,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: AppSizes.buttonHeight,
                ),
                child: Row(
                  children: [
                    Expanded(
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
                    if (onConfirm != null)
                      AppIconButton(
                        icon: AppIcons.check,
                        semanticLabel: l10n.done,
                        onPressed: onConfirm,
                      ),
                  ],
                ),
              ),
            ),
            Flexible(
              child: Padding(padding: padding, child: child),
            ),
          ],
        ),
      ),
    );
  }
}

/// Presents an [AppBottomSheet] (or any widget) modally with the app's
/// barrier and motion.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool dimBackground = true,
}) {
  final colors = context.colors;
  final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  return showModalBottomSheet<T>(
    context: context,
    builder: builder,
    isDismissible: isDismissible,
    enableDrag: isDismissible,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    // Editor tool sheets keep the preview visible while adjusting.
    barrierColor: dimBackground ? colors.scrim : Colors.transparent,
    showDragHandle: false,
    sheetAnimationStyle: AnimationStyle(
      duration: reduceMotion ? Duration.zero : AppMotion.slow,
      reverseDuration: reduceMotion ? Duration.zero : AppMotion.standard,
      curve: AppMotion.curve,
    ),
  );
}

/// Dialog asking the user to confirm an action. Resolves to true when
/// confirmed.
Future<bool> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  String? cancelLabel,
  bool destructive = false,
}) async {
  final colors = context.colors;
  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: colors.scrim,
    transitionDuration: AppMotion.of(context, AppMotion.standard),
    transitionBuilder: (context, animation, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: AppMotion.curve),
      child: child,
    ),
    pageBuilder: (context, _, _) => ConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      destructive: destructive,
      onCancel: () => Navigator.of(context).pop(false),
      onConfirm: () => Navigator.of(context).pop(true),
    ),
  );
  return result ?? false;
}

/// A notice with one button, for something the user should know (an
/// import that failed, say).
Future<void> showNoticeDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String buttonLabel,
}) async {
  final colors = context.colors;
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: colors.scrim,
    transitionDuration: AppMotion.of(context, AppMotion.standard),
    transitionBuilder: (context, animation, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: AppMotion.curve),
      child: child,
    ),
    pageBuilder: (context, _, _) => ConfirmDialog(
      title: title,
      message: message,
      confirmLabel: buttonLabel,
      onCancel: null,
      onConfirm: () => Navigator.of(context).pop(),
    ),
  );
}

/// Body of a confirmation dialog. Use [showConfirmDialog] to present it.
class ConfirmDialog extends StatelessWidget {
  const new({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.onCancel,
    required this.onConfirm,
    this.cancelLabel,
    this.destructive = false,
    super.key,
  });

  final String title;
  final String message;
  final String confirmLabel;

  /// Defaults to "Cancel".
  final String? cancelLabel;
  final bool destructive;

  /// Null leaves only the confirm button: a notice to acknowledge.
  final VoidCallback? onCancel;
  final VoidCallback onConfirm;

  /// Above this text scale the buttons stack so labels are not truncated.
  static const double _stackButtonsAtScale = 1.3;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final stacked =
        MediaQuery.textScalerOf(context).scale(1) > _stackButtonsAtScale;

    final cancel = SecondaryButton(
      label: cancelLabel ?? l10n.cancel,
      onPressed: onCancel,
      expand: true,
    );
    final confirm = destructive
        ? DestructiveButton(
            label: confirmLabel,
            onPressed: onConfirm,
            expand: true,
          )
        : PrimaryButton(
            label: confirmLabel,
            onPressed: onConfirm,
            expand: true,
          );

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _dialogMaxWidth),
          child: Semantics(
            scopesRoute: true,
            namesRoute: true,
            explicitChildNodes: true,
            label: title,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border.all(color: colors.border),
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyLarge.semibold.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      message,
                      style: AppTypography.body.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    if (onCancel == null)
                      confirm
                    else if (stacked) ...[
                      confirm,
                      const SizedBox(height: AppSpacing.sm),
                      cancel,
                    ] else
                      Row(
                        children: [
                          Expanded(child: cancel),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(child: confirm),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dialog with one text field, for naming things. Resolves to the trimmed
/// text, or null when cancelled.
Future<String?> showTextInputDialog({
  required BuildContext context,
  required String title,
  required String confirmLabel,
  String initialValue = '',
  String? hint,
}) {
  final colors = context.colors;
  return showGeneralDialog<String>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: colors.scrim,
    transitionDuration: AppMotion.of(context, AppMotion.standard),
    transitionBuilder: (context, animation, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: AppMotion.curve),
      child: child,
    ),
    pageBuilder: (context, _, _) => _TextInputDialog(
      title: title,
      confirmLabel: confirmLabel,
      initialValue: initialValue,
      hint: hint,
    ),
  );
}

class _TextInputDialog extends StatefulWidget {
  const new({
    required this.title,
    required this.confirmLabel,
    required this.initialValue,
    this.hint,
  });

  final String title;
  final String confirmLabel;
  final String initialValue;
  final String? hint;

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  late final _controller = TextEditingController(text: widget.initialValue)
    ..selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.initialValue.length,
    );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _dialogMaxWidth),
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border.all(color: colors.border),
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        widget.title,
                        style: AppTypography.bodyLarge.semibold.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _controller,
                      hint: widget.hint,
                      autofocus: true,
                      semanticLabel: widget.title,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      children: [
                        Expanded(
                          child: SecondaryButton(
                            label: l10n.cancel,
                            onPressed: () => Navigator.of(context).pop(),
                            expand: true,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: ListenableBuilder(
                            listenable: _controller,
                            builder: (context, _) => PrimaryButton(
                              label: widget.confirmLabel,
                              expand: true,
                              onPressed: _controller.text.trim().isEmpty
                                  ? null
                                  : _submit,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One action in an action sheet.
final class SheetAction {
  const new({
    required this.icon,
    required this.label,
    required this.onSelected,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onSelected;
  final bool destructive;
}

/// A bottom sheet listing [actions]. Choosing one closes the sheet first,
/// then runs the action.
Future<void> showActionSheet({
  required BuildContext context,
  required String title,
  required List<SheetAction> actions,
}) async {
  SheetAction? chosen;
  await showAppBottomSheet<void>(
    context: context,
    builder: (context) => AppBottomSheet(
      title: title,
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final action in actions)
            ListRow(
              title: action.label,
              leadingIcon: action.icon,
              destructive: action.destructive,
              onTap: () {
                chosen = action;
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
    ),
  );
  chosen?.onSelected();
}
