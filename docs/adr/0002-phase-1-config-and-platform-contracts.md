# ADR 0002: Phase 1 Config And Platform Contracts

## Status

Accepted

## Context

Phase 1 requires typed config Resource conventions, a save schema/versioning convention, and explicit platform adapter boundaries before gameplay systems multiply. The initial scaffold started with a small number of tuning Resources under `src/`, while later Phase 1 work established `resources/config/` as the shared home for tuning scripts and `src/platform/` as the typed platform seam.

Without an explicit decision, the codebase would have had two unresolved problems:

- the docs would imply that all tuning scripts live under `resources/config/`, while some earlier domain-owned tuning scripts still lived under `src/`
- save/local storage, UTC date access, rewarded ads, haptics, lifecycle, purchases, subscriptions, and sharing would exist in code without a recorded architectural rule for how later phases must use them

## Decision

- Use typed `Resource` classes as the standard configuration model.
- Shared tuning/config scripts for gameplay, economy, generation, Chaser, cosmetics, and ads live under `resources/config/`.
- Concrete `.tres` configuration assets also live under `resources/config/`.
- Config Resources with constrained values expose `validate()`, `is_valid()`, and `assert_valid()`.
- Save data uses an explicit schema version and must fail fast on unsupported versions, missing required fields, and corrupt persisted values.
- Platform seams are defined as typed adapters under `src/platform/`.
- Gameplay code may depend on typed platform interfaces and typed models, but it may not call platform SDKs directly.
- Phase 1 platform contract boundaries are local storage, UTC clock/date, rewarded ads, haptics, app lifecycle, purchases, subscriptions, and sharing.

## Consequences

- Phase 2 and later slices can build against stable typed contracts instead of inventing new ad hoc boundaries.
- The docs now match the implementation: `resources/config/` is the home for shared config scripts and config assets.
- Save and platform code must keep failing fast at the boundary instead of introducing fallback parsing or silent defaulting.
- New gameplay systems can consume config Resources without introducing new location-specific conventions.