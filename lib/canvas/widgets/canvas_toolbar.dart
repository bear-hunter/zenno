import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:zenno/canvas/canvas_controller.dart';
import 'package:zenno/canvas/io/canvas_export.dart';
import 'package:zenno/canvas/model/canvas_element.dart';
import 'package:zenno/canvas/model/canvas_layer.dart';
import 'package:zenno/canvas/model/canvas_style.dart';
import 'package:zenno/canvas/model/stroke.dart';
import 'package:zenno/config/theme/app_spacing.dart';
import 'package:zenno/core/database/tables/canvas_tables.dart';

const List<(CanvasTool, IconData, String)> _canvasToolOptions =
    <(CanvasTool, IconData, String)>[
      (CanvasTool.pan, Icons.pan_tool_alt_outlined, 'Pan'),
      (CanvasTool.pen, Icons.draw_outlined, 'Draw'),
      (CanvasTool.eraser, Icons.cleaning_services_outlined, 'Eraser'),
      (CanvasTool.lasso, Icons.gesture, 'Lasso select'),
      (CanvasTool.shape, Icons.category_outlined, 'Shapes'),
      (CanvasTool.text, Icons.notes_outlined, 'Text note'),
      (CanvasTool.link, Icons.add_link, 'Place a link'),
    ];

/// Responsive, content-first chrome for the infinite canvas editor.
class CanvasToolbar extends StatefulWidget {
  /// Creates controls bound to [controller].
  const CanvasToolbar({
    required this.controller,
    this.onBack,
    this.title,
    this.trailingMenu,
    this.palette = _defaultSwatches,
    this.onPaletteChanged,
    this.controlsLockedOpen = false,
    super.key,
  });

  /// The canvas state and command surface this toolbar drives.
  final CanvasController controller;

  /// Optional page-owned back action.
  final VoidCallback? onBack;

  /// Optional compact title/editor shown independently above the canvas.
  final Widget? title;

  /// Optional page-owned menu, such as bookmarks.
  final Widget? trailingMenu;
  final List<int> palette;
  final ValueChanged<List<int>>? onPaletteChanged;

  /// Retained for compatibility with page-owned title editing state.
  final bool controlsLockedOpen;

  static const String toolButtonKeyPrefix = 'canvas-tool';
  static const String widthButtonKeyPrefix = 'canvas-width';
  static const String penWidthModeButtonKeyPrefix = 'canvas-pen-width-mode';
  static const String swatchButtonKeyPrefix = 'canvas-swatch';
  static const String palettePresetButtonKeyPrefix = 'canvas-palette-preset';
  static const String paperKindButtonKeyPrefix = 'canvas-paper-kind';
  static const String paperBackgroundPresetButtonKeyPrefix =
      'canvas-paper-background-preset';
  static const String paperGridPresetButtonKeyPrefix =
      'canvas-paper-grid-preset';
  static const Key importImageKey = ValueKey<String>('canvas-import-image');
  static const Key importPdfKey = ValueKey<String>('canvas-import-pdf');
  static const Key paperSettingsPanelKey = ValueKey<String>(
    'canvas-paper-settings-panel',
  );
  static const Key canvasSettingsDockKey = ValueKey<String>(
    'canvas-settings-dock',
  );
  static const Key penDockKey = ValueKey<String>('canvas-pen-dock');
  static const Key topNavigationDockKey = ValueKey<String>(
    'canvas-top-navigation-dock',
  );
  static const Key topActionsDockKey = ValueKey<String>(
    'canvas-top-actions-dock',
  );
  static const Key compactDrawingPadKey = ValueKey<String>(
    'canvas-compact-drawing-pad',
  );
  static const Key minimalBackKey = ValueKey<String>('canvas-minimal-back');
  static const Key minimalToolMenuKey = ValueKey<String>(
    'canvas-minimal-tool-menu',
  );
  static const Key wheelCenterKey = ValueKey<String>('canvas-wheel-center');
  static const Key paletteDockKey = ValueKey<String>('canvas-palette-dock');
  static const Key minimalSaveErrorKey = ValueKey<String>(
    'canvas-minimal-save-error',
  );
  static const Key pinControlsKey = ValueKey<String>('canvas-pin-controls');
  static const Key hideControlsKey = ValueKey<String>('canvas-hide-controls');
  static const Key gestureGuideKey = ValueKey<String>('canvas-gesture-guide');
  static const Key showFullControlsKey = ValueKey<String>(
    'canvas-show-full-controls',
  );

  /// Neutral canvas-editor backdrop used by standalone hosts.
  static const Color canvasBackground = Color(0xFF101016);

  static const List<int> _defaultSwatches = <int>[
    0xFFFF4F91,
    0xFFFFC928,
    0xFF36D400,
    0xFF1E9BFF,
    0xFFFFFFFF,
    0xFF111820,
  ];

  @override
  State<CanvasToolbar> createState() => CanvasToolbarState();
}

/// Route-local mode state for [CanvasToolbar].
///
/// It is public so a stylus shortcut can reveal the contextual side of the
/// wheel without persisting transient UI state into canvas data.
class CanvasToolbarState extends State<CanvasToolbar> {
  _WheelPage _wheelPage = _WheelPage.tools;

  /// Reveals the contextual side of the persistent wheel.
  ///
  /// The name remains compatible with editor and stylus shortcut call sites
  /// that predate the bar-free wheel.
  void showFullControls() {
    final page = widget.controller.hasSelection
        ? _WheelPage.selection
        : _WheelPage.context;
    if (_wheelPage != page) {
      setState(() => _wheelPage = page);
    }
  }

  void _handleCenterTap() {
    setState(() {
      _wheelPage = switch (_wheelPage) {
        _WheelPage.tools =>
          widget.controller.hasSelection
              ? _WheelPage.selection
              : _WheelPage.context,
        _WheelPage.context ||
        _WheelPage.selection ||
        _WheelPage.more => _WheelPage.tools,
        _WheelPage.insert ||
        _WheelPage.appearance ||
        _WheelPage.view => _WheelPage.more,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return _CanvasToolbarContent(
      controller: widget.controller,
      onBack: widget.onBack,
      title: widget.title,
      trailingMenu: widget.trailingMenu,
      palette: widget.palette,
      onPaletteChanged: widget.onPaletteChanged,
      wheelPage: _wheelPage,
      onWheelPageChanged: (page) => setState(() => _wheelPage = page),
      onCenterTap: _handleCenterTap,
    );
  }
}

class _CanvasToolbarContent extends StatelessWidget {
  const _CanvasToolbarContent({
    required this.controller,
    required this.onBack,
    required this.title,
    required this.trailingMenu,
    required this.palette,
    required this.onPaletteChanged,
    required this.wheelPage,
    required this.onWheelPageChanged,
    required this.onCenterTap,
  });

  final CanvasController controller;
  final VoidCallback? onBack;
  final Widget? title;
  final Widget? trailingMenu;
  final List<int> palette;
  final ValueChanged<List<int>>? onPaletteChanged;
  final _WheelPage wheelPage;
  final ValueChanged<_WheelPage> onWheelPageChanged;
  final VoidCallback onCenterTap;

  static const String toolButtonKeyPrefix = CanvasToolbar.toolButtonKeyPrefix;
  static const String widthButtonKeyPrefix = CanvasToolbar.widthButtonKeyPrefix;
  static const String penWidthModeButtonKeyPrefix =
      CanvasToolbar.penWidthModeButtonKeyPrefix;
  static const String swatchButtonKeyPrefix =
      CanvasToolbar.swatchButtonKeyPrefix;
  static const Key importImageKey = CanvasToolbar.importImageKey;
  static const Key importPdfKey = CanvasToolbar.importPdfKey;
  static const Key canvasSettingsDockKey = CanvasToolbar.canvasSettingsDockKey;
  static const Key penDockKey = CanvasToolbar.penDockKey;
  static const Key topNavigationDockKey = CanvasToolbar.topNavigationDockKey;
  static const Key topActionsDockKey = CanvasToolbar.topActionsDockKey;
  static const Key compactDrawingPadKey = CanvasToolbar.compactDrawingPadKey;

  static const List<int> _defaultSwatches = CanvasToolbar._defaultSwatches;
  static const double _rotationStep = 0.2617993877991494; // 15 degrees.
  static const List<double> _widths = <double>[1, 2, 4, 8, 12, 20];
  static const double _wheelTop = 60;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double wheelSize = constraints.maxWidth >= 720 ? 176 : 156;
              final List<_WheelAction> wheelActions = _wheelActions(context);
              final double paletteWidth = math.min(
                wheelSize,
                math.max(0, constraints.maxWidth - 16),
              );
              double actionRight = 8;
              final List<Widget> cornerActions = <Widget>[];

              void addCornerAction(Widget child) {
                cornerActions.add(
                  Positioned(
                    top: 8,
                    right: actionRight,
                    child: _FloatingSurface.circular(child: child),
                  ),
                );
                actionRight += 48;
              }

              if (trailingMenu != null) {
                addCornerAction(
                  SizedBox.square(dimension: 44, child: trailingMenu),
                );
              }
              if (controller.hasUnsavedWrites) {
                addCornerAction(_saveWarningButton(context));
              }

              final double titleLeft = onBack == null ? 8 : 60;
              final double titleRight = actionRight;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  if (onBack != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _FloatingSurface.circular(
                        key: topNavigationDockKey,
                        child: _HudButton(
                          key: CanvasToolbar.minimalBackKey,
                          icon: controller.hasSelection
                              ? Icons.close
                              : Icons.arrow_back,
                          tooltip: controller.hasSelection
                              ? 'Done selecting'
                              : 'Back',
                          onPressed: onBack,
                        ),
                      ),
                    ),
                  if (titleRight + titleLeft < constraints.maxWidth - 24)
                    Positioned(
                      key: topActionsDockKey,
                      top: 8,
                      left: titleLeft,
                      right: titleRight,
                      height: 44,
                      child: Align(
                        alignment: Alignment.center,
                        child: _FloatingSurface(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 280),
                            child:
                                title ??
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  child: Text(
                                    'Canvas',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                ),
                          ),
                        ),
                      ),
                    ),
                  ...cornerActions,
                  Positioned(
                    key: compactDrawingPadKey,
                    top: _wheelTop,
                    left: 8,
                    width: wheelSize,
                    height: wheelSize,
                    child: _RadialWheel(
                      key: CanvasToolbar.minimalToolMenuKey,
                      actions: wheelActions,
                      activeColor: Color(controller.penColor),
                      centerIcon: _wheelCenterIcon,
                      centerLabel: _wheelCenterLabel,
                      centerTooltip: _wheelCenterTooltip,
                      centerKey: CanvasToolbar.wheelCenterKey,
                      onCenterTap: onCenterTap,
                      onCenterLongPress:
                          _effectiveWheelPage == _WheelPage.tools ||
                              _effectiveWheelPage == _WheelPage.context ||
                              _effectiveWheelPage == _WheelPage.selection
                          ? () => _showToolSettings(context)
                          : null,
                    ),
                  ),
                  Positioned(
                    key: CanvasToolbar.paletteDockKey,
                    top: _wheelTop + wheelSize - 4,
                    left: 8,
                    width: paletteWidth,
                    height: 32,
                    child: _PaletteDock(
                      colors: palette.isEmpty ? _defaultSwatches : palette,
                      selectedColor: controller.penColor,
                      onSelect: controller.setPenColor,
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _saveWarningButton(BuildContext context) {
    final bool failed = controller.hasSaveError;
    return _HudButton(
      key: CanvasToolbar.minimalSaveErrorKey,
      icon: failed ? Icons.cloud_off_outlined : Icons.cloud_sync_outlined,
      tooltip: 'Canvas not saved',
      destructive: failed,
      onPressed: () => _showSaveActions(context),
    );
  }

  Future<void> _showSaveActions(BuildContext context) async {
    final action = await showDialog<_SaveAction>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Canvas not saved'),
        content: const Text(
          'Some changes could not be saved. Retry before leaving the canvas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_SaveAction.dismiss),
            child: const Text('Dismiss'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_SaveAction.retry),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
    switch (action) {
      case _SaveAction.retry:
        unawaited(controller.retryFailedWrites());
      case _SaveAction.dismiss:
        controller.dismissSaveError();
      case null:
        break;
    }
  }

  void _runInsert(BuildContext context, _InsertAction action) {
    if (kIsWeb) {
      _showAndroidOnly(
        context,
        action == _InsertAction.image ? 'Image import' : 'PDF import',
      );
      return;
    }
    switch (action) {
      case _InsertAction.image:
        controller.importImage();
      case _InsertAction.pdf:
        controller.importPdf();
    }
  }

  void _runMoreAction(BuildContext context, _MoreAction action) {
    switch (action) {
      case _MoreAction.image:
        _runInsert(context, _InsertAction.image);
      case _MoreAction.pdf:
        _runInsert(context, _InsertAction.pdf);
      case _MoreAction.layers:
        _showLayerPanel(context);
      case _MoreAction.export:
        if (kIsWeb) {
          _showAndroidOnly(context, 'Canvas export');
        } else {
          _showExportDialog(context);
        }
      case _MoreAction.paper:
        _showPaperSettings(context);
      case _MoreAction.snap:
        controller.toggleSnapToGrid();
      case _MoreAction.rotationLock:
        controller.toggleRotationLock();
      case _MoreAction.resetRotation:
        controller.resetRotation();
      case _MoreAction.fit:
        controller.fitContent();
      case _MoreAction.resetView:
        controller.resetView();
      case _MoreAction.palette:
        if (onPaletteChanged != null) {
          _showPaletteEditor(
            context,
            palette.isEmpty ? _defaultSwatches : palette,
          );
        }
      case _MoreAction.gestureGuide:
        _showGestureGuide(context);
      case _MoreAction.clear:
        unawaited(_confirmClear(context));
    }
  }

  Future<void> _showGestureGuide(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gesture shortcuts'),
        scrollable: true,
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _GestureGuideRow(
              icon: Icons.pan_tool_alt_outlined,
              gesture: 'Finger drag or pinch',
              result: 'Pan, zoom, or rotate the canvas',
            ),
            _GestureGuideRow(
              icon: Icons.gesture,
              gesture: 'Pen long press (default)',
              result: 'Temporarily lasso a selection',
            ),
            _GestureGuideRow(
              icon: Icons.open_with,
              gesture: 'Selected content',
              result:
                  'Drag with stylus or finger\n'
                  'Stylus: corners resize • Top handle rotates',
            ),
            _GestureGuideRow(
              icon: Icons.close,
              gesture: 'Tap ×, empty space, or Esc',
              result: 'Finish the selection and return to your current tool',
            ),
            _GestureGuideRow(
              icon: Icons.edit_outlined,
              gesture: 'Stylus side-button defaults',
              result:
                  'Hold/drag: erase • Tap: previous tool\n'
                  'Customize tap, hold, and drag in Settings',
            ),
            _GestureGuideRow(
              icon: Icons.undo,
              gesture: 'Two-finger tap',
              result: 'Undo',
            ),
            _GestureGuideRow(
              icon: Icons.redo,
              gesture: 'Three-finger tap',
              result: 'Redo',
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Clear canvas?'),
            content: const Text(
              'Remove everything from this canvas? You can undo this while '
              'the canvas remains open.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Clear'),
              ),
            ],
          ),
        ) ??
        false;
    if (confirmed) controller.clear();
  }

  void _showAndroidOnly(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature is available in the Android app.')),
    );
  }

