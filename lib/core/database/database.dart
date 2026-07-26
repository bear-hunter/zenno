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
    CanvasLayers,
    CanvasBookmarks,
    CanvasFolders,
    CanvasElements,
    InkStrokes,
    PdfDocuments,
    Images,
    CanvasLinks,
    CanvasTexts,
    CanvasShapes,
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
  int get schemaVersion => 14;

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
        await m.createIndex(idxCardCanvasAttachmentsCardPosition);
        await m.createIndex(idxCardCanvasAttachmentsCanvasId);
      }
      if (from < 4) {
        await m.createTable(canvasTexts);
      }
      if (from < 5) {
        await m.addColumn(appSettings, appSettings.accentColor);
        await m.addColumn(appSettings, appSettings.backgroundColor);
        await m.addColumn(canvases, canvases.rotationLocked);
      }
      if (from < 6) {
        await m.addColumn(appSettings, appSettings.inkPaletteJson);
        // SQLite validates this boolean CHECK against existing rows. Add it
        // before the other defaulted canvas columns; adding it last can fail
        // on non-empty v5 databases with a spurious NOT NULL violation.
        await m.addColumn(canvases, canvases.pressureEnabled);
        await m.addColumn(canvases, canvases.canvasBackgroundColor);
        await m.addColumn(canvases, canvases.gridColor);
        await m.addColumn(canvases, canvases.gridSpacing);
        await m.addColumn(canvases, canvases.gridOpacity);
        await m.addColumn(canvases, canvases.graphMajorInterval);
        await m.addColumn(canvases, canvases.activePenColor);
        await m.addColumn(canvases, canvases.activePenWidth);
        await m.addColumn(canvases, canvases.activePenTool);
        await m.createTable(canvasShapes);
      }
      if (from < 7) {
        await m.addColumn(appSettings, appSettings.stylusMappingJson);
        await m.addColumn(appSettings, appSettings.penProfileJson);
      }
      if (from >= 6 && from < 7) {
        await m.addColumn(canvasShapes, canvasShapes.arrowBodyKind);
        await m.addColumn(canvasShapes, canvasShapes.arrowStartHead);
        await m.addColumn(canvasShapes, canvasShapes.arrowEndHead);
        await m.addColumn(canvasShapes, canvasShapes.arrowHeadScale);
        await m.addColumn(canvasShapes, canvasShapes.controlPointsJson);
        await m.addColumn(canvasShapes, canvasShapes.arrowLegacy);
      }
      if (from < 8) {
        await m.createTable(canvasLayers);
        await m.createIndex(idxCanvasLayersCanvasId);
        await m.createIndex(idxCanvasLayersCanvasIdPosition);
        await m.addColumn(canvasElements, canvasElements.layerId);
        await customStatement('''
          INSERT OR IGNORE INTO canvas_layers (
            id, canvas_id, name, position, visible, locked, opacity,
            blend_mode, kind, created_at, updated_at
          )
          SELECT id || ':content', id, 'Notes', 0, 1, 0, 1.0, 'srcOver', 0,
            created_at, updated_at
          FROM canvases
          ''');
        await customStatement('''
          UPDATE canvas_elements
          SET layer_id = canvas_id || ':content'
          WHERE layer_id IS NULL
          ''');
      }
      if (from < 9) {
        await m.addColumn(canvases, canvases.activePenWidthMode);
      }
      if (from < 10) {
        await m.createTable(canvasBookmarks);
        await m.createIndex(idxCanvasBookmarksCanvasPosition);
      }
      if (from < 12) {
        await m.addColumn(canvases, canvases.toolWheelJson);
      }
      if (from < 13) {
        await m.addColumn(appSettings, appSettings.toolWheelPositionJson);
      }
      if (from < 14) {
        await m.addColumn(canvases, canvases.paperTexture);
        await m.addColumn(canvases, canvases.paperTextureOpacity);
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
