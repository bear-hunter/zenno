import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zenno/canvas/canvas_editor_navigation.dart';
import 'package:zenno/config/theme/app_spacing.dart';
import 'package:zenno/core/database/database.dart';
import 'package:zenno/core/database/database_exceptions.dart';
import 'package:zenno/core/database/tables/settings_tables.dart';
import 'package:zenno/core/widgets/aurora.dart';
import 'package:zenno/features/library/application/library_providers.dart';
import 'package:zenno/features/library/presentation/widgets/canvas_card.dart';
import 'package:zenno/features/settings/application/settings_providers.dart';

/// The canvas library — the app's home screen.
///
/// Shows every non-archived canvas in a responsive grid, lets the user create
/// a new canvas, and exposes the sort order. Reads are reactive, so a rename
/// or delete from a [CanvasCard] refreshes the grid automatically.
class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  /// Stable key for a folder's expand/collapse control.
  static ValueKey<String> folderToggleKey(String? folderId) =>
      ValueKey('library-folder-toggle-${folderId ?? 'unfiled'}');

  /// Stable key for the header area that accepts dragged canvases.
  static ValueKey<String> folderDropTargetKey(String? folderId) =>
      ValueKey('library-folder-drop-${folderId ?? 'unfiled'}');

  /// Stable key for a folder's expanded grid or empty state.
  static ValueKey<String> folderContentsKey(String? folderId) =>
      ValueKey('library-folder-contents-${folderId ?? 'unfiled'}');

  /// Stable key for a draggable canvas card.
  static ValueKey<String> canvasDragKey(String canvasId) =>
      ValueKey('library-canvas-drag-$canvasId');

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  bool _creating = false;
  final TextEditingController _searchController = TextEditingController();
  final Set<String?> _collapsedFolderIds = <String?>{};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  void _toggleFolder(String? folderId) {
    setState(() {
      if (!_collapsedFolderIds.add(folderId)) {
        _collapsedFolderIds.remove(folderId);
      }
    });
  }

  /// Human-readable label for a [LibrarySort] menu entry.
  static String _sortLabel(LibrarySort sort) => switch (sort) {
    LibrarySort.recent => 'Last edited',
    LibrarySort.created => 'Date created',
    LibrarySort.title => 'Title',
  };

  /// Creates a canvas and opens it in the full-bleed editor.
  Future<void> _createCanvas(BuildContext context, WidgetRef ref) async {
    if (_creating) return;
    setState(() => _creating = true);
    try {
      final id = await ref.read(libraryRepositoryProvider).createCanvas();
      if (context.mounted) {
        await openCanvasEditor(context, id);
      }
    } catch (error) {
      debugPrint('Create canvas failed: $error');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not create canvas. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<String?> _promptFolderName(
    BuildContext context, {
    String title = 'New folder',
    String initialName = '',
  }) {
    final controller = TextEditingController(text: initialName);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(labelText: 'Folder name'),
          onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  Future<void> _createFolder(BuildContext context) async {
    final name = await _promptFolderName(context);
    if (!context.mounted || name == null || name.isEmpty) return;
    try {
      await ref.read(libraryRepositoryProvider).createFolder(name);
    } catch (error) {
      debugPrint('Create folder failed: $error');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not create folder.')),
        );
      }
    }
  }

  Future<void> _renameFolder(BuildContext context, CanvasFolder folder) async {
    final name = await _promptFolderName(
      context,
      title: 'Rename folder',
      initialName: folder.name,
    );
    if (!context.mounted ||
        name == null ||
        name.isEmpty ||
        name == folder.name) {
      return;
    }
    try {
      await ref.read(libraryRepositoryProvider).renameFolder(folder.id, name);
    } catch (error) {
      debugPrint('Rename folder failed: $error');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not rename folder.')),
        );
      }
    }
  }

  Future<void> _deleteFolder(BuildContext context, CanvasFolder folder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete folder?'),
        content: Text(
          '"${folder.name}" will be removed. Its canvases will move to Unfiled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!context.mounted || confirmed != true) return;
    try {
      await ref.read(libraryRepositoryProvider).deleteFolder(folder.id);
    } catch (error) {
      debugPrint('Delete folder failed: $error');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete folder.')),
        );
      }
    }
  }

  Future<void> _moveCanvasToFolder(
    Canvase canvas,
    String? targetFolderId,
  ) async {
    if (canvas.folderId == targetFolderId) return;
    try {
      await ref
          .read(libraryRepositoryProvider)
          .moveCanvasToFolder(canvas.id, targetFolderId);
      if (!mounted) return;
      setState(() => _collapsedFolderIds.remove(targetFolderId));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Canvas moved')));
    } catch (error) {
      debugPrint('Move canvas failed: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not move canvas. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canvases = ref.watch(canvasListProvider);
    final folders = ref.watch(canvasFolderListProvider);
    final activeSort = ref.watch(librarySortProvider);
    final query = _searchController.text.trim().toLowerCase();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          AuroraTopBar(
            eyebrow: 'Workspace',
            title: 'Library',
            subtitle:
                'Pick up a canvas where your thinking left off, or start a new one.',
            actions: [
              FilledButton.icon(
                onPressed: _creating ? null : () => _createCanvas(context, ref),
                icon: _creating
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: Text(_creating ? 'Creating...' : 'New canvas'),
              ),
            ],
          ),
          _LibraryToolbar(
            searchController: _searchController,
            activeSort: activeSort,
            onClearSearch: _searchController.clear,
            onSortSelected: (sort) =>
                ref.read(settingsRepositoryProvider).setLibrarySort(sort),
            onCreateFolder: () => _createFolder(context),
          ),
          Expanded(child: _buildLibraryBody(canvases, folders, query)),
        ],
      ),
    );
  }

  Widget _buildLibraryBody(
    AsyncValue<List<Canvase>> canvases,
    AsyncValue<List<CanvasFolder>> folders,
    String query,
  ) {
    final items = canvases.value;
    final folderItems = folders.value;
    if (items != null && folderItems != null) {
      return _LibraryFoldersView(
        canvases: _filterCanvases(items, folderItems, query),
        folders: _filterFolders(items, folderItems, query),
        isFiltering: query.isNotEmpty,
        collapsedFolderIds: _collapsedFolderIds,
        onToggleFolder: _toggleFolder,
        onMoveCanvas: _moveCanvasToFolder,
        onRenameFolder: (folder) => _renameFolder(context, folder),
        onDeleteFolder: (folder) => _deleteFolder(context, folder),
      );
    }

    final Object? loadError = switch ((canvases, folders)) {
      (AsyncError(:final error), _) => error,
      (_, AsyncError(:final error)) => error,
      _ => null,
    };
    if (loadError != null) {
      final alreadyOpen = isDatabaseAlreadyOpenError(loadError);
      return _LibraryMessage(
        icon: Icons.error_outline,
        title: alreadyOpen
            ? 'Zenno is open in another tab'
            : 'Could not load your canvases',
        subtitle: alreadyOpen
            ? 'Close the other tab, then reload this page.'
            : 'Please try again.',
        onRetry: alreadyOpen
            ? null
            : () {
                ref.invalidate(canvasListProvider);
                ref.invalidate(canvasFolderListProvider);
              },
      );
    }
    return const Center(child: CircularProgressIndicator());
  }

  List<Canvase> _filterCanvases(
    List<Canvase> canvases,
    List<CanvasFolder> folders,
    String query,
  ) {
    if (query.isEmpty) return canvases;
    final folderNames = {for (final folder in folders) folder.id: folder.name};
    return canvases
        .where((canvas) {
          final title = canvas.title.toLowerCase();
          final folder = folderNames[canvas.folderId]?.toLowerCase() ?? '';
          return title.contains(query) || folder.contains(query);
        })
        .toList(growable: false);
  }

  List<CanvasFolder> _filterFolders(
    List<Canvase> canvases,
    List<CanvasFolder> folders,
    String query,
  ) {
    if (query.isEmpty) return folders;
    final Set<String> folderIdsWithMatchingCanvases = <String>{
      for (final canvas in canvases)
        if (canvas.folderId != null &&
            canvas.title.toLowerCase().contains(query))
          canvas.folderId!,
    };
    return folders
        .where((folder) {
          final nameMatches = folder.name.toLowerCase().contains(query);
          final hasMatchingCanvas = folderIdsWithMatchingCanvases.contains(
            folder.id,
          );
          return nameMatches || hasMatchingCanvas;
        })
        .toList(growable: false);
  }
}

