import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:stitch/design/tokens.dart';

/// Thin horizontal progress bar. A null [value] shows indeterminate
/// progress.
class LinearProgress extends StatefulWidget {
  const new({this.value, this.semanticLabel, super.key});

  /// 0.0 to 1.0, or null for indeterminate.
  final double? value;
  final String? semanticLabel;

  @override
  State<LinearProgress> createState() => _LinearProgressState();
}

class _LinearProgressState extends State<LinearProgress>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(LinearProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final animate =
        widget.value == null &&
        !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    if (animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final value = widget.value?.clamp(0.0, 1.0);
    return Semantics(
      label: widget.semanticLabel,
      value: value == null ? null : '${(value * 100).round()}%',
      child: SizedBox(
        height: AppSizes.progressTrack,
        width: double.infinity,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _LinearPainter(
              value: value,
              phase: _controller.value,
              track: colors.border,
              fill: colors.accent,
            ),
          ),
        ),
      ),
    );
  }
}

class _LinearPainter extends CustomPainter {
  const new({
    required this.value,
    required this.phase,
    required this.track,
    required this.fill,
  });

  final double? value;
  final double phase;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = Radius.circular(size.height / 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, radius),
      Paint()..color = track,
    );
    final Rect bar;
    if (value case final v?) {
      bar = Rect.fromLTWH(0, 0, size.width * v, size.height);
    } else {
      // A third-width segment sweeping left to right.
      final width = size.width / 3;
      final left = -width + (size.width + width) * phase;
      bar = Rect.fromLTWH(
        left,
        0,
        width,
        size.height,
      ).intersect(Offset.zero & size);
    }
    if (bar.width <= 0) return;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bar, radius),
      Paint()..color = fill,
    );
  }

  @override
  bool shouldRepaint(_LinearPainter old) =>
      old.value != value ||
      old.phase != phase ||
      old.track != track ||
      old.fill != fill;
}

/// Circular progress. A null [value] spins. Use [child] for a centered
/// readout, as on the export screen.
class ProgressRing extends StatefulWidget {
  const new({
    this.value,
    this.size = AppSizes.toolbarIcon,
    this.strokeWidth,
    this.color,
    this.child,
    this.semanticLabel,
    super.key,
  });

  /// 0.0 to 1.0, or null for indeterminate.
  final double? value;
  final double size;

  /// Defaults to a width proportional to [size].
  final double? strokeWidth;

  /// Defaults to the accent color.
  final Color? color;
  final Widget? child;
  final String? semanticLabel;

  @override
  State<ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends State<ProgressRing>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(ProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final animate =
        widget.value == null &&
        !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    if (animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final value = widget.value?.clamp(0.0, 1.0);
    final stroke =
        widget.strokeWidth ?? math.max(AppSizes.strokeWidth, widget.size / 12);
    return Semantics(
      label: widget.semanticLabel,
      value: value == null ? null : '${(value * 100).round()}%',
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => CustomPaint(
            painter: _RingPainter(
              value: value,
              phase: _controller.value,
              stroke: stroke,
              track: widget.color == null
                  ? colors.border
                  : widget.color!.withValues(alpha: 0.25),
              fill: widget.color ?? colors.accent,
            ),
            child: child,
          ),
          child: widget.child == null ? null : Center(child: widget.child),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const new({
    required this.value,
    required this.phase,
    required this.stroke,
    required this.track,
    required this.fill,
  });

  final double? value;
  final double phase;
  final double stroke;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = track);
    const top = -math.pi / 2;
    if (value case final v?) {
      if (v > 0) {
        canvas.drawArc(rect, top, math.pi * 2 * v, false, paint..color = fill);
      }
    } else {
      canvas.drawArc(
        rect,
        top + math.pi * 2 * phase,
        math.pi / 2,
        false,
        paint..color = fill,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value ||
      old.phase != phase ||
      old.stroke != stroke ||
      old.track != track ||
      old.fill != fill;
}

/// Placeholder block for loading layouts. Compose skeletons in the shape
/// of the real content; never show a lone spinner on an empty screen.
class Skeleton extends StatefulWidget {
  const new({
    this.width,
    this.height,
    this.radius = AppRadius.control,
    super.key,
  });

  /// Skeleton sized like one line of text in [style].
  factory text(TextStyle style, {double? width}) =>
      Skeleton(width: width, height: style.fontSize, radius: AppRadius.small);

  final double? width;
  final double? height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
    lowerBound: 0.6,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller
        ..stop()
        ..value = 1;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: FadeTransition(
        opacity: _controller,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: context.colors.surfaceRaised,
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
      ),
    );
  }
}
