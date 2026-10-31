/// A newer version of Stitch in the App Store or on Google Play.
final class StoreUpdate {
  const new({required this.id, required this.storeUrl, this.version});

  /// Names this release, to remember the user's answer for it ("ios:1.2.0",
  /// "android:7").
  final String id;

  /// The app's page in the store, where the user updates.
  final String storeUrl;

  /// Like "1.2.0", when the store says (the App Store does, Play does not).
  final String? version;
}

/// Compares dotted version numbers ("1.10.0" after "1.9.2"). Missing parts
/// count as 0 and anything after a part's digits is ignored ("2.0.0-beta"
/// reads as 2.0.0). Negative when [a] is older, positive when newer.
int compareVersions(String a, String b) {
  List<int> parts(String v) => [
    for (final p in v.trim().split('.'))
      int.tryParse(RegExp(r'^\d*').stringMatch(p) ?? '') ?? 0,
  ];
  final x = parts(a);
  final y = parts(b);
  for (var i = 0; i < x.length || i < y.length; i++) {
    final d = (i < x.length ? x[i] : 0) - (i < y.length ? y[i] : 0);
    if (d != 0) return d;
  }
  return 0;
}
