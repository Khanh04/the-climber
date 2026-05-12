# Implementation Roadmap

This roadmap turns the MVP docs into a dependency-managed implementation sequence. The guiding priority is to prove the playable climb loop early while keeping strict typed systems, thin scenes, validated Resources, platform adapters, tests, and docs aligned.

## Roadmap Principles

- Build vertical slices before broad subsystems.
- Keep scene scripts as coordinators; reusable rules live under `src/`.
- Use typed domain models and typed `Resource` tuning classes, not untyped gameplay dictionaries.
- Fail fast on invalid config, missing nodes, unsupported enum values, and corrupt local data.
- Keep platform behavior behind typed adapters under `src/platform/`.
- Add or update tests with every gameplay, economy, generation, or platform-boundary change.
- Update the relevant design docs or add an ADR when implementation behavior diverges from documented MVP rules.

## Phase 1: Foundation And Contracts

Purpose: make the project rules explicit before gameplay systems multiply.

Implementation outcomes:

- Maintain the Godot project shell, strict GDScript warnings, GUT runner, and validation scripts.
- Define the typed config `Resource` convention for gameplay, economy, generation, Chaser, cosmetics, and ads tuning.
- Define the save schema versioning convention, validation behavior, and local storage adapter boundary.
- List MVP platform adapter boundaries: rewarded ads, local storage, haptics, app lifecycle, UTC clock/date provider, purchases/subscriptions, and future sharing.
- Keep `sh scripts/validate.sh` green.

Acceptance gates:

- New config classes expose validation when values have constraints.
- Missing or invalid config fails fast.
- No gameplay system calls platform SDKs directly.
- Documentation explains any architecture or tooling decision that affects later phases.

## Phase 2: Run Core And Input Intents

Purpose: create the typed rules that drive the run loop without depending on scenes.

Implementation outcomes:

- Add typed run states: ready, climbing, falling, rescue offered, ended.
- Add a typed run session service for height, run-earned coins, rescue usage, and end reason.
- Add rescue orchestration using `RunEndReason` and `RescueEligibility`.
- Add stamina runtime behavior separate from stamina tuning.
- Add typed input intent models for grip, release, aim, and debug reset.
- Add mobile touch and desktop debug adapters that produce the same gameplay intents.

Acceptance gates:

- Unit tests cover valid transitions, invalid transitions, rescue once-per-run, and stamina drain/recover behavior.
- Gameplay systems consume typed input intents, not raw input events.
- Run state changes are explicit and unsupported states fail fast.

## Phase 3: Climb Feel Prototype

Purpose: prove the core interaction before hardening full scene structure or art.

Implementation outcomes:

- Create a dev playground where the player can grip, release, climb, lose stamina, and fall.
- Use deliberately simple placeholder visuals.
- Add basic handhold detection and climb impulse behavior.
- Keep tuning values in validated typed Resources.
- Add dev controls for reset and quick scenario testing.

Acceptance gates:

- The player can complete a simple upward movement loop in the editor.
- Grip and release behavior is driven by typed intents.
- Stamina failure maps to the documented rescue-eligible run-end taxonomy.
- Validation remains green after the prototype slice.

## Phase 4: Player Physics And Scene Contract

Purpose: harden the player into a reliable scene with controlled and falling physics modes.

Implementation outcomes:

- Define controlled climbing mode and falling/ragdoll mode.
- Add transition rules between controlled climb and fall.
- Define collision ownership for the base player skeleton.
- Add required node references for hands, body, collision shapes, and debug anchors.
- Add scene contract tests for required nodes, collision layers, and ownership.

Acceptance gates:

- Missing required nodes fail fast.
- Cosmetics cannot alter mass, friction, collision layers, collision shapes, or gameplay tuning.
- Scene tests cover player skeleton collision ownership once the scene exists.

## Phase 5: Camera, HUD, And Run Loop

Purpose: turn the climb prototype into a repeatable run.

Status: implemented in the main run scene and its typed run-loop, UI presentation, and fall-resolution helpers.

Implementation outcomes:

- Add camera follow rules for vertical progress and falling.
- Track height in meters through the run session.
- Detect bottom-screen falls as a typed run-end reason.
- Add a functional HUD for height, stamina, and run coins.
- Add a basic run-end screen and restart flow.

Acceptance gates:

- A run can start, progress upward, end, and restart cleanly.
- Bottom-screen fall maps to the rescue-eligible taxonomy.
- UI reads state and dispatches commands; it does not own gameplay rules.

## Phase 6: Chaser Pressure

Purpose: add the rising hazard that prevents passive climbing and creates urgency.

Implementation outcomes:

- Expand the typed Chaser pacing model.
- Add Chaser scene as a full-width `Area2D` kill zone.
- Implement speed clamping, camping response, and rapid-climb easing.
- Add Chaser contact as final run end with no rescue offer.
- Add Chaser collision and pacing tests.

