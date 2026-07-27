# Goal Cycle Feature — UI/UX Review

Scope: the Goal Cycle feature (goal kanban + reflection journaling + reflection templates) — `features/goal_cycle/presentation/*`, plus `goal_providers.dart`, `reflection_providers.dart`, `reflection_template_schema.dart`.

Findings: 5 High · 11 Medium · 11 Low.

Line numbers are as of the review; verify against current source before editing.

---

## `goal_card_detail_sheet.dart`

### High · Feedback & States · `goal_card_detail_sheet.dart:103-119` — no loading/feedback on Save
**Problem.** `_save` awaits two writes (`updateCard`, `setStatusNote`) then pops the sheet. There is no `_saving` flag, so Save stays enabled and tappable during the write — a double-tap fires two write batches. No spinner, no success SnackBar. The reflection editor and template editor both track `_saving` and disable Save; this sheet is the inconsistent one.
**Fix.** Add a `bool _saving`, gate the button (`onPressed: _dirty && !_saving ? _save : null`), show a spinner in place of the icon while saving.

### High · Error Handling · `goal_card_detail_sheet.dart:103-163` — Save/delete/date/note writes have no error handling
**Problem.** Every write here is awaited with no `try/catch`. If `updateCard`, `setStatusNote`, `setTargetDate`, or `deleteCard` throws, the future rejects unhandled and the sheet either stays open silently or the optimistic local `_targetDate` diverges permanently from the DB with no recovery. The other two editors wrap writes in `try/catch` — this sheet does not.
**Fix.** Wrap each write in `try/catch`; show a failure SnackBar and, for the date case, revert the optimistic `_targetDate`.

### High · UX Flow · `goal_card_detail_sheet.dart:202-352` — unsaved edits silently discarded
**Problem.** The sheet tracks `_dirty` but never guards dismissal. The user can edit Title/Summary/Status note then dismiss via scrim tap, drag-handle swipe, or system Back — all discard the edits with no warning. Easy to trigger accidentally with an S Pen.
**Fix.** Wrap the sheet body in `PopScope(canPop: !_dirty, ...)` and confirm "Discard changes?" when `_dirty`.

### Medium · UX Flow · `goal_card_detail_sheet.dart:114-137` — mixed autosave / manual-save in one form
**Problem.** The status note is written only on the explicit Save button, but the target date is written *immediately* on pick/clear. Two controls in the same section behave oppositely; if the user picks a date then dismisses without Save, the date persists but the note edits vanish.
**Fix.** Make both follow one model — defer the target date into `_save` (the more predictable choice for a form with a Save button), or make both immediate.

### Medium · Feedback & States · `goal_card_detail_sheet.dart:177-200` — reflection delete has no feedback
**Problem.** After the confirm dialog, `deleteEntry` is awaited with no `try/catch` and no feedback; a failure is silent (the reflection stays with no explanation), a success is unconfirmed.
**Fix.** `try/catch` with an error SnackBar; consider a brief success SnackBar.

### Medium · Layout/Overflow · `goal_card_detail_sheet.dart:379-402` — `_TargetDateRow` can overflow with a long date
**Problem.** The Row holds an icon, an `Expanded` date text, a conditional clear `IconButton`, and a `TextButton`. The date uses `DateFormat.yMMMMd()` (fully spelled out — far longer in some locales); with the `'Target: '` prefix baked into the same `Text`, the date itself becomes unreadable on a narrow portrait sheet.
**Fix.** Split `'Target: '` into a separate non-flex label so only the date ellipsizes, or use `DateFormat.yMMMd()`.

### Low · Accessibility · `goal_card_detail_sheet.dart:320-345` — destructive action signalled by color only
**Problem.** Delete and Save are equal-width side by side; Delete's only cue is red `foregroundColor`.
**Fix.** Acceptable (a confirm dialog already exists); verify the error-color contrast meets 4.5:1 against the sheet surface.

---

## `reflection_editor_page.dart`

### High · UX Flow · `reflection_editor_page.dart:110-167` — unsaved reflection answers discarded on back
**Problem.** A full-page editor whose answers live in `_answers`, with no dirty-tracking and no `PopScope`. The user can fill in an entire multi-prompt reflection, press the AppBar back arrow or system Back, and lose everything with no warning — real data loss for a journaling app.
**Fix.** Track whether `_answers` differs from `widget.existingEntry?.answers`, wrap the Scaffold in `PopScope`, confirm "Discard this reflection?" when dirty.

### Medium · UX Flow · `reflection_editor_page.dart:113-124` — Save disabled with no explanation
**Problem.** `canSave` requires `_answers.isNotEmpty`. If the user types nothing (or clears every field), Save is silently disabled with no hint why — no validation message, no helper text. It can read as a broken button.
**Fix.** Show inline helper text near Save when a schema is active but `_answers` is empty ("Fill in at least one prompt to save").

