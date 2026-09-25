import 'dart:convert';

import 'package:stitch/features/projects/domain/project.dart';
import 'package:stitch/features/timeline/domain/composition.dart';

/// The JSON document the native engines play and export (see
/// `EngineDocument.swift`): canvas, background, media files with absolute
/// paths, and the timeline resolved to absolute times.
///
/// [resolve] turns a path relative to the project folder into an absolute
/// one.
String engineDocumentJson(
  Project project, {
  required String Function(String relativePath) resolve,
}) {
  final composition = ResolvedComposition.resolve(project.timeline);
  return jsonEncode({
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
    'composition': composition.toJson(),
  });
}
