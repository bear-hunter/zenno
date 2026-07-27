# Connect Focus, Revision, And Goals To Canvases

## Summary

Implement Ahmni-style canvas attachment across Zenno's study system: focus
sessions attach to one working canvas, while revision and goal cards can own
multiple named canvases. Use an explicit "create or select canvas" flow so users
can connect existing library canvases or create new ones from the relevant study
context.

## Key Changes

- Add a reusable canvas picker/create flow:
  - Select from existing `Canvases`.
  - Create a new canvas with a default title based on context, then attach it.
  - Return the selected/created canvas id to the calling feature.
- Focus:
  - Extend `FocusSetupState` to carry `linkedCanvasId`.
  - Add a "Canvas" row to Focus Setup with create/select/clear actions.
  - Persist the chosen canvas through existing `focus_sessions.linked_canvas_id`.
  - Add an "Open canvas" action on active/history/review focus surfaces when a
    session has a linked canvas.
  - Keep the active timer restorable while the user navigates to the canvas.
- Revision:
  - Add a new Drift table for card-canvas attachments, keyed by revision card id
    and canvas id, with display title/position/created timestamp.
  - In the revision card detail sheet, show attached canvases as rows/cards with
    open, rename label, detach, and add canvas actions.
  - Opening an attached canvas routes to the existing canvas editor.
- Goal Cycle:
  - Reuse the same attachment model for goal cards, or create a parallel
    goal-card canvas attachment table if keeping feature ownership clearer.
  - In the goal card detail sheet, add a "Canvases" area for reverse planning,
    study mindmaps, and related work.
  - Add create/select/open/detach behavior matching revision.
- Library/canvas integration:
  - Newly created canvases still appear in the normal library.
  - Deleting a canvas should cascade or remove attachment rows.
  - Detaching a canvas from a card/session must not delete the canvas itself.

## Data And Interfaces

- Add Drift schema migration and regenerate code with
  `dart run build_runner build`.
- Add repository methods for:
  - Listing card canvas attachments.
  - Attaching an existing canvas.
  - Creating and attaching a new canvas.
  - Renaming attachment label.
  - Detaching attachment.
- Add focused Riverpod providers/controllers for revision/goal canvas
  attachments.
- Prefer one reusable UI component for attachment lists so revision and goal
  behavior stays consistent.

## Test Plan

- Add database tests for attachment insert, delete, canvas cascade, card cascade,
  and ordering.
- Add repository tests for create-and-attach, attach-existing,
  detach-without-delete, and rename label.
- Add focus controller tests confirming `linkedCanvasId` survives
  setup-to-session persistence.
- Run:
  - `dart run build_runner build`
  - `flutter analyze`
  - Targeted repository/controller tests
  - `flutter test` if changes touch shared providers or shared widgets

## Assumptions

- Revision and goal cards support many canvases per card.
- Focus sessions support one linked working canvas per session.
- The UI should offer create/select rather than auto-create.
- Canvas ownership remains soft: attached canvases are normal library canvases,
  and detaching does not delete them.
