import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenno/canvas/model/canvas_element.dart';
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

  test('v2 migrates to v3 and adds card canvas attachments table', () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    addTearDown(() {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
    });
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema = await verifier.schemaAt(2);

    final migrated = ZennoDatabase(schema.newConnection());
    await migrated.select(migrated.cardCanvasAttachments).get();

    final tables = await migrated
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'card_canvas_attachments'",
        )
        .get();
    final columns = await migrated
        .customSelect('PRAGMA table_info(card_canvas_attachments)')
        .get();
    final columnNames = columns.map((row) => row.read<String>('name'));

    expect(tables, hasLength(1));
    expect(columnNames, containsAll(['card_id', 'canvas_id', 'label']));

    await migrated.close();
    schema.close();
  });

  test('v3 migrates to v4 and adds canvas text notes table', () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    addTearDown(() {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
    });
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema = await verifier.schemaAt(3);

    final migrated = ZennoDatabase(schema.newConnection());
    await migrated.select(migrated.canvasTexts).get();

    final tables = await migrated
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'canvas_texts'",
        )
        .get();
    final columns = await migrated
        .customSelect('PRAGMA table_info(canvas_texts)')
        .get();
    final columnNames = columns.map((row) => row.read<String>('name'));

    expect(tables, hasLength(1));
    expect(
      columnNames,
      containsAll(['element_id', 'note_text', 'color', 'font_size']),
    );

    await migrated.close();
    schema.close();
  });

  test(
    'v4 migrates to v5 and adds system colours plus rotation lock',
    () async {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      addTearDown(() {
        driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
      });
      final verifier = SchemaVerifier(GeneratedHelper());
      final schema = await verifier.schemaAt(4);

      final migrated = ZennoDatabase(schema.newConnection());
      await migrated.select(migrated.appSettings).get();

      final settingsColumns = await migrated
          .customSelect('PRAGMA table_info(app_settings)')
          .get();
      final canvasColumns = await migrated
          .customSelect('PRAGMA table_info(canvases)')
          .get();
      final settingNames = settingsColumns.map(
        (row) => row.read<String>('name'),
      );
      final canvasNames = canvasColumns.map((row) => row.read<String>('name'));
      final settings = await migrated.select(migrated.appSettings).getSingle();

      expect(settingNames, containsAll(['accent_color', 'background_color']));
      expect(canvasNames, contains('rotation_locked'));
      expect(settings.accentColor, 0xFFE8B84B);
      expect(settings.backgroundColor, 0xFF121212);

      await migrated.close();
      schema.close();
    },
  );

  test('v5 migrates to v6 and preserves existing canvases', () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    addTearDown(() {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
    });
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema = await verifier.schemaAt(5);
    schema.rawDatabase.execute(
      '''
        INSERT INTO canvases (id, title, created_at, updated_at)
        VALUES (?, ?, ?, ?)
        ''',
      [
        'canvas-v5',
        'Existing notes',
        DateTime.utc(2026, 5, 27).toIso8601String(),
        DateTime.utc(2026, 5, 27).toIso8601String(),
      ],
    );

    final migrated = ZennoDatabase(schema.newConnection());
    await migrated.select(migrated.canvases).get();

    final canvas = await migrated.select(migrated.canvases).getSingle();
    final shapeTables = await migrated
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'canvas_shapes'",
        )
        .get();
    expect(canvas.id, 'canvas-v5');
    expect(canvas.pressureEnabled, isTrue);
    expect(canvas.gridSpacing, 48);
    expect(shapeTables, hasLength(1));

    await migrated.close();
    schema.close();
  });

  test('older schemas create indexes for tables added by migrations', () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    addTearDown(() {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
    });
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema = await verifier.schemaAt(1);

    final migrated = ZennoDatabase(schema.newConnection());
    await migrated.select(migrated.canvasLayers).get();
    final rows = await migrated
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'index'")
        .get();
    final names = rows.map((row) => row.read<String>('name')).toSet();

    expect(
      names,
      containsAll({
        'idx_card_canvas_attachments_card_position',
        'idx_card_canvas_attachments_canvas_id',
        'idx_canvas_layers_canvas_id',
        'idx_canvas_layers_canvas_id_position',
      }),
    );

    await migrated.close();
    schema.close();
  });

  test('v6 migrates to v7 and preserves legacy arrow defaults', () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    addTearDown(() {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
    });
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema = await verifier.schemaAt(6);

    schema.rawDatabase.execute(
      '''
        INSERT INTO canvases (id, title, created_at, updated_at)
        VALUES (?, ?, ?, ?)
        ''',
      [
        'canvas-v6',
        'Legacy arrows',
        DateTime.utc(2026, 5, 28).toIso8601String(),
        DateTime.utc(2026, 5, 28).toIso8601String(),
      ],
    );
    schema.rawDatabase.execute(
      '''
        INSERT INTO canvas_elements (
          id, canvas_id, kind, x, y, width, height, z_index,
          created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
      [
        'arrow-v6',
        'canvas-v6',
        ElementKind.shape.index,
        0,
        0,
        100,
        100,
        0,
        DateTime.utc(2026, 5, 28).toIso8601String(),
        DateTime.utc(2026, 5, 28).toIso8601String(),
      ],
    );
    schema.rawDatabase.execute(
      '''
        INSERT INTO canvas_shapes (
          element_id, shape_kind, start_x, start_y, end_x, end_y,
          color, stroke_width
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''',
      ['arrow-v6', 3, 0, 0, 100, 100, 0xFFFFFFFF, 4],
    );

    final migrated = ZennoDatabase(schema.newConnection());
    await migrated.select(migrated.canvasShapes).get();

    final shape = await migrated.select(migrated.canvasShapes).getSingle();
    final settings = await migrated.select(migrated.appSettings).getSingle();

    expect(shape.arrowLegacy, isTrue);
    expect(shape.arrowEndHead, ArrowHeadStyle.filled.index);
    expect(shape.controlPointsJson, '[]');
    expect(settings.stylusMappingJson, '{}');
    expect(settings.penProfileJson, '{}');

    await migrated.close();
    schema.close();
  });

  test(
    'v7 migrates to v8 and assigns existing elements to default layers',
    () async {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      addTearDown(() {
        driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
      });
      final verifier = SchemaVerifier(GeneratedHelper());
      final schema = await verifier.schemaAt(7);

      schema.rawDatabase.execute(
        '''
        INSERT INTO canvases (id, title, created_at, updated_at)
        VALUES (?, ?, ?, ?)
        ''',
        [
          'canvas-v7',
          'Layer migration',
          DateTime.utc(2026, 5, 30).toIso8601String(),
          DateTime.utc(2026, 5, 30).toIso8601String(),
        ],
      );
      schema.rawDatabase.execute(
        '''
        INSERT INTO canvas_elements (
          id, canvas_id, kind, x, y, width, height, z_index,
          created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          'element-v7',
          'canvas-v7',
          ElementKind.image.index,
          0,
          0,
          100,
          100,
          0,
          DateTime.utc(2026, 5, 30).toIso8601String(),
          DateTime.utc(2026, 5, 30).toIso8601String(),
        ],
      );

      final migrated = ZennoDatabase(schema.newConnection());
      await migrated.select(migrated.canvasLayers).get();

      final layers = await migrated.select(migrated.canvasLayers).get();
      final element = await migrated
          .select(migrated.canvasElements)
          .getSingle();
      final elementColumns = await migrated
          .customSelect('PRAGMA table_info(canvas_elements)')
          .get();
      final elementColumnNames = elementColumns.map(
        (row) => row.read<String>('name'),
      );

      expect(layers, hasLength(1));
      expect(layers.single.id, 'canvas-v7:content');
      expect(layers.single.name, 'Notes');
      expect(layers.single.kind, CanvasLayerKind.content);
      expect(elementColumnNames, contains('layer_id'));
      expect(element.layerId, 'canvas-v7:content');

      await migrated.close();
      schema.close();
    },
  );

  test('v8 migrates to v9 and defaults pen width mode to Screen', () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    addTearDown(() {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
    });
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema = await verifier.schemaAt(8);

    schema.rawDatabase.execute(
      '''
        INSERT INTO canvases (id, title, created_at, updated_at)
        VALUES (?, ?, ?, ?)
        ''',
      [
        'canvas-v8',
        'Pen mode migration',
        DateTime.utc(2026, 6, 1).toIso8601String(),
        DateTime.utc(2026, 6, 1).toIso8601String(),
      ],
    );

    final migrated = ZennoDatabase(schema.newConnection());
    await migrated.select(migrated.canvases).get();

    final canvas = await migrated.select(migrated.canvases).getSingle();
    final canvasColumns = await migrated
        .customSelect('PRAGMA table_info(canvases)')
        .get();
    final columnNames = canvasColumns.map((row) => row.read<String>('name'));

    expect(columnNames, contains('active_pen_width_mode'));
    expect(canvas.activePenWidthMode, 0);

    await migrated.close();
    schema.close();
  });

  test('v9 migrates to v10 and creates persistent canvas bookmarks', () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    addTearDown(() {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
    });
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema = await verifier.schemaAt(9);

    final migrated = ZennoDatabase(schema.newConnection());
    await migrated.select(migrated.canvasBookmarks).get();
    final tables = await migrated
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'canvas_bookmarks'",
        )
        .get();
    final indexes = await migrated
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'index' AND name = 'idx_canvas_bookmarks_canvas_position'",
        )
        .get();

    expect(tables, hasLength(1));
    expect(indexes, hasLength(1));

    await migrated.close();
    schema.close();
  });

  for (var version = 1; version < 11; version++) {
    test('v$version migrates to the exact v11 schema', () async {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      addTearDown(() {
        driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
      });
      final verifier = SchemaVerifier(GeneratedHelper());
      final schema = await verifier.schemaAt(version);
      final migrated = ZennoDatabase(schema.newConnection());

      await verifier.migrateAndValidate(
        migrated,
        11,
        options: const ValidationOptions(validateDropped: true),
      );

      await migrated.close();
      schema.close();
    });
  }
}
