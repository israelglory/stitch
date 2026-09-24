import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stitch/features/editor/application/filmstrip.dart';
import 'package:stitch/features/editor/presentation/editor_media.dart';
import 'package:stitch/features/projects/domain/project.dart';

/// One filmstrip frame: a real frame of the source near [sourceUs] when
/// the engine can make one, otherwise the media's poster.
class ClipFrame extends ConsumerStatefulWidget {
  const new({
    required this.project,
    required this.mediaId,
    required this.mediaPath,
    required this.sourceUs,
    required this.cacheWidth,
    super.key,
  });

  final Project project;
  final String mediaId;

  /// Absolute path of the source file.
  final String mediaPath;
  final int sourceUs;
  final int cacheWidth;

  @override
  ConsumerState<ClipFrame> createState() => _ClipFrameState();
}

class _ClipFrameState extends ConsumerState<ClipFrame> {
  late Future<String?> _frame;

  @override
  void initState() {
    super.initState();
    _request();
  }

  @override
  void didUpdateWidget(ClipFrame old) {
    super.didUpdateWidget(old);
    if (old.mediaPath != widget.mediaPath || old.sourceUs != widget.sourceUs) {
      _request();
    }
  }

  void _request() {
    _frame = ref
        .read(filmstripProvider)
        .frame(widget.mediaPath, widget.sourceUs);
  }

  @override
  Widget build(BuildContext context) {
    final poster = MediaPoster(
      project: widget.project,
      mediaId: widget.mediaId,
      cacheWidth: widget.cacheWidth,
    );
    return FutureBuilder<String?>(
      future: _frame,
      builder: (context, snapshot) {
        final path = snapshot.data;
        if (path == null) return poster;
        return Image.file(
          File(path),
          fit: BoxFit.cover,
          cacheWidth: widget.cacheWidth,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => poster,
        );
      },
    );
  }
}
