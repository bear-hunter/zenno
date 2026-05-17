import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import 'package:zenno/canvas/canvas_controller.dart';
import 'package:zenno/canvas/model/canvas_element.dart';
import 'package:zenno/canvas/model/viewport_state.dart';
import 'package:zenno/canvas/persistence/canvas_providers.dart';
import 'package:zenno/canvas/render/canvas_view.dart';
import 'package:zenno/canvas/widgets/canvas_bookmarks_menu.dart';
import 'package:zenno/canvas/widgets/canvas_toolbar.dart';
import 'package:zenno/canvas/widgets/link_target_dialog.dart';

/// Hosts the infinite-canvas engine for a single canvas document.
///
/// Owns the [CanvasController] for the lifetime of the route — created in
/// [State.initState] and disposed in [State.dispose].
///
/// ## Persistence
///
/// The page is a [ConsumerStatefulWidget]: it reads the [canvasRepository]
/// provider (built over the app `databaseProvider`) and hands that repository
/// plus [canvasId] to the controller, so the canvas is **persistence-aware**.
/// On init the controller's [CanvasController.load] hydrates its elements and
/// viewport from SQLite; the page shows a brief loading spinner until that
/// completes. Thereafter every committed mutation writes through automatically.
/// On dispose the page [CanvasController.flush]es any pending debounced writes
/// — so a canvas closed mid-pan still saves where it was left — before
/// disposing the controller.
///
/// ## Links and multi-canvas navigation
///
/// The page is the seam between the self-contained `lib/canvas/` engine and the
/// rest of the app:
///
/// * **Placing a link** — when the link tool is tapped, [CanvasView] calls back
///   here; the page opens [showLinkTargetDialog] to collect the chip label and
///   destination, then asks the controller to place the [LinkElement]. To pick
///   a destination *canvas* the dialog needs the list of canvases, which lives
///   in the library feature — so the page takes an optional injected
///   [canvasChooser] rather than importing the library. With no chooser the
///   dialog falls back to a free-text canvas-id field, keeping the engine
///   usable standalone.
/// * **Following a link** — a pan-tool tap on a link chip calls back here; the
///   page pushes `/canvas/<targetId>` via `go_router`. When the link pins a
///   target viewport it is passed as the route `extra`, so the destination
///   `CanvasEditorPage` can frame it.
/// * **Arriving via a link** — on load the page reads any [ViewportState]
///   passed as the route `extra` (see [GoRouterState.extra]) and "flies" the
///   controller's camera to it once the canvas has laid out. An explicit
///   [initialViewport] constructor argument takes precedence (and makes the
///   behaviour testable without a router).
///
/// The app bar's [BackButton] returns to the previous canvas, so following a
/// chain of links and stepping back out works for free.
class CanvasEditorPage extends ConsumerStatefulWidget {
  /// Creates the editor page for the canvas identified by [canvasId].
  const CanvasEditorPage({
    required this.canvasId,
    this.canvasChooser,
    this.initialViewport,
    super.key,
  });

  /// Identifier of the canvas document to open, taken from the `/canvas/:id`
  /// route path parameter.
  final String canvasId;

  /// Lists the canvases the link dialog may target, as `(id, title)` records.
  ///
  /// Injected by whatever builds the route (the library feature, later) so
  /// `lib/canvas/` never depends on the library. When `null` the link dialog
  /// degrades to a free-text canvas-id field.
  final Future<List<LinkCanvasOption>> Function()? canvasChooser;

  /// Viewport to frame when the page opens, overriding any route `extra` and
  /// any persisted last viewport.
  ///
  /// Mainly a test seam — in normal use a link-driven target viewport arrives
  /// as the route `extra` instead (see the class doc).
  final ViewportState? initialViewport;

  @override
  ConsumerState<CanvasEditorPage> createState() => _CanvasEditorPageState();
}

class _CanvasEditorPageState extends ConsumerState<CanvasEditorPage> {
  late final CanvasController _controller;
  final GlobalKey _thumbnailKey = GlobalKey();

  /// Whether the one-shot "fly to the arrival viewport" has already run.
  bool _appliedInitialViewport = false;

