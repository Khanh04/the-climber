# Route Generation Audit

Audit of the route/level generation algorithm (`src/gameplay/generation/` and everything that
feeds or consumes it), focused on making runs more fun. Priorities: repetition/sameness,
difficulty fairness, progression/stakes, reach/grab clarity.

The random per-run seed is **intentional** (endless, no shared daily challenge), so it is not
treated as a bug here.

Status: **superseded.** On 2026-10-07 the route-first generator audited here was replaced by
the hold-field generator ([ADR 0011](adr/0011-hold-field-generation.md)). Findings about the
deleted internals (plan builder, lane solver, population builder, route validator, slot
scheduler) no longer apply; runtime findings (T3/D2 `MISSED_GRIP_FALL`, T6 assert-based
validation, C4 stamina, T12 main-thread generation) still do. Measurement harness:
`tools/generation/`.

- **First audit:** 2026-10-02 (findings T1–T12, A1–D3).
- **Re-audit:** 2026-10-07, after the fix commits `9a9d9a6` … `ef873f0`, `5037b27`, `f61c06c`.
  Every earlier finding now carries a status, and new findings are numbered N1–N10.
  Sources: code review of the current tree, plus a headless run of the real generator over
  150 run seeds x 15 chunks (2,250 chunks, 0–180 m) to measure N1, N2, N4 and N11.

---

## How generation works today

```
DailySeedKey.current_run()  ("generator_v5:run:<usec>-<randi>")   <- only entropy source
  -> GeneratedChunkCoordinator._ensure_chunk  (main thread, synchronous)
  -> DailyChunkGenerator.build_chunk(seed, index)
      builds every predecessor 0..index (cached, evicted behind the player), each via a
      candidate loop (route_validation_candidate_attempt_count, default 3):
        ChunkRouteGenerationPipeline.build_layout    (once per candidate)
          1. ChunkRoutePlanBuilder       -> 11-row role template (seeded rotation)
                                            + branch contract + hazard intents
          2. RouteAnchorGraphBuilder     -> 5 lanes x 11 rows = 55 anchors, jittered
          3. ChunkRoutePathSolver        -> safe path (weighted lane walk, anti-ladder)
                                            + seeded optional/branch path
          4. ChunkRoutePopulationBuilder -> path holds, support holds, 1-3 rewards, hazards
          5. ChunkRouteLayoutEmitter     -> GeneratedChunkLayout
        RoutePathValidator.validate_layout  -> BFS over SAFE-PATH HOLDS ONLY to an exit port
        validate_chunk_seam(prev, candidate)          <- cached, see N1
      chunk 0: keep the highest least-committing score
      chunk 1+: keep a seeded pick among candidates within 0.05 of the target difficulty
      all candidates fail -> return null -> coordinator spawns nothing (wall gap)
```

Fixed invariants: every chunk is **11 rows / 12 m tall / ~0.985 m row pitch**. Difficulty
band by altitude: EASY `<50 m` (chunks 0–4), BASELINE `<100 m` (5–8), CHALLENGE `9+`, plus a
continuous altitude bonus of 0.15 per 100 m above 100 m (cap 0.6). Chunks 0–3 are always
OPENER / BASELINE / SKILL / RECOVERY; from chunk 4 the slot is a weighted seeded pick.

Hazard intents per slot, and the kind each resolves to:

| Slot | Intents |
|---|---|
| OPENER | Recovery lift |
| RECOVERY | Recovery lift, Safe-route relief |
| SKILL | Traverse force, Crux pressure |
| RISK | Branch denial, Reward greed |
| PRESSURE | Crux pressure, Branch denial |
| BASELINE | Safe-route relief, Traverse force |

| Intent | Kind | Anchored on |
|---|---|---|
| Branch denial | Spike 64% / Falling rock 29% / Pendulum log 7% | optional path, last outer row |
| Traverse force | Wind gust 80% / Wandering critter 20% | optional path if any, else **safe path** |
| Crux pressure | Downdraft | **safe path**, pressure row |
| Reward greed | Bug swarm | first reward's anchor |
| Recovery lift | Updraft | **safe path**, first CATCH row |
| Safe-route relief | Startle puff | **safe path**, last CATCH row |

---

## Part 1 — Technical issues

### Prior findings

