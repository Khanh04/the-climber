# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**The Climber** is a Godot 4.6 mobile-first 2D physics climbing game targeting Android. The core loop is: climb, fall, laugh, retry. It uses GDScript with strict typing throughout.

## Commands

```sh
# Run all tests (unit + integration + scene)
sh scripts/test.sh

# Validate project loads cleanly, then run all tests
sh scripts/validate.sh

# Lint documentation markdown
sh scripts/check_docs.sh
```

Godot binary defaults to `$HOME/.local/godot`. Override with `GODOT_BIN=/path/to/godot`.

To run a single GUT test file from the editor, use the GUT panel (addons/gut). From CLI, the runner discovers all tests under `tests/` automatically — there is no per-file CLI flag.

## Architecture

### Source Boundaries

| Directory | Responsibility |
|---|---|
| `src/core/` | Enums, identifiers, `Validation` helper, project-wide constants |
| `src/gameplay/player/` | Ragdoll, grip, stamina, hand attachment, rescue hooks |
| `src/gameplay/run/` | Run state machine, death taxonomy, fall timing, retry flow, rescue orchestration |
| `src/gameplay/chaser/` | Chaser motion, pacing, kill-zone, theme hooks |
| `src/gameplay/generation/` | Daily seed, route-first chunk generation pipeline, altitude-band placement |
| `src/gameplay/hazards/` | Hazard contact services |
| `src/gameplay/pickups/` | Coin pickup services |
| `src/economy/` | Wallet, coin ledger, consumables, reward grants |
| `src/cosmetics/` | Visual-only loadouts, cosmetic applicators |
| `src/platform/` | Typed adapters for ads, storage, clock, haptics, lifecycle, commerce, sharing |
| `src/ui/` | Presenters, state models, and view contracts for HUD, overlays, store, settings |
| `src/debug/` | Debug-only utilities (not shipped) |
| `resources/config/` | Typed `Resource` scripts and `.tres` tuning assets |
| `scenes/` | Thin scene coordinator scripts and `.tscn` files |
| `tests/unit/` | Pure logic tests (no scenes) |
| `tests/integration/` | Cross-system tests |
| `tests/scene/` | Scene contract tests (node presence, collision layers, groups) |

### Dependency Rules

- Gameplay systems depend on typed domain models and `resources/config/` Resources.
- Gameplay systems never call platform SDKs directly — only through `src/platform/` adapters.
- Scene scripts are thin coordinators. Reusable rules live in `src/`.
- UI reads game state and dispatches typed commands; it does not own gameplay rules.
- Cosmetics must never modify mass, friction, collision layers, collision shapes, or gameplay tuning.

### Run State Machine

`RunState` (`src/gameplay/run/run_state.gd`) has five values: `READY → CLIMBING → FALLING → RESCUE_OFFERED → ENDED`. `RunLoopCoordinator` contains the pure logic for camera, fall detection, and state transitions.

### Generation Pipeline

Chunk generation is route-first (`src/gameplay/generation/`): plan route intent (`ChunkRoutePlan`) → solve path on a five-lane anchor graph → populate handholds by row role → assign `HandholdType` deterministically from seed + chunk index → place hazards from typed intents. All generation is deterministic from a UTC daily seed key. Invalid candidates are hard errors — no silent fallback.

### Configuration Resources

All tuning lives in `resources/config/` as typed `Resource` subclasses with `.tres` concrete assets. Resources with constrained values expose `validate()`, `is_valid()`, and `assert_valid()`. Never clamp or silently default invalid config values.

### Platform Adapters

Every platform concern (storage, rewarded ads, haptics, UTC clock, purchases, subscriptions, sharing, audio settings) has a typed abstract adapter in `src/platform/` with a factory and at least one concrete implementation. Persistence dictionaries must be parsed into typed models immediately at the adapter boundary and validated.

## Coding Standards

- Strictly typed GDScript: every parameter, return type, and property must be typed. Avoid `Variant` except at Godot or serialization boundaries.
- No silent fallbacks: fail fast with a clear message when required state is invalid. Do not catch and ignore errors. Do not substitute defaults for invalid config.
- No loose dictionaries for domain data: use typed classes or Resources. Dictionaries are allowed only at Godot API, persistence, or platform SDK boundaries — parse them immediately.
- Forbidden pattern: `var x = value if value != null else default` — use explicit validation instead.

## Testing Standards

- GUT v9.6.0 (pinned). Tests live under `tests/` with subdirectories `unit/`, `integration/`, `scene/`.
- Test names describe behavior, not implementation.
- Scene tests verify required node presence, exported references, collision layers, and group membership.
- Do not loosen assertions to make tests pass.
- Run `sh scripts/validate.sh` before considering any implementation complete.

## Documentation

- Update the relevant `docs/` design module when behavior changes from what is documented.
- Add an ADR under `docs/adr/` for architecture, tooling, platform SDK, monetization policy, or MVP scope decisions. Follow the `0001-short-title.md` naming pattern.
- Engineering docs: `docs/engineering/ARCHITECTURE.md`, `CODING_STANDARDS.md`, `TESTING.md`, `DOCUMENTATION.md`.

## MVP Constraints

- No global leaderboards.
- No server-authoritative replay validation.
- Chaser contact is final and not rescue-eligible. Falls and stamina-caused falls are rescue-eligible once per run.
