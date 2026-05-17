# Module 3: Environment and Procedural Generation

## Owner

Level Designer / Systems Programmer

## Goal

Generate a daily-shared tower layout that feels like a chain of
short, readable bouldering problems: clear starts, intentional movement
sequences, a fair crux, recoverable top-outs, optional risky beta, and
enough hazard interaction to support replayability, friend ghosts, and
social comparison without requiring MVP leaderboards. The opening
route must stay readable for onboarding and the runtime must stay safe
for mobile object budgets.

## MVP Scope

- UTC daily seed and generator version drive deterministic chunk
  layouts.
- Layouts include a generated opener at the reset anchor, generated
  handholds, normal coin sockets, and hazard sockets.
- Generated chunks should be evaluated as climbable route problems,
  not only as lane patterns. Each non-opener problem needs a validated
  entry, setup, crux or pressure beat, recovery/top-out, and connector
  into the next chunk window.
- The opener must support first-run onboarding with obvious reachable
  hold pairs, low early punishment, and no misleading cross-screen
  route asks before the player learns the left and right grip loop.
- The current MVP hazard set is spike clusters, wind gusts,
  downdrafts, and updrafts through one shared generated-hazard runtime
  seam.
- Use daily layouts for shared challenge and future friend ghosts, not
  for server-authoritative score validation.
- Keep the first generator simple enough to debug by altitude segment,
  difficulty band, route profile, route role, and validation result.
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
- Recommended key format: `generator_v4:YYYY-MM-DD` using UTC.
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
- Later chunks should follow a deterministic profile schedule that can
  be reproduced from the daily seed while still avoiding abrupt
  difficulty cliffs. Baseline, skill, recovery, risk, and
  challenge-only pressure profiles may remain as coarse labels, but
  selection should be weighted by altitude, recent profile history,
  and recovery needs rather than picked uniformly from a flat allowed
  list.
- Within each selected route profile, chunk archetypes should also be
  chosen by deterministic slot-aware weighting so recovery chunks bias
  toward denser central lines, risk chunks bias toward forked or
  hazard-denial branches, and pressure chunks bias toward sparse or
  commitment-heavy shapes without collapsing to one archetype.
- Vertical density should be authored per chunk archetype through
  explicit row-step tuning. Chunk segment height remains a ceiling and
  seam budget, not the source of row spacing.
- Chunk spawn and despawn windows around the camera must never change
  layout content or chunk metadata.

### Bouldering-Style Route Model

- Treat each generated non-opener chunk as a compact climbing problem
  with route roles: entry, setup, crux, recovery, top-out, optional
  beta, reward, and hazard-denial positions.
- Generate or derive a typed route graph where handholds are nodes and
  possible moves are directed edges with movement costs. Costs should
  consider vertical distance, lateral distance, hand alternation,
  hold type, stamina pressure, hazards, and whether the move is static
  or dynamic.
- Validate at least one safe path from the chunk entry to the chunk
  exit before accepting a layout. Optional harder or riskier beta can
  exist, but it must not be the only path through an onboarding or
  baseline problem.
- Grade-like difficulty should be based primarily on the hardest move
  and the hardest short sequence, not only on average handhold density
  or hazard count. Game danger remains a separate tuning dimension
  driven by Chaser pressure, lethal hazards, force hazards, stamina,
  and fall exposure.
- Seam continuity is part of the route problem. The top-out or exit
  holds of one chunk must connect to the entry holds of the next chunk
  through validated reach, a deliberate force-hazard launch, or another
  explicit connector rule.
- Preserve readable left-right grip alternation in easy and baseline
  paths. Wide reaches, dyno-like launches, cross-throughs, and sparse
  recovery should be reserved for profiles that clearly signal higher
  difficulty or optional beta.
- Coins should reward route expression by sitting near optional beta,
  crux exits, or Chaser-pressure lines rather than being sprinkled
  evenly across all anchors.
- Pickup anchoring should prioritize reward, optional-beta, and
  hazard-denial route roles before falling back to generic side-biased
  anchors.
- Hazards should shape choices: deny a risky line, pressure a crux, or
  create a recovery moment. They should not obscure the intended safe
  path or make a generated layout technically valid but unreadable.
- Hazard anchoring should prioritize hazard-denial, crux, and recovery
  roles so the dangerous line reads as intentional route pressure
  rather than background noise.

### Daily Progression Goals

- Daily layouts should support local daily best and lifetime personal
  best tracking without requiring account services.
