// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The [GoalRepository], bound to the app-wide [ZennoDatabase].

@ProviderFor(goalRepository)
final goalRepositoryProvider = GoalRepositoryProvider._();

/// The [GoalRepository], bound to the app-wide [ZennoDatabase].

final class GoalRepositoryProvider
    extends $FunctionalProvider<GoalRepository, GoalRepository, GoalRepository>
    with $Provider<GoalRepository> {
  /// The [GoalRepository], bound to the app-wide [ZennoDatabase].
  GoalRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'goalRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$goalRepositoryHash();

  @$internal
  @override
  $ProviderElement<GoalRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoalRepository create(Ref ref) {
    return goalRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoalRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoalRepository>(value),
    );
  }
}

String _$goalRepositoryHash() => r'533531c73a73082e7cd41960485c6ce8f8975f01';

/// The Goal Cycle board as a reactive [KanbanBoardData] stream.
///
/// A thin wrapper over [GoalRepository.watchGoalBoard]; any write through
/// [GoalBoardController] (or a reflection add/delete) re-emits here and
/// rebuilds every watching widget.
///
/// `@riverpod`-safe: [KanbanBoardData] is a hand-written model, not a Drift
/// row type, so it can legally appear in a codegen provider's signature.

@ProviderFor(goalBoard)
final goalBoardProvider = GoalBoardProvider._();

/// The Goal Cycle board as a reactive [KanbanBoardData] stream.
///
/// A thin wrapper over [GoalRepository.watchGoalBoard]; any write through
/// [GoalBoardController] (or a reflection add/delete) re-emits here and
/// rebuilds every watching widget.
///
/// `@riverpod`-safe: [KanbanBoardData] is a hand-written model, not a Drift
/// row type, so it can legally appear in a codegen provider's signature.

final class GoalBoardProvider
    extends
        $FunctionalProvider<
          AsyncValue<KanbanBoardData>,
          KanbanBoardData,
          Stream<KanbanBoardData>
        >
    with $FutureModifier<KanbanBoardData>, $StreamProvider<KanbanBoardData> {
  /// The Goal Cycle board as a reactive [KanbanBoardData] stream.
  ///
  /// A thin wrapper over [GoalRepository.watchGoalBoard]; any write through
  /// [GoalBoardController] (or a reflection add/delete) re-emits here and
  /// rebuilds every watching widget.
  ///
  /// `@riverpod`-safe: [KanbanBoardData] is a hand-written model, not a Drift
  /// row type, so it can legally appear in a codegen provider's signature.
  GoalBoardProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'goalBoardProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$goalBoardHash();

  @$internal
  @override
  $StreamProviderElement<KanbanBoardData> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<KanbanBoardData> create(Ref ref) {
    return goalBoard(ref);
  }
}

String _$goalBoardHash() => r'424490be356c4a9ea01995319a7658d2f9f51818';

/// A [GoalBoardController] bound to the repository.
///
/// Plain provider (not a `Notifier`): the controller is stateless — the UI's
/// state lives entirely in the [goalBoardProvider] stream.

@ProviderFor(goalBoardController)
final goalBoardControllerProvider = GoalBoardControllerProvider._();

/// A [GoalBoardController] bound to the repository.
///
/// Plain provider (not a `Notifier`): the controller is stateless — the UI's
/// state lives entirely in the [goalBoardProvider] stream.

final class GoalBoardControllerProvider
    extends
        $FunctionalProvider<
          GoalBoardController,
          GoalBoardController,
          GoalBoardController
        >
    with $Provider<GoalBoardController> {
  /// A [GoalBoardController] bound to the repository.
  ///
  /// Plain provider (not a `Notifier`): the controller is stateless — the UI's
  /// state lives entirely in the [goalBoardProvider] stream.
  GoalBoardControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'goalBoardControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$goalBoardControllerHash();

  @$internal
  @override
  $ProviderElement<GoalBoardController> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GoalBoardController create(Ref ref) {
    return goalBoardController(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoalBoardController value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoalBoardController>(value),
    );
  }
}

String _$goalBoardControllerHash() =>
    r'56370fd36b5f1c0f31eaa4f4f874cad902aa0171';
