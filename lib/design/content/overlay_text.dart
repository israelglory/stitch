import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:stitch/design/tokens.dart';

/// Fonts offered for text in the video. User content, not UI type: the
/// interface itself uses Inter only. All are under the SIL Open Font
/// License (see assets/licenses/).
enum OverlayFont {
  inter('inter', 'Inter', 'Inter', FontWeight.w600),
  anton('anton', 'Anton', 'Anton', FontWeight.w400),
  bebas('bebas', 'BebasNeue', 'Bebas Neue', FontWeight.w400),
  serif('dmSerif', 'DMSerifDisplay', 'DM Serif Display', FontWeight.w400),
  script('pacifico', 'Pacifico', 'Pacifico', FontWeight.w400),
  mono('spaceMono', 'SpaceMono', 'Space Mono', FontWeight.w700);

  new(this.id, this.family, this.displayName, this.weight);

  /// Stored in projects.
  final String id;
  final String family;

  /// The font's own name, shown in its own face in the font picker.
  final String displayName;
  final FontWeight weight;

  /// The font for [id]; Inter when unknown.
  static OverlayFont byId(String id) =>
      values.firstWhere((f) => f.id == id, orElse: () => inter);
}

/// Colors offered for text, stroke, and background box. Content colors:
/// they appear in the user's video.
abstract final class TextPalette {
  static const colors = <Color>[
    Color(0xFFFFFFFF),
    Color(0xFF000000),
    Color(0xFFF2C94C),
    Color(0xFFEB5757),
    Color(0xFF6FCF97),
    Color(0xFF56CCF2),
    Color(0xFFBB6BD9),
    Color(0xFFF2994A),
  ];

  static Color fromArgb(int argb) => Color(argb);
}

/// A text overlay's look, in pixels of the surface it is drawn on.
@immutable
class OverlayTextSpec {
  const new({
    required this.text,
    required this.fontId,
    required this.fontSize,
    required this.color,
    required this.maxWidth,
    this.strokeColor,
    this.strokeWidth = 0,
    this.backgroundColor,
    this.align = TextAlign.center,
    this.highlight,
  });

  final String text;
  final String fontId;
  final double fontSize;

  /// ARGB.
  final int color;
  final int? strokeColor;

  /// Stroke width as a fraction of [fontSize].
  final double strokeWidth;
  final int? backgroundColor;
  final TextAlign align;

  /// Lines wrap at this width.
  final double maxWidth;

  /// A part of [text] in another color (the word being spoken, in
  /// captions).
  final TextHighlight? highlight;
}

/// Characters [start] to [end] (UTF-16 offsets) of a text, in [color]
/// (ARGB).
@immutable
class TextHighlight {
  const new({required this.start, required this.end, required this.color});

  final int start;
  final int end;
  final int color;

  @override
  bool operator ==(Object other) =>
      other is TextHighlight &&
      other.start == start &&
      other.end == end &&
      other.color == color;

  @override
  int get hashCode => Object.hash(start, end, color);
}