- The generation model should create enough route, hazard, and coin
  variation inside the daily seed framework that one day feels worth
  multiple attempts.
- Difficulty should ramp from onboarding-safe opener routes into the
  normal baseline and challenge cadence without a sudden fairness cliff.
- Distribution should include recovery after high-pressure or high-crux
  chunks so the daily route feels set by a designer rather than sampled
  independently one chunk at a time.
- If streaks or simple achievement-style goals ship, they should align
  with behaviors the generator can support consistently, such as
  height milestones, clean fall recovery, or hazard-survival goals.
- Player-facing UI may surface the active daily seed context and next
  UTC reset timing, but the generator must not depend on live service
  availability.

### Planned Handhold Type Expansion

- Chunk types remain route-pattern archetypes. Per-handhold behavior
  must ship as a second typed layer and must never overload
  `ChunkType`.
- Special handholds must stay readable within one grab window through
  distinct silhouette, color, and one primary gameplay effect per
  hold.
- Deterministic generation must assign handhold types after handhold
  geometry is placed so the same seed reproduces both route pattern
  and hold behavior.
- Opener and early easy-band chunks must restrict hold selection to
  beginner-safe holds with no hidden timers, forced launch
  requirements, or linked-route dependencies.
- The first handhold-type issue should ship only `NORMAL`, `REST`,
  `BURN`, `BREAK`, and `BOOST`.
- The first issue subset should prove passive drain tuning, readable
  timed failure, and release-triggered movement before adding reward,
  shield, linked-route, or moving-path holds.
- The current implemented follow-up extends the active generator-backed
  catalog with `GHOST` and `ROCKET`.
- `GHOST` is currently a one-use hold that breaks on release, and
  `ROCKET` is currently a stronger deterministic release-launch hold.
- Active route-first generation now uses seeded weighted selection so
  these new holds can appear deterministically in challenge optional
  pressure and traverse contexts.

#### Reference Hold Idea Catalog

The catalog below preserves candidate ideas from handhold-type
brainstorming. Some entries may ship as fully distinct mechanics,
while climbing-flavored names may later collapse into presentation
aliases over a smaller ruleset.

##### Core Surface, Stamina, And Risk Holds

- `NORMAL`: default hold with no special rule.
- `REST`: lower stamina drain and recovery-friendly readability.
- `BURN`: higher stamina drain to create tempo pressure.
- `STICKY`: increased grip stability or hazard resistance while
  attached.
- `SLICK`: easier to peel off under swing or force hazards.
- `ANCHOR`: resists wind-style forced releases and stabilizes recovery
  lines.
- `SPIKE`: still grabbable, but taxes health, score, or stamina on
  use.
- `OVERHEAT`: starts safe, then turns hostile if the player camps on
  it.
- `HEAVY`: damps swing and keeps the player from overcommitting.
- `GRAVITY`: alters post-release gravity to exaggerate float or drop.
- `PAINT`: applies a temporary buff or debuff that changes the next
  move.

##### Timed, Consumable, And Stateful Holds

- `BREAK`: valid on attach, then breaks after a short readable window
  or on release.
- `GHOST`: usable once, then disappears for the rest of the run.
- `FLIP`: alternates between safe and dangerous states on each grab.
- `BLINK`: phases in and out on a readable rhythm.
- `DICE`: resolves to one of several outcomes on first grab.
- `MOVING`: shifts position along a simple path while remaining
  grabbable.

##### Motion And Routing Holds

- `BOOST`: adds a deterministic release impulse.
- `ROCKET`: converts aim direction into a stronger release launch.
- `PINBALL`: kicks the player away immediately after grab or release.
- `ORBIT`: increases angular control and encourages circular swing
  setups.
- `ZIP`: slides the player along a short authored rail or lane.
- `TETHER`: keeps a short elastic attachment after release and can
  slingshot the player.
- `MAGNET`: gently pulls a nearby aiming hand toward the hold.
- `ELASTIC_VINE`: stretches under load and rebounds on release.
- `MIRROR`: activates a mirrored counterpart on the opposite side.
- `KEY`: unlocks a nearby reward, safer lane, or temporary route aid.
- `SWITCH`: toggles another runtime object such as a hazard, reward
  line, or bridge hold.

##### Reward, Defense, And Combo Holds

- `BATTERY`: grants a one-time stamina burst on first grab.
- `COIN`: pays out coin only when successfully grabbed.
- `COMBO`: rewards clean left-right alternation or chain timing.
- `CHAIN`: escalates payoff when grabbed after another chain hold.
- `BUBBLE`: grants a temporary shield against one hazard
  interaction.

