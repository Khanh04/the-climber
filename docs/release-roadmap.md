# Release Roadmap

This roadmap continues after the MVP implementation sequence in [implementation-roadmap.md](./implementation-roadmap.md). The goal is to turn the current late-MVP foundation into an Android-first v1.0 release without losing the project's typed boundaries, fail-fast validation, test discipline, or mobile-first focus.

## Release Principles

- Freeze the core control model early so content, onboarding, and economy can balance around stable inputs.
- Keep mobile-first ergonomics ahead of platform breadth. Ship Android first, then add iOS after Android is stable.
- Placeholders may remain through systems, balance, and beta work, but they must stay readable enough for valid playtests.
- Push full placeholder replacement to the final production presentation pass so art polish does not block gameplay iteration.
- Keep ads, purchases, analytics, sharing, and future social systems behind typed platform adapters.
- Keep `sh scripts/validate.sh` green through every release phase.

## Release Assumptions

- Launch target: Android first.
- Desktop remains a development and testing surface, not a release target.
- The launch control model is the simple two-thumb split: left thumb controls the left hand, right thumb controls the right hand.
- `Hold` and `release` are the only required gestures for v1.0. Hidden smart reach assist is allowed; visible joysticks and complex gesture sets are not.
- Optional hold-drag nudge stays behind playtest validation and does not block release.

## Phase 12: Release Scope And Control Lock

Purpose: lock the v1.0 target and stop the core input model from drifting while the rest of the game is balanced.

Implementation outcomes:

- Define the Android-first v1.0 feature set and explicitly separate launch scope from post-launch scope.
- Lock the mobile control baseline as split-screen two-thumb grip alternation.
- Define hidden smart reach assist rules so auto-grab stays fair without adding UI complexity.
- Keep hold-drag nudge as an optional follow-up path, not a release dependency.
- Record the placeholder policy for the release track: readable placeholders are acceptable until the final presentation phase.

Acceptance gates:

- The control decision is consistent across roadmap, gameplay docs, and onboarding plans.
- No launch-critical system depends on a visible joystick, tap-to-target scheme, or other higher-complexity gesture layer.
- Onboarding, UI, and settings plans can all work with the locked two-thumb baseline.

## Phase 13: Onboarding And Core Feel

Purpose: make the first ten minutes understandable and make the climb loop feel reliable on touch devices.

Implementation outcomes:

- Add first-run onboarding with safe opener conditions, simple grip and release teaching, and delayed or disabled early Chaser pressure.
- Tune grip reliability, stamina readability, camera smoothing, fall timing, and rescue restoration around the locked control model.
- Add basic but meaningful haptics and UI feedback for grip, release, warning, pickup, rescue, and fail states.
- Add the first accessibility-oriented touch settings that improve comfort without adding new mechanics.

Acceptance gates:

- New players can understand the grip and release loop without external explanation.
- Core falls, rescues, and camera beats read clearly on mobile.
- Touch controls feel stable across supported aspect ratios and thumb positions.

## Phase 14: Content Balance And Daily Progression

Purpose: deepen the climb so the game has enough daily replay value before monetization and release operations harden.

Implementation outcomes:

- Tune deterministic generation across easy, baseline, and challenge bands.
- Expand route pacing, hazard cadence, and coin risk-reward placement around the launch controls.
- Add local daily progression hooks such as daily best, personal best, streaks, or simple achievement-style goals where they help retention.
- Keep generated object counts, chunk lifetimes, and hazard density inside Android performance budgets.

Acceptance gates:

- Daily runs feel varied enough without breaking determinism.
- Difficulty ramps cleanly from onboarding into the normal loop.
- Mobile object budgets hold under long-run generation and hazard pressure.

## Phase 15: Economy Completion And Store Depth

Purpose: finish the launch economy loop so retries, rewards, cosmetics, and spend sinks feel coherent.

Implementation outcomes:

- Add missing launch economy features that remain in scope: consumables, pre-run vending, and any retained special-coin systems.
- Expand store flow so permanent unlocks and run-scoped consumables are clearly separated.
- Add purchase confirmation, equip feedback, and inventory/loadout UX that remains functional even with placeholder presentation.
- Tune pricing, earn rate, and spend sinks against the intended Android launch cadence.

Acceptance gates:

- The economy loop is understandable without hidden rules.
- Store and inventory flows stay typed, validated, and persistence-safe.
- Economy tuning supports retention without making the core climb feel boost-dependent.

## Phase 16: Production Platform Integrations

Purpose: replace mock launch boundaries with real release-facing platform behavior.

Implementation outcomes:

- Integrate production rewarded ads for Continue, Coin Doubler, and Pre-run Vending.
- Add Google Play Billing and Supporter subscription behavior if monetization remains launch-scope.
- Add purchase restore, duplicate-prevention, receipt-validation strategy, and subscription grace or expiry handling.
- Add crash reporting and analytics behind typed boundaries.
- Add the lightweight launch sharing slice, preferably screenshot or share-card based unless native video is proven low-risk.

Acceptance gates:

- Sandbox ads and purchases work end-to-end.
- Failure paths remain explicit and do not trap the player.
- Privacy, consent, and data-safety obligations are defined before release candidate work begins.

## Phase 17: Android Systems Beta

Purpose: validate the full release system stack on real Android devices before the final presentation pass locks content and timing.

Implementation outcomes:

- Produce internal Android builds with enough export configuration to test on real devices.
- Run device profiling across performance tiers, aspect ratios, offline states, lifecycle transitions, ad callbacks, and purchase flows.
- Run balance and retention playtests using readable placeholders.
- Capture onboarding drop-off, average run length, economy health, crash-free sessions, and control pain points.

Acceptance gates:

- The system stack is stable enough for broader closed testing.
- Placeholders are not hiding readability problems or distorting playtest conclusions.
- Major balance and onboarding problems are identified before final art and audio begin replacing temporary presentation.

## Phase 18: Final Production Presentation Pass

Purpose: replace placeholder visuals, audio, and effects only after the systems and balance work are stable.

Implementation outcomes:

- Replace placeholder player, hold, hazard, coin, Chaser, UI, store, and share-card presentation with production assets.
- Add final animation, particles, screen feedback, and audio pass for gameplay, UI, store, rescue, and fail states.
- Re-check readability, touch ergonomics, and mobile performance after final assets land.
- Keep final presentation changes gameplay-neutral unless a documented balance reason requires otherwise.

Acceptance gates:

- Final assets improve clarity instead of fighting it.
- Cosmetic and presentation changes do not alter physics, collisions, determinism, or economy rules.
- Final art and audio still fit Android performance and memory budgets.

## Phase 19: Release Candidate Hardening And Android Launch

Purpose: lock the build, validate the final presentation under real release conditions, and ship the first production version.

Implementation outcomes:

- Finalize release export presets, signing, versioning, package metadata, store assets, privacy policy, and rollout plan.
- Run full regression after final visuals and audio are in place.
- Validate frame rate, memory, thermal behavior, load times, save safety, ads, purchases, and lifecycle handling on target devices.
- Ship a staged Android rollout with monitoring and a hotfix process.

Acceptance gates:

- Release candidate builds pass validation, regression, and device checks.
- Final asset integration has not introduced unacceptable performance regressions.
- Store submission, compliance, and rollout monitoring are ready before public launch.

## Post-Launch Track

These items stay outside the Android v1.0 critical path unless scope changes later:

- iOS release and StoreKit integration.
- Friend ghosts and backend-driven async systems.
- Full replay video export.
- Facecam features.
- Leaderboards or other backend-heavy competition features.

## Cross-Phase Release Gates

Every release phase should pass these checks before being treated as complete:

- Controls: the two-thumb split remains the launch baseline unless a documented decision replaces it.
- Readability: placeholders remain acceptable only while they still support valid testing and clear UX.
- Architecture: platform SDKs stay behind typed adapters; gameplay remains under `src/`; scene scripts coordinate.
- Validation: `sh scripts/validate.sh` stays green.
- Documentation: release-scope behavior changes update the relevant design docs or ADRs in the same change.
- Performance: Android device profiling starts before the final art pass and is rerun after it.

## Recommended First Release Sprint

Start Phase 12 now that the MVP loop is playable and the launch control direction is decided.

Sprint outcomes:

- Lock the Android-first v1.0 scope.
- Record the two-thumb control baseline and the placeholder-late presentation strategy.
- Start onboarding and touch-feel work before expanding economy, platform, and release operations.
