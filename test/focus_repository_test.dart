import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenno/core/database/database.dart';
import 'package:zenno/core/database/tables/focus_tables.dart';
import 'package:zenno/features/focus/data/focus_repository.dart';

void main() {
  late ZennoDatabase db;
  late FocusRepository repo;

  setUp(() async {
    db = ZennoDatabase(NativeDatabase.memory());
    repo = FocusRepository(db);
    await db
        .into(db.canvases)
        .insert(
          CanvasesCompanion.insert(
            id: 'canvas-1',
            title: 'Working canvas',
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  test('createSession persists linked canvas id', () async {
    final sessionId = await repo.createSession(
      startedAt: DateTime.utc(2026, 5, 17),
      goalText: 'Renal physiology',
      preEnergy: 4,
      timerKind: TimerKind.pomodoro,
      plannedDurationSecs: 3000,
      pomodoroWorkSecs: 1500,
      pomodoroBreakSecs: 300,
      linkedCanvasId: 'canvas-1',
    );

    final session = await repo.session(sessionId);

    expect(session?.linkedCanvasId, 'canvas-1');
  });

  test('createSession refuses a second live session', () async {
    await repo.createSession(
      startedAt: DateTime.utc(2026, 5, 17),
      goalText: 'First',
      preEnergy: 4,
      timerKind: TimerKind.pomodoro,
      plannedDurationSecs: 1500,
    );

    await expectLater(
      repo.createSession(
        startedAt: DateTime.utc(2026, 5, 17, 1),
        goalText: 'Second',
        preEnergy: 4,
        timerKind: TimerKind.pomodoro,
        plannedDurationSecs: 1500,
      ),
      throwsA(isA<FocusSessionAlreadyActiveException>()),
    );

    expect(await db.select(db.focusSessions).get(), hasLength(1));
  });

  test('restore repairs older duplicate live sessions', () async {
    final oldStart = DateTime.utc(2026, 5, 17);
    final newStart = DateTime.utc(2026, 5, 17, 1);
    await db.batch((batch) {
      batch.insertAll(db.focusSessions, [
        FocusSessionsCompanion.insert(
          id: 'old-live',
          startedAt: oldStart,
          goalText: 'Old',
          preEnergy: 3,
          timerKind: TimerKind.pomodoro,
          plannedDurationSecs: 1500,
          status: FocusSessionStatus.inProgress,
          runtimeStatus: const Value(1),
          runtimePhase: const Value(0),
          runtimePhaseStartedAt: Value(oldStart),
        ),
        FocusSessionsCompanion.insert(
          id: 'new-live',
          startedAt: newStart,
          goalText: 'New',
          preEnergy: 4,
          timerKind: TimerKind.pomodoro,
          plannedDurationSecs: 1500,
          status: FocusSessionStatus.inProgress,
          runtimeStatus: const Value(1),
          runtimePhase: const Value(0),
          runtimePhaseStartedAt: Value(newStart),
        ),
      ]);
    });

    final restored = await repo.readLatestInProgressSession();
    final old = await repo.session('old-live');

    expect(restored?.id, 'new-live');
    expect(old?.status, FocusSessionStatus.abandoned);
    expect(old?.endedAt, newStart);
    expect(old?.runtimeStatus, isNull);
    expect(
      await db
          .select(db.focusSessions)
          .get()
          .then(
            (rows) => rows
                .where((row) => row.status == FocusSessionStatus.inProgress)
                .length,
          ),
      1,
    );
  });

  test('createSession rolls back if the ritual snapshot fails', () async {
    expect(
      () => repo.createSession(
        startedAt: DateTime.utc(2026, 5, 17),
        goalText: 'Renal physiology',
        preEnergy: 4,
        timerKind: TimerKind.pomodoro,
        plannedDurationSecs: 3000,
        pomodoroWorkSecs: 1500,
        pomodoroBreakSecs: 300,
        ritualItems: const [
          (
            itemId: 'missing-ritual-item',
            label: 'Missing item',
            wasChecked: true,
          ),
        ],
      ),
      throwsA(isA<Exception>()),
    );

    expect(await db.select(db.focusSessions).get(), isEmpty);
  });

  test('finishing clears restorable live runtime fields', () async {
    final sessionId = await repo.createSession(
      startedAt: DateTime.utc(2026, 5, 17),
      goalText: 'Renal physiology',
      preEnergy: 4,
      timerKind: TimerKind.pomodoro,
      plannedDurationSecs: 3000,
      pomodoroWorkSecs: 1500,
      pomodoroBreakSecs: 300,
    );

    await repo.finishSession(
      sessionId: sessionId,
      endedAt: DateTime.utc(2026, 5, 17, 1),
      status: FocusSessionStatus.completed,
      actualFocusSecs: 1200,
      cyclesCompleted: 0,
    );

    final session = await repo.session(sessionId);
    expect(session!.runtimeStatus, isNull);
    expect(session.runtimePhase, isNull);
    expect(session.runtimePhaseStartedAt, isNull);
    expect(session.runtimePhaseTargetSecs, isNull);
  });
}