##### Climbing-Flavored Aliases And Structural Variants

- `JUG`: big forgiving hold that likely maps to `NORMAL` or `REST`.
- `CRIMP`: small stressful hold that likely maps to `BURN`.
- `SLOPER`: rewards controlled motion and likely maps to `SLICK`.
- `POCKET`: narrow commitment hold that can bias one-hand route
  decisions.
- `SIDEPULL`: directional grip that favors lateral movement.
- `UNDERCLING`: rewards upward pop or reversal timing under the hold.
- `FRAGILE_TWIN`: works for one hand but punishes or breaks under dual
  load.
- `ONE_WAY`: reliable only when approached from the intended side or
  direction.
- `PHASE`: only becomes valid under a specific state such as upward
  movement or sufficient stamina.

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

### Route Graph And Validation

- The generator rewrite uses a route-first model. Route intent is planned
  before handhold geometry, and fixed lane-row templates are replaced by
  typed route plans, layered anchor graphs, solved paths, support
  population, deterministic hold-type assignment, and hazard-intent
  placement.
- Use five logical lanes for route planning: outer-left, inner-left,
  center, inner-right, and outer-right. The center lane keeps beginner
  safe routes readable, while outer lanes make optional traverses visibly
  distinct.
- Build each chunk from row roles rather than raw hold counts. MVP row
  roles are support, decision, traverse, crux, pressure, catch, and
  top-out. Easy chunks should preserve frequent support and catch rows;
  challenge chunks may use longer sparse or pressure windows only when
  recovery appears in the broader schedule.
- Treat branchable chunks as two-route problems. A branchable plan must
  include a mandatory safe path and a distinct optional path with explicit
  split and merge rows, minimum branch separation, and minimum outer-lane
  occupancy.
- Horizontal branch quality is a first-class score. Optional paths should
  earn score for sustained width and lateral movement, and lose score for
  returning to the center before the merge row.
- Assign hold types after path solving. `NORMAL` and `REST` support
  beginner-safe and recovery roles; `BURN` adds stamina pressure on crux
  or optional lines; `BREAK` is reserved for readable challenge pressure;
  `BOOST` is a deliberate connector or fast-branch tool, not random
  decoration.
- Place hazards from typed route intent. Spike clusters deny or tax risky
  and reward branches, wind gusts shape traverse timing, downdrafts add
  challenge pressure, and updrafts provide recovery or connector relief.
  Hazards must not block the only safe path.
- Reject invalid candidates. A generated chunk must not fall back to an
  invalid layout when safe-path, branch, seam, support, hazard, or
  hold-type constraints fail.
- Build the primary handhold path before placing rewards and hazards.
  Handhold placement should own route readability; pickup and hazard
  passes should react to route roles rather than redefine the path.
- Use the runtime grip envelope as a validation input. The first
  implementation can use a conservative static reach threshold, then
  expand to dynamic movement allowances only when those allowances are
  explicit and tested.
- Validate chunk interiors and chunk seams. A layout is not acceptable
  if rows are locally reachable but the exit-to-entry gap between
  adjacent chunks is not supported by a connector rule.
- Use a small deterministic generate-and-test budget per chunk. If the
  generator cannot produce a valid candidate within that budget, fail
  fast with seed, chunk index, profile, and validation reason rather
  than silently falling back to unrelated content.
- Score accepted candidates for target difficulty, route readability,
  novelty, optional beta quality, recovery availability, object count,
  and hazard fairness. Keep the score deterministic so identical seeds
  choose identical layouts.
- Candidate scoring should include route-role coverage, route-intent
  socket alignment, and hazard fairness so the accepted chunk is not
  merely valid, but also readable as a compact bouldering problem.
- Weighted chunk-type selection should use authored lane-row shape
  metrics, not only flat membership in an allowed list, so profile
  pacing and geometry reinforce one another.
- Add distribution tests across multiple dates and chunk ranges so
  weighted profile changes do not accidentally remove recovery chunks,
  overproduce hazards, or create repeated crux styles.
- See [ADR 0006](adr/0006-route-first-generation-rewrite.md) for the
  route-first rewrite decision, data model, and validation scope.

### Handhold Type Model

- Keep `ChunkType` responsible for route geometry and add a second
  typed handhold layer for per-hold behavior.
