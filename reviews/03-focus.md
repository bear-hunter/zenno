# Focus Feature — UI/UX Review

Scope: the Focus feature (Pomodoro / Flowmodoro timer) — `features/focus/presentation/*`, plus `active_session_controller.dart`, `focus_setup_controller.dart`, `timer_engine.dart`.

Findings: 6 High · 23 Medium · 20 Low.

Line numbers are as of the review; verify against current source before editing.

---

## `focus_home_page.dart`

### Medium · Feedback & States · `focus_home_page.dart:90` — raw error string in the recent-sessions panel
**Problem.** The error branch renders a bare `Text('Could not load history: $error')` — unstyled, no icon, inline with content, and interpolates the raw exception (a stack-trace-like string). `FocusHistoryPage` handles the same error in a centered, padded layout — inconsistent.
**Fix.** Render a styled error state with short user-facing copy, `colorScheme.error`, and an optional retry. Do not interpolate `$error`.

### Medium · Layout/Overflow · `focus_home_page.dart:268-310` — long stat label cramped in `_StatsSummary`
**Problem.** `_StatsSummary` is a `Row` of three `Expanded` `_MiniStat`s. The label "Distractions / session" is forced into one-third of the card width; `_MiniStat`'s label has no `maxLines`/`overflow`, so it wraps to 3+ lines on narrow widths, and the differing label heights misalign the value baselines.
**Fix.** Add `maxLines: 2, overflow: TextOverflow.ellipsis` to the label, or shorten it ("Distractions" / "Per session").

