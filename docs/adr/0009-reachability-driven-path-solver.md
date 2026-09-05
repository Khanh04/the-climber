# ADR 0009: Reachability-Driven Path Solver

## Status

Accepted

## Context

`ChunkRoutePathSolver` picked each row's lane from a fixed, per-movement-style
modulo pattern (e.g. inner -> outer -> inner -> center, repeating every 8
rows for LADDER/ZIGZAG), independent of the anchor graph's actual world-space
distances or of the row's row-role purpose (CRUX/CATCH/DECISION/...).
Reachability was checked only afterward, by a completely separate graph
(`RouteGraphBuilder` + `RoutePathValidator`) rebuilt from the emitted layout;
a failure there triggered `DailyChunkGenerator` to reroll the whole chunk with
a new RNG salt. Two independent representations of the same holds, connected
only by regenerate-and-pray, produced a path whose shape repeated near-
identically chunk to chunk (modulo left/right mirroring) and never reflected
what a row was actually for.

Separately, the reachability check had no notion of the player's collision
footprint, so nothing stopped two holds from sitting close enough in world
space that a swing between them would clip the wall or an adjacent hold.

## Decision

Replace the fixed lane-pattern functions with a deterministic weighted walk.
For each row, the walk filters the anchor graph's lane candidates down to
those actually within reach (real `Vector2` distance <=
`RouteValidationTuning.max_move_distance_meters`) of the previous row's
chosen anchor. Staying on the same lane is always a valid candidate (a pure
vertical move), so the walk can never produce an unreachable row --
reachability is a generation-time filter, not a post-hoc pass/fail gate.

A lateral move to a *different* lane must also clear
`RouteValidationTuning.player_body_width_meters` (new field, sourced from the
player's collision footprint in `scenes/player/player_character.tscn`), so a
swing is never a near-miss squeeze past the wall. This same clearance value
now also excludes support-hold candidates from a row's swing envelope around
its path anchor (`ChunkRoutePopulationBuilder`).

Among whatever survives those filters, a deterministic hash-weighted pick
selects the lane, weighted by the row's purpose: CRUX/PRESSURE rows favor
bigger, more committing moves; CATCH rows favor a short rest move;
DECISION/TRAVERSE rows favor lateral movement; SUPPORT/TOP_OUT rows lean
mildly lateral (to keep the wall's width in use across chunks made mostly of
that role, e.g. openers) with a repetition penalty against the lane two rows
back. Row purpose finally drives lane shape, not just hold type and support
density.

The optional (branch) path keeps its original deterministic alternating
pattern unchanged: it has a hard downstream requirement (at least one
outer-lane row, or hazard/reward anchor lookup fails) that the fixed pattern
already guarantees by construction, and the new safe-path walk stays
restricted to the lane pool on the side opposite the branch throughout the
branch span -- the two paths are drawn from disjoint lane pools and can never
collide, without needing a runtime separation check.

One case has no "stay on this lane" fallback and is handled by direct
assignment rather than filtering: the first row leaving the fixed CENTER
split pivot for the branch side always takes the inner lane on that side (the
same conservative choice the old pattern always made there), since a wide
outer lane's reachability from a jittered CENTER anchor isn't reliably
provable and doesn't need to be.

Everything else that made a chunk valid is unchanged: `RouteAnchorGraphBuilder`'s
lane fan-out and jitter geometry, the post-hoc `RoutePathValidator`/
`RouteGraphBuilder` layout check, and `DailyChunkGenerator`'s
candidate-attempt retry loop all stay in place as the existing safety net for
jitter-caused seam or connectivity edge cases -- the walk's own guarantee
covers consecutive-row reachability along the path it builds, not every
possible edge in the final emitted layout.

Alongside the rewrite, dead machinery uncovered next to it was deleted:
`GenerationTuning`'s legacy `ChunkType`-keyed hold-row template arrays and
row-step fields (referenced only by their own test, never by the live
pipeline), and the `HandholdAssignmentRule` engine (`handhold_assignment_rule.gd`,
`handhold_row_zone.gd`, `handhold_assignment_rule_catalog.gd`/`.tres`) --
also never called by the live pipeline, which already selects handhold types
directly in `ChunkRoutePlanBuilder`/`ChunkRoutePopulationBuilder`. The 9
near-duplicate `_get_*_support_lane(s)` functions in
`ChunkRoutePopulationBuilder` (one per movement-style/row-role combination)
were collapsed into one function that picks non-path lanes by proximity to
the path (mirror lane first, then closest to center), capped by a row-
purpose/difficulty-band count.

## Consequences

- Path shape now varies by seed (`tests/unit/test_chunk_route_path_solver.gd:test_safe_path_lane_choice_varies_with_seed`)
  and is guaranteed reachable and swing-clear on every consecutive pair of
  rows for every route slot and difficulty band
  (`test_safe_path_moves_stay_within_the_move_envelope_across_many_seeds_and_slots`).
- `RouteMovementStyle` no longer drives lane selection at all; it remains
  live only as the whole-chunk archetype used for route-slot pacing
  (`DailyChunkGenerator`) and the cosmetic `ChunkType` label
  (`ChunkRouteLayoutEmitter`). Collapsing that enum, `RouteRowRole`, and
  `RouteRole` into fewer taxonomies was considered and deliberately deferred:
  each is genuinely load-bearing for a distinct purpose (row-level path
  shaping, per-hold assigned semantics, hazard/reward row lookup), and
  merging them is a separately-scoped, higher-risk change.
- Support-hold placement no longer varies by movement style; it now varies
  by row purpose and difficulty band plus proximity to the actual (now
  variable) path lane, which is a behavior change from the old fixed
  per-style lane tables -- tests that asserted specific old lane choices
  were rewritten to assert the general contract (no collision with the
  path, swing clearance kept, fewer/no support on crux/pressure/traverse
  rows) instead.
