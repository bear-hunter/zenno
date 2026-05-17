import 'package:flutter/material.dart';

import 'package:zenno/canvas/canvas_controller.dart';
import 'package:zenno/canvas/model/stroke.dart';

/// Compact horizontal toolbar driving a [CanvasController].
///
/// Surfaces the tool selector (pan / pen / eraser / lasso / shape / link),
/// tool-aware sub-controls — the ink-kind toggle and stroke styling for pen, an
/// eraser object/partial mode toggle for the eraser, a line/rectangle/oval/arrow
/// picker for the shape tool, a "delete selection" action while a lasso
/// selection is held, a hint while the link tool is active — the "add image" /
/// "add PDF" import actions, plus the colour swatches, width presets and the
/// undo / redo / clear / reset-view actions. The whole bar is wrapped in a
/// [ListenableBuilder] so it reflects controller state without any manual
/// subscription.
class CanvasToolbar extends StatelessWidget {
  /// Creates a toolbar bound to [controller].
  const CanvasToolbar({required this.controller, super.key});

  /// The canvas state and command surface this toolbar drives.
  final CanvasController controller;

  /// Selectable stroke colours, as packed ARGB integers.
  static const List<int> _swatches = <int>[
    0xFFFFFFFF, // white
    0xFFE8B84B, // gold accent
    0xFFE5484D, // red
    0xFF30A46C, // green
    0xFF3E63DD, // blue
    0xFF101012, // black
  ];

