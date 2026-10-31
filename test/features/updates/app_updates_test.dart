// Finding a newer version: Google Play through the in-app update API on
// Android, the App Store's public lookup on iOS. A failed check is never
// an error, just no update.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/core/platform/system_services.dart';
import 'package:stitch/features/updates/data/app_updates.dart';
import 'package:stitch/features/updates/domain/store_update.dart';

const _url = 'https://apps.apple.com/ng/app/stitch/id123';

String _listing(String version) => jsonEncode({
  'resultCount': 1,
  'results': [
    {'version': version, 'trackViewUrl': _url, 'bundleId': storeAppId},
  ],
});

final String _noListing = jsonEncode({'resultCount': 0, 'results': <Object>[]});

void main() {
  group('compareVersions', () {
    test('compares part by part, as numbers', () {
      expect(compareVersions('1.10.0', '1.9.2'), greaterThan(0));
      expect(compareVersions('1.0.0', '1.0.1'), lessThan(0));
      expect(compareVersions('2.0', '2.0.0'), 0);
      expect(compareVersions('1.2.0-beta', '1.2.0'), 0);
      expect(compareVersions('1.0.0', '1.0.0'), 0);
    });
  });

  group('parseAppStoreLookup', () {
    test('reads the version and page', () {
      expect(parseAppStoreLookup(_listing('1.2.0')), (
        version: '1.2.0',
        url: _url,
      ));
    });

    test('is null when the app is not listed or the answer is odd', () {
      expect(parseAppStoreLookup(_noListing), isNull);
      expect(parseAppStoreLookup('not json'), isNull);
      expect(parseAppStoreLookup('{"results": [{"version": 3}]}'), isNull);
      expect(
        parseAppStoreLookup(
          jsonEncode({
            'results': [
              {'version': '2.0.0', 'trackViewUrl': 'http://insecure'},
            ],
          }),
        ),
        isNull,
      );
    });
  });

  group('App Store', () {
    final system = FakeSystemServices(); // runs 0.1.0 (1)

    test('offers a newer version, from the device country store', () async {
      final asked = <Uri>[];
      final updates = StoreAppUpdates(
        system: system,
        isIOS: true,
        country: 'NG',
        fetch: (url) async {
          asked.add(url);
          return _listing('0.2.0');
        },
      );
      final update = await updates.check();
      expect(update?.id, 'ios:0.2.0');
      expect(update?.version, '0.2.0');
      expect(update?.storeUrl, _url);
      expect(asked.single.host, 'itunes.apple.com');
      expect(asked.single.queryParameters, {
        'bundleId': storeAppId,
        'country': 'ng',
      });
    });

    test('falls back to the default store when not sold locally', () async {
      final asked = <Uri>[];
      final updates = StoreAppUpdates(
        system: system,
        isIOS: true,
        country: 'NG',
        fetch: (url) async {
          asked.add(url);
          return url.queryParameters.containsKey('country')
              ? _noListing
              : _listing('0.3.0');
        },
      );
      expect((await updates.check())?.version, '0.3.0');
      expect(asked, hasLength(2));
    });

    test('offers nothing for the same or an older version', () async {
      for (final version in ['0.1.0', '0.0.9']) {
        final updates = StoreAppUpdates(
          system: system,
          isIOS: true,
          fetch: (_) async => _listing(version),
        );
        expect(await updates.check(), isNull, reason: version);
      }
    });

    test('a failed lookup is no update', () async {
      final updates = StoreAppUpdates(
        system: system,
        isIOS: true,
        fetch: (_) async => throw const FormatException('offline'),
      );
      expect(await updates.check(), isNull);
    });
  });

  group('Google Play', () {
    test('offers the release Play reports, on its store page', () async {
      final system = FakeSystemServices()..playUpdate = 7;
      final update = await StoreAppUpdates(
        system: system,
        isIOS: false,
      ).check();
      expect(update?.id, 'android:7');
      expect(update?.storeUrl, playStoreUrl);
      expect(update?.version, isNull);
    });

    test('offers nothing when Play has nothing newer', () async {
      final updates = StoreAppUpdates(
        system: FakeSystemServices(),
        isIOS: false,
      );
      expect(await updates.check(), isNull);
    });
  });
}
