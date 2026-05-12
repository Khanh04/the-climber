class_name RunEndScreenState
extends RefCounted

const RunEndReasonScript = preload("res://src/core/run_end_reason.gd")
const RunStateScript = preload("res://src/gameplay/run/run_state.gd")

var run_state: int = RunStateScript.Value.READY
var final_height_meters: float = 0.0
var run_earned_coins: int = 0
var has_end_reason: bool = false
var end_reason: int = -1

func _init(
	run_state_value: int = RunStateScript.Value.READY,
	final_height_meters_value: float = 0.0,
	run_earned_coins_value: int = 0,
	has_end_reason_value: bool = false,
	end_reason_value: int = -1
) -> void:
	run_state = run_state_value
	final_height_meters = final_height_meters_value
	run_earned_coins = run_earned_coins_value
	has_end_reason = has_end_reason_value
	end_reason = end_reason_value

func is_visible() -> bool:
	return run_state == RunStateScript.Value.RESCUE_OFFERED or run_state == RunStateScript.Value.ENDED

func is_rescue_offered() -> bool:
	return run_state == RunStateScript.Value.RESCUE_OFFERED

func assert_valid() -> void:
	RunStateScript.assert_valid(run_state)
	Validation.require_condition(final_height_meters >= 0.0, "RunEndScreenState final height cannot be negative.")
	Validation.require_condition(run_earned_coins >= 0, "RunEndScreenState run-earned coins cannot be negative.")

	if has_end_reason:
		RunEndReasonScript.assert_valid(end_reason)
	else:
		Validation.require_condition(end_reason == -1, "RunEndScreenState without an end reason must use the sentinel value.")

	if is_visible():
		Validation.require_condition(has_end_reason, "RunEndScreenState requires an end reason when visible.")