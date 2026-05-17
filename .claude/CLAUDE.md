# Zenno — Project Notes

Flutter app for Android tablets — an Ahmni-style infinite-canvas study app.
Implementation plan: `~/.claude/plans/okay-improve-my-prompt-functional-bird.md`.

## Stack
- State: Riverpod 3 (codegen `@riverpod`). DB: Drift (SQLite, local-only).
- Nav: go_router. Models: freezed + json_serializable. Ink: perfect_freehand. PDF: pdfrx.
- Architecture: feature-first. Engine under `lib/canvas/`; features under `lib/features/`; shared Kanban under `lib/shared/kanban/`.

## Build
- Run `dart run build_runner build` after touching Drift tables, `@riverpod` providers, or freezed models.
- Target device: Samsung Galaxy Tab S9 FE (Android, S Pen). Verify on-device — emulators do not reproduce S Pen pressure/hover.
- Web is a dev-preview target (`flutter run -d chrome`). Phase 0 UI runs on web fine. WARNING: once a phase actually reads the DB, web needs `sqlite3.wasm` + a drift worker placed in `web/` — `drift_flutter` does NOT auto-bundle them. Add before testing DB-backed phases on web.

## Lessons Learned
- [WORKS][deps]: Drift's SQLite ships transitively via `drift_flutter` (`sqlite3` + `sqlite3_flutter_libs`). Do NOT add `sqlite3_flutter_libs` to pubspec explicitly.
- [WORKS][phase0]: Phase 0 scaffold verified green — `flutter analyze` clean, debug APK builds (`minSdk 24` OK for pdfrx/drift/file_picker), Drift FK-cascade + seed tests pass.
- [FAIL][scaffold]: `flutter create --platforms=<x> .` regenerates default files (e.g. `test/widget_test.dart` referencing `MyApp`) — delete/replace them again after adding a platform.
- [WORKS][canvas]: `perfect_freehand` exports its own `StrokePoint` that collides with `lib/canvas/model/stroke.dart` — import it with `hide StrokePoint`.
- [FAIL][riverpod]: A `@riverpod` codegen provider whose signature names a Drift-generated row class (`Canvase`, `AppSetting`, `RitualChecklistItem`, …) throws `InvalidTypeException` at codegen. Use a plain `StreamProvider`/`Provider` for those, or return a hand-written model.
- [FAIL][riverpod]: riverpod_generator 4.x strips a trailing "Notifier" — `@riverpod class FooNotifier` generates `fooProvider`, NOT `fooNotifierProvider`.
- [FAIL][riverpod]: Riverpod 3 removed `AsyncValue.valueOrNull` — use `.value` (nullable, non-throwing).
- [FAIL][file_picker]: file_picker 11 made `pickFiles` static — call `FilePicker.pickFiles(...)`, NOT `FilePicker.platform.pickFiles(...)`.
- [FAIL][drift]: Drift's `CanvasElements` table generates a row class `CanvasElement` that collides with the canvas engine's sealed `CanvasElement` — import `database.dart` with `hide CanvasElement` (or alias `as db`).
- [WORKS][v1]: All 6 phases feature-complete & verified — `flutter analyze` clean, 159 tests pass, web + release APK build. Web runtime still needs `sqlite3.wasm` + a drift worker in `web/` for DB-backed screens; the Android APK is fully functional.
