# Route Generation Audit

Audit of the route/level generation algorithm (`src/gameplay/generation/` and everything that
feeds or consumes it), focused on making runs more fun. Priorities: repetition/sameness,
difficulty fairness, progression/stakes, reach/grab clarity.

The random per-run seed is **intentional** (endless, no shared daily challenge), so it is not
treated as a bug here.

Status: findings only — no changes applied.

---

## How generation works today

```
DailySeedKey.current_run()  ("generator_v5:run:<ticks>-<randi>")   <- only entropy source
  -> DailyChunkGenerator.build_chunk(seed, index)
      builds every predecessor 0..index (cached), each via a 3-candidate loop:
        ChunkRouteGenerationPipeline.build_layout    (run TWICE per candidate)
          1. ChunkRoutePlanBuilder       -> 11-row role template + branch contract + hazard intents
          2. RouteAnchorGraphBuilder     -> 5 lanes x 11 rows = 55 anchors, jittered
          3. ChunkRoutePathSolver        -> safe path (weighted per-row walk) + optional/branch path
          4. ChunkRoutePopulationBuilder -> path holds, support holds, 1 reward, hazards
          5. ChunkRouteLayoutEmitter     -> GeneratedChunkLayout
        RoutePathValidator.validate_layout  -> BFS over SAFE-PATH HOLDS ONLY to an exit port
        validate_chunk_seam(prev, candidate)
      keep the candidate with the HIGHEST candidate_score; if all 3 fail -> return null
```

Key invariants baked in: every chunk is exactly **11 rows / 12 m tall / ~0.985 m row pitch**.
Difficulty is a 3-step function of altitude: EASY `<50 m` (chunks 0–4), BASELINE `<100 m`
(5–8), CHALLENGE `9+`. Bootstrap chunks 1–3 are always BASELINE/SKILL/RECOVERY regardless of
seed.

---

## Part 1 — Technical issues

### Bugs / dead code

| # | Issue | Location |
|---|---|---|
| T1 | `_get_merge_row_index` — both `match` arms `return row_roles.size() - 2`. The CHALLENGE-specific merge row the structure implies does not exist. | `chunk_route_plan_builder.gd:245-250` |
| T2 | Public `get_route_slot_for_chunk` builds a **different seed** (`"<ver>:route_profile_preview"`) than real generation. Any UI/telemetry/test calling it reads a fiction — it does not match what the run built. | `daily_chunk_generator.gd:249-256` |
| T3 | `MISSED_GRIP_FALL` is defined, rescue-eligible, and has end-screen copy, but **is never raised**. Whiffed grabs fall off the bottom and get logged as `BOTTOM_SCREEN_FALL`. Any "cause of death" data is wrong. | `run_end_reason.gd:7`, `rescue_eligibility.gd:13`, `run_end_screen.gd:80` |
| T4 | `run_scene.tscn` inline `Resource_generation` sets 8 fields that **no longer exist** on `GenerationTuning` (`handhold_assignment_rules`, `ladder_hold_rows`, `zigzag_hold_rows`, …). Silently ignored. | `scenes/main/run_scene.tscn:119-131` |
| T5 | ~11 tuning knobs are validated (some test-poked) but **unused by the route-first pipeline**: `target_difficulty_score`, `target_support_score`, `max_sparse_row_streak`, `non_opener_row_base_height_meters`, `setup/crux/top_out_zone_upper_ratio`, `route_port_row_tolerance_meters`, `socket_count_per_chunk`, `pickup_socket_ratio`, `pickup_lateral_offset_meters`, `pickup/hazard_branch_side_alignment_meters`. Designers turning these see nothing happen. | `generation_tuning.gd`, `route_validation_tuning.gd`, `chunk_route_plan_builder.gd:276-326` |

### Robustness

