class_name SpartanKickSkill
extends "res://src/gameplay/player/skills/character_active_skill.gd"

const HandSideScript = preload("res://src/gameplay/player/hand_side.gd")

## Sideways share of the launch; the rest is straight up.
const SIDEWAYS_SHARE: float = 0.5

var _launch_speed: float

func _init(launch_speed: float) -> void:
	Validation.require_condition(launch_speed > 0.0, "SpartanKickSkill launch speed must be positive.")
	_launch_speed = launch_speed

func can_activate(context: SkillContextScript) -> bool:
	return context.controller.get_attachment_state().get_attached_hand_count() > 0

func activate(context: SkillContextScript) -> void:
	Validation.require_condition(can_activate(context), "SpartanKickSkill needs a hand on a hold to push off.")
	context.player.set_body_linear_velocity(launch_velocity(_push_off_position(context), context.player.get_body_global_position(), _launch_speed))
	context.controller.release_all_hands()
	context.player.clear_runtime_grip_joints()
	context.player.clear_runtime_grip_links()

## Up, plus a sideways push away from the hold being kicked off. Directly under it: straight up.
static func launch_velocity(push_off_position: Vector2, body_position: Vector2, speed: float) -> Vector2:
	var away_sign: float = signf(body_position.x - push_off_position.x)
	return Vector2(away_sign * SIDEWAYS_SHARE, -1.0).normalized() * speed

func _push_off_position(context: SkillContextScript) -> Vector2:
	var attachment_state: HandAttachmentState = context.controller.get_attachment_state()
	if attachment_state.is_attached(HandSideScript.Value.LEFT) and attachment_state.is_attached(HandSideScript.Value.RIGHT):
		return (attachment_state.get_attach_position(HandSideScript.Value.LEFT) + attachment_state.get_attach_position(HandSideScript.Value.RIGHT)) * 0.5
	if attachment_state.is_attached(HandSideScript.Value.LEFT):
		return attachment_state.get_attach_position(HandSideScript.Value.LEFT)
	return attachment_state.get_attach_position(HandSideScript.Value.RIGHT)