  (CanvasTool, IconData, String) get _activeToolOption => _canvasToolOptions
      .firstWhere((option) => option.$1 == controller.activeTool);

  String get _activeToolSummary => switch (controller.activeTool) {
    CanvasTool.pen => '${controller.penWidth.toStringAsFixed(0)} pt',
    CanvasTool.eraser =>
      '${controller.eraserRadius.round()} ${controller.eraserMode == EraserMode.object ? 'whole' : 'split'}',
    CanvasTool.lasso => switch (controller.selectionMode) {
      SelectionMode.replace => 'Select',
      SelectionMode.add => 'Add next',
      SelectionMode.subtract => 'Remove next',
    },
    CanvasTool.shape => switch (controller.shapeKind) {
      ShapeKind.line => 'Line',
      ShapeKind.rectangle => 'Rectangle',
      ShapeKind.oval => 'Oval',
      ShapeKind.arrow => 'Arrow',
    },
    CanvasTool.pan => _zoomLabel(controller.viewport.scale),
    CanvasTool.text => 'Text',
    CanvasTool.link => 'Link',
  };

  _WheelPage get _effectiveWheelPage =>
      wheelPage == _WheelPage.selection && !controller.hasSelection
      ? _WheelPage.tools
      : wheelPage;

  List<_WheelAction> _wheelActions(BuildContext context) =>
      switch (_effectiveWheelPage) {
        _WheelPage.tools => _toolWheelActions(),
        _WheelPage.context => _contextWheelActions(context),
        _WheelPage.selection when controller.hasSelection =>
          _selectionWheelActions(),
        _WheelPage.selection => _toolWheelActions(),
        _WheelPage.more => _moreWheelActions(context),
        _WheelPage.insert => _insertWheelActions(context),
        _WheelPage.appearance => _appearanceWheelActions(context),
        _WheelPage.view => _viewWheelActions(context),
      };

  IconData get _wheelCenterIcon => switch (_effectiveWheelPage) {
    _WheelPage.tools when controller.hasSelection => Icons.select_all,
    _WheelPage.tools => _activeToolOption.$2,
    _WheelPage.context ||
    _WheelPage.selection ||
    _WheelPage.more => Icons.apps_rounded,
    _WheelPage.insert ||
    _WheelPage.appearance ||
    _WheelPage.view => Icons.more_horiz,
  };

  String get _wheelCenterLabel => switch (_effectiveWheelPage) {
    _WheelPage.tools when controller.hasSelection => _selectionCountLabel,
    _WheelPage.tools => _activeToolSummary,
    _WheelPage.context || _WheelPage.selection || _WheelPage.more => 'Tools',
    _WheelPage.insert || _WheelPage.appearance || _WheelPage.view => 'More',
  };

  String get _wheelCenterTooltip => switch (_effectiveWheelPage) {
    _WheelPage.tools when controller.hasSelection => 'Selection actions',
    _WheelPage.tools => '${_activeToolOption.$3} settings',
    _WheelPage.context ||
    _WheelPage.selection ||
    _WheelPage.more => 'Show drawing tools',
    _WheelPage.insert ||
    _WheelPage.appearance ||
    _WheelPage.view => 'Back to more actions',
  };

  List<_WheelAction> _toolWheelActions() {
    const tools = <(CanvasTool, IconData, String)>[
      (CanvasTool.pen, Icons.draw_outlined, 'Draw'),
      (CanvasTool.eraser, Icons.cleaning_services_outlined, 'Eraser'),
      (CanvasTool.lasso, Icons.gesture, 'Lasso select'),
      (CanvasTool.shape, Icons.category_outlined, 'Shapes'),
      (CanvasTool.text, Icons.notes_outlined, 'Text note'),
      (CanvasTool.link, Icons.add_link, 'Place a link'),
      (CanvasTool.pan, Icons.pan_tool_alt_outlined, 'Pan'),
    ];
    return <_WheelAction>[
      for (final (tool, icon, label) in tools)
        _WheelAction(
          key: ValueKey<String>('$toolButtonKeyPrefix-$tool'),
          icon: icon,
          label: label,
          selected: controller.activeTool == tool,
          onTap: () {
            if (controller.activeTool == tool) {
              onWheelPageChanged(
                controller.hasSelection
                    ? _WheelPage.selection
                    : _WheelPage.context,
              );
            } else {
              controller.setTool(tool);
            }
          },
        ),
      _WheelAction(
        key: canvasSettingsDockKey,
        icon: Icons.more_horiz,
        label: 'More canvas actions',
        onTap: () => onWheelPageChanged(_WheelPage.more),
      ),
    ];
  }

  String get _selectionCountLabel {
    final int count = controller.selectedIds.length;
    return count == 1 ? '1 selected' : '$count selected';
  }

  List<_WheelAction> _selectionWheelActions() {
    return <_WheelAction>[
      _WheelAction(
        icon: Icons.check,
        label: 'Done selecting',
        onTap: controller.clearSelection,
      ),
      _WheelAction(
        icon: Icons.delete_outline,
        label: 'Delete selection',
        destructive: true,
        onTap: controller.deleteSelection,
      ),
      _WheelAction(
        icon: Icons.add_circle_outline,
        label: 'Add to selection once',
        selected: controller.selectionMode == SelectionMode.add,
        onTap: () => controller.setSelectionMode(SelectionMode.add),
      ),
      _WheelAction(
        icon: Icons.remove_circle_outline,
        label: 'Remove from selection once',
        selected: controller.selectionMode == SelectionMode.subtract,
        onTap: () => controller.setSelectionMode(SelectionMode.subtract),
      ),
      _WheelAction(
        icon: Icons.rotate_left,
        label: 'Rotate selection left',
        onTap: () => controller.rotateSelection(-_rotationStep),
      ),
      _WheelAction(
        icon: Icons.rotate_right,
        label: 'Rotate selection right',
        onTap: () => controller.rotateSelection(_rotationStep),
      ),
      _WheelAction(
        icon: Icons.zoom_in_map,
        label: 'Scale selection down',
        onTap: () => controller.scaleSelection(1 / 1.1, 1 / 1.1),
      ),
      _WheelAction(
        icon: Icons.zoom_out_map,
        label: 'Scale selection up',
        onTap: () => controller.scaleSelection(1.1, 1.1),
      ),
    ];
  }

  List<_WheelAction> _moreWheelActions(BuildContext context) {
    return <_WheelAction>[
      _WheelAction(
        icon: Icons.undo,
        label: 'Undo',
        onTap: controller.canUndo ? controller.undo : null,
      ),
      _WheelAction(
        icon: Icons.redo,
        label: 'Redo',
        onTap: controller.canRedo ? controller.redo : null,
      ),
      _WheelAction(
        icon: controller.isImporting ? Icons.hourglass_top : Icons.add,
        label: controller.isImporting ? 'Importing' : 'Insert',
        onTap: controller.isImporting
            ? null
            : () => onWheelPageChanged(_WheelPage.insert),
      ),
      _WheelAction(
        icon: Icons.layers_outlined,
        label: 'Layers',
        onTap: () => _runMoreAction(context, _MoreAction.layers),
      ),
      _WheelAction(
        icon: Icons.file_download_outlined,
        label: 'Export',
        onTap: () => _runMoreAction(context, _MoreAction.export),
      ),
      _WheelAction(
        icon: Icons.palette_outlined,
        label: 'Appearance',
        onTap: () => onWheelPageChanged(_WheelPage.appearance),
      ),
      _WheelAction(
        icon: Icons.tune,
        label: 'View and gestures',
        onTap: () => onWheelPageChanged(_WheelPage.view),
      ),
      _WheelAction(
        icon: Icons.delete_sweep_outlined,
        label: 'Clear canvas',
        destructive: true,
        onTap: controller.elements.isEmpty
            ? null
            : () => _runMoreAction(context, _MoreAction.clear),
      ),
    ];
  }

