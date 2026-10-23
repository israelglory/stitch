import 'dart:async';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:stitch/core/logging/logger.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/features/ads/ads.dart';

const _log = Logger('ads');

/// The app's ad units. Debug and profile builds use Google's test units:
/// tapping the app's own live ads breaks AdMob's rules.
abstract final class AdUnits {
  static bool get _ios => defaultTargetPlatform == TargetPlatform.iOS;

  static String get banner => !kReleaseMode
      ? (_ios
            ? 'ca-app-pub-3940256099942544/2435281174'
            : 'ca-app-pub-3940256099942544/9214589741')
      : (_ios
            ? 'ca-app-pub-3925626843029360/8343531971'
            : 'ca-app-pub-3925626843029360/4404286964');

  static String get interstitial => !kReleaseMode
      ? (_ios
            ? 'ca-app-pub-3940256099942544/4411468910'
            : 'ca-app-pub-3940256099942544/1033173712')
      : (_ios
            ? 'ca-app-pub-3925626843029360/7992178189'
            : 'ca-app-pub-3925626843029360/5653875170');
}

/// Ads from Google AdMob. Consent comes first (Google's consent form,
/// shown only where the law requires it); no ad is asked for without it.
final class AdMobAds implements Ads {
  new({this.onConsentNotRequired});

  /// Told when the consent form is not needed where the user is.
  final void Function()? onConsentNotRequired;

  Future<void>? _started;
  bool _canRequest = false;
  InterstitialAd? _interstitial;

  /// Completes when the load in flight ends, however it ends.
  Completer<void>? _loading;
  Timer? _retry;
  DateTime? _lastShown;

  /// Shortest time between two full-screen ads.
  static const _minGap = Duration(seconds: 60);

  /// A failed load is tried again after this.
  static const _retryAfter = Duration(seconds: 60);

  /// Longest a caller waits for an ad still loading before going on
  /// without one.
  static const _loadWait = Duration(seconds: 3);

  /// A full-screen ad is loaded and ready (for tests).
  @visibleForTesting
  bool get interstitialReady => _interstitial != null;

  @override
  Future<void> start() => _started ??= _start();

  Future<void> _start() async {
    try {
      final updated = Completer<void>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        updated.complete,
        (error) {
          _log.warning('Consent update failed: ${error.message}');
          updated.complete();
        },
      );
      await updated.future;
      await ConsentForm.loadAndShowConsentFormIfRequired((error) {
        if (error != null) _log.warning('Consent form: ${error.message}');
      });
      final status = await ConsentInformation.instance.getConsentStatus();
      _log.info('Consent: ${status.name}');
      if (status == ConsentStatus.notRequired) {
        onConsentNotRequired?.call();
      }
      // iOS: Apple's tracking dialog, once, after Google's consent form.
      // Whatever the answer, ads keep working (personalized or not).
      await _requestTracking();
      _canRequest = await ConsentInformation.instance.canRequestAds();
      if (!_canRequest) return;
      await MobileAds.instance.initialize();
      _loadInterstitial();
    } on Object catch (e, st) {
      _log.error('Ads could not start', e, st);
    }
  }

  Future<void> _requestTracking() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
    } on Object catch (e) {
      _log.warning('Tracking authorization failed: $e');
    }
  }

  void _loadInterstitial() {
    if (!_canRequest || _interstitial != null || _loading != null) return;
    _retry?.cancel();
    final loading = _loading = Completer<void>();
    void done() {
      if (identical(_loading, loading)) _loading = null;
      if (!loading.isCompleted) loading.complete();
    }

    unawaited(
      InterstitialAd.load(
        adUnitId: AdUnits.interstitial,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitial = ad;
            done();
          },
          onAdFailedToLoad: (error) {
            _log.warning('Interstitial did not load: ${error.message}');
            done();
            // No fill now does not mean none in a minute.
            _retry?.cancel();
            _retry = Timer(_retryAfter, _loadInterstitial);
          },
        ),
      ),
    );
  }

  @override
  Future<void> showInterstitial() async {
    final last = _lastShown;
    if (last != null && DateTime.now().difference(last) < _minGap) {
      _loadInterstitial();
      return;
    }
    if (_interstitial == null) {
      // One may be moments away (opening the app and exporting at once):
      // start or join the load and give it a few seconds.
      _loadInterstitial();
      final loading = _loading;
      if (loading != null) {
        await loading.future.timeout(_loadWait, onTimeout: () {});
      }
    }
    final ad = _interstitial;
    if (ad == null) return;
    _interstitial = null;
    final closed = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        unawaited(ad.dispose());
        if (!closed.isCompleted) closed.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _log.warning('Interstitial did not show: ${error.message}');
        unawaited(ad.dispose());
        if (!closed.isCompleted) closed.complete();
      },
    );
    _lastShown = DateTime.now();
    try {
      await ad.show();
      await closed.future;
    } on Object catch (e, st) {
      _log.error('Interstitial failed', e, st);
    } finally {
      _loadInterstitial();
    }
  }

  @override
  Widget banner() => _AdMobBanner(this);

  @override
  Future<bool> privacyChoicesRequired() async {
    try {
      return await ConsentInformation.instance
              .getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;
    } on Object {
      return false;
    }
  }

  @override
  Future<void> showPrivacyChoices() =>
      ConsentForm.showPrivacyOptionsForm((error) {
        if (error != null) _log.warning('Privacy choices: ${error.message}');
      });
}

/// An anchored adaptive banner, as wide as the screen. Takes no room until
/// an ad has loaded.
class _AdMobBanner extends StatefulWidget {
  const new(this.ads);

  final AdMobAds ads;

  @override
  State<_AdMobBanner> createState() => _AdMobBannerState();
}

class _AdMobBannerState extends State<_AdMobBanner> {
  BannerAd? _ad;
  bool _loaded = false;
  int? _width;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final width = MediaQuery.sizeOf(context).width.truncate();
    if (width != _width) {
      _width = width;
      unawaited(_load(width));
    }
  }

  Future<void> _load(int width) async {
    await widget.ads.start();
    if (!mounted || !widget.ads._canRequest || width != _width) return;
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    if (!mounted || size == null || width != _width) return;
    final old = _ad;
    final ad = BannerAd(
      adUnitId: AdUnits.banner,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          _log.warning('Banner did not load: ${error.message}');
          unawaited(ad.dispose());
          if (mounted && identical(_ad, ad)) {
            setState(() {
              _ad = null;
              _loaded = false;
            });
          }
        },
      ),
    );
    setState(() {
      _ad = ad;
      _loaded = false;
    });
    unawaited(old?.dispose());
    await ad.load();
  }

  @override
  void dispose() {
    unawaited(_ad?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (ad == null || !_loaded) return const SizedBox.shrink();
    return ColoredBox(
      color: context.colors.background,
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: ad.size.width.toDouble(),
          height: ad.size.height.toDouble(),
          child: AdWidget(ad: ad),
        ),
      ),
    );
  }
}
