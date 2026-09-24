import 'package:meta/meta.dart';
import 'package:stitch/features/timeline/domain/models.dart';

/// Whether the app may read the photo library.
enum LibraryAccess {
  /// Never asked. Requesting shows the system prompt.
  notDetermined,

  /// Full access.
  granted,

  /// iOS and Android 14+: only items the user picked.
  limited,

  /// Refused. Only the system settings can change it.
  denied,
}

enum LibraryFilter { videos, photos, all }

/// A photo or video in the device library.
@immutable
final class LibraryItem {
  const new({
    required this.id,
    required this.kind,
    required this.width,
    required this.height,
    this.durationUs,
  });

  final String id;

  /// [MediaKind.video] or [MediaKind.photo].
  final MediaKind kind;

  /// Display size after rotation.
  final int width;
  final int height;

  /// Null for photos.
  final int? durationUs;

  @override
  bool operator ==(Object other) => other is LibraryItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