class _LibraryToolbar extends StatelessWidget {
  const _LibraryToolbar({
    required this.searchController,
    required this.activeSort,
    required this.onClearSearch,
    required this.onSortSelected,
    required this.onCreateFolder,
  });

  final TextEditingController searchController;
  final LibrarySort activeSort;
  final VoidCallback onClearSearch;
  final ValueChanged<LibrarySort> onSortSelected;
  final VoidCallback onCreateFolder;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final search = TextField(
      controller: searchController,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search canvases and folders',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: searchController.text.isEmpty
            ? null
            : IconButton(
                onPressed: onClearSearch,
                tooltip: 'Clear search',
                icon: const Icon(Icons.close),
              ),
      ),
    );
    final sort = PopupMenuButton<LibrarySort>(
      tooltip: 'Sort canvases',
      initialValue: activeSort,
      onSelected: onSortSelected,
      itemBuilder: (context) => [
        for (final value in LibrarySort.values)
          PopupMenuItem(
            value: value,
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: value == activeSort
                      ? Icon(Icons.check, size: 18, color: colors.primary)
                      : null,
                ),
                Text(_LibraryPageState._sortLabel(value)),
              ],
            ),
          ),
      ],
      child: _ToolbarControl(
        icon: Icons.swap_vert,
        label: _LibraryPageState._sortLabel(activeSort),
      ),
    );
    final folder = OutlinedButton.icon(
      onPressed: onCreateFolder,
      icon: const Icon(Icons.create_new_folder_outlined),
      label: const Text('New folder'),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xs,
        AppSpacing.xl,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 620) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                search,
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(child: sort),
                    const SizedBox(width: AppSpacing.sm),
                    folder,
                  ],
                ),
              ],
            );
          }
          return Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: search,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              sort,
              const SizedBox(width: AppSpacing.sm),
              folder,
            ],
          );
        },
      ),
    );
  }
}

