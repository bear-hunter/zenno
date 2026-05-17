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
}
