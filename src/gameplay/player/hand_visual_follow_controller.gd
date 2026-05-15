class_name HandVisualFollowController
extends RefCounted

const ClimbPrototypeTuningScript = preload("res://resources/config/climb_prototype_tuning.gd")

var _tuning: ClimbPrototypeTuningScript

func _init(tuning: Resource) -> void:
	Validation.require_condition(tuning != null, "HandVisualFollowController requires climb tuning.")
	Validation.require_condition(tuning is ClimbPrototypeTuningScript, "HandVisualFollowController requires climb prototype tuning implementation.")

	_tuning = tuning
	_tuning.assert_valid()

func calculate_target_local_position(
	hand_anchor_local_position: Vector2,
	visual_offset_from_reach: Vector2,
	body_local_velocity: Vector2,
	attached_hold_local_position: Vector2 = Vector2.ZERO,
	attached_to_hold: bool = false
) -> Vector2:
	var velocity_trail: Vector2 = -body_local_velocity * _tuning.hand_visual_velocity_lag_seconds
	if velocity_trail.length() > _tuning.hand_visual_max_lag_pixels:
		velocity_trail = velocity_trail.normalized() * _tuning.hand_visual_max_lag_pixels

	var target_local_position: Vector2 = hand_anchor_local_position + visual_offset_from_reach + velocity_trail
	if attached_to_hold:
		var attached_hold_pull: Vector2 = (attached_hold_local_position - target_local_position) * _tuning.hand_visual_attached_hold_pull_ratio
		if attached_hold_pull.length() > _tuning.hand_visual_attached_hold_max_pull_pixels:
			attached_hold_pull = attached_hold_pull.normalized() * _tuning.hand_visual_attached_hold_max_pull_pixels
		target_local_position += attached_hold_pull

	return target_local_position

func calculate_next_local_position(
	current_visual_local_position: Vector2,
	hand_anchor_local_position: Vector2,
	visual_offset_from_reach: Vector2,
	body_local_velocity: Vector2,
	delta_seconds: float,
	attached_hold_local_position: Vector2 = Vector2.ZERO,
	attached_to_hold: bool = false
) -> Vector2:
	Validation.require_condition(delta_seconds >= 0.0, "HandVisualFollowController delta seconds cannot be negative.")

	var target_local_position: Vector2 = calculate_target_local_position(
		hand_anchor_local_position,
		visual_offset_from_reach,
		body_local_velocity,
		attached_hold_local_position,
		attached_to_hold
	)
	if delta_seconds == 0.0:
		return current_visual_local_position

	return current_visual_local_position.move_toward(
		target_local_position,
		_tuning.hand_visual_follow_speed_pixels_per_second * delta_seconds
	)