| # | Status | Issue (original) → current state | Location |
|---|---|---|---|
| T1 | FIXED `9a9d9a6` | Merge row both arms identical → now a seeded pick of `size-2` / `size-1`. `difficulty_band` arg is validated but unused. | `chunk_route_plan_builder.gd:280-285` |
| T2 | FIXED `9a9d9a6` | `get_route_slot_for_chunk` used a different seed → method deleted. | — |
| T3 | **OPEN** | `MISSED_GRIP_FALL` defined, rescue-eligible, has end-screen copy, **never raised**. Only `STAMINA_FALL` (`run_session.gd:63`) and `BOTTOM_SCREEN_FALL` (`bottom_screen_fall_service.gd:25`) are emitted. | `run_end_reason.gd:7` |
| T4 | FIXED `9a9d9a6` | Phantom `.tscn` fields removed. Leftover: `handhold_definitions = null` overrides the script default — confirm intended. | `run_scene.tscn:121-123` |
| T5 | FIXED `4d720f2` | Dead tuning knobs removed. | `generation_tuning.gd`, `route_validation_tuning.gd` |
| T6 | **OPEN** | "Hard errors" are still `push_error` + `assert`; release builds strip `assert`, so every guard becomes log-and-continue. See also N8. | `validation.gd:4-9` |
| T7 | PARTIAL | Attempt count is now tunable but defaults to 3, with no escalation. All fail → `null` → coordinator logs and **leaves a wall gap**. N1 makes "all fail" more likely. | `daily_chunk_generator.gd:110-111`, `generated_chunk_coordinator.gd:88-90` |
| T8 | **OPEN** | Validator graphs safe-path holds only; hazards are invisible to it. Stacking was moved upstream (B4) but see N3. | `route_graph_builder.gd:32-33` |
| T9 | FIXED `4557111` | Seam now applies the downward-move limit. | `route_path_validator.gd:152-158` |
| T10 | FIXED `00eb6d0` | All seeded decisions use `DeterministicHash.of_string`; no `String.hash()` left. | — |
| T11 | FIXED `4d720f2`, **caused regression N1** | Caches evicted behind the player. The seam key dropped instance ids and no longer distinguishes candidates. | `daily_chunk_generator.gd:56, 289-290` |
| T12 | PARTIAL `29e61ed` | Each candidate is built once now. Generation is still synchronous on the main thread at every 12 m boundary. | `generated_chunk_coordinator.gd:87` |

### New findings

| # | Sev | Issue | Location |
|---|---|---|---|
| N1 | FIXED 2026-10-07 | **Seam cache shared across candidates.** The key was `seed\|i\|i+1`, so every candidate of a chunk reused the first candidate's seam result. The key now includes both layouts' candidate attempt index; regression test `test_each_candidate_gets_its_own_seam_check`. | `daily_chunk_generator.gd` `_get_chunk_seam_cache_key` |
| N7 | LOW | Solver failure asserts instead of counting as a failed candidate attempt. | `chunk_route_generation_pipeline.gd:80` |
| N8 | LOW | **Silent fallbacks**, which break the "no silent fallback" rule once asserts are stripped (T6): `return Vector2.ZERO` after `require_condition(false)` (`daily_chunk_generator.gd:315`); hazard kind defaults to SPIKE (`chunk_route_population_builder.gd:616`); `minf` quietly trims `opener_top_padding` 1.5 → 1.43 **with the shipped default tuning** (`chunk_route_generation_pipeline.gd:132`). | — |
| N9 | LOW | **Dead / duplicated code.** `_require_route_port_hold_ids` is never called (`route_path_validator.gd:300-305`). Graph `move_kind` (centre distance) disagrees with the reach check (edge gap) and is never read, nor is node `route_role` (`route_graph_builder.gd:60, 84, 96-97`). `_measure_gap_distance` / `_measure_downward_gap` are copy-pasted in the validator and graph builder. Validator defaults hard-code `0.12` / `0.96` from tuning. Anchor-builder lane-ratio defaults (0.28/0.82) differ from tuning (0.425/0.8). `route_validation_result` / `candidate_score` params of `build_layout` are always `null` / `0.0`. `_build_candidate_score`'s `-1.0` branch is unreachable. | various |
| N9b | LOW | **Typing.** Internal modules talk through `RefCounted` + `.call("populate")` / `.call("validate_layout")` / `.get()` / `.set()` instead of typed calls; untyped `Array` in `route_path_validator.gd:55,230,254`, `route_graph_builder.gd:45`; Variant loop var `for row_offset in [1, -1, 2, -2]` (`chunk_route_population_builder.gd:531`). Mixed tabs/spaces in several generation files. | pipeline, validator, population builder |
| N10 | LOW | Post-PRESSURE slot multipliers (Recovery +7, Pressure x0, Risk x0.2, Skill/Baseline x0.5) are hard-coded, not tuning. `route_profile_tuning.tres` overrides nothing, so all slot weights are script defaults. | `daily_chunk_generator.gd:384-389` |

