import 'dart:convert';

/// A short key for [s] that stays the same across launches (FNV-1a, 64
/// bits, base 36), for naming cached files. The native thumbnailers use
/// the same hash.
String stableKey(String s) {
  // Native only (ints are 64 bits), like the rest of the app.
  // ignore: avoid_js_rounded_ints
  var hash = 0xcbf29ce484222325;
  for (final byte in utf8.encode(s)) {
    // Wraps at 64 bits, as FNV expects.
    hash = (hash ^ byte) * 0x100000001b3;
  }
  return BigInt.from(hash).toUnsigned(64).toRadixString(36);
}