- Generate handhold positions first, then assign handhold types in a
  deterministic second pass keyed by seed, chunk index, route slot,
  difficulty band, and local row role.
- Use immutable authored type definitions for rules and keep mutable
  per-run state local to spawned handhold runtime nodes rather than
  inside generated layout snapshots.
- Extend the generated handhold socket and player target models with
  typed handhold-type data rather than growing ad hoc node metadata.
- Add a dedicated handhold runtime adapter, mirroring the pickup and
  hazard seams, before implementing timed, reward, defense, or
  linked-route holds.
- See [ADR 0004](adr/0004-generated-hold-type-model.md) for the
  proposed typed model that can scale from the first five handhold
  types to the broader catalog above.

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
- Linked, moving, and shield or reward-reactive holds such as `ZIP`,
  `MIRROR`, `KEY`, `TETHER`, `BUBBLE`, and `DICE` can follow once the
  first five handhold types validate readability, determinism, and
  runtime cost.
- Friend ghost overlays and fall sprays stay associated with the UTC
  seed and generator version.
- Generator migrations should preserve old ghost data when content
  rules change.
- More advanced daily challenge goal variants can follow once the
  local-first progression layer is stable.
- More expressive route-setting models such as richer graph grammars,
  competition-style boulder profile packs, or player-skill-adaptive
  weighting can follow once the deterministic graph validation layer is
  stable.

## Open Questions

- What final easy, baseline, and challenge altitude thresholds should
  ship after balancing opener consistency and hazard cadence?
- What static and dynamic reach envelopes should define valid moves for
  easy, baseline, and challenge route graphs?
- What grade-like labels or internal movement-cost thresholds should be
  used for bouldering-style problems?
- How many deterministic candidate retries per chunk are acceptable on
  target Android hardware before generation should fail fast?
- How should the active daily seed and UTC reset timing be surfaced in
  debug tools and player-facing UI?
- How many generated objects can remain active on mobile before
  pooling or stricter despawning is required?
- Which reference handhold ideas should ship as distinct mechanics
  versus presentation aliases over the same smaller runtime ruleset?
- How much active timer, shield, and linked-route state can remain in
  the loaded chunk window before mobile performance or debugging
  clarity degrades?
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
- Chunk seams can create unreachable daily layouts if each chunk is
  validated in isolation rather than as part of a connected route.
- Uniform chunk-type selection can create repetitive or unfair routes
  even when every individual archetype is valid.
- Fixed altitude bands can create difficulty cliffs if they do not
  cover a full profile cycle or do not schedule recovery after pressure.
- Overly dense early chunks can undermine onboarding even if they are
  technically reachable.
- UTC rollover can confuse players if the UI does not clearly show
  daily reset timing.
- Mobile performance can degrade quickly if scattered pickups, force
  hazards, and chunk lifetimes are allowed to scale together.
- Special handholds can become unreadable if safe, breaking, launch,
  and reward behaviors are not differentiated quickly enough through
  color, silhouette, and timing cues.
- Force hazards can feel arbitrary if impulse tuning bypasses the
  shared fall rules or obscures readable route intent.

## Suggested First Tasks

1. Define the daily seed key, generator version, and chunk models
   before any runtime spawning.
2. Implement chunk 0 as a generated opener at the reset anchor and
   prove the initial hold pair is reachable and onboarding-safe.
3. Define a typed route graph model for generated handholds, movement
   edges, route roles, difficulty costs, and chunk connection ports.
4. Generate the primary safe path before pickups and hazards, then
   validate chunk interiors and chunk seams against the runtime grip
   envelope.
5. Replace flat uniform archetype selection with deterministic weighted
   route profiles that account for altitude, recent profile history,
   recovery needs, and optional risky beta.
6. Generate handholds, pickups, and hazards in separate deterministic
   passes keyed by chunk index, with pickups and hazards anchored to
   route roles rather than raw handhold order.
7. Set and validate Android object budgets for chunk windows, hazards,
   pickups, and transient scatter bodies before widening content
   variety.
8. Add chunk metadata, route validation metadata, UTC rollover
   coverage, and local daily progression hooks so the daily layout
   stays debuggable and replay-worthy.
9. Land the typed handhold model and deterministic handhold-type
   assignment pass described in
   [ADR 0004](adr/0004-generated-hold-type-model.md).
10. Implement `NORMAL`, `REST`, `BURN`, `BREAK`, and `BOOST` through a
    dedicated handhold runtime adapter before adding reward, defense,
    moving, or linked-route holds.