/// Lays out and paints a text overlay: the background box, the stroke,
/// then the text. The one renderer of overlay text; the engines draw
/// images made with it, and the editor draws it live while editing.
class OverlayTextLayout {
  factory(OverlayTextSpec spec) {
    final font = OverlayFont.byId(spec.fontId);
    final hasStroke = spec.strokeColor != null && spec.strokeWidth > 0;
    final stroke = hasStroke ? spec.strokeWidth * spec.fontSize : 0.0;
    final hasBox = spec.backgroundColor != null;
    final padX = hasBox ? spec.fontSize * 0.3 : 0.0;
    final padY = hasBox ? spec.fontSize * 0.15 : 0.0;
    final margin = stroke + (hasBox ? 0 : spec.fontSize * 0.05);

    TextStyle style(Paint? foreground) => TextStyle(
      fontFamily: font.family,
      fontWeight: font.weight,
      fontSize: spec.fontSize,
      height: 1.2,
      color: foreground == null ? Color(spec.color) : null,
      foreground: foreground,
    );

    final wrapWidth = math.max(
      spec.fontSize,
      spec.maxWidth - 2 * (padX + margin),
    );
    final highlight = spec.highlight;
    final text = spec.text;
    InlineSpan span(TextStyle s, {required bool fill}) {
      if (highlight == null ||
          highlight.start < 0 ||
          highlight.end > text.length ||
          highlight.start >= highlight.end) {
        return TextSpan(text: text, style: s);
      }
      // Only the fill changes color; the stroke stays whole.
      return TextSpan(
        style: s,
        children: [
          TextSpan(text: text.substring(0, highlight.start)),
          TextSpan(
            text: text.substring(highlight.start, highlight.end),
            style: fill ? TextStyle(color: Color(highlight.color)) : null,
          ),
          TextSpan(text: text.substring(highlight.end)),
        ],
      );
    }

    TextPainter painter(TextStyle s, {bool fill = false}) => TextPainter(
      text: span(s, fill: fill),
      textAlign: spec.align,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: wrapWidth);

    final fill = painter(style(null), fill: true);
    final strokePainter = hasStroke
        ? painter(
            style(
              Paint()
                ..style = PaintingStyle.stroke
                // Half the stroke falls inside the glyph outline.
                ..strokeWidth = stroke * 2
                ..strokeJoin = StrokeJoin.round
                ..color = Color(spec.strokeColor!),
            ),
          )
        : null;
    final inset = Offset(padX + margin, padY + margin);
    return OverlayTextLayout._(
      spec: spec,
      fill: fill,
      stroke: strokePainter,
      inset: inset,
      size: Size(fill.width + inset.dx * 2, fill.height + inset.dy * 2),
    );
  }

  new _({
    required this.spec,
    required this._fill,
    required this._stroke,
    required this._inset,
    required this.size,
  });

  final OverlayTextSpec spec;
  final TextPainter _fill;
  final TextPainter? _stroke;
  final Offset _inset;

  /// The box the overlay occupies, including padding and stroke.
  final Size size;

  /// Characters, as the reader counts them (for typewriter reveals).
  int get characterCount => spec.text.characters.length;

  /// Paints the overlay with its top left at [origin]. With [revealed],
  /// only that many characters show; the layout does not change.
  void paint(Canvas canvas, Offset origin, {int? revealed}) {
    if (spec.backgroundColor case final background?) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          origin & size,
          Radius.circular(spec.fontSize * 0.2),
        ),
        Paint()..color = Color(background),
      );
    }
    final at = origin + _inset;
    final count = revealed;
    if (count == null || count >= characterCount) {
      _stroke?.paint(canvas, at);
      _fill.paint(canvas, at);
      return;
    }
    // Hide the rest by clipping to the revealed characters' boxes, which
    // keeps every line exactly where the full text puts it.
    final end = spec.text.characters.take(count).string.length;
    final boxes = _fill.getBoxesForSelection(
      TextSelection(baseOffset: 0, extentOffset: end),
    );
    if (boxes.isEmpty) return;
    final grow = spec.fontSize * 0.2 + (spec.strokeWidth * spec.fontSize);
    final clip = Path();
    for (final box in boxes) {
      clip.addRect(box.toRect().inflate(grow).shift(at));
    }
    canvas
      ..save()
      ..clipPath(clip);
    _stroke?.paint(canvas, at);
    _fill.paint(canvas, at);
    canvas.restore();
  }

  /// The overlay as an image at [pixelRatio] times its size.
  Future<ui.Image> toImage({double pixelRatio = 1, int? revealed}) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(pixelRatio);
    paint(canvas, Offset.zero, revealed: revealed);
    final picture = recorder.endRecording();
    try {
      return await picture.toImage(
        math.max(1, (size.width * pixelRatio).ceil()),
        math.max(1, (size.height * pixelRatio).ceil()),
      );
    } finally {
      // Its native memory goes now, not whenever the collector runs.
      picture.dispose();
    }
  }

  void dispose() {
    _fill.dispose();
    _stroke?.dispose();
  }
}

/// "Aa" in [font], for the font picker. The only UI text that is not
/// Inter: it shows what the user's text will look like.
class OverlayFontSample extends StatelessWidget {
  const new(this.font, {super.key});

  final OverlayFont font;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Text(
      'Aa',
      style: TextStyle(
        fontFamily: font.family,
        fontWeight: font.weight,
        fontSize: AppFontSizes.title,
        color: context.colors.textPrimary,
      ),
    ),
  );
}
