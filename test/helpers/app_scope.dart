import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/app/providers.dart';
import 'package:stitch/core/ids/ids.dart';
import 'package:stitch/core/platform/system_services.dart';
import 'package:stitch/engine/engine_provider.dart';
import 'package:stitch/engine/fake_editor_engine.dart';
import 'package:stitch/features/audio/application/audio_providers.dart';
import 'package:stitch/features/audio/data/audio_device.dart';
import 'package:stitch/features/captions/application/caption_providers.dart';
import 'package:stitch/features/onboarding/data/onboarding_repository.dart';
import 'package:stitch/features/text/application/text_providers.dart';

import 'fake_captions.dart';
import 'fake_media_library.dart';
import 'fake_text_rasterizer.dart';
import 'prefs.dart';

/// Everything the app needs, on disk in a temp folder, with a fake
/// library and engine and a fixed clock.
final class TestEnv {
  new _(
    this.root,
    this.library,
    this.engine,
    this.container,
    this.audio,
    this.rasterizer,
    this.speech,
    this.models,
    this.system,
  );

  static final DateTime now = DateTime.utc(2026, 9, 24, 12);

  final Directory root;
  final FakeMediaLibrary library;
  final FakeEditorEngine engine;
  final ProviderContainer container;
  final FakeAudioDevice audio;
  final FakeTextRasterizer rasterizer;
  final FakeSpeechRecognizer speech;
  final FakeCaptionModelStore models;
  final FakeSystemServices system;

  /// Creates the environment. Call from a test (it registers tear-downs).
  /// Real file IO must run outside the widget tester's fake async zone,
  /// so widget tests call this through `tester.runAsync`.
  static Future<TestEnv> create({bool onboarded = true}) async {
    final root = Directory.systemTemp.createTempSync('stitch_test');
    final libraryDir = Directory('${root.path}/library')..createSync();
    final library = FakeMediaLibrary(libraryDir);
    final engine = FakeEditorEngine();
    final audio = FakeAudioDevice();
    final rasterizer = FakeTextRasterizer();
    final speech = FakeSpeechRecognizer();
    final models = FakeCaptionModelStore();
    final system = FakeSystemServices();
    final prefs = await inMemoryPrefs({
      if (onboarded) OnboardingRepository.completedKey: true,
    });
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        storageRootProvider.overrideWithValue(root),
        cacheRootProvider.overrideWithValue(Directory('${root.path}/cache')),
        mediaLibraryProvider.overrideWithValue(library),
        editorEngineProvider.overrideWithValue(engine),
        clockProvider.overrideWithValue(() => now),
        idGeneratorProvider.overrideWithValue(SequentialIdGenerator()),
        audioDeviceProvider.overrideWithValue(audio),
        textRasterizerProvider.overrideWithValue(rasterizer),
        speechRecognizerProvider.overrideWithValue(speech),
        captionModelStoreProvider.overrideWithValue(models),
        systemServicesProvider.overrideWithValue(system),
      ],
    );
    addTearDown(() {
      container.dispose();
      if (root.existsSync()) root.deleteSync(recursive: true);
    });
    return TestEnv._(
      root,
      library,
      engine,
      container,
      audio,
      rasterizer,
      speech,
      models,
      system,
    );
  }
}
