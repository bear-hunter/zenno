# Shared Kanban & Canvas Attachments — UI/UX Review

Scope: the shared Kanban board (`shared/kanban/*`) and the canvas-attachment UI (`shared/canvas_attachments/*`).

The Kanban board backs both the Goal Cycle and the Revision boards, so every finding here affects two features.

Findings: 5 High · 18 Medium · 12 Low.

Line numbers are as of the review; verify against current source before editing.

---

## `kanban_board_view.dart`

### High · UX Flow / Touch/Input · `kanban_board_view.dart:99-141` — no autoscroll while dragging near a board edge
**Problem.** The board is a horizontally-scrolling `SingleChildScrollView` and columns are vertically-scrolling `ListView`s. `LongPressDraggable` does not auto-scroll its ancestors. On a Tab S9 FE in landscape with 4+ columns, the user physically cannot move a card to an off-screen column, or reorder a column past the viewport — the drag stalls at the edge. A core feature is effectively broken for any non-trivial board.
**Fix.** Make a drag near the edge trigger scrolling — attach an `EdgeDraggingAutoScroller` driven from `LongPressDraggable.onDragUpdate` (scroll the relevant `ScrollController` when the pointer enters an edge band ~80 px wide), or adopt a Kanban package with built-in autoscroll.

### High · Touch/Input / Feedback & States · `kanban_board_view.dart` (with `kanban_column_view.dart:450-465`) — long-press drag has no "armed" feedback and collides with tap
**Problem.** `LongPressDraggable` is used with no visible cue that the long-press timer has elapsed. The default ~500 ms long-press is easy to under-shoot (registers as a tap, opening the detail sheet) or over-shoot. The user gets no signal that the card is grabbed until it has already moved. With an S Pen a long-press-hold is awkward.
**Fix.** Confirm `hapticFeedbackOnStart` fires on-device. Add a visual "armed" cue at `onDragStarted` (scale/elevation bump on the source card). Consider making the existing `drag_indicator` handle the explicit grab area so users have a discoverable, deliberate grab point instead of long-pressing the whole card body (which competes with `onTap`).

### Medium · Touch/Input · `kanban_board_view.dart:178-189` — inter-column drop zones are nearly invisible and unhittable
**Problem.** `_ColumnDropZone` is `AppSpacing.xs` (4 px) wide, growing to `AppSpacing.sm` (8 px) on hover. An 8 px-wide drop target is far below 48 dp and is practically impossible to land a dragged column on — especially when the column feedback pill obscures the area. Column reorder is technically present but practically unusable.
**Fix.** Keep the visible indicator thin but widen the `DragTarget` hit area (24–32 px), or make adjacent columns the drop targets (left half = insert before, right half = insert after) with a clear insertion-line indicator.

### Medium · UX Flow · `kanban_board_view.dart:99-101` — horizontal scrollability is not discoverable
**Problem.** When columns overflow there is no edge fade, no scrollbar, and no peeking partial column to signal more content. Users may not realise they can scroll right — and the "add column" button (the only thing past the fold) becomes invisible.
**Fix.** Add a `Scrollbar` around the `SingleChildScrollView`, and/or size columns so a sliver of the next column always peeks at the edge.

### Medium · Error Handling · `kanban_board_view.dart:347` (and `kanban_column_view.dart:814`) — raw exception strings shown to users
**Problem.** `_runKanbanAction` shows `'$errorMessage: $error'` in a SnackBar — e.g. "Could not add column: SqliteException(...)". Drift/SQLite stack-traced strings are meaningless and alarming, and get truncated by the SnackBar anyway.
**Fix.** Show only the human-readable `errorMessage`; log `$error` separately. Optionally add a "Retry" `SnackBarAction`.

### Medium · Feedback & States · `kanban_board_view.dart:252-271` (with `kanban_column_view.dart:330-365`) — no success feedback; column delete cascades with no Undo
**Problem.** Add/rename/delete produce no confirmation toast. Column deletion cascades all its cards and is gated only by a confirm dialog ("This cannot be undone") — there is no Undo, so a misclick permanently destroys cards.
**Fix.** Show a SnackBar after delete with an "Undo" action (re-insert the column + cards) and a few-second window before the cascade commits. A brief confirmation toast for add/rename is optional polish.

