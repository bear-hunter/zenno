import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenno/core/database/tables/focus_tables.dart';
import 'package:zenno/features/focus/application/focus_providers.dart';
import 'package:zenno/features/focus/data/focus_repository.dart';
import 'package:zenno/features/focus/domain/focus_stats.dart';

part 'focus_stats_provider.g.dart';

/// Derived descriptive aggregates over the focus-session history.
///
/// Watches [focusHistoryProvider] and folds every *completed* session through
/// the pure [FocusStats.from] aggregator — average pre/post energy, the energy
/// delta, total focus time and the internal/external distraction split. It
/// recomputes automatically whenever a session is added, finished or reviewed.
///
/// Only [FocusSessionStatus.completed] sessions count: an in-progress session
/// has no meaningful totals yet, and an abandoned one would skew the averages.
@riverpod
FocusStats focusStats(Ref ref) {
  // Before the first stream emission (or on error) `valueOrNull` is null —
  // report the empty bundle so the History screen renders a calm zero-state.
  final details = ref.watch(focusHistoryProvider).value;
  if (details == null) return FocusStats.empty;

  final completed = details
      .where((d) => d.session.status == FocusSessionStatus.completed)
      .toList();
  if (completed.isEmpty) return FocusStats.empty;

  return FocusStats.from([for (final detail in completed) _toInput(detail)]);
}

/// Folds one [FocusSessionDetail] into the aggregator's input shape.
FocusStatsInput _toInput(FocusSessionDetail detail) {
  var internal = 0;
  var external = 0;
  for (final distraction in detail.distractions) {
    switch (distraction.kind) {
      case DistractionKind.internal:
        internal += 1;
      case DistractionKind.external:
        external += 1;
    }
  }
  return FocusStatsInput(
    focusSecs: detail.session.actualFocusSecs,
    preEnergy: detail.session.preEnergy,
    postEnergy: detail.session.postEnergy,
    internalDistractions: internal,
    externalDistractions: external,
  );
}