### Low · Visual Consistency · `focus_home_page.dart:138-208` — inconsistent card radii
**Problem.** `_StartCard`/`_ResumeBanner` use `BorderRadius.circular(16)`; `_StatsSummary`/`_NoSessionsYet` use `12` — on the same screen.
**Fix.** Use one radius token (see the foundation review's radius-scale recommendation).

### Low · Accessibility · `focus_home_page.dart:150-178` — decorative noise
**Problem.** Magic sizes (`CircleAvatar radius: 28`, play `Icon size: 32`) and a decorative `chevron_right` next to an already-obviously-tappable card.
**Fix.** Minor — drop the chevron if desired; replace magic sizes with tokens.

---

## `focus_setup_page.dart`

### High · UX Flow · `focus_setup_page.dart:135-176` — "Start session" has no loading/disabled state
**Problem.** `_start` is async (`createSession`, `snapshotRitualChecks`, `startFrom`) but the button stays fully enabled during the awaits. A double-tap — easy on a tablet — re-enters `_start`; the second `createSession` + `snapshotRitualChecks` race with the first, and the user gets no feedback.
**Fix.** Track an `isStarting` flag, disable the button, and show a spinner in the label while `_start` runs.

### High · Error Handling · `focus_setup_page.dart:151-176` — `_start` has no error handling
**Problem.** `_start` awaits DB writes with no `try/catch`. If `createSession`/`snapshotRitualChecks` throws, the exception is unhandled, `FocusActivePage` is never pushed, and the user is stranded on Setup with no idea whether the session started.
**Fix.** Wrap in `try/catch`; on failure show a SnackBar and keep the user on Setup.

### Medium · Error Handling · `focus_setup_page.dart:240-243` — canvas-create failure is silent
**Problem.** In `_chooseCanvas`, the `NewCanvasPicked` branch awaits `createCanvas(...)` with no error handling and no loading indicator. A failed create silently does nothing.
**Fix.** Wrap in `try/catch` with a failure SnackBar.

### Medium · UX Flow · `focus_setup_page.dart:87-94` — goal field not state-backed; misleading IME action
**Problem.** The goal `TextField` writes via `onChanged` but has no `controller`/`initialValue`, so it can desync from retained controller state. `textInputAction: TextInputAction.next` is set but there is no next focusable field.
**Fix.** Use `TextInputAction.done`; if draft persistence is wanted, back the field with a `TextEditingController` seeded from state.

### Medium · Touch/Input · `focus_setup_page.dart:357-374` — `_DurationStepper` never disables at its bounds
**Problem.** The minus/plus buttons never disable. Clamping happens only in the controller (5-min floor for duration, 1-min for Pomodoro phases) — at the floor the user keeps tapping a button that does nothing. There is also no maximum at all (the user can reach 999 min).
**Fix.** Disable minus at the documented minimum; impose and enforce a sane maximum and disable plus at it.

### Medium · Layout/Overflow · `focus_setup_page.dart:200-222` — `_FocusCanvasRow` title unbounded
**Problem.** The linked-canvas title (`selected?.title`, free user text) renders with no `maxLines`/`overflow`; a long title wraps to many lines and balloons the row alongside the Clear icon and "Change" button.
**Fix.** Add `maxLines: 1, overflow: TextOverflow.ellipsis` to the title `Text`.

### Low · Accessibility · `focus_setup_page.dart:305-312` — Flowmodoro slider lacks a value description
**Problem.** The `Slider` has no semantic value beyond the drag-time float label; a screen reader hears a raw `0.05–0.5` value.
**Fix.** Provide a `semanticFormatterCallback` returning "`<percent>`% of focus time".

### Low · Visual Consistency · `focus_setup_page.dart:363` — magic width
**Problem.** `SizedBox(width: 88)` for the stepper value column.
**Fix.** Minor; document or derive it.

---

## `focus_active_page.dart`

### High · UX Flow · `focus_active_page.dart:30-54` — Android back gesture bypasses "End early"
**Problem.** The AppBar sets `automaticallyImplyLeading: false` to prevent a silent pop, but the **system back gesture** is not intercepted (no `PopScope`). A back gesture pops `FocusActivePage` straight to Home while the session keeps running in the background — bypassing the deliberate "End early" confirmation and contradicting the file's own doc ("leaving is finish or abandon, never a silent pop").
**Fix.** Wrap the `Scaffold` in `PopScope(canPop: false, onPopInvokedWithResult: ...)` that routes the back gesture through `_confirmAbandon`.

### Medium · Feedback & States · `focus_active_page.dart:58-65` — `_finish` has no loading/error handling
**Problem.** `_finish` awaits `controller.stop()` (a DB write). If it throws, navigation to Review never happens and the user is stuck on Active with the timer already stopped. The "Finish" button stays enabled during the await (double-tap possible).
**Fix.** Disable Finish while awaiting; `try/catch` with a failure SnackBar.

### Medium · Feedback & States · `focus_active_page.dart:246-252` — distraction capture gives no failure feedback
**Problem.** `captureDistraction(...)` is awaited then a success SnackBar shown unconditionally. If `addDistraction` throws, the await rejects, the SnackBar never shows, the sheet has already closed — the user gets no feedback at all.
**Fix.** `try/catch` around `captureDistraction`; show a failure SnackBar in the catch.

### Medium · UX Flow · `focus_active_page.dart:195-202` — disabled button labelled "Auto"
**Problem.** During a Pomodoro work phase the secondary button is rendered but disabled, labelled "Auto" with a coffee icon. A greyed-out "Auto" button reads as a broken control, not as "the timer advances itself".
**Fix.** Hide the second button during Pomodoro work (show Pause full-width), or replace it with non-button text ("Break starts automatically").

### Low · Accessibility · `focus_active_page.dart:38-41` — small destructive AppBar action
**Problem.** "End early" is a `TextButton` in `actions`; its hit target can fall under 48 dp, and a destructive action as a small text link is easy to mis-tap.
**Fix.** Use an `IconButton` with tooltip, or give the `TextButton` adequate `minimumSize`/padding.

### Low · Feedback & States · `focus_active_page.dart:44-46` — "No active session" flash on restore
**Problem.** During the `_restoreLatestInProgressSession` race there is a window where the page renders `_NoSession` before the timer appears — a flash of "No active session".
**Fix.** Distinguish "restoring" (spinner) from "truly none".

---

## `focus_review_page.dart`

### High · UX Flow · `focus_review_page.dart:48-52` — back gesture discards the review
**Problem.** Review sets `automaticallyImplyLeading: false` but does not intercept the system back gesture (no `PopScope`). A back gesture pops Review to Home without calling `submitReview` — silently discarding the user's post-energy rating and note, and leaving a dangling held session (`_clear()` runs only in `submitReview`/`discard`).
**Fix.** Wrap in `PopScope(canPop: false, ...)`; on back, confirm ("Discard your review?") and call `discard()`, or auto-save.

### High · Error Handling · `focus_review_page.dart:184-191` — `_save` has no error handling or button-disable
**Problem.** `_save` awaits `submitReview` (a DB write) with no `try/catch`; the "Save & finish" button is not disabled during the await. A failed write throws unhandled — navigation to Home never happens, the user is stuck with no feedback. Double-tap is possible.
**Fix.** Disable the button while saving; `try/catch` with a failure SnackBar.

### Medium · Feedback & States · `focus_review_page.dart:253-289` — a load failure is shown as "nice focus"
**Problem.** The `StreamBuilder<List<Distraction>>` only reads `snapshot.data` — it ignores `hasError` and the waiting state. On stream error it falls through to `const []` and renders **"No distractions captured — nice focus."** A load failure is presented to the user as a positive message.
**Fix.** Handle `connectionState == waiting` (spinner) and `hasError` (error text) before defaulting to the empty state.

### Medium · Feedback & States · `focus_review_page.dart:98-110` — "Retire" ritual item with no confirmation
**Problem.** The "Tidy your ritual" checklist's `onRetire` calls `retireItem` directly — a destructive removal with no confirmation and no Undo, and no success/failure feedback.
**Fix.** Add a confirmation or an Undo SnackBar for Retire. (Root cause is in `ritual_checklist.dart`, below.)

### Medium · UX Flow · `focus_review_page.dart:30-33` — post-energy silently defaults to 3
**Problem.** `_postEnergy` initialises to a hardcoded `3` every time Review opens. A user who taps "Save & finish" without touching the selector records "3", skewing the `avgPostEnergy`/`energyDelta` stats on History. Nothing flags that this field needs input.
**Fix.** Seed `_postEnergy` from `session.config?.preEnergy`, or treat it as unset (no pip filled) and require a selection before enabling Save.

### Low · Accessibility · `focus_review_page.dart:152-181` — empty add-ritual input fails silently
**Problem.** Submitting an empty/whitespace label just closes the add-ritual dialog (the `trimmed.isNotEmpty` check discards it) with no message.
**Fix.** Keep the dialog open on empty input or show a brief "Enter a label" hint.

### Low · Layout/Overflow · `focus_review_page.dart:225-232` — unbounded summary text
**Problem.** `_Summary` concatenates focus + cycles into one `Text` with no `maxLines`.
**Fix.** Low priority — add `maxLines`/`softWrap` if tight portrait layouts matter.

---

## `focus_history_page.dart`

### Medium · Layout/Overflow · `focus_history_page.dart:213-219` — unbounded session title
**Problem.** In `_SessionTile`, the `Expanded` title `Text` has no `maxLines`/`overflow` next to a `_StatusBadge`. A long `goalText` (free user input) wraps to many lines and balloons the card. Home's `_RecentSessionTile` correctly clamps its title — History is the inconsistent one.
**Fix.** Add `maxLines: 2, overflow: TextOverflow.ellipsis` to the title `Text`.

### Medium · Layout/Overflow · `focus_history_page.dart:259-268` — unbounded notes block
**Problem.** Session notes render with no `maxLines`; a long note (up to 6 lines from the Review field) makes every card very tall with no "show more" affordance.
**Fix.** Clamp with `maxLines: 3-4, overflow: TextOverflow.ellipsis`, or make the card expandable.

### Low · Feedback & States · `focus_history_page.dart:31-38` — raw error string
**Problem.** The error state interpolates the raw `$error` into user-facing text.
**Fix.** Show friendly copy; log the raw error.

### Low · Accessibility · `focus_history_page.dart:254-256` — energy delta lacks a glance signal
**Problem.** `'energy 3→4'` conveys direction only through the numbers; the `battery_charging_full` icon is identical regardless of improvement/decline.
**Fix.** Minor polish — color or vary the icon by delta sign.

---

## `timer_display.dart`

### High · Layout/Overflow · `timer_display.dart:41-58` — hardcoded 280 px ring can overflow
**Problem.** The timer ring is a fixed `SizedBox(width: 280, height: 280)` and the figure uses `displayMedium`. For an `h:mm:ss` figure (a session over an hour) the `Text` — not wrapped in `FittedBox`, no `maxLines` — can exceed the 280 px inner width and overflow the ring. The ring also does not shrink for portrait or split-screen widths below 280 px.
**Fix.** Wrap the figure in `FittedBox`, and make the ring size responsive (`LayoutBuilder`/`MediaQuery`-derived, capped). Do not hardcode 280.

### Medium · Accessibility · `timer_display.dart:62-77` — timer figure has no semantics
**Problem.** The central figure has no `Semantics` label — a screen reader announces the raw string ("5:03") with no context, and it updates every second, spamming the user.
**Fix.** Wrap in `Semantics` with a composed label ("5 minutes 3 seconds of work remaining"); tune `liveRegion` so it does not announce every tick (e.g. only on phase change).

### Medium · Feedback & States · `timer_display.dart:48-57` — open-ended stretch drawn as a full ring
**Problem.** For an open-ended Flowmodoro work stretch the ring is drawn with constant `value: 1.0`. A full determinate ring conventionally means "100 % / complete" — the opposite of "open-ended, still going" — so users may read the stretch as finished.
**Fix.** Use a genuinely indeterminate `CircularProgressIndicator` (omit `value`) for the open-ended stretch, or a clearly different visual.

### Medium · Feedback & States · `timer_display.dart:101-108` — silent phase transition
**Problem.** When a Pomodoro work phase runs past its target before the 1 Hz ticker advances, `remaining` clamps to `0:00`, the label still says "Focus", the ring is full — no flash, color change, or "time's up" cue. The phase boundary is invisible.
**Fix.** When `isPhaseComplete` and not yet advanced, show an explicit "Time's up" state or animate the transition.

### Low · Accessibility · `timer_display.dart:33` — break vs focus ring color only
**Problem.** Break vs Focus is signalled by ring color (`flagGreen` vs `primary`). The `_PhaseChip` text label also distinguishes them, so this is acceptable.
**Fix.** No change strictly needed — the chip carries the label.

---

## `timer_type_picker.dart`

### Medium · Accessibility · `timer_type_picker.dart:73-89` — mode cards have no selection semantics
**Problem.** `_ModeCard`s are selectable but have no `Semantics(selected:, button:)`; selection is conveyed only visually (border, accent, check icon).
**Fix.** Wrap each in `Semantics(button: true, selected: selected, label: title)`.

### Low · Layout/Overflow · `timer_type_picker.dart:26-48` — unequal card heights
**Problem.** Two `Expanded` cards in a `Row`; their descriptions (uncontrolled `Text`, no `maxLines`) differ in length, so the cards end at different heights with no `IntrinsicHeight`.
**Fix.** Equal-height cards (`IntrinsicHeight` or a min height), or clamp descriptions with `maxLines: 2`.

---

## `ritual_checklist.dart`

### Medium · Touch/Input · `ritual_checklist.dart:134-152` — sub-48 dp toggle rows
**Problem.** Each ritual row is an `InkWell` with only `vertical: AppSpacing.xs` (4) padding around a ~24 px checkbox icon — total row height ~32 px, well below the 48 dp minimum for a primary toggle.
**Fix.** Increase vertical padding to reach 48 dp, or use `CheckboxListTile`.

### Medium · Feedback & States · `ritual_checklist.dart:155-178` — destructive "Retire" fires immediately
**Problem.** "Retire" in the per-row `PopupMenuButton` permanently removes a ritual item with no confirmation and no Undo. "Rename" opens a dialog (safe); "Retire" does not.
**Fix.** Add a confirmation dialog or an Undo SnackBar before `onRetire`.

### Low · Accessibility · `ritual_checklist.dart:141-153` — checkbox state not exposed semantically
**Problem.** The checkbox is an `Icon` in a plain `InkWell` with no `Semantics(checked:)`/toggle role; a screen reader announces only the label, not the ticked state. (`EnergyRatingSelector` does add semantics — inconsistent.)
**Fix.** Wrap the row in `Semantics(checked: checked, button: true, label: item.label)` or use `CheckboxListTile`.

### Low · Visual Consistency · `ritual_checklist.dart:136` — magic radius
**Fix.** `BorderRadius.circular(8)` → a radius token.

---

## `distraction_sheet.dart`

### Medium · Layout/Overflow · `distraction_sheet.dart:60-124` — sheet can overflow with the keyboard up
**Problem.** The sheet `Column` is `MainAxisSize.min` and not scrollable, yet the note field is `autofocus: true` so the IME is always up on open. On a short tablet split-screen, content height + `bottomInset` can exceed available height and overflow.
**Fix.** Wrap the body in `SingleChildScrollView`.

### Low · Touch/Input · `distraction_sheet.dart:104-114` — autofocus forces the keyboard up
**Problem.** The sheet aims for sub-five-second capture where the note is *optional*, but `autofocus: true` raises the keyboard every time, covering the segmented button.
**Fix.** Consider `autofocus: false` so the keyboard appears only if the user taps the note field.

### Low · Visual Consistency · `distraction_sheet.dart:116-120` — inconsistent button height
**Problem.** The "Capture" `FilledButton.icon` has no explicit height while every other primary button in the feature is given a tall (52–56) touch height.
**Fix.** Add `minimumSize: const Size.fromHeight(52)`.

---

## `energy_rating_selector.dart`

### Low · Accessibility · `energy_rating_selector.dart:96-99` — cumulative-fill semantics are misleading
**Problem.** `Semantics.selected` is `level <= value`, so pips 1–3 are all "selected" at value 3 — a screen reader hears "level 1 selected, level 2 selected, level 3 selected", which implies multi-select rather than "the rating is 3".
**Fix.** Use `inMutuallyExclusiveGroup: true` and set `selected` only on `level == value`, or add a value-style label.

### Low · Touch/Input · `energy_rating_selector.dart:103-106` — pips exactly at the 48 dp floor
**Problem.** Pips are `height: 48` — meets the minimum exactly, not above it.
**Fix.** No change required; consider 52–56 for comfort on a stylus tablet.

---

## `active_session_controller.dart`

### Medium · Feedback & States · `active_session_controller.dart:189-347` — no error capture for DB writes
**Problem.** Every DB-writing method (`captureDistraction`, `_persistRuntime`, `finishSession` in `stop`, `completeReview` in `submitReview`) awaits the repository with no `try/catch` anywhere in the controller. A failed write throws to the calling widget; most call sites also lack `try/catch`, so a DB failure surfaces as an uncaught exception with no user feedback. The controller is the natural choke point to catch these.
**Fix.** Capture write errors into state (e.g. an `error` field on `ActiveSessionState`) so the UI can show "couldn't save" feedback.
**Note (positive).** The controller correctly handles screen-awake (`_syncWakelockWithSettings`, `_setWakelock`); the `keepAlive` + wall-clock engine correctly survives backgrounding. Those concerns are addressed.

---

## `focus_setup_controller.dart`

### Low · UX Flow · `focus_setup_controller.dart:173-175` — clamp range disagrees with the slider
**Problem.** `setFlowBreakRatio` clamps to `0.05–1.0`, but the Setup slider is `min: 0.05, max: 0.5` — the controller permits values the UI can never produce.
**Fix.** Align the clamp upper bound with the slider's `max` (0.5).

### Low · UX Flow · `focus_setup_controller.dart:163-184` — no maximum on durations
**Problem.** `setPomodoroWork`/`setPomodoroBreak`/`setPlannedDuration` enforce minimums but no maximum; the stepper "+" can drive them to absurd values.
**Fix.** Add sane upper bounds and disable the stepper "+" at the ceiling.

---

## `timer_engine.dart`

No UI/UX issues — pure-Dart domain logic with no Flutter dependency. Its wall-clock correctness is what makes the backgrounding/screen-sleep behaviour safe (a UX positive), but there is nothing visual to review.

---

## Top focus fixes

1. **No `PopScope` on Active or Review** — the Android back gesture bypasses "End early" (orphaning a running session) and silently discards the user's review input.
2. **`_save` (Review) and "Start session" (Setup) have no `try/catch` and no button-disable** — a failed DB write dead-ends the screen; double-tap is possible.
3. **`timer_display`'s hardcoded 280 px ring** can be overflowed by an `h:mm:ss` figure and does not adapt to portrait/split-screen.
4. **The distraction `StreamBuilder` shows a load failure as "No distractions — nice focus."**
5. **Free-text content** (goal titles, notes) renders without `maxLines`/`overflow` on several tiles.
6. **Destructive "Retire"** has no confirmation; **screen-reader semantics** are inconsistent across `RitualChecklist`, `TimerTypePicker`, and the live timer figure.