### Medium · Layout/Overflow · `kanban_board_view.dart:145-161` — `_columnWidthFor` reserves add-column space even when columns overflow
**Problem.** When `available / columnCount` falls below `KanbanColumnView.minWidth` (240), width clamps up to 240, producing content wider than the viewport — acceptable for a scroller *if* autoscroll is fixed. The trailing 64 px "add column" button is always reserved inline, wasting space precisely when it is scarcest.
**Fix.** When columns overflow, move the add-column affordance into an overflow menu rather than reserving width inline.

### Low · Visual Consistency · `kanban_board_view.dart:212-249` — add-column button reads as a real column
**Problem.** The compact add-column affordance uses a plain solid border, so it looks like a real column rather than an add tile.
**Fix.** Use a dashed-border painter for the add affordance, or accept the solid border.

---

## `kanban_column_view.dart`

### High · Accessibility · `kanban_column_view.dart:239-248` — column drag handle has no label or tooltip
**Problem.** The *card* drag handle has a tooltip ("Hold and drag to move") and the card has `Semantics`, but the *column* drag handle is a bare `Icon` inside a `LongPressDraggable` — no tooltip, no `Semantics`. A screen-reader user cannot tell it is interactive; sighted users get no hover tooltip.
**Fix.** Wrap the column handle in `Tooltip(message: 'Hold and drag to reorder column')` and `Semantics(label: 'Reorder column ${column.name}', button: true)`.

### Medium · Touch/Input · `kanban_column_view.dart:243-247, 507-511` — drag handles below 48 dp
**Problem.** The drag-indicator icons are 18–20 px with no surrounding padding. They are hard to grab precisely; the column handle sits next to the title, inviting mis-taps.
**Fix.** Wrap each handle in a `SizedBox`/`Padding` giving a ≥48×48 dp interactive region while keeping the glyph its current size.

### Medium · Touch/Input / UX Flow · `kanban_column_view.dart:450-497` — whole-card long-press drag conflicts with tap-to-open
**Problem.** The whole card is both a `LongPressDraggable` and an `InkWell` with `onTap`. The card shows a `drag_indicator` icon implying the *icon* is the handle, but long-pressing anywhere drags. A slightly-too-long tap meant to open the card instead arms a drag.
**Fix.** Pick one model — make only the `drag_indicator` icon the draggable handle, or remove the misleading icon and accept whole-card long-press drag. Make the affordance honest.

### Medium · Feedback & States · `kanban_column_view.dart:524-569` — drop indicator only appears at thin inter-card gaps
**Problem.** While dragging, the only feedback is a 56 px highlighted box at whichever 8 px inter-card gap the pointer hovers. The user must hover precisely between two cards to see any indicator; sweeping the dragged card over a card body shows nothing, so the drop location feels unpredictable. No "card slides aside" affordance.
**Fix.** Treat each card as a drop target split top/bottom-half (insert before/after), so hovering anywhere over the list shows an insertion line.

### Medium · Feedback & States · `kanban_column_view.dart:463` — source slot does not collapse during drag
**Problem.** `childWhenDragging` keeps the original slot at full height as a 35 %-opacity ghost. Combined with the gap-only drop indicator, the column shows a faded card *plus* a highlighted box — visually busy, and it is unclear whether dropping will duplicate the card. Standard Kanban UX collapses the source slot.
**Fix.** Use `childWhenDragging: const SizedBox.shrink()` (or an animated collapse) so the source slot closes and only the drop indicator shows the future position.

### Medium · UX Flow · `kanban_column_view.dart:145-209` — drops into a non-empty column's empty lower region do nothing
**Problem.** An empty column shows a full-bleed `_CardDropZone(expand: true)` — good. But in a non-empty column the only "drop at end" target is the 160 px trailing `SizedBox` plus the wrapping zone; empty space below the last card in a tall column is not a drop target, so dropping there silently does nothing.
**Fix.** Ensure the column body's wrapping `_CardDropZone` fills the full lane height so any drop below the last card appends.

### Medium · Error Handling · `kanban_column_view.dart:667-752` — name/title fields have no length cap
**Problem.** `_ColumnNameDialog._submit` validates only emptiness; a 500-char column name is silently stored (the header `Text` ellipsizes, so it does not overflow). `_CardDraftDialog` has the same no-max-length issue.
**Fix.** Add a reasonable `maxLength` with a `LengthLimitingTextInputFormatter`.

