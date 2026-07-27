import 'dart:async';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:zenno/core/database/database.dart';
import 'package:zenno/core/database/tables/focus_tables.dart';
import 'package:zenno/core/util/id.dart';
import 'package:zenno/features/focus/domain/timer_engine.dart' as timer;

/// A focus session bundled with its captured distractions and ritual-check
/// snapshot — the shape the History and Review screens render.
class FocusSessionDetail {
  /// Creates a detail bundle.
  const FocusSessionDetail({
    required this.session,
    required this.distractions,
    required this.ritualChecks,
  });

  /// The `focus_sessions` row.
  final FocusSession session;

  /// Distractions captured during the session, oldest first.
  final List<Distraction> distractions;

  /// The per-session ritual-item snapshot taken at session start.
  final List<FocusSessionRitualCheck> ritualChecks;
}

/// Raised when another persisted session is already live.
class FocusSessionAlreadyActiveException implements Exception {
  const FocusSessionAlreadyActiveException(this.sessionId);

  final String sessionId;

  @override
  String toString() => 'FocusSessionAlreadyActiveException($sessionId)';
}

/// Drift-backed access to the Focus aggregate: `focus_sessions`,
/// `focus_session_ritual_checks` and `distractions`.
///
/// Reads are reactive [Stream]s; writes are one-shot [Future]s. Drift row
/// classes are the Focus feature's models, so they are allowed to surface; no
/// other Drift type does.
class FocusRepository {
  /// Creates a repository over [_db].
  FocusRepository(this._db);

  final ZennoDatabase _db;

  // ---------------------------------------------------------------------------
  // Session lifecycle
  // ---------------------------------------------------------------------------

  /// Inserts an opening `focus_sessions` row in the [FocusSessionStatus.inProgress]
  /// state and returns its generated id.
  ///
  /// Called once at session start. The ritual snapshot is written separately
  /// via [snapshotRitualChecks] inside the same logical "start" step.
  Future<String> createSession({
    required DateTime startedAt,
    required String goalText,
    required int preEnergy,
    required TimerKind timerKind,
    required int plannedDurationSecs,
    int? pomodoroWorkSecs,
    int? pomodoroBreakSecs,
    double? flowBreakRatio,
    String? linkedCanvasId,
    List<({String itemId, String label, bool wasChecked})> ritualItems =
        const [],
  }) async {
    final id = newId();
    await _db.transaction(() async {
      final FocusSession? active =
          await (_db.select(_db.focusSessions)
                ..where(
                  (session) => session.status.isIn(<int>[
                    FocusSessionStatus.inProgress.index,
                    FocusSessionStatus.reviewPending.index,
                  ]),
                )
                ..limit(1))
              .getSingleOrNull();
      if (active != null) {
        throw FocusSessionAlreadyActiveException(active.id);
      }
      await _db
          .into(_db.focusSessions)
          .insert(
            FocusSessionsCompanion.insert(
              id: id,
              startedAt: startedAt,
              goalText: goalText,
              preEnergy: preEnergy,
              timerKind: timerKind,
              plannedDurationSecs: plannedDurationSecs,
              pomodoroWorkSecs: Value(pomodoroWorkSecs),
              pomodoroBreakSecs: Value(pomodoroBreakSecs),
              flowBreakRatio: Value(flowBreakRatio),
              linkedCanvasId: Value(linkedCanvasId),
              status: FocusSessionStatus.inProgress,
              runtimeStatus: Value(timer.TimerStatus.running.index),
              runtimePhase: Value(timer.TimerPhase.work.index),
              runtimePhaseStartedAt: Value(startedAt),
              runtimeCarriedPhaseSecs: const Value(0),
              runtimePhaseTargetSecs: Value(pomodoroWorkSecs),
              runtimeBankedFocusSecs: const Value(0),
            ),
          );
      await _insertRitualChecks(sessionId: id, items: ritualItems);
    });
    return id;
  }

  /// Persists the running tally of a live session.
  ///
  /// Called periodically (and on lifecycle changes) while a session runs so
  /// `actual_focus_secs` and `cycles_completed` survive an app kill. Only the
  /// supplied fields are written.
  Future<void> updateProgress({
    required String sessionId,
    int? actualFocusSecs,
    int? cyclesCompleted,
  }) async {
    await (_db.update(
      _db.focusSessions,
    )..where((s) => s.id.equals(sessionId))).write(
      FocusSessionsCompanion(
        actualFocusSecs: actualFocusSecs == null
            ? const Value.absent()
            : Value(actualFocusSecs),
        cyclesCompleted: cyclesCompleted == null
            ? const Value.absent()
            : Value(cyclesCompleted),
      ),
    );
  }

