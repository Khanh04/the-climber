# ADR 0010: Run Restart Keeps Seed; New-Seed Run And Main Menu Are Scene Re-Entry

## Status

Accepted

## Context

The pause menu (`scenes/ui/pause_menu.tscn`) and the run-end / death screen
(`scenes/ui/run_end_screen.tscn`) offered a single "Restart Run" action. It
routes through `RunScene._request_restart()` -> `_reset_playground()` ->
`GeneratedChunkCoordinator.reset_chunks()`, which rebuilds terrain from the
`_seed_key` captured once in `RunScene._ready()` via
`_configure_generated_chunks()`. That key is never regenerated during a scene's
lifetime (see ADR 0008 for why the key is now per-run rather than per-UTC-day),
so "Restart Run" always replays the identical route.

Players need two more options from both menus:

1. Start a fresh run on a **new** route (new seed), not the current one.
2. Leave the run and return to the main menu.

## Decision

Keep "Restart Run" exactly as-is: an in-place reset that preserves the current
seed, so a player can re-attempt the same route.

Add two command actions to both menus, each a plain scene switch handled by one
`RunScene._change_scene(path)` helper:

- **New Seed Run** -> `get_tree().change_scene_to_file("res://scenes/main/run_scene.tscn")`.
  Re-entering the scene re-runs `_ready()`, which calls `DailySeedKey.current_run()`
  again and yields a fresh route. No reseed method is added to
  `GeneratedChunkCoordinator`; scene re-entry reuses the one seeding path and
  avoids stale generator caches.
- **Main Menu** -> `get_tree().change_scene_to_file("res://scenes/main/main_menu_scene.tscn")`.

Both unpause the tree before switching. `RunScene` gains a
`set_scene_change_callable_for_test()` seam (mirroring `TutorialScene`) so scene
tests can assert routing without a real scene swap. The menu scenes emit typed
`new_seed_run_requested` / `main_menu_requested` signals following the existing
`*_requested` command pattern; `RunScene` connects them next to the existing
`restart_requested` wiring.

## Consequences

- "Restart Run" and "New Seed Run" are distinct and both live in the pause and
  run-end menus. Restart = same route; New Seed Run = new route.
- New Seed Run and Main Menu discard the current run with no confirmation
  prompt, matching the existing Restart behavior.
- In-place restart stays the fast path; New Seed Run pays a full scene reload.
  A `reseed()` on the coordinator is only worth adding if that reload cost ever
  matters.
- No generation, reset-pipeline, or `RunEndScreenState` / `PauseMenuState`
  changes: the new buttons are always-visible fire-and-forget commands.
