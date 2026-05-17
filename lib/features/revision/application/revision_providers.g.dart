// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'revision_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The [RevisionRepository], bound to the app-wide [ZennoDatabase].

@ProviderFor(revisionRepository)
final revisionRepositoryProvider = RevisionRepositoryProvider._();

/// The [RevisionRepository], bound to the app-wide [ZennoDatabase].

final class RevisionRepositoryProvider
    extends
        $FunctionalProvider<
          RevisionRepository,
          RevisionRepository,
          RevisionRepository
        >
    with $Provider<RevisionRepository> {
  /// The [RevisionRepository], bound to the app-wide [ZennoDatabase].
  RevisionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'revisionRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$revisionRepositoryHash();

  @$internal
  @override
  $ProviderElement<RevisionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RevisionRepository create(Ref ref) {
    return revisionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RevisionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RevisionRepository>(value),
    );
  }
}

String _$revisionRepositoryHash() =>
    r'bbec1210e852ede21cd21c7471777012400a6530';

/// The Schedule Revision board as a reactive [KanbanBoardData] stream.
///
/// A thin wrapper over [RevisionRepository.watchRevisionBoard]; any write
/// through [RevisionBoardController] re-emits here and rebuilds every
/// watching widget.

@ProviderFor(revisionBoard)
final revisionBoardProvider = RevisionBoardProvider._();

/// The Schedule Revision board as a reactive [KanbanBoardData] stream.
///
/// A thin wrapper over [RevisionRepository.watchRevisionBoard]; any write
/// through [RevisionBoardController] re-emits here and rebuilds every
/// watching widget.

final class RevisionBoardProvider
    extends
        $FunctionalProvider<
          AsyncValue<KanbanBoardData>,
          KanbanBoardData,
          Stream<KanbanBoardData>
        >
    with $FutureModifier<KanbanBoardData>, $StreamProvider<KanbanBoardData> {
  /// The Schedule Revision board as a reactive [KanbanBoardData] stream.
  ///
  /// A thin wrapper over [RevisionRepository.watchRevisionBoard]; any write
  /// through [RevisionBoardController] re-emits here and rebuilds every
  /// watching widget.
  RevisionBoardProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'revisionBoardProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$revisionBoardHash();

  @$internal
  @override
  $StreamProviderElement<KanbanBoardData> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<KanbanBoardData> create(Ref ref) {
    return revisionBoard(ref);
  }
}

String _$revisionBoardHash() => r'9eebb87af71f822455f886691e4f4cbbc9a79c20';

/// A [RevisionBoardController] bound to the repository.
///
/// Plain provider (not a `Notifier`): the controller is stateless — the UI's
/// state lives entirely in the [revisionBoardProvider] stream.

@ProviderFor(revisionBoardController)
final revisionBoardControllerProvider = RevisionBoardControllerProvider._();

/// A [RevisionBoardController] bound to the repository.
///
/// Plain provider (not a `Notifier`): the controller is stateless — the UI's
/// state lives entirely in the [revisionBoardProvider] stream.

final class RevisionBoardControllerProvider
    extends
        $FunctionalProvider<
          RevisionBoardController,
          RevisionBoardController,
          RevisionBoardController
        >
    with $Provider<RevisionBoardController> {
  /// A [RevisionBoardController] bound to the repository.
  ///
  /// Plain provider (not a `Notifier`): the controller is stateless — the UI's
  /// state lives entirely in the [revisionBoardProvider] stream.
  RevisionBoardControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'revisionBoardControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$revisionBoardControllerHash();

  @$internal
  @override
  $ProviderElement<RevisionBoardController> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RevisionBoardController create(Ref ref) {
    return revisionBoardController(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RevisionBoardController value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RevisionBoardController>(value),
    );
  }
}

String _$revisionBoardControllerHash() =>
    r'8ff6f10a4a09243f6ebc66f50bada85ec5ca0dd0';
