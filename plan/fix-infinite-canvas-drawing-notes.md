# Fix Infinite Canvas Drawing And Note-Taking Issues

## Summary

Fix the live ink bug first, then harden tablet input, erasing, links, long-stroke performance, thumbnails, and add a minimal persistent text-note tool. The target outcome is that S Pen writing appears immediately while drawing, does not jump from palm/finger input, erases reliably, supports typed notes on the canvas, and remains covered by focused tests.

## Key Changes

- **Live ink rendering**
  - Make live strokes immutable per append: `appendToStroke` should replace `liveStroke` with a copied `Stroke` and copied points list so `LiveStrokePainter.shouldRepaint` reliably sees changes.
  - Add a painter/controller test proving point appends repaint before pen-up.

- **Tablet input and link taps**
  - In `CanvasView`, ignore touch pan/pinch events while a stylus/tool gesture is active.
  - Add a small tap-slop threshold, around 8 logical px, so link placement/follow and lasso tap-clear are not broken by normal pen jitter.
  - Resolve link placement/follow taps from the final up position when movement is within tap slop.

- **Partial eraser reliability**
  - Replace point-only partial erasing with segment-aware splitting: if the eraser path crosses between stroke samples, split the stroke at the intersection/projection point and keep surviving fragments.
  - Preserve pressure/style and keep the operation one undoable `ReplaceElementsCommand`.

- **Typed canvas notes**
  - Add `TextElement` to the canvas model with `id`, `zIndex`, `worldBounds`, `text`, `color`, `fontSize`, and translation support.
  - Add `CanvasTool.text`; tapping the canvas opens an editor dialog/sheet with a multiline `TextField`; saving creates or updates a text element.
  - Add a Drift `CanvasTexts` detail table linked to `canvas_elements`, persist it under existing `ElementKind.text`, and reconstruct/write it in `CanvasRepository`.
  - Render text in `ElementsPainter`, include it in selection, lasso, move, object erase, undo/redo, spatial index, and link/card-independent canvas flows.

- **Long-stroke performance and thumbnails**
  - Add lightweight point filtering before appending, skipping samples closer than about 1 screen pixel in world units unless pressure changed meaningfully.
  - Make thumbnail capture safer by moving best-effort thumbnail generation to an explicit pre-pop/back path after flushing, or by guarding dispose-time async work so disposed `ref/context` is not used.

## Public Interfaces And Data

- New engine type: `TextElement extends CanvasElement`.
- New tool enum value: `CanvasTool.text`.
- New persistence table: `CanvasTexts(elementId, text, color, fontSize)`.
- New repository support: `ElementKind.text` maps to/from `TextElement`.
- Migration/codegen: bump Drift schema version, add migration for `CanvasTexts`, run `dart run build_runner build`.

## Test Plan

- Unit tests:
  - `appendToStroke` changes `liveStroke` identity and increases point count before commit.
  - `LiveStrokePainter.shouldRepaint` returns true for appended live stroke state.
  - Partial eraser splits a sparse two-point stroke when the eraser crosses the segment midpoint.
  - Touch pan/pinch does not change viewport while stylus drawing is active.
  - Tap jitter below threshold still places/follows links; drag beyond threshold does not.
  - `TextElement` translates, lasso-selects, object-erases, undo/redoes, and persists/loads.
- Widget/render tests:
  - Text note is painted in the expected bounds.
  - Text tool dialog creates a text element from multiline input.
- Validation:
  - `dart run build_runner build`
  - `flutter analyze`
  - targeted canvas tests, then `flutter test`
  - manual Samsung Tab S9 FE smoke test: long S Pen handwriting appears live, palm/finger does not pan during writing, partial eraser cuts fast strokes, text note can be added/moved/deleted/reopened.

## Assumptions

- Include typed canvas notes in this fix batch.
- Use a minimal text-note feature, not rich text, markdown, resizing handles, or inline editing in v1.
- Text notes use the current pen color for initial color and a fixed default readable font size, with richer styling deferred.
- Existing dirty worktree changes are not part of this plan and should not be reverted.
