import 'dart:io';
import 'dart:typed_data';

import 'package:photo_manager/photo_manager.dart';
import 'package:stitch/core/time/time.dart';
import 'package:stitch/features/media/data/media_library.dart';
import 'package:stitch/features/media/domain/library_item.dart';
import 'package:stitch/features/timeline/domain/models.dart';

/// [MediaLibrary] backed by PhotoKit on iOS and MediaStore on Android.
final class PhotoManagerLibrary implements MediaLibrary {
  const new();

  /// Images and videos; location metadata is never requested.
  static const _option = PermissionRequestOption();

  @override
  Future<LibraryAccess> access() async =>
      _map(await PhotoManager.getPermissionState(requestOption: _option));

  @override
  Future<LibraryAccess> requestAccess() async =>
      _map(await PhotoManager.requestPermissionExtend());

  @override
  Future<void> openSystemSettings() => PhotoManager.openSetting();

  @override
  Future<void> manageLimitedSelection() => PhotoManager.presentLimited();

  @override
  Future<List<LibraryItem>> items(
    LibraryFilter filter, {
    required int page,
    int pageSize = 60,
  }) async {
    final type = switch (filter) {
      LibraryFilter.videos => RequestType.video,
      LibraryFilter.photos => RequestType.image,
      LibraryFilter.all => RequestType.common,
    };
    final paths = await PhotoManager.getAssetPathList(
      onlyAll: true,
      type: type,
      filterOption: FilterOptionGroup(orders: [const OrderOption()]),
    );
    if (paths.isEmpty) return const [];
    final assets = await paths.first.getAssetListPaged(
      page: page,
      size: pageSize,
    );
    return [
      for (final a in assets)
        if (a.type == AssetType.video || a.type == AssetType.image)
          LibraryItem(
            id: a.id,
            kind: a.type == AssetType.video ? MediaKind.video : MediaKind.photo,
            width: a.orientatedWidth,
            height: a.orientatedHeight,
            // Whole seconds, rounded down so a clip never claims more than
            // the file holds. The engine probes exact durations (M5).
            durationUs: a.type == AssetType.video
                ? a.duration * usPerSecond
                : null,
          ),
    ];
  }

  @override
  Future<Uint8List?> thumbnail(
    String id, {
    int width = 256,
    int height = 256,
  }) async {
    final asset = await AssetEntity.fromId(id);
    return await asset?.thumbnailDataWithSize(ThumbnailSize(width, height));
  }

  @override
  Future<File?> originalFile(String id) async {
    final asset = await AssetEntity.fromId(id);
    return await asset?.originFile;
  }

  static LibraryAccess _map(PermissionState state) => switch (state) {
    PermissionState.authorized => LibraryAccess.granted,
    PermissionState.limited => LibraryAccess.limited,
    PermissionState.notDetermined => LibraryAccess.notDetermined,
    PermissionState.denied ||
    PermissionState.restricted => LibraryAccess.denied,
  };
}
