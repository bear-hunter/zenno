import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenno/core/database/database.dart';
import 'package:zenno/core/database/tables/focus_tables.dart';
import 'package:zenno/core/providers/database_provider.dart';
import 'package:zenno/features/focus/application/active_session_controller.dart';
import 'package:zenno/features/focus/application/focus_wakelock_service.dart';
import 'package:zenno/features/focus/domain/focus_session_config.dart';
import 'package:zenno/features/focus/domain/timer_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'backgrounding suspends ticker and resume catches up from wall clock',
    () async {
      final db = ZennoDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      var now = DateTime.utc(2026, 7, 10, 9);
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          focusClockProvider.overrideWithValue(() => now),
          focusWakelockServiceProvider.overrideWithValue(
            const _FakeWakelockService(),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(activeSessionControllerProvider);
      await pumpEventQueue();
      const config = FocusSessionConfig(
        mode: TimerMode.pomodoro,
        goalText: 'Review physiology',
        preEnergy: 4,
        plannedDuration: Duration(minutes: 4),
        pomodoroWork: Duration(minutes: 1),
        pomodoroBreak: Duration(minutes: 1),
        flowBreakRatio: 0.2,
        linkedCanvasId: null,
      );
      final controller = container.read(
        activeSessionControllerProvider.notifier,
      );

      await controller.startFrom(config, checkedRitualItems: const []);
      expect(controller.debugTickerActive, isTrue);

      controller.didChangeAppLifecycleState(AppLifecycleState.paused);
      await pumpEventQueue();
      expect(controller.debugTickerActive, isFalse);

      now = now.add(const Duration(minutes: 2, seconds: 30));
      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await pumpEventQueue();

      final snapshot = container.read(activeSessionControllerProvider).snapshot;
      expect(snapshot?.phase, TimerPhase.work);
      expect(snapshot?.elapsed, const Duration(seconds: 30));
      expect(snapshot?.cyclesCompleted, 1);
      expect(controller.debugTickerActive, isTrue);
    },
  );

  test('paused focus session does not keep a repaint ticker alive', () async {
    final db = ZennoDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        focusWakelockServiceProvider.overrideWithValue(
          const _FakeWakelockService(),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(activeSessionControllerProvider);
    await pumpEventQueue();
    const config = FocusSessionConfig(
      mode: TimerMode.pomodoro,
      goalText: 'Review physiology',
      preEnergy: 4,
      plannedDuration: Duration(minutes: 25),
      pomodoroWork: Duration(minutes: 25),
      pomodoroBreak: Duration(minutes: 5),
      flowBreakRatio: 0.2,
      linkedCanvasId: null,
    );
    final controller = container.read(activeSessionControllerProvider.notifier);

    await controller.startFrom(config, checkedRitualItems: const []);
    expect(controller.debugTickerActive, isTrue);

    await controller.pause();
    expect(controller.debugTickerActive, isFalse);

    await controller.resume();
    expect(controller.debugTickerActive, isTrue);
  });

  test(
    'restore keeps zero elapsed at the start of a persisted break',
    () async {
      final db = ZennoDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final startedAt = DateTime.utc(2026, 7, 10, 9);
      await db
          .into(db.focusSessions)
          .insert(
            FocusSessionsCompanion.insert(
              id: 'session-1',
              startedAt: startedAt,
              goalText: 'Review physiology',
              preEnergy: 4,
              timerKind: TimerKind.pomodoro,
              plannedDurationSecs: 3000,
              pomodoroWorkSecs: const Value(1500),
              pomodoroBreakSecs: const Value(300),
              actualFocusSecs: const Value(1500),
              cyclesCompleted: const Value(1),
              status: FocusSessionStatus.inProgress,
              runtimeStatus: Value(TimerStatus.paused.index),
              runtimePhase: Value(TimerPhase.breakTime.index),
              runtimeCarriedPhaseSecs: const Value(0),
              runtimePhaseTargetSecs: const Value(300),
              runtimeBankedFocusSecs: const Value(1500),
            ),
          );

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          focusWakelockServiceProvider.overrideWithValue(
            const _FakeWakelockService(),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(activeSessionControllerProvider);
      await pumpEventQueue();

      final snapshot = container.read(activeSessionControllerProvider).snapshot;
      expect(snapshot, isNotNull);
      expect(snapshot!.phase, TimerPhase.breakTime);
      expect(snapshot.elapsed, Duration.zero);
      expect(snapshot.remaining, const Duration(minutes: 5));
      expect(snapshot.accumulatedFocus, const Duration(minutes: 25));
    },
  );

  test('concurrent starts create only one in-progress session', () async {
    final db = ZennoDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        focusWakelockServiceProvider.overrideWithValue(
          const _FakeWakelockService(),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(activeSessionControllerProvider);
    await pumpEventQueue();

    const config = FocusSessionConfig(
      mode: TimerMode.pomodoro,
      goalText: 'Review physiology',
      preEnergy: 4,
      plannedDuration: Duration(minutes: 50),
      pomodoroWork: Duration(minutes: 25),
      pomodoroBreak: Duration(minutes: 5),
      flowBreakRatio: 0.2,
      linkedCanvasId: null,
    );
    final controller = container.read(activeSessionControllerProvider.notifier);

    await Future.wait([
      controller.startFrom(config, checkedRitualItems: const []),
      controller.startFrom(config, checkedRitualItems: const []),
    ]);

    final sessions = await db.select(db.focusSessions).get();
    expect(sessions, hasLength(1));
  });

  test('active timer reads the current time on every transition', () async {
    final db = ZennoDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    var now = DateTime.utc(2026, 7, 10, 9);
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        focusClockProvider.overrideWithValue(() => now),
        focusWakelockServiceProvider.overrideWithValue(
          const _FakeWakelockService(),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(activeSessionControllerProvider);
    await pumpEventQueue();
    const config = FocusSessionConfig(
      mode: TimerMode.pomodoro,
      goalText: 'Review physiology',
      preEnergy: 4,
      plannedDuration: Duration(minutes: 50),
      pomodoroWork: Duration(minutes: 25),
      pomodoroBreak: Duration(minutes: 5),
      flowBreakRatio: 0.2,
      linkedCanvasId: null,
    );
    final controller = container.read(activeSessionControllerProvider.notifier);

    await controller.startFrom(config, checkedRitualItems: const []);
    now = now.add(const Duration(minutes: 2));
    await controller.pause();

    final state = container.read(activeSessionControllerProvider);
    expect(state.snapshot!.elapsed, const Duration(minutes: 2));
  });

  test(
    'start waits for restoration and does not orphan an older session',
    () async {
      final db = ZennoDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final startedAt = DateTime.utc(2026, 7, 10, 8);
      await db
          .into(db.focusSessions)
          .insert(
            FocusSessionsCompanion.insert(
              id: 'restored-session',
              startedAt: startedAt,
              goalText: 'Existing session',
              preEnergy: 3,
              timerKind: TimerKind.pomodoro,
              plannedDurationSecs: 1500,
              pomodoroWorkSecs: const Value(1500),
              pomodoroBreakSecs: const Value(300),
              status: FocusSessionStatus.inProgress,
              runtimeStatus: Value(TimerStatus.paused.index),
              runtimePhase: Value(TimerPhase.work.index),
            ),
          );
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          focusWakelockServiceProvider.overrideWithValue(
            const _FakeWakelockService(),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(activeSessionControllerProvider);
      final controller = container.read(
        activeSessionControllerProvider.notifier,
      );
      const replacement = FocusSessionConfig(
        mode: TimerMode.pomodoro,
        goalText: 'Replacement session',
        preEnergy: 4,
        plannedDuration: Duration(minutes: 25),
        pomodoroWork: Duration(minutes: 25),
        pomodoroBreak: Duration(minutes: 5),
        flowBreakRatio: 0.2,
        linkedCanvasId: null,
      );

      final started = await controller.startFrom(
        replacement,
        checkedRitualItems: const [],
      );

      expect(started, isFalse);
      expect(await db.select(db.focusSessions).get(), hasLength(1));
      expect(
        container.read(activeSessionControllerProvider).sessionId,
        'restored-session',
      );
    },
  );

  test('wakelock failure does not strand a committed session', () async {
    final db = ZennoDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        focusWakelockServiceProvider.overrideWithValue(
          const _ThrowingWakelockService(),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(activeSessionControllerProvider);
    await pumpEventQueue();
    const config = FocusSessionConfig(
      mode: TimerMode.pomodoro,
      goalText: 'Review physiology',
      preEnergy: 4,
      plannedDuration: Duration(minutes: 25),
      pomodoroWork: Duration(minutes: 25),
      pomodoroBreak: Duration(minutes: 5),
      flowBreakRatio: 0.2,
      linkedCanvasId: null,
    );

    final started = await container
        .read(activeSessionControllerProvider.notifier)
        .startFrom(config, checkedRitualItems: const []);

    expect(started, isTrue);
    expect(container.read(activeSessionControllerProvider).hasSession, isTrue);
    expect(await db.select(db.focusSessions).get(), hasLength(1));
  });

  test('finished session restores its pending Review after restart', () async {
    final db = ZennoDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final first = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        focusWakelockServiceProvider.overrideWithValue(
          const _FakeWakelockService(),
        ),
      ],
    );
    first.read(activeSessionControllerProvider);
    await pumpEventQueue();
    const config = FocusSessionConfig(
      mode: TimerMode.pomodoro,
      goalText: 'Durable review',
      preEnergy: 4,
      plannedDuration: Duration(minutes: 25),
      pomodoroWork: Duration(minutes: 25),
      pomodoroBreak: Duration(minutes: 5),
      flowBreakRatio: 0.2,
      linkedCanvasId: null,
    );
    final firstController = first.read(
      activeSessionControllerProvider.notifier,
    );
    await firstController.startFrom(config, checkedRitualItems: const []);
    await firstController.stop();
    expect(
      (await db.select(db.focusSessions).getSingle()).status,
      FocusSessionStatus.reviewPending,
    );
    first.dispose();

    final second = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        focusWakelockServiceProvider.overrideWithValue(
          const _FakeWakelockService(),
        ),
      ],
    );
    addTearDown(second.dispose);
    second.read(activeSessionControllerProvider);
    await pumpEventQueue();

    final restored = second.read(activeSessionControllerProvider);
    expect(restored.reviewPending, isTrue);
    expect(restored.sessionId, isNotNull);
    expect(restored.snapshot?.status, TimerStatus.finished);

    await second.read(activeSessionControllerProvider.notifier).discard();
    expect(second.read(activeSessionControllerProvider).hasSession, isFalse);
    expect(
      (await db.select(db.focusSessions).getSingle()).status,
      FocusSessionStatus.completed,
    );
  });
}

class _FakeWakelockService extends FocusWakelockService {
  const _FakeWakelockService();

  @override
  Future<void> setEnabled(bool enabled) => Future<void>.value();
}

class _ThrowingWakelockService extends FocusWakelockService {
  const _ThrowingWakelockService();

  @override
  Future<void> setEnabled(bool enabled) => Future<void>.error('unavailable');
}
