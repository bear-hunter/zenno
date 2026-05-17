// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_session_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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
    r'0343c1e24724da868f808d38fa81ce6f48a648a8';

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
