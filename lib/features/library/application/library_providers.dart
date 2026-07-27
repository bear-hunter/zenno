import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:zenno/core/database/database.dart';
import 'package:zenno/core/database/tables/settings_tables.dart';
import 'package:zenno/core/providers/database_provider.dart';
import 'package:zenno/features/library/data/library_repository.dart';
import 'package:zenno/features/settings/application/settings_providers.dart';

part 'library_providers.g.dart';

/// Provides the singleton [LibraryRepository], wired to the app database.
///
/// Kept alive deliberately: this repository owns orphaned-file housekeeping,
/// and an autoDispose rebuild would re-run that scan every time the library
/// screen is re-entered.
@Riverpod(keepAlive: true)
LibraryRepository libraryRepository(Ref ref) {
  return LibraryRepository(ref.watch(databaseProvider));
}

/// Runs orphaned-media housekeeping exactly once per app launch.
///
/// Deliberately not a provider side effect: file deletion must not be tied to
/// a provider's lifecycle, where it would re-run on every rebuild and could
/// race an in-flight import.
Future<void> runLibraryStartupCleanup(ProviderContainer container) async {
  try {
    await container.read(libraryRepositoryProvider).cleanupOrphanedFiles();
  } catch (error) {
    debugPrint('Library file cleanup failed: $error');
  }
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

/// Streams only the title for one canvas, used by editor chrome.
final canvasTitleProvider = StreamProvider.family<String?, String>((ref, id) {
  return ref.watch(libraryRepositoryProvider).watchCanvasTitle(id);
});

/// Streams one-level canvas folders for the library.
final canvasFolderListProvider = StreamProvider<List<CanvasFolder>>((ref) {
  return ref.watch(libraryRepositoryProvider).watchFolders();
});
