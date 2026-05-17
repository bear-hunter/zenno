import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:zenno/core/database/database.dart';
import 'package:zenno/core/database/tables/settings_tables.dart';
import 'package:zenno/core/providers/database_provider.dart';
import 'package:zenno/features/library/data/library_repository.dart';
import 'package:zenno/features/settings/application/settings_providers.dart';

part 'library_providers.g.dart';

/// Provides the singleton [LibraryRepository], wired to the app database.
@riverpod
LibraryRepository libraryRepository(Ref ref) {
  return LibraryRepository(ref.watch(databaseProvider));
}

/// Current persisted [LibrarySort] for the library grid.
final librarySortProvider = Provider<LibrarySort>((ref) {
  return ref.watch(appSettingsProvider).value?.librarySort ??
      LibrarySort.recent;
});

/// Streams the non-archived canvases, re-querying whenever the active
/// [LibrarySort] changes.
///
/// Plain (non-codegen) provider — riverpod_generator cannot resolve Drift's
/// generated row class `Canvase` inside a `@riverpod` signature.
final canvasListProvider = StreamProvider<List<Canvase>>((ref) {
  final sort = ref.watch(librarySortProvider);
  return ref.watch(libraryRepositoryProvider).watchCanvases(sort);
});
