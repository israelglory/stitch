import 'dart:convert';

import 'package:stitch/features/captions/application/caption_rendering.dart';
import 'package:stitch/features/projects/domain/project.dart';
import 'package:stitch/features/text/application/text_rendering.dart';
import 'package:stitch/features/text/domain/text_motion.dart';
import 'package:stitch/features/timeline/domain/composition.dart';
import 'package:stitch/features/timeline/domain/models.dart';

/// The JSON document the native engines play and export (see
/// `EngineDocument.swift`): canvas, background, media files with absolute
/// paths, the timeline resolved to absolute times, and overlays (text drawn
/// to images) to place on top.
///
/// [resolve] turns a path relative to the project folder into an absolute
/// one. [texts] holds the images of each text item to show, by id; text
/// items without one are left out (the editor draws the one being edited
/// itself). [captions] are the caption images, placed above the text.
/// [version] numbers documents, so the editor can tell when the
/// engine shows this one.
String engineDocumentJson(
  Project project, {
  required String Function(String relativePath) resolve,
  Map<String, TextRaster> texts = const {},
  List<CaptionImage> captions = const [],
  int version = 0,
  ResolvedComposition? composition,
}) {
  final resolved = composition ?? ResolvedComposition.resolve(project.timeline);
  return jsonEncode({
    'version': version,
    'canvas': {
      'width': project.canvas.width,
      'height': project.canvas.height,
      'frameRate': project.frameRate,
    },
    'background': switch (project.background) {
      SolidBackground(:final color) => {'type': 'solid', 'color': color},
      BlurBackground() => {'type': 'blur'},
    },
    'media': {
      for (final asset in project.media.values)
        asset.id: {
          'path': resolve(asset.path),
          'kind': asset.kind.name,
          // Full source length; Media3 needs it before clipping.
          'durationUs': ?asset.durationUs,
          'hasAudio': asset.hasAudio,
          if (asset.proxyPath case final proxy?) 'proxyPath': resolve(proxy),
        },
    },
    'composition': resolved.toJson(),
    'overlays': [
      for (final t in resolved.texts)
        if (texts[t.id] case final raster?)
          _overlay(
            id: t.id,
            startUs: t.startUs,
            endUs: t.endUs,
            raster: raster,
            x: t.transform.x,
            y: t.transform.y,
            scale: t.transform.scale,
            rotationDeg: t.transform.rotationDeg,
            animationIn: t.animationIn,
            animationOut: t.animationOut,
          ),
      for (final c in captions)
        _overlay(
          id: c.id,
          startUs: c.startUs,
          endUs: c.endUs,
          raster: c.raster,
          x: 0.5,
          y: captionY(resolved.captionPosition),
          scale: 1,
          rotationDeg: 0,
          animationIn: TextAnimation.none,
          animationOut: TextAnimation.none,
        ),
    ],
  });
}

/// An image to place on the canvas: centered at ([x], [y]) (fractions of
/// the canvas, y down), [raster]'s size times [scale], turned [rotationDeg]
/// clockwise, entering and leaving as the animations say.
Map<String, Object> _overlay({
  required String id,
  required int startUs,
  required int endUs,
  required TextRaster raster,
  required double x,
  required double y,
  required double scale,
  required double rotationDeg,
  required TextAnimation animationIn,
  required TextAnimation animationOut,
}) {
  final durationUs = endUs - startUs;
  return {
    'id': id,
    'startUs': startUs,
    'endUs': endUs,
    'images': raster.paths,
    'width': raster.width,
    'height': raster.height,
    'x': x,
    'y': y,
    'scale': scale,
    'rotationDeg': rotationDeg,
    'animationIn': {
      'type': animationIn.name,
      'durationUs': textAnimationUs(animationIn, durationUs),
    },
    'animationOut': {
      'type': animationOut.name,
      'durationUs': textAnimationUs(animationOut, durationUs),
    },
  };
}
