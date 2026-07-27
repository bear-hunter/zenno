# Zenno — UI/UX Review

A UI/UX review of the Zenno codebase: layout, screen states, feedback, accessibility, touch input, visual consistency, and error handling. Architecture, test coverage, and raw performance are out of scope except where they produce a visible UX problem.

Reviewed at git `main`, ~22k lines of Dart across the canvas engine, five feature areas, the shared Kanban board, canvas attachments, the navigation shell, and the theme layer.

## Read this first

**[00 — Executive Summary](00-executive-summary.md)** — severity counts, the nine cross-cutting themes, and the top 12 priorities. Start here.

## Per-area findings

Each document lists every finding with `file:line`, the problem, and a concrete fix, grouped by file and ordered by severity.

| Document | Scope | High / Medium / Low |
|---|---|---|
| [01 — Foundation & Shell](01-foundation-and-shell.md) | Theme tokens, navigation shell, app root, utilities | 0 / 7 / 3 |
| [02 — Canvas Editor](02-canvas.md) | Infinite-canvas editor, toolbar, rendering, input, import | 6 / 22 / 18 |
| [03 — Focus](03-focus.md) | Pomodoro / Flowmodoro timer feature | 6 / 23 / 20 |
| [04 — Goal Cycle](04-goal-cycle.md) | Goal board, reflections, reflection templates | 5 / 11 / 11 |
| [05 — Revision / Library / Settings](05-revision-library-settings.md) | Revision board, canvas library, settings | 2 / 12 / 18 |
| [06 — Kanban & Attachments](06-kanban-and-attachments.md) | Shared Kanban board, canvas-attachment UI | 5 / 18 / 12 |

**Total: 199 findings — 24 High, 93 Medium, 82 Low.**

## Severity

- **High** — broken, unusable, causes data loss, or inaccessible.
- **Medium** — confusing, inconsistent, or missing feedback.
- **Low** — polish.

## Categories

Each finding is tagged: Layout/Overflow · Accessibility · UX Flow · Feedback & States · Visual Consistency · Touch/Input · Error Handling.

## Notes

- Line numbers are accurate as of the review; verify against current source before editing.
- Most High findings are instances of three recurring gaps (unsaved-changes data loss, unguarded async actions, hidden errors). The Executive Summary explains how a few shared widgets resolve the bulk of the list — read it before working through the per-area files.
