import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:stitch/features/media/data/media_library.dart';

/// Thumbnail of a library item, loaded through [MediaLibrary] and cached by
/// Flutter's bounded image cache like any other image.
@immutable
class LibraryThumbnail extends ImageProvider<LibraryThumbnail> {
  const new(this.library, this.id, {this.size = 256});

  final MediaLibrary library;
  final String id;
  final int size;

  @override
  Future<LibraryThumbnail> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    LibraryThumbnail key,
    ImageDecoderCallback decode,
  ) => MultiFrameImageStreamCompleter(
    codec: _load(decode),
    scale: 1,
    debugLabel: 'LibraryThumbnail($id)',
  );

  Future<ui.Codec> _load(ImageDecoderCallback decode) async {
    final bytes = await library.thumbnail(id, width: size, height: size);
    if (bytes == null || bytes.isEmpty) {
      throw StateError('No thumbnail for $id');
    }
    return await decode(await ui.ImmutableBuffer.fromUint8List(bytes));
  }

  @override
  bool operator ==(Object other) =>
      other is LibraryThumbnail && other.id == id && other.size == size;

  @override
  int get hashCode => Object.hash(id, size);
}