### Low · Visual Consistency · `kanban_column_view.dart:245-759` — magic numbers
**Problem.** Icon sizes `18`/`20`, drop-indicator `height: 56`, add-card `Size.fromHeight(44)`, dialog widths `420`/`520` — all literals. `44` is also below the 48 dp target.
**Fix.** Route through `AppSpacing`/tokens; bump `44` to `48`.

### Low · Visual Consistency · `kanban_column_view.dart:303-305` — bare `TextStyle` for the delete title
**Problem.** `Text('Delete column', style: TextStyle(color: colorScheme.error))` builds a bare `TextStyle`, losing the theme's font size/height for a `ListTile` title.
**Fix.** Use `textTheme.bodyLarge?.copyWith(color: colorScheme.error)`.

### Low · Layout/Overflow · `kanban_column_view.dart:184-188` — fixed 160 px trailing drop zone
**Problem.** A hardcoded 160 px invisible drop area below the last card leaves a large dead gap in a short column and forces extra scroll in a full one. `160` is also a magic number.
**Fix.** Make the trailing zone fill remaining space via the existing `expand` flag instead of a fixed height.

---

## `kanban_models.dart` / `kanban_controller.dart`

### Low · UX Flow · `kanban_models.dart:78-89` — `KanbanPositions.between` can collide after many same-slot reorders
**Problem.** Repeated midpoint insertions into the same slot converge to floating-point limits; two cards can end up with equal `position`, after which their visual order becomes non-deterministic between rebuilds (cards appear to "swap" on refresh). The doc comment expects the host to run a renormalisation pass, but nothing in this shared layer enforces or signals it.
**Fix.** Detect equal/NaN/Infinity results and trigger renormalisation, otherwise the user will eventually see cards reorder themselves.

(No other UI/UX issues — `kanban_models.dart` and `kanban_controller.dart` are otherwise pure data/contract files.)

---

## `canvas_picker_dialog.dart`

### High · Visual Consistency / UX Flow · `canvas_picker_dialog.dart:149-151` — raw `DateTime` rendered to the user
**Problem.** `Text('Opened ${canvas.lastOpenedAt}')` interpolates a raw `DateTime`, producing `Opened 2026-05-18 14:33:07.123456Z` in the subtitle. The codebase already has a purpose-built `relativeTime()` helper that is not used here. It looks unfinished/buggy.
**Fix.** `Text('Opened ${relativeTime(canvas.lastOpenedAt!)}')`.

### Medium · Feedback & States / UX Flow · `canvas_picker_dialog.dart:117-122` — empty title silently substitutes a default
**Problem.** If the title field is cleared, `_create` silently substitutes `widget.defaultTitle`; the user gets a canvas named something they did not choose, with no indication. The field has no error-state wiring.
**Fix.** Show an inline "Title required" error and block creation on empty, or show a hint that the default name will be used — do not silently override user input.

### Medium · Feedback & States · `canvas_picker_dialog.dart:138-157` — scrollable list with no scrollbar
**Problem.** The existing-canvas `ListView` is capped at `maxHeight: 280` with `shrinkWrap` and no `Scrollbar`. With many canvases the user gets a silently-scrolling region inside an `AlertDialog` with no indication more items exist below the fold.
**Fix.** Wrap the `ListView` in `Scrollbar(thumbVisibility: true)`.

### Medium · Error Handling · `canvas_picker_dialog.dart:117-122` — `_create` pops without a `mounted` check
**Problem.** `_create` pops without a `context.mounted` guard — inconsistent with the rest of the codebase, which guards `mounted` carefully.
**Fix.** Add a `mounted` check, or accept it as dialog-local and document.

### Low · UX Flow · `canvas_picker_dialog.dart:76-84` — title field not autofocused
**Problem.** Unlike the Kanban dialogs (`autofocus: true`), the canvas-title field is not autofocused, so creating a canvas needs an extra tap.
**Fix.** Add `autofocus: true`.

### Low · Visual Consistency · `canvas_picker_dialog.dart:71, 139` — magic numbers
**Problem.** Hardcoded dialog width `520` and list `maxHeight 280`.
**Fix.** Promote to tokens/named constants.

---

