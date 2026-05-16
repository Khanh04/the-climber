# ADR 0006: Route-First Generation Rewrite

## Status

Accepted

## Context

The current daily chunk generator is stable and deterministic, but it is
too template-driven. Chunk rows are stamped from fixed lane arrays, route
roles are assigned after geometry is placed, and validation metadata can
exist without becoming a hard acceptance gate. This makes beginner chunks
feel sparse when rows contain only one or two useful holds, while
branchable chunks can visually collapse back toward the center instead of
creating a sustained horizontal choice.

The MVP route model now needs beginner-friendly support cadence,
validated safe paths, meaningful optional branches, horizontal traverse
pressure, hazards that express route intent, and deterministic difficulty
growth with altitude.

## Decision

Rewrite generated chunk creation as a route-first constrained search.
The generator will plan route intent before handhold geometry, then solve
and score candidate paths on a layered lane graph.

The new generation pipeline is:

1. Use a deterministic tower scheduler with memory to choose route slot,
   movement style, recovery pressure, recent hazard pressure, and branch
   side bias.
2. Build a typed `ChunkRoutePlan` that defines row roles, safe-route
   requirements, optional-route requirements, split and merge rows,
   horizontal traversal targets, sparse-row limits, hazard intents, and
   allowed handhold-type pressure.
3. Build a five-lane layered anchor graph for the chunk, using authored
   row-step tuning for vertical cadence and a center lane for readable
   beginner routes.
4. Solve for a mandatory safe path from entry to exit.
5. Solve for a distinct optional path when the plan is branchable. The
   optional path must satisfy minimum branch separation and outer-lane
   occupancy, so branch chunks traverse horizontally instead of clumping
   in the middle.
6. Populate support, bailout, catch, reward, and recovery holds around
   the solved paths according to row role and difficulty band.
7. Assign handhold types after path solving. `NORMAL` and `REST` remain
   beginner-safe; `BURN`, `BREAK`, and `BOOST` express crux, pressure,
   fast-branch, or connector intent according to route role and band.
8. Place hazards from typed hazard intents rather than raw side filters.
   Spikes deny risky or reward branches, wind shapes lateral traverses,
   downdrafts add challenge pressure, and updrafts provide recovery or
   connector support.
9. Reject invalid candidates and choose the highest-scoring accepted
   candidate from a deterministic budget. No invalid fallback layout is
   acceptable.

## Consequences

- Chunk types become movement styles and no longer own complete row
  templates.
- Difficulty is based on path features: move gap, lateral severity,
  sparse-row streaks, support cadence, catch rows, hazard exposure, and
  hold-type pressure.
- Easy chunks can be denser without becoming boring because extra holds
  are typed as support, bailout, recovery, or optional rewards rather
  than all being part of the optimal route.
- Branchable chunks must prove a second route with real horizontal
  separation before being accepted.
- Hazard and pickup placement becomes route-intent-driven, improving
  readability and reducing background noise.
- Existing runtime-facing generated socket models may remain if they
  continue to fit spawning needs, but the old template generator internals
  are replaced rather than migrated incrementally.

## Validation

Initial tests must cover:

- route-plan validation and fail-fast constraints;
- five-lane lane semantics and outer-lane detection;
- easy-band support cadence and beginner-safe hold-type policy;
- branchable chunks requiring optional paths, split/merge rows, branch
  separation, and outer-lane occupancy;
- pressure and risk plans producing hazard intents that match route
  roles;
- challenge plans permitting higher-pressure hold types without leaking
  them into onboarding-safe paths.