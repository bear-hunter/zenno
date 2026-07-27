# Zenno — UI/UX Review: Executive Summary

A UI/UX review of the Zenno codebase (Flutter, infinite-canvas study app for an Android tablet with an S Pen). The review covers presentation and interaction only — layout, states, feedback, accessibility, touch input, visual consistency, and error handling. It does not cover architecture, test coverage, or raw performance except where performance produces a visible UX problem.

Reviewed: ~22k lines across the canvas engine, five feature areas, the shared Kanban board, canvas attachments, the navigation shell, and the theme layer.

---

## Findings at a glance

| Area | High | Medium | Low | Total |
|---|---:|---:|---:|---:|
| [Foundation & Shell](01-foundation-and-shell.md) | 0 | 7 | 3 | 10 |
| [Canvas Editor](02-canvas.md) | 6 | 22 | 18 | 46 |
| [Focus](03-focus.md) | 6 | 23 | 20 | 49 |
| [Goal Cycle](04-goal-cycle.md) | 5 | 11 | 11 | 27 |
| [Revision / Library / Settings](05-revision-library-settings.md) | 2 | 12 | 18 | 32 |
| [Kanban & Attachments](06-kanban-and-attachments.md) | 5 | 18 | 12 | 35 |
| **Total** | **24** | **93** | **82** | **199** |

Severity: **High** — broken, unusable, data-loss, or inaccessible. **Medium** — confusing, inconsistent, or missing feedback. **Low** — polish.

The headline: the app's individual screens are visually coherent and built on a genuinely good design-token system, but the same handful of interaction patterns are missing across nearly every screen. Most of the 24 High findings are instances of just three recurring gaps. Fixing the patterns once — ideally as the shared widgets described in the [Foundation review](01-foundation-and-shell.md) — resolves the majority of the list.

---

## Cross-cutting themes

These patterns recur across features. They are the highest-leverage things to fix because one change closes many findings.

### 1. Unsaved-changes data loss (the single biggest issue)
Every editing surface lets the user discard typed work with no warning. None of these screens has a `PopScope` guard, so the Android back gesture / predictive back / scrim tap / drag-dismiss all silently throw away input:

- Canvas editor — back gesture skips the save-error check (`canvas_editor_page.dart`).
- Focus Active — back gesture bypasses "End early", orphaning a running session.
- Focus Review — back gesture discards the post-session energy rating and note.
- Goal card detail sheet, Reflection editor, Template editor — back / scrim / drag discard all edits.

On a tablet with a stray S Pen these gestures are easy to trigger by accident. **Fix:** add `PopScope` with dirty-tracking + a "Discard changes?" confirmation to all six.

### 2. Async actions have no error handling and no loading/disabled state
DB writes are awaited with a bare `await` across the whole app. The consequences:
- A failed write throws an **unhandled exception** with no user feedback (`canvas_card` delete/rename, `library_page` create, Focus Start/Save/Finish, the goal detail sheet, canvas attachments).
- The triggering button stays enabled during the await, so a **double-tap** re-fires the action.
- A slow write looks identical to a failed one — no spinner, no progress.
- Some writes are fully fire-and-forget (every `settings_page` control), leaving the UI showing a value that was never persisted.

**Fix:** a shared guarded-async-action helper — disable the control while in flight, show a spinner, `try/catch`, report failure via SnackBar.

### 3. Destructive actions lack confirmation and/or undo
Canvas `clear()`, lasso delete, bookmark removal, Kanban column delete (which cascades all its cards), ritual "Retire", and attachment "Detach" all either fire immediately with no confirmation or confirm but offer no Undo. **Fix:** a uniform destructive-action helper — confirm dialog or an action-with-Undo SnackBar.

### 4. Errors are hidden, masked, or shown raw
- Raw exception strings are interpolated into user-facing text and SnackBars (`$error` in Focus Home/History, the Goal board, Kanban action failures) — users see Drift/SQLite stack-trace text.
- The link-target dialog shows a *load failure* as "No other canvases to link to."
- The Focus Review distraction `StreamBuilder` shows a *stream error* as "No distractions — nice focus."
- No error panel anywhere (`_BoardError`, the Library panel, `_SettingsMessage`) offers a **Retry**.

**Fix:** a shared `AsyncValueWidget` with a consistent error state + Retry, and a friendly-error presenter that logs the raw error instead of showing it.

### 5. Touch targets below the 48 dp minimum
The theme sets a 48 dp default, but many widgets locally override it: toolbar color swatches (28 px) and width dots (32 px), segmented buttons (`shrinkWrap`), the bookmark-remove icon (18 px), ritual rows (~32 px), revision flag choices (~36 px), Kanban drag handles (18–20 px), and inter-column drop zones (4–8 px). On a stylus tablet these are hard to hit accurately.