---

## Part 2 — Gameplay issues

### A. Repetition / sameness

| # | Status | Current state |
|---|---|---|
| A1 | **OPEN** | Every chunk is still 11 rows / 12 m / ~0.985 m pitch. `generation_tuning.gd:16`, `chunk_route_generation_pipeline.gd:116` |
| A2 | PARTIAL `aed3949` | Still 8 base templates chosen by `(slot, band)`; a seeded rotation of the 8 interior rows gives up to 8 orderings of the same role set. `chunk_route_plan_builder.gd:87-111` |
| A3 | PARTIAL `aed3949` | Chunks 1–3 slot order is still fixed (BASELINE/SKILL/RECOVERY); their row order and BASELINE style now vary by seed. `daily_chunk_generator.gd:395-403` |
| A4 | **OPEN** | Movement style is still slot-determined except BASELINE's coin flip; `FORK` is never produced. `chunk_route_plan_builder.gd:55-78` |
| A5 | FIXED `fdc8fc8` | Branch path is seeded. `chunk_route_path_solver.gd:~327` |
| A6 | PARTIAL `fdc8fc8` | Merge row seeded; split row still fixed at 1 outside EASY. `chunk_route_plan_builder.gd:272-273` |
| A7 | FIXED `83491ee` (see N4) | Score is `-\|observed - target\|`, seeded pick within 0.05. Opener keeps the old metric. `daily_chunk_generator.gd:132-139, 207` |
| A8 | FIXED `26d8943` | Same lane three rows running → weight 0.05; previous lane x0.6; two-back x0.5. `chunk_route_path_solver.gd:254-259` |
| A9 | FIXED `30108a0` | 1 reward (2 in CHALLENGE), -1 on opener, seeded +1; no slot excluded. `chunk_route_population_builder.gd:381-388` |
| N6 | LOW (new) | **Rare hazard kinds.** `_select_hazard_kind` weights by `(n-i)²`: pendulum log 1/14 ≈ 7%, wandering critter 1/5 = 20%. Two of nine hazards are close to invisible. The same weighting is reused for handhold types. `chunk_route_population_builder.gd:618-635` |

### B. Difficulty fairness

| # | Status | Current state |
|---|---|---|
| B1 | **OPEN** | Static reach 0.96 m vs move cap 2.2 m; no limit on consecutive swing moves, no swing simulation. Only additions: 0.15 m jitter margin, body-width clearance. `route_validation_tuning.gd:5-17` |
| B2 | **OPEN** | Downdraft still on the safe-path crux hold, updraft on the safe-path CATCH hold, both force-release the grip. See N2, N3, N5. `chunk_route_population_builder.gd:576, 586` |
| B3 | **OPEN** | `max_downward_move_meters = 0.12` — still no catch hold below a target. `route_validation_tuning.gd:9` |
| B4 | FIXED `4557111`, **undercut by N3** | Colliding hazards are nudged ±1/±2 rows — but the last fallback stacks them anyway. |
| B5 | **OPEN** | Seam move still ≈2.15 m, 0.05 m under the 2.2 m cap. `chunk_route_generation_pipeline.gd:127-138` |
| N2 | MED (new) | **Hazard motion is never checked.** Falling rock spawns 0.6 m above its anchor and falls 1.8 m (180 px at 100 px/m) — about two rows, sweeping past its hold and roughly one row below. Pendulum log sways ±0.38 m and dips 0.18 m; critter roams ±0.7 m. Branch-denial anchors sit on the optional path's last outer row, so a rock near the split can fall into rows where the safe path uses that lane. The primary coin and the branch-denial hazard can share an anchor. Motion constants are in pixels and won't follow a `pixels_per_meter` change. Measured: 0 lethal sweeps over a safe-path hold in 2,250 chunks — branch rows keep the safe path on the far side — so this is a missing guard, not a live bug. `generated_hazard_spawn_adapter.gd:21-27`, `chunk_route_population_builder.gd:561-565` |
| N3 | MED (new) | **Nudge fallback stacks hazards and can move one onto the safe path.** Order: optional path → safe path → return the already-occupied anchor. A lethal kind is never pushed onto the safe path today only because branch denial is always the first intent placed. `chunk_route_population_builder.gd:504-521` |
| N5 | MED (new) | **5 of 6 hazard intents land on the safe path** (crux pressure, recovery lift, safe-route relief, traverse force without a branch, reward greed when the reward is on a safe row). Force hazards on the safe path release both hands. The design doc says "Hazards must not block the only safe path". `chunk_route_population_builder.gd:568-588`, `run_scene.gd:939` |

