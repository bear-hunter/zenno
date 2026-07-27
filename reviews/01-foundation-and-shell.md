# Foundation & Shell — UI/UX Review

Scope: design tokens (`lib/config/theme/`), the navigation shell (`core/widgets/app_scaffold.dart`), app root (`app.dart`, `main.dart`), and shared utilities (`core/util/relative_time.dart`).

Findings: 0 High · 7 Medium · 3 Low, plus cross-cutting recommendations.

---

## What is already good

The theme layer is a genuine strength and most feature-level inconsistencies are violations *of* it, not gaps *in* it:

- `AppColors` / `AppSpacing` / `AppTextStyles` give a real token system. The dark-first Material 3 theme is coherent — hand-tuned near-black surface ramp, single warm-gold accent, explicit line heights so multi-line text breathes.
- `app_theme.dart` sets `materialTapTargetSize: MaterialTapTargetSize.padded` globally, so the **default** touch target is already 48 dp. Every sub-48 dp target reported in the feature files is a *local override* of this good default (`shrinkWrap`, custom `InkWell`/`InkResponse`), not a missing baseline.
- Mastery-flag colors are intentionally fixed (`flagGreen/Yellow/Red`) instead of seed-derived — correct call, semantic colors must stay recognisable.
- `AppSpacing.contentMaxWidth` (720) exists and is used to keep form line length comfortable on wide tablet landscapes.

The issues below are about closing the remaining gaps in that system and the shell.

---

## Design tokens (`lib/config/theme/`)

### Medium · Visual Consistency · no radius scale
**Problem.** `AppSpacing` covers spacing only. The theme reuses *spacing* values as corner radii (card = `AppSpacing.md` = 12, dialog/FAB = `AppSpacing.lg` = 16, inputs = `AppSpacing.sm` = 8). Feature code then hardcodes radii ad hoc and inconsistently — `focus_home_page.dart` uses `BorderRadius.circular(16)` for `_StartCard`/`_ResumeBanner` but `12` for `_StatsSummary`/`_NoSessionsYet` on the *same screen*; `ritual_checklist.dart` uses `8`. There is no single source of truth, so radii drift.
**Fix.** Add an `AppRadii` token set (e.g. `sm`, `md`, `lg`, `pill`). Reference it in `app_theme.dart` and in feature widgets. Eliminate raw `BorderRadius.circular(n)` literals.

### Medium · Visual Consistency · no icon-size scale
**Problem.** Icon sizes are magic numbers everywhere. Empty-state icons are hardcoded `size: 56` in at least four places (`revision_board_page`, `templates_page`, `goal_board_page`, settings message panel); toolbar icons are `18`; kanban drag handles are `18`/`20`. Nothing ties them together.
**Fix.** Add an `AppIconSizes` token set (e.g. `inline`, `action`, `emptyState`). Replace literals.

### Medium · Visual Consistency · no standard dialog width
**Problem.** Dialogs each hardcode a different content width: text-note dialog `420`, link-target dialog `360`, canvas-picker dialog `520`, kanban dialogs `420`/`520`. None adapt to orientation. `contentMaxWidth` (720) addresses forms but there is no dialog equivalent.
**Fix.** Add a dialog-width token (or a small `AppDialog` wrapper that applies a responsive `ConstrainedBox`). Make dialog width derive from `MediaQuery` clamped to that token rather than fixed.

### Medium · Visual Consistency · brand gold re-declared as a raw literal
**Problem.** `AppColors.goldAccent` is `0xFFE8B84B`, but that exact ARGB value is re-typed as a literal in `canvas_toolbar.dart` (`_swatches`), `elements_painter.dart` (`_accent`, `_selectionHalo`, `_linkChipFill`), `canvas_overlay_painter.dart` (`_accent`), and mirrored in `live_stroke_painter.dart`. `CustomPainter`s legitimately need raw `Color`s, but they should *derive* from `AppColors`, not duplicate it. A future accent change would leave the canvas chrome stale.
**Fix.** Have the painters and the toolbar import `AppColors` and build alpha variants from `AppColors.goldAccent` / surface tokens.

### Low · Visual Consistency · light theme nav-rail indicator is faint
**Problem.** `navigationRailTheme.indicatorColor` is `primary.withValues(alpha: 0.20)`. Gold at 20 % alpha over the light surface produces a weak selected-pill; combined with the missing `selectedIcon` (below) the selected destination is hard to read in the light theme.
**Fix.** Use a higher alpha for light, or pair the indicator with a filled `selectedIcon`.

