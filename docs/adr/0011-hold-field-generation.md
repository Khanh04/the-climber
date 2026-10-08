# ADR 0011: Hold-Field Generation On A 14 m Wall

## Status

Accepted. Supersedes [ADR 0005](0005-route-graph-bouldering-validation.md),
[ADR 0006](0006-route-first-generation-rewrite.md) and
[ADR 0009](0009-reachability-driven-path-solver.md).

## Context

The route-first generator (ADR 0006/0009) planned one safe line per chunk on a
fixed 11-row x 5-lane grid, then decorated around it. Measured over 2,250
chunks (`docs/route-generation-audit.md`):

- The route used ~3.4 m of an 8 m wall; off-route holds were filler.
- Any lane change was at least 1.8 m, so EASY and BASELINE played the same.
- Every chunk entered at x ≈ -0.8 m and exited at x = 0, so every 12 m the
  climb repeated the same 2.3 m seam hop.
- Above 100 m the slot scheduler alternated RISK/PRESSURE with RECOVERY and
  every chunk had the same zigzag-plus-side-branch silhouette.
- Force hazards always sat on the single line; lethal ones always sat on the
  branch, on a coin.

The product goal is a wider wall with several real routes and less
repetition.

## Decision

Replace the generator internals with a **hold field validated as a route
graph**, on a **14 m wall wider than the 9 m screen**, with the camera panning
sideways.

1. **Corridors.** Four route corridors wander up the wall. Each corridor's
   centre is a smooth function of world height seeded from the run seed only
   (`HoldFieldSampler.corridor_positions`), so corridors continue across chunk
   seams regardless of which candidate a chunk picks. Neighbours are pushed
   apart to at least 2.6 m. In every 36 m stretch exactly one seeded corridor
   fades out for 6–12 m, forcing a traverse while keeping the others intact.
   Chunk 0 starts the corridors near the two starter holds and fans them out
   by 6 m.
2. **Hold field.** Blue-noise holds are sampled along the corridors, plus a
   sparse scatter between them for traverses. The previous chunk's top 2.4 m
   (its seam band) is a fixed spacing anchor and the route source, so a seam is
   just more wall; there are no fixed entry or exit lanes.
3. **Reach graph.** `HoldReachGraph` links holds whose edge-to-edge gap fits
   the 2.2 m move envelope with at most 0.12 m of downward travel. Difficulty
   is the **bottleneck**: the longest move on the easiest route.
4. **Choice.** A chunk must offer K distinct routes from the seam band to its
   own seam band, each within the band's move limit (`BandFieldProfile`
   `max_route_move_meters`). Routes are searched along each corridor first,
   then the easiest route overall, then an open search. A route counts only
   when it stays on average at least 1.75 m from every counted route, so two
   routes may share a junction but not run side by side. K is 3 in EASY and
   BASELINE, 2 in CHALLENGE.
5. **Repair.** When a chunk is short of routes, every corridor without a
   climbable path gets holds added in the middle of its too-long moves
   (sidestepping holds that belong to other corridors), or a spine of holds up
   its centre when it has no path at all. Repair may place holds down into the
   previous chunk's seam band. Unreachable holds are pruned.
6. **Pruning.** Once K routes are found, holds no route needs are removed. The easiest
   route keeps every hold. Alternative routes keep only the holds they need within the
   band's move limit (greedy farthest jump along the route). Each route is continued up
   into the top 1.2 m, and every hold there stays, since the next chunk grows from them.
   `extra_hold_keep_ratio` (default 0) can keep a share of the other holds, links between
   two routes first. Any kept hold also keeps the chain that connects it to the sources
   through the fewest dropped holds. Routes are recounted afterwards; a candidate that lost
   one fails like any other.
7. **Decoration.** The easiest route only uses the band's safe hold types.
   Lethal hazards may cover holds only if the chunk still offers K-1 routes
   without them, never a route source, never a coin. Force hazards land on the
   easiest route only some of the time. Coins sit on holds off the easiest
   route; bug swarms sit next to coins.
8. **Candidates and failure.** Up to three candidates per chunk; the first
   whose bottleneck is within 0.2 m of the band's target is kept. If none is
   valid, one relaxed attempt (EASY field, no hazards, one route fewer) runs
   through the same validation and logs a warning. A chunk that still fails is
   a hard error. Measured over 6,000 chunks: 0 hard failures, relaxed attempt
   ~0.1% (after pruning).
9. **Runtime.** `generation_tuning.chunk_width_meters` is 14.
   `camera_horizontal_travel_limit_pixels` is 250 (the screen edge reaches the
   wall edge). The chaser kill zone spans the wall width, centred on the wall,
   instead of the visible width around the camera.

The public seam is unchanged: `DailyChunkGenerator.build_chunk(seed, index)`
returns a `GeneratedChunkLayout`. `safe_path_hold_ids` is the easiest route;
`route_slot` is OPENER for chunk 0 and BASELINE otherwise; `chunk_type` is
FORK when a chunk offers three or more routes, otherwise SPARSE_REACH. The
generator version is `generator_v6`.

## Consequences

- Measured (6,000 chunks, after pruning): holds span ~12 m of the 14 m wall;
  easiest-route longest move median 1.17 / 1.41 / 1.60 m (EASY / BASELINE /
  CHALLENGE); swing share on the easiest route 1% / 40% / 76%; holds per chunk
  ~48 / 38 / 28 (~80 / 59 / 47 before pruning); relaxed fallback ~0.1%. Three EASY
  routes of ~13 holds each put the floor near 40 holds; going lower means fewer routes
  or longer moves.
- Deleted: the plan builder, anchor graph, lane solver, population builder,
  layout emitter, route graph/validator, the slot scheduler and
  `route_profile_tuning`, and their tests. New: `hold_field_sampler.gd`,
  `hold_reach_graph.gd`, `field_chunk_pipeline.gd`, `field_chunk_decorator.gd`,
  `band_field_profile.gd` + three `.tres` profiles.
- Generation still runs synchronously on the main thread at chunk boundaries:
  ~5–10 ms median per chunk on desktop, p95 ~25 ms. Moving it to a worker
  thread is a follow-up if mobile frame spikes show up.
- EASY's easiest route almost never needs a swing (longest move ~1.2 m against
  a 1.3 m limit). The easiest route often climbs one corridor fairly straight;
  the field around it offers alternatives.
- Measurement harness: `tools/generation/` (headless dump, analysis, viewer).
