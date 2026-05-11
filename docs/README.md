# The Climber Docs

This repository is currently initialized as a docs-first scaffold based on the provided game design document.

## Document Map

- [01-core-gameplay-physics.md](./01-core-gameplay-physics.md): Core movement, ragdoll architecture, stamina, camera, and fail states.
- [02-chaser-system.md](./02-chaser-system.md): Rising hazard behavior, rubber-banding, cosmetics, and audio behavior.
- [03-environment-procedural-generation.md](./03-environment-procedural-generation.md): Daily seed generation, hazard behavior, and shared-layout rules.
- [04-economy-monetization.md](./04-economy-monetization.md): Coins, rewarded ads, store structure, and consumables.
- [05-meta-viral-features.md](./05-meta-viral-features.md): Replay capture, facecam overlay, friend ghosts, and fall sprays.
- [implementation-roadmap.md](./implementation-roadmap.md): Dependency-managed MVP implementation sequence, architecture gates, and recommended next sprint.

## Shared Project Assumptions

- Engine target: Godot with a 2D physics-driven character setup.
- Product target: mobile-first, with desktop controls used mainly for development and testing.
- Core run structure: endless vertical climb with daily-seeded layout generation.
- Daily seed identity should use the full UTC date, not day-of-month only.
- Competitive fairness: cosmetics remain visual-only and must not affect gameplay physics.
- MVP competitive scope: no global leaderboards or server-authoritative score validation. Daily seeds are for shared layouts, friend ghosts, and replayable challenges.

## MVP Product Slice

- Ship the fast retry loop first: climb, fall, laugh, retry.
- Include core ragdoll gripping, stamina, fall camera, Chaser pressure, seeded vertical layout, basic coins, cosmetics shell, and three rewarded-ad placements.
- Exclude global leaderboards, server-authoritative replay validation, lead ghosts, persistent public graffiti systems, facecam, and full native video capture from MVP.
- Treat async friend features as MVP-adjacent: useful for retention, but not required before the core physics loop proves fun.

## Suggested MVP Build Order

The detailed implementation sequence lives in [implementation-roadmap.md](./implementation-roadmap.md). The short build order is:

1. Implement the player ragdoll, grip system, and stamina loop.
2. Add camera follow, fall comedy timing, run-end states, and rescue eligibility.
3. Implement the Chaser and pacing rules.
4. Add UTC daily-seeded level generation and basic hazard spawning.
5. Add normal coin pickup, special coin stacks, and a minimal wallet.
6. Add Rewarded Continue, Post-run Coin Doubler, and Pre-run Vending Machine.
7. Add cosmetic loadout plumbing without gameplay-affecting stats.

## Pending Clarifications

- Whether accelerometer tilt assist ships in MVP or after virtual controls are proven.
- Exact Supporter subscription daily coin amount and claim reset timing.
- Platform SDK choices for rewarded ads, subscriptions, purchases, camera access, and social sharing.