  List<_WheelAction> _insertWheelActions(BuildContext context) {
    return <_WheelAction>[
      _WheelAction(
        key: importImageKey,
        icon: Icons.image_outlined,
        label: 'Insert image',
        onTap: controller.isImporting
            ? null
            : () => _runMoreAction(context, _MoreAction.image),
      ),
      _WheelAction(
        key: importPdfKey,
        icon: Icons.picture_as_pdf_outlined,
        label: 'Insert PDF',
        onTap: controller.isImporting
            ? null
            : () => _runMoreAction(context, _MoreAction.pdf),
      ),
    ];
  }

  List<_WheelAction> _appearanceWheelActions(BuildContext context) {
    return <_WheelAction>[
      _WheelAction(
        icon: Icons.palette_outlined,
        label: 'Edit palette',
        onTap: onPaletteChanged == null
            ? null
            : () => _runMoreAction(context, _MoreAction.palette),
      ),
      _WheelAction(
        icon: Icons.wallpaper_outlined,
        label: 'Paper',
        onTap: () => _runMoreAction(context, _MoreAction.paper),
      ),
    ];
  }

  List<_WheelAction> _viewWheelActions(BuildContext context) {
    return <_WheelAction>[
      _WheelAction(
        icon: controller.snapToGridEnabled
            ? Icons.grid_on
            : Icons.grid_off_outlined,
        label: controller.snapToGridEnabled
            ? 'Disable snap to grid'
            : 'Enable snap to grid',
        selected: controller.snapToGridEnabled,
        onTap: () => _runMoreAction(context, _MoreAction.snap),
      ),
      _WheelAction(
        icon: controller.rotationLocked
            ? Icons.lock_outline
            : Icons.lock_open_outlined,
        label: controller.rotationLocked ? 'Unlock rotation' : 'Lock rotation',
        selected: controller.rotationLocked,
        onTap: () => _runMoreAction(context, _MoreAction.rotationLock),
      ),
      _WheelAction(
        icon: Icons.screen_rotation_alt_outlined,
        label: 'Reset rotation',
        onTap: () => _runMoreAction(context, _MoreAction.resetRotation),
      ),
      _WheelAction(
        icon: Icons.fit_screen_outlined,
        label: 'Fit content',
        onTap: controller.contentBounds == null
            ? null
            : () => _runMoreAction(context, _MoreAction.fit),
      ),
      _WheelAction(
        icon: Icons.center_focus_strong,
        label: 'Reset view',
        onTap: () => _runMoreAction(context, _MoreAction.resetView),
      ),
      _WheelAction(
        key: CanvasToolbar.gestureGuideKey,
        icon: Icons.gesture_outlined,
        label: 'Gesture shortcuts',
        onTap: () => _runMoreAction(context, _MoreAction.gestureGuide),
      ),
    ];
  }

  List<_WheelAction> _contextWheelActions(BuildContext context) {
    return switch (controller.activeTool) {
      CanvasTool.pen => <_WheelAction>[
        for (final (kind, icon, label)
            in const <(StrokeToolKind, IconData, String)>[
              (StrokeToolKind.pen, Icons.brush_outlined, 'Pen'),
              (StrokeToolKind.pencil, Icons.edit_outlined, 'Pencil'),
              (
                StrokeToolKind.highlighter,
                Icons.highlight_outlined,
                'Highlighter',
              ),
              (
                StrokeToolKind.marker,
                Icons.format_color_fill_outlined,
                'Marker',
              ),
              (StrokeToolKind.airbrush, Icons.blur_on_outlined, 'Airbrush'),
            ])
          _WheelAction(
            icon: icon,
            label: label,
            selected: controller.penKind == kind,
            onTap: () => _setPenKind(kind),
          ),
        _WheelAction(
          icon: Icons.remove,
          label: 'Thinner',
          onTap: () => _stepPenWidth(-1),
        ),
        _WheelAction(
          icon: Icons.add,
          label: 'Thicker',
          onTap: () => _stepPenWidth(1),
        ),
        _WheelAction(
          icon: Icons.aspect_ratio,
          label: controller.penWidthMode == PenWidthMode.screen
              ? 'Screen width'
              : 'Canvas width',
          selected: controller.penWidthMode == PenWidthMode.screen,
          onTap: () => controller.setPenWidthMode(
            controller.penWidthMode == PenWidthMode.screen
                ? PenWidthMode.canvas
                : PenWidthMode.screen,
          ),
        ),
      ],
      CanvasTool.eraser => <_WheelAction>[
        _WheelAction(
          icon: Icons.delete_sweep_outlined,
          label: 'Erase whole strokes',
          selected: controller.eraserMode == EraserMode.object,
          onTap: () => controller.setEraserMode(EraserMode.object),
        ),
        _WheelAction(
          icon: Icons.content_cut,
          label: 'Split strokes',
          selected: controller.eraserMode == EraserMode.partial,
          onTap: () => controller.setEraserMode(EraserMode.partial),
        ),
        for (final radius in const <double>[8, 16, 32, 48, 64])
          _WheelAction(
            icon: Icons.circle_outlined,
            label: 'Eraser ${radius.round()}',
            selected: controller.eraserRadius.round() == radius.round(),
            onTap: () => controller.setEraserRadius(radius),
          ),
      ],
      CanvasTool.lasso => <_WheelAction>[
        _selectionWheelAction(
          SelectionMode.replace,
          Icons.select_all,
          'Start a new selection',
        ),
        _selectionWheelAction(
          SelectionMode.add,
          Icons.add_circle_outline,
          'Add to selection once',
        ),
        _selectionWheelAction(
          SelectionMode.subtract,
          Icons.remove_circle_outline,
          'Remove from selection once',
        ),
        _WheelAction(
          icon: Icons.close,
          label: 'Clear selection',
          onTap: controller.hasSelection ? controller.clearSelection : null,
        ),
        _WheelAction(
          icon: Icons.center_focus_strong,
          label: 'Frame selection',
          onTap: controller.hasSelection ? controller.fitSelection : null,
        ),
        _WheelAction(
          icon: Icons.delete_outline,
          label: 'Delete selection',
          destructive: true,
          onTap: controller.hasSelection ? controller.deleteSelection : null,
        ),
      ],
      CanvasTool.shape => <_WheelAction>[
        _shapeWheelAction(ShapeKind.line, Icons.horizontal_rule, 'Line'),
        _shapeWheelAction(ShapeKind.rectangle, Icons.crop_square, 'Rectangle'),
        _shapeWheelAction(ShapeKind.oval, Icons.circle_outlined, 'Oval'),
        _shapeWheelAction(ShapeKind.arrow, Icons.arrow_right_alt, 'Arrow'),
        _WheelAction(
          icon: Icons.remove,
          label: 'Thinner',
          onTap: () => _stepPenWidth(-1),
        ),
        _WheelAction(
          icon: Icons.add,
          label: 'Thicker',
          onTap: () => _stepPenWidth(1),
        ),
        if (controller.shapeKind == ShapeKind.arrow)
          _WheelAction(
            icon: Icons.tune,
            label: 'Arrow style',
            onTap: () => _showArrowStyle(context),
          ),
      ],
      CanvasTool.pan => <_WheelAction>[
        _WheelAction(
          icon: Icons.zoom_out,
          label: 'Zoom out',
          onTap: () => controller.zoomBy(1 / 1.2),
        ),
        _WheelAction(
          icon: Icons.zoom_in,
          label: 'Zoom in',
          onTap: () => controller.zoomBy(1.2),
        ),
        _WheelAction(
          icon: Icons.filter_1_outlined,
          label: 'Zoom to 100%',
          onTap: controller.zoomTo100,
        ),
        _WheelAction(
          icon: Icons.fit_screen_outlined,
          label: 'Fit content',
          onTap: controller.contentBounds == null
              ? null
              : controller.fitContent,
        ),
        _WheelAction(
          icon: Icons.center_focus_strong,
          label: 'Reset view',
          onTap: controller.resetView,
        ),
        _WheelAction(
          icon: controller.rotationLocked
              ? Icons.lock_outline
              : Icons.lock_open_outlined,
          label: controller.rotationLocked
              ? 'Unlock rotation'
              : 'Lock rotation',
          selected: controller.rotationLocked,
          onTap: controller.toggleRotationLock,
        ),
        _WheelAction(
          icon: Icons.screen_rotation_alt_outlined,
          label: 'Reset rotation',
          onTap: controller.resetRotation,
        ),
      ],
      CanvasTool.text => <_WheelAction>[
        _WheelAction(
          icon: Icons.palette_outlined,
          label: 'Edit palette',
          onTap: onPaletteChanged == null
              ? null
              : () => _showPaletteEditor(
                  context,
                  palette.isEmpty ? _defaultSwatches : palette,
                ),
        ),
        _WheelAction(
          icon: Icons.tune,
          label: 'Text settings',
          onTap: () => _showToolSettings(context),
        ),
      ],
      CanvasTool.link => <_WheelAction>[
        _WheelAction(
          icon: Icons.info_outline,
          label: 'Link help',
          onTap: () => _showToolSettings(context),
        ),
      ],
    };
  }

  _WheelAction _selectionWheelAction(
    SelectionMode mode,
    IconData icon,
    String label,
  ) {
    return _WheelAction(
      icon: icon,
      label: label,
      selected: controller.selectionMode == mode,
      onTap: () => controller.setSelectionMode(mode),
    );
  }

  _WheelAction _shapeWheelAction(ShapeKind kind, IconData icon, String label) {
    return _WheelAction(
      icon: icon,
      label: label,
      selected: controller.shapeKind == kind,
      onTap: () => controller.setShapeKind(kind),
    );
  }

  void _stepPenWidth(int direction) {
    var closest = 0;
    var distance = double.infinity;
    for (var index = 0; index < _widths.length; index++) {
      final nextDistance = (controller.penWidth - _widths[index]).abs();
      if (nextDistance < distance) {
        closest = index;
        distance = nextDistance;
      }
    }
    final next = (closest + direction).clamp(0, _widths.length - 1);
    controller.setPenWidth(_widths[next]);
  }