class _ToolbarControl extends StatelessWidget {
  const _ToolbarControl({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: AppSpacing.touchTarget),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 19, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Text(label, maxLines: 1, style: theme.textTheme.labelLarge),
          const SizedBox(width: AppSpacing.xs),
          Icon(
            Icons.expand_more,
            size: 19,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _LibraryFoldersView extends StatelessWidget {
  const _LibraryFoldersView({
    required this.canvases,
    required this.folders,
    required this.isFiltering,
    required this.collapsedFolderIds,
    required this.onToggleFolder,
    required this.onMoveCanvas,
    required this.onRenameFolder,
    required this.onDeleteFolder,
  });

  final List<Canvase> canvases;
  final List<CanvasFolder> folders;
  final bool isFiltering;
  final Set<String?> collapsedFolderIds;
  final ValueChanged<String?> onToggleFolder;
  final Future<void> Function(Canvase canvas, String? folderId) onMoveCanvas;
  final ValueChanged<CanvasFolder> onRenameFolder;
  final ValueChanged<CanvasFolder> onDeleteFolder;

  static const _gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 300,
    mainAxisSpacing: AppSpacing.xl,
    crossAxisSpacing: AppSpacing.xl,
    childAspectRatio: 1.35,
  );

  @override
  Widget build(BuildContext context) {
    if (canvases.isEmpty && folders.isEmpty) {
      return _LibraryMessage(
        icon: Icons.draw_outlined,
        title: isFiltering ? 'No matching canvases' : 'No canvases yet',
        subtitle: isFiltering
            ? 'Try a different search.'
            : 'Tap "New canvas" to start your first one.',
      );
    }

    final Map<String?, List<Canvase>> canvasesByFolder =
        <String?, List<Canvase>>{};
    for (final Canvase canvas in canvases) {
      (canvasesByFolder[canvas.folderId] ??= <Canvase>[]).add(canvas);
    }
    final List<Canvase> unfiled = canvasesByFolder[null] ?? const <Canvase>[];

    return CustomScrollView(
      slivers: [
        for (final folder in folders) ...[
          _FolderHeader(
            folderId: folder.id,
            label: folder.name,
            count: (canvasesByFolder[folder.id] ?? const <Canvase>[]).length,
            isExpanded: isFiltering || !collapsedFolderIds.contains(folder.id),
            onToggle: isFiltering ? null : () => onToggleFolder(folder.id),
            onCanvasDropped: (canvas) => onMoveCanvas(canvas, folder.id),
            onRename: () => onRenameFolder(folder),
            onDelete: () => onDeleteFolder(folder),
          ),
          if (isFiltering || !collapsedFolderIds.contains(folder.id))
            _CanvasGrid(
              folderId: folder.id,
              canvases: canvasesByFolder[folder.id] ?? const <Canvase>[],
              folders: folders,
            ),
        ],
        if (unfiled.isNotEmpty || folders.isNotEmpty) ...[
          _FolderHeader(
            folderId: null,
            label: 'Unfiled',
            count: unfiled.length,
            isExpanded: isFiltering || !collapsedFolderIds.contains(null),
            onToggle: isFiltering ? null : () => onToggleFolder(null),
            onCanvasDropped: (canvas) => onMoveCanvas(canvas, null),
          ),
          if (isFiltering || !collapsedFolderIds.contains(null))
            _CanvasGrid(folderId: null, canvases: unfiled, folders: folders),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 96)),
      ],
    );
  }
}

class _FolderHeader extends StatelessWidget {
  const _FolderHeader({
    required this.folderId,
    required this.label,
    required this.count,
    required this.isExpanded,
    required this.onToggle,
    required this.onCanvasDropped,
    this.onRename,
    this.onDelete,
  });

