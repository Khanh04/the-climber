# Project Guidelines

## Stack

- Target Godot 4.4+.
- Use strictly typed GDScript for gameplay and tests.
- Use GUT for Godot tests.
- Treat this as a mobile-first project with desktop support only for development and testing.

## Architecture

- Follow `docs/engineering/ARCHITECTURE.md`.
- Keep scene scripts thin and move reusable rules into typed systems under `src/`.
- Keep platform SDKs behind typed adapters under `src/platform/`.
- Do not add global leaderboard or server-authoritative replay assumptions to MVP code.

## Code Style

- Follow `docs/engineering/CODING_STANDARDS.md`.
- Do not use untyped domain dictionaries or implicit `Variant` gameplay models.
- Do not add silent fallback behavior for invalid config, missing assets, missing nodes, or unsupported enum values.
- Fail fast with clear validation messages.

## Testing

- Follow `docs/engineering/TESTING.md`.
- Add or update tests with every gameplay, economy, generation, or platform-boundary change.
- Run `sh scripts/validate.sh` before considering implementation complete.

## Documentation

- Follow `docs/engineering/DOCUMENTATION.md`.
- Update design docs or add an ADR when behavior diverges from documented MVP rules.