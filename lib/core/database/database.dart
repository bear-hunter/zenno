import 'package:drift/drift.dart';
import 'package:zenno/core/database/connection.dart';
import 'package:zenno/core/database/seed/seed_data.dart';
import 'package:zenno/core/database/tables/board_tables.dart';
import 'package:zenno/core/database/tables/canvas_tables.dart';
import 'package:zenno/core/database/tables/focus_tables.dart';
import 'package:zenno/core/database/tables/reflection_tables.dart';
import 'package:zenno/core/database/tables/settings_tables.dart';

part 'database.g.dart';

/// The single Drift database for Zenno. Holds every table across the Canvas,
/// Focus, Kanban, Reflection and Settings groups.
@DriftDatabase(
  tables: [
    // Canvas group.
    Canvases,
    CanvasFolders,
    CanvasElements,
    InkStrokes,
    PdfDocuments,
    Images,
    CanvasLinks,
    // Focus group.
    RitualChecklists,
    RitualChecklistItems,
    FocusSessions,
    FocusSessionRitualChecks,
    Distractions,
    // Kanban group.
    Boards,
    BoardColumns,
    BoardCards,
    RevisionCardDetails,
    GoalCardDetails,
    CardCanvasAttachments,
    // Reflection group.
    ReflectionTemplates,
    ReflectionEntries,
    // Settings.
    AppSettings,
  ],
)
class ZennoDatabase extends _$ZennoDatabase {
  /// Opens the database. The optional [executor] exists so tests can inject an
  /// in-memory executor; production code passes nothing and gets the on-device
  /// connection from [openZennoConnection].
  ZennoDatabase([QueryExecutor? executor])
    : super(executor ?? openZennoConnection());

  @override
  int get schemaVersion => 3;

  /// Persist `DateTime` columns as ISO-8601 TEXT (sortable, debuggable, and
  /// export-friendly) rather than Unix timestamp integers.
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(focusSessions, focusSessions.runtimeStatus);
        await m.addColumn(focusSessions, focusSessions.runtimePhase);
        await m.addColumn(focusSessions, focusSessions.runtimePhaseStartedAt);
        await m.addColumn(focusSessions, focusSessions.runtimeCarriedPhaseSecs);
        await m.addColumn(focusSessions, focusSessions.runtimePhaseTargetSecs);
        await m.addColumn(focusSessions, focusSessions.runtimeBankedFocusSecs);
      }
      if (from < 3) {
        await m.createTable(cardCanvasAttachments);
      }
    },
    beforeOpen: (details) async {
      // Drift does not enable foreign keys by default — cascade deletes
      // silently fail without this pragma.
      await customStatement('PRAGMA foreign_keys = ON');
      await seedDatabase(this);
    },
  );
}
