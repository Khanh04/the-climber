extends Node

const RunLaunchModeScript = preload("res://src/core/run_launch_mode.gd")

var _next_mode: int = RunLaunchModeScript.Value.NORMAL

func get_next_mode() -> int:
	return _next_mode

func set_next_mode(next_mode: int) -> void:
	RunLaunchModeScript.assert_valid(next_mode)
	_next_mode = next_mode

func consume_next_mode() -> int:
	var next_mode: int = _next_mode
	_next_mode = RunLaunchModeScript.Value.NORMAL
	return next_mode

func reset_to_default() -> void:
	_next_mode = RunLaunchModeScript.Value.NORMAL