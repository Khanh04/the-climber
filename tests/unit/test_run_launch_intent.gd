extends GutTest

const RunLaunchIntentScript = preload("res://src/core/run_launch_intent.gd")
const RunLaunchModeScript = preload("res://src/core/run_launch_mode.gd")

func test_run_launch_mode_rejects_invalid_values() -> void:
	assert_true(RunLaunchModeScript.is_valid(RunLaunchModeScript.Value.NORMAL))
	assert_true(RunLaunchModeScript.is_valid(RunLaunchModeScript.Value.TUTORIAL))
	assert_false(RunLaunchModeScript.is_valid(-1))

func test_run_launch_intent_defaults_to_normal_mode() -> void:
	var launch_intent := RunLaunchIntentScript.new()
	add_child_autofree(launch_intent)

	assert_eq(launch_intent.get_next_mode(), RunLaunchModeScript.Value.NORMAL)

func test_run_launch_intent_consumes_staged_mode_and_resets_to_normal() -> void:
	var launch_intent := RunLaunchIntentScript.new()
	add_child_autofree(launch_intent)

	launch_intent.set_next_mode(RunLaunchModeScript.Value.TUTORIAL)

	assert_eq(launch_intent.consume_next_mode(), RunLaunchModeScript.Value.TUTORIAL)
	assert_eq(launch_intent.get_next_mode(), RunLaunchModeScript.Value.NORMAL)