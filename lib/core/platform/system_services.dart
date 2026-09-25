import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:stitch/core/errors/failure.dart';
import 'package:stitch/engine/pigeon/engine_api.g.dart';

/// How saving to the photo library went.
enum GallerySave { saved, denied, permanentlyDenied }

/// What the app asks of the phone outside editing: free space, the photo
/// library, sharing, links, and keeping the screen on.
abstract interface class SystemServices {
  /// Bytes free for new files where [path] is (or would be).
  Future<int> freeSpace(String path);

  /// Copies the video at [path] into Photos (iOS) or Movies/Stitch
  /// (Android), asking for access when needed.
  Future<GallerySave> saveVideo(String path);

  Future<void> share(String path, {required String mimeType});

  Future<void> openUrl(String url);

  Future<void> keepScreenOn({required bool on});

  /// Like "0.1.0 (1)".
  Future<String> appVersion();

  /// Asks to show export progress notifications (Android 13 and later).
  Future<bool> requestNotifications();

  Future<void> openAppSettings();
}

/// Throws [InsufficientStorageFailure] unless [neededBytes] fit where
/// [path] is.
Future<void> ensureSpace(
  SystemServices system,
  String path,
  int neededBytes,
) async {
  final free = await system.freeSpace(path);
  if (free < neededBytes) {
    throw InsufficientStorageFailure(
      requiredBytes: neededBytes,
      availableBytes: free,
    );
  }
}

/// Over the Pigeon device API (DeviceHost.swift and DeviceHost.kt).
class NativeSystemServices implements SystemServices {
  new({DeviceHostApi? host}) : _host = host ?? DeviceHostApi();

  final DeviceHostApi _host;

  @override
  Future<int> freeSpace(String path) => _guard(() => _host.freeSpace(path));

  @override
  Future<GallerySave> saveVideo(String path) => _guard(() async {
    return switch (await _host.saveVideoToGallery(path)) {
      GallerySaveResult.saved => GallerySave.saved,
      GallerySaveResult.denied => GallerySave.denied,
      GallerySaveResult.permanentlyDenied => GallerySave.permanentlyDenied,
    };
  });

  @override
  Future<void> share(String path, {required String mimeType}) =>
      _guard(() => _host.shareFile(path, mimeType));

  @override
  Future<void> openUrl(String url) => _guard(() => _host.openUrl(url));

  @override
  Future<void> keepScreenOn({required bool on}) =>
      _guard(() => _host.setKeepScreenOn(on));

  @override
  Future<String> appVersion() => _guard(_host.appVersion);

  @override
  Future<bool> requestNotifications() => _guard(_host.requestNotifications);

  @override
  Future<void> openAppSettings() => _guard(_host.openAppSettings);

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on PlatformException catch (e, st) {
      throw UnexpectedFailure(cause: e, stackTrace: st);
    }
  }
}

/// For tests and platforms without the native side. Records what it was
/// asked to do.
class FakeSystemServices implements SystemServices {
  /// Reported by [freeSpace].
  int free = 64 * 1024 * 1024 * 1024;
  GallerySave saveResult = GallerySave.saved;
  final saved = <String>[];
  final shared = <String>[];
  final opened = <String>[];
  bool screenKeptOn = false;
  bool notificationsAllowed = true;
  int settingsOpened = 0;

  @override
  Future<int> freeSpace(String path) async => free;

  @override
  Future<GallerySave> saveVideo(String path) async {
    if (saveResult == GallerySave.saved) saved.add(path);
    return saveResult;
  }

  @override
  Future<void> share(String path, {required String mimeType}) async =>
      shared.add(path);

  @override
  Future<void> openUrl(String url) async => opened.add(url);

  @override
  Future<void> keepScreenOn({required bool on}) async => screenKeptOn = on;

  @override
  Future<String> appVersion() async => '0.1.0 (1)';

  @override
  Future<bool> requestNotifications() async => notificationsAllowed;

  @override
  Future<void> openAppSettings() async => settingsOpened++;
}

/// Native on iOS and Android; the fake elsewhere.
SystemServices platformSystemServices() => Platform.isIOS || Platform.isAndroid
    ? NativeSystemServices()
    : FakeSystemServices();
