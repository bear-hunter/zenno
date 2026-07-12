import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenno/canvas/input/pen_profile.dart';
import 'package:zenno/canvas/input/stylus_button_mapping.dart';
import 'package:zenno/core/database/database.dart';
import 'package:zenno/core/database/tables/settings_tables.dart';
import 'package:zenno/features/settings/data/settings_repository.dart';

void main() {
  late ZennoDatabase db;
  late SettingsRepository repo;

  setUp(() {
    db = ZennoDatabase(NativeDatabase.memory());
    repo = SettingsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('reads the seeded singleton defaults', () async {
    final settings = await repo.readSettings();

    // Matches the schema defaults in settings_tables.dart.
    expect(settings.themeMode, ThemeModeSetting.system);
    expect(settings.accentColor, 0xFFE8B84B);
    expect(settings.backgroundColor, 0xFF121212);
    expect(settings.inkPalette, isNotEmpty);
    expect(
      settings.stylusButtonMapping,
      const StylusButtonMapping(
        hold: StylusButtonAction.temporaryEraser,
        tap: StylusButtonAction.togglePreviousTool,
        drag: StylusButtonAction.temporaryEraser,
        penLongPress: StylusButtonAction.temporaryLasso,
      ),
    );
    expect(settings.penProfile, const PenProfile());
    expect(settings.pomodoroWork, const Duration(seconds: 1500));
    expect(settings.pomodoroBreak, const Duration(seconds: 300));
    expect(settings.flowBreakRatio, closeTo(0.2, 1e-9));
    expect(settings.sessionLength, const Duration(seconds: 3000));
    expect(settings.keepScreenOnInFocus, isTrue);
    expect(settings.librarySort, LibrarySort.recent);
    expect(settings.toolWheelPosition, isNull);
  });

  test('per-field update persists and re-reads', () async {
    await repo.setThemeMode(ThemeModeSetting.light);
    await repo.setPomodoroWork(const Duration(minutes: 30));
    await repo.setKeepScreenOnInFocus(value: false);
    await repo.setLibrarySort(LibrarySort.title);
    await repo.setAccentColor(0xFF1E9BFF);
    await repo.setBackgroundColor(0xFF172331);
    await repo.setInkPalette(const <int>[0xFF112233, 0xFF445566]);
    await repo.setStylusButtonMapping(
      const StylusButtonMapping(
        hold: StylusButtonAction.temporaryPan,
        tap: StylusButtonAction.undo,
        drag: StylusButtonAction.temporaryLasso,
        penLongPress: StylusButtonAction.temporaryPan,
      ),
    );
    await repo.setPenProfile(
      const PenProfile(
        stabilizer: 0.4,
        smoothing: 0.2,
        pressureCurve: PressureCurveKind.firm,
      ),
    );
    await repo.setToolWheelPosition(const Offset(0.25, 0.75));

    final updated = await repo.readSettings();

    expect(updated.themeMode, ThemeModeSetting.light);
    expect(updated.pomodoroWork, const Duration(minutes: 30));
    expect(updated.keepScreenOnInFocus, isFalse);
    expect(updated.librarySort, LibrarySort.title);
    expect(updated.accentColor, 0xFF1E9BFF);
    expect(updated.backgroundColor, 0xFF172331);
    expect(updated.inkPalette, const <int>[0xFF112233, 0xFF445566]);
    expect(
      updated.stylusButtonMapping,
      const StylusButtonMapping(
        hold: StylusButtonAction.temporaryPan,
        tap: StylusButtonAction.undo,
        drag: StylusButtonAction.temporaryLasso,
        penLongPress: StylusButtonAction.temporaryPan,
      ),
    );
    expect(
      updated.penProfile,
      const PenProfile(
        stabilizer: 0.4,
        smoothing: 0.2,
        pressureCurve: PressureCurveKind.firm,
      ),
    );
    expect(updated.toolWheelPosition, const Offset(0.25, 0.75));
    // Untouched fields keep their defaults.
    expect(updated.pomodoroBreak, const Duration(seconds: 300));
  });

  test('save() round-trips a full SettingsModel', () async {
    const model = SettingsModel(
      themeMode: ThemeModeSetting.dark,
      accentColor: 0xFFFF4F91,
      backgroundColor: 0xFF172331,
      inkPalette: <int>[0xFFFF4F91, 0xFFFFFFFF],
      stylusButtonMapping: StylusButtonMapping(
        hold: StylusButtonAction.temporaryEraser,
        tap: StylusButtonAction.redo,
        drag: StylusButtonAction.arrow,
        penLongPress: StylusButtonAction.disabled,
      ),
      penProfile: PenProfile(
        stabilizer: 0.25,
        smoothing: 0.5,
        pressureCurve: PressureCurveKind.light,
      ),
      pomodoroWork: Duration(minutes: 45),
      pomodoroBreak: Duration(minutes: 10),
      flowBreakRatio: 0.35,
      sessionLength: Duration(minutes: 120),
      keepScreenOnInFocus: false,
      librarySort: LibrarySort.created,
      toolWheelPosition: Offset(0.4, 0.6),
    );

    await repo.save(model);

    expect(await repo.readSettings(), model);
  });

  test('tool-wheel position clamps axes before persisting', () async {
    await repo.setToolWheelPosition(const Offset(-0.5, 1.5));

    final updated = await repo.readSettings();

    expect(updated.toolWheelPosition, const Offset(0, 1));
  });

  test('stored tool-wheel position is clamped while decoding', () async {
    await repo.readSettings();
    await (db.update(
      db.appSettings,
    )..where((settings) => settings.id.equals('singleton'))).write(
      const AppSettingsCompanion(
        toolWheelPositionJson: Value('{"x":-4,"y":3}'),
      ),
    );

    final updated = await repo.readSettings();

    expect(updated.toolWheelPosition, const Offset(0, 1));
  });

  test('invalid tool-wheel position falls back to the UI default', () async {
    await repo.readSettings();
    await (db.update(
      db.appSettings,
    )..where((settings) => settings.id.equals('singleton'))).write(
      const AppSettingsCompanion(
        toolWheelPositionJson: Value('{"x":"invalid","y":0.5}'),
      ),
    );

    final updated = await repo.readSettings();

    expect(updated.toolWheelPosition, isNull);
  });

  test('watchSettings emits the latest value after a write', () async {
    // Prime the stream so `beforeOpen` runs the seed, then update.
    await repo.readSettings();
    await repo.setThemeMode(ThemeModeSetting.dark);

    final emitted = await repo.watchSettings().first;

    expect(emitted.themeMode, ThemeModeSetting.dark);
  });
}
