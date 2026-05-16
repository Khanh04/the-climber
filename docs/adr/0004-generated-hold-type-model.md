# ADR 0004: Generated Hold Type Model

## Status

Proposed

## Context

Module 3 currently generates handhold geometry and only carries a
stamina drain multiplier through `GeneratedHandholdSocket`. The scene
builder materializes handholds as raw `StaticBody2D` nodes with node
metadata. That is sufficient for neutral holds, but it does not scale
cleanly to planned arcade handhold variants such as `BREAK`, `BOOST`,
`BATTERY`, `BUBBLE`, `ZIP`, or linked holds such as `MIRROR` and
`KEY`.

A flat handhold enum plus many ad hoc booleans on the generated socket
would couple generation, runtime state, and presentation too tightly.
Overloading `ChunkType` would also confuse route pattern with
per-handhold behavior and make deterministic tests harder to reason
about.

The handhold model must:

- keep `ChunkType` responsible for route geometry only,
- preserve deterministic layout generation from seed plus chunk index,
- support passive, timed, release-triggered, reward, defense, moving,
  and linked-route handholds,
- keep mutable per-run state out of generated layout snapshots, and
- remain strictly typed and fail fast.

## Decision

- Add a separate typed handhold layer instead of expanding
  `ChunkType`.
- Introduce `HandholdType` as a stable catalog id for design,
  debugging, and presentation labels.
- Author each handhold through an immutable
  `HandholdTypeDefinition` `Resource`.
- `HandholdTypeDefinition` composes behavior from a small number of
  typed sub-models:
  - `HandholdSurfaceProfile` for passive attachment rules such as
    drain, stability, and hazard resistance.
  - `HandholdLifecycleRule` for timers, one-shot use, break
    conditions, or blinking windows.
  - `HandholdMovementRule` for release impulse, rail motion,
    orbit/tether constraints, or gravity modifiers.
  - `HandholdRewardRule` for stamina grants, coin payouts, shields,
    combos, or paint-style buffs.
  - `HandholdLinkRule` for mirror, key, switch, or other linked-route
    interactions.
- Extend `GeneratedHandholdSocket` so each generated hold carries:
  - `handhold_type`
  - `definition_id`
  - `local_position`
  - deterministic resolved scalar values needed for tests and
    replay-stable layout inspection
  - no mutable runtime flags
- Keep layout generation two-phase:
  - phase 1 places handhold geometry from chunk pattern
  - phase 2 assigns handhold types deterministically from seed, chunk
    index, route slot, difficulty band, row role, and lane role
- Add a dedicated `GeneratedHandholdAdapter` runtime node to own
  mutable per-run state such as timers, break state,
  reward-consumed flags, and active linked-handhold handles.
- Keep `HandholdTarget` limited to attachment-time data and resolved
  passive modifiers. Runtime effects continue through the adapter
  rather than embedding timers or reward state in target snapshots.
- Implement special handhold behavior through typed trigger and effect
  specs instead of metadata bags or domain dictionaries.
  - `HandholdTrigger` examples: `ON_FIRST_ATTACH`, `ON_ATTACH`,
    `WHILE_ATTACHED`, `ON_RELEASE`, `ON_BREAK`, `ON_REENTER`,
    `ON_LINK_TRIGGER`
  - `HandholdEffectSpec` examples: drain multiplier, impulse, timed
    break, coin grant, stamina grant, shield grant, linked activation,
    or rail motion
- Scope the first issue to `NORMAL`, `REST`, `BURN`, `BREAK`, and
  `BOOST`.
  - This validates passive, punitive, timed, and release-triggered
    behaviors without requiring economy, shield, moving-path, or
    linked-route systems.

## Consequences

- Deterministic generation and runtime mutation remain separated, so
  tests can compare layout signatures without serializing mutable
  state.
- New handhold ideas can usually be added by authoring definitions and
  typed effect specs rather than inventing new socket classes or
  overloading `ChunkType`.
- Handhold runtime logic gains an explicit seam similar to the
  existing pickup and hazard adapters.
- High-concept holds such as `ZIP`, `TETHER`, `MIRROR`, or `DICE`
  will still require new effect-spec implementations, but not a model
  redesign.
- The first issue should avoid linked, moving, or defensive holds
  until the adapter, trigger, and effect seams are stable.