  Future<void> _showToolSettings(BuildContext context) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.12),
      transitionDuration: const Duration(milliseconds: 140),
      pageBuilder: (context, animation, secondaryAnimation) {
        return SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double top = constraints.maxHeight >= 560 ? 244 : 76;
              return Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(12, top, 12, 12),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: math.min(440, constraints.maxWidth - 24),
                      maxHeight: math.max(
                        160,
                        constraints.maxHeight - top - 12,
                      ),
                    ),
                    child: _FloatingSurface(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: ListenableBuilder(
                          listenable: controller,
                          builder: (context, _) => Wrap(
                            key: controller.activeTool == CanvasTool.pen
                                ? penDockKey
                                : null,
                            spacing: 4,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: <Widget>[
                              ..._activeToolProperties(context),
                              if (controller.hasSelection) ...[
                                const _DockDivider(),
                                ..._selectionProperties(),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(opacity: curved, child: child);
      },
    );
  }

  List<Widget> _activeToolProperties(BuildContext context) {
    return switch (controller.activeTool) {
      CanvasTool.pan => const <Widget>[
        _ContextLabel(icon: Icons.pan_tool_alt_outlined, label: 'Pan'),
        _ContextHint('Drag to move the canvas'),
      ],
      CanvasTool.pen => <Widget>[
        const _ContextLabel(icon: Icons.draw_outlined, label: 'Pen'),
        const _DockDivider(),
        ..._penKindButtons(),
        const _DockDivider(),
        _widthPicker(),
        const _DockDivider(),
        ..._swatches(context),
        const _DockDivider(),
        _HudButton(
          icon: controller.pressureEnabled ? Icons.speed : Icons.speed_outlined,
          tooltip: controller.pressureEnabled
              ? 'Disable pressure'
              : 'Enable pressure',
          selected: controller.pressureEnabled,
          onPressed: () => controller.setPressureEnabled(
            enabled: !controller.pressureEnabled,
          ),
        ),
        _widthModePicker(),
      ],
      CanvasTool.eraser => <Widget>[
        const _ContextLabel(
          icon: Icons.cleaning_services_outlined,
          label: 'Eraser',
        ),
        const _DockDivider(),
        _HudButton(
          icon: Icons.delete_sweep_outlined,
          tooltip: 'Erase whole strokes',
          selected: controller.eraserMode == EraserMode.object,
          onPressed: () => controller.setEraserMode(EraserMode.object),
        ),
        _HudButton(
          icon: Icons.content_cut,
          tooltip: 'Split strokes',
          selected: controller.eraserMode == EraserMode.partial,
          onPressed: () => controller.setEraserMode(EraserMode.partial),
        ),
        const _DockDivider(),
        const _ContextHint('Size'),
        SizedBox(
          width: 180,
          child: Slider(
            value: controller.eraserRadius.clamp(4, 64),
            min: 4,
            max: 64,
            divisions: 15,
            label: controller.eraserRadius.round().toString(),
            onChanged: controller.setEraserRadius,
          ),
        ),
        _HudLabel(controller.eraserRadius.round().toString()),
      ],
      CanvasTool.lasso => <Widget>[
        const _ContextLabel(icon: Icons.gesture, label: 'Select'),
        const _DockDivider(),
        _selectionModeButton(
          SelectionMode.replace,
          Icons.select_all,
          'Start a new selection',
        ),
        _selectionModeButton(
          SelectionMode.add,
          Icons.add_circle_outline,
          'Add to selection once',
        ),
        _selectionModeButton(
          SelectionMode.subtract,
          Icons.remove_circle_outline,
          'Remove from selection once',
        ),
      ],
      CanvasTool.shape => <Widget>[
        const _ContextLabel(icon: Icons.category_outlined, label: 'Shape'),
        const _DockDivider(),
        _shapeButton(ShapeKind.line, Icons.horizontal_rule, 'Line'),
        _shapeButton(ShapeKind.rectangle, Icons.crop_square, 'Rectangle'),
        _shapeButton(ShapeKind.oval, Icons.circle_outlined, 'Oval'),
        _shapeButton(ShapeKind.arrow, Icons.arrow_right_alt, 'Arrow'),
        if (controller.shapeKind == ShapeKind.arrow)
          _HudButton(
            icon: Icons.tune,
            tooltip: 'Arrow style',
            onPressed: () => _showArrowStyle(context),
          ),
        const _DockDivider(),
        _widthPicker(),
        const _DockDivider(),
        ..._swatches(context),
      ],
      CanvasTool.text => <Widget>[
        const _ContextLabel(icon: Icons.notes_outlined, label: 'Text'),
        const _ContextHint('Tap to place or edit'),
        const _DockDivider(),
        ..._swatches(context),
      ],
      CanvasTool.link => const <Widget>[
        _ContextLabel(icon: Icons.add_link, label: 'Link'),
        _ContextHint('Tap to place a canvas link'),
      ],
    };
  }

  List<Widget> _penKindButtons() {
    return <Widget>[
      _PenKindButton(
        icon: Icons.brush_outlined,
        tooltip: 'Pen',
        selected: controller.penKind == StrokeToolKind.pen,
        onPressed: () => _setPenKind(StrokeToolKind.pen),
      ),
      _PenKindButton(
        icon: Icons.edit_outlined,
        tooltip: 'Pencil',
        selected: controller.penKind == StrokeToolKind.pencil,
        onPressed: () => _setPenKind(StrokeToolKind.pencil),
      ),
      _PenKindButton(
        icon: Icons.highlight_outlined,
        tooltip: 'Highlighter',
        selected: controller.penKind == StrokeToolKind.highlighter,
        onPressed: () => _setPenKind(StrokeToolKind.highlighter),
      ),
      _PenKindButton(
        icon: Icons.format_color_fill_outlined,
        tooltip: 'Marker',
        selected: controller.penKind == StrokeToolKind.marker,
        onPressed: () => _setPenKind(StrokeToolKind.marker),
      ),
      _PenKindButton(
        icon: Icons.blur_on_outlined,
        tooltip: 'Airbrush',
        selected: controller.penKind == StrokeToolKind.airbrush,
        onPressed: () => _setPenKind(StrokeToolKind.airbrush),
      ),
    ];
  }

  void _setPenKind(StrokeToolKind kind) {
    controller
      ..setTool(CanvasTool.pen)
      ..setPenKind(kind);
  }

  List<Widget> _selectionProperties() {
    return <Widget>[
      const _ContextLabel(icon: Icons.select_all, label: 'Selection'),
      _HudButton(
        icon: Icons.center_focus_strong,
        tooltip: 'Frame selection',
        onPressed: controller.fitSelection,
      ),
      _nudgeMenu(),
      _HudButton(
        icon: Icons.rotate_left,
        tooltip: 'Rotate selection left',
        onPressed: () => controller.rotateSelection(-_rotationStep),
      ),
      _HudButton(
        icon: Icons.rotate_right,
        tooltip: 'Rotate selection right',
        onPressed: () => controller.rotateSelection(_rotationStep),
      ),
      _HudButton(
        icon: Icons.zoom_in_map,
        tooltip: 'Scale selection down',
        onPressed: () => controller.scaleSelection(1 / 1.1, 1 / 1.1),
      ),
      _HudButton(
        icon: Icons.zoom_out_map,
        tooltip: 'Scale selection up',
        onPressed: () => controller.scaleSelection(1.1, 1.1),
      ),
      _HudButton(
        icon: Icons.close,
        tooltip: 'Clear selection',
        onPressed: controller.clearSelection,
      ),
      _HudButton(
        icon: Icons.delete_outline,
        tooltip: 'Delete selection',
        destructive: true,
        onPressed: controller.deleteSelection,
      ),
    ];
  }

  Widget _selectionModeButton(
    SelectionMode mode,
    IconData icon,
    String tooltip,
  ) {
    return _HudButton(
      icon: icon,
      tooltip: tooltip,
      selected: controller.selectionMode == mode,
      onPressed: () => controller.setSelectionMode(mode),
    );
  }

  double _nudgeStep(CanvasController controller) {
    return 8 / controller.viewport.scale;
  }

  Widget _shapeButton(ShapeKind kind, IconData icon, String tooltip) {
    return _HudButton(
      icon: icon,
      tooltip: tooltip,
      selected: controller.shapeKind == kind,
      onPressed: () => controller.setShapeKind(kind),
    );
  }

  Widget _widthPicker() {
    return PopupMenuButton<double>(
      tooltip: 'Width ${controller.penWidth.toStringAsFixed(0)}',
      initialValue: controller.penWidth,
      onSelected: controller.setPenWidth,
      itemBuilder: (context) => <PopupMenuEntry<double>>[
        for (final double width in _widths)
          PopupMenuItem<double>(
            key: ValueKey<String>('$widthButtonKeyPrefix-$width'),
            value: width,
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Center(
                    child: Container(
                      width: 32,
                      height: width.clamp(1, 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurface,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(width.toStringAsFixed(0)),
              ],
            ),
          ),
      ],
      child: _ToolbarValueButton(
        icon: Icons.line_weight,
        label: controller.penWidth.toStringAsFixed(0),
      ),
    );
  }

  Widget _widthModePicker() {
    final String label = controller.penWidthMode == PenWidthMode.screen
        ? 'Screen'
        : 'Canvas';
    return PopupMenuButton<PenWidthMode>(
      tooltip: 'Width behavior: $label',
      initialValue: controller.penWidthMode,
      onSelected: controller.setPenWidthMode,
      itemBuilder: (context) => <PopupMenuEntry<PenWidthMode>>[
        PopupMenuItem<PenWidthMode>(
          key: ValueKey<String>(
            '$penWidthModeButtonKeyPrefix-${PenWidthMode.screen}',
          ),
          value: PenWidthMode.screen,
          child: const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.aspect_ratio),
            title: Text('Screen width'),
            subtitle: Text('Looks the same size while zooming'),
          ),
        ),
        PopupMenuItem<PenWidthMode>(
          key: ValueKey<String>(
            '$penWidthModeButtonKeyPrefix-${PenWidthMode.canvas}',
          ),
          value: PenWidthMode.canvas,
          child: const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.draw_outlined),
            title: Text('Canvas width'),
            subtitle: Text('Scales with the canvas'),
          ),
        ),
      ],
      child: _ToolbarValueButton(icon: Icons.straighten, label: label),
    );
  }

  List<Widget> _swatches(BuildContext context) {
    final colors = palette.isEmpty ? _defaultSwatches : palette;
    return <Widget>[
      for (var i = 0; i < colors.length; i++)
        _SwatchButton(
          key: ValueKey<String>('$swatchButtonKeyPrefix-$i'),
          color: Color(colors[i]),
          selected: controller.penColor == colors[i],
          onTap: () => controller.setPenColor(colors[i]),
        ),
      _HudButton(
        icon: Icons.palette_outlined,
        tooltip: 'Edit palette',
        onPressed: onPaletteChanged == null
            ? null
            : () => _showPaletteEditor(context, colors),
      ),
    ];
  }

  Widget _nudgeMenu() {
    return PopupMenuButton<_NudgeAction>(
      tooltip: 'Move selection',
      onSelected: (action) {
        final double step = _nudgeStep(controller);
        controller.nudgeSelection(switch (action) {
          _NudgeAction.left => Offset(-step, 0),
          _NudgeAction.up => Offset(0, -step),
          _NudgeAction.down => Offset(0, step),
          _NudgeAction.right => Offset(step, 0),
        });
      },
      itemBuilder: (context) => const <PopupMenuEntry<_NudgeAction>>[
        PopupMenuItem(value: _NudgeAction.left, child: Text('Move left')),
        PopupMenuItem(value: _NudgeAction.up, child: Text('Move up')),
        PopupMenuItem(value: _NudgeAction.down, child: Text('Move down')),
        PopupMenuItem(value: _NudgeAction.right, child: Text('Move right')),
      ],
      child: const _ToolbarValueButton(icon: Icons.open_with, label: 'Move'),
    );
  }

  Future<void> _showPaletteEditor(
    BuildContext context,
    List<int> colors,
  ) async {
    final next = await showDialog<List<int>>(
      context: context,
      builder: (context) => _PaletteDialog(initialColors: colors),
    );
    if (next != null) {
      onPaletteChanged?.call(next);
    }
  }

  Future<void> _showPaperSettings(BuildContext context) async {
    final next = await showGeneralDialog<CanvasPaperStyle>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.10),
      transitionDuration: const Duration(milliseconds: 140),
      pageBuilder: (context, animation, secondaryAnimation) {
        final size = MediaQuery.sizeOf(context);
        final maxWidth = (size.width - 36).clamp(320.0, 520.0).toDouble();
        final maxHeight = (size.height - 36).clamp(360.0, 720.0).toDouble();
        return SafeArea(
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 18, top: 18),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                  maxHeight: maxHeight,
                ),
                child: _PaperDialog(initial: controller.paperStyle),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1).animate(curved),
            alignment: Alignment.topLeft,
            child: child,
          ),
        );
      },
    );
    if (next != null) {
      controller.setPaperStyle(next);
    }
  }

  Future<void> _showLayerPanel(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => _LayerDialog(controller: controller),
    );
  }

  Future<void> _showArrowStyle(BuildContext context) async {
    final next = await showDialog<_ArrowStyleDraft>(
      context: context,
      builder: (context) => _ArrowStyleDialog(
        initial: _ArrowStyleDraft(
          body: controller.arrowBody,
          startHead: controller.arrowStartHead,
          endHead: controller.arrowEndHead,
          headScale: controller.arrowHeadScale,
        ),
      ),
    );
    if (next != null) {
      controller.setArrowStyle(
        body: next.body,
        startHead: next.startHead,
        endHead: next.endHead,
        headScale: next.headScale,
      );
    }
  }

  Future<void> _showExportDialog(BuildContext context) async {
    final options = await showDialog<CanvasExportOptions>(
      context: context,
      builder: (context) => _ExportDialog(
        hasSelection: controller.hasSelection,
        hasContent: controller.contentBounds != null,
      ),
    );
    if (options == null || !context.mounted) {
      return;
    }
    final NavigatorState navigator = Navigator.of(context, rootNavigator: true);
    final Route<void> progressRoute = DialogRoute<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PopScope<void>(
        canPop: false,
        child: AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              SizedBox(width: 16),
              Text('Exporting...'),
            ],
          ),
        ),
      ),
    );
    var progressVisible = true;
    unawaited(navigator.push(progressRoute));
    void closeProgress() {
      if (!progressVisible) return;
      progressVisible = false;
      if (navigator.mounted) navigator.removeRoute(progressRoute);
    }

    try {
      final result = await CanvasExportService.exportToFile(
        controller: controller,
        options: options,
      );
      closeProgress();
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Exported ${result.options.format.extension.toUpperCase()} to ${result.filePath}',
          ),
        ),
      );
    } on CanvasExportException catch (error) {
      closeProgress();
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      closeProgress();
    }
  }
}

