import 'package:drift/drift.dart';
import 'package:zenno/core/database/tables/board_tables.dart';

/// Builtin and custom reflection frameworks. Builtins use fixed IDs
/// (e.g. `builtin.gibbs`), are not deletable, and forking creates a copy.
class ReflectionTemplates extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  BoolColumn get isBuiltin => boolean().withDefault(const Constant(false))();

  /// Ordered prompt list as JSON: `[{key, label, hint, multiline}]`.
  TextColumn get schemaJson => text()();
  DateTimeColumn get createdAt => dateTime()();

  /// Fractional ordering position.
  RealColumn get position => real()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A filled reflection on a goal card. Snapshots make an entry render
/// identically forever even if its template later changes.
@TableIndex(name: 'idx_reflection_entries_card_id', columns: {#cardId})
class ReflectionEntries extends Table {
  TextColumn get id => text()();
  TextColumn get cardId =>
      text().references(BoardCards, #id, onDelete: KeyAction.cascade)();

  /// Restrict deletion of a template while filled entries reference it.
  TextColumn get templateId => text().references(
    ReflectionTemplates,
    #id,
    onDelete: KeyAction.restrict,
  )();

  /// The template name as it read when this entry was created.
  TextColumn get templateNameSnapshot => text()();

  /// The template schema JSON as it was when this entry was created.
  TextColumn get templateSchemaSnapshotJson => text()();

  /// Answers as JSON: `{promptKey: text}`.
  TextColumn get answersJson => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
