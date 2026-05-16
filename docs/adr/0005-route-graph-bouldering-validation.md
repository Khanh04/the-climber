# ADR 0005: Route Graph Bouldering Validation

## Status

Proposed

## Context

Module 3 no longer needs only deterministic lane rows. The generator
must evolve toward a route-setter model where each chunk reads as a
short bouldering problem with a safe path, optional risky beta,
validated seams, and deterministic retry behavior. The current row
generator can already produce typed handholds, pickups, hazards, and
deterministic chunk snapshots, but without a locked contract the next
steps risk mixing movement difficulty, danger, hazard pressure,
profile pacing, and retry behavior into one opaque score.

The route system must preserve:

- deterministic output from UTC seed plus generator version,
- build-order independence for chunk generation,
- fail-fast behavior when no valid candidate exists,
- mobile-friendly bounded candidate search, and
- a clear separation between movement solvability and game danger.

## Decision

- Represent each generated chunk as a small directed route graph.
  Handholds are route nodes, validated movement options are directed
  edges, and the accepted path is a typed entry-to-exit path through
  the chunk.
- Keep the first validation slice conservative and static-first.
  Safe-path validation starts with reachability, downward-drop limits,
  route entry anchors, and explicit entry/exit ports. Dynamic moves,
  force-hazard launches, and BOOST-specific connectors only count when
  expressed as explicit move kinds in later slices.
- Separate difficulty from danger.
  Movement difficulty is derived from reach, lateral displacement,
  sequence intensity, hold type, and stamina pressure. Danger is
  derived from hazards, Chaser pressure, fall exposure, and stamina
  punishment. A layout is not allowed to hide an unreadable route
  behind a “high score” that mixes both.
- Keep seam validation pairwise and deterministic.
  `build_chunk(seed, index)` produces the same layout and the same
  route ports regardless of runtime spawn timing. Adjacent seam checks
  evaluate chunk pairs after both layouts exist and must not mutate
  either layout.
- Use bounded deterministic candidate search.
  The generator may produce multiple candidates for a seed/index pair,
  but the retry budget is finite, deterministic, and part of typed
  validation tuning. During development, no valid candidate is a hard
  error with seed, chunk index, and validation diagnostics.
- Keep route validation and profile scheduling behind typed tuning
  resources referenced from `GenerationTuning`.
  `RouteValidationTuning` owns reach envelopes, conservative movement
  bounds, route-port tolerance, entry anchors, role-zone boundaries,
  and retry budget. `RouteProfileTuning` owns weighted macro pacing
  parameters for baseline, skill, recovery, risk, and pressure.
- Preserve current compatibility labels.
  Existing `ChunkRouteSlot` values remain valid debug and compatibility
  labels even after profile scheduling becomes the main pacing model.

## Consequences

- The generator can be evolved in slices: validate the current chunk
  layouts first, then add roles, weighted profiles, scored candidate
  selection, and finally bouldering-aware placement.
- Route analysis becomes inspectable in tests and debug metadata
  without forcing the runtime scenes to own generation rules.
- Retry budgets and route envelopes become tunable without reopening
  `DailyChunkGenerator` internals.
- Because safe-path validation is intentionally conservative in the
  first slice, some currently playable routes may still be rejected
  until explicit dynamic connectors and richer graph semantics are
  added.

## MVP Scope And Exclusions

- MVP safe-path validation uses conservative static reach with bounded
  downward movement and explicit route ports.
- MVP does not add server-authoritative replays, leaderboard anti-cheat,
  or spawn-order-dependent generation.
- MVP does not silently downgrade to unrelated easier content when all
  candidates fail validation.
- MVP may keep current chunk archetypes as placement templates while
  moving rule ownership into typed graph, role, and profile systems.

## Follow-Up Work

- Add typed route models: roles, move kinds, route nodes, edges,
  graph, paths, and ports.
- Add `RouteGraphBuilder` and migrate `RoutePathValidator` onto that
  graph contract.
- Replace flat chunk-type selection with weighted route profiles using
  `RouteProfileTuning`.
- Refactor placement, reward anchoring, and hazard shaping around
  route roles instead of raw row order.
- Bump the generator version when the accepted candidate set changes
  enough to alter shipped daily layouts.