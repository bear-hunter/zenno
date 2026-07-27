ALL OF THESE GAPS ARE ALREADY RESOLVED!

ALL ARE MERGED TO STAGING

FYI "/best" is not needed anymore

ALREADY PR-ED AND MERGED

Short answer: **not fully**. The staging branch implements a lot of the plan, but I would not call it complete/correct against `queue-intel-recovery-plan.html`.

**Findings**

- **P1: Historical ranking rebuild is missing.**  
  [migration 045](/Users/karlromero/work/center-court-central-email/migrations/045_queue_intel_hybrid_scores.sql:8) adds the hybrid score columns, but it does not backfill `actual_score`, `hypothesis_score`, `final_rank_score`, or scored-drop counts for existing `account_scores`. Outputs then fall back to legacy `composite_score` via `COALESCE`, e.g. [/best](/Users/karlromero/work/center-court-central-email/src/discord/bot.ts:126), [profile export](/Users/karlromero/work/center-court-central-email/src/queue-intel/profile-export.ts:133), and [analyzer payload](/Users/karlromero/work/center-court-central-email/src/queue-intel/analyzer-data.ts:164). That misses the plan’s “backfill then rebuild account rankings” requirement.

- **P1: Queue-score repair only fills nulls, not all anchored historical sessions.**  
  The plan says recompute `queue_score` for every historical anchored session. The migration only updates rows where `qe.queue_score IS NULL` at [migration 045](/Users/karlromero/work/center-court-central-email/migrations/045_queue_intel_hybrid_scores.sql:43). If any historical score was stale because an anchor changed or was previously computed wrong, it stays stale.

- **P1: Weight changes do not trigger ranking recalculation.**  
  The dashboard saves weights at [scoring-weights.ts](/Users/karlromero/work/center-court-central-email/src/dashboard/routes/scoring-weights.ts:74) and redirects. `scoreCalculator.updateWeights` also only writes weights at [score-calculator.ts](/Users/karlromero/work/center-court-central-email/src/queue-intel/score-calculator.ts:222). Recalculation waits for the nightly cron at [index.ts](/Users/karlromero/work/center-court-central-email/src/index.ts:317), so the plan’s “recompute after weight changes” is not satisfied immediately.

- **P2: Human-reviewed memory workflow is schema-only.**  
  Memory candidates are persisted, but [memory.ts](/Users/karlromero/work/center-court-central-email/src/queue-intel/memory.ts:97) always inserts them as `'hypothesis'`. I found no route/UI/API that lets Trevor promote/refute/regression-test findings or set `human_reviewed_by`, so the success criterion “Humans control promotion from hypothesis to confirmed memory” is not implemented yet.

- **P2: `/best` does not clearly label cross-test/emerging accounts in the main embed.**  
  It selects `score_reason_codes` at [bot.ts](/Users/karlromero/work/center-court-central-email/src/discord/bot.ts:142), but the displayed line only shows score components and drop counts at [bot.ts](/Users/karlromero/work/center-court-central-email/src/discord/bot.ts:225). The companion score report carries reason codes, but the operator-facing ranking is not clearly labeled as the plan requires.

What looks good: EOD/API gating is in place, partial tags are rejected, `tagged_at` is set only on full tags, incomplete sessions remain in backlog, anchor accounts are excluded from the main scoring/analyzer/export paths, the hybrid scoring model exists, and the analyzer payload/memory persistence/brief were substantially updated.

Validation I ran:

- Queue Intel tests: `99 passed`
- EOD/API targeted tests: `87 passed`
- `pnpm build`: passed
- `pnpm lint`: passed with 7 warnings
- `pnpm lint:migrations`: passed, 6 acknowledged warnings

There is no `tests/discord*` path, so the Discord `/best` behavior is not covered by the plan’s requested validation.




ALREADY PR-ED AND MERGED

Not fully. Staging implements most of `queue-intel-recovery-plan.html`, but I found one real plan-compliance gap.

**Finding**
- [P1] Cross-presale scoring can still include anchor evidence from other presales: [score-calculator.ts](/Users/karlromero/work/center-court-central-email/src/queue-intel/score-calculator.ts:268) only excludes accounts that are anchors for the requested `$1` presale. But the query intentionally loads all presale events, then uses `allEvents` for `totalScoredDropCount`, carryover, hypothesis proxy, and emerging/cross-test scores at [score-calculator.ts](/Users/karlromero/work/center-court-central-email/src/queue-intel/score-calculator.ts:285). That means if an account was an anchor in some other presale, its anchor row can still boost cross-presale evidence. The plan says anchor accounts must be excluded from rankings, examples, cohorts, and hypothesis tracking.

**What Looks Correct**
- EOD/API gating requires `presale_type_id` and `anchor_position` together.
- Historical queue score repair exists in migration `046`.
- `/best` ranks by `final_rank_score`, removes tier display, shows actual/hypothesis/confidence/drop counts, and attaches Jancy CSV + score report for presale-specific requests.
- Analyzer payload uses fully tagged, scored, non-late evidence and excludes target-presale anchors.
- Hybrid score fields, memory table, memory injection, human status updates, and updated brief are present.
- `account_group` is removed from active scoring/analyzer/export paths for this work.

