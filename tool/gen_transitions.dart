// Generates every platform's transition code from transitions/*.glsl.
//
//   dart run tool/gen_transitions.dart
//
// Writes (all checked in; see transitions/README.md for the source rules):
// - shaders/transitions/<id>.frag: Flutter fragment shaders for the
//   transition previews, and the shaders: list in pubspec.yaml;
// - TransitionShaders.kt: the GLSL each Android clip effect compiles;
// - TransitionSources.swift: the same transitions as Metal, for iOS;
// - transition_catalog.g.dart: the transitions, by category, for Dart;
// - transition_names.g.dart: each transition's name from the app strings,
//   and any missing English names in app_en.arb.
import 'dart:io';

const _categories = {
  'basic': 'Basic',
  'slide': 'Slide',
  'wipe': 'Wipe',
  'zoom': 'Zoom',
  'shape': 'Shape',
  'light': 'Light',
  'glitch': 'Glitch',
  'fun': 'Fun',
};

const _types = 'float|int|bool|void|vec2|vec3|vec4|mat2|mat3';

/// Names the hosts define around a transition, or that Metal reserves.
const _reserved = {
  'main',
  'inside',
  'getFromColor',
  'getToColor',
  'sampleuFrom',
  'progress',
  'ratio',
  'half',
  'kernel',
  'device',
  'constant',
  'thread',
  'threadgroup',
  'sampler',
  'texture',
  'vertex',
  'fragment',
  'uint',
  'sample',
  'namespace',
  'using',
  'class',
  'template',
  'new',
  'delete',
  'this',
  'auto',
  'register',
  'signed',
  'unsigned',
  'long',
  'short',
};

/// Constructs that compile on one platform but not another.
final _forbidden = <RegExp, String>{
  RegExp(r'^\s*const\b', multiLine: true):
      'global or local const (use #define)',
  RegExp(r'\b(in|out|inout)\s+(float|int|bool|vec|mat)'):
      'in/out/inout parameters (Metal has none)',
  RegExp(r'\btexture2?D?\s*\('):
      'texture lookups (use getFromColor/getToColor)',
  RegExp('%'): '% (GLSL ES 1.0 has none; use mod)',
  RegExp(r'\b(round|trunc|roundEven|isnan|isinf)\s*\('):
      'functions GLSL ES 1.0 lacks',
  RegExp(r'\[\s*\d*\s*\]'): 'arrays',
  RegExp(r'\b(highp|mediump|lowp|precision)\b'): 'precision qualifiers',
  RegExp(r'\bpow\s*\('): 'pow (undefined for negative bases; multiply)',
};

final class _Transition {
  new(
    this.id,
    this.name,
    this.category,
    this.description,
    this.body,
    this.tolerance,
  );

  final String id;
  final String name;
  final String category;
  final String description;
  final String body;
  final double? tolerance;

  String get key => 'transition${id[0].toUpperCase()}${id.substring(1)}';
}

void main() {
  final transitions = _read();
  _writeFlutter(transitions);
  _writeAndroid(transitions);
  _writeIos(transitions);
  _writeCatalog(transitions);
  _writeNames(transitions);
  _writeArb(transitions);
  _writeTolerances(transitions);
  stdout.writeln('Generated ${transitions.length} transitions.');
}

List<_Transition> _read() {
  final files =
      Directory('transitions')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.glsl'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  final errors = <String>[];
  final out = <_Transition>[];
  for (final file in files) {
    final id = file.uri.pathSegments.last.replaceAll('.glsl', '');
    final text = file.readAsStringSync();
    String? field(String name) => RegExp(
      '^// $name: (.+)\$',
      multiLine: true,
    ).firstMatch(text)?.group(1)?.trim();
    final name = field('name');
    final category = field('category');
    final description = field('description');
    final body = text
        .split('\n')
        .where((l) => !RegExp(r'^// \w+: ').hasMatch(l))
        .join('\n')
        .trim();
    void fail(String why) => errors.add('$id: $why');
    if (!RegExp(r'^[a-z][a-zA-Z0-9]*$').hasMatch(id)) {
      fail('id must be camelCase');
    }
    if (name == null || description == null) {
      fail('name and description needed');
    }
    if (!_categories.containsKey(category)) fail('unknown category $category');
    if (!RegExp(
      r'^vec4 transition\(vec2 uv\)',
      multiLine: true,
    ).hasMatch(body)) {
      fail('needs vec4 transition(vec2 uv)');
    }
    if (!body.contains('getFromColor(') || !body.contains('getToColor(')) {
      fail('must sample both clips');
    }
    for (final MapEntry(key: pattern, value: why) in _forbidden.entries) {
      if (pattern.hasMatch(body)) fail(why);
    }
    for (final m in RegExp(
      '^(?:$_types)\\s+(\\w+)\\s*\\(',
      multiLine: true,
    ).allMatches(body)) {
      if (_reserved.contains(m.group(1))) fail('reserved name ${m.group(1)}');
    }
    for (final m in RegExp(
      r'\b(?:float|int|bool|vec[234]|mat[23])\s+(\w+)\s*[=;,)]',
    ).allMatches(body)) {
      if (_reserved.contains(m.group(1))) fail('reserved name ${m.group(1)}');
    }
    out.add(
      _Transition(
        id,
        name ?? id,
        category ?? 'basic',
        description ?? '',
        body,
        double.tryParse(field('tolerance') ?? ''),
      ),
    );
  }
  if (errors.isNotEmpty) {
    stderr.writeln(errors.join('\n'));
    exit(1);
  }
  // Catalog order: by category, then as listed in the category's order file
  // if present, else by name.
  final order = _categories.keys.toList();
  out.sort((a, b) {
    final c = order.indexOf(a.category).compareTo(order.indexOf(b.category));
    return c != 0 ? c : _rank(a).compareTo(_rank(b));
  });
  return out;
}

