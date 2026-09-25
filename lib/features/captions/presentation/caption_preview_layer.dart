import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/features/captions/application/caption_rendering.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';
import 'package:stitch/features/editor/application/playback_controller.dart';
import 'package:stitch/features/editor/application/resolved_texts.dart';
import 'package:stitch/features/text/application/text_rendering.dart';

/// The caption at the playhead, drawn by the editor. Only used without a
/// native preview (the fake engine, in tests and UI work); the engines
/// draw captions from images made with the same layout.
class CaptionPreviewLayer extends ConsumerWidget {
  const new({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final composition = ref.watch(resolvedCompositionProvider(projectId));
    final canvas = ref.watch(
      editorControllerProvider(projectId)
          .select((s) => s.value?.project.canvas),
    );
    final playhead = ref.watch(
      playbackControllerProvider.select((p) => p.positionUs),
    );
    if (composition == null || canvas == null) return const SizedBox.shrink();
    final caption = composition.captions
        .where((c) => c.startUs <= playhead && playhead < c.endUs)
        .firstOrNull;
    if (caption == null) return const SizedBox.shrink();
    final piece = captionPieces(
      caption,
      composition.captionPreset,
    ).where((p) => p.startUs <= playhead && playhead < p.endUs).firstOrNull;
    final spec = overlaySpecFor(
      caption.text,
      captionStyle(
        composition.captionPreset,
        canvasWidth: canvas.width,
        canvasHeight: canvas.height,
      ),
      canvasWidth: canvas.width.toDouble(),
      canvasHeight: canvas.height.toDouble(),
      wrapFraction: captionWrapFraction,
      highlight: piece?.highlight,
    );
    return IgnorePointer(
      child: CustomPaint(
        painter: _CaptionPainter(
          spec: spec,
          y: captionY(composition.captionPosition),
          canvasWidth: canvas.width.toDouble(),
        ),
      ),
    );
  }
}

class _CaptionPainter extends CustomPainter {
  const new({required this.spec, required this.y, required this.canvasWidth});

  final OverlayTextSpec spec;
  final double y;
  final double canvasWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = OverlayTextLayout(spec);
    final unit = size.width / canvasWidth;
    canvas
      ..save()
      ..translate(size.width / 2, size.height * y)
      ..scale(unit)
      ..translate(-layout.size.width / 2, -layout.size.height / 2);
    layout.paint(canvas, Offset.zero);
    canvas.restore();
    layout.dispose();
  }

  @override
  bool shouldRepaint(_CaptionPainter old) =>
      old.spec.text != spec.text ||
      old.spec.highlight != spec.highlight ||
      old.spec.fontId != spec.fontId ||
      old.spec.fontSize != spec.fontSize ||
      old.spec.backgroundColor != spec.backgroundColor ||
      old.y != y ||
      old.canvasWidth != canvasWidth;
}
