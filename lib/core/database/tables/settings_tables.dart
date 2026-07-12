import 'package:drift/drift.dart';

/// App-wide theme mode preference.
enum ThemeModeSetting { system, light, dark }

/// Sort order for the canvas library.
enum LibrarySort { recent, created, title }

/// Typed singleton settings row. Exactly one row exists, with
/// `id == 'singleton'`.
class AppSettings extends Table {
  /// Always the constant `'singleton'` — the only DB-side default in the
  /// schema, so the single settings row is trivial to upsert.
  TextColumn get id => text().withDefault(const Constant('singleton'))();

  IntColumn get themeMode =>
      intEnum<ThemeModeSetting>().withDefault(const Constant(0))();
  IntColumn get accentColor =>
      integer().withDefault(const Constant(0xFFE8B84B))();
  IntColumn get backgroundColor =>
      integer().withDefault(const Constant(0xFF121212))();
  TextColumn get inkPaletteJson => text().withDefault(
    const Constant(
      '[4294922129,4291316008,4281771008,4276755455,4294967295,4279318560]',
    ),
  )();
  TextColumn get stylusMappingJson =>
      text().withDefault(const Constant('{}'))();
  TextColumn get penProfileJson => text().withDefault(const Constant('{}'))();
  TextColumn get toolWheelPositionJson =>
      text().withDefault(const Constant('{}'))();

  IntColumn get defaultPomodoroWorkSecs =>
      integer().withDefault(const Constant(1500))();
  IntColumn get defaultPomodoroBreakSecs =>
      integer().withDefault(const Constant(300))();
  RealColumn get defaultFlowBreakRatio =>
      real().withDefault(const Constant(0.2))();
  IntColumn get defaultSessionLengthSecs =>
      integer().withDefault(const Constant(3000))();

  BoolColumn get keepScreenOnInFocus =>
      boolean().withDefault(const Constant(true))();
  IntColumn get librarySort =>
      intEnum<LibrarySort>().withDefault(const Constant(0))();
  BoolColumn get onboardingDone =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get dbSchemaSeeded =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
