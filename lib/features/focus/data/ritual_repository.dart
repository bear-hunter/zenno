import 'package:drift/drift.dart';
import 'package:zenno/core/database/database.dart';
import 'package:zenno/core/util/id.dart';

/// Drift-backed access to the pre-study ritual checklist and the focus-related
/// `app_settings` defaults.
///
/// The app seeds exactly one default `ritual_checklists` row; this repository
/// resolves it lazily and operates on its items. Reads are reactive
/// [Stream]s (Drift `.watch()`); writes are one-shot [Future]s. No Drift type
/// escapes upward except the generated row classes, which the Focus feature
/// treats as its models.
class RitualRepository {
  /// Creates a repository over [_db].
  RitualRepository(this._db);

  final ZennoDatabase _db;

  /// Memoised id of the default checklist — resolved once, then reused.
  String? _defaultChecklistId;

  /// Resolves (and caches) the id of the seeded default ritual checklist.
  ///
  /// Prefers the row flagged `is_default`; falls back to the first checklist
  /// if, for any reason, no row is flagged.
  Future<String> _resolveDefaultChecklistId() async {
    final cached = _defaultChecklistId;
    if (cached != null) return cached;

    final defaultRow =
        await (_db.select(_db.ritualChecklists)
              ..where((c) => c.isDefault.equals(true))
              ..limit(1))
            .getSingleOrNull();
    final row =
        defaultRow ??
        await (_db.select(_db.ritualChecklists)..limit(1)).getSingleOrNull();

    if (row == null) {
      throw StateError(
        'No ritual checklist found — the database seed should create one.',
      );
    }
    return _defaultChecklistId = row.id;
  }

  /// Watches the **active** items of the default checklist, ordered by
  /// `position`.
  ///
  /// Retired (inactive) items are excluded — they are kept only so historical
  /// session snapshots stay coherent. Emits a fresh list on every change.
  Stream<List<RitualChecklistItem>> watchActiveItems() async* {
    final checklistId = await _resolveDefaultChecklistId();
    yield* (_db.select(_db.ritualChecklistItems)
          ..where(
            (i) => i.checklistId.equals(checklistId) & i.isActive.equals(true),
          )
          ..orderBy([(i) => OrderingTerm.asc(i.position)]))
        .watch();
  }

  /// One-shot read of the active items of the default checklist, ordered by
  /// `position`. Used at session start to snapshot the ritual.
  Future<List<RitualChecklistItem>> activeItems() async {
    final checklistId = await _resolveDefaultChecklistId();
    return (_db.select(_db.ritualChecklistItems)
          ..where(
            (i) => i.checklistId.equals(checklistId) & i.isActive.equals(true),
          )
          ..orderBy([(i) => OrderingTerm.asc(i.position)]))
        .get();
  }

  /// Appends a new active item with [label] to the end of the default
  /// checklist.
  ///
  /// The new `position` is one greater than the current maximum, so the item
  /// sorts last; the first item starts at `0`.
  Future<void> addItem(String label) async {
    final checklistId = await _resolveDefaultChecklistId();
    final existing = await (_db.select(_db.ritualChecklistItems)
          ..where((i) => i.checklistId.equals(checklistId)))
        .get();
    final nextPosition = existing.isEmpty
        ? 0.0
        : existing
                  .map((i) => i.position)
                  .reduce((a, b) => a > b ? a : b) +
              1.0;

    await _db
        .into(_db.ritualChecklistItems)
        .insert(
          RitualChecklistItemsCompanion.insert(
            id: newId(),
            checklistId: checklistId,
            label: label,
            position: nextPosition,
          ),
        );
  }

  /// Renames the ritual item identified by [itemId] to [label].
  Future<void> editItem(String itemId, String label) async {
    await (_db.update(
      _db.ritualChecklistItems,
    )..where((i) => i.id.equals(itemId))).write(
      RitualChecklistItemsCompanion(label: Value(label)),
    );
  }

  /// Retires the ritual item identified by [itemId].
  ///
  /// The row is *kept* with `is_active = false` rather than deleted, so any
  /// `focus_session_ritual_checks` snapshot that references it stays valid.
  Future<void> retireItem(String itemId) async {
    await (_db.update(
      _db.ritualChecklistItems,
    )..where((i) => i.id.equals(itemId))).write(
      const RitualChecklistItemsCompanion(isActive: Value(false)),
    );
  }

  /// Reads the singleton `app_settings` row, which carries the Pomodoro,
  /// Flowmodoro and session-length defaults the Setup screen pre-fills.
  Future<AppSetting> settings() => _db.select(_db.appSettings).getSingle();

  /// Watches the singleton `app_settings` row.
  Stream<AppSetting> watchSettings() =>
      _db.select(_db.appSettings).watchSingle();
}
