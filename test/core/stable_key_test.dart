import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/core/hash/stable_key.dart';

void main() {
  test('matches the native thumbnailers (FNV-1a, base 36)', () {
    // The same value EngineTests.kt pins for Kotlin; Swift uses the same
    // function.
    expect(stableKey('/a/b.mp4'), '1na42wz0z081x');
  });

  test('differs for different input', () {
    expect(stableKey('a'), isNot(stableKey('b')));
  });
}