**Validation Run**
- `pnpm test tests/queue-intel tests/dashboard/eod-panel-tagged-at.test.ts tests/dashboard/eod-panel-recently-tagged.test.ts tests/dashboard/eod-panel-sessions-filter.test.ts tests/api/drop-sessions.test.ts` passed: 133 tests.
- `pnpm build` passed.
- `pnpm lint` passed with 7 pre-existing warnings.
- `pnpm lint:migrations` passed with expected historical warnings.

Verdict: mostly implemented, but I would not call it fully correct until anchor exclusion is tightened across all cross-presale scoring evidence.

ALREADY PRED AND MERGED DO NOT MIND "/BEST"

**Findings**
1. [P1] Score repair does not rebuild rankings after changing historical `queue_score`.
[migrations/046_queue_intel_full_score_repair.sql](/Users/karlromero/work/center-court-central-email/migrations/046_queue_intel_full_score_repair.sql:8) repairs `queue_events`, but nothing invalidates or rebuilds `account_scores`. Startup only calls `refreshStaleHybridScores()` in [src/index.ts](/Users/karlromero/work/center-court-central-email/src/index.ts:70), and that only catches missing/null/old model rows in [src/queue-intel/score-calculator.ts](/Users/karlromero/work/center-court-central-email/src/queue-intel/score-calculator.ts:496). If staging already has current hybrid rows, `/best` can keep using stale `final_rank_score` until the nightly refresh.

2. [P1] Cross-presale scoring can still include anchor evidence from non-target presales.
The scorer intentionally loads all presale histories for carryover in [src/queue-intel/score-calculator.ts](/Users/karlromero/work/center-court-central-email/src/queue-intel/score-calculator.ts:251), but the anchor exclusion only checks anchor emails for the requested presale at [src/queue-intel/score-calculator.ts](/Users/karlromero/work/center-court-central-email/src/queue-intel/score-calculator.ts:274). That means a row where `qe.account_email = ds.anchor_account_email` from another presale can still affect total-drop counts, carryover, and cross-test ranking.

3. [P2] The “10+ total scored drops can be proven” rule is not fully implemented.
`rankingMode()` labels direct `<3` and total `>=10` accounts as `cross_test` in [src/queue-intel/score-calculator.ts](/Users/karlromero/work/center-court-central-email/src/queue-intel/score-calculator.ts:135), then applies the 50/50 formula at [src/queue-intel/score-calculator.ts](/Users/karlromero/work/center-court-central-email/src/queue-intel/score-calculator.ts:370). The plan says 10+ total drops with strong carryover can use proven 80/20 treatment, so that graduation logic is missing unless v0.6 intentionally superseded the plan.

4. [P2] `hypothesis_score` is persisted/displayed, but not actually LLM/memory-driven.
The score comes from deterministic history/carryover in [src/queue-intel/score-calculator.ts](/Users/karlromero/work/center-court-central-email/src/queue-intel/score-calculator.ts:165). Memory is stored and injected for future analyzer prompts in [src/queue-intel/memory.ts](/Users/karlromero/work/center-court-central-email/src/queue-intel/memory.ts:32), but promoted/refuted memory does not affect account ranking. So the plan’s “LLM hypotheses add controlled lift” piece is only partially implemented.

**What Looks Good**
P0 gating is mostly in place: EOD/API require presale type and anchor together, queue scores are computed from anchors, analyzers require fully tagged/scored/non-late evidence, `/best` ranks by `final_rank_score`, the Jancy CSV headers match the template, memory review exists, and the brief was updated.

**Validation**
Passed: `pnpm test tests/queue-intel "tests/dashboard/eod-panel*"`: 100 tests.  
Passed: `pnpm build`.  
Passed: `pnpm lint:migrations` with existing warnings only.  
Passed: `pnpm lint` with 7 warnings, 0 errors.

Bottom line: staging implemented a lot of the plan, but I would not call it fully correct yet because stale ranking rebuild and cross-presale anchor contamination can make `/best` materially wrong.

ALREADY PR-ED AND MERGED DO NOT MIND "/BEST"

**Findings**
- P2: `/best` only attaches the human score report when a `presale_type` is provided. The all-types path still attaches only the Jancy CSV, even though `presale_type` is optional and the plan calls for a Jancy CSV plus human-readable score report. See [src/discord/bot.ts](/Users/karlromero/work/center-court-central-email/src/discord/bot.ts:275).
- P3: I don’t see dedicated Discord `/best` tests, despite the plan asking for tests proving anchors do not appear in `/best`. The SQL looks right, but this remains a coverage gap around an operator-facing command.

Short answer: **mostly yes**. The core recovery plan is implemented on `staging`: evidence gating, queue score repair, anchor exclusion, hybrid score fields, account-group removal from active scoring, Jancy-compatible export, analyzer v2 payload, persisted memory, brief update, and daily scan gating are all present.

