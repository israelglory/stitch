import 'dart:math' as math;

import 'package:stitch/core/logging/logger.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/features/text/application/text_rendering.dart';
import 'package:stitch/features/timeline/domain/composition.dart';
import 'package:stitch/features/timeline/domain/models.dart';

/// Captions wrap at this fraction of the canvas width.
const captionWrapFraction = 0.8;

/// Caption text size, as a fraction of the canvas's shorter side, so
/// captions read the same in portrait and landscape.
const _captionSize = 0.065;

const _black = 0xFF000000;

/// The spoken word's color in [CaptionPreset.highlightWord].
final int captionHighlightColor = TextPalette.colors[2].toARGB32();

/// How captions in [preset] look on a [canvasWidth] x [canvasHeight]
/// canvas.
TextStyleSpec captionStyle(
  CaptionPreset preset, {
  required int canvasWidth,
  required int canvasHeight,
}) {
  final size =
      _captionSize * math.min(canvasWidth, canvasHeight) / canvasHeight;
  return switch (preset) {
    CaptionPreset.plain => TextStyleSpec(
      size: size,
      strokeColor: _black,
      strokeWidth: 0.06,
    ),
    CaptionPreset.boxed => TextStyleSpec(
      size: size,
      backgroundColor: 0xCC000000,
    ),
    CaptionPreset.highlightWord => TextStyleSpec(
      size: size,
      strokeColor: _black,
      strokeWidth: 0.1,
    ),
    CaptionPreset.outline => TextStyleSpec(
      fontId: 'anton',
      size: size * 1.15,
      strokeColor: _black,
      strokeWidth: 0.14,
    ),
  };
}

/// Where captions sit: the center's height, as a fraction of the canvas.
double captionY(CaptionPosition position) => switch (position) {
  CaptionPosition.top => 0.18,
  CaptionPosition.middle => 0.5,
  CaptionPosition.bottom => 0.78,
};

/// A stretch of a caption shown one way: with one word highlighted, or
/// (with no highlight) plain.
typedef CaptionPiece = ({int startUs, int endUs, TextHighlight? highlight});

/// How [caption] shows over time. In [CaptionPreset.highlightWord], each
/// word is highlighted from its start until the next word starts;
/// otherwise the caption is one piece.
List<CaptionPiece> captionPieces(
  ResolvedCaption caption,
  CaptionPreset preset,
) {
  final whole = [
    (startUs: caption.startUs, endUs: caption.endUs, highlight: null),
  ];
  final words = caption.words;
  if (preset != CaptionPreset.highlightWord || words.isEmpty) return whole;
  // Find each word in the text, in order. Text edited out of step with
  // its words shows without highlights.
  final ranges = <(int, int)>[];
  var cursor = 0;
  for (final w in words) {
    final at = caption.text.indexOf(w.text, cursor);
    if (at < 0) return whole;
    ranges.add((at, at + w.text.length));
    cursor = at + w.text.length;
  }
  return [
    for (var i = 0; i < words.length; i++)
      if ((
            i == 0
                ? caption.startUs
                : math.max(caption.startUs, words[i].startUs),
            i + 1 < words.length
                ? math.min(caption.endUs, words[i + 1].startUs)
                : caption.endUs,
          )
          case (final start, final end) when end > start)
        (
          startUs: start,
          endUs: end,
          highlight: TextHighlight(
            start: ranges[i].$1,
            end: ranges[i].$2,
            color: captionHighlightColor,
          ),
        ),
  ];
}

/// A caption piece drawn for the engines.
typedef CaptionImage = ({String id, int startUs, int endUs, TextRaster raster});

/// Draws every caption in [composition] for a [canvasWidth] x
/// [canvasHeight] canvas: one image per piece.
Future<List<CaptionImage>> renderCaptions(
  TextRasterizer rasterizer,
  ResolvedComposition composition, {
  required int canvasWidth,
  required int canvasHeight,
}) async {
  final style = captionStyle(
    composition.captionPreset,
    canvasWidth: canvasWidth,
    canvasHeight: canvasHeight,
  );
  final jobs = [
    for (final c in composition.captions)
      for (final (i, piece) in captionPieces(
        c,
        composition.captionPreset,
      ).indexed)
        (caption: c, index: i, piece: piece),
  ];
  // A few at a time: a long video in the highlight style has a piece per
  // word, and drawing them all at once holds every image in memory.
  final drawn = List<CaptionImage?>.filled(jobs.length, null);
  var next = 0;
  Future<void> worker() async {
    while (next < jobs.length) {
      final at = next++;
      final job = jobs[at];
      try {
        final raster = await rasterizer.render(
          text: job.caption.text,
          style: style,
          typewriter: false,
          canvasWidth: canvasWidth,
          canvasHeight: canvasHeight,
          wrapFraction: captionWrapFraction,
          highlight: job.piece.highlight,
        );
        drawn[at] = (
          id: '${job.caption.id}#${job.index}',
          startUs: job.piece.startUs,
          endUs: job.piece.endUs,
          raster: raster,
        );
      } on Object catch (e, st) {
        // One piece that cannot be drawn is left out, not every caption.
        _log.warning('Could not draw caption ${job.caption.id}', e, st);
      }
    }
  }

  await Future.wait([for (var w = 0; w < _drawAtOnce; w++) worker()]);
  return drawn.nonNulls.toList();
}

/// Caption pieces drawn at the same time.
const _drawAtOnce = 4;

const _log = Logger('captions');
