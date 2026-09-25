import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stitch/app/providers.dart';
import 'package:stitch/engine/engine_provider.dart';
import 'package:stitch/features/audio/application/waveforms.dart';
import 'package:stitch/features/audio/data/audio_device.dart';

part 'audio_providers.g.dart';

/// Native on iOS and Android; a fake elsewhere. Tests override it.
@Riverpod(keepAlive: true)
AudioDevice audioDevice(Ref ref) =>
    !kIsWeb && (Platform.isIOS || Platform.isAndroid)
    ? NativeAudioDevice()
    : FakeAudioDevice();

@Riverpod(keepAlive: true)
WaveformCache waveformCache(Ref ref) => WaveformCache(
  ref.watch(editorEngineProvider),
  Directory(p.join(ref.watch(cacheRootProvider).path, 'waveforms')),
);

/// Peaks of a sound file; see [WaveformCache.peaks].
@riverpod
Future<List<double>> waveform(Ref ref, String path) =>
    ref.watch(waveformCacheProvider).peaks(path);
