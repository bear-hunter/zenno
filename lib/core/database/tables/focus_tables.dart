import 'package:drift/drift.dart';
import 'package:zenno/core/database/tables/canvas_tables.dart';

/// The timing model a focus session runs on.
enum TimerKind { pomodoro, flowmodoro }

/// Lifecycle state of a focus session.
enum FocusSessionStatus { inProgress, completed, abandoned }

/// Whether a captured distraction originated from the user or the environment.
enum DistractionKind { internal, external }

/// A reusable pre-study ritual checklist.
class RitualChecklists extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// An item belonging to a [RitualChecklists] row. Retired items are kept
/// (deactivated) so historical session snapshots stay coherent.
class RitualChecklistItems extends Table {
  TextColumn get id => text()();
  TextColumn get checklistId =>
      text().references(RitualChecklists, #id, onDelete: KeyAction.cascade)();
  TextColumn get label => text()();

  /// Fractional ordering position.
  RealColumn get position => real()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// A single focus (Pomodoro or Flowmodoro) study session.
@TableIndex(name: 'idx_focus_sessions_started_at', columns: {#startedAt})
class FocusSessions extends Table {
  TextColumn get id => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  TextColumn get goalText => text()();

  /// Self-rated energy on a 1–5 scale.
  IntColumn get preEnergy => integer()();
  IntColumn get postEnergy => integer().nullable()();

  IntColumn get timerKind => intEnum<TimerKind>()();
  IntColumn get plannedDurationSecs => integer()();

  /// Accumulated work time only (excludes breaks).
  IntColumn get actualFocusSecs => integer().withDefault(const Constant(0))();

  IntColumn get pomodoroWorkSecs => integer().nullable()();
  IntColumn get pomodoroBreakSecs => integer().nullable()();
  RealColumn get flowBreakRatio => real().nullable()();

  IntColumn get cyclesCompleted => integer().withDefault(const Constant(0))();
  IntColumn get status => intEnum<FocusSessionStatus>()();

  TextColumn get linkedCanvasId =>
      text().nullable().references(Canvases, #id, onDelete: KeyAction.cascade)();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Per-session snapshot of a ritual checklist item, captured at session start
/// so the label as it was then is preserved.
class FocusSessionRitualChecks extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId =>
      text().references(FocusSessions, #id, onDelete: KeyAction.cascade)();
  TextColumn get itemId => text()
      .nullable()
      .references(RitualChecklistItems, #id, onDelete: KeyAction.cascade)();

  /// The item label as it read when the session started.
  TextColumn get itemLabelSnapshot => text()();
  BoolColumn get wasChecked => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// A distraction captured during a focus session.
@TableIndex(name: 'idx_distractions_session_id', columns: {#sessionId})
class Distractions extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId =>
      text().references(FocusSessions, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get capturedAt => dateTime()();
  IntColumn get kind => intEnum<DistractionKind>()();
  TextColumn get note => text()();

  /// Seconds into the session — feeds "when do I drift" analysis.
  IntColumn get elapsedSecs => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
