import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:zenno/core/database/database.dart';
import 'package:zenno/core/database/tables/board_tables.dart';

const _uuid = Uuid();

/// One prompt in a builtin reflection template.
({String key, String label, String hint, bool multiline}) _prompt(
  String key,
  String label,
) => (key: key, label: label, hint: '', multiline: true);

/// Encodes an ordered prompt list to the `schema_json` TEXT representation.
String _schemaJson(
  List<({String key, String label, String hint, bool multiline})> prompts,
) => jsonEncode([
  for (final p in prompts)
    {
      'key': p.key,
      'label': p.label,
      'hint': p.hint,
      'multiline': p.multiline,
    },
]);

/// Idempotently seeds builtin data: the settings singleton, the four builtin
/// reflection templates, one board per type with its starter columns, and a
/// default ritual checklist.
///
/// Safe to call on every open — it returns immediately once
/// `app_settings.db_schema_seeded` is `true`.
Future<void> seedDatabase(ZennoDatabase db) async {
  final existingSettings = await db.select(db.appSettings).getSingleOrNull();
  if (existingSettings != null && existingSettings.dbSchemaSeeded) {
    return;
  }

  final now = DateTime.now().toUtc();

  await db.transaction(() async {
    // --- Settings singleton -------------------------------------------------
    // `id` defaults to 'singleton' DB-side; insert-or-replace keeps this row
    // unique even if a partial earlier seed left a stale row behind.
    await db
        .into(db.appSettings)
        .insert(
          const AppSettingsCompanion(),
          mode: InsertMode.insertOrReplace,
        );

    // --- Builtin reflection templates --------------------------------------
    await _seedTemplates(db, now);

    // --- Boards + columns ---------------------------------------------------
    await _seedBoard(
      db,
      now: now,
      type: BoardType.revision,
      name: 'Schedule Revision',
      columnNames: const [
        'Studying',
        '1 Day Retrieval',
        '1 Week Retrieval',
        '1 Month Retrieval',
      ],
    );
    await _seedBoard(
      db,
      now: now,
      type: BoardType.goalCycle,
      name: 'Goal Cycle',
      columnNames: const ['Todo', 'In Cycle', 'Monitoring', 'Out of Cycle'],
    );

    // --- Default ritual checklist ------------------------------------------
    await _seedRitualChecklist(db);

    // --- Mark the schema seeded --------------------------------------------
    await db
        .update(db.appSettings)
        .write(const AppSettingsCompanion(dbSchemaSeeded: Value(true)));
  });
}

Future<void> _seedTemplates(ZennoDatabase db, DateTime now) async {
  final templates = <ReflectionTemplatesCompanion>[
    ReflectionTemplatesCompanion.insert(
      id: 'builtin.kolb',
      name: 'Kolb',
      description: const Value('Experiential learning cycle'),
      isBuiltin: const Value(true),
      schemaJson: _schemaJson([
        _prompt('concrete_experience', 'Concrete Experience'),
        _prompt('reflective_observation', 'Reflective Observation'),
        _prompt('abstract_conceptualisation', 'Abstract Conceptualisation'),
        _prompt('active_experimentation', 'Active Experimentation'),
      ]),
      createdAt: now,
      position: 0,
    ),
    ReflectionTemplatesCompanion.insert(
      id: 'builtin.gibbs',
      name: 'Gibbs',
      description: const Value('Gibbs reflective cycle'),
      isBuiltin: const Value(true),
      schemaJson: _schemaJson([
        _prompt('description', 'Description'),
        _prompt('feelings', 'Feelings'),
        _prompt('evaluation', 'Evaluation'),
        _prompt('analysis', 'Analysis'),
        _prompt('conclusion', 'Conclusion'),
        _prompt('action_plan', 'Action Plan'),
      ]),
      createdAt: now,
      position: 1,
    ),
    ReflectionTemplatesCompanion.insert(
      id: 'builtin.era',
      name: 'ERA',
      description: const Value('Experience, Reflection, Action'),
      isBuiltin: const Value(true),
      schemaJson: _schemaJson([
        _prompt('experience', 'Experience'),
        _prompt('reflection', 'Reflection'),
        _prompt('action', 'Action'),
      ]),
      createdAt: now,
      position: 2,
    ),
    ReflectionTemplatesCompanion.insert(
      id: 'builtin.driscoll',
      name: 'Driscoll',
      description: const Value('Driscoll "What?" model'),
      isBuiltin: const Value(true),
      schemaJson: _schemaJson([
        _prompt('what', 'What?'),
        _prompt('so_what', 'So what?'),
        _prompt('now_what', 'Now what?'),
      ]),
      createdAt: now,
      position: 3,
    ),
  ];

  for (final template in templates) {
    // Fixed IDs make this insert idempotent across partial earlier seeds.
    await db
        .into(db.reflectionTemplates)
        .insert(template, mode: InsertMode.insertOrReplace);
  }
}

Future<void> _seedBoard(
  ZennoDatabase db, {
  required DateTime now,
  required BoardType type,
  required String name,
  required List<String> columnNames,
}) async {
  final boardId = _uuid.v7();
  await db
      .into(db.boards)
      .insert(
        BoardsCompanion.insert(
          id: boardId,
          boardType: type,
          name: name,
          createdAt: now,
        ),
      );

  for (var i = 0; i < columnNames.length; i++) {
    await db
        .into(db.boardColumns)
        .insert(
          BoardColumnsCompanion.insert(
            id: _uuid.v7(),
            boardId: boardId,
            name: columnNames[i],
            position: i.toDouble(),
          ),
        );
  }
}

Future<void> _seedRitualChecklist(ZennoDatabase db) async {
  final checklistId = _uuid.v7();
  await db
      .into(db.ritualChecklists)
      .insert(
        RitualChecklistsCompanion.insert(
          id: checklistId,
          name: 'Pre-study ritual',
          isDefault: const Value(true),
        ),
      );

  const items = [
    'Silence notifications',
    'Water within reach',
    'Clear the desk',
  ];
  for (var i = 0; i < items.length; i++) {
    await db
        .into(db.ritualChecklistItems)
        .insert(
          RitualChecklistItemsCompanion.insert(
            id: _uuid.v7(),
            checklistId: checklistId,
            label: items[i],
            position: i.toDouble(),
          ),
        );
  }
}
