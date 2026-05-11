# Testing

The project uses GUT for Godot tests. Test scripts must follow the same strict typed GDScript rules as production scripts.

## Test Layout

- `tests/unit/`: pure logic tests for typed systems.
- `tests/integration/`: cross-system tests that do not require full gameplay scenes unless necessary.
- `tests/scene/`: scene contract tests for required nodes, exported references, collision layers, and group membership.
- `tests/fixtures/`: typed fixtures, Resources, and test scenes.

## Required Coverage

New gameplay systems need unit tests for rule behavior. Systems that depend on scene wiring also need integration or scene tests.

Initial required tests:

- UTC daily seed key format.
- Rescue eligibility matrix.
- Wallet grant/spend rules.
- Invalid tuning config fails validation.
- Player skeleton collision ownership once the player scene exists.
- Chaser collision setup once the Chaser scene exists.

## Commands

Use the scripts instead of calling tools ad hoc:

```sh
sh scripts/test.sh
sh scripts/validate.sh
```

Both scripts default to `$HOME/.local/godot`. Override with `GODOT_BIN=/path/to/godot` only when testing with another Godot executable.

`scripts/test.sh` requires GUT at `addons/gut/gut_cmdln.gd`. If GUT is not installed, the script fails with installation guidance rather than skipping tests.

## GUT Installation

Pin a GUT version before adding gameplay-heavy tests. Recommended path:

```text
addons/gut/
```

After installing or updating GUT, record the version here and keep tests compatible with that version.

## Test Style

- Test names should describe behavior, not implementation.
- Avoid random test data unless the seed is explicit.
- Do not loosen assertions to make tests pass.
- Prefer small fixtures over full scenes for pure logic.