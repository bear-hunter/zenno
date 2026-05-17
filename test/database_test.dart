import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenno/core/database/database.dart';
import 'package:zenno/core/database/tables/canvas_tables.dart';

import 'generated_migrations/schema.dart';

void main() {
  late ZennoDatabase db;

  setUp(() {
    db = ZennoDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('foreign-key cascade deletes canvas children', () async {
    const canvasId = 'canvas-1';
    const elementId = 'element-1';

    await db
        .into(db.canvases)
        .insert(
          CanvasesCompanion.insert(
            id: canvasId,
            title: 'Test canvas',
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
          ),
        );

    await db
        .into(db.canvasElements)
        .insert(
          CanvasElementsCompanion.insert(
            id: elementId,
            canvasId: canvasId,
            kind: ElementKind.stroke,
            x: 0,
            y: 0,
            width: 100,
            height: 100,
            zIndex: 0,
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
          ),
        );

    await db
        .into(db.inkStrokes)
        .insert(
          InkStrokesCompanion.insert(
            elementId: elementId,
            points: Uint8List.fromList(const [1, 0, 0, 0]),
            pointCount: 0,
            color: 0xFF000000,
            strokeWidth: 2,
            tool: StrokeTool.pen,
          ),
        );

    // Sanity: children exist before the cascade.
    expect(await db.select(db.canvasElements).get(), hasLength(1));
    expect(await db.select(db.inkStrokes).get(), hasLength(1));

    // Deleting the canvas should cascade to elements and strokes.
    await (db.delete(db.canvases)..where((c) => c.id.equals(canvasId))).go();

    final remainingElements = await (db.select(
      db.canvasElements,
    )..where((e) => e.canvasId.equals(canvasId))).get();
    final remainingStrokes = await (db.select(
      db.inkStrokes,
    )..where((s) => s.elementId.equals(elementId))).get();

    expect(remainingElements, isEmpty);
    expect(remainingStrokes, isEmpty);
  });

  test('seed inserts 4 builtin templates and 2 boards', () async {
    // Touch the database so `beforeOpen` runs the migration + seed.
    await db.select(db.appSettings).get();

    final builtinTemplates = await (db.select(
      db.reflectionTemplates,
    )..where((t) => t.isBuiltin.equals(true))).get();
    final boards = await db.select(db.boards).get();

    expect(builtinTemplates, hasLength(4));
    expect(boards, hasLength(2));

    final settings = await db.select(db.appSettings).getSingle();
    expect(settings.dbSchemaSeeded, isTrue);
  });

  test('v1 migrates to v2 and preserves in-progress focus sessions', () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    addTearDown(() {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
    });
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema = await verifier.schemaAt(1);

    schema.rawDatabase.execute(
      '''
      INSERT INTO focus_sessions (
        id, started_at, goal_text, pre_energy, timer_kind,
        planned_duration_secs, actual_focus_secs, pomodoro_work_secs,
        pomodoro_break_secs, cycles_completed, status
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        'session-v1',
        DateTime.utc(2026, 5, 17).toIso8601String(),
        'Read chapter 4',
        4,
        0,
        1500,
        120,
        1500,
        300,
        1,
        0,
      ],
    );

    final migrated = ZennoDatabase(schema.newConnection());
    // Opening the current app database on a v1 schema runs the real
    // MigrationStrategy. Drift's generated verifier helpers provide the v1
    // starting point; the explicit assertions below cover the app-specific
    // data-preservation contract.
    await migrated.select(migrated.focusSessions).get();

    final session = await (migrated.select(
      migrated.focusSessions,
    )..where((s) => s.id.equals('session-v1'))).getSingle();
    final focusColumns = await migrated
        .customSelect('PRAGMA table_info(focus_sessions)')
        .get();
    final columnNames = focusColumns.map((row) => row.read<String>('name'));

    expect(session.goalText, 'Read chapter 4');
    expect(session.actualFocusSecs, 120);
    expect(columnNames, contains('runtime_status'));
    expect(columnNames, contains('runtime_phase'));
    expect(columnNames, contains('runtime_phase_started_at'));
    expect(columnNames, contains('runtime_carried_phase_secs'));
    expect(columnNames, contains('runtime_phase_target_secs'));
    expect(columnNames, contains('runtime_banked_focus_secs'));
    expect(session.runtimeCarriedPhaseSecs, 0);
    expect(session.runtimeBankedFocusSecs, 0);
    expect(session.runtimeStatus, null);
    expect(session.runtimePhase, null);

    await migrated.close();
    schema.close();
  });
}
