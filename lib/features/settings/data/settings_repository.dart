import 'package:drift/drift.dart';

import 'package:zenno/core/database/database.dart';
import 'package:zenno/core/database/tables/settings_tables.dart';

/// Immutable, hand-written view of the editable app-settings columns.
///
/// Deliberately a plain Dart class rather than a Drift row or a `freezed`
/// model: riverpod_generator cannot resolve Drift's generated `AppSetting`
/// row class inside a `@riverpod` signature, so the repository maps that row
/// to this type and the codegen providers traffic in [SettingsModel] instead.
///
/// Only the user-facing, editable fields are mirrored here — the internal
/// `onboardingDone` / `dbSchemaSeeded` flags stay in the database.
class SettingsModel {
  /// Creates an immutable settings snapshot.
  const SettingsModel({
    required this.themeMode,
    required this.pomodoroWork,
    required this.pomodoroBreak,
    required this.flowBreakRatio,
    required this.sessionLength,
    required this.keepScreenOnInFocus,
    required this.librarySort,
  });

  /// App-wide theme-mode preference (system / light / dark).
  final ThemeModeSetting themeMode;

  /// Default Pomodoro work interval.
  final Duration pomodoroWork;

  /// Default Pomodoro break interval.
  final Duration pomodoroBreak;

  /// Default Flowmodoro break ratio — break length as a fraction of the
  /// preceding focus stretch.
  final double flowBreakRatio;

  /// Default total planned session length.
  final Duration sessionLength;

  /// Whether the screen is kept awake during a Focus session.
  final bool keepScreenOnInFocus;

  /// Default sort order for the canvas library.
  final LibrarySort librarySort;

  /// Returns a copy with the given fields replaced.
  SettingsModel copyWith({
    ThemeModeSetting? themeMode,
    Duration? pomodoroWork,
    Duration? pomodoroBreak,
    double? flowBreakRatio,
    Duration? sessionLength,
    bool? keepScreenOnInFocus,
    LibrarySort? librarySort,
  }) {
    return SettingsModel(
      themeMode: themeMode ?? this.themeMode,
      pomodoroWork: pomodoroWork ?? this.pomodoroWork,
      pomodoroBreak: pomodoroBreak ?? this.pomodoroBreak,
      flowBreakRatio: flowBreakRatio ?? this.flowBreakRatio,
      sessionLength: sessionLength ?? this.sessionLength,
      keepScreenOnInFocus: keepScreenOnInFocus ?? this.keepScreenOnInFocus,
      librarySort: librarySort ?? this.librarySort,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SettingsModel &&
            other.themeMode == themeMode &&
            other.pomodoroWork == pomodoroWork &&
            other.pomodoroBreak == pomodoroBreak &&
            other.flowBreakRatio == flowBreakRatio &&
            other.sessionLength == sessionLength &&
            other.keepScreenOnInFocus == keepScreenOnInFocus &&
            other.librarySort == librarySort;
  }

  @override
  int get hashCode => Object.hash(
    themeMode,
    pomodoroWork,
    pomodoroBreak,
    flowBreakRatio,
    sessionLength,
    keepScreenOnInFocus,
    librarySort,
  );
}

/// Data layer for app settings.
///
/// The only code in the feature that touches Drift. The settings table is a
/// typed singleton row (`id == 'singleton'`), so every read targets that one
/// row and every write updates it. Reads are exposed as a reactive `Stream`
/// of the hand-written [SettingsModel]; writes return `Future<void>`.
class SettingsRepository {
  /// Creates a repository backed by [db].
  const SettingsRepository(this._db);

  final ZennoDatabase _db;

  /// Watches the singleton settings row, mapped to a [SettingsModel].
  ///
  /// Emits a fresh model whenever the row changes, so any screen listening
  /// updates automatically after a setting is saved.
  Stream<SettingsModel> watchSettings() {
    return _db.select(_db.appSettings).watchSingle().map(_toModel);
  }

  /// Reads the current settings once.
  Future<SettingsModel> readSettings() {
    return _db.select(_db.appSettings).getSingle().then(_toModel);
  }

  /// Persists [model] in full, overwriting every editable column of the
  /// singleton row.
  Future<void> save(SettingsModel model) {
    return _writeCompanion(
      AppSettingsCompanion(
        themeMode: Value(model.themeMode),
        defaultPomodoroWorkSecs: Value(model.pomodoroWork.inSeconds),
        defaultPomodoroBreakSecs: Value(model.pomodoroBreak.inSeconds),
        defaultFlowBreakRatio: Value(model.flowBreakRatio),
        defaultSessionLengthSecs: Value(model.sessionLength.inSeconds),
        keepScreenOnInFocus: Value(model.keepScreenOnInFocus),
        librarySort: Value(model.librarySort),
      ),
    );
  }

  /// Updates the theme-mode preference.
  Future<void> setThemeMode(ThemeModeSetting mode) {
    return _writeCompanion(AppSettingsCompanion(themeMode: Value(mode)));
  }

  /// Updates the default Pomodoro work interval.
  Future<void> setPomodoroWork(Duration value) {
    return _writeCompanion(
      AppSettingsCompanion(defaultPomodoroWorkSecs: Value(value.inSeconds)),
    );
  }

  /// Updates the default Pomodoro break interval.
  Future<void> setPomodoroBreak(Duration value) {
    return _writeCompanion(
      AppSettingsCompanion(defaultPomodoroBreakSecs: Value(value.inSeconds)),
    );
  }

  /// Updates the default Flowmodoro break ratio.
  Future<void> setFlowBreakRatio(double value) {
    return _writeCompanion(
      AppSettingsCompanion(defaultFlowBreakRatio: Value(value)),
    );
  }

  /// Updates the default planned session length.
  Future<void> setSessionLength(Duration value) {
    return _writeCompanion(
      AppSettingsCompanion(defaultSessionLengthSecs: Value(value.inSeconds)),
    );
  }

  /// Updates the keep-screen-on-during-Focus preference.
  Future<void> setKeepScreenOnInFocus({required bool value}) {
    return _writeCompanion(
      AppSettingsCompanion(keepScreenOnInFocus: Value(value)),
    );
  }

  /// Updates the default canvas-library sort order.
  Future<void> setLibrarySort(LibrarySort sort) {
    return _writeCompanion(AppSettingsCompanion(librarySort: Value(sort)));
  }

  /// Applies [companion] to the singleton settings row.
  Future<void> _writeCompanion(AppSettingsCompanion companion) {
    return (_db.update(
      _db.appSettings,
    )..where((s) => s.id.equals('singleton'))).write(companion);
  }

  /// Maps a Drift [AppSetting] row to the hand-written [SettingsModel].
  static SettingsModel _toModel(AppSetting row) {
    return SettingsModel(
      themeMode: row.themeMode,
      pomodoroWork: Duration(seconds: row.defaultPomodoroWorkSecs),
      pomodoroBreak: Duration(seconds: row.defaultPomodoroBreakSecs),
      flowBreakRatio: row.defaultFlowBreakRatio,
      sessionLength: Duration(seconds: row.defaultSessionLengthSecs),
      keepScreenOnInFocus: row.keepScreenOnInFocus,
      librarySort: row.librarySort,
    );
  }
}
