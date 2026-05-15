# Module 3: Environment and Procedural Generation

## Owner

Level Designer / Systems Programmer

## Goal

Generate a daily-shared tower layout with enough variation and hazard
interaction to support replayability, friend ghosts, and social
comparison without requiring MVP leaderboards, while keeping the
opening route readable for onboarding and the runtime safe for mobile
object budgets.

## MVP Scope

- UTC daily seed and generator version drive deterministic chunk
  layouts.
- Layouts include a generated opener at the reset anchor, generated
  handholds, normal coin sockets, and hazard sockets.
- The opener must support first-run onboarding with obvious reachable
  hold pairs, low early punishment, and no misleading cross-screen
  route asks before the player learns the left and right grip loop.
- The current MVP hazard set is spike clusters, wind gusts,
  downdrafts, and updrafts through one shared generated-hazard runtime
  seam.
- Use daily layouts for shared challenge and future friend ghosts, not
  for server-authoritative score validation.
- Keep the first generator simple enough to debug by altitude segment,
  difficulty band, and route slot.
- Keep generated chunk lifetimes, spawned pickups, and hazard counts
  within Android-friendly object budgets.
- Daily progression should stay local-first: daily best, personal
  best, streaks, and simple challenge goals may exist without adding a
  backend requirement.

## Core Requirements

### Daily Seed Generation

- All players share the same global layout for each 24-hour period.
- Seed generation is based on the full UTC date rather than
  day-of-month only.
- Recommended key format: `generator_v1:YYYY-MM-DD` using UTC.
- Use a dedicated `RandomNumberGenerator` instance for daily generation
  rather than relying on global RNG state.
- Include a generator version in the seed key so future layout changes
  do not corrupt old ghost or replay data.
- The seed drives handhold placement, hazard placement, and coin
  placement across every chunk, including the opener.
- The same seed should allow friends to compare routes and death
  locations on identical layouts.

### Generated Opener And Chunk Flow

- Chunk 0 is a generated opener slot, not an authored starter route.
- The generated chunk coordinator anchors chunk 0 directly at the reset
  marker with no starter gap.
- The opener must place at least one reachable left and right handhold
  pair within the player's initial grip range.
- The opener should bias toward a readable left-right alternation with
  obvious upward intent and minimal need for advanced pendulum timing.
- Early opener routes should avoid stacking lethal hazards, dense force
  hazards, or bait holds that create unfair first-run failures before
  the onboarding grace period ends.
- Before the player reaches the normal route cadence, generated chunks
  should prefer recovery and baseline patterns over challenge-only
  pressure.
- Later chunks follow a deterministic route-slot cadence: baseline,
  skill, recovery, risk, and challenge-only pressure repeating upward.
- Chunk spawn and despawn windows around the camera must never change
  layout content or chunk metadata.

### Daily Progression Goals

- Daily layouts should support local daily best and lifetime personal
  best tracking without requiring account services.
- The generation model should create enough route, hazard, and coin
  variation inside the daily seed framework that one day feels worth
  multiple attempts.
- Difficulty should ramp from onboarding-safe opener routes into the
  normal baseline and challenge cadence without a sudden fairness cliff.
- If streaks or simple achievement-style goals ship, they should align
  with behaviors the generator can support consistently, such as
  height milestones, clean fall recovery, or hazard-survival goals.
- Player-facing UI may surface the active daily seed context and next
  UTC reset timing, but the generator must not depend on live service
  availability.

### Current MVP Hazard Set

#### Spike Clusters

- Spawn as generated lethal hazard sockets.
- Use them to deny risky or pressure lanes and end the run immediately
  on contact.

#### Wind Gusts

- Spawn as force hazards that release attachments, clear active grip
  joints, and apply a lateral or upward impulse without forcing the
  run into the falling state.
- Use them as the default non-lethal disruption in baseline or easy
  skill chunks.

#### Downdrafts

- Spawn as force hazards that release attachments, clear active grip
  joints, and push the player downward while keeping re-grabs
  available.
- Reserve them for challenge-band skill slots where timing pressure
  should increase without making the hazard instantly lethal.

#### Updrafts

