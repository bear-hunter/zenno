import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenno/core/database/database.dart' hide RitualChecklist;
import 'package:zenno/core/database/tables/focus_tables.dart';
import 'package:zenno/core/database/tables/settings_tables.dart';
import 'package:zenno/core/providers/database_provider.dart';
import 'package:zenno/features/focus/application/active_session_controller.dart';
import 'package:zenno/features/focus/application/focus_providers.dart';
import 'package:zenno/features/focus/application/focus_stats_provider.dart';
import 'package:zenno/features/focus/application/focus_wakelock_service.dart';
import 'package:zenno/features/focus/data/focus_repository.dart';
import 'package:zenno/features/focus/domain/focus_session_config.dart';
import 'package:zenno/features/focus/domain/focus_stats.dart';
import 'package:zenno/features/focus/domain/timer_engine.dart';
import 'package:zenno/features/focus/presentation/pages/focus_active_page.dart';
import 'package:zenno/features/focus/presentation/pages/focus_home_page.dart';
import 'package:zenno/features/focus/presentation/pages/focus_review_page.dart';
import 'package:zenno/features/focus/presentation/pages/focus_setup_page.dart';
import 'package:zenno/features/focus/presentation/widgets/ritual_checklist.dart';
import 'package:zenno/features/focus/presentation/widgets/timer_display.dart';
import 'package:zenno/features/library/application/library_providers.dart';

void main() {
  testWidgets('Setup allows only one Start operation at a time', (
    tester,
  ) async {
    final db = ZennoDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = _ControllableFocusRepository(db);
    final createGate = Completer<String>();
    repository.nextCreate = createGate;
    final container = _focusContainer(db, repository);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: FocusSetupPage()),
      ),
    );
    await tester.pumpAndSettle();

    final start = find.text('Start session');
    await tester.scrollUntilVisible(
      start,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    final startPosition = tester.getCenter(start);
    await tester.tapAt(startPosition);
    await tester.pump();
    await tester.tapAt(startPosition);
    await tester.pump();

    expect(repository.createCalls, 1);
    expect(find.text('Starting…'), findsOneWidget);

    createGate.complete('session-1');
    await tester.pumpAndSettle();

    expect(find.byType(FocusActivePage), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
  });

  testWidgets('Active disables sibling actions and surfaces a failed pause', (
    tester,
  ) async {
    final db = ZennoDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = _ControllableFocusRepository(db);
    final container = _focusContainer(db, repository);
    addTearDown(container.dispose);
    await tester.runAsync(() => _startSession(container));

    final runtimeGate = Completer<void>();
    repository.nextRuntimeWrite = runtimeGate;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: FocusActivePage()),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Pause'));
    await tester.pump();

    final resumeButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Resume'),
    );
    expect(resumeButton.onPressed, isNull);
    expect(repository.runtimeWriteCalls, 2);

    runtimeGate.completeError(StateError('disk full'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text('Could not pause the session. Please try again.'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
  });

  testWidgets('Active allows only one Finish operation at a time', (
    tester,
  ) async {
    final db = ZennoDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = _ControllableFocusRepository(db);
    final container = _focusContainer(db, repository);
    addTearDown(container.dispose);
    await tester.runAsync(() => _startSession(container));

    final finishGate = Completer<void>();
    repository.nextFinish = finishGate;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: FocusActivePage()),
      ),
    );
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Finish'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    final finishPosition = tester.getCenter(find.text('Finish'));
    await tester.tapAt(finishPosition);
    await tester.pump();
    await tester.tapAt(finishPosition);
    await tester.pump();

    expect(repository.finishCalls, 1);
    expect(find.text('Finishing…'), findsOneWidget);

    finishGate.complete();
    await tester.pumpAndSettle();

    expect(find.byType(FocusReviewPage), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
  });

  testWidgets('Review ignores back navigation while save is in flight', (
    tester,
  ) async {
    final db = ZennoDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = _ControllableFocusRepository(db);
    final container = _focusContainer(db, repository);
    addTearDown(container.dispose);
    await tester.runAsync(() async {
      await _startSession(container);
      await container.read(activeSessionControllerProvider.notifier).stop();
    });

    final reviewGate = Completer<void>();
    repository.nextReview = reviewGate;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: FocusReviewPage()),
      ),
    );
    await tester.pump();

    final save = find.text('Save & finish');
    await tester.scrollUntilVisible(
      save,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(save);
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(repository.reviewCalls, 1);
    expect(find.text('Saving…'), findsOneWidget);
    expect(find.text('Discard changes?'), findsNothing);

    reviewGate.complete();
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
  });

  testWidgets('Focus home labels its unfiltered aggregate as All time', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeSessionControllerProvider.overrideWithValue(
            ActiveSessionState.none,
          ),
          focusHistoryProvider.overrideWith((ref) => Stream.value(const [])),
          focusStatsProvider.overrideWithValue(
            const FocusStats(
              completedSessions: 1,
              totalFocus: Duration(minutes: 25),
              avgPreEnergy: 3,
              avgPostEnergy: 4,
              avgEnergyDelta: 1,
              totalDistractions: 0,
              internalDistractions: 0,
              externalDistractions: 0,
              distractionsPerSession: 0,
            ),
          ),
        ],
        child: const MaterialApp(home: FocusHomePage()),
      ),
    );
    await tester.pump();

    expect(find.text('All time'), findsOneWidget);
    expect(find.text('This month'), findsNothing);
  });

  testWidgets('Focus home does not offer Start during restoration', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeSessionControllerProvider.overrideWithValue(
            ActiveSessionState.restoring,
          ),
          focusHistoryProvider.overrideWith((ref) => Stream.value(const [])),
          focusStatsProvider.overrideWithValue(FocusStats.empty),
        ],
        child: const MaterialApp(home: FocusHomePage()),
      ),
    );
    await tester.pump();

    expect(find.text('Restoring your focus session…'), findsOneWidget);
    expect(find.text('Start a focus session'), findsNothing);
  });

  testWidgets('focus timer fits the available compact width', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 220,
              child: TimerDisplay(
                snapshot: TimerSnapshot(
                  status: TimerStatus.running,
                  phase: TimerPhase.work,
                  mode: TimerMode.pomodoro,
                  elapsed: Duration(minutes: 5),
                  remaining: Duration(minutes: 20),
                  target: Duration(minutes: 25),
                  cyclesCompleted: 0,
                  accumulatedFocus: Duration(minutes: 5),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byKey(const ValueKey('focus-timer-ring'))).width,
      lessThanOrEqualTo(220),
    );
  });

  testWidgets('management-only ritual rows do not show fake checkboxes', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RitualChecklist(
            items: [
              RitualChecklistItem(
                id: 'ritual-1',
                checklistId: 'default',
                label: 'Clear the desk',
                position: 1,
                isActive: true,
              ),
            ],
            checkedItemIds: <String>{},
            onToggle: null,
            editable: false,
          ),
        ),
      ),
    );

    expect(find.text('Clear the desk'), findsOneWidget);
    expect(find.byIcon(Icons.check_box_outline_blank), findsNothing);
    expect(find.byIcon(Icons.check_box), findsNothing);
  });
}

