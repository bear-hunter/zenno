import 'dart:convert';
import 'dart:ui' show Offset;

import 'package:drift/drift.dart';

import 'package:zenno/canvas/input/pen_profile.dart';
import 'package:zenno/canvas/input/stylus_button_mapping.dart';
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
    required this.accentColor,
    required this.backgroundColor,
    required this.inkPalette,
    required this.stylusButtonMapping,
    required this.penProfile,
    required this.pomodoroWork,
    required this.pomodoroBreak,
    required this.flowBreakRatio,
    required this.sessionLength,
    required this.keepScreenOnInFocus,
    required this.librarySort,
    this.toolWheelPosition,
  });

  /// App-wide theme-mode preference (system / light / dark).
  final ThemeModeSetting themeMode;

  /// App-wide primary/accent colour.
  final int accentColor;

  /// App-wide scaffold/background colour.
  final int backgroundColor;

  /// Global editable ink palette used by canvas toolbars.
  final List<int> inkPalette;

  /// Global stylus-button behavior for canvas input.
  final StylusButtonMapping stylusButtonMapping;

  /// Global capture profile for new pen strokes.
  final PenProfile penProfile;

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

  /// Global normalized position of the canvas tool-wheel cluster.
  ///
  /// `null` keeps the toolbar's built-in default position. Non-null axes are
  /// always normalized to the inclusive range from zero to one.
  final Offset? toolWheelPosition;

  /// Returns a copy with the given fields replaced.
  SettingsModel copyWith({
    ThemeModeSetting? themeMode,
    int? accentColor,
    int? backgroundColor,
    List<int>? inkPalette,
    StylusButtonMapping? stylusButtonMapping,
    PenProfile? penProfile,
    Duration? pomodoroWork,
    Duration? pomodoroBreak,
    double? flowBreakRatio,
    Duration? sessionLength,
    bool? keepScreenOnInFocus,
    LibrarySort? librarySort,
    Offset? toolWheelPosition,
  }) {
    return SettingsModel(
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      inkPalette: inkPalette ?? this.inkPalette,
      stylusButtonMapping: stylusButtonMapping ?? this.stylusButtonMapping,
      penProfile: penProfile ?? this.penProfile,
      pomodoroWork: pomodoroWork ?? this.pomodoroWork,
      pomodoroBreak: pomodoroBreak ?? this.pomodoroBreak,
      flowBreakRatio: flowBreakRatio ?? this.flowBreakRatio,
      sessionLength: sessionLength ?? this.sessionLength,
      keepScreenOnInFocus: keepScreenOnInFocus ?? this.keepScreenOnInFocus,
      librarySort: librarySort ?? this.librarySort,
      toolWheelPosition: toolWheelPosition ?? this.toolWheelPosition,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SettingsModel &&
            other.themeMode == themeMode &&
            other.accentColor == accentColor &&
            other.backgroundColor == backgroundColor &&
            _settingsListEquals(other.inkPalette, inkPalette) &&
            other.stylusButtonMapping == stylusButtonMapping &&
            other.penProfile == penProfile &&
            other.pomodoroWork == pomodoroWork &&
            other.pomodoroBreak == pomodoroBreak &&
            other.flowBreakRatio == flowBreakRatio &&
            other.sessionLength == sessionLength &&
            other.keepScreenOnInFocus == keepScreenOnInFocus &&
            other.librarySort == librarySort &&
            other.toolWheelPosition == toolWheelPosition;
  }

  @override
  int get hashCode => Object.hash(
    themeMode,
    accentColor,
    backgroundColor,
    Object.hashAll(inkPalette),
    stylusButtonMapping,
    penProfile,
    pomodoroWork,
    pomodoroBreak,
    flowBreakRatio,
    sessionLength,
    keepScreenOnInFocus,
    librarySort,
    toolWheelPosition,
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
        accentColor: Value(model.accentColor),
        backgroundColor: Value(model.backgroundColor),
        inkPaletteJson: Value(jsonEncode(model.inkPalette)),
        stylusMappingJson: Value(model.stylusButtonMapping.encode()),
        penProfileJson: Value(model.penProfile.encode()),
        toolWheelPositionJson: Value(
          _encodeToolWheelPosition(model.toolWheelPosition),
        ),
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

  /// Updates the app-wide primary/accent colour.
  Future<void> setAccentColor(int color) {
    return _writeCompanion(AppSettingsCompanion(accentColor: Value(color)));
  }

  /// Updates the app-wide scaffold/background colour.
  Future<void> setBackgroundColor(int color) {
    return _writeCompanion(AppSettingsCompanion(backgroundColor: Value(color)));
  }

  /// Replaces the global editable ink palette.
  Future<void> setInkPalette(List<int> colors) {
    final normalized = _normalizePalette(colors);
    return _writeCompanion(
      AppSettingsCompanion(inkPaletteJson: Value(jsonEncode(normalized))),
    );
  }

  /// Updates the global stylus-button mapping.
  Future<void> setStylusButtonMapping(StylusButtonMapping mapping) {
    return _writeCompanion(
      AppSettingsCompanion(stylusMappingJson: Value(mapping.encode())),
    );
  }

  /// Updates the global pen capture profile.
  Future<void> setPenProfile(PenProfile profile) {
    return _writeCompanion(
      AppSettingsCompanion(penProfileJson: Value(profile.encode())),
    );
  }

  /// Updates the app-wide normalized canvas tool-wheel position.
  Future<void> setToolWheelPosition(Offset position) {
    return _writeCompanion(
      AppSettingsCompanion(
        toolWheelPositionJson: Value(_encodeToolWheelPosition(position)),
      ),
    );
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
      accentColor: row.accentColor,
      backgroundColor: row.backgroundColor,
      inkPalette: _decodePalette(row.inkPaletteJson),
      stylusButtonMapping: StylusButtonMapping.fromJsonString(
        row.stylusMappingJson,
      ),
      penProfile: PenProfile.fromJsonString(row.penProfileJson),
      toolWheelPosition: _decodeToolWheelPosition(row.toolWheelPositionJson),
      pomodoroWork: Duration(seconds: row.defaultPomodoroWorkSecs),
      pomodoroBreak: Duration(seconds: row.defaultPomodoroBreakSecs),
      flowBreakRatio: row.defaultFlowBreakRatio,
      sessionLength: Duration(seconds: row.defaultSessionLengthSecs),
      keepScreenOnInFocus: row.keepScreenOnInFocus,
      librarySort: row.librarySort,
    );
  }

  static List<int> _decodePalette(String json) {
    try {
      final value = jsonDecode(json);
      if (value is List) {
        return _normalizePalette(value.whereType<num>().map((n) => n.toInt()));
      }
    } catch (_) {
      // Fall through to defaults.
    }
    return _normalizePalette(const <int>[
      0xFFFF4F91,
      0xFFFFC928,
      0xFF36D400,
      0xFF1E9BFF,
      0xFFFFFFFF,
      0xFF111820,
    ]);
  }

  static String _encodeToolWheelPosition(Offset? position) {
    if (position == null) {
      return '{}';
    }
    return jsonEncode({
      'x': _normalizePositionAxis(position.dx),
      'y': _normalizePositionAxis(position.dy),
    });
  }

  static Offset? _decodeToolWheelPosition(String json) {
    try {
      final value = jsonDecode(json);
      if (value is Map<String, dynamic>) {
        final x = value['x'];
        final y = value['y'];
        if (x is num && y is num) {
          final dx = x.toDouble();
          final dy = y.toDouble();
          if (dx.isFinite && dy.isFinite) {
            return Offset(
              _normalizePositionAxis(dx),
              _normalizePositionAxis(dy),
            );
          }
        }
      }
    } catch (_) {
      // Fall through to the toolbar's default position.
    }
    return null;
  }

  static double _normalizePositionAxis(double value) {
    if (!value.isFinite) {
      return 0;
    }
    return value.clamp(0.0, 1.0).toDouble();
  }

  static List<int> _normalizePalette(Iterable<int> colors) {
    final seen = <int>{};
    final list = <int>[];
    for (final color in colors) {
      final normalized = color & 0xFFFFFFFF;
      if (seen.add(normalized)) {
        list.add(normalized);
      }
    }
    return list.isEmpty
        ? const <int>[0xFFFFFFFF]
        : List<int>.unmodifiable(list);
  }
}

bool _settingsListEquals(List<int> a, List<int> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
