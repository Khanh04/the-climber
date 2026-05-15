# ADR 0003: Phase 11 Mobile Settings And Android Export

## Status

Accepted

## Context

Phase 11 prepares the MVP loop for mobile testing and eventual export. The roadmap calls for touch ergonomics, pause and lifecycle polish, haptics and audio settings boundaries, settings flow, performance checks, export presets, and a documentation audit.

The project already has separate platform adapters for local storage, rewarded ads, app lifecycle, and haptics. The gameplay save schema currently stores economy and cosmetic state. Phase 11 needs user preferences, but those preferences should not force unrelated economy-save migrations.

## Decision

- Phase 11 targets Android first for mobile debug exports and device testing.
- The MVP settings surface includes audio mute/volume, haptics enabled, and touch-zone ergonomics.
- App settings use a dedicated versioned settings snapshot and storage key through the existing `LocalStorageAdapter` boundary.
- Gameplay save data remains focused on wallet, inventory, cosmetics, and transaction state.
- Audio settings are applied through a typed adapter under `src/platform/audio/`.
- Haptics remain behind typed adapters under `src/platform/haptics/`; unsupported runtime haptics are represented explicitly by an unavailable adapter.
- Touch controls consume typed touch settings rather than hard-coded screen zones.

## Consequences

- Missing settings can create a validated default settings snapshot, while corrupt settings still fail fast with clear validation messages.
- UI scenes dispatch settings intents and never mutate `AudioServer`, haptics, storage, or gameplay state directly.
- Android export presets can be added for debug/mobile testing without committing signing secrets or production keystore paths.
- iOS export, production ad SDK integration, purchase SDK integration, cloud state, and leaderboard behavior remain outside this phase.
