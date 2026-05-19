class_name RewardedContinueRescuePlan
extends RefCounted

const HandholdTargetScript = preload("res://src/gameplay/player/handhold_target.gd")

var left_hold_target: HandholdTargetScript
var right_hold_target: HandholdTargetScript
var rescue_body_position: Vector2

func _init(
	left_hold_target_value: HandholdTargetScript,
	right_hold_target_value: HandholdTargetScript,
	rescue_body_position_value: Vector2
) -> void:
	Validation.require_condition(left_hold_target_value != null, "RewardedContinueRescuePlan requires a left hold target.")
	Validation.require_condition(right_hold_target_value != null, "RewardedContinueRescuePlan requires a right hold target.")
	left_hold_target_value.assert_valid()
	right_hold_target_value.assert_valid()
	left_hold_target = left_hold_target_value
	right_hold_target = right_hold_target_value
	rescue_body_position = rescue_body_position_value

func assert_valid() -> void:
	Validation.require_condition(left_hold_target != null, "RewardedContinueRescuePlan requires a left hold target.")
	Validation.require_condition(right_hold_target != null, "RewardedContinueRescuePlan requires a right hold target.")
	left_hold_target.assert_valid()
	right_hold_target.assert_valid()