  /// Returns the latest in-progress session, if one exists.
  ///
  /// Older app versions could leave more than one live row after competing
  /// starts. When found, the newest remains active and each older row is
  /// closed as abandoned at the next session's start time. This preserves its
  /// recorded focus tally while restoring the one-session invariant.
  Future<FocusSession?> readLatestInProgressSession() {
    return _db.transaction(() async {
      final List<FocusSession> active =
          await (_db.select(_db.focusSessions)
                ..where(
                  (session) => session.status.equals(
                    FocusSessionStatus.inProgress.index,
                  ),
                )
                ..orderBy([
                  (session) => OrderingTerm(
                    expression: session.startedAt,
                    mode: OrderingMode.desc,
                  ),
                ]))
              .get();
      for (var index = 1; index < active.length; index += 1) {
        final FocusSession orphan = active[index];
        final DateTime supersededAt = active[index - 1].startedAt;
        await (_db.update(
          _db.focusSessions,
        )..where((session) => session.id.equals(orphan.id))).write(
          FocusSessionsCompanion(
            endedAt: Value(supersededAt),
            status: const Value(FocusSessionStatus.abandoned),
            runtimeStatus: const Value(null),
            runtimePhase: const Value(null),
            runtimePhaseStartedAt: const Value(null),
            runtimePhaseTargetSecs: const Value(null),
          ),
        );
      }
      return active.isEmpty ? null : active.first;
    });
  }

