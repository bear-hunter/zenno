# Fix Revision And Goal Page Review Findings

## Summary

Resolve the two review findings with scoped UI changes only: keep empty boards recoverable by exposing the existing "Add column" affordance, and make the revision detail sheet scroll like the goal detail sheet.

## Implementation Changes

- Update both `RevisionBoardPage` and `GoalBoardPage` so `_BoardBody` always builds `KanbanBoardView`, even when `board.columns` is empty.
- Remove the now-unused `_BoardEmpty` widgets and stale comments. `KanbanBoardView` already renders `_AddColumnButton` when `board.columns` is empty.
- Update `revision_card_detail_sheet.dart` to wrap the existing sheet `Column` in a `SingleChildScrollView`, matching the goal sheet structure.
- Do not change repositories, Drift tables, providers, seeded board data, drag/drop behavior, or shared Kanban APIs.

## Public APIs / Types

- No public API, schema, provider, route, or model changes.
- No codegen required.

## Test Plan

- Run `flutter analyze`.
- Add or run a targeted widget test that pumps revision and goal board pages with an empty `KanbanBoardData` stream and verifies `Add column` is visible.
- Manually smoke test:
  - Delete all columns from Revision and Goal boards; confirm `Add column` remains available.
  - Open a revision card detail sheet on a short viewport / with keyboard open; confirm content scrolls and Save/Delete/Mark revised remain reachable.

## Assumptions

- Empty boards should reuse the existing Kanban board surface instead of showing a separate empty-state message.
- The revision sheet should match the goal sheet's scrolling behavior rather than introducing a new shared bottom-sheet component.
