import 'package:flutter/widgets.dart';
import 'package:stitch/design/tokens.dart';

/// Shared tap behavior for every tappable component: dims while pressed,
/// dims further when disabled, exposes button semantics, and guarantees
/// the minimum touch target. No ripple, no ink.
class Pressable extends StatefulWidget {
  const new({
    required this.child,
    required this.onPressed,
    this.semanticLabel,
    this.selected,
    this.onLongPress,
    this.busy = false,
    this.minSize = const Size.square(AppSizes.minTouchTarget),
    super.key,
  });

  final Widget child;

  /// Null disables the control.
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;

  /// Accessibility label. Leave null when [child] already contains the
  /// visible label text.
  final String? semanticLabel;

  /// Ignores taps without dimming, for controls showing their own
  /// progress (a loading button).
  final bool busy;

  /// Non-null for toggles and selectable items.
  final bool? selected;

  final Size minSize;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.busy;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final opacity = widget.onPressed == null
        ? kDisabledOpacity
        : widget.busy
        ? 1.0
        : _pressed
        ? kPressedOpacity
        : 1.0;
    final labelled = widget.semanticLabel != null;

    return Semantics(
      button: true,
      enabled: _enabled,
      selected: widget.selected,
      label: widget.semanticLabel,
      // Excluding the child's semantics also drops the gesture's actions,
      // so expose them here or screen readers cannot activate the control.
      excludeSemantics: labelled,
      onTap: labelled && _enabled ? widget.onPressed : null,
      onLongPress: labelled && _enabled ? widget.onLongPress : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _enabled ? widget.onPressed : null,
        onLongPress: _enabled ? widget.onLongPress : null,
        onTapDown: _enabled ? (_) => _setPressed(true) : null,
        onTapUp: _enabled ? (_) => _setPressed(false) : null,
        onTapCancel: _enabled ? () => _setPressed(false) : null,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: widget.minSize.width,
            minHeight: widget.minSize.height,
          ),
          child: AnimatedOpacity(
            opacity: opacity,
            duration: AppMotion.of(context, AppMotion.fast),
            curve: AppMotion.curve,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
