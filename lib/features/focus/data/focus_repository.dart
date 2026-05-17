import 'package:drift/drift.dart';
import 'package:zenno/core/database/database.dart';
import 'package:zenno/core/database/tables/focus_tables.dart';
import 'package:zenno/core/util/id.dart';

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
  }) async {
    final id = newId();
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
          ),
        );
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
    await (_db.update(_db.focusSessions)
          ..where((s) => s.id.equals(sessionId)))
        .write(
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
    await (_db.update(_db.focusSessions)
          ..where((s) => s.id.equals(sessionId)))
        .write(
          FocusSessionsCompanion(
            endedAt: Value(endedAt),
            status: Value(status),
            actualFocusSecs: Value(actualFocusSecs),
            cyclesCompleted: Value(cyclesCompleted),
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
    await (_db.update(_db.focusSessions)
          ..where((s) => s.id.equals(sessionId)))
        .write(
          FocusSessionsCompanion(
            postEnergy: Value(postEnergy),
            notes: Value(notes),
            status: const Value(FocusSessionStatus.completed),
          ),
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
    return (_db.select(_db.focusSessionRitualChecks)
          ..where((c) => c.sessionId.equals(sessionId)))
        .get();
  }

  // ---------------------------------------------------------------------------
  // History
  // ---------------------------------------------------------------------------

  /// Reads a single session by [sessionId], or `null` if it does not exist.
  Future<FocusSession?> session(String sessionId) {
    return (_db.select(_db.focusSessions)
          ..where((s) => s.id.equals(sessionId)))
        .getSingleOrNull();
  }

  /// Watches all focus sessions, most recent first.
  Stream<List<FocusSession>> watchHistory() {
    return (_db.select(_db.focusSessions)
          ..orderBy([(s) => OrderingTerm.desc(s.startedAt)]))
        .watch();
  }

  /// Watches the full session history as [FocusSessionDetail] bundles, each
  /// joined with its distractions and ritual-check snapshot, most recent first.
  ///
  /// Built by watching the sessions stream and resolving the children per
  /// emission. The History feed is small (one row per study session), so the
  /// per-emission child fetch is comfortably cheap.
  Stream<List<FocusSessionDetail>> watchHistoryDetails() {
    return watchHistory().asyncMap((sessions) async {
      final details = <FocusSessionDetail>[];
      for (final session in sessions) {
        final distractions =
            await (_db.select(_db.distractions)
                  ..where((d) => d.sessionId.equals(session.id))
                  ..orderBy([(d) => OrderingTerm.asc(d.capturedAt)]))
                .get();
        final checks = await ritualChecks(session.id);
        details.add(
          FocusSessionDetail(
            session: session,
            distractions: distractions,
            ritualChecks: checks,
          ),
        );
      }
      return details;
    });
  }
}
