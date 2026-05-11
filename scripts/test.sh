#!/usr/bin/env sh
set -eu

GODOT_BIN="${GODOT_BIN:-$HOME/.local/godot}"
GUT_CMD="addons/gut/gut_cmdln.gd"

if [ ! -x "$GODOT_BIN" ]; then
    echo "ERROR: Godot executable not found or not executable at $GODOT_BIN. Set GODOT_BIN=/path/to/godot." >&2
    exit 127
fi

if [ ! -f "$GUT_CMD" ]; then
    echo "ERROR: GUT is not installed at $GUT_CMD. Install and pin GUT under addons/gut before running tests." >&2
    exit 66
fi

"$GODOT_BIN" --headless --path . -s "res://$GUT_CMD" -gdir=res://tests -gexit