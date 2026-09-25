import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the real fonts for every test so goldens show Inter and Lucide
/// instead of the test font, and makes golden comparison tolerate tiny
/// anti-aliasing differences between machines.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadFont('Inter', [
    'assets/fonts/Inter-Regular.ttf',
    'assets/fonts/Inter-SemiBold.ttf',
  ]);
  await _loadFont('Lucide', ['assets/fonts/Lucide.ttf']);
  // Fonts for text in the video.
  for (final (family, file) in [
    ('Anton', 'Anton-Regular'),
    ('BebasNeue', 'BebasNeue-Regular'),
    ('DMSerifDisplay', 'DMSerifDisplay-Regular'),
    ('Pacifico', 'Pacifico-Regular'),
    ('SpaceMono', 'SpaceMono-Bold'),
  ]) {
    await _loadFont(family, ['assets/fonts/text/$file.ttf']);
  }

  if (goldenFileComparator case final LocalFileComparator local) {
    goldenFileComparator = _TolerantComparator(
      local.basedir.resolve('flutter_test_config.dart'),
    );
  }
  await testMain();
}

Future<void> _loadFont(String family, List<String> assets) async {
  final loader = FontLoader(family);
  for (final asset in assets) {
    loader.addFont(rootBundle.load(asset));
  }
  await loader.load();
}

/// Passes when at most 0.1% of pixels differ.
class _TolerantComparator extends LocalFileComparator {
  new(super.testFile);

  static const double _tolerance = 0.001;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed || result.diffPercent <= _tolerance) {
      result.dispose();
      return true;
    }
    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}
