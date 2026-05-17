// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reflection_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The [ReflectionRepository], bound to the app-wide [ZennoDatabase].

@ProviderFor(reflectionRepository)
final reflectionRepositoryProvider = ReflectionRepositoryProvider._();

/// The [ReflectionRepository], bound to the app-wide [ZennoDatabase].

final class ReflectionRepositoryProvider
    extends
        $FunctionalProvider<
          ReflectionRepository,
          ReflectionRepository,
          ReflectionRepository
        >
    with $Provider<ReflectionRepository> {
  /// The [ReflectionRepository], bound to the app-wide [ZennoDatabase].
  ReflectionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reflectionRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reflectionRepositoryHash();

  @$internal
  @override
  $ProviderElement<ReflectionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReflectionRepository create(Ref ref) {
    return reflectionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReflectionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReflectionRepository>(value),
    );
  }
}

String _$reflectionRepositoryHash() =>
    r'4ab5a565d94e3b49f1621d1efb6b07e1d9c155ba';

/// Every reflection template (builtin + custom) as a reactive stream.
///
/// `@riverpod`-safe: [ReflectionTemplateView] is a hand-written model class,
/// not a Drift row type, so it may legally appear in a codegen signature. A
/// create/update/delete/duplicate through [ReflectionRepository] re-emits here
/// and rebuilds the Templates page.

@ProviderFor(reflectionTemplates)
final reflectionTemplatesProvider = ReflectionTemplatesProvider._();

/// Every reflection template (builtin + custom) as a reactive stream.
///
/// `@riverpod`-safe: [ReflectionTemplateView] is a hand-written model class,
/// not a Drift row type, so it may legally appear in a codegen signature. A
/// create/update/delete/duplicate through [ReflectionRepository] re-emits here
/// and rebuilds the Templates page.

final class ReflectionTemplatesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ReflectionTemplateView>>,
          List<ReflectionTemplateView>,
          Stream<List<ReflectionTemplateView>>
        >
    with
        $FutureModifier<List<ReflectionTemplateView>>,
        $StreamProvider<List<ReflectionTemplateView>> {
  /// Every reflection template (builtin + custom) as a reactive stream.
  ///
  /// `@riverpod`-safe: [ReflectionTemplateView] is a hand-written model class,
  /// not a Drift row type, so it may legally appear in a codegen signature. A
  /// create/update/delete/duplicate through [ReflectionRepository] re-emits here
  /// and rebuilds the Templates page.
  ReflectionTemplatesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reflectionTemplatesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reflectionTemplatesHash();

  @$internal
  @override
  $StreamProviderElement<List<ReflectionTemplateView>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ReflectionTemplateView>> create(Ref ref) {
    return reflectionTemplates(ref);
  }
}

String _$reflectionTemplatesHash() =>
    r'2f93e7032ed1f0f8fa24916601fadcc7fa599ca6';

/// The reflection entries on a single goal card, as a reactive stream.
///
/// A `family` provider keyed by `cardId`: the goal-card detail sheet watches
/// `cardReflectionsProvider(card.id)`. Adding, editing or deleting a
/// reflection re-emits here. `@riverpod`-safe — [ReflectionEntryView] is a
/// hand-written model class.

@ProviderFor(cardReflections)
final cardReflectionsProvider = CardReflectionsFamily._();

/// The reflection entries on a single goal card, as a reactive stream.
///
/// A `family` provider keyed by `cardId`: the goal-card detail sheet watches
/// `cardReflectionsProvider(card.id)`. Adding, editing or deleting a
/// reflection re-emits here. `@riverpod`-safe — [ReflectionEntryView] is a
/// hand-written model class.

final class CardReflectionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ReflectionEntryView>>,
          List<ReflectionEntryView>,
          Stream<List<ReflectionEntryView>>
        >
    with
        $FutureModifier<List<ReflectionEntryView>>,
        $StreamProvider<List<ReflectionEntryView>> {
  /// The reflection entries on a single goal card, as a reactive stream.
  ///
  /// A `family` provider keyed by `cardId`: the goal-card detail sheet watches
  /// `cardReflectionsProvider(card.id)`. Adding, editing or deleting a
  /// reflection re-emits here. `@riverpod`-safe — [ReflectionEntryView] is a
  /// hand-written model class.
  CardReflectionsProvider._({
    required CardReflectionsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'cardReflectionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$cardReflectionsHash();

  @override
  String toString() {
    return r'cardReflectionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<ReflectionEntryView>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ReflectionEntryView>> create(Ref ref) {
    final argument = this.argument as String;
    return cardReflections(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CardReflectionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$cardReflectionsHash() => r'482474c73d8e63ce909486d3ad24374c140feed3';

/// The reflection entries on a single goal card, as a reactive stream.
///
/// A `family` provider keyed by `cardId`: the goal-card detail sheet watches
/// `cardReflectionsProvider(card.id)`. Adding, editing or deleting a
/// reflection re-emits here. `@riverpod`-safe — [ReflectionEntryView] is a
/// hand-written model class.

final class CardReflectionsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<ReflectionEntryView>>, String> {
  CardReflectionsFamily._()
    : super(
        retry: null,
        name: r'cardReflectionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The reflection entries on a single goal card, as a reactive stream.
  ///
  /// A `family` provider keyed by `cardId`: the goal-card detail sheet watches
  /// `cardReflectionsProvider(card.id)`. Adding, editing or deleting a
  /// reflection re-emits here. `@riverpod`-safe — [ReflectionEntryView] is a
  /// hand-written model class.

  CardReflectionsProvider call(String cardId) =>
      CardReflectionsProvider._(argument: cardId, from: this);

  @override
  String toString() => r'cardReflectionsProvider';
}