/// Position within its category: transitions/order.txt lists ids in order.
int _rank(_Transition t) {
  final file = File('transitions/order.txt');
  if (!file.existsSync()) return 0;
  final ids = file.readAsLinesSync().map((l) => l.trim()).toList();
  final i = ids.indexOf(t.id);
  return i < 0 ? ids.length : i;
}

const _header =
    'Generated by tool/gen_transitions.dart from transitions/*.glsl. '
    'Do not edit.';

void _writeFlutter(List<_Transition> ts) {
  final dir = Directory('shaders/transitions');
  if (dir.existsSync()) dir.deleteSync(recursive: true);
  dir.createSync(recursive: true);
  for (final t in ts) {
    File('${dir.path}/${t.id}.frag').writeAsStringSync('''
#version 460 core
// $_header

#include <flutter/runtime_effect.glsl>

// Canvas size in pixels (xy), progress (z), and width over height (w), in
// one uniform so none can be dropped as unused.
uniform vec4 uParams;
uniform sampler2D uFrom;
uniform sampler2D uTo;

out vec4 fragColor;

#define progress uParams.z
#define ratio uParams.w

// Images are stored top row first; transitions use y up.
vec4 getFromColor(vec2 p) {
  return texture(uFrom, vec2(p.x, 1.0 - p.y));
}

vec4 getToColor(vec2 p) {
  return texture(uTo, vec2(p.x, 1.0 - p.y));
}

${t.body}

void main() {
  vec2 p = FlutterFragCoord().xy / uParams.xy;
  fragColor = transition(vec2(p.x, 1.0 - p.y));
}
''');
  }
  final pubspec = File('pubspec.yaml');
  final lines = pubspec.readAsLinesSync();
  final start = lines.indexOf('  shaders:');
  if (start >= 0) {
    var end = start + 1;
    while (end < lines.length && lines[end].startsWith('    ')) {
      end++;
    }
    lines.removeRange(start, end);
    if (start < lines.length && lines[start].trim().isEmpty) {
      lines.removeAt(start);
    }
  }
  final fonts = lines.indexOf('  fonts:');
  lines.insertAll(fonts, [
    '  shaders:',
    '    # Transition previews; generated by tool/gen_transitions.dart.',
    for (final t in ts) '    - shaders/transitions/${t.id}.frag',
    '',
  ]);
  pubspec.writeAsStringSync('${lines.join('\n')}\n');
}

void _writeAndroid(List<_Transition> ts) {
  String kotlinString(String s) => s.replaceAll(r'$', r"${'$'}");
  File(
    'android/app/src/main/kotlin/xyz/olaifaglory/stitch/engine/'
    'TransitionShaders.kt',
  ).writeAsStringSync('''
// $_header
package xyz.olaifaglory.stitch.engine

/**
 * Each transition's GLSL: `vec4 transition(vec2 uv)` and its helpers, over
 * `getFromColor`, `getToColor`, `progress`, and `ratio`, which [ClipEffect]
 * defines around it.
 */
object TransitionShaders {
  val sources: Map<String, String> = mapOf(
${ts.map((t) => '    "${t.id}" to """\n${kotlinString(t.body)}\n""",').join('\n')}
  )
}
''');
}

/// [body] as Metal: every function also takes the textures, progress, and
/// ratio (Metal has no global uniforms), through CTX_PARAMS and CTX_ARGS,
/// which Transitions.swift defines.
String _metal(String body) {
  var out = body;
  final names = RegExp(
    '^(?:$_types)\\s+(\\w+)\\s*\\(',
    multiLine: true,
  ).allMatches(body).map((m) => m.group(1)!).toSet();
  for (final name in names) {
    out = out.replaceAllMapped(
      RegExp('^((?:$_types)\\s+$name\\s*\\()(\\s*\\))?', multiLine: true),
      (m) => m.group(2) != null
          ? '${m.group(1)}CTX_PARAMS)'
          : '${m.group(1)}CTX_PARAMS, ',
    );
    out = out.replaceAllMapped(
      RegExp('(?<![\\w.])$name\\s*\\((?!CTX_PARAMS)(\\s*\\))?'),
      (m) => m.group(1) != null ? '$name(CTX_ARGS)' : '$name(CTX_ARGS, ',
    );
  }
  return out;
}

