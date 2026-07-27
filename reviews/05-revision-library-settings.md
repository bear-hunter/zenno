# Revision, Library & Settings — UI/UX Review

Scope: `features/revision/presentation/*`, `features/library/presentation/*`, `features/settings/presentation/*`, plus the related provider files.

Findings: 2 High · 12 Medium · 18 Low.

Line numbers are as of the review; verify against current source before editing.

---

## `revision_board_page.dart`

### Low · Feedback & States · `revision_board_page.dart:33` — bare loading spinner
**Problem.** The board loading state is a lone `CircularProgressIndicator` floating in a large tablet void.
**Fix.** Acceptable for a fast local-DB read; consider a skeleton of the column layout. Low priority.

### Low · UX Flow · `revision_board_page.dart:59-61` — per-minute full-board rebuild
**Problem.** A 1-minute `Timer.periodic` rebuilds the entire `_BoardBody` (and the whole `KanbanBoardView`) just to refresh "13d ago" labels — wasteful, and it can interrupt an in-progress drag animation frame. Relative labels do not change at sub-hour resolution.
**Fix.** Increase the interval to ~1 hour, or push the clock down to the `_RevisedAgo` widgets via an `InheritedWidget`/provider so the board itself does not rebuild.

### Low · Visual Consistency · `revision_board_page.dart:98` — magic icon size
**Problem.** `Icon(..., size: 56)` — the same literal duplicated in `_LibraryMessage` and `_SettingsMessage`.
**Fix.** Promote to an icon-size token; unify the three message panels.

---

## `revision_card_tile.dart`

### Medium · Layout/Overflow · `revision_card_tile.dart:55-91` — footer can overflow
**Problem.** The footer `Row` is `MasteryFlagChip` → `Spacer()` → `_RevisedAgo`. `_RevisedAgo` (an icon + `Text`) is not wrapped in `Flexible` and its `Text` has no `maxLines`/ellipsis. With a long mastery label plus a long relative string in a ~200 px Kanban column, the row overflows.
**Fix.** Wrap `_RevisedAgo` in `Flexible` and give its `Text` `overflow: TextOverflow.ellipsis, maxLines: 1`; consider `Flexible` around the chip too.

### Low · Accessibility · `revision_card_tile.dart:85-92` — decorative icon + terse timestamp
**Problem.** The `history` icon is decorative; the terse "13d ago"/"Not revised" string is brief for assistive tech.
**Fix.** Wrap the icon in `ExcludeSemantics`; add a `Semantics(label: 'Last revised 13 days ago')`.

---

## `mastery_flag_chip.dart`

### Medium · Accessibility · `mastery_flag_chip.dart:42-71` — color-only flag signalling
**Problem.** The mastery flag is conveyed by a colored dot and a colored border tint — both purely chromatic. The text label ("Confident"/"Shaky"/"Weak") is the saving grace, but the **dot itself is a shape-identical circle** for all three flags, and on the small `dense` chip green↔yellow are hard to distinguish for deuteranopia. The same dot is reused in `_FlagChoice` in the detail sheet.
**Fix.** Differentiate the dot by shape (circle / triangle / square) or a tiny glyph (check / dash / exclamation) so the signal survives grayscale and small size. Fix it in `_FlagChoice` too for consistency.

### Low · Accessibility · `mastery_flag_chip.dart:48-50` — faint chip border
**Problem.** The border (alpha 0.5) and fill (alpha 0.16) are low-contrast washes; `flagYellow` at 0.5 alpha on `#121212` is faint.
**Fix.** Bump border alpha to ~0.6 for the dense variant. (Label text uses `onSurface`, so text contrast is fine.)

---

## `revision_card_detail_sheet.dart`

### High · UX Flow / Feedback · `revision_card_detail_sheet.dart:155-171, 367-378` — a flag write freezes the whole sheet
**Problem.** Tapping a mastery flag sets `_flagSaving`, which sets `_busy`, which nulls every other flag's `onTap` *and* disables Mark revised / Delete / Save — with no spinner anywhere explaining why the sheet went inert. A user who taps a flag then immediately taps "Mark revised" finds the button dead with no explanation.
**Fix.** Show a small inline progress indicator next to the "Mastery" header (or on the touched chip) while `_flagSaving`, and do not gate the unrelated buttons on a flag write — flag writes are independent of text/mark/delete.

### Medium · Feedback & States · `revision_card_detail_sheet.dart:155-171` — flag change has no success confirmation
**Problem.** Setting a flag produces only a *failure* SnackBar. Marking revised, saving, and deleting all confirm; flag changes do not — inconsistent.
**Fix.** Add a subtle "Mastery updated" SnackBar, or rely on the optimistic check icon and accept silence — but make the choice deliberate.

### Medium · Touch/Input · `revision_card_detail_sheet.dart:478-516` — `_FlagChoice` is sub-48 dp
**Problem.** The flag-choice `InkWell` has `AppSpacing.sm` (8) vertical padding around a 12 px dot + label — total height ~36 px, below the 48 dp minimum for a primary interaction on a stylus tablet.
**Fix.** Add `constraints: BoxConstraints(minHeight: 48)` or increase vertical padding to `AppSpacing.md`.

