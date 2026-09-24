import 'package:flutter/widgets.dart';
import 'package:stitch/design/tokens.dart';

/// Transition looks the preview can show. Mirrors the editor's transition
/// types; kept here so the design system does not depend on features.
enum TransitionLook {
  none,
  crossfade,
  fadeToBlack,
  slideLeft,
  slideRight,
  wipeLeft,
  wipeRight,
  zoomIn,
}

/// A short looping preview of a transition between two frames. Stills are
/// shown instead when the system asks for reduced motion.
class TransitionPreview extends StatefulWidget {
  const new({
    required this.look,
    required this.from,
    required this.to,
    this.animate = true,
    super.key,
  });

  final TransitionLook look;
  final Widget from;
  final Widget to;

  /// False shows the midpoint still, for goldens and reduced motion.
  final bool animate;

  @override
  State<TransitionPreview> createState() => _TransitionPreviewState();
}

class _TransitionPreviewState extends State<TransitionPreview>
    with SingleTickerProviderStateMixin {
  // Hold the first frame, transition, hold the second frame.
  static const _cycle = Duration(milliseconds: 1800);
  static const _holdFraction = 0.3;

  late final _controller = AnimationController(vsync: this, duration: _cycle);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(TransitionPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (widget.animate && !reduce) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller
        ..stop()
        ..value = 0.5;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Progress of the transition itself (0 to 1) at loop position [t].
  static double _progress(double t) {
    final p = (t - _holdFraction) / (1 - _holdFraction * 2);
    return Curves.easeInOut.transform(p.clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => _frame(_progress(_controller.value)),
        ),
      ),
    );
  }

  Widget _frame(double p) {
    final from = widget.from;
    final to = widget.to;
    final black = context.colors.background;
    Widget stack(List<Widget> children) =>
        Stack(fit: StackFit.expand, children: children);

    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        return switch (widget.look) {
          TransitionLook.none => p < 0.5 ? from : to,
          TransitionLook.crossfade => stack([
            from,
            Opacity(opacity: p, child: to),
          ]),
          TransitionLook.fadeToBlack => stack([
            if (p < 0.5) from else to,
            Opacity(
              opacity: 1 - (p - 0.5).abs() * 2,
              child: ColoredBox(color: black),
            ),
          ]),
          TransitionLook.slideLeft => stack([
            Transform.translate(offset: Offset(-w * p, 0), child: from),
            Transform.translate(offset: Offset(w * (1 - p), 0), child: to),
          ]),
          TransitionLook.slideRight => stack([
            Transform.translate(offset: Offset(w * p, 0), child: from),
            Transform.translate(offset: Offset(-w * (1 - p), 0), child: to),
          ]),
          TransitionLook.wipeLeft => stack([
            from,
            ClipRect(clipper: _WipeClipper(p, fromRight: true), child: to),
          ]),
          TransitionLook.wipeRight => stack([
            from,
            ClipRect(clipper: _WipeClipper(p, fromRight: false), child: to),
          ]),
          TransitionLook.zoomIn => stack([
            to,
            Opacity(
              opacity: 1 - p,
              child: Transform.scale(scale: 1 + p * 0.6, child: from),
            ),
          ]),
        };
      },
    );
  }
}

/// Reveals the part of the incoming frame already wiped in.
class _WipeClipper extends CustomClipper<Rect> {
  const new(this.progress, {required this.fromRight});

  final double progress;
  final bool fromRight;

  @override
  Rect getClip(Size size) {
    final w = size.width * progress;
    return fromRight
        ? Rect.fromLTWH(size.width - w, 0, w, size.height)
        : Rect.fromLTWH(0, 0, w, size.height);
  }

  @override
  bool shouldReclip(_WipeClipper old) =>
      old.progress != progress || old.fromRight != fromRight;
}