enum _SaveAction { retry, dismiss }

enum _InsertAction { image, pdf }

enum _WheelPage { tools, context, selection, more, insert, appearance, view }

enum _MoreAction {
  image,
  pdf,
  layers,
  export,
  paper,
  snap,
  rotationLock,
  resetRotation,
  fit,
  resetView,
  palette,
  gestureGuide,
  clear,
}

enum _QuickMenuAction { contextSettings }

enum _NudgeAction { left, up, down, right }

/// Opens the same radial tool language at a stylus side-button tap.
Future<void> showCanvasQuickToolMenuAt({
  required BuildContext context,
  required CanvasController controller,
  required Offset overlayPosition,
  required VoidCallback onShowFullControls,
}) async {
  final RenderBox? overlay =
      Overlay.of(context).context.findRenderObject() as RenderBox?;
  if (overlay == null || !overlay.hasSize) {
    return;
  }
  const double wheelSize = 176;
  final Object? action = await showGeneralDialog<Object>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 100),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      final double left = (overlayPosition.dx - wheelSize / 2).clamp(
        8,
        math.max(8, overlay.size.width - wheelSize - 8),
      );
      final double top = (overlayPosition.dy - wheelSize / 2).clamp(
        8,
        math.max(8, overlay.size.height - wheelSize - 8),
      );
      const tools = <(CanvasTool, IconData, String)>[
        (CanvasTool.pen, Icons.draw_outlined, 'Draw'),
        (CanvasTool.eraser, Icons.cleaning_services_outlined, 'Eraser'),
        (CanvasTool.lasso, Icons.gesture, 'Lasso select'),
        (CanvasTool.shape, Icons.category_outlined, 'Shapes'),
        (CanvasTool.text, Icons.notes_outlined, 'Text note'),
        (CanvasTool.link, Icons.add_link, 'Place a link'),
        (CanvasTool.pan, Icons.pan_tool_alt_outlined, 'Pan'),
      ];
      return Stack(
        children: [
          Positioned(
            left: left,
            top: top,
            width: wheelSize,
            height: wheelSize,
            child: Material(
              type: MaterialType.transparency,
              child: _RadialWheel(
                actions: <_WheelAction>[
                  for (final (tool, icon, label) in tools)
                    _WheelAction(
                      icon: icon,
                      label: label,
                      selected: controller.activeTool == tool,
                      onTap: () => Navigator.of(dialogContext).pop(tool),
                    ),
                ],
                activeColor: Color(controller.penColor),
                centerIcon: Icons.tune,
                centerLabel: 'Settings',
                centerTooltip: 'Show tool settings',
                centerKey: CanvasToolbar.showFullControlsKey,
                onCenterTap: () => Navigator.of(
                  dialogContext,
                ).pop(_QuickMenuAction.contextSettings),
              ),
            ),
          ),
        ],
      );
    },
  );
  if (action != null && context.mounted) {
    if (action is CanvasTool) {
      controller.setTool(action);
    } else if (action == _QuickMenuAction.contextSettings) {
      onShowFullControls();
    }
  }
}

String _zoomLabel(double scale) {
  if (scale >= 100) {
    return '${scale.round()}x';
  }
  if (scale >= 10) {
    return '${scale.toStringAsFixed(1)}x';
  }
  if (scale > 0 && scale < 0.0001) {
    return '1:${(1 / scale).round()}';
  }
  final double percent = scale * 100;
  if (percent >= 10) {
    return '${percent.round()}%';
  }
  if (percent >= 1) {
    return '${percent.toStringAsFixed(1)}%';
  }
  return '${percent.toStringAsFixed(2)}%';
}

class _ArrowStyleDraft {
  const _ArrowStyleDraft({
    required this.body,
    required this.startHead,
    required this.endHead,
    required this.headScale,
  });

  final ArrowBodyKind body;
  final ArrowHeadStyle startHead;
  final ArrowHeadStyle endHead;
  final double headScale;
}

class _ArrowStyleDialog extends StatefulWidget {
  const _ArrowStyleDialog({required this.initial});

  final _ArrowStyleDraft initial;

  @override
  State<_ArrowStyleDialog> createState() => _ArrowStyleDialogState();
}

class _ArrowStyleDialogState extends State<_ArrowStyleDialog> {
  late ArrowBodyKind _body = widget.initial.body;
  late ArrowHeadStyle _startHead = widget.initial.startHead;
  late ArrowHeadStyle _endHead = widget.initial.endHead;
  late double _headScale = widget.initial.headScale;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Arrow style'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<ArrowBodyKind>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: ArrowBodyKind.straight,
                  icon: Icon(Icons.horizontal_rule),
                ),
                ButtonSegment(
                  value: ArrowBodyKind.curved,
                  icon: Icon(Icons.timeline),
                ),
                ButtonSegment(
                  value: ArrowBodyKind.elbow,
                  icon: Icon(Icons.turn_right),
                ),
                ButtonSegment(
                  value: ArrowBodyKind.sketch,
                  icon: Icon(Icons.gesture),
                ),
              ],
              selected: {_body},
              onSelectionChanged: (value) =>
                  setState(() => _body = value.first),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final head in ArrowHeadStyle.values)
                  ChoiceChip(
                    label: Text(_headLabel(head)),
                    selected: _endHead == head,
                    onSelected: (_) => setState(() => _endHead = head),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Double headed'),
              value: _startHead != ArrowHeadStyle.none,
              onChanged: (value) => setState(() {
                _startHead = value
                    ? (_endHead == ArrowHeadStyle.none
                          ? ArrowHeadStyle.open
                          : _endHead)
                    : ArrowHeadStyle.none;
              }),
            ),
            Slider(
              value: _headScale.clamp(0.5, 2.0),
              min: 0.5,
              max: 2.0,
              divisions: 6,
              label: '${_headScale.toStringAsFixed(1)}x',
              onChanged: (value) => setState(() => _headScale = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            _ArrowStyleDraft(
              body: _body,
              startHead: _startHead,
              endHead: _endHead,
              headScale: _headScale,
            ),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }

  static String _headLabel(ArrowHeadStyle style) {
    return switch (style) {
      ArrowHeadStyle.none => 'None',
      ArrowHeadStyle.open => 'Open',
      ArrowHeadStyle.filled => 'Filled',
      ArrowHeadStyle.dot => 'Dot',
      ArrowHeadStyle.diamond => 'Diamond',
      ArrowHeadStyle.bar => 'Bar',
    };
  }
}

class _LayerDialog extends StatelessWidget {
  const _LayerDialog({required this.controller});

  final CanvasController controller;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Layers'),
      content: SizedBox(
        width: 420,
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final layers = controller.layers;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final layer in layers)
                  _LayerRow(
                    layer: layer,
                    active: controller.activeLayerId == layer.id,
                    onActivate: layer.isEditable
                        ? () => controller.setActiveLayer(layer.id)
                        : null,
                    onToggleVisible: () => controller.setLayerVisible(
                      layer.id,
                      visible: !layer.visible,
                    ),
                    onToggleLocked: () => controller.setLayerLocked(
                      layer.id,
                      locked: !layer.locked,
                    ),
                    onMoveBack: () => controller.moveLayer(layer.id, -1),
                    onMoveForward: () => controller.moveLayer(layer.id, 1),
                  ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () => controller.addLayer(),
          icon: const Icon(Icons.add),
          label: const Text('Add'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class _LayerRow extends StatelessWidget {
  const _LayerRow({
    required this.layer,
    required this.active,
    required this.onActivate,
    required this.onToggleVisible,
    required this.onToggleLocked,
    required this.onMoveBack,
    required this.onMoveForward,
  });

  final CanvasLayer layer;
  final bool active;
  final VoidCallback? onActivate;
  final VoidCallback onToggleVisible;
  final VoidCallback onToggleLocked;
  final VoidCallback onMoveBack;
  final VoidCallback onMoveForward;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          IconButton(
            tooltip: active ? 'Active layer' : 'Make active',
            icon: Icon(
              active
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
            ),
            onPressed: onActivate,
          ),
          Expanded(
            child: Text(
              layer.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            tooltip: layer.visible ? 'Hide layer' : 'Show layer',
            icon: Icon(
              layer.visible
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
            onPressed: onToggleVisible,
          ),
          IconButton(
            tooltip: layer.locked ? 'Unlock layer' : 'Lock layer',
            icon: Icon(
              layer.locked ? Icons.lock_outline : Icons.lock_open_outlined,
            ),
            onPressed: onToggleLocked,
          ),
          IconButton(
            tooltip: 'Move backward',
            icon: const Icon(Icons.arrow_downward),
            onPressed: onMoveBack,
          ),
          IconButton(
            tooltip: 'Move forward',
            icon: const Icon(Icons.arrow_upward),
            onPressed: onMoveForward,
          ),
        ],
      ),
    );
  }
}

class _ExportDialog extends StatefulWidget {
  const _ExportDialog({required this.hasSelection, required this.hasContent});

  final bool hasSelection;
  final bool hasContent;