### C. Progression / stakes

| # | Status | Current state |
|---|---|---|
| C1 | FIXED `43a14e6`, **undercut by N4** | Continuous altitude bonus (0.15 / 100 m, cap 0.6). Also thins support holds above ~167 m. |
| C2 | FIXED `5037b27` | Chaser +0.35 m/s per 100 m above 50 m; the 5.0 m/s cap is reached around 1.2 km. `chaser_pacing_model.gd:66-68` |
| C3 | FIXED `5037b27` | Camping bonus fades to zero by ~193 m. `chaser_pacing_model.gd:53-54` |
| C4 | **OPEN** | `one_hand_seconds = 100.0` still disables the stamina pillar. `run_scene.tscn:119` |
| C5 | FIXED `ef873f0` | After PRESSURE, RECOVERY is boosted, not forced; BASELINE band PRESSURE weight 0.25. EASY still 0. |
| C6 | PARTIAL `43a14e6` | `target_difficulty_score` is now read by the selector. `target_support_score`, `max_sparse_row_streak` are still unread. |
| N4 | PARTIAL 2026-10-07 | **Difficulty was flat across bands.** Three causes: (1) the selector measured the validator's BFS path, which takes the fewest hops and skips rows, so every route read as ~0.8; (2) band targets (0.25 / 0.55 / 0.85+) sat outside the reachable range — a straight-up route alone scores ~0.45; (3) the solver's lane weights ignored the band. Fixes: the selector measures the designed safe path (`_observed_route_difficulty`); targets are 0.52 / 0.60 / 0.68 with smaller slot offsets and a quarter-weighted altitude bonus; the solver ranks moves by a band preference for short moves (EASY `(1-r)^3`, BASELINE `(1-r)^1.5`; the opener is exempt), applied before the anti-ladder rules, and a third same-lane row is effectively banned. A first version applied the preference after the anti-ladder floor and turned 75% of EASY chunks into 4+ row vertical ladders; that is fixed. Measured over 2,250 chunks, before → after: mean move EASY 1.60 → 1.38 m, BASELINE 1.57 → 1.43 m, CHALLENGE 1.58 → 1.56 m; moves past the 0.96 m edge-to-edge reach 71% → 48% / 68% → 54% / 70% → 68%; 4+ row ladders 1% → 0%. Still PARTIAL: at full lane width the shortest non-straight move is ~1.8 m, so EASY and BASELINE stay close. Narrower EASY lanes (half width) measured 1.20 m / 30% / worst 1.31 m with no ladders, but break the 65%-of-wall spread rule. Test: `test_safe_path_moves_get_longer_from_easy_to_challenge_band` (fails at full width: EASY 1.39 vs BASELINE 1.46 m). |

| N11 | MED (new) | **Coins sit under lethal hazards; the greed hazard misses them.** Measured: 172/172 falling rocks and 44/44 pendulum logs share their spot with a coin, while 0/395 bug swarms do. Branch denial and reward greed both resolve to the reward anchor; branch denial is placed first and keeps it, and the bug swarm is nudged away. Players see coins inside rocks and logs, and the swarm guards nothing. `chunk_route_population_builder.gd:561-573` |

### D. Reach / grab clarity

