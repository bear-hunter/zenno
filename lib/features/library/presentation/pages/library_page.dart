import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:zenno/config/router/routes.dart';
import 'package:zenno/config/theme/app_spacing.dart';
import 'package:zenno/core/database/tables/settings_tables.dart';
import 'package:zenno/features/library/application/library_providers.dart';
import 'package:zenno/features/library/presentation/widgets/canvas_card.dart';
import 'package:zenno/features/settings/application/settings_providers.dart';

/// The canvas library — the app's home screen.
///
/// Shows every non-archived canvas in a responsive grid, lets the user create
/// a new canvas, and exposes the sort order. Reads are reactive, so a rename
/// or delete from a [CanvasCard] refreshes the grid automatically.
class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  /// Human-readable label for a [LibrarySort] menu entry.
  static String _sortLabel(LibrarySort sort) => switch (sort) {
    LibrarySort.recent => 'Last edited',
    LibrarySort.created => 'Date created',
    LibrarySort.title => 'Title',
  };

  /// Creates a canvas and opens it in the full-bleed editor.
  Future<void> _createCanvas(BuildContext context, WidgetRef ref) async {
    final id = await ref.read(libraryRepositoryProvider).createCanvas();
    if (context.mounted) {
      await context.push(Routes.canvasPath(id));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canvases = ref.watch(canvasListProvider);
    final activeSort = ref.watch(librarySortProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          PopupMenuButton<LibrarySort>(
            tooltip: 'Sort canvases',
            icon: const Icon(Icons.sort),
            initialValue: activeSort,
            onSelected: ref.read(settingsRepositoryProvider).setLibrarySort,
            itemBuilder: (context) => [
              for (final sort in LibrarySort.values)
                PopupMenuItem(value: sort, child: Text(_sortLabel(sort))),
            ],
          ),
        ],
      ),
      body: canvases.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _LibraryMessage(
          icon: Icons.error_outline,
          title: 'Could not load your canvases',
          subtitle: '$error',
        ),
        data: (items) {
          if (items.isEmpty) {
            return const _LibraryMessage(
              icon: Icons.draw_outlined,
              title: 'No canvases yet',
              subtitle: 'Tap "New canvas" to start your first one.',
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 260,
              mainAxisSpacing: AppSpacing.lg,
              crossAxisSpacing: AppSpacing.lg,
              childAspectRatio: 4 / 3,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) => CanvasCard(canvas: items[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createCanvas(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New canvas'),
      ),
    );
  }
}

/// A centered icon-and-text panel used for the library's empty and error
/// states.
class _LibraryMessage extends StatelessWidget {
  const _LibraryMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
