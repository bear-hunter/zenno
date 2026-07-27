import 'dart:async';

import 'package:drift/drift.dart'
    show ApplyInterceptor, QueryExecutor, QueryInterceptor, Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenno/core/database/database.dart';
import 'package:zenno/core/database/tables/focus_tables.dart';
import 'package:zenno/features/focus/data/focus_repository.dart';
import 'package:zenno/features/focus/domain/timer_engine.dart';

void main() {
  late ZennoDatabase db;
  late FocusRepository repo;
  late _SelectRecorder selects;

  setUp(() async {
    selects = _SelectRecorder();
    db = ZennoDatabase(NativeDatabase.memory().interceptWith(selects));
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

  test(
    'history detail query count stays fixed as session count grows',
    () async {
      const sessionCount = 24;
      await db.batch((batch) {
        batch.insertAll(db.focusSessions, [
          for (var index = 0; index < sessionCount; index += 1)
            FocusSessionsCompanion.insert(
              id: 'history-$index',
              startedAt: DateTime.utc(2026, 7, 1, index),
              goalText: 'Session $index',
              preEnergy: 3,
              timerKind: TimerKind.pomodoro,
              plannedDurationSecs: 1500,
              status: FocusSessionStatus.completed,
            ),
        ]);
        batch.insertAll(db.distractions, [
          for (var index = 0; index < sessionCount; index += 1)
            DistractionsCompanion.insert(
              id: 'distraction-$index',
              sessionId: 'history-$index',
              capturedAt: DateTime.utc(2026, 7, 1, index, 1),
              kind: DistractionKind.internal,
              note: 'Thought',
              elapsedSecs: 60,
            ),
        ]);
        batch.insertAll(db.focusSessionRitualChecks, [
          for (var index = 0; index < sessionCount; index += 1)
            FocusSessionRitualChecksCompanion.insert(
              id: 'check-$index',
              sessionId: 'history-$index',
              itemLabelSnapshot: 'Clear desk',
            ),
        ]);
      });
      selects.statements.clear();

      final details = await repo.watchHistoryDetails().first;

      expect(details, hasLength(sessionCount));
      expect(
        details.every((detail) => detail.distractions.length == 1),
        isTrue,
      );
      expect(
        details.every((detail) => detail.ritualChecks.length == 1),
        isTrue,
      );
      expect(
        selects.statements.where(_isHistorySelect),
        hasLength(3),
        reason: 'History must use one fixed query per backing table.',
      );
    },
  );

  test(
    'runtime checkpoints reuse child batches and emit only displayed changes',
    () async {
      await db
          .into(db.focusSessions)
          .insert(
            FocusSessionsCompanion.insert(
              id: 'live-history',
              startedAt: DateTime.utc(2026, 7, 20),
              goalText: 'Live',
              preEnergy: 4,
              timerKind: TimerKind.pomodoro,
              plannedDurationSecs: 1500,
              status: FocusSessionStatus.inProgress,
            ),
          );
      var emissions = 0;
      final initial = Completer<void>();
      final displayedChange = Completer<void>();
      final subscription = repo.watchHistoryDetails().listen((_) {
        emissions += 1;
        if (emissions == 1) initial.complete();
        if (emissions == 2) displayedChange.complete();
      });
      addTearDown(subscription.cancel);
      await initial.future;

      selects.statements.clear();
      await repo.updateRuntime(
        sessionId: 'live-history',
        runtime: TimerEngineRuntimeSnapshot(
          status: TimerStatus.running,
          phase: TimerPhase.work,
          phaseStartedAt: DateTime.utc(2026, 7, 20, 0, 0, 1),
          carried: const Duration(seconds: 1),
          phaseTarget: const Duration(minutes: 25),
          bankedFocus: Duration.zero,
          cyclesCompleted: 0,
        ),
        actualFocusSecs: 0,
      );
      await pumpEventQueue();

      expect(emissions, 1);
      expect(selects.statements.where(_isFocusSessionSelect), hasLength(1));
      expect(selects.statements.where(_isHistoryChildSelect), isEmpty);

      selects.statements.clear();
      await repo.updateRuntime(
        sessionId: 'live-history',
        runtime: TimerEngineRuntimeSnapshot(
          status: TimerStatus.running,
          phase: TimerPhase.work,
          phaseStartedAt: DateTime.utc(2026, 7, 20),
          carried: const Duration(seconds: 15),
          phaseTarget: const Duration(minutes: 25),
          bankedFocus: Duration.zero,
          cyclesCompleted: 0,
        ),
        actualFocusSecs: 15,
      );
      await displayedChange.future.timeout(const Duration(seconds: 2));

      expect(emissions, 2);
      expect(selects.statements.where(_isFocusSessionSelect), hasLength(1));
      expect(selects.statements.where(_isHistoryChildSelect), isEmpty);
    },
  );
}

bool _isHistorySelect(String statement) =>
    _isFocusSessionSelect(statement) || _isHistoryChildSelect(statement);

bool _isFocusSessionSelect(String statement) =>
    statement.contains('FROM "focus_sessions"');

bool _isHistoryChildSelect(String statement) =>
    statement.contains('FROM "distractions"') ||
    statement.contains('FROM "focus_session_ritual_checks"');

class _SelectRecorder extends QueryInterceptor {
  final List<String> statements = <String>[];

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    statements.add(statement);
    return executor.runSelect(statement, args);
  }
}