  @override
  State<_ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<_ExportDialog> {
  late CanvasExportScope _scope = widget.hasContent
      ? CanvasExportScope.content
      : CanvasExportScope.viewport;
  CanvasExportFormat _format = CanvasExportFormat.png;
  double _scale = 1.5;
  double _padding = 32;
  int _jpgQuality = 92;
  bool _transparent = false;
  bool _includeGrid = true;

  @override
  Widget build(BuildContext context) {
    final bool canTransparent =
        _format == CanvasExportFormat.png || _format == CanvasExportFormat.svg;
    return AlertDialog(
      title: const Text('Export'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<CanvasExportScope>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: CanvasExportScope.content,
                  icon: const Icon(Icons.select_all),
                  enabled: widget.hasContent,
                ),
                const ButtonSegment(
                  value: CanvasExportScope.viewport,
                  icon: Icon(Icons.crop_free),
                ),
                ButtonSegment(
                  value: CanvasExportScope.selection,
                  icon: const Icon(Icons.gesture),
                  enabled: widget.hasSelection,
                ),
              ],
              selected: {_scope},
              onSelectionChanged: (value) =>
                  setState(() => _scope = value.first),
            ),
            const SizedBox(height: 12),
            SegmentedButton<CanvasExportFormat>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: CanvasExportFormat.png,
                  label: Text('PNG'),
                ),
                ButtonSegment(
                  value: CanvasExportFormat.jpg,
                  label: Text('JPG'),
                ),
                ButtonSegment(
                  value: CanvasExportFormat.svg,
                  label: Text('SVG'),
                ),
              ],
              selected: {_format},
              onSelectionChanged: (value) => setState(() {
                _format = value.first;
                if (_format == CanvasExportFormat.jpg) {
                  _transparent = false;
                }
              }),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Transparent background'),
              value: canTransparent && _transparent,
              onChanged: canTransparent
                  ? (value) => setState(() => _transparent = value)
                  : null,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Include grid'),
              value: _includeGrid,
              onChanged: (value) => setState(() => _includeGrid = value),
            ),
            _ExportSlider(
              label: 'Scale',
              value: _scale,
              min: 0.5,
              max: 4,
              divisions: 7,
              valueLabel: '${_scale.toStringAsFixed(1)}x',
              onChanged: (value) => setState(() => _scale = value),
            ),
            _ExportSlider(
              label: 'Padding',
              value: _padding,
              min: 0,
              max: 128,
              divisions: 8,
              valueLabel: '${_padding.round()} px',
              onChanged: (value) => setState(() => _padding = value),
            ),
            if (_format == CanvasExportFormat.jpg)
              _ExportSlider(
                label: 'JPG quality',
                value: _jpgQuality.toDouble(),
                min: 40,
                max: 100,
                divisions: 12,
                valueLabel: '$_jpgQuality',
                onChanged: (value) =>
                    setState(() => _jpgQuality = value.round()),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            CanvasExportOptions(
              scope: _scope,
              format: _format,
              scale: _scale,
              jpgQuality: _jpgQuality,
              padding: _padding,
              transparentBackground: canTransparent && _transparent,
              includeGrid: _includeGrid,
            ),
          ),
          child: const Text('Export'),
        ),
      ],
    );
  }
}

class _ExportSlider extends StatelessWidget {
  const _ExportSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.valueLabel,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String valueLabel;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text(valueLabel),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          label: valueLabel,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _WheelAction {
  const _WheelAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.key,
    this.selected = false,
    this.destructive = false,
  });

  final Key? key;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final bool destructive;
}

class _RadialWheel extends StatelessWidget {
  const _RadialWheel({
    required this.actions,
    required this.activeColor,
    required this.centerIcon,
    required this.centerLabel,
    required this.centerTooltip,
    required this.onCenterTap,
    this.centerKey,
    this.onCenterLongPress,
    super.key,
  });

  final List<_WheelAction> actions;
  final Color activeColor;
  final IconData centerIcon;
  final String centerLabel;
  final String centerTooltip;
  final VoidCallback onCenterTap;
  final VoidCallback? onCenterLongPress;
  final Key? centerKey;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double size = math.min(
          constraints.maxWidth,
          constraints.maxHeight,
        );
        final Offset center = Offset(size / 2, size / 2);
        final double outerRadius = size / 2;
        final double innerRadius = size * 40 / 176;
        final double centerSize = size * 80 / 176;
        final int count = actions.length;
        final double sweep = count == 0 ? math.pi * 2 : math.pi * 2 / count;
        final double gap = math.min(0.045, sweep * 0.12);
        final double firstStart = -math.pi / 2 - sweep / 2;
        final double iconRadius = (outerRadius + innerRadius) / 2;
        final Color centerForeground = activeColor.computeLuminance() > 0.42
            ? Colors.black
            : Colors.white;