### Medium · Feedback & States · `reflection_editor_page.dart` / `reflection_form.dart:137` — no autofocus on the first field
**Problem.** Neither the template picker nor the first prompt field requests focus; after picking a framework, the user must precisely tap into the first prompt.
**Fix.** Give the first `_PromptField` `autofocus: true` (or a `FocusNode` focused once the schema is shown). Do not autofocus while the template dropdown is the active step.

### Low · Visual Consistency · `reflection_editor_page.dart:212-217` — bare error text in `_TemplatePicker`
**Problem.** The templates-load error renders as a bare red `Text`, inconsistent with the polished `_TemplatesError`/`_BoardError` blocks elsewhere, and offers no retry.
**Fix.** Use a consistent inline error treatment (icon + message) with an optional retry that invalidates `reflectionTemplatesProvider`.

---

## `template_editor_page.dart`

### High · UX Flow · `template_editor_page.dart:215-329` — unsaved template edits discarded on back
**Problem.** The editor manages name/description controllers and a whole `_prompts` list — none dirty-tracked, no `PopScope`. A user can build out a multi-prompt template and lose all of it with a single back press.
**Fix.** Snapshot initial state vs current to track dirtiness, wrap the Scaffold in `PopScope`, confirm "Discard changes?" on back.

### Medium · UX Flow · `template_editor_page.dart:224-236, 476-506` — read-only banner advertises an absent control
**Problem.** Opening a builtin shows `_ReadOnlyBanner` telling the user to use "Duplicate & edit" — but the editor has no Save *and no Duplicate* action. The duplicate affordance exists only back on the Templates page tile menu; the user is told to do something with no on-screen control to do it.
**Fix.** Add a "Duplicate & edit" `TextButton.icon` to the AppBar actions when `_readOnly`, calling the same flow the Templates page uses.

### Medium · Feedback & States · `template_editor_page.dart:170-180` — validation errors are transient SnackBars
**Problem.** An empty name or empty prompt list is reported only via SnackBar. The fields are plain `TextField` (no `errorText`), so the user reads a SnackBar that vanishes in seconds and must remember which field it meant; the name field is not scrolled into view or focused.
**Fix.** Show an `errorText` on the name field set on failed save; inline helper text under "Prompts" for the empty-list case.

### Medium · UX Flow · `template_editor_page.dart:99-101, 292-311` — last prompt cannot be removed, with no explanation
**Problem.** The editor force-keeps one `_PromptDraft` and disables the last row's remove button (`onRemove: _prompts.length > 1 ? ... : null`). The user gets no reason why the X is missing — it looks broken.
**Fix.** Keep the behaviour but add a subtle hint ("A template needs at least one prompt"), or always allow removal and rely on save-time validation.

### Low · Touch/Input · `template_editor_page.dart:416-422` — small drag handle
**Problem.** `ReorderableDragStartListener` wraps a bare 24 dp `Icon(Icons.drag_indicator)` with no padding — below 48 dp, finicky with a stylus.
**Fix.** Wrap the icon in a 48×48 region; add a `tooltip`/`Semantics` label ("Drag to reorder").

### Low · Accessibility · `template_editor_page.dart:416-422` — drag handle has no semantic label
**Problem.** Reordering is mouse/touch-only with no accessible alternative and no label.
**Fix.** Add `Semantics(label: 'Reorder prompt ${index + 1}')`; consider exposing move-up/down actions.

---

## `templates_page.dart`

### Medium · Feedback & States · `templates_page.dart:112-170` — duplicate/delete feedback gaps + contradictory delete copy
**Problem.** `_duplicate` awaits `duplicateTemplate` then pushes the editor with no progress indication. `_delete` has error handling but no success confirmation. Crucially, deleting a template that has saved reflections throws a `StateError` ("…cannot be deleted") — surfaced via SnackBar (good) — but the confirm dialog copy promises "Saved reflections … are unaffected. This cannot be undone," implying the delete will always succeed. The user confirms, then gets a contradictory error.
**Fix.** Add a loading affordance on duplicate. Reconcile the delete-dialog copy with the actual RESTRICT behaviour — pre-check usage and warn upfront that templates with reflections cannot be deleted.

### Low · UX Flow · `templates_page.dart:112-133` — push after await without a mounted check
**Problem.** `_duplicate` pushes a route after an `await`; if the page was popped during the write, the push targets a stale navigator. (It captures `navigator` up front, so impact is low.)
**Fix.** Minor robustness note rather than a visible bug.

### Low · Visual Consistency · `templates_page.dart:239` — magic icon size
**Problem.** `Icon(..., size: 56)` is hardcoded and duplicated in `goal_board_page.dart:87`.
**Fix.** Use a shared icon-size token; better, extract the duplicated `_BoardError`/`_TemplatesError` into one shared error widget.

---

## `goal_board_page.dart`

### Medium · Feedback & States · `goal_board_page.dart:73-106` — board error has no retry, shows raw error
**Problem.** When `goalBoardProvider` fails, the user sees an icon + message + raw error string and is stuck — the only recovery is to leave and re-enter.
**Fix.** Add a "Try again" button calling `ref.invalidate(goalBoardProvider)`; show friendly copy and hide the raw error behind a "Details" expansion.

