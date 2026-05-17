// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_session_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Injectable clock for deterministic active-session controller tests.

@ProviderFor(focusClock)
final focusClockProvider = FocusClockProvider._();

/// Injectable clock for deterministic active-session controller tests.

final class FocusClockProvider
    extends $FunctionalProvider<DateTime, DateTime, DateTime>
    with $Provider<DateTime> {
  /// Injectable clock for deterministic active-session controller tests.
  FocusClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'focusClockProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$focusClockHash();

  @$internal
  @override
  $ProviderElement<DateTime> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DateTime create(Ref ref) {
    return focusClock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime>(value),
    );
  }
}

String _$focusClockHash() => r'd1e4eaf4b67f06079e809be30be3c8f3a6e4e350';

/// Owns the [TimerEngine] for the one in-progress focus session and persists
/// that session's lifecycle.
///
/// `keepAlive` so the timer keeps running across navigation — the user can
/// leave the Active screen, browse a canvas, and return without losing time.
/// A `Timer.periodic` at 1 Hz only drives UI repaint: it pushes a fresh
/// [ActiveSessionState] each second and lets a Pomodoro engine auto-advance
/// work↔break. Because [TimerEngine] is wall-clock correct, a stalled or
/// throttled ticker never corrupts elapsed time — the next emission is still
/// accurate, which is also why no `AppLifecycleListener` reconciliation is
/// needed here.
///
/// DB writes are deliberately sparse: the opening row at start, a tally write
/// on each phase transition and on finish/abandon. The reactive
/// `focusHistoryProvider` picks those up automatically.

@ProviderFor(ActiveSessionController)
final activeSessionControllerProvider = ActiveSessionControllerProvider._();

/// Owns the [TimerEngine] for the one in-progress focus session and persists
/// that session's lifecycle.
///
/// `keepAlive` so the timer keeps running across navigation — the user can
/// leave the Active screen, browse a canvas, and return without losing time.
/// A `Timer.periodic` at 1 Hz only drives UI repaint: it pushes a fresh
/// [ActiveSessionState] each second and lets a Pomodoro engine auto-advance
/// work↔break. Because [TimerEngine] is wall-clock correct, a stalled or
/// throttled ticker never corrupts elapsed time — the next emission is still
/// accurate, which is also why no `AppLifecycleListener` reconciliation is
/// needed here.
///
/// DB writes are deliberately sparse: the opening row at start, a tally write
/// on each phase transition and on finish/abandon. The reactive
/// `focusHistoryProvider` picks those up automatically.
final class ActiveSessionControllerProvider
    extends $NotifierProvider<ActiveSessionController, ActiveSessionState> {
  /// Owns the [TimerEngine] for the one in-progress focus session and persists
  /// that session's lifecycle.
  ///
  /// `keepAlive` so the timer keeps running across navigation — the user can
  /// leave the Active screen, browse a canvas, and return without losing time.
  /// A `Timer.periodic` at 1 Hz only drives UI repaint: it pushes a fresh
  /// [ActiveSessionState] each second and lets a Pomodoro engine auto-advance
  /// work↔break. Because [TimerEngine] is wall-clock correct, a stalled or
  /// throttled ticker never corrupts elapsed time — the next emission is still
  /// accurate, which is also why no `AppLifecycleListener` reconciliation is
  /// needed here.
  ///
  /// DB writes are deliberately sparse: the opening row at start, a tally write
  /// on each phase transition and on finish/abandon. The reactive
  /// `focusHistoryProvider` picks those up automatically.
  ActiveSessionControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeSessionControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeSessionControllerHash();

  @$internal
  @override
  ActiveSessionController create() => ActiveSessionController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ActiveSessionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ActiveSessionState>(value),
    );
  }
}

String _$activeSessionControllerHash() =>
    r'6533a75911cf2ff106ae23fd35ec5df9066dafef';

/// Owns the [TimerEngine] for the one in-progress focus session and persists
/// that session's lifecycle.
///
/// `keepAlive` so the timer keeps running across navigation — the user can
/// leave the Active screen, browse a canvas, and return without losing time.
/// A `Timer.periodic` at 1 Hz only drives UI repaint: it pushes a fresh
/// [ActiveSessionState] each second and lets a Pomodoro engine auto-advance
/// work↔break. Because [TimerEngine] is wall-clock correct, a stalled or
/// throttled ticker never corrupts elapsed time — the next emission is still
/// accurate, which is also why no `AppLifecycleListener` reconciliation is
/// needed here.
///
/// DB writes are deliberately sparse: the opening row at start, a tally write
/// on each phase transition and on finish/abandon. The reactive
/// `focusHistoryProvider` picks those up automatically.

abstract class _$ActiveSessionController extends $Notifier<ActiveSessionState> {
  ActiveSessionState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ActiveSessionState, ActiveSessionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ActiveSessionState, ActiveSessionState>,
              ActiveSessionState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