### Medium · UX Flow · `revision_card_detail_sheet.dart:173-198` — "Mark revised" closes the sheet
**Problem.** Mark revised pops the sheet on success. But the sheet is the only place to set the mastery flag and manage attachments. The natural flow "I just revised this, it went well, bump it to green" is broken — the sheet is gone, forcing the user to reopen the card.
**Fix.** Do not auto-close on Mark revised; update `_RevisionStats` in place (the stream re-emits) and show the SnackBar over the still-open sheet. If auto-close is intentional, prompt for the new flag before closing.

### Medium · Feedback & States · `revision_card_detail_sheet.dart:200-243` — silent delete
**Problem.** The delete confirm dialog's destructive button is correctly styled, but after a successful delete the sheet just pops with no SnackBar. Marking revised confirms; the more consequential, irreversible delete is silent.
**Fix.** Show a "Card deleted" SnackBar (ideally with Undo) after the pop, using a captured `ScaffoldMessenger`.

### Low · UX Flow · `revision_card_detail_sheet.dart:432-447` — "Mark without saving" understates the loss
**Problem.** Editing the title then tapping "Mark revised" shows a 3-option dialog; "Mark without saving" silently discards the title edit but sounds benign.
**Fix.** Reword to "Mark & discard edits".

### Low · Accessibility · `revision_card_detail_sheet.dart:397-443` — busy state not announced
**Problem.** Async buttons swap to an 18 px spinner and change their label, but the change is not semantically announced unless focus is on the button.
**Fix.** Optionally wrap the busy state in `Semantics(liveRegion: true)`.

### Low · Visual Consistency · `revision_card_detail_sheet.dart:398-440` — duplicated spinner literals
**Problem.** Spinner `dimension: 18`, `strokeWidth: 2` are hardcoded and repeated across three buttons.
**Fix.** Extract a shared `_ButtonSpinner` widget/constant.

---

## `revision_providers.dart`

No UI/UX issues — controller/provider wiring with no presentation surface.

---

## `library_page.dart`

### Medium · Feedback & States · `library_page.dart:28-33` — `_createCanvas` has no loading/error handling
**Problem.** `_createCanvas` does `await ref.read(libraryRepositoryProvider).createCanvas()` then navigates, with no loading indication and no `try/catch`. If `createCanvas()` throws (disk full, DB locked), the exception is unhandled, the FAB does nothing visible, and the user taps a dead button.
**Fix.** Wrap in `try/catch` with a failure SnackBar; show a brief progress state while the create is in flight.

### Medium · Layout/Overflow · `library_page.dart:71-82` — grid card footer can overflow
**Problem.** `SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 260, childAspectRatio: 4/3)`. In portrait the grid yields ~3 columns; the footer (title + "13d ago" + a 48 dp `more_vert`) must fit in the non-thumbnail portion. At a large system font scale the two text lines + the 48 dp icon can exceed it and overflow the `Column`.
**Fix.** Raise `childAspectRatio` so the footer has breathing room (e.g. `3/3.4`), or fix the footer height and let only the thumbnail flex. Test at 1.3× text scale.

### Low · UX Flow · `library_page.dart:47-48` — sort menu rewrites a global preference
**Problem.** The app-bar sort `PopupMenuButton` writes the *same persisted setting* as Settings → Library → "Default sort". A user expecting a transient view toggle will be surprised the sort stuck app-wide.
**Fix.** The `initialValue: activeSort` checkmark partially signals it. Acceptable if intentional; note the dual-control coupling.

### Low · Feedback & States · `library_page.dart:58-69` — (positive)
The library error panel and empty state are clean and well-built; the empty state correctly references the FAB label. No issue.

---

## `canvas_card.dart`

### High · Feedback & States · `canvas_card.dart:79-112` — rename/delete have no error handling or feedback
**Problem.** Both `renameCanvas` and `deleteCanvas` are awaited with no `try/catch` and no result feedback. A failed rename or — critically — a failed delete throws unhandled with no SnackBar. For delete: the dialog says "This cannot be undone," the user confirms, and on a failed write they get zero signal about whether the canvas is gone.
**Fix.** Wrap both writes in `try/catch`; show a failure SnackBar on error and a "Canvas deleted"/"Renamed" confirmation on success. Capture `ScaffoldMessenger` before the `await`.

### Medium · Error Handling · `canvas_card.dart:199-218` — synchronous filesystem stat on every build
**Problem.** `_CanvasThumbnail` calls `File(filePath).existsSync()` on every build of every visible card — synchronous I/O during grid scroll, a visible jank source on a large library. There is also a TOCTOU race between the check and `Image.file` decoding (caught by `errorBuilder`, so harmless).
**Fix.** Drop the `existsSync()` pre-check entirely — `Image.file`'s `errorBuilder` already handles a missing file. Removes the per-build sync I/O and the race in one change.