  final String? folderId;
  final String label;
  final int count;
  final bool isExpanded;
  final VoidCallback? onToggle;
  final Future<void> Function(Canvase canvas) onCanvasDropped;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: DragTarget<Canvase>(
        key: LibraryPage.folderDropTargetKey(folderId),
        onWillAcceptWithDetails: (details) => details.data.folderId != folderId,
        onAcceptWithDetails: (details) {
          unawaited(onCanvasDropped(details.data));
        },
        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: isHovering
                  ? theme.colorScheme.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              border: Border.all(
                color: isHovering
                    ? theme.colorScheme.primary
                    : Colors.transparent,
              ),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Row(
              children: [
                IconButton(
                  key: LibraryPage.folderToggleKey(folderId),
                  onPressed: onToggle,
                  tooltip: onToggle == null
                      ? 'Folders stay expanded while searching'
                      : '${isExpanded ? 'Collapse' : 'Expand'} $label',
                  icon: Icon(
                    isExpanded ? Icons.expand_more : Icons.chevron_right,
                  ),
                ),
                Icon(
                  folderId == null
                      ? Icons.inbox_outlined
                      : isExpanded
                      ? Icons.folder_open_outlined
                      : Icons.folder_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  '$count ${count == 1 ? 'canvas' : 'canvases'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Divider(color: theme.colorScheme.outlineVariant),
                ),
                if (onRename != null || onDelete != null)
                  PopupMenuButton<_FolderAction>(
                    tooltip: 'Folder options',
                    onSelected: (action) {
                      switch (action) {
                        case _FolderAction.rename:
                          onRename?.call();
                        case _FolderAction.delete:
                          onDelete?.call();
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: _FolderAction.rename,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Rename'),
                        ),
                      ),
                      PopupMenuItem(
                        value: _FolderAction.delete,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.delete_outline),
                          title: Text('Delete'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

enum _FolderAction { rename, delete }

class _CanvasGrid extends StatelessWidget {
  const _CanvasGrid({
    required this.folderId,
    required this.canvases,
    required this.folders,
  });

  final String? folderId;
  final List<Canvase> canvases;
  final List<CanvasFolder> folders;

  @override
  Widget build(BuildContext context) {
    if (canvases.isEmpty) {
      return SliverToBoxAdapter(
        key: LibraryPage.folderContentsKey(folderId),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.md,
          ),
          child: Text(
            'No canvases',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    return SliverPadding(
      key: LibraryPage.folderContentsKey(folderId),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      sliver: SliverGrid.builder(
        gridDelegate: _LibraryFoldersView._gridDelegate,
        itemCount: canvases.length,
        itemBuilder: (context, index) {
          final canvas = canvases[index];
          return MouseRegion(
            cursor: SystemMouseCursors.grab,
            child: LongPressDraggable<Canvase>(
              key: LibraryPage.canvasDragKey(canvas.id),
              data: canvas,
              feedback: _CanvasDragFeedback(canvas: canvas),
              childWhenDragging: Opacity(
                opacity: 0.3,
                child: CanvasCard(canvas: canvas, folders: folders),
              ),
              child: CanvasCard(canvas: canvas, folders: folders),
            ),
          );
        },
      ),
    );
  }
}

class _CanvasDragFeedback extends StatelessWidget {
  const _CanvasDragFeedback({required this.canvas});

  final Canvase canvas;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 240),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.drive_file_move_outline,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  canvas.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ],
          ),
        ),
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
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onRetry;

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
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
