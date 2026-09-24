import 'dart:io';
import 'dart:typed_data';

import 'package:stitch/features/media/domain/library_item.dart';

/// The device photo library. Implemented with photo_manager; tests use a
/// fake.
abstract interface class MediaLibrary {
  /// Current access, without prompting.
  Future<LibraryAccess> access();

  /// Shows the system prompt when possible and returns the result.
  Future<LibraryAccess> requestAccess();

  Future<void> openSystemSettings();

  /// Lets the user change a limited selection (iOS, Android 14+).
  Future<void> manageLimitedSelection();

  /// Items newest first, [pageSize] per page starting at page 0.
  Future<List<LibraryItem>> items(
    LibraryFilter filter, {
    required int page,
    int pageSize = 60,
  });

  /// A thumbnail fitting [width] x [height] pixels, as encoded image
  /// bytes. For videos this is a frame near the start.
  Future<Uint8List?> thumbnail(String id, {int width = 256, int height = 256});

  /// The original file, downloading it first if it is stored in the cloud.
  /// Null when it cannot be obtained (offline, deleted).
  Future<File?> originalFile(String id);
}
