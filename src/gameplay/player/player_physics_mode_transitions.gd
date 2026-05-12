class_name PlayerPhysicsModeTransitions
extends RefCounted

const ClimbPrototypeFrameResultScript = preload("res://src/gameplay/player/climb_prototype_frame_result.gd")
const PlayerPhysicsModeScript = preload("res://src/gameplay/player/player_physics_mode.gd")

enum Reason {
	FRAME_ADVANCE,
	ALL_HANDS_RELEASED,
	STAMINA_DEPLETED,
	FALL_DETECTED,
	RESET_OR_RESCUE
}

static func is_reason_valid(reason: int) -> bool:
	match reason:
		Reason.FRAME_ADVANCE:
			return true
		Reason.ALL_HANDS_RELEASED:
			return true
		Reason.STAMINA_DEPLETED:
			return true
		Reason.FALL_DETECTED:
			return true
		Reason.RESET_OR_RESCUE:
			return true
		_:
			return false

static func assert_reason_valid(reason: int) -> void:
	Validation.require_condition(is_reason_valid(reason), "Unsupported player physics transition reason.")

static func is_transition_allowed(current_mode: int, next_mode: int, reason: int) -> bool:
	PlayerPhysicsModeScript.assert_valid(current_mode)
	PlayerPhysicsModeScript.assert_valid(next_mode)
	assert_reason_valid(reason)

	if current_mode == next_mode:
		return true

	if current_mode == PlayerPhysicsModeScript.controlled_climb() and next_mode == PlayerPhysicsModeScript.falling_ragdoll():
		return reason == Reason.ALL_HANDS_RELEASED \
			or reason == Reason.STAMINA_DEPLETED \
			or reason == Reason.FALL_DETECTED

	if current_mode == PlayerPhysicsModeScript.falling_ragdoll() and next_mode == PlayerPhysicsModeScript.controlled_climb():
		return reason == Reason.RESET_OR_RESCUE

	return false

static func assert_transition_allowed(current_mode: int, next_mode: int, reason: int) -> void:
	Validation.require_condition(is_transition_allowed(current_mode, next_mode, reason), "Player physics mode transition is not allowed.")

static func mode_after_frame(current_mode: int, frame_result: RefCounted) -> int:
	PlayerPhysicsModeScript.assert_valid(current_mode)
	Validation.require_condition(frame_result != null, "Player physics mode transition requires a frame result.")
	Validation.require_condition(frame_result is ClimbPrototypeFrameResultScript, "Player physics mode transition requires a ClimbPrototypeFrameResult.")

	var typed_frame_result: ClimbPrototypeFrameResultScript = frame_result
	typed_frame_result.assert_valid()

	if typed_frame_result.stamina_depleted_now:
		assert_transition_allowed(current_mode, PlayerPhysicsModeScript.falling_ragdoll(), Reason.STAMINA_DEPLETED)
		return PlayerPhysicsModeScript.falling_ragdoll()

	return current_mode

static func reset_mode(current_mode: int) -> int:
	assert_transition_allowed(current_mode, PlayerPhysicsModeScript.controlled_climb(), Reason.RESET_OR_RESCUE)
	return PlayerPhysicsModeScript.controlled_climb()