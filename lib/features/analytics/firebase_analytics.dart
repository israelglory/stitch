import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:stitch/core/logging/logger.dart';
import 'package:stitch/features/analytics/analytics.dart';

const _log = Logger('analytics');

/// Analytics with Google Analytics for Firebase. Daily, weekly, and monthly
/// active users come from it without any event of the app's own.
///
/// Consent: analytics and ad storage start denied (`Info.plist`,
/// `AndroidManifest.xml`). Where no consent is needed they are granted;
/// where it is, Firebase reads the choices made in Google's consent form.
final class FirebaseAppAnalytics implements Analytics {
  FirebaseAnalytics get _firebase => FirebaseAnalytics.instance;

  String? _screen;

  @override
  void screen(String screen) {
    if (screen == _screen) return;
    _screen = screen;
    _send(
      () => _firebase.logScreenView(screenName: screen, screenClass: screen),
    );
  }

  @override
  void log(String event, [Map<String, Object> parameters = const {}]) => _send(
    () => _firebase.logEvent(
      name: event,
      parameters: parameters.isEmpty ? null : parameters,
    ),
  );

  @override
  Future<void> consentNotRequired() async => _send(
    () => _firebase.setConsent(
      analyticsStorageConsentGranted: true,
      adStorageConsentGranted: true,
      adUserDataConsentGranted: true,
      adPersonalizationSignalsConsentGranted: true,
    ),
  );

  /// Analytics never gets in the way: failures are logged, not thrown.
  /// Future.sync also catches synchronous throws (reading
  /// FirebaseAnalytics.instance throws when Firebase could not start).
  void _send(Future<void> Function() call) {
    unawaited(
      Future<void>.sync(call).catchError((Object e, StackTrace st) {
        _log.warning('Analytics call failed: $e');
      }),
    );
  }
}