- Spawn as force hazards that release attachments, clear active grip
  joints, and launch the player upward while preserving recovery
  inputs.
- Use them in opener and recovery slots so early chunks feel dynamic
  without requiring an authored handoff.

## Implementation Notes

### Deterministic Generation

- Keep generation order stable so content placement remains
  reproducible from the same seed.
- Build a dedicated RNG from the daily seed plus chunk index rather
  than sharing mutable global RNG state.
- Avoid mixing non-deterministic runtime events into layout generation.
- Separate layout generation from runtime hazard state so daily layout
  sharing remains predictable.
- Generation results must remain stable regardless of spawn timing,
  camera position, or chunk build call order.
- Exact physics replay validation is not an MVP requirement.

### Content Buckets

- Use separate placement passes for handholds, hazards, and pickups
  within each chunk.
- Tag spawned chunk roots with source seed and generator-version
  metadata for debugging and future ghost placement.
- Segment generation by easy, baseline, and challenge altitude bands
  so route-slot mix, hazard density, and coin risk can scale
  predictably.
- Keep the opener handhold pattern explicit and testable so initial
  reachability regressions fail fast.

### Mobile Object Budgets

- Cap active generated content by chunk window rather than letting
  object counts grow with run length.
- Keep live pickup counts, force hazards, and transient scatter bodies
  inside explicit Android performance budgets before adding more route
  variety.
- Prefer pooled or quickly cleaned-up runtime objects for scattered
  coins, force-hazard visuals, and other short-lived spawned elements.
- Final presentation must not expand generated runtime counts beyond
  the validated systems-beta budget.
- When budget pressure appears, reduce active object counts or hazard
  density before widening the chunk window or adding richer effects.

### Hazard Interactions

- Hazards should modify the existing grip and physics systems rather
  than inventing parallel rules.
- Force hazards should release attachments and apply impulses through
  the shared falling path, not scripted teleports.
- Lethal hazards should end the run through the existing
  non-rescueable hazard flow.
- Future surface hazards such as greasy or crumbling holds should
  reuse the same typed socket and runtime separation.

## Post-MVP

- Crumbling ledges, greasy ledges, and elastic vines can follow once
  the generated opener and current four-hazard set are stable.
- Friend ghost overlays and fall sprays stay associated with the UTC
  seed and generator version.
- Generator migrations should preserve old ghost data when content
  rules change.
- More advanced daily challenge goal variants can follow once the
  local-first progression layer is stable.

## Open Questions

- What final easy, baseline, and challenge altitude thresholds should
  ship after balancing opener consistency and hazard cadence?
- How should the active daily seed and UTC reset timing be surfaced in
  debug tools and player-facing UI?
- How many generated objects can remain active on mobile before
  pooling or stricter despawning is required?
- Which local daily progression hooks should be in the first Android
  release: daily best only, daily best plus streaks, or a broader goal
  set?
- When should the design expand beyond spike clusters, wind gusts,
  downdrafts, and updrafts to surface-based hazards such as crumbling
  or greasy holds?

## Risks

- Generator changes can invalidate ghost data unless the seed includes
  a generator version.
- Generated opener regressions can create unreachable starts if player
  spawn, grip radius, or opener spacing changes.
- Overly dense early chunks can undermine onboarding even if they are
  technically reachable.
- UTC rollover can confuse players if the UI does not clearly show
  daily reset timing.
- Mobile performance can degrade quickly if scattered pickups, force
  hazards, and chunk lifetimes are allowed to scale together.
- Force hazards can feel arbitrary if impulse tuning bypasses the
  shared fall rules or obscures readable route intent.

## Suggested First Tasks

1. Define the daily seed key, generator version, and chunk models
   before any runtime spawning.
2. Implement chunk 0 as a generated opener at the reset anchor and
  prove the initial hold pair is reachable and onboarding-safe.
3. Generate handholds, pickups, and hazards in separate deterministic
   passes keyed by chunk index.
4. Set and validate Android object budgets for chunk windows, hazards,
  pickups, and transient scatter bodies before widening content
  variety.
5. Add chunk metadata, UTC rollover coverage, and local daily
  progression hooks so the daily layout stays debuggable and
  replay-worthy.
