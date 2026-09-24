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

/// Selection frame shared by every timeline item: an accent outline with
/// trim handles on both sides, drawn inside the item's bounds.
///
/// Each handle's touch area extends inward to 44pt (or half the item for
/// short items); taps still reach the item because the handles only claim
/// horizontal drags.
class TimelineItemFrame extends StatelessWidget {
  const new({
    required this.child,
    required this.selected,
    this.trim,
    this.radius = AppRadius.control,
    super.key,
  });

  final Widget child;
  final bool selected;

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
