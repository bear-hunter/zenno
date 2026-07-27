# Canvas Editor — UI/UX Review

Scope: the infinite-canvas editor and its rendering/input UI — `canvas_editor_page.dart`, `canvas_controller.dart`, `canvas/widgets/*`, `canvas/render/*`, `canvas/input/pointer_classifier.dart`, `canvas/io/canvas_import.dart`, `canvas/pdf/pdf_raster_service.dart`, `canvas/model/viewport_state.dart`.

Findings: 6 High · 22 Medium · 18 Low.

Line numbers are as of the review; verify against current source before editing.

---

## `canvas_editor_page.dart`

### High · Touch/Input · `canvas_editor_page.dart:298-299` — app bar title is always "Canvas"
**Problem.** The app bar title is the hardcoded string `'Canvas'`. The canvas being edited has no visible name — every canvas reads identically. In a study app where the user follows link chains between canvases, after a few hops there is no way to know which canvas is open; the back button is the only orientation.
**Fix.** Read the canvas title from the repository (`canvasChooser` already exposes `(id, title)` records) and show it as the `AppBar.title` with `overflow: TextOverflow.ellipsis`.

### High · Feedback & States · `canvas_editor_page.dart:250-282` — emptying a note silently deletes it
**Problem.** `_showTextNoteDialog` / `_onEditText`: when the user edits an existing note, clears all text, and presses **Save**, `updateTextElement` silently deletes the element (controller `:1526-1531` — empty body → `removeElements`). A button labelled "Save" destroys data with no confirmation and no SnackBar.
**Fix.** Either keep an emptied note as a blank note box, or, if delete-on-empty is intended, confirm it ("Delete this note?") or show a SnackBar with Undo.