  /// Stroke-width presets, in logical pixels at `scale == 1`.
  static const List<double> _widths = <double>[2, 4, 8];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final CanvasTool tool = controller.activeTool;
        // The colour + width controls only matter for tools that emit ink.
        final bool inkControlsApply =
            tool == CanvasTool.pen || tool == CanvasTool.shape;
        return Material(
          color: colors.surfaceContainerHigh,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _toolToggle(colors),
                  // Contextual sub-control for the active tool.
                  if (tool == CanvasTool.pen) _kindToggle(colors),
                  if (tool == CanvasTool.eraser) _eraserModeToggle(colors),
                  if (tool == CanvasTool.shape) _shapeKindToggle(colors),
                  if (tool == CanvasTool.link) _linkHint(colors),
                  if (inkControlsApply) ...[
                    _divider(colors),
                    _swatchRow(colors),
                    _divider(colors),
                    _widthRow(colors),
                  ],
                  if (controller.hasSelection) ...[
                    _divider(colors),
                    _deleteSelectionButton(colors),
                  ],
                  _divider(colors),
                  _insertActions(colors),
                  _divider(colors),
                  _actions(colors),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Pan / pen / eraser / lasso / shape tool selector.
  Widget _toolToggle(ColorScheme colors) {
    return SegmentedButton<CanvasTool>(
      showSelectedIcon: false,
      style: _segmentStyle,
      segments: const [
        ButtonSegment<CanvasTool>(
          value: CanvasTool.pan,
          icon: Icon(Icons.pan_tool_outlined),
          tooltip: 'Pan',
        ),
        ButtonSegment<CanvasTool>(
          value: CanvasTool.pen,
          icon: Icon(Icons.edit_outlined),
          tooltip: 'Draw',
        ),
        ButtonSegment<CanvasTool>(
          value: CanvasTool.eraser,
          icon: Icon(Icons.cleaning_services_outlined),
          tooltip: 'Eraser',
        ),
        ButtonSegment<CanvasTool>(
          value: CanvasTool.lasso,
          icon: Icon(Icons.gesture_outlined),
          tooltip: 'Lasso select',
        ),
        ButtonSegment<CanvasTool>(
          value: CanvasTool.shape,
          icon: Icon(Icons.category_outlined),
          tooltip: 'Shapes',
        ),
        ButtonSegment<CanvasTool>(
          value: CanvasTool.link,
          icon: Icon(Icons.add_link),
          tooltip: 'Place a link',
        ),
      ],
      selected: <CanvasTool>{controller.activeTool},
      onSelectionChanged: (selection) =>
          controller.setTool(selection.first),
    );
  }

  /// A short instruction shown while the link tool is active.
  Widget _linkHint(ColorScheme colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.touch_app_outlined, size: 18, color: colors.primary),
        const SizedBox(width: 6),
        Text(
          'Tap the canvas to place a link',
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
        ),
      ],
    );
  }

  /// Pen / highlighter ink-kind selector (pen tool only).
  Widget _kindToggle(ColorScheme colors) {
    return SegmentedButton<StrokeToolKind>(
      showSelectedIcon: false,
      style: _segmentStyle,
      segments: const [
        ButtonSegment<StrokeToolKind>(
          value: StrokeToolKind.pen,
          icon: Icon(Icons.brush),
          tooltip: 'Pen',
        ),
        ButtonSegment<StrokeToolKind>(
          value: StrokeToolKind.highlighter,
          icon: Icon(Icons.highlight),
          tooltip: 'Highlighter',
        ),
      ],
      selected: <StrokeToolKind>{controller.penKind},
      onSelectionChanged: (selection) =>
          controller.setPenKind(selection.first),
    );
  }

  /// Object / partial eraser-mode selector (eraser tool only).
  ///
  /// "Object" deletes whole strokes; "Split" is the vector partial eraser that
  /// cuts a stroke into surviving fragments.
  Widget _eraserModeToggle(ColorScheme colors) {
    return SegmentedButton<EraserMode>(
      showSelectedIcon: false,
      style: _segmentStyle,
      segments: const [
        ButtonSegment<EraserMode>(
          value: EraserMode.object,
          icon: Icon(Icons.delete_sweep_outlined),
          label: Text('Object'),
          tooltip: 'Erase whole strokes',
        ),
        ButtonSegment<EraserMode>(
          value: EraserMode.partial,
          icon: Icon(Icons.content_cut),
          label: Text('Split'),
          tooltip: 'Vector erase — split strokes',
        ),
      ],
      selected: <EraserMode>{controller.eraserMode},
      onSelectionChanged: (selection) =>
          controller.setEraserMode(selection.first),
    );
  }

  /// Line / rectangle / oval / arrow shape-kind selector (shape tool only).
  Widget _shapeKindToggle(ColorScheme colors) {
    return SegmentedButton<ShapeKind>(
      showSelectedIcon: false,
      style: _segmentStyle,
      segments: const [
        ButtonSegment<ShapeKind>(
          value: ShapeKind.line,
          icon: Icon(Icons.horizontal_rule),
          tooltip: 'Line',
        ),
        ButtonSegment<ShapeKind>(
          value: ShapeKind.rectangle,
          icon: Icon(Icons.crop_square),
          tooltip: 'Rectangle',
        ),
        ButtonSegment<ShapeKind>(
          value: ShapeKind.oval,
          icon: Icon(Icons.circle_outlined),
          tooltip: 'Oval',
        ),
        ButtonSegment<ShapeKind>(
          value: ShapeKind.arrow,
          icon: Icon(Icons.arrow_right_alt),
          tooltip: 'Arrow',
        ),
      ],
      selected: <ShapeKind>{controller.shapeKind},
      onSelectionChanged: (selection) =>
          controller.setShapeKind(selection.first),
    );
  }

  /// "Delete selection" action, shown only while a lasso selection is held.
  Widget _deleteSelectionButton(ColorScheme colors) {
    return FilledButton.tonalIcon(
      style: FilledButton.styleFrom(
        visualDensity: VisualDensity.compact,
        backgroundColor: colors.errorContainer,
        foregroundColor: colors.onErrorContainer,
      ),
      onPressed: controller.deleteSelection,
      icon: const Icon(Icons.delete_outline, size: 18),
      label: const Text('Delete'),
    );
  }

  /// Row of selectable colour swatches.
  Widget _swatchRow(ColorScheme colors) {
    return Wrap(
      spacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final argb in _swatches)
          _SwatchButton(
            color: Color(argb),
            selected: controller.penColor == argb,
            outline: colors.onSurfaceVariant,
            highlight: colors.primary,
            onTap: () => controller.setPenColor(argb),
          ),
      ],
    );
  }

  /// Row of three stroke-width preset buttons.
  Widget _widthRow(ColorScheme colors) {
    return Wrap(
      spacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final width in _widths)
          _WidthButton(
            width: width,
            selected: controller.penWidth == width,
            foreground: colors.onSurface,
            highlight: colors.primary,
            onTap: () => controller.setPenWidth(width),
          ),
      ],
    );
  }

  /// "Add image" / "Add PDF" import actions.
  ///
  /// Both open the OS file picker via the controller's import flow. They are
  /// disabled while an import is already running ([CanvasController.isImporting])
  /// so a second picker cannot be launched on top of the first.
  Widget _insertActions(ColorScheme colors) {
    final bool busy = controller.isImporting;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.image_outlined),
          tooltip: 'Add image',
          onPressed: busy ? null : controller.importImage,
        ),
        IconButton(
          icon: const Icon(Icons.picture_as_pdf_outlined),
          tooltip: 'Add PDF',
          onPressed: busy ? null : controller.importPdf,
        ),
      ],
    );
  }

  /// Undo / redo / clear / reset-view actions.
  Widget _actions(ColorScheme colors) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.undo),
          tooltip: 'Undo',
          onPressed: controller.canUndo ? controller.undo : null,
        ),
        IconButton(
          icon: const Icon(Icons.redo),
          tooltip: 'Redo',
          onPressed: controller.canRedo ? controller.redo : null,
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Clear canvas',
          onPressed: controller.clear,
        ),
        IconButton(
          icon: const Icon(Icons.center_focus_strong),
          tooltip: 'Reset view',
          onPressed: controller.resetView,
        ),
      ],
    );
  }

  /// A thin vertical rule separating toolbar groups.
  Widget _divider(ColorScheme colors) {
    return Container(
      width: 1,
      height: 28,
      color: colors.outlineVariant,
    );
  }

  /// Shared dense styling for the segmented toggles.
  static final ButtonStyle _segmentStyle = ButtonStyle(
    visualDensity: VisualDensity.compact,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    padding: WidgetStateProperty.all(
      const EdgeInsets.symmetric(horizontal: 12),
    ),
  );
}

