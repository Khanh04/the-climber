---
description: "Use when writing GUT tests, test fixtures, or validation scripts. Covers typed tests, coverage expectations, and headless Godot test execution."
applyTo: "tests/**/*.gd"
---
# Testing Rules

- Tests use GUT and must be strictly typed GDScript.
- Prefer unit tests for pure gameplay rules before scene tests.
- Add integration or scene tests when behavior depends on node wiring, collision layers, groups, or exported references.
- Keep fixtures typed and explicit.
- Do not weaken assertions to match implementation.
- Run `sh scripts/test.sh` for the GUT suite and `sh scripts/validate.sh` for full validation.
- Follow `docs/engineering/TESTING.md`.