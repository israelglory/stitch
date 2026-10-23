import 'package:flutter/widgets.dart';

/// Ads in the app: a banner at the bottom of the projects screen, and a
/// full-screen ad before captions are generated and before an export.
///
/// Everything ad related goes through this interface, so a build without
/// ads only swaps [NoAds] in.
abstract interface class Ads {
  /// Asks for consent where the law requires it, then starts the ad SDK.
  /// Safe to call more than once; later calls wait for the first.
  Future<void> start();

  /// The banner, pinned where it is placed. Takes no room until an ad has
  /// loaded.
  Widget banner();

  /// Shows a full-screen ad, when one is ready and none showed recently.
  /// Completes when it is closed, or at once when none shows: the action
  /// it comes before goes on either way.
  Future<void> showInterstitial();

  /// Whether the user must be offered a way to change their ad privacy
  /// choices (in Settings).
  Future<bool> privacyChoicesRequired();

  /// Shows the ad privacy choices.
  Future<void> showPrivacyChoices();
}

/// No ads: tests, and builds without them.
final class NoAds implements Ads {
  const new();

  @override
  Future<void> start() async {}

  @override
  Widget banner() => const SizedBox.shrink();

  @override
  Future<void> showInterstitial() async {}

  @override
  Future<bool> privacyChoicesRequired() async => false;

  @override
  Future<void> showPrivacyChoices() async {}
}
