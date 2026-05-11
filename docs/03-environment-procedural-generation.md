# Module 3: Environment and Procedural Generation

## Owner

Level Designer / Systems Programmer

## Goal

Generate a daily-shared tower layout with enough variation and hazard interaction to support replayability, friend ghosts, and social comparison without requiring MVP leaderboards.

## MVP Scope

- UTC daily seed, generator version, deterministic hold placement, basic hazard placement, and normal coin placement.
- Use daily layouts for shared challenge and future friend ghosts, not for server-authoritative score validation.
- Keep the first generator simple enough to debug by altitude segment.

## Core Requirements

### Daily Seed Generation

- All players share the same global layout for each 24-hour period.
- Seed generation is based on the full UTC date rather than day-of-month only.
- Recommended key format: `generator_v1:YYYY-MM-DD` using UTC.
- Use a dedicated `RandomNumberGenerator` instance for daily generation rather than relying on global RNG state.
- Include a generator version in the seed key so future layout changes do not corrupt old ghost or replay data.
- The seed drives ledge placement, hazard placement, and coin placement.
- The same seed should allow friends to compare routes and death locations on identical layouts.

### Interactive Sandbox Hazards

#### Crumbling Ledges

- Implement as `StaticBody2D`-based holds.
- On grip, start a 2-second destruction timer.
- Play a destruction animation before the ledge becomes unavailable.

#### Elastic Vines

- Build from chained `PinJoint2D` segments.
- The vines should produce bounce, sway, and possible tangling behavior.

#### High Winds

- Use `Area2D` zones.
- Apply a constant force to the ragdoll while inside the zone.

#### Greasy Ledges

- Use low-friction surface behavior.
- Grip stamina drains three times faster on these nodes.
- The player should physically slide more easily while attached.

## Implementation Notes

### Deterministic Generation

- Keep generation order stable so content placement remains reproducible from the same seed.
- Avoid mixing non-deterministic runtime events into layout generation.
- Separate layout generation from runtime hazard state so daily layout sharing remains predictable.
- Exact physics replay validation is not an MVP requirement.

### Content Buckets

- Consider splitting generation into placement passes for holds, hazards, and pickups.
- Tag spawned content with source seed metadata for debugging and ghost placement.
- Segment generation by altitude bands so difficulty, hazard density, and coin risk can scale predictably.

### Hazard Interactions

- Hazards should modify the existing grip and physics systems rather than inventing parallel rules.
- Greasy ledges should hook into the stamina drain model already used by core movement.
- Wind zones should apply force through the physics model rather than scripted teleports.

## Post-MVP

- Elastic vines after core holds, crumbling ledges, and greasy ledges are stable.
- Friend ghost overlays and fall sprays associated with the UTC seed and generator version.
- Generator migrations that preserve old ghost data when content rules change.

## Open Questions

- What altitude band size should generation use for difficulty scaling?
- Which hazards are MVP: crumbling ledges and greasy ledges only, or winds as well?
- How many generated objects can remain active on mobile before pooling/despawning is required?

## Risks

- Generator changes can invalidate ghost data unless the seed includes a generator version.
- UTC rollover can confuse players if the UI does not clearly show daily reset timing.
- Tangling vines can produce unstable collision or joint behavior without careful limits.

## Suggested First Tasks

1. Define the deterministic generation pipeline.
2. Implement seeded ledge and coin placement.
3. Add each hazard type behind a shared spawn interface.
4. Build debugging tools for displaying the active seed and generated content.
5. Validate UTC daily rollover and generator-version compatibility.