  /// Returns the most recently finished session still waiting for Review.
  Future<FocusSession?> readPendingReviewSession() {
    return (_db.select(_db.focusSessions)
          ..where(
            (session) =>
                session.status.equals(FocusSessionStatus.reviewPending.index),
          )
          ..orderBy([
            (session) => OrderingTerm(
              expression: session.endedAt,
              mode: OrderingMode.desc,
            ),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Persists enough timer runtime to restore the live session after restart.
  Future<void> updateRuntime({
    required String sessionId,
    required timer.TimerEngineRuntimeSnapshot runtime,
    required int actualFocusSecs,
  }) async {
    await (_db.update(
      _db.focusSessions,
    )..where((s) => s.id.equals(sessionId))).write(
      FocusSessionsCompanion(
        actualFocusSecs: Value(actualFocusSecs),
        cyclesCompleted: Value(runtime.cyclesCompleted),
        runtimeStatus: Value(runtime.status.index),
        runtimePhase: Value(runtime.phase.index),
        runtimePhaseStartedAt: Value(runtime.phaseStartedAt),
        runtimeCarriedPhaseSecs: Value(runtime.carried.inSeconds),
        runtimePhaseTargetSecs: Value(runtime.phaseTarget?.inSeconds),
        runtimeBankedFocusSecs: Value(runtime.bankedFocus.inSeconds),
      ),
    );
  }

  /// Closes a session: stamps `ended_at`, sets the final [status], and writes
  /// the closing focus / cycle tally.
  ///
  /// Used both when a session is abandoned mid-run (status
  /// [FocusSessionStatus.abandoned]) and — together with [completeReview] —
  /// when it finishes.
  Future<void> finishSession({
    required String sessionId,
    required DateTime endedAt,
    required FocusSessionStatus status,
    required int actualFocusSecs,
    required int cyclesCompleted,
  }) async {
    await (_db.update(
      _db.focusSessions,
    )..where((s) => s.id.equals(sessionId))).write(
      FocusSessionsCompanion(
        endedAt: Value(endedAt),
        status: Value(status),
        actualFocusSecs: Value(actualFocusSecs),
        cyclesCompleted: Value(cyclesCompleted),
        runtimeStatus: const Value(null),
        runtimePhase: const Value(null),
        runtimePhaseStartedAt: const Value(null),
        runtimePhaseTargetSecs: const Value(null),
      ),
    );
  }

  /// Writes the post-session Review fields and marks the session
  /// [FocusSessionStatus.completed].
  ///
  /// [notes] of `null` clears the column; an empty string is stored verbatim.
  Future<void> completeReview({
    required String sessionId,
    required int postEnergy,
    String? notes,
  }) async {
    await (_db.update(
      _db.focusSessions,
    )..where((s) => s.id.equals(sessionId))).write(
      FocusSessionsCompanion(
        postEnergy: Value(postEnergy),
        notes: Value(notes),
        status: const Value(FocusSessionStatus.completed),
      ),
    );
  }

  /// Closes a pending Review without adding post-session answers.
  Future<void> discardReview(String sessionId) {
    return (_db.update(
      _db.focusSessions,
    )..where((session) => session.id.equals(sessionId))).write(
      const FocusSessionsCompanion(status: Value(FocusSessionStatus.completed)),
    );
  }

  // ---------------------------------------------------------------------------
  // Distractions
  // ---------------------------------------------------------------------------

  /// Records a distraction captured during a session.
  ///
  /// [elapsedSecs] is how far into the session the capture happened — it feeds
  /// the "when do I drift" analysis on the History screen.
  Future<void> addDistraction({
    required String sessionId,
    required DateTime capturedAt,
    required DistractionKind kind,
    required String note,
    required int elapsedSecs,
  }) async {
    await _db
        .into(_db.distractions)
        .insert(
          DistractionsCompanion.insert(
            id: newId(),
            sessionId: sessionId,
            capturedAt: capturedAt,
            kind: kind,
            note: note,
            elapsedSecs: elapsedSecs,
          ),
        );
  }

  /// Watches the distractions of [sessionId], oldest first.
  Stream<List<Distraction>> watchDistractions(String sessionId) {
    return (_db.select(_db.distractions)
          ..where((d) => d.sessionId.equals(sessionId))
          ..orderBy([(d) => OrderingTerm.asc(d.capturedAt)]))
        .watch();
  }

  // ---------------------------------------------------------------------------
  // Ritual snapshot
  // ---------------------------------------------------------------------------

  /// Snapshots the pre-study ritual into `focus_session_ritual_checks`.
  ///
  /// [items] is the list of `(itemId, label, wasChecked)` tuples as the ritual
  /// stood when the session started — the label is copied so a later rename or
  /// retirement of the source item never alters this session's history.
  Future<void> snapshotRitualChecks({
    required String sessionId,
    required List<({String itemId, String label, bool wasChecked})> items,
  }) {
    return _insertRitualChecks(sessionId: sessionId, items: items);
  }

  Future<void> _insertRitualChecks({
    required String sessionId,
    required List<({String itemId, String label, bool wasChecked})> items,
  }) async {
    if (items.isEmpty) return;
    await _db.batch((batch) {
      batch.insertAll(_db.focusSessionRitualChecks, [
        for (final item in items)
          FocusSessionRitualChecksCompanion.insert(
            id: newId(),
            sessionId: sessionId,
            itemId: Value(item.itemId),
            itemLabelSnapshot: item.label,
            wasChecked: Value(item.wasChecked),
          ),
      ]);
    });
  }

  /// Reads the ritual-check snapshot for [sessionId].
  Future<List<FocusSessionRitualCheck>> ritualChecks(String sessionId) {
    return (_db.select(
      _db.focusSessionRitualChecks,
    )..where((c) => c.sessionId.equals(sessionId))).get();
  }

  // ---------------------------------------------------------------------------
  // History
  // ---------------------------------------------------------------------------

  /// Reads a single session by [sessionId], or `null` if it does not exist.
  Future<FocusSession?> session(String sessionId) {
    return (_db.select(
      _db.focusSessions,
    )..where((s) => s.id.equals(sessionId))).getSingleOrNull();
  }

  /// Watches all focus sessions, most recent first.
  Stream<List<FocusSession>> watchHistory() {
    return (_db.select(
      _db.focusSessions,
    )..orderBy([(s) => OrderingTerm.desc(s.startedAt)])).watch();
  }

  /// Watches the full session history as [FocusSessionDetail] bundles, each
  /// joined with its distractions and ritual-check snapshot, most recent first.
  ///
  /// Exactly three batched queries back this stream: all sessions, all
  /// distractions and all ritual checks. Child rows are grouped in memory, so
  /// the query count stays constant as history grows. A runtime checkpoint
  /// invalidates only the session query; the cached child batches are reused.
  Stream<List<FocusSessionDetail>> watchHistoryDetails() {
    final distractions = (_db.select(
      _db.distractions,
    )..orderBy([(row) => OrderingTerm.asc(row.capturedAt)])).watch();
    final ritualChecks = _db.select(_db.focusSessionRitualChecks).watch();
    return _combineHistoryStreams(
      sessions: watchHistory(),
      distractions: distractions,
      ritualChecks: ritualChecks,
    );
  }
}

Stream<List<FocusSessionDetail>> _combineHistoryStreams({
  required Stream<List<FocusSession>> sessions,
  required Stream<List<Distraction>> distractions,
  required Stream<List<FocusSessionRitualCheck>> ritualChecks,
}) {
  late final StreamController<List<FocusSessionDetail>> controller;
  final subscriptions = <StreamSubscription<dynamic>>[];
  List<FocusSession>? latestSessions;
  List<Distraction>? latestDistractions;
  List<FocusSessionRitualCheck>? latestRitualChecks;
  List<FocusSessionDetail>? lastEmission;

  void emitIfReady() {
    final sessionRows = latestSessions;
    final distractionRows = latestDistractions;
    final ritualRows = latestRitualChecks;
    if (sessionRows == null || distractionRows == null || ritualRows == null) {
      return;
    }

    final distractionsBySession = <String, List<Distraction>>{};
    for (final row in distractionRows) {
      (distractionsBySession[row.sessionId] ??= <Distraction>[]).add(row);
    }
    final ritualChecksBySession = <String, List<FocusSessionRitualCheck>>{};
    for (final row in ritualRows) {
      (ritualChecksBySession[row.sessionId] ??= <FocusSessionRitualCheck>[])
          .add(row);
    }
    final next = <FocusSessionDetail>[
      for (final session in sessionRows)
        FocusSessionDetail(
          session: session,
          distractions:
              distractionsBySession[session.id] ?? const <Distraction>[],
          ritualChecks:
              ritualChecksBySession[session.id] ??
              const <FocusSessionRitualCheck>[],
        ),
    ];
    if (_historyDetailsEqual(lastEmission, next)) return;
    lastEmission = next;
    controller.add(next);
  }

  controller = StreamController<List<FocusSessionDetail>>(
    sync: true,
    onListen: () {
      subscriptions
        ..add(
          sessions.listen((rows) {
            latestSessions = rows;
            emitIfReady();
          }, onError: controller.addError),
        )
        ..add(
          distractions.listen((rows) {
            latestDistractions = rows;
            emitIfReady();
          }, onError: controller.addError),
        )
        ..add(
          ritualChecks.listen((rows) {
            latestRitualChecks = rows;
            emitIfReady();
          }, onError: controller.addError),
        );
    },
    onPause: () {
      for (final subscription in subscriptions) {
        subscription.pause();
      }
    },
    onResume: () {
      for (final subscription in subscriptions) {
        subscription.resume();
      }
    },
    onCancel: () async {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    },
  );
  return controller.stream;
}

const _distractionEquality = ListEquality<Distraction>();
const _ritualCheckEquality = ListEquality<FocusSessionRitualCheck>();

bool _historyDetailsEqual(
  List<FocusSessionDetail>? previous,
  List<FocusSessionDetail> next,
) {
  if (previous == null || previous.length != next.length) return false;
  for (var index = 0; index < next.length; index += 1) {
    final before = previous[index];
    final after = next[index];
    if (!_displayedSessionEqual(before.session, after.session) ||
        !_distractionEquality.equals(before.distractions, after.distractions) ||
        !_ritualCheckEquality.equals(before.ritualChecks, after.ritualChecks)) {
      return false;
    }
  }
  return true;
}

bool _displayedSessionEqual(FocusSession before, FocusSession after) {
  return before.id == after.id &&
      before.startedAt == after.startedAt &&
      before.goalText == after.goalText &&
      before.preEnergy == after.preEnergy &&
      before.postEnergy == after.postEnergy &&
      before.timerKind == after.timerKind &&
      before.actualFocusSecs == after.actualFocusSecs &&
      before.cyclesCompleted == after.cyclesCompleted &&
      before.status == after.status &&
      before.linkedCanvasId == after.linkedCanvasId &&
      before.notes == after.notes;
}
