# ADR 0001: Project Structure And Standards

## Status

Accepted

## Context

The project is a Godot 4.4+ mobile-first physics climber. The MVP needs strict typing, no silent fallback behavior, SOLID-oriented boundaries, proper testing, and workspace-shared agent instructions.

## Decision

- Use strictly typed GDScript.
- Use GUT for tests.
- Use `.github/copilot-instructions.md` as the single project-wide agent instruction file.
- Use `.github/instructions/*.instructions.md` for targeted file-specific instructions.
- Organize gameplay into typed systems under `src/` and scene composition under `scenes/`.
- Use typed Resources under `resources/config/` for tuning.
- Fail fast on invalid configuration, missing assets, missing nodes, and unsupported states.

## Consequences

- Implementation work starts slower, but gameplay rules remain testable and safer to evolve.
- GUT must be installed and pinned before the full test suite can run in CI.
- Platform SDKs must stay behind adapters instead of leaking into gameplay code.