### Low · UX Flow · `goal_board_page.dart:55-70` — no empty-state guidance on this page
**Problem.** The page delegates entirely to `KanbanBoardView` with no FAB or empty-state copy. Whether an all-empty board shows a "create your first goal" path depends entirely on the shared Kanban widget.
**Fix.** Confirm the shared widget surfaces a discoverable add affordance for empty columns (see the Kanban review); otherwise add an empty-state overlay here.

---

## `goal_card_tile.dart`

### Medium · Layout/Overflow · `goal_card_tile.dart:53-59` — footer Row can overflow
**Problem.** The footer is `Row([_ReflectionBadge, Spacer, if(targetDate) _TargetDateLabel])`. Both children are `MainAxisSize.min` with no `Flexible`. In a narrow Kanban column the badge + label can together exceed the card width, and a `Spacer` between two unconstrained children produces a `RenderFlex` overflow rather than graceful shrinking. The badge text has no `maxLines`/ellipsis.
**Fix.** Wrap `_ReflectionBadge` in `Flexible` (its `Text` ellipsizing), or use a `Wrap` so the date drops to a second line in a tight column.

### Low · Accessibility · `goal_card_tile.dart:94-132` — small text + low-contrast badge state
**Problem.** `labelSmall` text plus a 14 px icon is small for an at-a-glance card; the "has reflections" signal rides largely on low-contrast fill/border alpha (0.16/0.08, 0.5 border).
**Fix.** Verify muted badge text/border contrast meets 3:1; avoid shrinking below the design system's label style.

---

## `reflection_entry_tile.dart`

### Low · Accessibility · `reflection_entry_tile.dart:45-77` — collapsed tile has no expand affordance
**Problem.** When an `ExpansionTile` has a `trailing` widget it suppresses its default chevron. The tile shows a framework name and a `more_vert` menu with zero visual cue that answers are hidden inside — the user may never realise it expands.
**Fix.** Re-introduce an expand indicator — pair the `more_vert` menu with an explicit `Icon(Icons.expand_more)` in a `Row` as `trailing`, or move the menu so the default chevron returns.

### Low · Visual Consistency · `reflection_entry_tile.dart:44` — raw `Colors.transparent`
**Problem.** `dividerColor: Colors.transparent` uses a raw Material color.
**Fix.** Acceptable in practice — `Colors.transparent` for "no divider" is fine to leave.

---

## `reflection_form.dart`

### Medium · UX Flow · `reflection_form.dart:82-88` (with `reflection_editor_page.dart:158`) — Save button lags input
**Problem.** `_emitChange` calls `widget.onChanged` on every keystroke; in `ReflectionEditorPage`, `onChanged: (answers) => _answers = answers` updates `_answers` **without `setState`**. So `canSave` (which depends on `_answers.isNotEmpty`) is not recomputed when the user types the first character into an empty form — Save stays disabled until an unrelated rebuild. Clearing the last field likewise won't promptly re-disable Save.
**Fix.** In `ReflectionEditorPage`, wrap the assignment in `setState(() => _answers = answers)` so Save tracks input live.

### Low · Touch/Input · `reflection_form.dart:143-144` — scroll-within-scroll on long answers
**Problem.** Multiline prompts are `minLines: 3, maxLines: 8`; past 8 lines the field scrolls internally inside an already-scrolling `ListView`, creating nested-scroll friction, and the user may not realise more text exists.
**Fix.** Consider `maxLines: null` so the field grows with content (the outer `ListView` already scrolls).

---

## `template_tile.dart`

### Low · Layout/Overflow · `template_tile.dart:61-73` — name `Text` missing `maxLines`
**Problem.** The name is `Flexible` with `overflow: ellipsis` (good), but no `maxLines: 1` — a name with a newline or extreme length could wrap before ellipsizing.
**Fix.** Add `maxLines: 1` to the name `Text`.

---

## `goal_providers.dart` / `reflection_providers.dart` / `reflection_template_schema.dart`

No UI/UX issues — pure provider wiring and a pure-Dart model with no presentation surface. (`reflection_template_schema.dart`'s tolerant parsing is a sound defensive choice.)

---

## Top goal-cycle fixes

1. **Unsaved-changes data loss in all three editors** — `goal_card_detail_sheet`, `reflection_editor_page`, and `template_editor_page` all let the user discard substantial typed input via Back / scrim / drag with no `PopScope` guard. This is the most important fix.
2. **Inconsistent save feedback** — the reflection and template editors track `_saving` and disable Save and `try/catch` their writes; the goal detail sheet does none of this. Standardise: dirty-tracking + `_saving` + `try/catch` + failure SnackBar across all three.
3. **The goal detail sheet mixes autosave (target date) with manual save (title/note)** in one form, misleading users about what persisted.
4. **The `template_editor_page` read-only banner** points to a "Duplicate & edit" control that does not exist on that screen.
5. **`reflection_form` → `ReflectionEditorPage` Save button lags input** because `_answers` is updated without `setState`.
