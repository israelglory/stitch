// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'engine_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The media engine: native on iOS; the fake elsewhere until the Android
/// engine lands (M6). Tests override it with their own fake.

@ProviderFor(editorEngine)
final editorEngineProvider = EditorEngineProvider._();

/// The media engine: native on iOS; the fake elsewhere until the Android
/// engine lands (M6). Tests override it with their own fake.

final class EditorEngineProvider
    extends $FunctionalProvider<EditorEngine, EditorEngine, EditorEngine>
    with $Provider<EditorEngine> {
  /// The media engine: native on iOS; the fake elsewhere until the Android
  /// engine lands (M6). Tests override it with their own fake.
  EditorEngineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'editorEngineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$editorEngineHash();

  @$internal
  @override
  $ProviderElement<EditorEngine> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  EditorEngine create(Ref ref) {
    return editorEngine(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EditorEngine value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EditorEngine>(value),
    );
  }
}

String _$editorEngineHash() => r'4d2e39f71d1b00daaa700540b8c86775ba6eae3f';

/// Texture id of the preview, or null when the engine has no native
/// preview (the fake engine shows posters instead).

@ProviderFor(previewTexture)
final previewTextureProvider = PreviewTextureProvider._();

/// Texture id of the preview, or null when the engine has no native
/// preview (the fake engine shows posters instead).

final class PreviewTextureProvider
    extends $FunctionalProvider<AsyncValue<int?>, int?, FutureOr<int?>>
    with $FutureModifier<int?>, $FutureProvider<int?> {
  /// Texture id of the preview, or null when the engine has no native
  /// preview (the fake engine shows posters instead).
  PreviewTextureProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'previewTextureProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$previewTextureHash();

  @$internal
  @override
  $FutureProviderElement<int?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int?> create(Ref ref) {
    return previewTexture(ref);
  }
}

String _$previewTextureHash() => r'fca231505a636e413422168df984a8a3fb57b2b4';
