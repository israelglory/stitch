import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stitch/app/providers.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/features/projects/domain/project.dart';

/// Poster still of [mediaId] in [project], filling its box. Neutral when
/// the media has no poster or the file is gone.
class MediaPoster extends ConsumerWidget {
  const new({
    required this.project,
    required this.mediaId,
    this.fit = BoxFit.cover,
    this.cacheWidth,
    super.key,
  });

  final Project project;
  final String mediaId;
  final BoxFit fit;

  /// Decode width in physical pixels; keeps timeline frames small.
  final int? cacheWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = project.media[mediaId]?.posterPath;
    final fallback = ColoredBox(color: context.colors.surfaceRaised);
    if (path == null) return fallback;
    final store = ref.watch(projectStoreProvider);
    return Image.file(
      File(store.resolve(project.id, path)),
      fit: fit,
      cacheWidth: cacheWidth,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}
