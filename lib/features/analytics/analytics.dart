/// Usage analytics: which screens are opened and which features are used,
/// for daily visitors and feature counts. Nothing about the user's media
/// or projects is sent: screens are route patterns (`/editor/:projectId`),
/// and events carry counts and settings only.
///
/// Everything goes through this interface, so a build without analytics
/// only swaps [NoAnalytics] in.
abstract interface class Analytics {
  /// Records that [screen] (a route pattern) is showing.
  void screen(String screen);

  /// Records [event] (one of [AppEvents]) with [parameters]: strings and
  /// numbers only.
  void log(String event, [Map<String, Object> parameters = const {}]);

  /// No consent is needed where the user is: collection is allowed. Where
  /// it is needed, the choices made in Google's consent form apply.
  Future<void> consentNotRequired();
}

/// The events the app records.
abstract final class AppEvents {
  /// A new project: `clips`, `format`.
  static const projectCreated = 'project_created';

  /// Videos or photos added over the main track: `count`.
  static const overlayAdded = 'overlay_added';

  /// A clip's frame held as a still.
  static const freezeFrame = 'freeze_frame';

  /// Text added to the video.
  static const textAdded = 'text_added';

  /// Captions made: `segments`, `language` ("auto" when detected), `model`.
  static const captionsGenerated = 'captions_generated';

  /// An export finished: `resolution` (lines), `fps`, `seconds`, `hevc`.
  static const exportCompleted = 'export_completed';
}

/// No analytics: tests, and builds without it.
final class NoAnalytics implements Analytics {
  const new();

  @override
  void screen(String screen) {}

  @override
  void log(String event, [Map<String, Object> parameters = const {}]) {}

  @override
  Future<void> consentNotRequired() async {}
}