### Medium · Feedback & States · `canvas_editor_page.dart:148-173` — back paths diverge on unsaved work
**Problem.** `_handleBack` flushes and checks `hasSaveError` (showing a dialog), but it is wired *only* to the app-bar `BackButton`. A swipe-back gesture, predictive back, or programmatic `context.pop()` (e.g. from `_onFollowLink`'s stack) skips that check entirely. `_captureThumbnail` also runs in `dispose()` before `flush()` and is async, so capture + flush continue detached with no user-visible signal.
**Fix.** Wrap the `Scaffold` in `PopScope(canPop: false, onPopInvokedWithResult: ...)` so the unsaved-changes/save-error check runs for **all** back paths.

### Medium · Feedback & States · `canvas_editor_page.dart:312-326` — two conflicting save-error surfaces
**Problem.** A failed save shows *both* a `MaterialBanner` ("Canvas not saved" / Retry / Dismiss) and, via `_handleBack`, an `AlertDialog` with the same message but different buttons (Stay / Leave). Two surfaces, inconsistent labels. The banner's "Dismiss" hides the error without fixing it — a user who dismisses then keeps drawing has no indication their work is not persisting.
**Fix.** Pick one persistent affordance. Keep a subtle persistent indicator (e.g. a `cloud_off` icon in the app bar) until writes actually succeed, so a dismissed error is not silently forgotten.

### Medium · Layout/Overflow · `canvas_editor_page.dart:250-282` — note dialog width not responsive
**Problem.** The note dialog wraps its `TextField` in a fixed `SizedBox(width: 420)`. In tablet portrait this is borderline against the available `AlertDialog` width; in landscape it is needlessly narrow; at large system text scale it can overflow.
**Fix.** Derive width from `MediaQuery.sizeOf(context).width` clamped to a dialog-width token, or use a `ConstrainedBox`.

### Medium · Feedback & States · `canvas_editor_page.dart:307-309` — unlabelled loading spinner
**Problem.** The loading state is a bare centered `CircularProgressIndicator`. For a canvas that hydrates many elements from SQLite, a slow load reads as a hang.
**Fix.** Add a "Loading canvas…" label below the spinner using `AppTextStyles`.

### Low · Visual Consistency · `canvas_editor_page.dart:256-268` — magic numbers in the note dialog
**Problem.** Hardcoded `width: 420`, `minLines: 5`, `maxLines: 10`; no `AppSpacing` tokens.
**Fix.** Use the dialog-width token and `AppSpacing`.

---

## `canvas_controller.dart`

### High · Feedback & States · `canvas_controller.dart:1660-1749` — import failures are completely silent
**Problem.** `importImage` and `importPdf` call throwing operations (`CanvasImporter.pickImage`, `pdfRasterService.probe`) with no `try/catch` — the `try` block only has a `finally` that resets `_isImporting`. On a corrupt/locked/unreadable file the exception propagates unhandled: the toolbar button un-greys, nothing appears on the canvas, and there is no error message. A failed import is indistinguishable from a cancelled or a slow one — the feature looks broken.
**Fix.** Catch import errors in both methods and surface them. Expose an error signal (an `importError` field + notify, or a callback) that `CanvasEditorPage` turns into a SnackBar ("Couldn't import that image / PDF").

### Medium · Feedback & States · `canvas_controller.dart:882-890` — `clear()` wipes the canvas with no confirmation
**Problem.** `clear()` removes every element on the canvas. The toolbar wires it directly to an icon button (`canvas_toolbar.dart:341-345`). One mistaken tap wipes everything. It is undoable via `ClearCommand`, but undo discoverability is low (icon-only button, no SnackBar).
**Fix.** Confirm the clear with a dialog, or perform it and immediately show a SnackBar with an "Undo" action wired to `controller.undo`.

### Medium · Feedback & States · `canvas_controller.dart:1219-1229` — delete/erase have no undo affordance
**Problem.** Deleting a lasso selection (and erasing) produces no SnackBar and no Undo affordance; the only undo path is the icon-only toolbar button.
**Fix.** Have the page/view surface a SnackBar with Undo after `deleteSelection`.

### Low · Touch/Input · `canvas_controller.dart:281` — tap slop is tight for stylus
**Problem.** `tapSlop = 8.0` logical px gates tap-vs-drag for all input. For a slightly shaky stylus tap (placing/following a link) this can register as a drag and be ignored.
**Fix.** Consider ~10–12 px, or `kTouchSlop`, which Flutter tunes per platform.

---

## `canvas/widgets/canvas_toolbar.dart`

### High · Layout/Overflow · `canvas_toolbar.dart:57-84` — toolbar wraps to 3+ rows in portrait
**Problem.** The toolbar is a single `Wrap`. With the pen tool active the children are: 7-segment tool toggle + 2-segment kind toggle + 6 swatches + 3 width buttons + 2 insert actions + 4 action buttons + dividers. In tablet portrait (~800 logical px) this wraps to 3+ rows, consuming a large vertical band above the canvas and pushing the drawing area down. The eraser tool's labelled segments widen it further. There is no scrollable fallback.
**Fix.** Make the toolbar horizontally scrollable (`SingleChildScrollView(scrollDirection: Axis.horizontal)`) or collapse color/width controls into a popover. A multi-row wrapping toolbar over a canvas wastes vertical space.

### Medium · Accessibility · `canvas_toolbar.dart:361-367` — segments opt out of the 48 dp minimum
**Problem.** `_segmentStyle` sets `tapTargetSize: MaterialTapTargetSize.shrinkWrap` on every `SegmentedButton`, explicitly opting out of the 48 dp minimum. With 7 tool segments plus contextual segments in a compact bar, individual hit areas can fall well below the Android accessibility minimum.
**Fix.** Drop `shrinkWrap` (keep `padded`) so each segment retains a 48 dp target; `compact` visual density is fine, opting out of the minimum target is not.

### Medium · Accessibility · `canvas_toolbar.dart:399-462` — swatch and width buttons are sub-48 dp
**Problem.** Swatches are 28 px containers and width dots are 32 px (`InkResponse radius: 22`). Both are well below the 48 dp minimum for a frequently-repeated action.
**Fix.** Wrap each in a 48×48 hit region; the visual dot can stay small while the tap target meets the minimum.

### Medium · UX Flow · `canvas_toolbar.dart:62-68` — active tool is not obvious
**Problem.** Tool-mode clarity relies on the `SegmentedButton`'s subtle selected styling, plus a transient hint for *only* the link and text tools. Pen/eraser/lasso/shape/pan get no in-canvas cue — a user who set the eraser, panned, and returned has no obvious signal that the next stylus stroke will erase, not draw.
**Fix.** Give every tool a consistent one-line hint, or add an in-canvas cue for lasso/shape/pan (the hover ring already differentiates pen vs eraser).

### Medium · Visual Consistency · `canvas_toolbar.dart` (lines 25-35, 56, 144-166, 357, 399-462) — pervasive magic values
**Problem.** `_swatches` are raw ARGB ints (the gold `0xFFE8B84B` duplicated from `AppColors`); padding/spacing literals (`8`, `6`); divider/swatch/width sizes (`28`, `32`, `1`); hint text uses inline `TextStyle(... fontSize: 13)` instead of `AppTextStyles`.
**Fix.** Replace literals with `AppSpacing`, route the gold through `AppColors`, use `AppTextStyles` for hint text.

### Low · Accessibility · `canvas_toolbar.dart:195-217` — eraser mode toggle is inconsistent and jargon-y
**Problem.** The eraser-mode segments show both icon and text label while every other toggle is icon-only. The labels "Object" / "Split" are jargon.
**Fix.** Be consistent (all toggles labelled or none); if keeping labels, "Whole" / "Partial" (or "Erase" / "Trim") is clearer.

### Low · Feedback & States · `canvas_toolbar.dart:307-324` — no positive loading state on import
**Problem.** The add-image / add-PDF buttons grey out while `isImporting`, but show no progress. A slow import looks identical to a failed one (see the controller's silent-failure finding).
**Fix.** Show a small `CircularProgressIndicator` in place of the icon while `controller.isImporting`.

---

## `canvas/widgets/canvas_bookmarks_menu.dart`

### Medium · Feedback & States · `canvas_bookmarks_menu.dart:62-70` — bookmark deletion has no confirmation/undo
**Problem.** The trailing close `IconButton` deletes a bookmark immediately — no confirmation, no SnackBar, no Undo.
**Fix.** Confirm deletion, or show a SnackBar with Undo after `removeBookmark`.

### Medium · Accessibility · `canvas_bookmarks_menu.dart:62-64` — tiny destructive target next to the navigate target
**Problem.** The remove button is an 18 px icon in a dense `ListTile` trailing slot, well under 48 dp, sitting right next to the row's tap-to-navigate area — easy to mis-tap (delete vs jump).
**Fix.** Increase the hit target to 48 dp and visually separate the destructive action from the navigate action.

### Medium · Layout/Overflow · `canvas_bookmarks_menu.dart:54-72` — long bookmark names clip in the popup
**Problem.** Each row is a `ListTile` with a leading icon and trailing `IconButton` inside a `PopupMenuItem` with no explicit width; a long name can clip or force the popup very wide.
**Fix.** Constrain the popup item width (`SizedBox`/`ConstrainedBox`) so long names ellipsize predictably.

### Medium · Feedback & States · `canvas_bookmarks_menu.dart:43-52` — no confirmation after saving a view
**Problem.** After `saveBookmark` succeeds the menu just closes; the user cannot tell the save worked without reopening the menu.
**Fix.** Show a brief "View saved" SnackBar after a successful save.

### Low · Visual Consistency · `canvas_bookmarks_menu.dart` — icon sizes are literals
**Fix.** Use `AppIconSizes`/`AppSpacing` tokens for icon sizing.

---

## `canvas/widgets/link_target_dialog.dart`

### High · Feedback & States · `link_target_dialog.dart:156-195` — load failure is masked as "no canvases"
**Problem.** The `FutureBuilder` over `_optionsFuture` has no error branch. If the canvas-list future rejects, `connectionState` is `done`, `snapshot.data` is `null`, `options` is empty, and the dialog shows **"No other canvases to link to."** — telling the user there is nothing to link when in fact the load failed.
**Fix.** Check `snapshot.hasError` and show a distinct error state ("Couldn't load canvases — try again").

### Medium · UX Flow · `link_target_dialog.dart:125-133` — autofocus lands on the optional field
**Problem.** The optional "Label" field is `autofocus: true` and first; the *required* target picker is second and unfocused. A user can type a label and find "Add link" still disabled with no hint pointing to the target picker.
**Fix.** Autofocus the required target/id input instead, or add helper text on the target field explaining why the button is disabled.

### Medium · Layout/Overflow · `link_target_dialog.dart:119` — hardcoded non-responsive width
**Problem.** `SizedBox(width: 360)` — a third distinct hardcoded dialog width in the app.
**Fix.** Use the shared dialog-width token.

### Low · Visual Consistency · `link_target_dialog.dart:134` — magic spacing
**Fix.** `SizedBox(height: 16)` → `AppSpacing.lg`.

### Low · UX Flow · `link_target_dialog.dart:168-169` — empty state is a dead end
**Problem.** "No other canvases to link to." offers no way forward but Cancel.
**Fix.** Consider an affordance to create a canvas inline.

---

## `canvas/render/canvas_view.dart`

### Medium · Touch/Input · `canvas_view.dart:256-286` — pinch jitter when a third touch lands
**Problem.** `_applyPinch` always uses `_touchPositions[0]` / `[1]` — the first two entries in `Map.values` iteration order. If a user mid-pinch rests a third finger or a palm, the two indexed offsets can reorder between moves without a touch-count change, making the pinch jump.
**Fix.** Track the specific two pointer ids that began the pinch and keep using those, rather than indexing into iteration order.

### Medium · Touch/Input · `canvas_view.dart:195-201, 264-273` — palm landing before the stylus pans the canvas
**Problem.** Palm rejection works *once* `_toolPointerId` is set. But a palm that lands and moves in the gap *before* the stylus touches down starts a one-finger pan, shifting the canvas out from under the user's intended stroke origin.
**Fix.** Hard problem; at minimum ignore a single touch that began very recently when a stylus goes down, or require two touches for any viewport transform (the pan tool already covers deliberate one-pointer panning). Worth a code comment acknowledging the gap.

### Medium · Feedback & States · `canvas_view.dart:447-452` — no cursor affordance for mouse/pan
**Problem.** No `MouseCursor` is set per tool, so the dev-preview web/mouse target gets no cursor feedback (no grab cursor for pan, no precise cursor for pen).
**Fix.** Set an appropriate `MouseCursor` on the `MouseRegion` based on `activeTool`.

### Low · Touch/Input · `canvas_view.dart:454-466` — trackpad zoom is jumpy
**Problem.** Scroll-wheel/trackpad zoom uses a fixed `1.15` factor per event, ignoring `scrollDelta` magnitude; trackpad scroll emits many small events, making zoom extremely fast.
**Fix.** Scale the factor by `scrollDelta.dy` magnitude (e.g. `exp(-dy * k)`).

### Low · Feedback & States · `canvas_view.dart:565-569` — per-build post-frame callback
**Problem.** `addPostFrameCallback` is registered on every build to run `_syncRasterScheduling`; rebuilds happen on every `notifyListeners` (every stroke sample, every pan delta). Churn, and fragile against a stale `context.size` during rotation.
**Fix.** Prefer a `LayoutBuilder`/`SizeChangedLayoutNotifier` to react to actual size changes.

---

## `canvas/render/elements_painter.dart`

### Medium · Visual Consistency · `elements_painter.dart:228-246` — hardcoded chrome colors
**Problem.** `_selectionHalo`, `_placeholderFill`, `_placeholderBorder`, `_accent`, `_linkChipFill` are all raw literals; the gold `E8B84B` is duplicated from `AppColors` and the toolbar.
**Fix.** Derive these from `AppColors` so a theme change does not leave canvas chrome stale.

### Low · Accessibility · `elements_painter.dart:240, 350-376` — selection signalled only by a faint halo
**Problem.** A selected ink element is signalled only by a low-alpha gold halo (`0x55`). Against arbitrary stroke colors / on a bright panel this is weak and is the sole cue.
**Fix.** Give selected ink a clearly visible bounding affordance (handles/box), not only a translucent halo.

### Low · Feedback & States · `elements_painter.dart:385-421` — image/PDF placeholders look blank
**Problem.** While a raster loads, `_paintPlaceholder` draws a near-invisible rectangle (fill alpha ~8 %, border ~20 %) with no spinner/label/icon. A multi-page PDF shows several barely-visible rectangles indistinguishable from empty placeholders.
**Fix.** Draw a centered progress/page icon (or "Loading") so an in-progress raster reads as rendering.

---

## `canvas/render/canvas_overlay_painter.dart`

### Medium · Accessibility / Visual Consistency · `canvas_overlay_painter.dart:63-221` — faint pen hover ring + hardcoded colors
**Problem.** All colors are literals (the gold `_accent` is the third copy). The pen hover ring at white-alpha `0x66` with a 1 px stroke is very faint — over a light image or PDF page it can be nearly invisible, losing the pen-position affordance exactly where content is busiest.
**Fix.** Route the accent through `AppColors`; raise the hover-ring contrast or give it a thin dark outline so it survives over light content.

### Low · Touch/Input · `canvas_overlay_painter.dart:74-99` — hover ring disappears for thin pens
**Problem.** The hover ring radius is `penWidth * scale`; at a thin 2 px pen zoomed out it becomes a sub-pixel ring and the cursor effectively vanishes.
**Fix.** Clamp to a minimum on-screen radius (e.g. `max(radius, 3)`).

---

## `canvas/render/grid_painter.dart`

### Low · Visual Consistency · `grid_painter.dart:78` — grid color hardcoded
**Problem.** Grid dots are `Color(0x24FFFFFF)`; not derived from the theme, so a light canvas surface would make them vanish.
**Fix.** Derive the grid color from the theme surface/onSurface.

### Low · Feedback & States · `grid_painter.dart:90-99` — grid density at extreme zoom
**Problem.** At extreme zoom the grid hits `_minStep`/`_maxStep` clamps and looks too dense (moiré) or too sparse.
**Fix.** Cosmetic; optionally fade the grid out past the clamp.

---

## `canvas/render/live_stroke_painter.dart`

No standalone UI/UX issue. Minor nit: `_highlighterOpacity = 0.35` is duplicated from `ElementsPainter`; the two must be kept in sync by hand or a live highlighter stroke will not match its committed appearance. Hoist to one shared constant.

---

## `canvas/input/pointer_classifier.dart`

### Low · Touch/Input · `pointer_classifier.dart:39-42` — trackpad behaves like a mouse
**Problem.** `PointerDeviceKind.trackpad` maps to `CanvasInputKind.mouse`, so a trackpad "follows the active tool" and would draw with the pen tool — contradicting the "two-finger pan" mental model. Dev-preview only.
**Fix.** Route trackpad pan gestures to viewport transforms, or document the behaviour.

### Low · Touch/Input · `pointer_classifier.dart:54-60` — `unknown` pointers are a silent no-op
**Problem.** An `unknown` pointer kind is neither `followsTool` nor touch, so it neither pans nor draws — the canvas is completely unresponsive to an unrecognised digitizer with no feedback.
**Fix.** Treat `unknown` as touch (pan) or mouse (tool) so the canvas is never silently dead to an input device.

---

## `canvas/io/canvas_import.dart`

### High · Error Handling · `canvas_import.dart:87-133` — `pickImage`/`pickPdf` throw with no caller catch
**Problem.** Both methods throw on unreadable/corrupt/locked files (`readAsBytes`, `instantiateImageCodec`, `pdfRasterService.probe`, `File.copy`, even `FilePicker.pickFiles` itself can throw). The controller does not catch them (see the controller High finding). Net effect: a bad/locked PDF produces an unhandled exception, no SnackBar, an unchanged canvas — a failed import is indistinguishable from a cancelled or a slow one.
**Fix.** Either return a `Result`-style success/failure instead of throwing, or ensure the controller wraps these in `try/catch` and surfaces a user-facing error.

---

## `canvas/pdf/pdf_raster_service.dart`

### Medium · Feedback & States · `pdf_raster_service.dart:121-209` — permanently failed pages stay invisible placeholders
**Problem.** `probe` throws on a non-readable PDF; `rasterizePage` returns `null` on failure, and `_loadPdfRaster` treats `null` as "just return". A page that *permanently* fails to render stays a faint placeholder forever, with no error and no retry — the user sees blank boxes and cannot tell failure from slowness.
**Fix.** Distinguish "render failed" from "render pending" so the painter can show an error state on a page that will never render; surface a failure rather than a bare `null` at the service boundary.

### Low · Feedback & States · `pdf_raster_service.dart:97-106` — init failure throws on every PDF interaction
**Problem.** If `pdfrxFlutterInitialize()` fails, the exception propagates through every `probe`/`rasterizePage` call with no user feedback.
**Fix.** Catch init failure once and surface "PDF support unavailable".

---

## `canvas/model/viewport_state.dart`

No UI/UX issues — a pure immutable value type with no user-facing surface.

---

## Top canvas fixes

1. **Silent import failures** — `importImage`/`importPdf` + `pickImage`/`pickPdf` throw on a bad file with no catch and no feedback; the feature looks broken.
2. **Link dialog masks a load failure** as "No other canvases to link to."
3. **Toolbar `Wrap` becomes 3+ rows in tablet portrait**, stealing canvas space — make it scroll horizontally.
4. **App bar title is a static "Canvas"** — no orientation when following link chains.
5. **Emptying a note and pressing Save silently deletes it**; multiple touch targets are sub-48 dp.
6. Back-navigation save-error check covers only the app-bar button — wrap the page in `PopScope`.