| # | Issue | Detail |
|---|---|---|
| T6 | "Hard errors, no silent fallback" is **debug-only**. `Validation.require_condition` is `push_error` + `assert`; Godot strips `assert()` in exported builds. Every `_find_*_row` "role missing", `_select_allowed_handhold_type` "could not select", solver "no reachable lane", and every `assert_valid` becomes *log-and-continue-with-bad-state* in a shipped build. `validation.gd:4-9` |
| T7 | All-3-candidates-fail -> `build_chunk` returns `null` -> coordinator logs an error and **spawns nothing = a physical gap in the wall mid-climb**. Only 3 attempts, no escalation, run continues. `daily_chunk_generator.gd:75-77`, `generated_chunk_coordinator.gd:88-90` |
| T8 | **Hazards bypass validation entirely.** `RoutePathValidator` graphs only safe-path holds; it never sees hazard sockets. A hazard on the sole reachable crux hold, two stacked hazards, or a hazard on the entry hold cannot fail generation. `route_graph_builder.gd:42-66` |
| T9 | Seam validator applies **no downward-move limit** (`max_downward_move_meters` 0.12) even though intra-chunk edges do. A chunk exit slightly above the next entry passes the seam when the equivalent in-chunk move would be rejected. `route_path_validator.gd:141-166` |
| T10 | **Two hashers.** `RouteAnchorGraphBuilder` uses a hand-rolled FNV-1a (version-stable); everything else — plan style, branch side, safe-path lane walk, handhold types, hazard kinds, route-slot RNG seed — uses Godot `String.hash()`, which is **not contractually stable across Godot versions**. A Godot upgrade can silently reshuffle every route while the jitter stays put. `route_anchor_graph_builder.gd:153-159` |
| T11 | `_chunk_layout_cache` / `_route_slot_cache` are **never evicted** — unbounded growth over a long run. `_chunk_seam_cache` key includes `get_instance_id()` of freed layouts; ids are recycled after `free()` -> theoretical stale hit. `daily_chunk_generator.gd:33-35` |

### Performance

| # | Issue | Detail |
|---|---|---|
| T12 | `_ensure_chunk` runs the **full generator synchronously on the main thread** at every 12 m boundary: 3 candidates x (plan + graph + solve + populate + emit) **run twice each** (preliminary for validation, then final with result embedded) + seam validation. Potential frame spike every chunk. First `build_chunk(N)` also builds all predecessors `0..N`. Node count itself (~120 live) is fine. `daily_chunk_generator.gd:52-80`, `chunk_route_generation_pipeline.gd:98,110` |

---

## Part 2 — Gameplay issues

### A. Repetition / sameness

| # | Issue |
|---|---|
| A1 | **Fixed macro-structure.** Every chunk = 11 rows, 12 m, ~0.985 m pitch, forever. No variation in chunk length, row count, or vertical rhythm anywhere in a run. `chunk_route_generation_pipeline.gd:106-119` |
| A2 | **~7 role templates total,** chosen purely by `(slot, band)`. Two chunks with the same slot+band get an **identical** 11-row role sequence; the only differences are the lane walk, handhold types, and <=0.08 m / <=0.2 m jitter. `chunk_route_plan_builder.gd:95-219` |
| A3 | **Bootstrap chunks 1–3 are seed-independent** (BASELINE/SKILL/RECOVERY). Combined with A1–A2 and A4, the **first ~48 m of every run is structurally identical.** `daily_chunk_generator.gd:297-307` |
| A4 | **Movement style is a pure function of slot** for 5 of 6 slots; only BASELINE flips LADDER/ZIGZAG on a coin-flip. `FORK` style is defined but **never produced.** `chunk_route_plan_builder.gd:55-78` |
| A5 | **Optional/branch path is unseeded** — a fixed inner/outer alternation. Every branch of a given side+span is byte-identical; branch chunks in a band feel the same. `chunk_route_path_solver.gd:290-318` |
| A6 | **Branch chunks are mostly on-rails.** With `split_row_index = 1` (non-EASY) and `merge = row_count-2`, only the middle rows have free lane choice; rows 0–1 and merge–10 are forced. `chunk_route_path_solver.gd:153-163` |
| A7 | **Candidate scoring rewards the gentlest route.** `score = max_move - largest_move_on_path`, and the selector keeps the **maximum**. Of 3 rolls, the least-committing wins every time — a built-in difficulty suppressor *and* variety killer. `daily_chunk_generator.gd:121-133, 71-73` |
| A8 | **Weak anti-ladder pressure.** Only a `x0.5` weight penalty for matching the lane from *two* rows back; a lane repeated only 1 row back is unpenalized. A run of SUPPORT rows can still hash into a dead-straight vertical ladder. `chunk_route_path_solver.gd:250-251` |
| A9 | **Rewards** never appear on OPENER or BASELINE slots, and there is **at most one per chunk.** Long stretches with nothing to chase off-route. `chunk_route_population_builder.gd:349-350` |

