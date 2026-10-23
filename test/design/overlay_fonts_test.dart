import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/design/content/overlay_text.dart';

void main() {
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final bootstrap = File('lib/app/bootstrap.dart').readAsStringSync();

  test('every font ships: declared, its file there, and licensed', () {
    for (final font in OverlayFont.values) {
      final declared = RegExp(
        '- family: ${font.family}\\n\\s+fonts:\\n\\s+- asset: (\\S+)',
      ).firstMatch(pubspec);
      expect(declared, isNotNull, reason: '${font.family} in pubspec.yaml');
      expect(
        File(declared!.group(1)!).existsSync(),
        isTrue,
        reason: '${font.family} file',
      );
      final license = RegExp(
        "'${RegExp.escape(font.displayName)}': '(assets/licenses/[^']+)'",
      ).firstMatch(bootstrap);
      expect(license, isNotNull, reason: '${font.displayName} license');
      expect(File(license!.group(1)!).existsSync(), isTrue);
    }
  });

  test('ids are unique, and those in projects already never change', () {
    final ids = OverlayFont.values.map((f) => f.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
    expect(OverlayFont.byId('inter'), OverlayFont.inter);
    expect(OverlayFont.byId('anton'), OverlayFont.anton);
    expect(OverlayFont.byId('bebas'), OverlayFont.bebas);
    expect(OverlayFont.byId('dmSerif'), OverlayFont.serif);
    expect(OverlayFont.byId('pacifico'), OverlayFont.script);
    expect(OverlayFont.byId('spaceMono'), OverlayFont.mono);
    expect(OverlayFont.byId('from a newer version'), OverlayFont.inter);
  });

  test('every group has fonts, listed together', () {
    for (final group in FontGroup.values) {
      expect(OverlayFont.values.where((f) => f.group == group), isNotEmpty);
    }
    final order = OverlayFont.values.map((f) => f.group.index).toList();
    expect(order, [...order]..sort(), reason: 'grouped in the picker');
    expect(OverlayFont.values, hasLength(28));
  });
}