ProviderContainer _focusContainer(
  ZennoDatabase db,
  _ControllableFocusRepository repository,
) {
  return ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(db),
      focusRepositoryProvider.overrideWithValue(repository),
      focusWakelockServiceProvider.overrideWithValue(
        const _FakeWakelockService(),
      ),
      focusSettingsProvider.overrideWith((ref) => Stream.value(_settings)),
      ritualItemsProvider.overrideWith((ref) => Stream.value(const [])),
      canvasListProvider.overrideWith((ref) => Stream.value(const [])),
    ],
  );
}

Future<void> _startSession(ProviderContainer container) async {
  container.read(activeSessionControllerProvider);
  await pumpEventQueue();
  await container
      .read(activeSessionControllerProvider.notifier)
      .startFrom(_config, checkedRitualItems: const []);
}

const _config = FocusSessionConfig(
  mode: TimerMode.pomodoro,
  goalText: 'Review physiology',
  preEnergy: 4,
  plannedDuration: Duration(minutes: 25),
  pomodoroWork: Duration(minutes: 25),
  pomodoroBreak: Duration(minutes: 5),
  flowBreakRatio: 0.2,
  linkedCanvasId: null,
);

const _settings = AppSetting(
  id: 'singleton',
  themeMode: ThemeModeSetting.system,
  accentColor: 0,
  backgroundColor: 0,
  inkPaletteJson: '[]',
  stylusMappingJson: '{}',
  penProfileJson: '{}',
  toolWheelPositionJson: '{}',
  defaultPomodoroWorkSecs: 1500,
  defaultPomodoroBreakSecs: 300,
  defaultFlowBreakRatio: 0.2,
  defaultSessionLengthSecs: 1500,
  keepScreenOnInFocus: false,
  librarySort: LibrarySort.recent,
  onboardingDone: true,
  dbSchemaSeeded: true,
);

class _ControllableFocusRepository extends FocusRepository {
  _ControllableFocusRepository(super.db);

  int createCalls = 0;
  int runtimeWriteCalls = 0;
  int finishCalls = 0;
  int reviewCalls = 0;
  Completer<String>? nextCreate;
  Completer<void>? nextRuntimeWrite;
  Completer<void>? nextFinish;
  Completer<void>? nextReview;

  @override
  Future<FocusSession?> readLatestInProgressSession() async => null;

  @override
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
  }) {
    createCalls += 1;
    final gate = nextCreate;
    nextCreate = null;
    return gate?.future ?? Future.value('session-$createCalls');
  }

  @override
  Future<void> updateRuntime({
    required String sessionId,
    required TimerEngineRuntimeSnapshot runtime,
    required int actualFocusSecs,
  }) {
    runtimeWriteCalls += 1;
    final gate = nextRuntimeWrite;
    nextRuntimeWrite = null;
    return gate?.future ?? Future.value();
  }

  @override
  Future<void> finishSession({
    required String sessionId,
    required DateTime endedAt,
    required FocusSessionStatus status,
    required int actualFocusSecs,
    required int cyclesCompleted,
  }) {
    finishCalls += 1;
    final gate = nextFinish;
    nextFinish = null;
    return gate?.future ?? Future.value();
  }

  @override
  Future<void> completeReview({
    required String sessionId,
    required int postEnergy,
    String? notes,
  }) {
    reviewCalls += 1;
    final gate = nextReview;
    nextReview = null;
    return gate?.future ?? Future.value();
  }

  @override
  Stream<List<Distraction>> watchDistractions(String sessionId) {
    return Stream.value(const []);
  }
}

class _FakeWakelockService extends FocusWakelockService {
  const _FakeWakelockService();

  @override
  Future<void> setEnabled(bool enabled) => Future.value();
}
