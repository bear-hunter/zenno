import 'library_file_cleanup_stub.dart'
    if (dart.library.io) 'library_file_cleanup_io.dart'
    as platform;

/// Deletes unreferenced app-owned canvas media and thumbnail files.
Future<void> deleteOwnedLibraryFiles(Iterable<String> paths) {
  return platform.deleteOwnedLibraryFiles(paths);
}

/// Removes app-owned files that no persisted canvas row references anymore.
///
/// Files modified within [graceWindow] are skipped: an import writes its media
/// file before the element row referencing it exists, so a young unreferenced
/// file may simply be mid-import rather than orphaned.
Future<void> deleteOrphanedOwnedLibraryFiles(
  Set<String> referencedPaths, {
  Duration graceWindow = const Duration(minutes: 10),
}) {
  return platform.deleteOrphanedOwnedLibraryFiles(
    referencedPaths,
    graceWindow: graceWindow,
  );
}
