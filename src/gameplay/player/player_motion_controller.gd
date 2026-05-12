class_name PlayerMotionController
extends RefCounted

const ClimbPrototypeFrameResultScript = preload("res://src/gameplay/player/climb_prototype_frame_result.gd")
const ClimbPrototypeTuningScript = preload("res://resources/config/climb_prototype_tuning.gd")
const HandAttachmentStateScript = preload("res://src/gameplay/player/hand_attachment_state.gd")
const HandSideScript = preload("res://src/gameplay/player/hand_side.gd")

var _tuning: ClimbPrototypeTuningScript

func _init(tuning: Resource) -> void:
	Validation.require_condition(tuning != null, "PlayerMotionController requires climb tuning.")
	Validation.require_condition(tuning is ClimbPrototypeTuningScript, "PlayerMotionController requires climb prototype tuning implementation.")

	_tuning = tuning
	_tuning.assert_valid()

func calculate_grip_target_position(attachment_state: RefCounted, control_force: Vector2) -> Vector2:
	Validation.require_condition(attachment_state != null, "Grip target position requires hand attachment state.")
	Validation.require_condition(attachment_state is HandAttachmentStateScript, "Grip target position requires HandAttachmentState.")

	var typed_attachment_state: HandAttachmentStateScript = attachment_state
	var attached_count: int = typed_attachment_state.get_attached_hand_count()
	Validation.require_condition(attached_count > 0, "Grip target position requires an attached hand.")

	var hold_position_sum: Vector2 = Vector2.ZERO
	if typed_attachment_state.is_attached(HandSideScript.Value.LEFT):
		hold_position_sum += typed_attachment_state.get_attach_position(HandSideScript.Value.LEFT)

	if typed_attachment_state.is_attached(HandSideScript.Value.RIGHT):
		hold_position_sum += typed_attachment_state.get_attach_position(HandSideScript.Value.RIGHT)

	var average_hold_position: Vector2 = hold_position_sum / float(attached_count)
	var aim_offset: Vector2 = Vector2.ZERO
	if control_force != Vector2.ZERO:
		aim_offset = control_force.normalized() * _tuning.grip_aim_target_offset_pixels

	return average_hold_position + Vector2.DOWN * _tuning.grip_hang_offset_pixels + aim_offset

func calculate_clamped_velocity(velocity: Vector2) -> Vector2:
	if velocity.length() <= _tuning.max_player_speed_pixels_per_second:
		return velocity

	return velocity.normalized() * _tuning.max_player_speed_pixels_per_second

func calculate_damped_velocity(velocity: Vector2, attached_hand_count: int) -> Vector2:
	Validation.require_condition(attached_hand_count >= 0 and attached_hand_count <= 2, "PlayerMotionController attached hand count must be between 0 and 2.")

	if attached_hand_count == 2:
		return velocity * _tuning.two_hand_velocity_damping

	return velocity

func apply_frame_motion(player_body: RigidBody2D, attachment_state: RefCounted, frame_result: RefCounted) -> void:
	Validation.require_condition(player_body != null, "PlayerMotionController requires a player body.")
	Validation.require_condition(attachment_state != null, "PlayerMotionController requires hand attachment state.")
	Validation.require_condition(attachment_state is HandAttachmentStateScript, "PlayerMotionController requires HandAttachmentState.")
	Validation.require_condition(frame_result != null, "PlayerMotionController requires a frame result.")
	Validation.require_condition(frame_result is ClimbPrototypeFrameResultScript, "PlayerMotionController requires a ClimbPrototypeFrameResult.")

	var typed_attachment_state: HandAttachmentStateScript = attachment_state
	var typed_frame_result: ClimbPrototypeFrameResultScript = frame_result
	typed_frame_result.assert_valid()

	if typed_frame_result.attached_hand_count > 0:
		_apply_virtual_grip_forces(player_body, typed_attachment_state, typed_frame_result)

	if typed_frame_result.control_force != Vector2.ZERO:
		player_body.apply_central_force(typed_frame_result.control_force)

	player_body.linear_velocity = calculate_clamped_velocity(player_body.linear_velocity)
	player_body.linear_velocity = calculate_damped_velocity(player_body.linear_velocity, typed_frame_result.attached_hand_count)

func _apply_virtual_grip_forces(player_body: RigidBody2D, attachment_state: HandAttachmentStateScript, frame_result: ClimbPrototypeFrameResultScript) -> void:
	var target_position: Vector2 = calculate_grip_target_position(attachment_state, frame_result.control_force)
	var displacement: Vector2 = target_position - player_body.global_position

	player_body.apply_central_force(Vector2.UP * _tuning.attached_gravity_compensation_force * player_body.mass * player_body.gravity_scale)
	player_body.apply_central_force(displacement * _tuning.grip_pull_stiffness)
	player_body.linear_velocity *= _tuning.grip_velocity_damping