I validated with:
- `pnpm test tests/queue-intel 'tests/dashboard/eod-panel*' 'tests/discord*'` passed Queue Intel tests; no Discord tests were matched.
- Direct EOD tests passed: `86` tests.
- API/drop-session, scoring weights, and analysis-route tests passed.
- `pnpm build` passed.
- `pnpm lint:migrations` passed.
- `pnpm lint` had `0` errors and `7` warnings in unrelated existing files.

So I’d call this **implemented enough to move forward**, with the `/best` all-types score-report gap and Discord command test coverage worth tightening before telling Trevor it is fully complete.


ALREADY PRED AND MERGED, DO NOT MIND "/BEST"

No, I would not call staging fully implemented against [queue-intel-recovery-plan.html](/Users/karlromero/work/center-court-central-email/.plans/queue-intel-recovery-plan.html:520). The core recovery work is mostly there, but I found a few gaps.

**Findings**
- **P1: Default scoring-weight tunability is broken.** [migrations/021_scoring_weights.sql](/Users/karlromero/work/center-court-central-email/migrations/021_scoring_weights.sql:14) uses a normal `UNIQUE (presale_type_id)`, but Postgres allows multiple `NULL` values. Both [score-calculator.ts](/Users/karlromero/work/center-court-central-email/src/queue-intel/score-calculator.ts:330) and [scoring-weights.ts](/Users/karlromero/work/center-court-central-email/src/dashboard/routes/scoring-weights.ts:79) rely on that constraint to upsert the global default row, so saving “Default (All Types)” can insert duplicate default rows instead of updating the existing one. Reads then use `LIMIT 1` with no deterministic ordering. This violates the plan’s “retain admin tunability” requirement.

- **P2: `/best` only attaches the score report when a presale type is supplied.** The presale-specific branch attaches Jancy CSV plus score report, but the all-types branch only emits a manually built Jancy CSV in [bot.ts](/Users/karlromero/work/center-court-central-email/src/discord/bot.ts:290). The plan says `/best` should attach “a Jancy CSV plus score report” and the human report should carry score evidence.

- **P2: Queue Dashboard still exposes `account_group` as Queue Intel UI.** [queue-dashboard.ts](/Users/karlromero/work/center-court-central-email/src/dashboard/routes/queue-dashboard.ts:53) accepts a `group` filter, filters on `a.account_group`, selects it, and loads group dropdown data; [queue-dashboard.ejs](/Users/karlromero/work/center-court-central-email/views/pages/queue-dashboard.ejs:122) renders the Group filter. The plan’s success criteria say tiers and `account_group` should be removed from user-facing Queue Intel outputs.

**What Looks Implemented**
P0 evidence gating, queue score repair, anchor exclusion, hybrid score fields, analyzer v2 payload, memory persistence/review, brief refresh, and daily scan gating are all present in staging.

**Validation**
I ran:

- `pnpm test tests/queue-intel tests/dashboard/eod-panel-tagged-at.test.ts tests/dashboard/eod-panel-recently-tagged.test.ts tests/dashboard/eod-panel-sessions-filter.test.ts tests/api/drop-sessions.test.ts tests/dashboard/scoring-weights.test.ts` → 139 passed
- `pnpm build` → passed
- `pnpm lint:migrations` → passed, 6 acknowledged warnings
- `pnpm lint` → 0 errors, 7 warnings in unrelated existing files

So: staging is close, but not complete against the plan until those output/tunability gaps are fixed.

LATEST CONCERN, IN THE PROCESS OF CREATING FIXES ON THESE FINDINGS

**Findings**
- [P2] Memory does not persist prior ranking outcomes. `analysis_results.account_rankings_json` is always written as `null` in [llm-analysis.ts](/Users/karlromero/work/center-court-central-email/src/queue-intel/llm-analysis.ts:72), and prior prompt memory only loads `queue_intel_memory_findings` from [memory.ts](/Users/karlromero/work/center-court-central-email/src/queue-intel/memory.ts:42). Findings/hypotheses/status review are implemented, but the plan’s “prior ranking outcomes” part is still partial.
- [P2] “Last 10 scored drops” is implemented as last 10 queue events, not definitely distinct drop sessions. Scoring slices event arrays in [score-calculator.ts](/Users/karlromero/work/center-court-central-email/src/queue-intel/score-calculator.ts:428), and analyzer uses `ROW_NUMBER()` over events in [analyzer-data.ts](/Users/karlromero/work/center-court-central-email/src/queue-intel/analyzer-data.ts:163). If ingest guarantees one event per account per drop, this is fine; the DB uniqueness still allows multiple timestamps per account/drop.

Everything else important from the recovery plan looks correctly implemented, ignoring `/best` as requested: EOD/API partial-tag rejection, queue score repair, anchor exclusion, hybrid actual/hypothesis/final scoring, analyzer v2 payload, memory review statuses, brief update, and Eastern-time scheduled scans are all present.

Validation passed:
- Targeted Queue Intel/EOD/API/analysis tests: `200 passed`
- `pnpm build`: passed
- `pnpm lint`: passed with 7 warnings, no errors
- `pnpm lint:migrations`: passed, `48 pass, 0 fail`