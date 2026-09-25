import 'dart:ffi';

import 'package:ffi/ffi.dart';

// The shim over whisper.cpp in native/whisper, built by hook/build.dart.

/// See `stitch_whisper_transcribe` in native/whisper/stitch_whisper.cpp.
@Native<
  Pointer<Utf8> Function(
    Pointer<Utf8>,
    Pointer<Float>,
    Int32,
    Pointer<Utf8>,
    Int32,
    Pointer<Int32>,
    Pointer<Int32>,
  )
>(symbol: 'stitch_whisper_transcribe', assetId: 'package:stitch/stitch_whisper')
external Pointer<Utf8> whisperTranscribe(
  Pointer<Utf8> modelPath,
  Pointer<Float> samples,
  int sampleCount,
  Pointer<Utf8> language,
  int threads,
  Pointer<Int32> progress,
  Pointer<Int32> cancel,
);

@Native<Void Function(Pointer<Utf8>)>(
  symbol: 'stitch_whisper_free',
  assetId: 'package:stitch/stitch_whisper',
)
external void whisperFree(Pointer<Utf8> result);
