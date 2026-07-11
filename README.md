# Zenno

Zenno is an Android-tablet study app built around an infinite canvas. It is designed for S Pen-first thinking: handwriting, imported PDFs/images, links between canvases, study boards, focus sessions, revision cards, and reflection workflows.

The current product target is a Samsung Galaxy Tab S9 FE with S Pen. Web can be useful for development previews, but Android is the real runtime target for canvas and pen behavior.

## What Is In The App

- Infinite canvas engine with pan/zoom/rotate, freehand ink, highlighter, eraser, lasso selection, shapes, image/PDF import, bookmarks, and canvas links.
- Local-first Drift SQLite persistence for canvases, boards, focus sessions, revision cards, reflections, and settings.
- Study system features: goal-cycle boards, revision board, Flowmodoro/Pomodoro focus flows, distraction capture, and review history.
- Shared Kanban and canvas-attachment components used by multiple study features.

## Tech Stack

- Flutter / Dart
- Riverpod 3 with code generation
- Drift SQLite via `drift_flutter`
- go_router
- freezed + json_serializable
- perfect_freehand for ink geometry
- pdfrx for PDF rendering

Architecture is feature-first:

- `lib/canvas/` contains the canvas engine, rendering, input, persistence, import, and editor UI.
- `lib/features/` contains product features such as focus, goal cycle, library, revision, and settings.
- `lib/shared/` contains reusable app components.
- `lib/core/` contains database, providers, utilities, and app-level infrastructure.

## Setup

```bash
flutter pub get
```

Generated files are committed, but regenerate them after changing Drift tables, Riverpod providers, freezed models, or json-serializable types:

```bash
dart run build_runner build
```

If generated files conflict during active development, use:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Run

Android device:

```bash
flutter run -d <device-id>
```

Web development preview:

```bash
flutter run -d chrome
```

Note: DB-backed web flows load `web/sqlite3.wasm` directly into Drift's
IndexedDB-backed WASM database. Android remains the reliable target for
persistence-heavy testing. The web preview takes an exclusive browser lock;
if another Zenno tab owns the database, a second tab refuses to open it.

## Validate

Use the smallest relevant check for the change, then broaden when shared behavior is touched.

```bash
flutter analyze
flutter test
```

Useful targeted tests:

```bash
flutter test test/canvas_commands_test.dart
flutter test test/canvas_repository_test.dart
flutter test test/ink_codec_test.dart
flutter test test/spatial_index_test.dart
flutter test test/elements_painter_test.dart
```

Android build smoke tests:

```bash
flutter build apk --debug
flutter build appbundle --release
```

## Canvas Work Notes

The canvas is split into a few important layers:

- `CanvasView` routes raw pointer input into controller actions.
- `CanvasController` owns viewport state, active tools, live gestures, undo/redo, spatial indexing, imports, and persistence write-through.
- `ElementsPainter` paints committed canvas elements with viewport culling and tile-picture caching.
- `LiveStrokePainter` paints the in-progress ink/shape preview.
- `CanvasRepository` maps engine elements to Drift rows and back.

## Development Rules

- Inspect the relevant code before editing.
- Keep changes scoped to the requested behavior.
- Do not commit, push, create PRs, merge, rebase, or run destructive git commands unless explicitly asked.
- Do not write secrets into tracked files.
- Run `dart run build_runner build` after table/provider/model changes.
- Use a real S Pen device for final manual verification of pressure, hover, palm rejection, and handwriting latency.
