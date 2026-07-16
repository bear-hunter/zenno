import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import 'package:zenno/canvas/canvas_controller.dart';
import 'package:zenno/canvas/canvas_editor_navigation.dart';
import 'package:zenno/canvas/input/pen_profile.dart';
import 'package:zenno/canvas/input/stylus_button_mapping.dart';
import 'package:zenno/canvas/model/canvas_element.dart';
import 'package:zenno/canvas/model/viewport_state.dart';
import 'package:zenno/canvas/persistence/canvas_providers.dart';
import 'package:zenno/canvas/persistence/canvas_repository.dart';
import 'package:zenno/canvas/render/canvas_view.dart';
import 'package:zenno/canvas/widgets/canvas_bookmarks_menu.dart';
import 'package:zenno/canvas/widgets/canvas_toolbar.dart';
import 'package:zenno/canvas/widgets/link_target_dialog.dart';
import 'package:zenno/config/router/routes.dart';
import 'package:zenno/features/library/application/library_providers.dart';
import 'package:zenno/features/settings/application/settings_providers.dart';

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
///   a destination *canvas* the page supplies the current Library list. Tests
///   or standalone hosts may override that list with [canvasChooser].
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
  /// Optional override for the production Library-backed chooser.
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
  late final CanvasRepository _repository;
  late Future<bool> _loadFuture;
  final GlobalKey _thumbnailKey = GlobalKey();
  final GlobalKey<_EditableCanvasTitleState> _titleKey =
      GlobalKey<_EditableCanvasTitleState>();
  final GlobalKey<CanvasToolbarState> _toolbarKey =
      GlobalKey<CanvasToolbarState>();

  /// Whether the one-shot "fly to the arrival viewport" has already run.
  bool _appliedInitialViewport = false;
  ViewportState? _arrivalViewport;
  Object? _loadError;
  bool _handlingBack = false;
  bool _editingTitle = false;
  bool _quickToolMenuOpen = false;
  CanvasEditorRouteRegistration? _navigationRegistration;

  @override
  void initState() {
    super.initState();
    // The repository is read once, here, rather than watched: the controller
    // holds it for the page's lifetime and a Drift repo never changes identity.
    _repository = ref.read(canvasRepositoryProvider);
    _controller = CanvasController(
      repository: _repository,
      canvasId: widget.canvasId,
    );
    // Hydrate elements + viewport from SQLite. `load` flips `isLoaded` and
    // notifies; the build watches the controller, so the spinner clears itself.
    _loadFuture = _loadController();
  }

  Future<bool> _loadController() async {
    try {
      await _controller.load();
      if (mounted && _loadError != null) {
        setState(() => _loadError = null);
      }
      return true;
    } catch (error) {
      if (mounted) {
        setState(() => _loadError = error);
      }
      return false;
    }
  }

  void _retryLoad() {
    setState(() => _loadError = null);
    _loadFuture = _loadController();
    _scheduleArrivalViewport();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _navigationRegistration ??= _registerNavigationRoute();
    // Resolve the arrival viewport once: an explicit constructor argument wins,
    // otherwise a `ViewportState` handed in as the route `extra` by a link.
    if (_appliedInitialViewport) {
      return;
    }
    _arrivalViewport = widget.initialViewport ?? _viewportFromRouteExtra();
    _appliedInitialViewport = true;
    _scheduleArrivalViewport();
  }

  CanvasEditorRouteRegistration? _registerNavigationRoute() {
    final ModalRoute<dynamic>? route = ModalRoute.of(context);
    if (route == null) {
      return null;
    }
    return CanvasEditorNavigation.register(
      canvasId: widget.canvasId,
      route: route,
      isMounted: () => mounted,
      close: _closeForNavigation,
      applyViewport: _applyNavigationViewport,
    );
  }

  void _applyNavigationViewport(ViewportState viewport) {
    if (!mounted) {
      return;
    }
    _arrivalViewport = viewport;
    if (_controller.isLoaded) {
      _controller.setViewport(viewport);
      _arrivalViewport = null;
      return;
    }
    _scheduleArrivalViewport();
  }

  void _scheduleArrivalViewport() {
    final ViewportState? target = _arrivalViewport;
    if (target == null) return;
    // Hydration may outlive the first frame. Apply the link target only after
    // the persisted viewport has loaded, so hydration cannot overwrite it.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final bool loaded = await _loadFuture;
      if (!mounted || !loaded || _arrivalViewport == null) return;
      _controller.setViewport(_arrivalViewport!);
      _arrivalViewport = null;
    });
  }

  @override
  void dispose() {
    _navigationRegistration?.dispose();
    // Persist any debounced/in-flight writes before the controller goes away,
    // so a canvas closed straight after a pan still saves its final state.
    final CanvasController controller = _controller;
    unawaited(controller.flush().whenComplete(controller.dispose));
    super.dispose();
  }

  Future<void> _captureThumbnail() async {
    if (kIsWeb) return;
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
      await _repository.updateThumbnailPath(widget.canvasId, file.path);
    } catch (_) {
      // Best-effort preview generation; content persistence is handled by the
      // controller's explicit save-error path.
    }
  }

  Future<void> _handleBack() async {
    if (_controller.hasSelection) {
      _controller.clearSelection();
      return;
    }
    await _closeEditor();
  }

  Future<bool> _closeForNavigation() {
    if (ModalRoute.of(context)?.isCurrent != true) {
      return Future<bool>.value(false);
    }
    return _closeEditor(waitForThumbnail: false);
  }

  Future<bool> _closeEditor({bool waitForThumbnail = true}) async {
    if (_handlingBack) return false;
    _handlingBack = true;
    try {
      final bool titleSaved =
          await (_titleKey.currentState?.saveForExit() ??
              Future<bool>.value(true));
      if (!titleSaved) return false;

      await _controller.flush();
      if (!mounted) return false;
      if (_controller.hasUnsavedWrites) {
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
        if (leave != true) return false;
      }
      // A render object is detached during dispose, so capture while the route
      // is still mounted. Dispose remains a persistence-only safety net.
      if (waitForThumbnail) {
        await _captureThumbnail();
      } else {
        unawaited(_captureThumbnail());
      }
      if (!mounted) return false;
      final NavigatorState navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop();
      } else {
        GoRouter.maybeOf(context)?.go(Routes.library);
      }
      return true;
    } finally {
      _handlingBack = false;
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
      canvasChooser: widget.canvasChooser ?? _canvasChoices,
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

  Future<List<LinkCanvasOption>> _canvasChoices() async {
    final canvases = await ref.read(canvasListProvider.future);
    return [
      for (final canvas in canvases)
        if (canvas.id != widget.canvasId) (id: canvas.id, title: canvas.title),
    ];
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
  Future<void> _onFollowLink(LinkElement link) async {
    final String targetId = link.target.targetCanvasId;
    final ViewportState? target = link.target.targetViewport;
    if (targetId == widget.canvasId) {
      if (target != null) _controller.setViewport(target);
      return;
    }
    if (!await _repository.canvasExists(targetId)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('That linked canvas no longer exists.')),
        );
      }
      return;
    }
    if (mounted) {
      unawaited(openCanvasEditor(context, targetId, targetViewport: target));
    }
  }

  void _nudgeSelection(Offset direction) {
    if (!_controller.hasSelection) {
      return;
    }
    final double step = 8 / _controller.viewport.scale;
    _controller.nudgeSelection(direction * step);
  }

  void _rotateSelection(double direction) {
    if (!_controller.hasSelection) {
      return;
    }
    _controller.rotateSelection(direction * math.pi / 12);
  }

  void _scaleSelection(double factor) {
    if (!_controller.hasSelection) {
      return;
    }
    _controller.scaleSelection(factor, factor);
  }

  void _onShowQuickTools(Offset localPosition) {
    if (!mounted || _quickToolMenuOpen) {
      return;
    }
    final RenderBox? surface =
        _thumbnailKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (surface == null || overlay == null) {
      return;
    }
    final Offset overlayPosition = overlay.globalToLocal(
      surface.localToGlobal(localPosition),
    );
    _quickToolMenuOpen = true;
    unawaited(_openQuickToolMenu(overlayPosition));
  }

  Future<void> _openQuickToolMenu(Offset overlayPosition) async {
    try {
      await showCanvasQuickToolMenuAt(
        context: context,
        controller: _controller,
        overlayPosition: overlayPosition,
        onShowFullControls: () => _toolbarKey.currentState?.showFullControls(),
      );
    } finally {
      _quickToolMenuOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final canvasTitle = ref.watch(canvasTitleProvider(widget.canvasId)).value;
    final settings = ref.watch(appSettingsProvider).value;

    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        // Watch the controller so the body swaps from the loading spinner to the
        // canvas the moment `load` finishes hydrating it.
        body: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final importError = _controller.importErrorMessage;
            if (importError != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(importError)));
                _controller.clearImportError();
              });
            }
            if (_loadError case final Object error) {
              final bool missing = error is CanvasNotFoundException;
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.link_off, size: 40),
                      const SizedBox(height: 16),
                      Text(
                        missing
                            ? 'This canvas no longer exists.'
                            : 'Could not load this canvas.',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: _handleBack,
                            child: const Text('Back'),
                          ),
                          if (!missing)
                            FilledButton(
                              onPressed: _retryLoad,
                              child: const Text('Retry'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }
            if (!_controller.isLoaded) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading canvas…'),
                  ],
                ),
              );
            }
            return Focus(
              autofocus: true,
              child: CallbackShortcuts(
                bindings: _editingTitle
                    ? const <ShortcutActivator, VoidCallback>{}
                    : <ShortcutActivator, VoidCallback>{
                        const SingleActivator(
                          LogicalKeyboardKey.keyZ,
                          control: true,
                        ): _controller.undo,
                        const SingleActivator(
                          LogicalKeyboardKey.keyZ,
                          control: true,
                          shift: true,
                        ): _controller.redo,
                        const SingleActivator(
                          LogicalKeyboardKey.keyC,
                          control: true,
                        ): _controller.copySelection,
                        const SingleActivator(
                          LogicalKeyboardKey.keyV,
                          control: true,
                        ): _controller.pasteSelection,
                        const SingleActivator(LogicalKeyboardKey.delete):
                            _controller.deleteSelection,
                        const SingleActivator(LogicalKeyboardKey.escape):
                            _controller.clearSelection,
                        const SingleActivator(
                          LogicalKeyboardKey.arrowLeft,
                          control: true,
                        ): () =>
                            _nudgeSelection(const Offset(-1, 0)),
                        const SingleActivator(
                          LogicalKeyboardKey.arrowRight,
                          control: true,
                        ): () =>
                            _nudgeSelection(const Offset(1, 0)),
                        const SingleActivator(
                          LogicalKeyboardKey.arrowUp,
                          control: true,
                        ): () =>
                            _nudgeSelection(const Offset(0, -1)),
                        const SingleActivator(
                          LogicalKeyboardKey.arrowDown,
                          control: true,
                        ): () =>
                            _nudgeSelection(const Offset(0, 1)),
                        const SingleActivator(
                          LogicalKeyboardKey.bracketLeft,
                          control: true,
                        ): () =>
                            _rotateSelection(-1),
                        const SingleActivator(
                          LogicalKeyboardKey.bracketRight,
                          control: true,
                        ): () =>
                            _rotateSelection(1),
                        const SingleActivator(
                          LogicalKeyboardKey.minus,
                          control: true,
                        ): () =>
                            _scaleSelection(1 / 1.1),
                        const SingleActivator(
                          LogicalKeyboardKey.equal,
                          control: true,
                        ): () =>
                            _scaleSelection(1.1),
                        const SingleActivator(LogicalKeyboardKey.keyV): () =>
                            _controller.setTool(CanvasTool.pan),
                        const SingleActivator(LogicalKeyboardKey.keyP): () =>
                            _controller.setTool(CanvasTool.pen),
                        const SingleActivator(LogicalKeyboardKey.keyE): () =>
                            _controller.setTool(CanvasTool.eraser),
                        const SingleActivator(LogicalKeyboardKey.keyL): () =>
                            _controller.setTool(CanvasTool.lasso),
                        const SingleActivator(LogicalKeyboardKey.keyS): () =>
                            _controller.setTool(CanvasTool.shape),
                        const SingleActivator(LogicalKeyboardKey.keyT): () =>
                            _controller.setTool(CanvasTool.text),
                        const SingleActivator(LogicalKeyboardKey.keyK): () =>
                            _controller.setTool(CanvasTool.link),
                      },
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: RepaintBoundary(
                        key: _thumbnailKey,
                        child: CanvasView(
                          controller: _controller,
                          onPlaceLink: _onPlaceLink,
                          onFollowLink: _onFollowLink,
                          onEditText: _onEditText,
                          onShowQuickTools: _onShowQuickTools,
                          stylusButtonMapping:
                              settings?.stylusButtonMapping ??
                              const StylusButtonMapping(),
                          penProfile:
                              settings?.penProfile ?? const PenProfile(),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: CanvasToolbar(
                        key: _toolbarKey,
                        controller: _controller,
                        onBack: _handleBack,
                        controlsLockedOpen: _editingTitle,
                        title: _EditableCanvasTitle(
                          key: _titleKey,
                          canvasId: widget.canvasId,
                          title: canvasTitle?.trim().isNotEmpty == true
                              ? canvasTitle!.trim()
                              : 'Canvas',
                          onEditingChanged: (editing) {
                            if (mounted && _editingTitle != editing) {
                              setState(() => _editingTitle = editing);
                            }
                          },
                        ),
                        trailingMenu: CanvasBookmarksMenu(
                          controller: _controller,
                        ),
                        palette: settings?.inkPalette ?? const <int>[],
                        onPaletteChanged: (colors) => ref
                            .read(settingsRepositoryProvider)
                            .setInkPalette(colors),
                        toolWheelPosition: settings?.toolWheelPosition,
                        onToolWheelPositionChanged: (position) => ref
                            .read(settingsRepositoryProvider)
                            .setToolWheelPosition(position),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EditableCanvasTitle extends ConsumerStatefulWidget {
  const _EditableCanvasTitle({
    required this.canvasId,
    required this.title,
    required this.onEditingChanged,
    super.key,
  });

  final String canvasId;
  final String title;
  final ValueChanged<bool> onEditingChanged;

  @override
  ConsumerState<_EditableCanvasTitle> createState() =>
      _EditableCanvasTitleState();
}

class _EditableCanvasTitleState extends ConsumerState<_EditableCanvasTitle> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _editing = false;
  bool _saving = false;
  Future<bool>? _saveInFlight;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.title);
  }

  @override
  void didUpdateWidget(covariant _EditableCanvasTitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing && widget.title != _controller.text) {
      _controller.text = widget.title;
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() => _editing = true);
    widget.onEditingChanged(true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
  }

  Future<bool> saveForExit() => _save();

  Future<bool> _save() {
    final Future<bool>? inFlight = _saveInFlight;
    if (inFlight != null) return inFlight;
    final Future<bool> future = _performSave();
    _saveInFlight = future;
    return future.whenComplete(() => _saveInFlight = null);
  }

  Future<bool> _performSave() async {
    final next = _controller.text.trim();
    if (!_editing) return true;
    if (next.isEmpty || next == widget.title) {
      setState(() {
        _editing = false;
        _controller.text = widget.title;
      });
      widget.onEditingChanged(false);
      return true;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(libraryRepositoryProvider)
          .renameCanvas(widget.canvasId, next);
      if (mounted) {
        setState(() {
          _editing = false;
          _saving = false;
        });
        widget.onEditingChanged(false);
      }
      return true;
    } catch (error) {
      debugPrint('Inline rename failed: $error');
      if (!mounted) return false;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not rename canvas.')));
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.titleSmall?.copyWith(
      color: colors.onSurface,
      fontWeight: FontWeight.w700,
    );
    if (_editing) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: SizedBox(
          height: 40,
          child: TextField(
            key: const ValueKey<String>('canvas-title-field'),
            controller: _controller,
            focusNode: _focusNode,
            enabled: !_saving,
            textAlign: TextAlign.left,
            textInputAction: TextInputAction.done,
            style: style,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: colors.surfaceContainerHighest,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              suffixIcon: _saving
                  ? const Padding(
                      padding: EdgeInsets.all(11),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
            ),
            onSubmitted: (_) => unawaited(_save()),
            onTapOutside: (_) => unawaited(_save()),
          ),
        ),
      );
    }
    return Tooltip(
      message: 'Rename canvas',
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: _startEditing,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Text(
            widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ),
    );
  }
}
