import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zenno/config/router/app_router.dart';
import 'package:zenno/config/theme/app_theme.dart';
import 'package:zenno/core/database/tables/settings_tables.dart';
import 'package:zenno/features/settings/application/settings_providers.dart';

/// Root widget of the Zenno application.
///
/// Wires the Material 3 dark/light themes and the [appRouter]. The active
/// [ThemeMode] is driven by the user's saved preference (`app_settings`):
/// the Settings screen writes it, this widget watches it and rebuilds, so the
/// whole app re-themes live. While settings are still loading — or if the
/// read fails — Zenno falls back to its dark-first default.
class ZennoApp extends ConsumerWidget {
  const ZennoApp({super.key});

  /// Maps the persisted [ThemeModeSetting] to Flutter's [ThemeMode].
  static ThemeMode _toThemeMode(ThemeModeSetting setting) =>
      switch (setting) {
        ThemeModeSetting.system => ThemeMode.system,
        ThemeModeSetting.light => ThemeMode.light,
        ThemeModeSetting.dark => ThemeMode.dark,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fall back to the dark-first default until the setting resolves (and on
    // any error) — `value` is null in both the loading and error states.
    final themeMode = ref
            .watch(appSettingsProvider)
            .value
            ?.themeMode
            .let(_toThemeMode) ??
        ThemeMode.dark;

    return MaterialApp.router(
      title: 'Zenno',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Small functional helper: applies [transform] to a non-null receiver.
extension _Let<T> on T {
  R let<R>(R Function(T value) transform) => transform(this);
}
