import 'package:drift/drift.dart';

import 'package:zenno/core/database/database.dart';
import 'package:zenno/core/util/id.dart';
import 'package:zenno/features/goal_cycle/domain/reflection_template_schema.dart';

/// A reflection template as the Goal Cycle UI consumes it.
///
/// A hand-written, Drift-free view of a `reflection_templates` row with its
/// `schema_json` already parsed into a [ReflectionTemplateSchema]. Hand-written
/// (rather than the generated `ReflectionTemplate` row) so the providers that
/// stream it can stay `@riverpod` — a codegen provider may not name a Drift
/// row type in its signature.
class ReflectionTemplateView {
  /// Creates a template view.
  const ReflectionTemplateView({
    required this.id,
    required this.name,
    required this.description,
    required this.isBuiltin,
    required this.schema,
    required this.position,
  });

  /// Stable template id (builtins use fixed ids, e.g. `builtin.gibbs`).
  final String id;

  /// Display name of the framework.
  final String name;

  /// Optional one-line description.
  final String? description;

  /// Whether this is a builtin (view-only, not deletable) template.
  final bool isBuiltin;

  /// The parsed ordered prompt list.
  final ReflectionTemplateSchema schema;

  /// Fractional ordering position among sibling templates.
  final double position;
}

/// A filled reflection entry as the Goal Cycle UI consumes it.
///
/// A hand-written, Drift-free view of a `reflection_entries` row. The template
/// name and schema are read from the entry's *snapshot* columns, so an entry
/// renders identically forever even after its source template changes or is
/// duplicated. Hand-written for the same `@riverpod` reason as
/// [ReflectionTemplateView].
class ReflectionEntryView {
  /// Creates an entry view.
  const ReflectionEntryView({
    required this.id,
    required this.cardId,
    required this.templateId,
    required this.templateName,
    required this.schema,
    required this.answers,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Stable entry id.
  final String id;

  /// Id of the goal card this reflection belongs to.
  final String cardId;

  /// Id of the source template (`ON DELETE RESTRICT` — a template with
  /// entries cannot be deleted).
  final String templateId;

  /// The template name as it read when this entry was created (snapshot).
  final String templateName;

  /// The template schema as it was when this entry was created (snapshot).
  final ReflectionTemplateSchema schema;

  /// The user's answers, keyed by [ReflectionPrompt.key].
  final Map<String, String> answers;

  /// When the entry was first created.
  final DateTime createdAt;

  /// When the entry was last edited.
  final DateTime updatedAt;
}

/// The only code that touches Drift for reflection templates and entries.
///
/// Exposes reactive [Stream] reads and `Future` writes; Drift row types never
/// leak past this class — reads come out as [ReflectionTemplateView] /
/// [ReflectionEntryView].
///
/// Builtin templates (`is_builtin` true) are view-only: [updateTemplate] and
/// [deleteTemplate] reject them. To customise a builtin, [duplicateTemplate]
/// forks a non-builtin copy the user can then edit freely.
class ReflectionRepository {
  /// Creates a repository over the given [_db].
  ReflectionRepository(this._db);

  final ZennoDatabase _db;

  // ---------------------------------------------------------------------------
  // Template reads
  // ---------------------------------------------------------------------------

  /// Watches every reflection template, ordered by `position` then `name`.
  ///
  /// Re-emits on any insert/update/delete so the Templates page stays live.
  Stream<List<ReflectionTemplateView>> watchTemplates() {
    final query = _db.select(_db.reflectionTemplates)
      ..orderBy([
        (t) => OrderingTerm.asc(t.position),
        (t) => OrderingTerm.asc(t.name),
      ]);
    return query.watch().map(
      (rows) => [for (final row in rows) _toTemplateView(row)],
    );
  }

  /// Reads a single template by [id], or `null` if it no longer exists.
  Future<ReflectionTemplateView?> templateById(String id) async {
    final query = _db.select(_db.reflectionTemplates)
      ..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row == null ? null : _toTemplateView(row);
  }

  ReflectionTemplateView _toTemplateView(ReflectionTemplate row) {
    return ReflectionTemplateView(
      id: row.id,
      name: row.name,
      description: row.description,
      isBuiltin: row.isBuiltin,
      schema: ReflectionTemplateSchema.fromJsonString(row.schemaJson),
      position: row.position,
    );
  }

  // ---------------------------------------------------------------------------
  // Template writes
  // ---------------------------------------------------------------------------

  /// Creates a new custom (non-builtin) template. Returns the new id.
  ///
  /// It is appended after the current last template.
  Future<String> createTemplate({
    required String name,
    String? description,
    required ReflectionTemplateSchema schema,
  }) async {
    final id = newId();
    await _db
        .into(_db.reflectionTemplates)
        .insert(
          ReflectionTemplatesCompanion.insert(
            id: id,
            name: name,
            description: Value(description),
            // Custom templates are always editable/deletable.
            isBuiltin: const Value(false),
            schemaJson: schema.toJsonString(),
            createdAt: DateTime.now().toUtc(),
            position: await _nextTemplatePosition(),
          ),
        );
    return id;
  }

  /// Updates the [name], [description] and [schema] of a custom template.
  ///
  /// Builtin templates are view-only — calling this on one throws a
  /// [StateError]. Existing `reflection_entries` are unaffected: each carries
  /// its own snapshot of the template as it was when the entry was filled.
  Future<void> updateTemplate(
    String id, {
    required String name,
    String? description,
    required ReflectionTemplateSchema schema,
  }) async {
    await _assertNotBuiltin(id, 'edited');
    await (_db.update(
      _db.reflectionTemplates,
    )..where((t) => t.id.equals(id))).write(
      ReflectionTemplatesCompanion(
        name: Value(name),
        description: Value(description),
        schemaJson: Value(schema.toJsonString()),
      ),
    );
  }

  /// Deletes a custom template.
  ///
  /// Builtin templates are not deletable (throws a [StateError]). A template
  /// still referenced by any `reflection_entries` row is also not deletable —
  /// the FK is `ON DELETE RESTRICT`, so this surfaces a [StateError] before
  /// the database would reject it.
  Future<void> deleteTemplate(String id) async {
    await _assertNotBuiltin(id, 'deleted');

    // Count entries still referencing this template — the FK is
    // `ON DELETE RESTRICT`, so a delete would otherwise fail at the DB.
    final countExpr = _db.reflectionEntries.id.count();
    final usage = _db.selectOnly(_db.reflectionEntries)
      ..addColumns([countExpr])
      ..where(_db.reflectionEntries.templateId.equals(id));
    final inUse = (await usage.getSingle()).read(countExpr) ?? 0;
    if (inUse > 0) {
      throw StateError(
        'This template has $inUse saved reflection(s) and cannot be deleted.',
      );
    }

    await (_db.delete(
      _db.reflectionTemplates,
    )..where((t) => t.id.equals(id))).go();
  }

  /// Forks template [sourceId] into a new, editable, non-builtin copy.
  ///
  /// This is the "Duplicate & edit" path: a builtin can never be edited in
  /// place, so a user customises one by duplicating it first. Returns the new
  /// template's id. The copy's name gets a " (copy)" suffix unless an explicit
  /// [name] is supplied.
  Future<String> duplicateTemplate(String sourceId, {String? name}) async {
    final source = await templateById(sourceId);
    if (source == null) {
      throw StateError('Template "$sourceId" no longer exists.');
    }
    return createTemplate(
      name: name ?? '${source.name} (copy)',
      description: source.description,
      schema: source.schema,
    );
  }

  // ---------------------------------------------------------------------------
  // Entry reads
  // ---------------------------------------------------------------------------

  /// Watches every reflection entry on goal card [cardId], newest first.
  Stream<List<ReflectionEntryView>> watchEntriesForCard(String cardId) {
    final query = _db.select(_db.reflectionEntries)
      ..where((e) => e.cardId.equals(cardId))
      ..orderBy([(e) => OrderingTerm.desc(e.createdAt)]);
    return query.watch().map(
      (rows) => [for (final row in rows) _toEntryView(row)],
    );
  }

  ReflectionEntryView _toEntryView(ReflectionEntry row) {
    return ReflectionEntryView(
      id: row.id,
      cardId: row.cardId,
      templateId: row.templateId,
      templateName: row.templateNameSnapshot,
      schema: ReflectionTemplateSchema.fromJsonString(
        row.templateSchemaSnapshotJson,
      ),
      answers: reflectionAnswersFromJsonString(row.answersJson),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  // ---------------------------------------------------------------------------
  // Entry writes
  // ---------------------------------------------------------------------------

  /// Adds a reflection on card [cardId] filled from [template].
  ///
  /// The template's name and schema are *snapshotted* onto the entry, so the
  /// saved reflection renders identically forever even if the template is
  /// later edited, duplicated or (where allowed) deleted. Returns the new id.
  Future<String> addEntry({
    required String cardId,
    required ReflectionTemplateView template,
    required Map<String, String> answers,
  }) async {
    final id = newId();
    final now = DateTime.now().toUtc();
    await _db
        .into(_db.reflectionEntries)
        .insert(
          ReflectionEntriesCompanion.insert(
            id: id,
            cardId: cardId,
            templateId: template.id,
            templateNameSnapshot: template.name,
            templateSchemaSnapshotJson: template.schema.toJsonString(),
            answersJson: reflectionAnswersToJsonString(answers),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  /// Updates the [answers] of an existing reflection entry.
  ///
  /// Only the answers and `updated_at` change — the snapshotted template name
  /// and schema are intentionally left frozen.
  Future<void> updateEntry(
    String entryId, {
    required Map<String, String> answers,
  }) async {
    await (_db.update(
      _db.reflectionEntries,
    )..where((e) => e.id.equals(entryId))).write(
      ReflectionEntriesCompanion(
        answersJson: Value(reflectionAnswersToJsonString(answers)),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  /// Deletes the reflection entry [entryId].
  Future<void> deleteEntry(String entryId) async {
    await (_db.delete(
      _db.reflectionEntries,
    )..where((e) => e.id.equals(entryId))).go();
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  /// Throws a [StateError] if template [id] is a builtin (which is view-only).
  ///
  /// [verb] reads into the message, e.g. "edited" / "deleted".
  Future<void> _assertNotBuiltin(String id, String verb) async {
    final query = _db.select(_db.reflectionTemplates)
      ..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row != null && row.isBuiltin) {
      throw StateError(
        'Builtin templates cannot be $verb. Duplicate it to make changes.',
      );
    }
  }

  /// Returns a `position` just past the current last template.
  Future<double> _nextTemplatePosition() async {
    final query = _db.select(_db.reflectionTemplates)
      ..orderBy([(t) => OrderingTerm.desc(t.position)])
      ..limit(1);
    final last = await query.getSingleOrNull();
    return (last?.position ?? -1) + 1;
  }
}
