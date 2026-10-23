import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:stitch/features/editor/domain/canvas_snap.dart';
import 'package:stitch/features/editor/presentation/editor_media.dart';
import 'package:stitch/features/projects/domain/project.dart';
import 'package:stitch/features/timeline/domain/models.dart';

/// An overlay drawn on the preview as the engines draw it: fitted (or
/// filled) into the canvas, then zoomed, moved, and turned by [values],
/// at their opacity, with nothing around it. Fills its parent, the
/// canvas. Shows [image] (a frame of it), or its poster.
class OverlayPicture extends StatelessWidget {
  const new({
    required this.project,
    required this.overlay,
    required this.values,
    this.image,
    super.key,
  });

  final Project project;
  final OverlayClip overlay;
  final KeyframeValues values;
  final ImageProvider? image;

  @override
  Widget build(BuildContext context) {
    final asset = project.media[overlay.mediaId];
    return LayoutBuilder(
      builder: (context, box) {
        final size = framedSize(
          box.maxWidth,
          box.maxHeight,
          (asset?.width ?? 0).toDouble(),
          (asset?.height ?? 0).toDouble(),
          fill: overlay.framing.mode == FramingMode.fill,
        );
        final picture = switch (image) {
          final image? => Image(
            image: image,
            fit: BoxFit.fill,
            gaplessPlayback: true,
          ),
          null => MediaPoster(
            project: project,
            mediaId: overlay.mediaId,
            fit: BoxFit.fill,
          ),
        };
        return Opacity(
          opacity: values.opacity.clamp(0.0, 1.0),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..translateByDouble(
                values.x * box.maxWidth,
                values.y * box.maxHeight,
                0,
                1,
              )
              ..rotateZ(values.rotationDeg * math.pi / 180)
              ..scaleByDouble(values.scale, values.scale, 1, 1),
            child: Center(
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: picture,
              ),
            ),
          ),
        );
      },
    );
  }
}
