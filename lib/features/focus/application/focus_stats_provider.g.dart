// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'focus_stats_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Derived descriptive aggregates over the focus-session history.
///
/// Watches [focusHistoryProvider] and folds every *completed* session through
/// the pure [FocusStats.from] aggregator — average pre/post energy, the energy
/// delta, total focus time and the internal/external distraction split. It
/// recomputes automatically whenever a session is added, finished or reviewed.
///
/// Only [FocusSessionStatus.completed] sessions count: an in-progress session
/// has no meaningful totals yet, and an abandoned one would skew the averages.

@ProviderFor(focusStats)
final focusStatsProvider = FocusStatsProvider._();

/// Derived descriptive aggregates over the focus-session history.
///
/// Watches [focusHistoryProvider] and folds every *completed* session through
/// the pure [FocusStats.from] aggregator — average pre/post energy, the energy
/// delta, total focus time and the internal/external distraction split. It
/// recomputes automatically whenever a session is added, finished or reviewed.
///
/// Only [FocusSessionStatus.completed] sessions count: an in-progress session
/// has no meaningful totals yet, and an abandoned one would skew the averages.

final class FocusStatsProvider
    extends $FunctionalProvider<FocusStats, FocusStats, FocusStats>
    with $Provider<FocusStats> {
  /// Derived descriptive aggregates over the focus-session history.
  ///
  /// Watches [focusHistoryProvider] and folds every *completed* session through
  /// the pure [FocusStats.from] aggregator — average pre/post energy, the energy
  /// delta, total focus time and the internal/external distraction split. It
  /// recomputes automatically whenever a session is added, finished or reviewed.
  ///
  /// Only [FocusSessionStatus.completed] sessions count: an in-progress session
  /// has no meaningful totals yet, and an abandoned one would skew the averages.
  FocusStatsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'focusStatsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$focusStatsHash();

  @$internal
  @override
  $ProviderElement<FocusStats> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FocusStats create(Ref ref) {
    return focusStats(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FocusStats value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FocusStats>(value),
    );
  }
}

String _$focusStatsHash() => r'f263ef69969339463c6132d50b7d6524c29c0b22';
