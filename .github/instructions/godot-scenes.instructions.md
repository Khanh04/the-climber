---
description: "Use when editing Godot scenes or resources. Covers scene composition, typed Resources, exported references, collision ownership, and avoiding unsafe scene churn."
applyTo: ["**/*.tscn", "**/*.tres", "**/*.res"]
---
# Godot Scene And Resource Rules

- Keep scenes compositional and scripts focused.
- Required exported references must be validated by code or scene tests.
- Do not change mass, friction, or collision layers through cosmetics.
- Player collision shapes belong to the base skeleton; only a player appearance may refit them (head box, arm silhouettes, shoulder sockets) to its art, per `docs/adr/0012-appearance-fitted-collision.md`.
- Typed tuning data belongs in Resource scripts under `resources/config/`.
- Avoid broad scene rewrites when a targeted scene or Resource edit is enough.
- Add scene-contract tests for required nodes, collision layers, and gameplay groups.