  @override
  void initState() {
    super.initState();
    // The repository is read once, here, rather than watched: the controller
    // holds it for the page's lifetime and a Drift repo never changes identity.
    _controller = CanvasController(
      repository: ref.read(canvasRepositoryProvider),
      canvasId: widget.canvasId,
    );
    // Hydrate elements + viewport from SQLite. `load` flips `isLoaded` and
    // notifies; the build watches the controller, so the spinner clears itself.
    _controller.load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Resolve the arrival viewport once: an explicit constructor argument wins,
    // otherwise a `ViewportState` handed in as the route `extra` by a link.
    if (_appliedInitialViewport) {
      return;
    }
    final ViewportState? target =
        widget.initialViewport ?? _viewportFromRouteExtra();
    _appliedInitialViewport = true;
    if (target != null) {
      // Defer to after first layout so the controller knows its viewport size
      // (the camera math and any later region framing depend on it). The frame
      // callback also runs after `load` has typically resolved, so an explicit
      // arrival viewport is applied on top of (and overrides) the persisted one.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.setViewport(target);
        }
      });
    }
  }

  @override
  void dispose() {
    // Persist any debounced/in-flight writes before the controller goes away,
    // so a canvas closed straight after a pan still saves its final state.
    final CanvasController controller = _controller;
    _captureThumbnail().whenComplete(() {
      controller.flush().whenComplete(controller.dispose);
    });
    super.dispose();
  }

  Future<void> _captureThumbnail() async {
    try {
      final context = _thumbnailKey.currentContext;
      final boundary = context?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 0.35);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final bytes = byteData?.buffer.asUint8List();
      if (bytes == null) return;

      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory('${docs.path}/thumbnails');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final file = File('${dir.path}/${widget.canvasId}.png');
      await file.writeAsBytes(bytes, flush: true);
      await ref
          .read(canvasRepositoryProvider)
          .updateThumbnailPath(widget.canvasId, file.path);
    } catch (_) {
      // Best-effort preview generation; content persistence is handled by the
      // controller's explicit save-error path.
    }
  }

  Future<void> _handleBack() async {
    await _controller.flush();
    if (!mounted) return;
    if (_controller.hasSaveError) {
      final leave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Canvas not saved'),
          content: const Text(
            'Some changes could not be saved yet. Leave this canvas anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Stay'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Leave'),
            ),
          ],
        ),
      );
      if (leave != true) return;
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  /// The [ViewportState] passed as this route's `extra`, or `null`.
  ///
  /// A link that pins a target viewport pushes it as the `extra`; reading it
  /// here means the route table needs no extra parameter. Any other `extra`
  /// type is ignored.
  ViewportState? _viewportFromRouteExtra() {
    final Object? extra = GoRouterState.of(context).extra;
    return extra is ViewportState ? extra : null;
  }

  /// Handles a link-placement tap from the canvas.
  ///
  /// Opens the link dialog to collect the chip label and destination, then —
  /// if the user confirmed — asks the controller to place the [LinkElement] at
  /// [worldCenter].
  Future<void> _onPlaceLink(Offset worldCenter) async {
    final LinkDialogResult? result = await showLinkTargetDialog(
      context,
      canvasChooser: widget.canvasChooser,
    );
    if (result == null) {
      return;
    }
    _controller.placeLink(
      worldCenter: worldCenter,
      label: result.label,
      target: result.target,
    );
  }

  /// Handles a text-tool tap by creating a note or editing the tapped one.
  Future<void> _onEditText(Offset worldCenter, TextElement? existing) async {
    final String? text = await _showTextNoteDialog(existing?.text ?? '');
    if (text == null) {
      return;
    }
    if (existing == null) {
      if (text.trim().isNotEmpty) {
        _controller.placeText(worldCenter: worldCenter, text: text);
      }
    } else {
      _controller.updateTextElement(existing, text);
    }
  }

  Future<String?> _showTextNoteDialog(String initialText) {
    final controller = TextEditingController(text: initialText);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(initialText.trim().isEmpty ? 'New note' : 'Edit note'),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: controller,
            autofocus: true,
            minLines: 5,
            maxLines: 10,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Write a note',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  /// Handles a pan-tool tap on an existing link chip.
  ///
  /// Pushes the destination canvas route. When the link pins a target viewport
  /// it travels as the route `extra` so the destination page frames it; a back
  /// action returns here.
  void _onFollowLink(LinkElement link) {
    final ViewportState? target = link.target.targetViewport;
    context.push('/canvas/${link.target.targetCanvasId}', extra: target);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: _handleBack),
        title: const Text('Canvas'),
        actions: [CanvasBookmarksMenu(controller: _controller)],
      ),
      // Watch the controller so the body swaps from the loading spinner to the
      // canvas the moment `load` finishes hydrating it.
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (!_controller.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              if (_controller.hasSaveError)
                MaterialBanner(
                  content: const Text('Canvas not saved'),
                  leading: const Icon(Icons.cloud_off_outlined),
                  actions: [
                    TextButton(
                      onPressed: _controller.retryFailedWrites,
                      child: const Text('Retry'),
                    ),
                    TextButton(
                      onPressed: _controller.dismissSaveError,
                      child: const Text('Dismiss'),
                    ),
                  ],
                ),
              CanvasToolbar(controller: _controller),
              Expanded(
                child: RepaintBoundary(
                  key: _thumbnailKey,
                  child: CanvasView(
                    controller: _controller,
                    onPlaceLink: _onPlaceLink,
                    onFollowLink: _onFollowLink,
                    onEditText: _onEditText,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
