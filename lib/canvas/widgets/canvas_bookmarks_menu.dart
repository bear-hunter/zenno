import 'package:flutter/material.dart';

import 'package:zenno/canvas/canvas_controller.dart';
import 'package:zenno/canvas/model/canvas_bookmark.dart';

/// A small bookmarks menu for the canvas, surfaced as an app-bar action.
///
/// Wraps a [PopupMenuButton] bound to a [CanvasController]: the menu offers
/// "Save current view" (which prompts for a name) and then lists every saved
/// [Bookmark] — tapping one flies the camera to it, the trailing button
/// removes it. Bookmarks are held in memory on the controller in Phase 1; this
/// widget is purely their UI surface.
class CanvasBookmarksMenu extends StatelessWidget {
  /// Creates a bookmarks menu bound to [controller].
  const CanvasBookmarksMenu({required this.controller, super.key});

  /// The canvas whose bookmarks this menu manages.
  final CanvasController controller;

  /// Sentinel menu value for the "save current view" action.
  static const String _saveValue = '__save__';

  @override
  Widget build(BuildContext context) {
    // Rebuild with the controller so a freshly saved bookmark appears at once.
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final List<Bookmark> bookmarks = controller.bookmarks;
        return PopupMenuButton<String>(
          icon: const Icon(Icons.bookmark_outline),
          tooltip: 'Bookmarks',
          onSelected: (value) {
            if (value == _saveValue) {
              _promptSave(context);
            } else {
              final Bookmark? target = _byName(bookmarks, value);
              if (target != null) {
                controller.goToBookmark(target);
              }
            }
          },
          itemBuilder: (context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: _saveValue,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.add_location_alt_outlined),
                title: Text('Save current view'),
              ),
            ),
            if (bookmarks.isNotEmpty) const PopupMenuDivider(),
            for (final Bookmark bookmark in bookmarks)
              PopupMenuItem<String>(
                value: bookmark.name,
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.place_outlined),
                  title: Text(bookmark.name, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: 'Remove',
                    onPressed: () {
                      controller.removeBookmark(bookmark);
                      // Close the menu so its now-stale list is not shown.
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Returns the bookmark named [name] from [bookmarks], or `null`.
  static Bookmark? _byName(List<Bookmark> bookmarks, String name) {
    for (final Bookmark bookmark in bookmarks) {
      if (bookmark.name == name) {
        return bookmark;
      }
    }
    return null;
  }

  /// Prompts for a name, then saves the current viewport as a bookmark.
  Future<void> _promptSave(BuildContext context) async {
    final String? name = await showDialog<String>(
      context: context,
      builder: (context) => const _NameBookmarkDialog(),
    );
    if (name != null) {
      controller.saveBookmark(name);
    }
  }
}

/// Modal that collects a name for a new bookmark.
class _NameBookmarkDialog extends StatefulWidget {
  const _NameBookmarkDialog();

  @override
  State<_NameBookmarkDialog> createState() => _NameBookmarkDialogState();
}

class _NameBookmarkDialogState extends State<_NameBookmarkDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Closes the dialog, returning the trimmed name when it is non-empty.
  void _submit() {
    final String name = _controller.text.trim();
    if (name.isEmpty) {
      return;
    }
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Save view'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _submit(),
        decoration: const InputDecoration(
          labelText: 'Bookmark name',
          hintText: 'e.g. Overview, Diagram 3',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _controller.text.trim().isEmpty ? null : _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
