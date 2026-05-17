import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:zenno/core/providers/database_provider.dart';
import 'package:zenno/features/settings/data/settings_repository.dart';

part 'settings_providers.g.dart';

/// Provides the singleton [SettingsRepository], wired to the app database.
@riverpod
SettingsRepository settingsRepository(Ref ref) {
  return SettingsRepository(ref.watch(databaseProvider));
}

/// Streams the app settings, re-emitting whenever any setting is saved.
///
/// Safe as a codegen provider: [SettingsModel] is a hand-written class, so
/// riverpod_generator never sees Drift's generated row type in the signature.
@riverpod
Stream<SettingsModel> appSettings(Ref ref) {
  return ref.watch(settingsRepositoryProvider).watchSettings();
}
