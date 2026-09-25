// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resolved_texts.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The project's timeline resolved to absolute times. Recomputed when the
/// timeline changes, not with the playhead.

@ProviderFor(resolvedComposition)
final resolvedCompositionProvider = ResolvedCompositionFamily._();

/// The project's timeline resolved to absolute times. Recomputed when the
/// timeline changes, not with the playhead.

final class ResolvedCompositionProvider
    extends
        $FunctionalProvider<
          ResolvedComposition?,
          ResolvedComposition?,
          ResolvedComposition?
        >
    with $Provider<ResolvedComposition?> {
  /// The project's timeline resolved to absolute times. Recomputed when the
  /// timeline changes, not with the playhead.
  ResolvedCompositionProvider._({
    required ResolvedCompositionFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'resolvedCompositionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$resolvedCompositionHash();

  @override
  String toString() {
    return r'resolvedCompositionProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<ResolvedComposition?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ResolvedComposition? create(Ref ref) {
    final argument = this.argument as String;
    return resolvedComposition(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ResolvedComposition? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ResolvedComposition?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ResolvedCompositionProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$resolvedCompositionHash() =>
    r'3ff47771fbe358232c0b2e591a0842cc5c28e822';

/// The project's timeline resolved to absolute times. Recomputed when the
/// timeline changes, not with the playhead.

final class ResolvedCompositionFamily extends $Family
    with $FunctionalFamilyOverride<ResolvedComposition?, String> {
  ResolvedCompositionFamily._()
    : super(
        retry: null,
        name: r'resolvedCompositionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The project's timeline resolved to absolute times. Recomputed when the
  /// timeline changes, not with the playhead.

  ResolvedCompositionProvider call(String projectId) =>
      ResolvedCompositionProvider._(argument: projectId, from: this);

  @override
  String toString() => r'resolvedCompositionProvider';
}

/// The project's text items at their times on the timeline.

@ProviderFor(resolvedTexts)
final resolvedTextsProvider = ResolvedTextsFamily._();

/// The project's text items at their times on the timeline.

final class ResolvedTextsProvider
    extends
        $FunctionalProvider<
          List<ResolvedText>,
          List<ResolvedText>,
          List<ResolvedText>
        >
    with $Provider<List<ResolvedText>> {
  /// The project's text items at their times on the timeline.
  ResolvedTextsProvider._({
    required ResolvedTextsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'resolvedTextsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$resolvedTextsHash();

  @override
  String toString() {
    return r'resolvedTextsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<ResolvedText>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<ResolvedText> create(Ref ref) {
    final argument = this.argument as String;
    return resolvedTexts(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ResolvedText> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ResolvedText>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ResolvedTextsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$resolvedTextsHash() => r'5223f403cb2ede02202ea3e13ea3995155f1d038';

/// The project's text items at their times on the timeline.

final class ResolvedTextsFamily extends $Family
    with $FunctionalFamilyOverride<List<ResolvedText>, String> {
  ResolvedTextsFamily._()
    : super(
        retry: null,
        name: r'resolvedTextsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The project's text items at their times on the timeline.

  ResolvedTextsProvider call(String projectId) =>
      ResolvedTextsProvider._(argument: projectId, from: this);

  @override
  String toString() => r'resolvedTextsProvider';
}
