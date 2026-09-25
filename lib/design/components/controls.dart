import 'package:flutter/material.dart';
import 'package:stitch/design/components/buttons.dart';
import 'package:stitch/design/components/pressable.dart';
import 'package:stitch/design/icons.dart';
import 'package:stitch/design/tokens.dart';

/// Slider with a label on the left and the formatted value on the right.
class AppSlider extends StatelessWidget {
  const new({
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.formatValue,
    this.onChangeStart,
    this.onChangeEnd,
    super.key,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;

  /// Formats the readout. Defaults to a percentage of the range.
  final String Function(double value)? formatValue;

  String _format(double v) =>
      formatValue?.call(v) ?? '${((v - min) / (max - min) * 100).round()}%';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final readout = _format(value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.body.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                readout,
                style: AppTypography.body.tabular.copyWith(
                  color: onChanged == null
                      ? colors.textTertiary
                      : colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: AppSizes.minTouchTarget,
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: AppSizes.sliderTrack,
              activeTrackColor: colors.accent,
              inactiveTrackColor: colors.border,
              thumbColor: colors.textPrimary,
              overlayColor: Colors.transparent,
              activeTickMarkColor: Colors.transparent,
              inactiveTickMarkColor: Colors.transparent,
              disabledActiveTrackColor: colors.textTertiary,
              disabledInactiveTrackColor: colors.border,
              disabledThumbColor: colors.textTertiary,
              thumbShape: const RoundSliderThumbShape(
                elevation: 0,
                pressedElevation: 0,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.sliderThumb / 2,
              ),
              showValueIndicator: ShowValueIndicator.never,
            ),
            child: Semantics(
              label: label,
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                divisions: divisions,
                onChanged: onChanged,
                onChangeStart: onChangeStart,
                onChangeEnd: onChangeEnd,
                semanticFormatterCallback: _format,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A segment in a [SegmentedControl].
class Segment<T> {
  const new(this.value, this.label);

  final T value;
  final String label;
}

/// Two to five mutually exclusive options.
class SegmentedControl<T> extends StatelessWidget {
  const new({
    required this.segments,
    required this.selected,
    required this.onChanged,
    super.key,
  }) : assert(segments.length >= 2, 'Use at least two segments');

  final List<Segment<T>> segments;
  final T selected;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final selectedIndex = segments.indexWhere((s) => s.value == selected);
    final duration = AppMotion.of(context, AppMotion.standard);
    // Segments span the full 44pt height so each is a full touch target;
    // the selection indicator is drawn inset.
    const inset = AppSpacing.xs;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = constraints.maxWidth / segments.length;
          return Stack(
            children: [
              if (selectedIndex >= 0)
                AnimatedPositionedDirectional(
                  duration: duration,
                  curve: AppMotion.curve,
                  start: segmentWidth * selectedIndex + inset,
                  top: inset,
                  bottom: inset,
                  width: segmentWidth - inset * 2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.surfaceRaised,
                      borderRadius: BorderRadius.circular(
                        AppRadius.control - inset / 2,
                      ),
                    ),
                  ),
                ),
              Row(
                children: [
                  for (final (i, segment) in segments.indexed)
                    Expanded(
                      child: Pressable(
                        onPressed: onChanged == null
                            ? null
                            : () => onChanged!(segment.value),
                        selected: i == selectedIndex,
                        semanticLabel: segment.label,
                        minSize: const Size(0, AppSizes.minTouchTarget),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.sm,
                            ),
                            child: AnimatedDefaultTextStyle(
                              duration: duration,
                              style: AppTypography.body.semibold.copyWith(
                                color: i == selectedIndex
                                    ? colors.textPrimary
                                    : colors.textSecondary,
                              ),
                              child: Text(
                                segment.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A single row in a list or settings group.
class ListRow extends StatelessWidget {
  const new({
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.value,
    this.trailing,
    this.showChevron = false,
    this.destructive = false,
    this.onTap,
    this.inset = true,
    super.key,
  });

  final String title;
  final String? subtitle;
  final IconData? leadingIcon;

  /// Pads to the screen edge. False inside something already padded (a
  /// sheet), so the row lines up with what is around it.
  final bool inset;

  /// Short trailing text, such as a current setting or a size.
  final String? value;

  /// Custom trailing widget, shown after [value].
  final Widget? trailing;
  final bool showChevron;
  final bool destructive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final titleColor = destructive ? colors.destructive : colors.textPrimary;
    final row = Container(
      constraints: const BoxConstraints(minHeight: AppSizes.listRowHeight),
      padding: EdgeInsets.symmetric(
        horizontal: inset ? AppSpacing.screen : 0,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          if (leadingIcon != null) ...[
            Icon(
              leadingIcon,
              size: scaledIconSize(context),
              color: destructive ? colors.destructive : colors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyLarge.copyWith(color: titleColor),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: AppTypography.body.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (value != null) ...[
            const SizedBox(width: AppSpacing.md),
            Text(
              value!,
              style: AppTypography.body.tabular.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.md),
            trailing!,
          ],
          if (showChevron) ...[
            const SizedBox(width: AppSpacing.sm),
            Icon(
              AppIcons.chevronRight,
              size: AppSizes.inlineIcon,
              color: colors.textTertiary,
            ),
          ],
        ],
      ),
    );
    if (onTap == null) return MergeSemantics(child: row);
    return MergeSemantics(
      child: Pressable(onPressed: onTap, child: row),
    );
  }
}

/// A row that turns an option on or off, with a square check box at the
/// end (no pill switches: nothing is fully rounded but icon buttons).
class CheckRow extends StatelessWidget {
  const new({
    required this.title,
    required this.checked,
    required this.onChanged,
    this.subtitle,
    this.inset = true,
    super.key,
  });

  final String title;
  final String? subtitle;
  final bool checked;

  /// Null disables the row.
  final ValueChanged<bool>? onChanged;

  /// See [ListRow.inset].
  final bool inset;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = onChanged != null;
    final box = AnimatedContainer(
      duration: AppMotion.of(context, AppMotion.fast),
      curve: AppMotion.curve,
      width: AppSizes.inlineIcon,
      height: AppSizes.inlineIcon,
      decoration: BoxDecoration(
        color: checked ? colors.accent : null,
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: checked
            ? null
            : Border.all(
                color: colors.textTertiary,
                width: AppSizes.strokeWidth,
              ),
      ),
      child: checked
          ? Icon(
              AppIcons.check,
              size: AppSizes.microIcon,
              color: colors.onAccent,
            )
          : null,
    );
    return Semantics(
      checked: checked,
      enabled: enabled,
      child: Opacity(
        opacity: enabled ? 1 : kDisabledOpacity,
        child: ListRow(
          title: title,
          subtitle: subtitle,
          inset: inset,
          trailing: ExcludeSemantics(child: box),
          onTap: enabled ? () => onChanged!(!checked) : null,
        ),
      ),
    );
  }
}

/// Single-line or multi-line text input.
class AppTextField extends StatelessWidget {
  const new({
    required this.controller,
    this.focusNode,
    this.hint,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.semanticLabel,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? hint;
  final bool autofocus;
  final int? maxLines;

  /// Grows from this many lines up to [maxLines]; null keeps [maxLines].
  final int? minLines;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.control),
      borderSide: BorderSide(color: color),
    );
    return Semantics(
      // Its own node, so it never merges with a control beside it.
      container: true,
      label: semanticLabel,
      textField: true,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
        maxLines: maxLines,
        minLines: minLines,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        onChanged: onChanged,
        cursorColor: colors.accent,
        style: AppTypography.bodyLarge.copyWith(color: colors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTypography.bodyLarge.copyWith(
            color: colors.textTertiary,
          ),
          filled: true,
          fillColor: colors.surfaceRaised,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          border: border(colors.surfaceRaised),
          enabledBorder: border(colors.surfaceRaised),
          focusedBorder: border(colors.accent),
        ),
      ),
    );
  }
}
