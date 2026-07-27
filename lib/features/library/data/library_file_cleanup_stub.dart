Future<void> deleteOwnedLibraryFiles(Iterable<String> paths) async {}

Future<void> deleteOrphanedOwnedLibraryFiles(
  Set<String> referencedPaths, {
  Duration graceWindow = const Duration(minutes: 10),
}) async {}
