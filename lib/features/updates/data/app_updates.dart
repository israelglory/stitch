import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:stitch/core/logging/logger.dart';
import 'package:stitch/core/platform/system_services.dart';
import 'package:stitch/features/updates/domain/store_update.dart';

/// Finds out whether the store has a newer version than the one running.
abstract interface class AppUpdates {
  /// The newer release, or null when there is none or the store cannot be
  /// asked (offline, not installed from a store). Never throws.
  Future<StoreUpdate?> check();
}

/// Never finds an update: tests, and builds outside the stores.
final class NoAppUpdates implements AppUpdates {
  const new();

  @override
  Future<StoreUpdate?> check() async => null;
}

/// The app's id in both stores.
const storeAppId = 'xyz.olaifaglory.stitch';

const playStoreUrl =
    'https://play.google.com/store/apps/details?id=$storeAppId';

/// Google Play through its in-app update API on Android; the App Store's
/// public lookup (itunes.apple.com) on iOS.
final class StoreAppUpdates implements AppUpdates {
  new({
    required this._system,
    required this._isIOS,
    this._country,
    Future<String> Function(Uri url)? fetch,
  }) : _fetch = fetch ?? _get;

  final SystemServices _system;
  final bool _isIOS;

  /// The device's region ("NG", "GB"), for the App Store of that country.
  final String? _country;
  final Future<String> Function(Uri url) _fetch;

  static const _log = Logger('updates');

  @override
  Future<StoreUpdate?> check() async {
    try {
      return _isIOS ? await _appStore() : await _play();
    } on Object catch (e) {
      _log.info('Update check failed: $e');
      return null;
    }
  }

  Future<StoreUpdate?> _play() async {
    final code = await _system.playUpdateVersionCode();
    if (code == null) return null;
    return StoreUpdate(id: 'android:$code', storeUrl: playStoreUrl);
  }

  Future<StoreUpdate?> _appStore() async {
    // The app may not be sold in every country: fall back to the default
    // store when the device's own has no listing.
    final listing =
        (_country == null ? null : await _lookup(_country)) ??
        await _lookup(null);
    if (listing == null) return null;
    final running = (await _system.appVersion()).split(' ').first;
    if (compareVersions(listing.version, running) <= 0) return null;
    return StoreUpdate(
      id: 'ios:${listing.version}',
      storeUrl: listing.url,
      version: listing.version,
    );
  }

  Future<AppStoreListing?> _lookup(String? country) async =>
      parseAppStoreLookup(
        await _fetch(
          Uri.https('itunes.apple.com', '/lookup', {
            'bundleId': storeAppId,
            'country': ?country?.toLowerCase(),
          }),
        ),
      );

  static Future<String> _get(Uri url) async {
    const timeout = Duration(seconds: 10);
    final http = HttpClient()..connectionTimeout = timeout;
    try {
      final response = await (await http.getUrl(url)).close().timeout(timeout);
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('HTTP ${response.statusCode}', uri: url);
      }
      return await response.transform(utf8.decoder).join().timeout(timeout);
    } finally {
      http.close(force: true);
    }
  }
}

/// The App Store's answer for this app: its newest version and its page.
typedef AppStoreListing = ({String version, String url});

/// Reads an itunes.apple.com lookup response. Null when the app is not
/// listed or the answer is not what was expected.
AppStoreListing? parseAppStoreLookup(String body) {
  try {
    if (jsonDecode(body)
        case {
          'results': [
            {'version': final String version, 'trackViewUrl': final String url},
            ...,
          ],
        }
        when version.isNotEmpty && url.startsWith('https://')) {
      return (version: version, url: url);
    }
  } on FormatException {
    return null;
  }
  return null;
}
