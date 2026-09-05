# ADR 0008: Per-Run Seed Instead Of Daily Seed

## Status

Accepted

## Context

Route generation derived its seed from the current UTC calendar date
(`DailySeedKey.current_utc`), so every player saw the same tower layout for a
given 24-hour period. This was the intended basis for a future shared-layout
feature (friend death ghosts, fall sprays, daily challenges), documented in
`docs/05-meta-viral-features.md` and referenced as an MVP positioning choice
in `docs/README.md`.

The product decision changed: every run should get its own fresh layout,
independent of the calendar day and of any other run, rather than sharing one
layout globally per day.

## Decision

Replace the UTC-date seed source with a per-run one. `DailySeedKey` drops
`current_utc()` and gains `current_run() -> String`, composing the existing
`GENERATOR_VERSION` prefix with run-unique entropy (`Time.get_ticks_usec()` +
`randi()`) instead of a UTC date. The one call site,
`scenes/main/run_scene.gd`, switched from `DailySeedKey.current_utc(utc_date_provider)`
to `DailySeedKey.current_run()`, and the now-unused `utc_date_provider`
wiring (field, setter, `UtcDateProvider`/`SystemUtcDateProvider` consts) was
removed from that scene.

`DailySeedKey.from_utc_date()` is unchanged and stays in place: it is used
throughout the test suite purely as a convenient deterministic seed-string
factory, unrelated to "today." Every downstream generation file
(`DailyChunkGenerator`, `ChunkRouteGenerationPipeline`,
`RouteAnchorGraphBuilder`, `ChunkRoutePathSolver`, ...) already treats
`seed_key` as an opaque string it doesn't interpret, so no generation logic
changed -- only the origin of the string passed into it.

`src/platform/clock/utc_date_provider.gd` and `system_utc_date_provider.gd`
are untouched: they remain the typed UTC clock adapter used by the Supporter
subscription's daily-coin-claim reset cadence (`src/platform/commerce/subscription_adapter.gd`,
`docs/04-economy-monetization.md`), an unrelated system.

## Consequences

- Two runs, even started back to back, generate different routes. Verified
  by `tests/unit/test_daily_seed_key.gd` and
  `tests/scene/test_run_scene.gd:test_run_scene_generated_seed_key_is_random_per_run`.
- The daily-shared-layout premise behind the planned friend-ghost/fall-spray
  feature (`docs/05-meta-viral-features.md`) and the MVP positioning note in
  `docs/README.md` no longer has a technical basis and needs its own
  follow-up product decision: rework the shared-route framing, or key that
  feature off something else (e.g. an explicit opt-in "share this run's
  seed" action) instead of "today's route." This ADR does not resolve that;
  it only records that the underlying seed mechanism changed.
- Local daily progression (daily best, streaks) is a calendar-day *stat*
  independent of route content and is unaffected by this change.
