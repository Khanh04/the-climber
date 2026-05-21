class_name TutorialRunObservation
extends RefCounted

var left_was_attached: bool = false
var right_was_attached: bool = false
var left_is_attached: bool = false
var right_is_attached: bool = false
var attached_hand_count: int = 0
var control_force: Vector2 = Vector2.ZERO
var has_reached_upper_hold: bool = false

func _init(
	left_was_attached_value: bool = false,
	right_was_attached_value: bool = false,
	left_is_attached_value: bool = false,
	right_is_attached_value: bool = false,
	attached_hand_count_value: int = 0,
	control_force_value: Vector2 = Vector2.ZERO,
	has_reached_upper_hold_value: bool = false
) -> void:
	left_was_attached = left_was_attached_value
	right_was_attached = right_was_attached_value
	left_is_attached = left_is_attached_value
	right_is_attached = right_is_attached_value
	attached_hand_count = attached_hand_count_value
	control_force = control_force_value
	has_reached_upper_hold = has_reached_upper_hold_value

func assert_valid() -> void:
	Validation.require_condition(attached_hand_count >= 0 and attached_hand_count <= 2, "TutorialRunObservation attached hand count must stay between zero and two.")
	var computed_attached_hand_count: int = 0
	if left_is_attached:
		computed_attached_hand_count += 1
	if right_is_attached:
		computed_attached_hand_count += 1
	Validation.require_condition(
		computed_attached_hand_count == attached_hand_count,
		"TutorialRunObservation attached hand count must match current attachment flags."
	)