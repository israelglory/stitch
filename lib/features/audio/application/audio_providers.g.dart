// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Native on iOS and Android; a fake elsewhere. Tests override it.

@ProviderFor(audioDevice)
final audioDeviceProvider = AudioDeviceProvider._();

/// Native on iOS and Android; a fake elsewhere. Tests override it.

final class AudioDeviceProvider
    extends $FunctionalProvider<AudioDevice, AudioDevice, AudioDevice>
    with $Provider<AudioDevice> {
  /// Native on iOS and Android; a fake elsewhere. Tests override it.
  AudioDeviceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'audioDeviceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$audioDeviceHash();

  @$internal
  @override
  $ProviderElement<AudioDevice> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AudioDevice create(Ref ref) {
    return audioDevice(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AudioDevice value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AudioDevice>(value),
    );
  }
}

String _$audioDeviceHash() => r'537e88120e61557520a3d66ffeed42c344022bf9';

@ProviderFor(waveformCache)
final waveformCacheProvider = WaveformCacheProvider._();

final class WaveformCacheProvider
    extends $FunctionalProvider<WaveformCache, WaveformCache, WaveformCache>
    with $Provider<WaveformCache> {
  WaveformCacheProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'waveformCacheProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$waveformCacheHash();

  @$internal
  @override
  $ProviderElement<WaveformCache> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WaveformCache create(Ref ref) {
    return waveformCache(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WaveformCache value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WaveformCache>(value),
    );
  }
}

String _$waveformCacheHash() => r'9ebab9190e0946caf98aa043537c2cc02b893c56';

/// Peaks of a sound file; see [WaveformCache.peaks].

@ProviderFor(waveform)
final waveformProvider = WaveformFamily._();

/// Peaks of a sound file; see [WaveformCache.peaks].

final class WaveformProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<double>>,
          List<double>,
          FutureOr<List<double>>
        >
    with $FutureModifier<List<double>>, $FutureProvider<List<double>> {
  /// Peaks of a sound file; see [WaveformCache.peaks].
  WaveformProvider._({
    required WaveformFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'waveformProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$waveformHash();

  @override
  String toString() {
    return r'waveformProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<double>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<double>> create(Ref ref) {
    final argument = this.argument as String;
    return waveform(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WaveformProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$waveformHash() => r'33518dbc33b317a4d4281aace7b2bad5b314c9cd';

/// Peaks of a sound file; see [WaveformCache.peaks].

final class WaveformFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<double>>, String> {
  WaveformFamily._()
    : super(
        retry: null,
        name: r'waveformProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Peaks of a sound file; see [WaveformCache.peaks].

  WaveformProvider call(String path) =>
      WaveformProvider._(argument: path, from: this);

  @override
  String toString() => r'waveformProvider';
}
