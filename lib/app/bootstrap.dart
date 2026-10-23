import 'dart:async';

import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitch/app/app.dart';
import 'package:stitch/app/providers.dart';
import 'package:stitch/core/logging/logger.dart';
import 'package:stitch/core/storage/cache_pruning.dart';
import 'package:stitch/design/tokens.dart';
import 'package:stitch/features/audio/application/waveforms.dart';
import 'package:stitch/features/editor/application/filmstrip.dart';
import 'package:stitch/features/text/application/text_rendering.dart';
import 'package:stitch/firebase_options.dart';

const _log = Logger('app');

/// Loads what must exist before the first frame, installs error handlers,
/// and starts the app.
///
/// Integration tests pass [installErrorHandlers] false (the test framework
/// owns error reporting there) and may replace providers with [overrides].
Future<void> bootstrap({
  bool installErrorHandlers = true,
  List<Override> overrides = const [],
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (installErrorHandlers) {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      _log.error('Flutter error', details.exception, details.stack);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      _log.error('Uncaught error', error, stack);
      return true;
    };
  }

  // iOS follows Info.plist: iPhones in portrait, iPads every way (which
  // iPad multitasking requires). Android phones stay in portrait.
  await SystemChrome.setPreferredOrientations(
    defaultTargetPlatform == TargetPlatform.iOS
        ? const []
        : const [DeviceOrientation.portraitUp],
  );
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: AppColors.dark.background,
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.dark.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  LicenseRegistry.addLicense(_bundledAssetLicenses);

  // Analytics (Google Analytics for Firebase). The app runs without it.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on Object catch (e, st) {
    _log.error('Firebase did not start', e, st);
  }

  final prefs = await SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(),
  );

  final documents = await getApplicationDocumentsDirectory();
  final cache = await getApplicationCacheDirectory();
  // Keep regenerated caches bounded; runs in the background.
  for (final (dir, bytes) in [
    ('filmstrip', filmstripCacheBytes),
    ('text', textCacheBytes),
    ('waveforms', waveformCacheBytes),
    // Exported copies; the gallery keeps its own.
    ('exports', 500 * 1000 * 1000),
  ]) {
    unawaited(pruneDirectory(Directory(p.join(cache.path, dir)), bytes));
  }
  // Left by work the app was stopped in the middle of: nothing is running
  // yet, so none of it is in use.
  unawaited(removeLeftovers(cache));

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        storageRootProvider.overrideWithValue(documents),
        cacheRootProvider.overrideWithValue(cache),
        ...overrides,
      ],
      child: const StitchApp(splash: true),
    ),
  );
}

/// Licenses of bundled assets and native code, and of the downloadable
/// caption models, shown on the open source licenses screen.
Stream<LicenseEntry> _bundledAssetLicenses() async* {
  const licenses = {
    'Inter': 'assets/licenses/inter.txt',
    'Lucide': 'assets/licenses/lucide.txt',
    'Anton': 'assets/licenses/anton.txt',
    'Bebas Neue': 'assets/licenses/bebasneue.txt',
    'DM Serif Display': 'assets/licenses/dmserifdisplay.txt',
    'Pacifico': 'assets/licenses/pacifico.txt',
    'Montserrat': 'assets/licenses/montserrat.txt',
    'Poppins': 'assets/licenses/poppins.txt',
    'Oswald': 'assets/licenses/oswald.txt',
    'Archivo Black': 'assets/licenses/archivoblack.txt',
    'Playfair Display': 'assets/licenses/playfairdisplay.txt',
    'Lora': 'assets/licenses/lora.txt',
    'Abril Fatface': 'assets/licenses/abrilfatface.txt',
    'Cinzel': 'assets/licenses/cinzel.txt',
    'Dancing Script': 'assets/licenses/dancingscript.txt',
    'Great Vibes': 'assets/licenses/greatvibes.txt',
    'Caveat': 'assets/licenses/caveat.txt',
    'Permanent Marker': 'assets/licenses/permanentmarker.txt',
    'Nunito': 'assets/licenses/nunito.txt',
    'Fredoka': 'assets/licenses/fredoka.txt',
    'Comfortaa': 'assets/licenses/comfortaa.txt',
    'Press Start 2P': 'assets/licenses/pressstart2p.txt',
    'Monoton': 'assets/licenses/monoton.txt',
    'VT323': 'assets/licenses/vt323.txt',
    'Lobster': 'assets/licenses/lobster.txt',
    'Bangers': 'assets/licenses/bangers.txt',
    'Luckiest Guy': 'assets/licenses/luckiestguy.txt',
    'Creepster': 'assets/licenses/creepster.txt',
    'Space Mono': 'assets/licenses/spacemono.txt',
    'Bundled music': 'assets/licenses/music.txt',
    'Bundled sound effects': 'assets/licenses/kenney.txt',
    'whisper.cpp': 'assets/licenses/whisper_cpp.txt',
    'Whisper models': 'assets/licenses/whisper_models.txt',
    'Android libraries': 'assets/licenses/android_libraries.txt',
  };
  for (final MapEntry(key: name, value: path) in licenses.entries) {
    yield LicenseEntryWithLineBreaks([name], await rootBundle.loadString(path));
  }
}
