# Revision Page UI/UX Fix Plan

## Summary
Fix the revision board and shared Kanban UX without changing the database model. Keep revision scheduling manual: `Mark revised` only records the review timestamp/count, shows clear feedback, and does not move the card. Apply shared Kanban improvements to both Revision and Goal Cycle where the issue lives in shared board code.

## Key Changes
- Revision detail sheet:
  - Convert title/notes to a validated form; empty title shows an inline error instead of silently doing nothing.
  - Keep explicit `Save`, but save in-place, clear dirty state, and show a `SnackBar`.
  - Add unsaved-change protection for back/drag/barrier dismissal with a “Discard changes?” dialog.
  - If `Mark revised` is tapped while dirty, show a dialog with `Save & mark`, `Mark without saving`, and `Cancel`; default primary action is `Save & mark`.
  - Add pending states for save, mark revised, delete, and mastery flag writes; disable conflicting actions while a write is running and show errors via `SnackBar`.
  - On mastery flag write failure, revert the local flag selection and show an error.
  - Style delete confirmation buttons with `colorScheme.error/onError`.

- Revision feedback and timestamps:
  - `Mark revised` closes the sheet after success and shows `Marked revised` feedback; it must not call `moveCard`.
  - Add a minute ticker for revision cards and revision stats so relative labels like `just now` / `13d ago` refresh while the page is open.
  - Pass the current `DateTime` into `RevisionCardTile`/revision stats and use `relativeTime(..., now: now)`.

- Shared Kanban UX:
  - Refactor shared Kanban so the board owns interactive card chrome: `Material`/`InkWell`, semantics, focus/hover/tap feedback, and drag affordance. Feature card widgets should render card content, not their own outer `Card`.
  - Add a visible muted drag handle/tooltip on each card: “Hold and drag to move”.
  - Replace bare `No cards` with a useful empty column state: “No cards yet” plus “Add a card or drop one here.”
  - Add a real empty-board state when there are no columns: “No columns yet” plus a primary `Add column` action.
  - Replace the single-field card create dialog with a shared card draft dialog containing required `Title` and optional `Notes`; persist notes through existing `subtitle`.
  - Add validation to add/rename dialogs so blank titles stay in the dialog with an error.
  - Make the add-column affordance compact when columns exist, and compute responsive column widths in `KanbanBoardView` so the seeded four-column revision board fits better on tablet landscape before horizontal scrolling is needed.
  - Add shared error handling for add, rename, delete, move, and reorder operations with `SnackBar` messages.

## Interfaces
- No Drift/schema changes and no build_runner required.
- Update shared Kanban’s card builder contract so feature widgets return content-only card bodies; `KanbanBoardView`/`KanbanColumnView` own the outer card, tap, semantics, drag, and ripple behavior.
- Add a `width` parameter to `KanbanColumnView`, supplied by responsive layout logic in `KanbanBoardView`.
- Add `now` to revision card/stat rendering so relative-time output is testable and refreshable.

## Test Plan
- Add widget tests for revision detail sheet:
  - dirty dismiss shows discard confirmation
  - empty title shows validation error
  - `Save` persists title/notes, clears dirty state, and keeps the sheet open
  - dirty `Mark revised` offers `Save & mark`, `Mark without saving`, and `Cancel`
  - successful `Mark revised` calls only `markRevised`, never `moveCard`, and shows feedback
  - failed mastery write reverts the selected flag
- Add shared Kanban widget tests:
  - empty board shows useful copy and add-column action
  - empty column shows useful copy
  - add-card dialog accepts title and notes and passes `subtitle`
  - blank add/rename submissions show validation errors
  - card taps have button semantics and open the detail callback
  - column delete confirmation uses destructive copy/button styling
- Run `flutter analyze` and `flutter test`.
- Manual smoke test on tablet-sized viewport/device: create a revision card with notes, edit/save, mark revised, drag a card, delete a card/column, and verify no obvious overflow in the default four-column board.

## Assumptions
- Revision buckets remain manually managed; the app will not auto-schedule or auto-move cards after review.
- Shared Kanban improvements are allowed to improve Goal Cycle too.
- Save remains explicit for title/notes; mastery and canvas attachment changes remain immediate but gain pending/error feedback.
