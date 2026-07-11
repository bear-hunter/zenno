import 'library_file_cleanup_stub.dart'
    if (dart.library.io) 'library_file_cleanup_io.dart'
    as platform;

/// Deletes unreferenced app-owned canvas media and thumbnail files.
Future<void> deleteOwnedLibraryFiles(Iterable<String> paths) {
  return platform.deleteOwnedLibraryFiles(paths);
}

/// Removes app-owned files that no persisted canvas row references anymore.
Future<void> deleteOrphanedOwnedLibraryFiles(Set<String> referencedPaths) {
  return platform.deleteOrphanedOwnedLibraryFiles(referencedPaths);
}
