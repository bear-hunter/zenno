// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'focus_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The application-wide [FocusRepository].
///
/// `keepAlive` so it shares the single [ZennoDatabase] connection for the whole
/// session rather than reopening per screen.

@ProviderFor(focusRepository)
final focusRepositoryProvider = FocusRepositoryProvider._();

/// The application-wide [FocusRepository].
///
/// `keepAlive` so it shares the single [ZennoDatabase] connection for the whole
/// session rather than reopening per screen.

final class FocusRepositoryProvider
    extends
        $FunctionalProvider<FocusRepository, FocusRepository, FocusRepository>
    with $Provider<FocusRepository> {
  /// The application-wide [FocusRepository].
  ///
  /// `keepAlive` so it shares the single [ZennoDatabase] connection for the whole
  /// session rather than reopening per screen.
  FocusRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'focusRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$focusRepositoryHash();

  @$internal
  @override
  $ProviderElement<FocusRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FocusRepository create(Ref ref) {
    return focusRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FocusRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FocusRepository>(value),
    );
  }
}

String _$focusRepositoryHash() => r'acca215c00a5f74842872a047fdfded20361f433';

/// The application-wide [RitualRepository].
///
/// `keepAlive` for the same reason as [focusRepository].

@ProviderFor(ritualRepository)
final ritualRepositoryProvider = RitualRepositoryProvider._();

/// The application-wide [RitualRepository].
///
/// `keepAlive` for the same reason as [focusRepository].

final class RitualRepositoryProvider
    extends
        $FunctionalProvider<
          RitualRepository,
          RitualRepository,
          RitualRepository
        >
    with $Provider<RitualRepository> {
  /// The application-wide [RitualRepository].
  ///
  /// `keepAlive` for the same reason as [focusRepository].
  RitualRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ritualRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ritualRepositoryHash();

  @$internal
  @override
  $ProviderElement<RitualRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RitualRepository create(Ref ref) {
    return ritualRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RitualRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RitualRepository>(value),
    );
  }
}

String _$ritualRepositoryHash() => r'3b552267863834be2c4b583b45acb1689ffde480';

/// The full focus-session history, most recent first, each joined with its
/// distractions and ritual-check snapshot.

@ProviderFor(focusHistory)
final focusHistoryProvider = FocusHistoryProvider._();

/// The full focus-session history, most recent first, each joined with its
/// distractions and ritual-check snapshot.

final class FocusHistoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<FocusSessionDetail>>,
          List<FocusSessionDetail>,
          Stream<List<FocusSessionDetail>>
        >
    with
        $FutureModifier<List<FocusSessionDetail>>,
        $StreamProvider<List<FocusSessionDetail>> {
  /// The full focus-session history, most recent first, each joined with its
  /// distractions and ritual-check snapshot.
  FocusHistoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'focusHistoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$focusHistoryHash();

  @$internal
  @override
  $StreamProviderElement<List<FocusSessionDetail>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<FocusSessionDetail>> create(Ref ref) {
    return focusHistory(ref);
  }
}

String _$focusHistoryHash() => r'fb16a15a7a67cf988a2f325ae7ecae186da57ebf';