Acceptance gates:

- Chaser contact always ends the run without rescue eligibility.
- Camping and rapid-climb behavior match documented pacing rules.
- Scene tests cover Chaser collision setup once the scene exists.

## Phase 7: Deterministic Daily Generation

Purpose: make the climb layout repeatable and shareable without server-authoritative MVP assumptions.

Implementation outcomes:

- Generate handholds and sockets from the UTC daily seed key and generator version.
- Use a dedicated `RandomNumberGenerator`.
- Add typed segment and chunk models.
- Add chunk spawn and despawn windows around the camera.
- Keep deterministic content independent of spawn timing.
- Add hazard and pickup sockets for later phases.

Acceptance gates:

- Same seed and segment index produce the same content.
- Different valid dates produce different layout sequences.
- Invalid generator config fails fast.
- Runtime chunk cleanup does not affect deterministic generation results.

## Phase 8: Coins, Save, And Transactions

Purpose: add the first economy loop with persistence and duplicate-prevention rules.

Implementation outcomes:

- Add normal coin pickups that bank immediately.
- Keep run-earned coins distinct from persisted wallet balance where needed for UI and result screens.
- Add typed transaction sources for pickups, ad rewards, purchases, grants, and debug/dev actions.
- Add idempotency rules for pickup collection and reward grants.
- Add local wallet persistence through the save adapter.

Acceptance gates:

- Duplicate pickup or reward events cannot double-grant currency.
- Corrupt or unsupported save data fails fast with clear validation messages.
- Wallet persistence tests cover save, load, invalid data, grants, and spends.

## Phase 9: Rewarded Ads And Rescue UX

Purpose: add MVP monetization hooks without coupling gameplay to SDK code.

Implementation outcomes:

- Define rewarded ad adapter contracts under `src/platform/`.
- Add editor/dev mock ad adapter for tests and local play.
- Implement Rewarded Continue through the unified rescue mechanic.
- Implement Post-run Coin Doubler.
- Represent unavailable ads, reward failure, reward success, and cancelled reward attempts explicitly.

Acceptance gates:

- Rewarded Continue obeys once-per-run rescue rules.
- Chaser contact and lethal hazards remain non-rescue-eligible by default.
- Tests cover reward success, reward failure, unavailable ads, cancellation, and already-rescued cases.

## Phase 10: Cosmetics And Store Shell

Purpose: give coins a simple visual sink without gameplay-affecting stats.

Implementation outcomes:

- Add typed cosmetic item Resources.
- Add inventory and loadout models.
- Add cosmetic unlock purchases with wallet transactions.
- Add a visual application point on the player scene.
- Add a minimal store/loadout UI shell.

Acceptance gates:

- Cosmetics are visual-only and cannot affect gameplay physics.
- Tests cover purchase validation, duplicate unlocks, insufficient funds, and loadout selection.
- Store UI calls typed commands rather than mutating wallet or inventory directly.

## Phase 11: Mobile Readiness And MVP Polish

Purpose: prepare the complete MVP loop for mobile testing and eventual export.

Implementation outcomes:

- Tune touch controls and input ergonomics on mobile-first assumptions.
- Add pause, resume, and app lifecycle handling behind adapters.
- Add haptics and audio settings boundaries.
- Add basic main menu, settings, run result, rescue, and store flows.
- Run performance pass on generated chunks, Chaser, pickups, and player physics.
- Add export presets once target platforms are selected.
- Audit docs against implemented behavior.

Acceptance gates:

- The full MVP loop is playable: open game, climb today's route, collect coins, use one eligible rescue, end run, spend coins on cosmetics, retry.
- Validation passes.
- Design docs and ADRs match implemented MVP behavior.

## Cross-Phase Architecture Gates

Every phase should pass these checks before being considered complete:

- Strict typing: no implicit `Variant` gameplay models or untyped domain dictionaries.
- Fail fast: no silent fallback for invalid config, missing nodes, missing assets, unsupported enum values, or corrupt data.
- SOLID boundaries: reusable rules live under `src/`; scene scripts coordinate, UI dispatches commands, platform code stays behind adapters.
- Test coverage: gameplay, economy, generation, and platform-boundary changes include focused tests.
- Documentation: behavior changes update the relevant design module or ADR in the same change.

## Recommended Next Sprint

Start with Phase 6 now that Phases 3 through 5 are implemented and the main run scene is in place.

Sprint outcomes:

- Add the typed Chaser pacing model and scene boundary.
- Wire Chaser contact to the existing run-end flow as a non-rescueable failure.
- Add focused pacing tests and scene collision tests for the Chaser slice.
- Keep `sh scripts/validate.sh` green while preserving the current run-loop contract.