## `card_canvas_attachments_section.dart`

### High · Feedback & States / Error Handling · `card_canvas_attachments_section.dart:57-180` — attach/detach/rename swallow all errors
**Problem.** `_add` (`attachExisting`/`createAndAttach`), `_handleAction` (`detach`), and `_rename` (`renameLabel`) all await repo calls with no `try/catch` and no SnackBar on success *or* failure. A failed DB write is swallowed by the async gap and the user sees nothing happen (the list just does not update). Detach in particular silently removes an item with no confirmation and no Undo.
**Fix.** Wrap each repo call in `try/catch` showing an error SnackBar (mirror the Kanban `_runKanbanAction` pattern); add an "Undo" action for detach.

### Medium · UX Flow · `card_canvas_attachments_section.dart:142-144` — detach is destructive with no confirmation
**Problem.** Selecting "Detach" from the popup menu immediately deletes the attachment row — one tap, no "are you sure", no Undo. (The canvas itself survives, per the repo, but the user does not know that.)
**Fix.** Add an Undo SnackBar (preferred — keeps the flow fast) or a confirm dialog; clarify in the menu that the canvas is kept ("Detach (keeps canvas)").

### Medium · Error Handling · `card_canvas_attachments_section.dart:152-180` — rename dialog accepts an empty label silently
**Problem.** The Save button pops `controller.text` with no trim and no empty-check; the repo's `renameLabel` silently no-ops on empty, so the user can "Save" an empty label and nothing happens with no feedback.
**Fix.** Trim/validate in the dialog; show an inline error for empty input. Consider a `StatefulWidget`-owned controller, the consistent pattern.

### Medium · UX Flow · `card_canvas_attachments_section.dart:100-109` — two affordances for the same action
**Problem.** The whole `ListTile` is tappable to open the canvas, *and* a separate "open in new" `IconButton` does the identical `context.push`. The icon button implies a different/secondary behaviour that does not exist.
**Fix.** Keep the row tap as the open action and drop the redundant `IconButton` (leaving just the overflow menu), or keep the icon button and make the tile non-tappable — not both.

### Low · Layout/Overflow · `card_canvas_attachments_section.dart:101-125` — cramped trailing controls + unbounded title
**Problem.** `ListTile.trailing` is a `Wrap` of an `IconButton` + a `PopupMenuButton` (two 48 dp controls) in the limited trailing slot; a long `item.label` title (no `maxLines`/`overflow`) can crowd it.
**Fix.** Give the title `maxLines: 1, overflow: TextOverflow.ellipsis`; removing the redundant open `IconButton` (above) leaves a single trailing button and resolves the crowding.

---

## `card_canvas_attachment_providers.dart` / `card_canvas_attachment_repository.dart`

### Low · Feedback & States · `card_canvas_attachment_repository.dart:129` — duplicate attach is a silent no-op
**Problem.** `attachExisting` uses `InsertMode.insertOrIgnore`; attaching an already-attached canvas is ignored. From the picker the user sees the dialog close with no change and no "already attached" feedback. The picker also does not disable already-attached canvases.
**Fix.** In the picker, mark/disable canvases already attached to this card; or detect the no-op in the UI layer and toast "Already attached". (The repo behaviour itself is fine.)

(Otherwise data-layer files — no further UI/UX issues.)

---

## Top Kanban & attachments fixes

1. **No drag autoscroll** — cards and columns cannot be moved off-screen; the core Kanban interaction is broken on any real board. This affects both the Goal and Revision boards.
2. **Inter-column drop zone is 4–8 px wide** — column reorder is practically un-hittable.
3. **Canvas-attachment add/detach/rename swallow all errors** — silent failures, plus a destructive detach with no confirmation and no Undo.
4. **The column drag handle has no `Semantics`/tooltip** — inaccessible and undiscoverable.
5. **Raw `DateTime` is rendered in the canvas picker** — looks broken; the `relativeTime()` helper exists and is unused.
6. **Long-press whole-card drag conflicts with tap-to-open** and has no "armed" feedback — accidental drags and accidental sheet-opens.

Recurring themes: no success/Undo feedback on any mutating Kanban or attachment action; raw exception strings shown in SnackBars; drag handles and drop zones below the 48 dp touch minimum; pervasive magic numbers that should come from the token system.
