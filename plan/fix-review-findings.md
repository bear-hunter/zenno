# Zenno Review-Fix Plan

## Summary

Fix every review finding with a full sweep: Focus session durability, canvas save failure visibility, wakelock behavior, distraction timing, persisted library sort, thumbnails, tile-picture caching, Drift schema/migration hardening, and analyzer cleanup.

## Key Changes

- **Focus durability and runtime restore**
  - Add migration-backed runtime columns to `focus_sessions`: timer runtime status, current phase, phase start time, carried phase seconds, phase target seconds, and banked focus seconds.
  - Add a pure-Dart `TimerEngineRuntimeSnapshot` plus `TimerEngine.fromRuntime(...)` and `runtimeSnapshot` so live sessions can be persisted and restored without Flutter/Drift coupling.
  - Update `ActiveSessionController` to hydrate the latest `inProgress` session on provider build, persist runtime every 15 seconds, and persist immediately on pause/resume/phase change/stop.
  - Add injectable `focusClockProvider` for deterministic controller tests.
  - Change distraction `elapsed_secs` to wall-clock seconds since `started_at`, clamped at zero.

- **Focus wakelock**
  - Add `wakelock_plus`.
  - Add a small `FocusWakelockService` provider so tests can fake it.
  - Enable wakelock when a session starts/restores and `keepScreenOnInFocus` is true; disable it on abandon, completed review/discard, provider dispose, or when the setting is false.

- **Library sort and thumbnails**
  - Remove the duplicate library-local `LibrarySort`; use the Drift/settings enum everywhere.
  - Replace the in-memory `LibrarySortNotifier` with the persisted `app_settings.library_sort`.
  - Add `LibraryRepository.updateThumbnailPath(...)`.
  - Capture a canvas thumbnail on explicit editor close/back using a `RepaintBoundary`, save it under app documents `thumbnails/<canvasId>.png`, update `thumbnail_path`, and show `Image.file` in `CanvasCard` with the existing placeholder fallback.

- **Canvas persistence safety and performance**
  - Replace silent persistence swallowing with tracked write tasks: failed upsert/delete/viewport/thumbnail writes set an exposed controller save-error state and keep retryable closures.
  - Show a non-blocking "Canvas not saved" banner in the editor with Retry and Dismiss; on back/close, await `flush()` and warn before leaving if save failures remain.
  - Add a controller-owned committed-layer tile picture cache with 2048-world-unit tiles, revision-based invalidation, and LRU eviction. Cache only committed non-drag content; live stroke, selection overlay, and dragged selection remain uncached.

- **Drift schema and cleanup**
  - Bump `schemaVersion` to 2 and add an explicit v1-to-v2 migration for the Focus runtime columns.
  - Add committed schema exports under `drift_schemas/` using `dart run drift_dev schema dump lib/core/database/database.dart <output>`.
  - Add generated schema verifier support with `dart run drift_dev schema generate <schema-input> <output>` and a migration test for v1-to-v2.
  - Remove the unnecessary `flutter/painting.dart` import from `test/canvas_commands_test.dart`.

## Test Plan

- Run and keep green: `flutter analyze`, `flutter test`, `flutter build apk --debug`, `flutter build appbundle --release`.
- Add tests for:
  - Restoring an in-progress Pomodoro and Flowmodoro session from persisted runtime.
  - Runtime persistence on tick interval, pause/resume, phase transition, and stop.
  - Distraction elapsed seconds using wall-clock session age rather than focus-only time.
  - Wakelock enable/disable behavior with both setting values.
  - Library sort reading/writing through `app_settings.library_sort`.
  - Thumbnail path update and `CanvasCard` fallback when the file is absent.
  - Canvas persistence failure state, retry, and back-navigation warning.
  - Tile cache invalidation when elements/raster revisions change.
  - Drift v1 database migrates to v2 with defaults and existing rows preserved.

## Assumptions

- Use a proper schema v2 migration even if v1 has not shipped, because Karl may already have local test databases.
- Existing v1 `inProgress` sessions without runtime data restore as paused work sessions using their saved `actual_focus_secs`.
- Thumbnail generation is best-effort on editor close; save failures surface through the same canvas save-error banner.
- Tile caching is implemented for committed rendering only, not for live ink or overlays.