/// A single tappable colour swatch with a selected-state ring.
class _SwatchButton extends StatelessWidget {
  const _SwatchButton({
    required this.color,
    required this.selected,
    required this.outline,
    required this.highlight,
    required this.onTap,
  });

  /// The colour this swatch applies.
  final Color color;

  /// Whether this swatch is the controller's current pen colour.
  final bool selected;

  /// Border colour used for the resting (unselected) state.
  final Color outline;

  /// Ring colour used for the selected state.
  final Color highlight;

  /// Called when the swatch is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 22,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? highlight : outline.withValues(alpha: 0.4),
            width: selected ? 3 : 1,
          ),
        ),
      ),
    );
  }
}

/// A stroke-width preset shown as a filled dot sized to the width.
class _WidthButton extends StatelessWidget {
  const _WidthButton({
    required this.width,
    required this.selected,
    required this.foreground,
    required this.highlight,
    required this.onTap,
  });

  /// The stroke width this button applies.
  final double width;

  /// Whether this preset is the controller's current pen width.
  final bool selected;

  /// Colour of the preview dot.
  final Color foreground;

  /// Ring / fill colour used for the selected state.
  final Color highlight;

  /// Called when the preset is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 22,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? highlight : Colors.transparent,
            width: 2,
          ),
        ),
        child: Center(
          child: Container(
            width: 4 + width * 2,
            height: 4 + width * 2,
            decoration: BoxDecoration(
              color: selected ? highlight : foreground,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