| # | Status | Current state |
|---|---|---|
| D1 | FIXED `f61c06c` | Aim preview uses the real 96 px detection radius. `run_scene.gd:776` |
| D2 | **OPEN** | Same as T3 — no "you were short" feedback. |
| D3 | FIXED `f61c06c` | Targeting score is `distance / alignment` with aim-direction alignment. `run_handhold_targeting_runtime.gd:38-43` |

---

## Part 3 — Doc drift

`docs/03-environment-procedural-generation.md` no longer matches the code:

- `:32`, `:267` — the "MVP hazard set" lists 4 kinds; the generator places 9.
- `:288` — downdrafts are "challenge-band skill only"; code uses them in SKILL at every band
  and in PRESSURE.
- `:281` — wind is listed for baseline / easy-skill chunks; code uses it in every band, and
  20% of the time it is a critter.
- `:372` — "Hazards must not block the only safe path" is violated (N5).
- `:378`, `:384-392` — candidate rejection and scoring are described as covering support,
  hazards, readability and novelty; code rejects on safe-path reachability and seam only and
  scores on mean hop vs target.
- `:92` — row step is tuned per archetype; every template is 11 rows with one derived step.
- `:320` — hazard density scales by band; it is fixed at 1–2 intents per slot.
- `:35`, `:81`, `:138-152` — still describe daily layouts; the seed is per-run.

## Part 4 — Test gaps

Existing generation tests cover determinism, caches, seams across 24 dates x 30 chunks, slot
distributions, hazard kinds per slot, support clearance, and the solver move envelope.
Missing:

- A test that each candidate gets its own seam result (would have caught N1).
- Hazard placement and motion envelopes vs safe-path holds (N2, N3, N5).
- Coin reachability, and the optional path's move envelope.
- Fuzzing over `DailySeedKey.current_run()` seeds; tests only use date seeds.
- That observed difficulty can reach each band's target (N4).
- Graceful handling of solver failure (N7) and of the nudge stacking fallback (N3).

---

## Part 5 — Recommendations (ranked)

Directional only — each is a change to plan separately.

1. ~~Seam cache (N1)~~ done. **Difficulty curve (N4)** partly done: decide between full-width
   EASY lanes (small curve) and narrower EASY lanes (clear curve, breaks the 65% spread rule).
   Also vary chunk entry/exit lanes: every chunk enters at x≈-0.8 and exits at x≈0, so every
   boundary is the same ~2.3 m hop — the hardest move in EASY (B5).
2. **Validate hazards and fix coin overlap (N11, N2, N3, N5, T8, B2).** Keep coins off lethal
   hazards and put the bug swarm on the coin. Feed hazard sockets and their motion envelopes
   into `RoutePathValidator`; reject a candidate where a lethal sweep crosses a safe-path
   hold; make the nudge fail the candidate instead of stacking; decide which force hazards
   are allowed on the safe path and update the design doc to match.
3. **Stop shipping wall gaps (T7, T6, N7, N8).** Escalate on failure (more attempts, then a
   known-safe fallback template flagged as such), count solver failures as failed attempts,
   and make validation fail loudly in release builds.
4. **Resolve the stamina question (C4)** and **raise `MISSED_GRIP_FALL` (T3/D2).**
5. **Variety (A1, A4, A6, N6).** Seed chunk height/row count, produce `FORK`, seed the split
   row, flatten the hazard-kind weighting so all nine hazards appear.
6. **Fairness (B1, B3, B5).** Cap consecutive swing moves, allow an occasional catch hold just
   below a crux target, add margin to the seam move.
7. **Housekeeping (N9, N9b, N10, C6) and doc drift (Part 3).**

## Part 6 — Open design questions

- **Is endurance (stamina) a gameplay pillar?** Still gated on `one_hand_seconds = 100.0`.
- **Which hazards may sit on the safe path?** Updraft and startle puff are arguably fine
  there; downdraft on the crux hold and wind on BASELINE safe rows force-release the grip on
  the only route.
- **What should "difficulty" measure?** Mean safe-path move length now separates the bands,
  but it ignores hazards, swing streaks and hold types.
- `DailySeedKey.from_utc_date` / `to_rng_seed` are test-only given the per-run seed — delete
  unless a daily-challenge mode is planned.