void _writeIos(List<_Transition> ts) {
  String indent(String s) =>
      s.split('\n').map((l) => l.isEmpty ? l : '    $l').join('\n');
  File('ios/Runner/Engine/TransitionSources.swift').writeAsStringSync('''
// $_header

/// Each transition as Metal: `float4 transition(CTX_PARAMS, float2 uv)` and
/// its helpers, which Transitions.swift wraps in its prelude and kernel.
enum TransitionSources {
  static let metal: [String: String] = [
${ts.map((t) => '    "${t.id}": #"""\n${indent(_metal(t.body))}\n    """#,').join('\n')}
  ]
}
''');
}

void _writeCatalog(List<_Transition> ts) {
  String dartString(String s) => "'${s.replaceAll("'", r"\'")}'";
  File('lib/features/timeline/domain/transition_catalog.g.dart')
      .writeAsStringSync('''
// $_header

/// Groups of transitions, in the order the transitions sheet shows them.
enum TransitionCategory { ${_categories.keys.join(', ')} }

/// A transition the engines know, by the id projects store.
final class TransitionSpec {
  const TransitionSpec(this.id, this.category, {this.tolerance});

  final String id;
  final TransitionCategory category;

  /// How far the engines may stray from the reference images (0 to 1,
  /// mean per channel); noisy transitions get more.
  final double? tolerance;
}

/// Every transition, grouped by category.
const transitionCatalog = <TransitionSpec>[
${ts.map((t) => '  TransitionSpec(${dartString(t.id)}, TransitionCategory.${t.category}${t.tolerance == null ? '' : ', tolerance: ${t.tolerance}'}),').join('\n')}
];
''');
}

void _writeNames(List<_Transition> ts) {
  File('lib/features/editor/presentation/transition_names.g.dart')
      .writeAsStringSync('''
// $_header
import 'package:stitch/features/timeline/domain/transition_catalog.g.dart';
import 'package:stitch/l10n/generated/app_localizations.dart';

/// The name of transition [id]; unknown ids (from a newer version) play as
/// a crossfade, and are named so.
String transitionName(AppLocalizations l10n, String id) => switch (id) {
${ts.map((t) => "  '${t.id}' => l10n.${t.key},").join('\n')}
  _ => l10n.transitionCrossfade,
};

/// The name of [category] in the transitions sheet.
String transitionCategoryName(
  AppLocalizations l10n,
  TransitionCategory category,
) => switch (category) {
${_categories.keys.map((c) => '  TransitionCategory.$c => l10n.transitionCategory${c[0].toUpperCase()}${c.substring(1)},').join('\n')}
};
''');
}

/// Default for how far an export may stray from a reference image: mean
/// difference per channel, 0 to 1. Video compression alone accounts for a
/// little.
const _defaultTolerance = 0.04;

/// Each transition's tolerance, for the engine tests (Kotlin and Swift),
/// which compare exports to `test_media/transitions/<id>_<percent>.png`.
void _writeTolerances(List<_Transition> ts) {
  final lines = [
    for (final t in ts) '  "${t.id}": ${t.tolerance ?? _defaultTolerance}',
  ];
  Directory('test_media/transitions').createSync(recursive: true);
  File('test_media/transitions/tolerances.json')
      .writeAsStringSync('{\n${lines.join(',\n')}\n}\n');
}

/// Adds missing English names; existing ones (and their translations) stay.
void _writeArb(List<_Transition> ts) {
  final file = File('lib/l10n/app_en.arb');
  var text = file.readAsStringSync().trimRight();
  String json(String s) => s.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
  final entries = <String>[];
  void add(String key, String value, String description) {
    if (text.contains('"$key":')) return;
    entries.add(
      '  "$key": "${json(value)}",\n'
      '  "@$key": {\n    "description": "${json(description)}"\n  }',
    );
  }

  for (final MapEntry(key: c, value: name) in _categories.entries) {
    add(
      'transitionCategory${c[0].toUpperCase()}${c.substring(1)}',
      name,
      'A group of transitions in the transitions sheet.',
    );
  }
  for (final t in ts) {
    add(t.key, t.name, 'Transition between two clips: ${t.description}');
  }
  if (entries.isEmpty) return;
  if (!text.endsWith('}')) throw StateError('app_en.arb must end with }');
  text =
      '${text.substring(0, text.length - 1).trimRight()},\n'
      '${entries.join(',\n')}\n}\n';
  file.writeAsStringSync(text);
}
