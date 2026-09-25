import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart' show TextAlign;
import 'package:path/path.dart' as p;
import 'package:stitch/core/hash/stable_key.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/features/timeline/domain/models.dart';

/// Disk budget for drawn text; pruned at startup.
const int textCacheBytes = 50 * 1024 * 1024;

/// Text wraps at this fraction of the canvas width.
const textWrapFraction = 0.9;

/// The painter input for [text] in [style] on a canvas [canvasWidth] x
/// [canvasHeight] pixels.
OverlayTextSpec overlaySpecFor(
  String text,
  TextStyleSpec style, {
  required double canvasWidth,
  required double canvasHeight,
  double wrapFraction = textWrapFraction,
  TextHighlight? highlight,
}) => OverlayTextSpec(
  text: text,
  fontId: style.fontId,
  fontSize: style.size * canvasHeight,
  color: style.color,
  strokeColor: style.strokeColor,
  strokeWidth: style.strokeWidth,
  backgroundColor: style.backgroundColor,
  align: switch (style.alignment) {
    TextAlignment.start => TextAlign.left,
    TextAlignment.center => TextAlign.center,
    TextAlignment.end => TextAlign.right,
  },
  maxWidth: canvasWidth * wrapFraction,
  highlight: highlight,
);

/// A text item drawn for the engines.
final class TextRaster {
  const new({required this.paths, required this.width, required this.height});

  /// One image, or a typewriter's frames from the first letter to all.
  final List<String> paths;

  /// Size on the canvas at scale 1, in canvas pixels.
  final double width;
  final double height;
}

/// Draws text items to images for the engines.
abstract interface class TextRasterizer {
  /// Most frames a typewriter is drawn in.
  static const maxTypewriterFrames = 24;

  /// Draws [text] in [style] for a [canvasWidth] x [canvasHeight] canvas;
  /// a [typewriter] gets one frame per step of the reveal. Lines wrap at
  /// [wrapFraction] of the width; [highlight] colors part of the text.
  Future<TextRaster> render({
    required String text,
    required TextStyleSpec style,
    required bool typewriter,
    required int canvasWidth,
    required int canvasHeight,
    double wrapFraction = textWrapFraction,
    TextHighlight? highlight,
  });

  /// Forgets images drawn earlier (their files were deleted).
  void forget();
}

/// Draws text items to PNG files, cached on disk by what they show. Both
/// engines only place these images, so text looks the same on every
/// platform, in preview and in export.
class PngTextRasterizer implements TextRasterizer {
  new(this.directory, {this.pixelRatio = 2});

  final Directory directory;

  /// Images are drawn this many times the canvas resolution, so text
  /// stays sharp at exports larger than the canvas.
  final double pixelRatio;

  final _inFlight = <String, Future<TextRaster>>{};

  /// Images drawn or found this session, most recent last. The disk cache
  /// is only pruned at startup, so these stay valid.
  final _done = <String, TextRaster>{};

  /// Enough for a long video in the highlight style (a piece per word).
  static const _doneLimit = 5000;

  @override
  void forget() => _done.clear();

  /// Bump when drawing changes, so cached images are redrawn.
  static const _version = 1;

  @override
  Future<TextRaster> render({
    required String text,
    required TextStyleSpec style,
    required bool typewriter,
    required int canvasWidth,
    required int canvasHeight,
    double wrapFraction = textWrapFraction,
    TextHighlight? highlight,
  }) {
    final key = stableKey(
      jsonEncode({
        'v': _version,
        'text': text,
        'style': style.toJson(),
        'typewriter': typewriter,
        'w': canvasWidth,
        'h': canvasHeight,
        'r': pixelRatio,
        if (wrapFraction != textWrapFraction) 'wrap': wrapFraction,
        if (highlight != null)
          'highlight': [highlight.start, highlight.end, highlight.color],
      }),
    );
    if (_done.remove(key) case final raster?) {
      return Future.value(_done[key] = raster);
    }
    return _inFlight[key] ??=
        _render(
              key,
              overlaySpecFor(
                text,
                style,
                canvasWidth: canvasWidth.toDouble(),
                canvasHeight: canvasHeight.toDouble(),
                wrapFraction: wrapFraction,
                highlight: highlight,
              ),
              typewriter: typewriter,
              // A block body: returning the removed future would make this one
              // wait for itself.
            )
            .then((raster) {
              _done[key] = raster;
              if (_done.length > _doneLimit) _done.remove(_done.keys.first);
              return raster;
            })
            .whenComplete(() {
              unawaited(_inFlight.remove(key));
            });
  }

  Future<TextRaster> _render(
    String key,
    OverlayTextSpec spec, {
    required bool typewriter,
  }) async {
    final dir = Directory(p.join(directory.path, key));
    final meta = File(p.join(dir.path, 'meta.json'));
    if (meta.existsSync()) {
      final json =
          jsonDecode(await meta.readAsString()) as Map<String, dynamic>;
      final count = json['frames'] as int;
      final paths = [
        for (var i = 0; i < count; i++) p.join(dir.path, '$i.png'),
      ];
      // Cache pruning deletes files one by one; redraw if any is gone.
      if (paths.every((path) => File(path).existsSync())) {
        return TextRaster(
          paths: paths,
          width: (json['width'] as num).toDouble(),
          height: (json['height'] as num).toDouble(),
        );
      }
    }

    await dir.create(recursive: true);
    final layout = OverlayTextLayout(spec);
    try {
      final characters = layout.characterCount;
      final reveals = typewriter && characters > 1
          ? [
              for (
                var i = 1;
                i <= math.min(characters, TextRasterizer.maxTypewriterFrames);
                i++
              )
                (characters *
                        i /
                        math.min(
                          characters,
                          TextRasterizer.maxTypewriterFrames,
                        ))
                    .ceil(),
            ]
          : [null];
      final paths = <String>[];
      for (final (i, revealed) in reveals.indexed) {
        final image = await layout.toImage(
          pixelRatio: pixelRatio,
          revealed: revealed,
        );
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        final path = p.join(dir.path, '$i.png');
        await _writeAtomically(path, png!.buffer.asUint8List());
        paths.add(path);
      }
      // Written last: its presence means every frame is on disk.
      await _writeAtomically(
        meta.path,
        utf8.encode(
          jsonEncode({
            'frames': paths.length,
            'width': layout.size.width,
            'height': layout.size.height,
          }),
        ),
      );
      return TextRaster(
        paths: paths,
        width: layout.size.width,
        height: layout.size.height,
      );
    } finally {
      layout.dispose();
    }
  }

  static Future<void> _writeAtomically(String path, List<int> bytes) async {
    final temp = File('$path.part');
    await temp.writeAsBytes(bytes, flush: true);
    await temp.rename(path);
  }
}
