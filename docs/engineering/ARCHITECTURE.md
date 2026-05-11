# Architecture

The Climber is a Godot 4.4+ mobile-first 2D physics game. The MVP architecture protects the fast retry loop first: climb, fall, laugh, retry.

## Dependency Direction

- Gameplay systems depend on typed domain models and configuration Resources.
- Gameplay systems do not depend directly on platform SDKs.
- Platform integrations live behind typed adapters under `src/platform/`.
- UI reads game state and dispatches typed commands; it does not own gameplay rules.
- Scenes compose systems. Reusable rules live in scripts under `src/` and are covered by tests.

## Source Boundaries

- `src/core/`: enums, identifiers, validation helpers, and project-wide constants.
- `src/gameplay/player/`: ragdoll, grip, stamina, hand attachment, and player-facing rescue hooks.
- `src/gameplay/run/`: run state, death taxonomy, fall timing, retry flow, and rescue orchestration.
- `src/gameplay/chaser/`: Chaser motion, pacing, kill-zone behavior, and theme hooks.
- `src/gameplay/generation/`: UTC daily seed keys, generator versions, altitude-band placement, and debug metadata.
- `src/gameplay/hazards/`: hazard-specific behavior.
- `src/gameplay/pickups/`: normal coins, special coin stacks, scatter behavior, and pickup events.
- `src/economy/`: wallet, inventory, consumables, reward grants, and entitlement state.
- `src/cosmetics/`: visual-only loadouts, themes, and physics-neutral cosmetic validation.
- `src/platform/`: rewarded ads, purchases, subscriptions, sharing, permissions, and future camera/social adapters.
- `src/ui/`: HUD, run summary, ad prompts, vending UI, store shell, and settings.

## Scene Boundaries

- Scene scripts should be thin coordinators.
- Scene scripts may cache required child nodes, but missing nodes must fail fast.
- Player collision shapes belong to the base skeleton only.
- Cosmetics must never modify mass, friction, collision layers, collision shapes, or gameplay tuning.

## Configuration

- Tunable values live in typed `Resource` classes under `resources/config/`.
- Configuration Resources must expose a `validate()` method when values have constraints.
- Invalid configuration is a development error. Do not clamp, guess, or silently replace invalid values.

## MVP Boundaries

- No global leaderboards in MVP.
- No server-authoritative replay validation in MVP.
- Chaser contact is final and not rescue-eligible.
- Falls and stamina-caused falls are rescue-eligible once per run.