import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stitch/features/timeline/domain/models.dart';

part 'project.freezed.dart';
part 'project.g.dart';

enum AspectPreset { portrait9x16, landscape16x9, square, portrait4x5, original }

/// Output frame size in pixels.
@freezed
abstract class ProjectCanvas with _$ProjectCanvas {
  const factory({
    required AspectPreset preset,
    required int width,
    required int height,
  }) = _ProjectCanvas;
  const new _();

  factory fromJson(Map<String, dynamic> json) => _$ProjectCanvasFromJson(json);

  /// Canvas for [preset]. [original] is the first clip's display size
  /// (after rotation), used only for [AspectPreset.original].
  factory forPreset(AspectPreset preset, {(int, int)? original}) {
    final (w, h) = switch (preset) {
      AspectPreset.portrait9x16 => (1080, 1920),
      AspectPreset.landscape16x9 => (1920, 1080),
      AspectPreset.square => (1080, 1080),
      AspectPreset.portrait4x5 => (1080, 1350),
      AspectPreset.original => original ?? (1080, 1920),
    };
    return ProjectCanvas(preset: preset, width: _even(w), height: _even(h));
  }

  double get aspectRatio => width / height;
}

/// Encoders need even dimensions.
int _even(int v) => v.isOdd ? v + 1 : v;

/// What fills canvas areas the video does not cover.
@freezed
sealed class CanvasBackground with _$CanvasBackground {
  /// A solid ARGB color from the neutral palette.
  const factory solid({@Default(0xFF000000) int color}) = SolidBackground;

  /// A blurred, scaled-up copy of the current clip.
  const factory blur() = BlurBackground;

  factory fromJson(Map<String, dynamic> json) =>
      _$CanvasBackgroundFromJson(json);
}

/// A media file imported into a project. Files live inside the project
/// folder, so projects keep working when the gallery changes.
@freezed
abstract class MediaAsset with _$MediaAsset {
  const factory({
    required String id,
    required MediaKind kind,

    /// Path of the imported copy, relative to the project folder.
    required String path,

    /// Display size after rotation, in pixels. Zero for audio.
    @Default(0) int width,
    @Default(0) int height,

    /// Null for photos.
    int? durationUs,

    /// A still frame, relative to the project folder.
    String? posterPath,

    /// Name shown for audio items, from the source file.
    @Default('') String displayName,

    /// False for videos without a sound track and for photos.
    @Default(true) bool hasAudio,

    /// A 720p copy for preview, relative to the project folder, when the
    /// source is larger than 1080p. Export always uses [path].
    String? proxyPath,
  }) = _MediaAsset;

  factory fromJson(Map<String, dynamic> json) => _$MediaAssetFromJson(json);
}

/// A saved project: one JSON document per project.
@freezed
abstract class Project with _$Project {
  const factory({
    required int schemaVersion,
    required String id,
    required String name,
    required DateTime createdAt,
    required DateTime updatedAt,
    required ProjectCanvas canvas,
    @Default(CanvasBackground.solid()) CanvasBackground background,

    /// Frame rate sources are conformed to; chosen again at export.
    @Default(30) int frameRate,
    @Default(Timeline.empty) Timeline timeline,

    /// Every file the timeline refers to, by media id.
    @Default(<String, MediaAsset>{}) Map<String, MediaAsset> media,
  }) = _Project;

  factory fromJson(Map<String, dynamic> json) => _$ProjectFromJson(json);
}

/// What the home grid needs about a project, kept in the project index so
/// the grid loads without opening every project.
@freezed
abstract class ProjectSummary with _$ProjectSummary {
  const factory({
    required String id,
    required String name,
    required DateTime createdAt,
    required DateTime updatedAt,
    required int durationUs,

    /// Poster of the first clip, relative to the project folder.
    String? posterPath,
  }) = _ProjectSummary;

  factory fromJson(Map<String, dynamic> json) => _$ProjectSummaryFromJson(json);
}
