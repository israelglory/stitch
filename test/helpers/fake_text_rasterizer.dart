import 'package:stitch/design/design.dart';
import 'package:stitch/features/text/application/text_rendering.dart';
import 'package:stitch/features/timeline/domain/models.dart';

/// Records what it would draw; returns made-up paths and a size from the
/// text length. Real drawing needs the engine's image codecs, which widget
/// tests do not run.
class FakeTextRasterizer implements TextRasterizer {
  final rendered = <String>[];

  /// Highlights asked for, in order (null for none).
  final highlights = <TextHighlight?>[];

  @override
  Future<TextRaster> render({
    required String text,
    required TextStyleSpec style,
    required bool typewriter,
    required int canvasWidth,
    required int canvasHeight,
    double wrapFraction = textWrapFraction,
    TextHighlight? highlight,
  }) async {
    rendered.add(text);
    highlights.add(highlight);
    final frames = typewriter ? text.length.clamp(1, 24) : 1;
    return TextRaster(
      paths: [
        for (var i = 0; i < frames; i++)
          '/text/${Object.hash(text, highlight)}/$i.png',
      ],
      width: text.length * style.size * canvasHeight * 0.6,
      height: style.size * canvasHeight * 1.2,
    );
  }

  @override
  void forget() {}
}