### Medium · Touch/Input · `canvas_card.dart:122-179` — overflow menu crowds the card-open gesture
**Problem.** The whole card is an `InkWell` (`onTap` → open) with the `more_vert` `PopupMenuButton` inside it. A slightly-off tap on the menu opens the canvas instead — a frequent mis-tap with a stylus.
**Fix.** Standard pattern, acceptable; consider padding around the `PopupMenuButton` so its 48 dp target does not crowd the card edge.

### Low · Layout/Overflow · `canvas_card.dart:129-134` — asymmetric footer padding
**Problem.** Footer padding `fromLTRB(md, sm, xs, sm)` leaves only 4 on the right, pushing the menu's 48 dp target close to the card edge.
**Fix.** Minor — verify the menu icon is not visually cramped against the border.

### Low · Accessibility · `canvas_card.dart:127-218` — card has no semantic role
**Problem.** The card `InkWell` has no `Semantics` label/role hint that tapping opens an editor.
**Fix.** Wrap in `Semantics(button: true, label: 'Open canvas ${canvas.title}')`.

### Low · UX Flow · `canvas_card.dart:52-79` — empty rename silently does nothing
**Problem.** The rename dialog pops the trimmed value; an empty/whitespace submit pops `''`, and line 79 guards `isNotEmpty`, so an empty rename silently closes the dialog — the user may think they renamed to blank.
**Fix.** Show a validation error in-dialog for empty input, or disable the Rename button when the field is empty.

---

## `library_providers.dart`

No UI/UX issues — pure provider wiring.

---

## `settings_page.dart`

### Medium · Feedback & States · `settings_page.dart:76-166` — every settings write is fire-and-forget
**Problem.** `setThemeMode`, `setPomodoroWork`, `setFlowBreakRatio`, `setLibrarySort`, `setKeepScreenOnInFocus`, etc. are all called without `await`, without `try/catch`, with no failure feedback. A failed write leaves the control showing the new value optimistically while the persisted setting silently did not change; the next stream emit snaps the control back with no explanation.
**Fix.** Catch write failures and show a SnackBar. The controls are stream-driven, so a failed write that does not re-emit leaves the UI lying.

### Medium · Feedback & States · `settings_page.dart:388-395` — slider writes to the DB on every drag pixel
**Problem.** The `_SliderTile` `Slider`'s `onChanged` fires continuously while dragging, calling `setFlowBreakRatio` dozens of times per drag — a write storm. There is no `onChangeEnd`.
**Fix.** Hold a local state value for live drag feedback; commit to the repository only in `onChangeEnd`.

### Low · Touch/Input · `settings_page.dart:304-325` — no press-and-hold on the stepper
**Problem.** `_StepperTile` has 48 dp `IconButton.outlined`s (good target size) but no long-press repeat. Going from 10 min to 240 min (`step: 10`) needs 23 taps.
**Fix.** Add press-and-hold acceleration, or pair with a slider, or widen the step.

### Low · Visual Consistency · `settings_page.dart:312` — magic fixed width
**Problem.** The stepper value uses a hardcoded `SizedBox(width: 88)`; at a large font scale "240 min" could clip or wrap.
**Fix.** Use a `ConstrainedBox(minWidth: ...)` or size to content; if a fixed width is needed, derive it from a token.

### Low · Accessibility · `settings_page.dart:308-324` — context-free stepper tooltips
**Problem.** The −/+ tooltips say "Decrease"/"Increase" with no mention of *what* — a screen reader on "+" hears "Increase" without "Pomodoro work".
**Fix.** Make tooltips specific, e.g. `tooltip: 'Increase $title'`.

### Low · UX Flow · `settings_page.dart:105-114` — unexplained "Flowmodoro" jargon
**Problem.** The "Flowmodoro break ratio" slider sits next to plain Pomodoro steppers; "Flowmodoro" is unexplained.
**Fix.** A one-line clarification or a help affordance.

### Low · Feedback & States · `settings_page.dart:25-35` — error state has no retry
**Problem.** If settings fail to load, the `_SettingsMessage` panel has no retry — the user is stuck on a dead screen. (The Revision board `_BoardError` and the Library error panel share this gap.)
**Fix.** Add a "Retry" button calling `ref.invalidate(appSettingsProvider)`.

---

## `settings_providers.dart`

No UI/UX issues — pure provider wiring.

---

## Top revision / library / settings fixes

1. **`canvas_card` delete/rename and `library_page` create have no error handling and no feedback** — data-affecting actions with literally no failure path visible to the user. The delete dialog says "this cannot be undone," then a failed delete is silent. Highest priority here.
2. **Every `settings_page` write is fire-and-forget** — failures leave the UI in a lying state; the slider additionally writes to the DB on every drag pixel.
3. **The revision detail sheet freezes entirely on a flag write** with no spinner explaining why.
4. **Color-only mastery signalling** — the flag dot is shape-identical across green/yellow/red; differentiate by glyph/shape.
5. **No retry on any error state** — `_BoardError`, the Library error panel, and `_SettingsMessage` are all dead ends.
6. **`canvas_card` does a synchronous filesystem stat on every build**, a scroll-jank source — drop it and rely on `Image.file`'s `errorBuilder`.
