---
description: "Use when writing or editing Godot GDScript files. Enforces strict typing, no fallback behavior, typed domain models, SOLID boundaries, and fail-fast validation."
applyTo: "**/*.gd"
---
# GDScript Strict Rules

- Use Godot 4.4+ typed GDScript.
- Type every function parameter and return value.
- Type every property and any local variable whose type is not obvious.
- Use typed classes or typed Resources for domain data.
- Do not use untyped dictionaries for gameplay, economy, run state, generated content, or config models.
- Parse boundary dictionaries into typed values immediately.
- Fail fast on missing nodes, missing Resources, invalid config, missing assets, and unsupported enum values.
- Keep scene scripts thin; put reusable logic under `src/` with tests.
- Follow `docs/engineering/CODING_STANDARDS.md`.