### B. Difficulty fairness

| # | Issue |
|---|---|
| B1 | **The "safe path" guarantee is graph connectivity, not physical achievability.** Player static grab radius = **0.96 m**, but generation routinely emits ~1.97 m lane-change moves and ~2.15 m seam moves, up to a 2.2 m cap. Everything past 0.96 m is a dynamic swing/lunge the generator **never simulates** — no stamina model, no swing physics, no seconds-per-move budget, no limit on consecutive swing moves. Whether these routes are fair rests entirely on swing feel with no corresponding check. `route_graph_builder.gd:68-108`, `route_validation_tuning.gd:5-9` |
| B2 | **Forced-path hazards are never validated and stack an unmodelled multiplier on the lowest-margin move.** `CRUX_PRESSURE` -> DOWNDRAFT placed *directly on* the safe-path crux hold, positioned in the swing corridor, and contact **force-releases both hands**. `RECOVERY_LIFT` -> UPDRAFT on the safe-path CATCH hold. The route grader can't see any of it. `chunk_route_population_builder.gd:436-449`, `chunk_route_layout_emitter.gd:184-208` |
| B3 | **No safety net for overshoots.** `max_downward_move_meters = 0.12` means there is essentially never a catch hold below a target. A swing that overshoots slightly and lands below the intended hold has nothing to grab -> fall. `route_validation_tuning.gd:9` |
| B4 | **No hazard<->hazard or hazard<->path spacing.** Multiple intents can resolve to the same anchor (e.g. PRESSURE slot's `[CRUX_PRESSURE, OPTIONAL_BRANCH_DENIAL]`), stacking two hazards on one hold with no dedup. `chunk_route_population_builder.gd:367-399` |
| B5 | **Every chunk seam is a ~2.15 m move, right at the 2.2 m cap, every 12 m,** validated geometrically only. Deliberately tuned to "just inside the envelope" — no margin for a bad jitter roll or a tired player. `chunk_route_generation_pipeline.gd:121-129` |

### C. Progression / stakes

| # | Issue |
|---|---|
| C1 | **Difficulty is a 3-step function that caps at 100 m.** After chunk 9 nothing changes — same target scores, same hold pools, same separation minimums, forever. An endless climber with a finite difficulty ceiling. `daily_chunk_generator.gd:238-247` |
| C2 | **The chaser never scales with altitude** and never exceeds ~1.0 m/s in practice (`max_rise_speed = 5.0` is unreachable — nothing adds beyond `+0.5`). It only reacts to the player's own last-5 s progress. `chaser_pacing_model.gd:31-58` |
| C3 | **The chaser speeds up when you're already struggling.** Slow progress -> CAMPING -> chaser rises to 1.0 m/s. A hard chunk that slows the player also *accelerates the threat*. Difficulty and punishment compound instead of the pacing compensating. `chaser_pacing_model.gd:34-48` |
| C4 | **The stamina/grip pillar is inert in the shipped scene.** `run_scene.tscn` overrides `one_hand_seconds` to **100.0** (default 8.0). At 100 s the BURN (1.35x) and greasy (3x) drain multipliers are meaningless, and the generator's careful placement of BURN holds on CRUX rows buys an endurance cost that doesn't exist. Either the endurance design isn't in effect, or 8.0 is the real target and 100.0 is debug debt. `scenes/main/run_scene.tscn:117`, `stamina_runtime.gd:34-47` |
| C5 | **Pressure rhythm is fixed and CHALLENGE-only.** PRESSURE is asserted to zero weight in EASY/BASELINE, and every PRESSURE chunk is always followed by a forced RECOVERY. Predictable pressure->relief cadence high on the wall, no pressure at all low on it. `route_profile_tuning.gd:79-80`, `daily_chunk_generator.gd:284-286` |
| C6 | **The knobs meant to shape the curve are dead.** `target_difficulty_score` (0.25/0.55/0.85), `target_support_score`, `max_sparse_row_streak` are computed and stored on the plan and **never read** by the solver or population builder. The difficulty curve is entirely implicit in role templates + hold-type pools. |

### D. Reach / grab clarity

| # | Issue |
|---|---|
| D1 | **The aim preview overstates the real grab radius.** The preview line is `max(160, 96 x 1.75) = 168 px`; the actual grab happens within **96 px**. Players are taught the wrong distance and will whiff moves that looked in range. `run_scene.gd:763` |
| D2 | **`MISSED_GRIP_FALL` never fires** (see T3) — a whiffed grab and a genuine fall-off-the-bottom look the same to the player and to analytics. No feedback that says "you were short." |
| D3 | **Grab is pure nearest-distance, no directionality.** `run_handhold_targeting_runtime.gd:28-29` picks the closest hold in radius regardless of whether it's above, below, or behind the intended move. Combined with the monotonic-up layout, an overshoot can grab a hold you didn't mean to and break your rhythm. |

---

## Part 3 — Recommendations (ranked by fun-per-effort)

Directional only — each is a design change, not a step-by-step plan.

1. **Fix the candidate selector (A7).** It currently optimizes for *least* spice. Score candidates on a target difficulty *band* (closest-to-target, not smallest-move), or just keep a seeded random pick among the 3 valid ones. Biggest single lever for both variety and challenge, tiny change.
2. **Vary the macro-structure (A1–A2).** Let `segment_height_meters` / row count vary per chunk (seeded), and add 2–3x more role templates per `(slot, band)` with a seeded pick. Kills the "every chunk is 11 rows" feel.
3. **Seed the branch path and de-rail branch chunks (A5–A6).** Give the optional path a seeded lane walk like the safe path, and widen the free-choice window (`split_row_index` earlier, `merge` later).
4. **Break the identical opening (A3).** Seed the bootstrap slots, or at least seed their templates/styles, so the first 48 m differs run to run.
5. **Add a real difficulty ramp past 100 m (C1).** Make target difficulty a continuous function of altitude (or add CHALLENGE sub-tiers) so an endless run keeps escalating.
6. **Make the chaser a real progression axis (C2–C3).** Add a slow altitude-based speed term, and stop the camping bonus from punishing players who are slow *because the route is hard* (e.g. cap the camping bonus when local route difficulty is high, or base "camping" on stationary time not distance).
7. **Validate hazards (B2, B4, T8).** Feed hazard sockets into `RoutePathValidator`: reject a hazard on the sole reachable hold of a row, dedupe stacked hazards, enforce minimum hazard<->hazard and hazard<->forced-hold spacing.
8. **Add physical-achievability to validation (B1, B3).** Cap consecutive `SWING_REACH` edges on the safe path, and/or add a cheap swing-cost budget per chunk. Add occasional catch holds slightly below crux targets so a small overshoot is recoverable.
9. **Resolve the stamina question (C4).** Decide whether endurance pressure is a pillar. If yes, set `one_hand_seconds` back toward 8–20 and tune around it; if no, delete the BURN/greasy multiplier machinery.
10. **Fix grab feedback (D1–D3).** Match the aim preview to the real 96 px radius, raise `MISSED_GRIP_FALL` on a grip press with a target just outside radius, and bias grab target selection toward the aim direction.
11. **Housekeeping (T1, T2, T4, T5, T10, T11).** Delete dead `merge_row_index` arm; align `get_route_slot_for_chunk` seed with real generation or drop the method; strip the 8 phantom `.tscn` fields and the dead tuning knobs; pick one hasher (the FNV-1a) for all seeded decisions to survive Godot upgrades; cap or evict the caches.

---

## Part 4 — Open design questions

- **Is endurance (stamina) a gameplay pillar?** The shipped `one_hand_seconds = 100.0` says no; the handhold catalog and BURN placement say yes. This decision gates recommendation 9 and roughly a third of the config surface.
- **Should difficulty be authored (bands/templates) or parametric (continuous target score)?** The dead `target_difficulty_score` machinery suggests parametric was intended but abandoned. Picking one determines whether recommendations 1, 5, and C6 are "wire up the existing knobs" or "delete them."
- **How committing should moves be by default?** The 0.96 m static reach vs. 2.2 m move cap gap means the game is *already* a swing game, but nothing acknowledges or tunes that. Worth an explicit call on the intended ratio.
- `DailySeedKey.from_utc_date` / `to_rng_seed` are now test-only dead code given the intentional random seed — safe to delete unless a daily-challenge mode is on the roadmap.