        return SizedBox.square(
          dimension: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _RadialWheelPainter(
                      actions: actions,
                      innerRadius: innerRadius,
                      gap: gap,
                      colors: Theme.of(context).colorScheme,
                    ),
                  ),
                ),
              ),
              for (var index = 0; index < count; index++)
                Positioned.fill(
                  child: ExcludeSemantics(
                    child: ClipPath(
                      clipper: _AnnularWedgeClipper(
                        startAngle: firstStart + index * sweep + gap / 2,
                        sweepAngle: sweep - gap,
                        innerRadius: innerRadius,
                      ),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: actions[index].onTap,
                      ),
                    ),
                  ),
                ),
              for (var index = 0; index < count; index++)
                Positioned(
                  left:
                      center.dx +
                      math.cos(-math.pi / 2 + index * sweep) * iconRadius -
                      20,
                  top:
                      center.dy +
                      math.sin(-math.pi / 2 + index * sweep) * iconRadius -
                      20,
                  width: 40,
                  height: 40,
                  child: Tooltip(
                    message: actions[index].label,
                    child: Semantics(
                      button: true,
                      enabled: actions[index].onTap != null,
                      selected: actions[index].selected,
                      label: actions[index].label,
                      onTap: actions[index].onTap,
                      child: GestureDetector(
                        key: actions[index].key,
                        behavior: HitTestBehavior.opaque,
                        onTap: actions[index].onTap,
                        child: Icon(
                          actions[index].icon,
                          size: size >= 170 ? 21 : 19,
                          color: actions[index].destructive
                              ? Theme.of(context).colorScheme.error
                              : actions[index].onTap == null
                              ? Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.3)
                              : actions[index].selected
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              Center(
                child: Material(
                  key: centerKey,
                  color: activeColor,
                  shape: CircleBorder(
                    side: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.outlineVariant.withValues(alpha: 0.9),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Tooltip(
                    message: centerTooltip,
                    child: InkWell(
                      onTap: onCenterTap,
                      onLongPress: onCenterLongPress,
                      child: SizedBox.square(
                        dimension: centerSize,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(centerIcon, color: centerForeground, size: 22),
                            const SizedBox(height: 2),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Text(
                                centerLabel,
                                maxLines: 1,
                                overflow: TextOverflow.fade,
                                softWrap: false,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: centerForeground,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RadialWheelPainter extends CustomPainter {
  const _RadialWheelPainter({
    required this.actions,
    required this.innerRadius,
    required this.gap,
    required this.colors,
  });

  final List<_WheelAction> actions;
  final double innerRadius;
  final double gap;
  final ColorScheme colors;

  @override
  void paint(Canvas canvas, Size size) {
    if (actions.isEmpty) return;
    final double sweep = math.pi * 2 / actions.length;
    final double firstStart = -math.pi / 2 - sweep / 2;
    for (var index = 0; index < actions.length; index++) {
      final action = actions[index];
      final path = _annularWedgePath(
        size,
        startAngle: firstStart + index * sweep + gap / 2,
        sweepAngle: sweep - gap,
        innerRadius: innerRadius,
      );
      canvas.drawShadow(path, Colors.black.withValues(alpha: 0.24), 3, false);
      final Color fill = action.selected
          ? colors.primaryContainer.withValues(alpha: 0.98)
          : colors.surfaceContainerHigh.withValues(alpha: 0.97);
      canvas.drawPath(path, Paint()..color = fill);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = colors.outlineVariant.withValues(alpha: 0.72),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RadialWheelPainter oldDelegate) =>
      oldDelegate.actions != actions ||
      oldDelegate.innerRadius != innerRadius ||
      oldDelegate.gap != gap ||
      oldDelegate.colors != colors;
}

class _AnnularWedgeClipper extends CustomClipper<Path> {
  const _AnnularWedgeClipper({
    required this.startAngle,
    required this.sweepAngle,
    required this.innerRadius,
  });

  final double startAngle;
  final double sweepAngle;
  final double innerRadius;

  @override
  Path getClip(Size size) => _annularWedgePath(
    size,
    startAngle: startAngle,
    sweepAngle: sweepAngle,
    innerRadius: innerRadius,
  );

  @override
  bool shouldReclip(covariant _AnnularWedgeClipper oldClipper) =>
      oldClipper.startAngle != startAngle ||
      oldClipper.sweepAngle != sweepAngle ||
      oldClipper.innerRadius != innerRadius;
}

Path _annularWedgePath(
  Size size, {
  required double startAngle,
  required double sweepAngle,
  required double innerRadius,
}) {
  final Offset center = Offset(size.width / 2, size.height / 2);
  final double outerRadius = math.min(size.width, size.height) / 2;
  final Rect outer = Rect.fromCircle(center: center, radius: outerRadius);
  final Rect inner = Rect.fromCircle(center: center, radius: innerRadius);
  final Offset innerStart =
      center + Offset(math.cos(startAngle), math.sin(startAngle)) * innerRadius;
  final Offset outerStart =
      center + Offset(math.cos(startAngle), math.sin(startAngle)) * outerRadius;
  return Path()
    ..moveTo(innerStart.dx, innerStart.dy)
    ..lineTo(outerStart.dx, outerStart.dy)
    ..arcTo(outer, startAngle, sweepAngle, false)
    ..arcTo(inner, startAngle + sweepAngle, -sweepAngle, false)
    ..close();
}

class _PaletteDock extends StatelessWidget {
  const _PaletteDock({
    required this.colors,
    required this.selectedColor,
    required this.onSelect,
  });

  final List<int> colors;
  final int selectedColor;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHigh.withValues(alpha: 0.97),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.72)),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double itemWidth = colors.length <= 6
              ? constraints.maxWidth / math.max(1, colors.length)
              : 28;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var index = 0; index < colors.length; index++)
                  Tooltip(
                    message: _hex(Color(colors[index])),
                    child: InkWell(
                      key: ValueKey<String>(
                        '${CanvasToolbar.swatchButtonKeyPrefix}-$index',
                      ),
                      onTap: () => onSelect(colors[index]),
                      child: SizedBox(
                        width: itemWidth,
                        height: constraints.maxHeight,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(colors[index]),
                            border: selectedColor == colors[index]
                                ? Border.all(color: scheme.primary, width: 3)
                                : null,
                          ),
                          child: selectedColor == colors[index]
                              ? Icon(
                                  Icons.check,
                                  size: 14,
                                  color:
                                      Color(colors[index]).computeLuminance() >
                                          0.42
                                      ? Colors.black
                                      : Colors.white,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FloatingSurface extends StatelessWidget {
  const _FloatingSurface({required this.child}) : circular = false;

  const _FloatingSurface.circular({required this.child, super.key})
    : circular = true;

  final Widget child;
  final bool circular;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainer.withValues(alpha: 0.94),
      shape: circular
          ? CircleBorder(
              side: BorderSide(
                color: colors.outlineVariant.withValues(alpha: 0.65),
              ),
            )
          : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
              side: BorderSide(
                color: colors.outlineVariant.withValues(alpha: 0.65),
              ),
            ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _GestureGuideRow extends StatelessWidget {
  const _GestureGuideRow({
    required this.icon,
    required this.gesture,
    required this.result,
  });

  final IconData icon;
  final String gesture;
  final String result;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: 52,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(gesture),
      subtitle: Text(result),
    );
  }
}

class _Cluster extends StatelessWidget {
  const _Cluster({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainer.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.72),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: child,
      ),
    );
  }
}

class _HudButton extends StatelessWidget {
  const _HudButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.selected = false,
    this.destructive = false,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool selected;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color foreground = destructive
        ? colors.error
        : selected
        ? colors.primary
        : onPressed == null
        ? colors.onSurface.withValues(alpha: 0.38)
        : colors.onSurfaceVariant;
    return Tooltip(
      message: tooltip,
      child: SizedBox.square(
        dimension: 44,
        child: IconButton(
          padding: EdgeInsets.zero,
          style: IconButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            backgroundColor: selected
                ? colors.primary.withValues(alpha: 0.16)
                : null,
            foregroundColor: foreground,
            disabledForegroundColor: foreground,
          ),
          icon: Icon(icon, size: 20),
          onPressed: onPressed,
        ),
      ),
    );
  }
}

class _PenKindButton extends StatelessWidget {
  const _PenKindButton({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _HudButton(
      icon: icon,
      tooltip: tooltip,
      selected: selected,
      onPressed: onPressed,
    );
  }
}

class _DockDivider extends StatelessWidget {
  const _DockDivider();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      width: 1,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      color: colors.outlineVariant.withValues(alpha: 0.72),
    );
  }
}

class _HudLabel extends StatelessWidget {
  const _HudLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      height: 44,
      child: Center(
        child: Text(
          label,
          maxLines: 1,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SwatchButton extends StatelessWidget {
  const _SwatchButton({
    required this.color,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Tooltip(
      message: _hex(color),
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: SizedBox.square(
          dimension: 44,
          child: Center(
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: selected
                      ? colors.primary
                      : colors.onSurface.withValues(alpha: 0.42),
                  width: selected ? 2 : 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ContextLabel extends StatelessWidget {
  const _ContextLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: colors.primary),
          const SizedBox(width: 7),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContextHint extends StatelessWidget {
  const _ContextHint(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ToolbarValueButton extends StatelessWidget {
  const _ToolbarValueButton({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: colors.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _PaletteDialog extends StatefulWidget {
  const _PaletteDialog({required this.initialColors});

  final List<int> initialColors;

  @override
  State<_PaletteDialog> createState() => _PaletteDialogState();
}

class _PaletteDialogState extends State<_PaletteDialog> {
  late final List<int> _colors;
  late final TextEditingController _hexController;
  int _selectedIndex = 0;
  _PalettePresetFamily _presetFamily = _PalettePresetFamily.core;
  String? _hexError;

  @override
  void initState() {
    super.initState();
    _colors = widget.initialColors.isEmpty
        ? List<int>.of(CanvasToolbar._defaultSwatches)
        : List<int>.of(widget.initialColors);
    _hexController = TextEditingController(text: _hex(_selectedColor));
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  int get _safeSelectedIndex =>
      _selectedIndex.clamp(0, _colors.length - 1).toInt();

  Color get _selectedColor => Color(_colors[_safeSelectedIndex]);

  void _syncHex(Color color) {
    final text = _hex(color);
    _hexController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _applySelectedColor(Color color, {bool updateHex = true}) {
    _colors[_safeSelectedIndex] = color.toARGB32();
    _hexError = null;
    if (updateHex) {
      _syncHex(color);
    }
  }

  void _setSelectedColor(Color color, {bool updateHex = true}) {
    setState(() {
      _applySelectedColor(color, updateHex: updateHex);
    });
  }

  void _selectSlot(int index) {
    setState(() {
      _selectedIndex = index;
      _hexError = null;
      _syncHex(_selectedColor);
    });
  }

  void _addSlot() {
    setState(() {
      _colors.add(_selectedColor.toARGB32());
      _selectedIndex = _colors.length - 1;
      _syncHex(_selectedColor);
    });
  }

  void _deleteSlot() {
    if (_colors.length <= 1) {
      return;
    }
    setState(() {
      _colors.removeAt(_safeSelectedIndex);
      _selectedIndex = _selectedIndex.clamp(0, _colors.length - 1).toInt();
      _hexError = null;
      _syncHex(_selectedColor);
    });
  }

  void _applyHex(String value) {
    final parsed = _parseHex(value);
    setState(() {
      _hexError = parsed == null ? 'Use #RRGGBB or #AARRGGBB' : null;
      if (parsed != null) {
        _applySelectedColor(parsed, updateHex: false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = _selectedColor;
    return AlertDialog(
      title: const Text('Edit palette'),
      content: SizedBox(
        width: 660,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.72,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Palette',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _addSlot,
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                    ),
                    TextButton.icon(
                      onPressed: _colors.length <= 1 ? null : _deleteSlot,
                      icon: const Icon(Icons.close),
                      label: const Text('Remove'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < _colors.length; i++)
                      _PaletteSlotButton(
                        color: Color(_colors[i]),
                        selected: _safeSelectedIndex == i,
                        index: i,
                        onTap: () => _selectSlot(i),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final presets = _palettePresets[_presetFamily]!;
                    final picker = _PresetPicker(
                      family: _presetFamily,
                      presets: presets,
                      onFamilyChanged: (family) =>
                          setState(() => _presetFamily = family),
                      onPresetSelected: (color) =>
                          _setSelectedColor(Color(color)),
                    );
                    final sliders = _PaletteColorEditor(
                      color: selectedColor,
                      hexController: _hexController,
                      hexError: _hexError,
                      onHexChanged: _applyHex,
                      onColorChanged: _setSelectedColor,
                    );
                    if (constraints.maxWidth < 560) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [picker, const SizedBox(height: 18), sliders],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 250, child: picker),
                        const SizedBox(width: 22),
                        Expanded(child: sliders),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(List<int>.of(_colors)),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

enum _PalettePresetFamily { core, warm, cool, muted }

const Map<_PalettePresetFamily, List<int>> _palettePresets =
    <_PalettePresetFamily, List<int>>{
      _PalettePresetFamily.core: <int>[
        0xFF111820,
        0xFFFFFFFF,
        0xFFF2C94C,
        0xFFFF4F91,
        0xFF36D400,
        0xFF1E9BFF,
        0xFF9B5CFF,
        0xFFFF7A3D,
        0xFF00D6A3,
        0xFFFFD166,
        0xFFEF476F,
        0xFF073B4C,
      ],
      _PalettePresetFamily.warm: <int>[
        0xFFFFF3B0,
        0xFFFFD166,
        0xFFF4A261,
        0xFFE76F51,
        0xFFD1495B,
        0xFFB56576,
        0xFFFFC8DD,
        0xFFFFAFCC,
        0xFFFF8FAB,
        0xFFFB6F92,
        0xFF8A5A44,
        0xFF583101,
      ],
      _PalettePresetFamily.cool: <int>[
        0xFFE0FBFC,
        0xFF98C1D9,
        0xFF3D5A80,
        0xFF293241,
        0xFF00B4D8,
        0xFF0077B6,
        0xFF80FFDB,
        0xFF2EC4B6,
        0xFF06D6A0,
        0xFF118AB2,
        0xFF5E60CE,
        0xFF7400B8,
      ],
      _PalettePresetFamily.muted: <int>[
        0xFFF8F9FA,
        0xFFCED4DA,
        0xFF6C757D,
        0xFF212529,
        0xFFB8C0A8,
        0xFFA3B18A,
        0xFF7F4F24,
        0xFF936639,
        0xFFC9ADA7,
        0xFF9A8C98,
        0xFF4A4E69,
        0xFF22223B,
      ],
    };

String _presetFamilyLabel(_PalettePresetFamily family) {
  return switch (family) {
    _PalettePresetFamily.core => 'Core',
    _PalettePresetFamily.warm => 'Warm',
    _PalettePresetFamily.cool => 'Cool',
    _PalettePresetFamily.muted => 'Muted',
  };
}

class _PresetPicker extends StatelessWidget {
  const _PresetPicker({
    required this.family,
    required this.presets,
    required this.onFamilyChanged,
    required this.onPresetSelected,
  });

  final _PalettePresetFamily family;
  final List<int> presets;
  final ValueChanged<_PalettePresetFamily> onFamilyChanged;
  final ValueChanged<int> onPresetSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Presets', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final value in _PalettePresetFamily.values)
              ChoiceChip(
                label: Text(_presetFamilyLabel(value)),
                selected: family == value,
                onSelected: (_) => onFamilyChanged(value),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < presets.length; i++)
              _PresetSwatchButton(
                key: ValueKey<String>(
                  '${CanvasToolbar.palettePresetButtonKeyPrefix}-$i',
                ),
                color: Color(presets[i]),
                onTap: () => onPresetSelected(presets[i]),
              ),
          ],
        ),
      ],
    );
  }
}

class _PaletteColorEditor extends StatelessWidget {
  const _PaletteColorEditor({
    required this.color,
    required this.hexController,
    required this.hexError,
    required this.onHexChanged,
    required this.onColorChanged,
  });

  final Color color;
  final TextEditingController hexController;
  final String? hexError;
  final ValueChanged<String> onHexChanged;
  final ValueChanged<Color> onColorChanged;

  @override
  Widget build(BuildContext context) {
    final hsl = HSLColor.fromColor(color);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: Colors.white24),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: hexController,
                decoration: InputDecoration(
                  labelText: 'Hex',
                  errorText: hexError,
                ),
                textCapitalization: TextCapitalization.characters,
                onChanged: onHexChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ExportSlider(
          label: 'Red',
          value: _red(color).toDouble(),
          min: 0,
          max: 255,
          divisions: 255,
          valueLabel: '${_red(color)}',
          onChanged: (value) => onColorChanged(
            _rgbColor(value.round(), _green(color), _blue(color)),
          ),
        ),
        _ExportSlider(
          label: 'Green',
          value: _green(color).toDouble(),
          min: 0,
          max: 255,
          divisions: 255,
          valueLabel: '${_green(color)}',
          onChanged: (value) => onColorChanged(
            _rgbColor(_red(color), value.round(), _blue(color)),
          ),
        ),
        _ExportSlider(
          label: 'Blue',
          value: _blue(color).toDouble(),
          min: 0,
          max: 255,
          divisions: 255,
          valueLabel: '${_blue(color)}',
          onChanged: (value) => onColorChanged(
            _rgbColor(_red(color), _green(color), value.round()),
          ),
        ),
        const SizedBox(height: 8),
        _ExportSlider(
          label: 'Hue',
          value: hsl.hue,
          min: 0,
          max: 360,
          divisions: 360,
          valueLabel: '${hsl.hue.round()} deg',
          onChanged: (value) => onColorChanged(hsl.withHue(value).toColor()),
        ),
        _ExportSlider(
          label: 'Saturation',
          value: hsl.saturation,
          min: 0,
          max: 1,
          divisions: 100,
          valueLabel: '${(hsl.saturation * 100).round()}%',
          onChanged: (value) =>
              onColorChanged(hsl.withSaturation(value).toColor()),
        ),
        _ExportSlider(
          label: 'Lightness',
          value: hsl.lightness,
          min: 0,
          max: 1,
          divisions: 100,
          valueLabel: '${(hsl.lightness * 100).round()}%',
          onChanged: (value) =>
              onColorChanged(hsl.withLightness(value).toColor()),
        ),
      ],
    );
  }
}

class _PaletteSlotButton extends StatelessWidget {
  const _PaletteSlotButton({
    required this.color,
    required this.selected,
    required this.index,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selectedColor = Theme.of(context).colorScheme.primary;
    return Tooltip(
      message: 'Palette color ${index + 1}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          width: 42,
          height: 42,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: selected ? selectedColor : Colors.white24,
              width: selected ? 2 : 1,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}

class _PresetSwatchButton extends StatelessWidget {
  const _PresetSwatchButton({
    required this.color,
    required this.onTap,
    super.key,
  });

  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _hex(color),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
          ),
        ),
      ),
    );
  }
}

class _PaperDialog extends StatefulWidget {
  const _PaperDialog({required this.initial});

  final CanvasPaperStyle initial;

  @override
  State<_PaperDialog> createState() => _PaperDialogState();
}

class _PaperDialogState extends State<_PaperDialog> {
  late CanvasPaperStyle _style = widget.initial;

  static const List<int> _backgroundPresets = <int>[
    0xFF172331,
    0xFF101016,
    0xFF0B1020,
    0xFF10322B,
    0xFF263238,
    0xFFF7F1DE,
    0xFFFFFFFF,
    0xFFB7CFE3,
  ];

  static const List<int> _gridPresets = <int>[
    0xFFFFFFFF,
    0xFF8EC5FF,
    0xFFE8B84B,
    0xFF36D400,
    0xFFFF4F91,
    0xFFEF4444,
    0xFF111820,
    0xFF6B7280,
  ];

  Future<void> _pickBackground() async {
    final color = await showDialog<Color>(
      context: context,
      builder: (context) =>
          _HexColorDialog(initialColor: Color(_style.backgroundColor)),
    );
    if (color != null) {
      setState(
        () => _style = _style.copyWith(backgroundColor: color.toARGB32()),
      );
    }
  }

  Future<void> _pickGrid() async {
    final color = await showDialog<Color>(
      context: context,
      builder: (context) =>
          _HexColorDialog(initialColor: Color(_style.gridColor)),
    );
    if (color != null) {
      setState(() => _style = _style.copyWith(gridColor: color.toARGB32()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      color: theme.colorScheme.onSurface,
      fontWeight: FontWeight.w800,
    );
    final labelStyle = theme.textTheme.labelLarge?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w700,
    );
    return _Cluster(
      key: CanvasToolbar.paperSettingsPanelKey,
      child: Material(
        color: Colors.transparent,
        child: DefaultTextStyle.merge(
          style: TextStyle(color: theme.colorScheme.onSurface),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.wallpaper_outlined,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text('Paper', style: titleStyle),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Close paper settings',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _PaperKindButton(
                      kind: BackgroundKind.blank,
                      icon: Icons.crop_square,
                      label: 'Blank',
                      selected: _style.kind == BackgroundKind.blank,
                      onTap: () => _setKind(BackgroundKind.blank),
                    ),
                    _PaperKindButton(
                      kind: BackgroundKind.dotted,
                      icon: Icons.apps,
                      label: 'Dots',
                      selected: _style.kind == BackgroundKind.dotted,
                      onTap: () => _setKind(BackgroundKind.dotted),
                    ),
                    _PaperKindButton(
                      kind: BackgroundKind.lined,
                      icon: Icons.horizontal_rule,
                      label: 'Lines',
                      selected: _style.kind == BackgroundKind.lined,
                      onTap: () => _setKind(BackgroundKind.lined),
                    ),
                    _PaperKindButton(
                      kind: BackgroundKind.grid,
                      icon: Icons.grid_4x4,
                      label: 'Graph',
                      selected: _style.kind == BackgroundKind.grid,
                      onTap: () => _setKind(BackgroundKind.grid),
                    ),
                    _PaperKindButton(
                      kind: BackgroundKind.isometric,
                      icon: Icons.view_in_ar,
                      label: 'Iso',
                      selected: _style.kind == BackgroundKind.isometric,
                      onTap: () => _setKind(BackgroundKind.isometric),
                    ),
                    _PaperKindButton(
                      kind: BackgroundKind.triangle,
                      icon: Icons.change_history,
                      label: 'Tri',
                      selected: _style.kind == BackgroundKind.triangle,
                      onTap: () => _setKind(BackgroundKind.triangle),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _PaperPresetSection(
                  title: 'Background',
                  value: Color(_style.backgroundColor),
                  presets: _backgroundPresets,
                  keyPrefix: CanvasToolbar.paperBackgroundPresetButtonKeyPrefix,
                  onSelected: (color) => setState(
                    () => _style = _style.copyWith(
                      backgroundColor: color.toARGB32(),
                    ),
                  ),
                  onCustom: _pickBackground,
                ),
                const SizedBox(height: 12),
                _PaperPresetSection(
                  title: 'Graph',
                  value: Color(_style.gridColor),
                  presets: _gridPresets,
                  keyPrefix: CanvasToolbar.paperGridPresetButtonKeyPrefix,
                  onSelected: (color) => setState(
                    () => _style = _style.copyWith(gridColor: color.toARGB32()),
                  ),
                  onCustom: _pickGrid,
                ),
                const SizedBox(height: 14),
                Text('Graph options', style: labelStyle),
                const SizedBox(height: 8),
                _ExportSlider(
                  label: 'Spacing',
                  value: _style.gridSpacing.clamp(16, 128),
                  min: 16,
                  max: 128,
                  divisions: 14,
                  valueLabel: _style.gridSpacing.round().toString(),
                  onChanged: (value) => setState(
                    () => _style = _style.copyWith(gridSpacing: value),
                  ),
                ),
                _ExportSlider(
                  label: 'Opacity',
                  value: _style.gridOpacity.clamp(0.02, 0.8),
                  min: 0.02,
                  max: 0.8,
                  divisions: 39,
                  valueLabel: '${(_style.gridOpacity * 100).round()}%',
                  onChanged: (value) => setState(
                    () => _style = _style.copyWith(gridOpacity: value),
                  ),
                ),
                _ExportSlider(
                  label: 'Major every',
                  value: _style.graphMajorInterval.clamp(2, 12).toDouble(),
                  min: 2,
                  max: 12,
                  divisions: 10,
                  valueLabel: _style.graphMajorInterval.toString(),
                  onChanged: (value) => setState(
                    () => _style = _style.copyWith(
                      graphMajorInterval: value.round(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(_style),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _setKind(BackgroundKind kind) {
    setState(() => _style = _style.copyWith(kind: kind));
  }
}

class _PaperKindButton extends StatelessWidget {
  const _PaperKindButton({
    required this.kind,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final BackgroundKind kind;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color selectedColor = colors.primary;
    final foreground = selected ? selectedColor : colors.onSurfaceVariant;
    return Tooltip(
      message: label,
      child: InkWell(
        key: ValueKey<String>(
          '${CanvasToolbar.paperKindButtonKeyPrefix}-$kind',
        ),
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 76,
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: selected
                ? selectedColor.withValues(alpha: 0.16)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected
                  ? selectedColor.withValues(alpha: 0.58)
                  : colors.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaperPresetSection extends StatelessWidget {
  const _PaperPresetSection({
    required this.title,
    required this.value,
    required this.presets,
    required this.keyPrefix,
    required this.onSelected,
    required this.onCustom,
  });

  final String title;
  final Color value;
  final List<int> presets;
  final String keyPrefix;
  final ValueChanged<Color> onSelected;
  final VoidCallback onCustom;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
      color: colors.onSurfaceVariant,
      fontWeight: FontWeight.w700,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: labelStyle),
            const Spacer(),
            Text(
              _hex(value),
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: onCustom,
              icon: const Icon(Icons.tune, size: 16),
              label: const Text('Custom'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (var i = 0; i < presets.length; i++)
              _PaperPresetSwatch(
                key: ValueKey<String>('$keyPrefix-$i'),
                color: Color(presets[i]),
                selected: value.toARGB32() == presets[i],
                onTap: () => onSelected(Color(presets[i])),
              ),
          ],
        ),
      ],
    );
  }
}

class _PaperPresetSwatch extends StatelessWidget {
  const _PaperPresetSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color selectedColor = colors.primary;
    return Tooltip(
      message: _hex(color),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 34,
          height: 34,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected ? selectedColor : colors.outline,
              width: selected ? 2 : 1,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.black.withValues(alpha: 0.18)),
            ),
            child: selected
                ? Icon(Icons.check, size: 17, color: _readableInkOn(color))
                : null,
          ),
        ),
      ),
    );
  }
}

class _HexColorDialog extends StatefulWidget {
  const _HexColorDialog({required this.initialColor});

  final Color initialColor;

  @override
  State<_HexColorDialog> createState() => _HexColorDialogState();
}

class _HexColorDialogState extends State<_HexColorDialog> {
  late Color _selected = widget.initialColor;
  late final TextEditingController _controller = TextEditingController(
    text: _hex(widget.initialColor),
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setSelected(Color color, {bool updateHex = true}) {
    _selected = color;
    _error = null;
    if (updateHex) {
      final text = _hex(color);
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  void _apply(String value) {
    final parsed = _parseHex(value);
    setState(() {
      _error = parsed == null ? 'Use #RRGGBB or #AARRGGBB' : null;
      if (parsed != null) {
        _setSelected(parsed, updateHex: false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final HSLColor hsl = HSLColor.fromColor(_selected);
    return AlertDialog(
      title: const Text('Choose color'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _selected,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Hex',
                      errorText: _error,
                    ),
                    textCapitalization: TextCapitalization.characters,
                    onChanged: _apply,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ExportSlider(
              label: 'Red',
              value: _red(_selected).toDouble(),
              min: 0,
              max: 255,
              divisions: 255,
              valueLabel: '${_red(_selected)}',
              onChanged: (value) => setState(
                () => _setSelected(
                  _rgbColor(value.round(), _green(_selected), _blue(_selected)),
                ),
              ),
            ),
            _ExportSlider(
              label: 'Green',
              value: _green(_selected).toDouble(),
              min: 0,
              max: 255,
              divisions: 255,
              valueLabel: '${_green(_selected)}',
              onChanged: (value) => setState(
                () => _setSelected(
                  _rgbColor(_red(_selected), value.round(), _blue(_selected)),
                ),
              ),
            ),
            _ExportSlider(
              label: 'Blue',
              value: _blue(_selected).toDouble(),
              min: 0,
              max: 255,
              divisions: 255,
              valueLabel: '${_blue(_selected)}',
              onChanged: (value) => setState(
                () => _setSelected(
                  _rgbColor(_red(_selected), _green(_selected), value.round()),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _ExportSlider(
              label: 'Hue',
              value: hsl.hue,
              min: 0,
              max: 360,
              divisions: 360,
              valueLabel: '${hsl.hue.round()} deg',
              onChanged: (value) =>
                  setState(() => _setSelected(hsl.withHue(value).toColor())),
            ),
            _ExportSlider(
              label: 'Saturation',
              value: hsl.saturation,
              min: 0,
              max: 1,
              divisions: 100,
              valueLabel: '${(hsl.saturation * 100).round()}%',
              onChanged: (value) => setState(
                () => _setSelected(hsl.withSaturation(value).toColor()),
              ),
            ),
            _ExportSlider(
              label: 'Lightness',
              value: hsl.lightness,
              min: 0,
              max: 1,
              divisions: 100,
              valueLabel: '${(hsl.lightness * 100).round()}%',
              onChanged: (value) => setState(
                () => _setSelected(hsl.withLightness(value).toColor()),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _error == null
              ? () => Navigator.of(context).pop(_selected)
              : null,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

int _red(Color color) => (color.toARGB32() >> 16) & 0xFF;

int _green(Color color) => (color.toARGB32() >> 8) & 0xFF;

int _blue(Color color) => color.toARGB32() & 0xFF;

Color _rgbColor(int red, int green, int blue) {
  return Color(0xFF000000 | (red << 16) | (green << 8) | blue);
}

String _hex(Color color) {
  return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
}

Color _readableInkOn(Color color) {
  return color.computeLuminance() > 0.45 ? Colors.black : Colors.white;
}

Color? _parseHex(String value) {
  final cleaned = value.trim().replaceFirst('#', '');
  if (cleaned.length != 6 && cleaned.length != 8) {
    return null;
  }
  final parsed = int.tryParse(cleaned, radix: 16);
  if (parsed == null) return null;
  return Color(cleaned.length == 6 ? parsed | 0xFF000000 : parsed);
}
