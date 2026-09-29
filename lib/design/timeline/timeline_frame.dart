import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:stitch/design/tokens.dart';

/// Labels inside fixed-height lanes stop growing here so they are not
/// clipped.
const double kTimelineMaxTextScale = 1.2;

enum TrimEdge { start, end }

/// Callbacks for dragging an item's edges. The timeline converts pixels to
/// time and applies snapping.
class TrimCallbacks {
  const new({required this.onUpdate, this.onStart, this.onEnd});

  final void Function(TrimEdge edge)? onStart;

  /// `dx` is the horizontal drag delta in logical pixels.
  final void Function(TrimEdge edge, double dx) onUpdate;
  final void Function(TrimEdge edge)? onEnd;
}

/// Keyframes of a selected timeline item, drawn on it as rhombuses.
@immutable
class KeyframeMarkers {
  const new({
    required this.positions,
    required this.labels,
    this.current,
    this.onTap,
  });

  /// Horizontal positions from the item's left edge, in logical pixels.
  final List<double> positions;

  /// What a screen reader says for each ("Keyframe at 0:04").
  final List<String> labels;

  /// Index of the keyframe under the playhead, drawn in the accent color.
  final int? current;

  /// Tapping a marker; the item moves the playhead there.
  final ValueChanged<int>? onTap;
}

/// Selection frame shared by every timeline item: an accent outline with
/// trim handles on both sides, drawn inside the item's bounds, and its
/// keyframes.
///
/// Each handle's touch area extends inward to 44pt (or half the item for
/// short items); taps still reach the item because the handles only claim
/// horizontal drags.
class TimelineItemFrame extends StatelessWidget {
  const new({
    required this.child,
    required this.selected,
    this.trim,
    this.keyframes,
    this.radius = AppRadius.control,
    super.key,
  });

  final Widget child;
  final bool selected;

  /// Shown while selected.
  final KeyframeMarkers? keyframes;

  /// Null hides the handles and shows the outline only.
  final TrimCallbacks? trim;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final hitWidth = math.min(
          AppSizes.minTouchTarget,
          constraints.maxWidth / 2,
        );
        return Stack(
          fit: StackFit.passthrough,
          children: [
            child,
            if (selected) ...[
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _FramePainter(
                      color: colors.accent,
                      grip: colors.onAccent,
                      radius: radius,
                      showHandles: trim != null,
                    ),
                  ),
                ),
              ),
              if (keyframes case final markers?) ..._markers(context, markers),
              if (trim case final trim?) ...[
                PositionedDirectional(
                  start: 0,
                  top: 0,
                  bottom: 0,
                  width: hitWidth,
                  child: _HandleHitArea(edge: TrimEdge.start, trim: trim),
                ),
                PositionedDirectional(
                  end: 0,
                  top: 0,
                  bottom: 0,
                  width: hitWidth,
                  child: _HandleHitArea(edge: TrimEdge.end, trim: trim),
                ),
              ],
            ],
          ],
        );
      },
    );
  }

  /// Each keyframe: a rhombus, and a tap target around it.
  List<Widget> _markers(BuildContext context, KeyframeMarkers markers) {
    final colors = context.colors;
    const hit = AppSizes.minTouchTarget / 2;
    return [
      for (final (i, x) in markers.positions.indexed)
        Positioned(
          left: x - hit / 2,
          top: 0,
          bottom: 0,
          width: hit,
          child: Semantics(
            button: true,
            label: markers.labels[i],
            selected: i == markers.current,
            onTap: markers.onTap == null ? null : () => markers.onTap!(i),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: markers.onTap == null ? null : () => markers.onTap!(i),
              child: Center(
                child: CustomPaint(
                  size: const Size.square(AppSizes.keyframeMarker),
                  painter: _RhombusPainter(
                    fill: i == markers.current
                        ? colors.accent
                        : colors.onOverlay,
                    edge: colors.overlay,
                  ),
                ),
              ),
            ),
          ),
        ),
    ];
  }
}

/// A keyframe marker: a square turned 45 degrees.
class _RhombusPainter extends CustomPainter {
  const new({required this.fill, required this.edge});

  final Color fill;
  final Color edge;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width / 2;
    final h = size.height / 2;
    final path = Path()
      ..moveTo(w, 0)
      ..lineTo(size.width, h)
      ..lineTo(w, size.height)
      ..lineTo(0, h)
      ..close();
    canvas
      ..drawPath(path, Paint()..color = fill)
      ..drawPath(
        path,
        Paint()
          ..color = edge
          ..style = PaintingStyle.stroke
          ..strokeWidth = AppSizes.borderWidth,
      );
  }

  @override
  bool shouldRepaint(_RhombusPainter old) =>
      old.fill != fill || old.edge != edge;
}

class _HandleHitArea extends StatelessWidget {
  const new({required this.edge, required this.trim});

  final TrimEdge edge;
  final TrimCallbacks trim;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (_) => trim.onStart?.call(edge),
      onHorizontalDragUpdate: (d) => trim.onUpdate(edge, d.delta.dx),
      onHorizontalDragEnd: (_) => trim.onEnd?.call(edge),
      onHorizontalDragCancel: () => trim.onEnd?.call(edge),
    );
  }
}

class _FramePainter extends CustomPainter {
  const new({
    required this.color,
    required this.grip,
    required this.radius,
    required this.showHandles,
  });

  final Color color;
  final Color grip;
  final double radius;
  final bool showHandles;

  static const double _gripHeight = 12;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final handle = showHandles
        ? math.min(AppSizes.trimHandleWidth, size.width / 3)
        : AppSizes.strokeWidth;
    final inner = RRect.fromLTRBR(
      handle,
      AppSizes.strokeWidth,
      size.width - handle,
      size.height - AppSizes.strokeWidth,
      Radius.circular(math.max(0, radius - AppSizes.strokeWidth)),
    );
    canvas.drawDRRect(outer, inner, Paint()..color = color);

    if (!showHandles || handle < AppSizes.trimHandleWidth / 2) return;
    final gripPaint = Paint()
      ..color = grip
      ..strokeWidth = AppSizes.strokeWidth
      ..strokeCap = StrokeCap.round;
    final top = (size.height - _gripHeight) / 2;
    for (final x in [handle / 2, size.width - handle / 2]) {
      canvas.drawLine(Offset(x, top), Offset(x, top + _gripHeight), gripPaint);
    }
  }

  @override
  bool shouldRepaint(_FramePainter old) =>
      old.color != color ||
      old.grip != grip ||
      old.radius != radius ||
      old.showHandles != showHandles;
}
