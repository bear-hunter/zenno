import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<void> deleteOwnedLibraryFiles(Iterable<String> paths) async {
  try {
    final List<Directory> roots = await _ownedRoots();
    final List<String> allowedRoots = <String>[];
    for (final root in roots) {
      if (await root.exists()) {
        allowedRoots.add(await root.resolveSymbolicLinks());
      }
    }
    for (final path in paths.toSet()) {
      final File file = File(path);
      if (!await file.exists()) continue;
      final String resolved = await file.resolveSymbolicLinks();
      final bool owned = allowedRoots.any(
        (root) => resolved.startsWith('$root${Platform.pathSeparator}'),
      );
      if (owned) await file.delete();
    }
  } catch (_) {
    // The database deletion is already durable. File cleanup is best-effort
    // and must never turn a successful note deletion into a misleading error.
  }
}

Future<void> deleteOrphanedOwnedLibraryFiles(
  Set<String> referencedPaths,
) async {
  try {
    final List<Directory> roots = await _ownedRoots();
    final Set<String> resolvedReferences = <String>{};
    for (final path in referencedPaths) {
      final file = File(path);
      if (await file.exists()) {
        resolvedReferences.add(await file.resolveSymbolicLinks());
      }
    }
    for (final root in roots) {
      if (!await root.exists()) continue;
      await for (final entity in root.list(followLinks: false)) {
        if (entity is! File) continue;
        final String resolved = await entity.resolveSymbolicLinks();
        if (!resolvedReferences.contains(resolved)) await entity.delete();
      }
    }
  } catch (_) {
    // Best-effort startup housekeeping; persistence remains authoritative.
  }
}

Future<List<Directory>> _ownedRoots() async {
  final Directory documents = await getApplicationDocumentsDirectory();
  return <Directory>[
    Directory('${documents.path}${Platform.pathSeparator}canvas_media'),
    Directory('${documents.path}${Platform.pathSeparator}thumbnails'),
  ];
}
