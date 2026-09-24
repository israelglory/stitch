// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'filmstrip.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(filmstrip)
final filmstripProvider = FilmstripProvider._();

final class FilmstripProvider
    extends $FunctionalProvider<Filmstrip, Filmstrip, Filmstrip>
    with $Provider<Filmstrip> {
  FilmstripProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filmstripProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filmstripHash();

  @$internal
  @override
  $ProviderElement<Filmstrip> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Filmstrip create(Ref ref) {
    return filmstrip(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Filmstrip value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Filmstrip>(value),
    );
  }
}

String _$filmstripHash() => r'd1d1a0526c7fa4045d929a9276447c9ea3954bb8';