### 6. Free-text rendered without `maxLines` / overflow
User-entered titles and notes (goal titles, focus goal text, session titles and notes, canvas titles, attachment labels) are rendered in `Row`s without `Flexible`/`Expanded` or without `maxLines`/`overflow`. In a narrow Kanban column or tablet portrait these overflow or balloon the layout.

### 7. The Kanban drag-and-drop is the weakest interaction in the app
It backs both the Goal and Revision boards, so its problems hit two features. There is no autoscroll (off-screen cards/columns are unreachable), drop zones are 4–8 px wide, the drop indicator only appears at thin inter-card gaps, the source slot does not collapse during a drag, long-press-to-drag conflicts with tap-to-open, and horizontal scrollability is not discoverable.

### 8. Design-system gaps
The token system is good but incomplete: no radius scale (radii are hardcoded `8`/`12`/`16` inconsistently), no icon-size scale (`size: 56` duplicated across four files), no dialog-width token (three+ hardcoded widths), and the brand gold `0xFFE8B84B` is re-typed as a literal in the toolbar and three painters instead of referencing `AppColors`.

### 9. Inconsistent accessibility
Some widgets do it right (`EnergyRatingSelector` has `Semantics`); their peers do not (`RitualChecklist`, `TimerTypePicker` cards, the live timer figure, Kanban drag handles). Mastery flags signal status by color alone — the dot is shape-identical across green/yellow/red, a problem for colorblind users on the small dense chip.

---

## Top priorities

Ordered by impact. The first three knock out most of the 24 High findings.

1. **Add `PopScope` + dirty-tracking to all six editing surfaces** (canvas editor, Focus Active, Focus Review, goal detail sheet, reflection editor, template editor). Stops silent data loss. — Theme 1
2. **Introduce a guarded async-action pattern** and apply it to every DB-writing button: canvas import, `canvas_card` delete/rename, `library_page` create, Focus Start/Save/Finish, the goal detail sheet, settings controls, Kanban and attachment actions. Stops unhandled exceptions, dead screens, and double-taps. — Theme 2
3. **Surface canvas import failures** — `importImage`/`importPdf` currently throw with no catch; a failed import looks identical to a cancelled or slow one and makes the feature look broken. — Canvas High
4. **Fix Kanban drag autoscroll** — without it, cards and columns cannot be moved off-screen; the core interaction is broken on any real board (both Goal and Revision). — Kanban High
5. **Add confirmation/undo to destructive actions** — canvas clear, Kanban column delete (cascades cards), ritual Retire, attachment detach, bookmark removal. — Theme 3
6. **Stop masking and dumping errors** — fix the link dialog ("no canvases" hiding a load failure), the distraction `StreamBuilder` ("nice focus" hiding a stream error), and raw `$error` interpolation; add Retry to every error panel. — Theme 4
7. **Raise sub-48 dp touch targets** — toolbar swatches/width dots, Kanban handles and drop zones, revision flag choices, ritual rows. — Theme 5
8. **Give the canvas editor a real title** — it currently always reads "Canvas", leaving users lost when following link chains. — Canvas High
9. **Make `timer_display`'s ring responsive** — the hardcoded 280 px ring can be overflowed by an `h:mm:ss` figure and does not adapt to portrait/split-screen. — Focus High
10. **Make the toolbar scroll horizontally** instead of wrapping to 3+ rows in tablet portrait, where it steals canvas space. — Canvas High
11. **Clamp free-text with `maxLines`/`overflow`** in card and list tiles (Goal, Revision, Focus history, attachments). — Theme 6
12. **Fix the revision detail sheet** — a flag write currently freezes the entire sheet with no spinner explaining why. — Revision High

---

## Where to start

Build the four shared pieces from the [Foundation review](01-foundation-and-shell.md) first — `AsyncValueWidget` (with Retry), a friendly-error presenter, a destructive-action helper, and a guarded async-action helper — then apply them screen by screen. That sequencing turns most of the 24 High and many Medium findings into mechanical, low-risk substitutions rather than 200 separate edits.

The per-area documents list every finding with `file:line`, the problem, and a concrete fix:

- [01 — Foundation & Shell](01-foundation-and-shell.md)
- [02 — Canvas Editor](02-canvas.md)
- [03 — Focus](03-focus.md)
- [04 — Goal Cycle](04-goal-cycle.md)
- [05 — Revision / Library / Settings](05-revision-library-settings.md)
- [06 — Kanban & Attachments](06-kanban-and-attachments.md)
