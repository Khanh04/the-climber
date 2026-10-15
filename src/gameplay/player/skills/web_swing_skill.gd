class_name WebSwingSkill
extends "res://src/gameplay/player/skills/character_active_skill.gd"

const HandSideScript = preload("res://src/gameplay/player/hand_side.gd")

## Holds must sit within this angle of the aim direction (cos 40 degrees).
const MIN_AIM_ALIGNMENT: float = 0.766
## Extra time after the pull to land the grab before the web lets go.
const CATCH_GRACE_SECONDS: float = 0.2

var _reach_multiplier: float
var _pull_seconds: float
var _busy: bool = false
var _elapsed_seconds: float = 0.0
var _pull_speed: float = 0.0
var _target_position: Vector2 = Vector2.ZERO

func _init(reach_multiplier: float, pull_seconds: float) -> void:
	Validation.require_condition(reach_multiplier > 1.0, "WebSwingSkill reach multiplier must exceed the grab radius.")
	Validation.require_condition(pull_seconds > 0.0, "WebSwingSkill pull seconds must be positive.")
	_reach_multiplier = reach_multiplier
	_pull_seconds = pull_seconds

func can_activate(context: SkillContextScript) -> bool:
	return find_target(context) != null

func activate(context: SkillContextScript) -> void:
	var target: Node2D = find_target(context)
	Validation.require_condition(target != null, "WebSwingSkill needs a target hold in the aim direction.")
	_target_position = target.global_position
	_pull_speed = context.get_hand_midpoint().distance_to(_target_position) / _pull_seconds
	_elapsed_seconds = 0.0
	_busy = true
	context.controller.release_all_hands()
	context.player.clear_runtime_grip_joints()
	context.player.clear_runtime_grip_links()
	context.player.show_web_line(_target_position)

func advance(delta_seconds: float, context: SkillContextScript) -> void:
	if not _busy:
		return

	_elapsed_seconds += delta_seconds
	var landed: bool = context.controller.get_attachment_state().get_attached_hand_count() > 0
	if landed or _elapsed_seconds > _pull_seconds + CATCH_GRACE_SECONDS:
		cancel(context)
		return

	var to_target: Vector2 = _target_position - context.get_hand_midpoint()
	# Grab on arrival even without the auto-catch passive; earlier holds on the way are ignored.
	context.controller.set_forced_catch(to_target.length() <= context.grab_radius_pixels)
	if to_target.is_zero_approx():
		context.player.set_body_linear_velocity(Vector2.ZERO)
	else:
		context.player.set_body_linear_velocity(to_target.normalized() * minf(_pull_speed, to_target.length() / maxf(delta_seconds, 0.001)))
	context.player.show_web_line(_target_position)

func is_busy() -> bool:
	return _busy

func cancel(context: SkillContextScript) -> void:
	_busy = false
	context.controller.set_forced_catch(false)
	context.player.hide_web_line()

## Nearest hold beyond normal grab reach but within web reach, inside the aim cone (up when not aiming).
func find_target(context: SkillContextScript) -> Node2D:
	var origin: Vector2 = context.get_hand_midpoint()
	var aim_direction: Vector2 = Vector2.UP if context.aim_vector == Vector2.ZERO else context.aim_vector.normalized()
	var max_reach: float = context.grab_radius_pixels * _reach_multiplier
	var attached_paths: Array[NodePath] = _attached_hold_paths(context)
	var best: Node2D = null
	var best_distance: float = INF

	for handhold in context.handholds:
		var offset: Vector2 = handhold.global_position - origin
		var distance: float = offset.length()
		if distance <= context.grab_radius_pixels or distance > max_reach:
			continue
		if aim_direction.dot(offset / distance) < MIN_AIM_ALIGNMENT:
			continue
		if attached_paths.has(handhold.get_path()):
			continue
		if distance < best_distance:
			best = handhold
			best_distance = distance

	return best

func _attached_hold_paths(context: SkillContextScript) -> Array[NodePath]:
	var attachment_state: HandAttachmentState = context.controller.get_attachment_state()
	var paths: Array[NodePath] = []
	var hand_sides: Array[int] = [HandSideScript.Value.LEFT, HandSideScript.Value.RIGHT]
	for hand_side in hand_sides:
		if attachment_state.is_attached(hand_side):
			paths.append(attachment_state.get_hold_path(hand_side))
	return paths
