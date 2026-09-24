import 'package:flutter/services.dart';

/// The only haptics in the app: a light tap on clip snap, split, and
/// selection. Nothing else vibrates.
abstract final class AppHaptics {
  static Future<void> snap() => HapticFeedback.lightImpact();

  static Future<void> split() => HapticFeedback.lightImpact();

  static Future<void> selection() => HapticFeedback.lightImpact();
}
