import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:zenno/core/database/database.dart';
import 'package:zenno/core/providers/database_provider.dart';
import 'package:zenno/features/library/data/library_repository.dart';

part 'library_providers.g.dart';

/// Provides the singleton [LibraryRepository], wired to the app database.
@riverpod
LibraryRepository libraryRepository(Ref ref) {
  return LibraryRepository(ref.watch(databaseProvider));
}

/// Holds the current [LibrarySort] for the library grid.
///
/// In-memory for now; a later phase persists the choice to
/// `app_settings.library_sort`. Defaults to [LibrarySort.recent].
@riverpod
class LibrarySortNotifier extends _$LibrarySortNotifier {
  @override
  LibrarySort build() => LibrarySort.recent;

  /// Switches the grid to [sort].
  void setSort(LibrarySort sort) => state = sort;
}

/// Streams the non-archived canvases, re-querying whenever the active
/// [LibrarySort] changes.
///
/// Plain (non-codegen) provider — riverpod_generator cannot resolve Drift's
/// generated row class `Canvase` inside a `@riverpod` signature.
final canvasListProvider = StreamProvider<List<Canvase>>((ref) {
  final sort = ref.watch(librarySortProvider);
  return ref.watch(libraryRepositoryProvider).watchCanvases(sort);
});
