extends GutTest

const RunLaunchModeScript = preload("res://src/core/run_launch_mode.gd")

func test_run_launch_mode_rejects_invalid_values() -> void:
	assert_true(RunLaunchModeScript.is_valid(RunLaunchModeScript.Value.NORMAL))
	assert_true(RunLaunchModeScript.is_valid(RunLaunchModeScript.Value.TUTORIAL))
	assert_false(RunLaunchModeScript.is_valid(-1))

func test_run_launch_mode_assert_valid_accepts_supported_values() -> void:
	RunLaunchModeScript.assert_valid(RunLaunchModeScript.Value.NORMAL)
	RunLaunchModeScript.assert_valid(RunLaunchModeScript.Value.TUTORIAL)
	assert_eq(RunLaunchModeScript.Value.TUTORIAL, 1)