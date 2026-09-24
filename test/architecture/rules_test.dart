// Project rules enforced as tests so CI fails when they are broken.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Hardcoded style values that belong in lib/design/ only.
final _hardcodedPatterns = <String, RegExp>{
  'Color literal': RegExp(r'\bColor\s*\('),
  'Color.fromARGB/fromRGBO': RegExp(r'\bColor\.from'),
  'Material Colors': RegExp(r'\bColors\.'),
  'EdgeInsets with a number': RegExp(
    r'\bEdgeInsets(Directional)?\.\w+\([^)]*\b\d+(\.\d+)?\b',
  ),
  'radius with a number': RegExp(r'\bRadius\.circular\(\s*\d'),
  'fontSize with a number': RegExp(r'\bfontSize\s*:\s*\d'),
  'SizedBox gap with a number': RegExp(
    r'\bSizedBox\([^)]*\b(width|height)\s*:\s*\d',
  ),
};

/// Material widgets and styling that feature code must take from design/
/// components instead.
final _nonDesignWidgets = <String, RegExp>{
  'TextStyle (use AppTypography)': RegExp(r'\bTextStyle\('),
  'fontFamily': RegExp(r'\bfontFamily\s*:'),
  'Material button': RegExp(
    r'\b(ElevatedButton|FilledButton|OutlinedButton|TextButton|IconButton|'
    r'FloatingActionButton)\b',
  ),
  'Material navigation bar': RegExp(r'\b(BottomNavigationBar|NavigationBar)\b'),
  'Material slider or progress': RegExp(
    r'\b(Slider|LinearProgressIndicator|CircularProgressIndicator)\(',
  ),
  'Material dialog or sheet': RegExp(
    r'\b(AlertDialog|SimpleDialog|showDialog|showModalBottomSheet)\b',
  ),
  'Material surface widget': RegExp(r'\b(Card|Chip|InkWell|TextField)\('),
};

/// Other icon sets. Lucide via AppIcons is the only one, everywhere.
final _otherIconSets = RegExp(r'\b(Icons|CupertinoIcons)\.');

final _emDash = String.fromCharCode(0x2014);

Iterable<File> _dartFiles(String dir) =>
    Directory(dir)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !f.path.endsWith('.g.dart'))
        .where((f) => !f.path.endsWith('.freezed.dart'))
        .where((f) => !f.path.contains('/l10n/generated/'));

String _stripComments(String line) {
  final i = line.indexOf('//');
  return i == -1 ? line : line.substring(0, i);
}

void main() {
  test('feature code uses design tokens, not raw values', () {
    final violations = <String>[];
    for (final file in _dartFiles('lib')) {
      if (file.path.startsWith('lib/design/')) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final code = _stripComments(lines[i]);
        for (final MapEntry(key: name, value: pattern)
            in _hardcodedPatterns.entries) {
          if (pattern.hasMatch(code)) {
            violations.add('${file.path}:${i + 1}  $name');
          }
        }
      }
    }
    expect(
      violations,
      isEmpty,
      reason:
          'Move these values into lib/design/tokens.dart and reference the '
          'token instead:\n${violations.join('\n')}',
    );
  });

  test('feature code builds UI from design/ components', () {
    final violations = <String>[];
    for (final file in _dartFiles('lib')) {
      if (file.path.startsWith('lib/design/')) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final code = _stripComments(lines[i]);
        for (final MapEntry(key: name, value: pattern)
            in _nonDesignWidgets.entries) {
          if (pattern.hasMatch(code)) {
            violations.add('${file.path}:${i + 1}  $name');
          }
        }
      }
    }
    expect(
      violations,
      isEmpty,
      reason:
          'Use the design/ component instead, or add one there:\n'
          '${violations.join('\n')}',
    );
  });

  test('Lucide through AppIcons is the only icon set', () {
    final violations = <String>[
      for (final file in _dartFiles('lib'))
        for (final (i, line) in file.readAsLinesSync().indexed)
          if (_otherIconSets.hasMatch(_stripComments(line)))
            '${file.path}:${i + 1}',
    ];
    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('domain layers are pure Dart', () {
    final violations = <String>[];
    for (final file in _dartFiles('lib')) {
      if (!file.path.contains('/domain/')) continue;
      final source = file.readAsStringSync();
      if (RegExp(r'''import\s+['"](package:flutter/|dart:ui)''')
          .hasMatch(source)) {
        violations.add(file.path);
      }
    }
    expect(
      violations,
      isEmpty,
      reason: 'domain/ must not import Flutter:\n${violations.join('\n')}',
    );
  });

  test('no em dashes in code, tests, docs, or copy', () {
    const roots = ['lib', 'test', 'docs', '.github', 'ios/Runner', 'android'];
    const extensions = {
      '.dart',
      '.arb',
      '.md',
      '.yaml',
      '.yml',
      '.swift',
      '.kt',
      '.plist',
      '.xml',
    };
    final files = <File>[
      File('README.md'),
      File('CONTRIBUTING.md'),
      for (final root in roots)
        if (Directory(root).existsSync())
          ...Directory(root)
              .listSync(recursive: true)
              .whereType<File>()
              .where(
                (f) =>
                    extensions.any(f.path.endsWith) &&
                    !f.path.contains('/build/') &&
                    !f.path.contains('/.gradle/'),
              ),
    ];

    final violations = <String>[];
    for (final file in files.where((f) => f.existsSync())) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].contains(_emDash)) violations.add('${file.path}:${i + 1}');
      }
    }
    expect(
      violations,
      isEmpty,
      reason:
          'Replace em dashes with a comma, colon, or period:\n'
          '${violations.join('\n')}',
    );
  });

  test('rule patterns catch what they should', () {
    bool flagged(String line) =>
        _hardcodedPatterns.values.any((p) => p.hasMatch(line));

    expect(flagged('color: Color(0xFF000000),'), isTrue);
    expect(flagged('color: Colors.red,'), isTrue);
    expect(flagged('padding: EdgeInsets.all(16),'), isTrue);
    expect(flagged('EdgeInsets.only(left: 8, top: AppSpacing.sm)'), isTrue);
    expect(flagged('BorderRadius.all(Radius.circular(12))'), isTrue);
    expect(flagged('TextStyle(fontSize: 14)'), isTrue);
    expect(flagged('const SizedBox(height: 16)'), isTrue);

    expect(flagged('padding: EdgeInsets.all(AppSpacing.lg),'), isFalse);
    expect(flagged('EdgeInsets.zero'), isFalse);
    expect(flagged('color: AppColors.accent,'), isFalse);
    expect(flagged('const SizedBox(height: AppSpacing.lg)'), isFalse);
    expect(flagged('final colorScheme = theme.colorScheme;'), isFalse);

    bool nonDesign(String line) =>
        _nonDesignWidgets.values.any((p) => p.hasMatch(line));
    expect(nonDesign('TextButton(onPressed: f, child: c)'), isTrue);
    expect(nonDesign('child: IconButton('), isTrue);
    expect(nonDesign('style: TextStyle(color: c)'), isTrue);
    expect(nonDesign('showModalBottomSheet<void>('), isTrue);
    expect(nonDesign('AppTextButton(label: l, onPressed: f)'), isFalse);
    expect(nonDesign('AppIconButton(icon: AppIcons.add)'), isFalse);
    expect(nonDesign('showAppBottomSheet<void>('), isFalse);
    expect(nonDesign('AppSlider(label: l)'), isFalse);
    expect(_otherIconSets.hasMatch('Icon(Icons.add)'), isTrue);
    expect(_otherIconSets.hasMatch('Icon(AppIcons.add)'), isFalse);
  });
}
