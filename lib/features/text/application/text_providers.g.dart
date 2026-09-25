// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'text_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(textRasterizer)
final textRasterizerProvider = TextRasterizerProvider._();

final class TextRasterizerProvider
    extends $FunctionalProvider<TextRasterizer, TextRasterizer, TextRasterizer>
    with $Provider<TextRasterizer> {
  TextRasterizerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'textRasterizerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$textRasterizerHash();

  @$internal
  @override
  $ProviderElement<TextRasterizer> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TextRasterizer create(Ref ref) {
    return textRasterizer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TextRasterizer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TextRasterizer>(value),
    );
  }
}

String _$textRasterizerHash() => r'c6ed11c83ca09e1b36c8634cb291fc02dd9da159';