---

## Navigation shell (`core/widgets/app_scaffold.dart`)

### Medium · Feedback & States · destinations have no selected icon
**Problem.** All five `NavigationRailDestination`s use `_outlined` icons for both states; no `selectedIcon` is supplied. The Material 3 convention is outlined-when-unselected, filled-when-selected. Without it, the only selected-state cue is the subtle rail pill — weak for a glanceable tablet shell.
**Fix.** Add a filled `selectedIcon` per destination (e.g. `Icons.grid_view` selected vs `Icons.grid_view_outlined` unselected).

### Medium · Layout/Overflow · no portrait / split-screen fallback
**Problem.** The shell is a hard `Row` of `NavigationRail` + content. The app locks landscape (`main.dart`), so the common case is safe — but Samsung DeX and Android split-screen multi-window can still present a narrow or non-landscape aspect ratio that the landscape lock does not prevent. The rail then eats horizontal space with no fallback.
**Fix.** Wrap the shell in a `LayoutBuilder` that drops to a bottom `NavigationBar` (or a minimal rail) below a width breakpoint.

### Low · Feedback & States · re-tapping the active destination silently resets the branch
**Problem.** Tapping the already-selected rail item calls `goBranch(..., initialLocation: true)`, popping that branch to its root. This is intentional, but if the user was deep in a sub-page a stray tap silently discards their place with no signal.
**Fix.** Acceptable as-is; consider only resetting when the branch is genuinely away from root, or a brief transition so the reset is perceptible.

---

## App root (`app.dart`, `main.dart`)

### Low · UX Flow · theme fallback can flash on cold start
**Problem.** `ZennoApp` watches `appSettingsProvider`; while it resolves, `themeMode` defaults to `ThemeMode.dark`. A user who selected the Light theme sees a brief dark flash before the setting loads on cold start.
**Fix.** Persist the last-used `themeMode` somewhere read synchronously at startup, or show a neutral splash until settings resolve.

### Low · UX Flow · landscape lock is fire-and-forget
**Problem.** `main.dart` calls `setPreferredOrientations` without awaiting or error handling. Harmless in itself, but every downstream layout (notably the Kanban board) assumes landscape with no responsive fallback. See the shell portrait note above.
**Fix.** No change needed in `main.dart`; the responsive gap belongs in the layout widgets.

---

## Utilities (`core/util/relative_time.dart`)

### Low · Visual Consistency · `4w` jumps straight to `1mo`
**Problem.** `weeks = days ~/ 7` but the branch is gated by `days < 30`, so the maximum week output is `4w` (day 28–29); day 30+ jumps to `1mo`. Day 29 → "4w ago" then day 31 → "1mo ago" is a slightly jarring boundary.
**Fix.** Cosmetic only — extend the week bucket (e.g. `days < 45`) or accept the boundary. The helper is otherwise correct and handles future timestamps gracefully.

---

## Cross-cutting recommendations (shared widgets to introduce)

These recur in every feature review. Building them once at the foundation layer fixes dozens of individual findings:

1. **`AsyncValueWidget<T>`** — a single wrapper for `AsyncValue` that renders a consistent loading state, a consistent error state *with a Retry button* (`ref.invalidate(...)`), and the data. Today loading is a bare `CircularProgressIndicator` on some screens and styled on others; error states vary from polished panels to raw `$error` interpolation, and **none** offer retry.
2. **A friendly error presenter.** Several SnackBars and inline error texts interpolate the raw exception (`'$error'`), surfacing Drift/SQLite stack-traced strings to the user. Standardise a helper that shows human copy and logs the raw error.
3. **A "destructive action" helper** — confirm dialog *or* an action-with-Undo SnackBar — applied uniformly. Many destructive actions across the app have neither.
4. **An `AppDialog` scaffold** — applies the responsive dialog width token and consistent padding, so the three different hardcoded dialog widths collapse to one.
5. **A guarded async-action mixin/helper** for buttons — disables the control while in flight, shows a spinner, try/catches, and reports failure. This single pattern resolves the most common High-severity finding in the feature reviews (bare `await` of a DB write with no loading/disabled/error state).
