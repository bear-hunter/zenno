import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
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
    expect(settings.pomodoroWork, const Duration(seconds: 1500));
    expect(settings.pomodoroBreak, const Duration(seconds: 300));
    expect(settings.flowBreakRatio, closeTo(0.2, 1e-9));
    expect(settings.sessionLength, const Duration(seconds: 3000));
    expect(settings.keepScreenOnInFocus, isTrue);
    expect(settings.librarySort, LibrarySort.recent);
  });

  test('per-field update persists and re-reads', () async {
    await repo.setThemeMode(ThemeModeSetting.light);
    await repo.setPomodoroWork(const Duration(minutes: 30));
    await repo.setKeepScreenOnInFocus(value: false);
    await repo.setLibrarySort(LibrarySort.title);

    final updated = await repo.readSettings();

    expect(updated.themeMode, ThemeModeSetting.light);
    expect(updated.pomodoroWork, const Duration(minutes: 30));
    expect(updated.keepScreenOnInFocus, isFalse);
    expect(updated.librarySort, LibrarySort.title);
    // Untouched fields keep their defaults.
    expect(updated.pomodoroBreak, const Duration(seconds: 300));
  });

  test('save() round-trips a full SettingsModel', () async {
    const model = SettingsModel(
      themeMode: ThemeModeSetting.dark,
      pomodoroWork: Duration(minutes: 45),
      pomodoroBreak: Duration(minutes: 10),
      flowBreakRatio: 0.35,
      sessionLength: Duration(minutes: 120),
      keepScreenOnInFocus: false,
      librarySort: LibrarySort.created,
    );

    await repo.save(model);

    expect(await repo.readSettings(), model);
  });

  test('watchSettings emits the latest value after a write', () async {
    // Prime the stream so `beforeOpen` runs the seed, then update.
    await repo.readSettings();
    await repo.setThemeMode(ThemeModeSetting.dark);

    final emitted = await repo.watchSettings().first;

    expect(emitted.themeMode, ThemeModeSetting.dark);
  });
}
