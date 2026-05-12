class_name DevPlayground
extends Node2D

const ClimbPrototypeControllerScript = preload("res://src/gameplay/player/climb_prototype_controller.gd")
const ClimbPrototypeFrameResultScript = preload("res://src/gameplay/player/climb_prototype_frame_result.gd")
const ClimbPrototypeTuningScript = preload("res://resources/config/climb_prototype_tuning.gd")
const DesktopDebugInputAdapterScript = preload("res://src/gameplay/player/desktop_debug_input_adapter.gd")
const HandSideScript = preload("res://src/gameplay/player/hand_side.gd")
const HandholdTargetScript = preload("res://src/gameplay/player/handhold_target.gd")
const MobileTouchInputAdapterScript = preload("res://src/gameplay/player/mobile_touch_input_adapter.gd")
const PlayerInputFrameScript = preload("res://src/gameplay/player/player_input_frame.gd")
const RunEndReasonScript = preload("res://src/core/run_end_reason.gd")
const RunSessionScript = preload("res://src/gameplay/run/run_session.gd")
const RunStateScript = preload("res://src/gameplay/run/run_state.gd")
const StaminaRuntimeScript = preload("res://src/gameplay/player/stamina_runtime.gd")
const StaminaTuningScript = preload("res://resources/config/stamina_tuning.gd")

@export var climb_tuning: ClimbPrototypeTuningScript
@export var stamina_tuning: StaminaTuningScript

@onready var _player_body: RigidBody2D = %PlayerBody
@onready var _left_hand_anchor: Marker2D = %LeftHandAnchor
@onready var _right_hand_anchor: Marker2D = %RightHandAnchor
@onready var _reset_anchor: Marker2D = %ResetAnchor
@onready var _camera: Camera2D = %DevCamera
@onready var _debug_label: Label = %DebugLabel

var _run_session: RunSessionScript = RunSessionScript.new()
var _stamina: StaminaRuntimeScript
var _desktop_input: DesktopDebugInputAdapterScript = DesktopDebugInputAdapterScript.new()
var _mobile_input: MobileTouchInputAdapterScript = MobileTouchInputAdapterScript.new()
var _controller: ClimbPrototypeControllerScript
var _active_touch_positions: PackedVector2Array = PackedVector2Array()
var _left_grip_link: Line2D = null
var _right_grip_link: Line2D = null
var _debug_reset_pressed: bool = false
var _start_y: float = 0.0

func _ready() -> void:
	_validate_required_state()
	_stamina = StaminaRuntimeScript.new(stamina_tuning)
	_controller = ClimbPrototypeControllerScript.new(climb_tuning, _stamina)
	_start_y = _reset_anchor.global_position.y
	_reset_playground()

func _physics_process(delta: float) -> void:
	if _consume_debug_reset_input():
		_reset_playground()
		_update_debug_label(PlayerInputFrameScript.new())
		return

	var input_frame: PlayerInputFrameScript = _create_input_frame()
	_update_debug_label(input_frame)
	_update_camera_follow()

	if _resolve_bottom_screen_fall_if_needed():
		_update_debug_label(input_frame)
		return

	if _run_session.get_state() != RunStateScript.Value.CLIMBING:
		return

	var left_target: RefCounted = _find_nearest_handhold(_left_hand_anchor.global_position)
	var right_target: RefCounted = _find_nearest_handhold(_right_hand_anchor.global_position)
	var result: ClimbPrototypeFrameResultScript = _controller.apply_input_frame(input_frame, left_target, right_target, delta)

	_apply_prototype_motion(result)
	_sync_grip_links()
	_record_height()

	if result.stamina_depleted_now:
		_run_session.begin_stamina_fall()
		_run_session.resolve_stamina_fall()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"debug_reset_run"):
		_reset_playground()
		_update_debug_label(PlayerInputFrameScript.new())
		get_viewport().set_input_as_handled()
		return

	if event is InputEventScreenTouch:
		_update_touch_position(event as InputEventScreenTouch)

func reset_for_test() -> void:
	_reset_playground()

func get_run_session_for_test() -> RunSessionScript:
	return _run_session

func get_controller_for_test() -> ClimbPrototypeControllerScript:
	return _controller

func sync_grip_links_for_test() -> void:
	_sync_grip_links()

func get_camera_player_lower_screen_offset_for_test() -> float:
	return _get_climb_tuning_float(&"camera_player_lower_screen_offset_pixels")

func get_bottom_fall_margin_for_test() -> float:
	return _get_climb_tuning_float(&"bottom_fall_margin_pixels")

func _validate_required_state() -> void:
	Validation.require_condition(climb_tuning != null, "DevPlayground requires climb tuning.")
	Validation.require_condition(stamina_tuning != null, "DevPlayground requires stamina tuning.")
	climb_tuning.assert_valid()
	stamina_tuning.assert_valid()
	Validation.require_condition(_player_body != null, "DevPlayground requires PlayerBody.")
	Validation.require_condition(_left_hand_anchor != null, "DevPlayground requires LeftHandAnchor.")
	Validation.require_condition(_right_hand_anchor != null, "DevPlayground requires RightHandAnchor.")
	Validation.require_condition(_reset_anchor != null, "DevPlayground requires ResetAnchor.")
	Validation.require_condition(_camera != null, "DevPlayground requires DevCamera.")
	Validation.require_condition(_debug_label != null, "DevPlayground requires DebugLabel.")
	Validation.require_condition(get_tree().get_nodes_in_group(climb_tuning.handhold_group_name).size() > 0, "DevPlayground requires at least one handhold.")

func _create_input_frame() -> PlayerInputFrameScript:
	if _active_touch_positions.size() > 0:
		return _mobile_input.create_input_frame(get_viewport_rect().size, _active_touch_positions, _get_debug_aim_vector())

	return _desktop_input.create_input_frame(
		Input.is_action_pressed(&"debug_left_grip"),
		Input.is_action_pressed(&"debug_right_grip"),
		_get_debug_aim_vector(),
		false
	)

func _consume_debug_reset_input() -> bool:
	var reset_pressed_now: bool = Input.is_action_pressed(&"debug_reset_run")
	var should_reset: bool = reset_pressed_now and not _debug_reset_pressed
	_debug_reset_pressed = reset_pressed_now
	return should_reset

func _get_debug_aim_vector() -> Vector2:
	var aim_vector: Vector2 = Vector2.ZERO

	if Input.is_action_pressed(&"debug_aim_left"):
		aim_vector.x -= 1.0

	if Input.is_action_pressed(&"debug_aim_right"):
		aim_vector.x += 1.0

	if Input.is_action_pressed(&"debug_aim_up"):
		aim_vector.y -= 1.0

	return aim_vector

func _update_debug_label(input_frame: PlayerInputFrameScript) -> void:
	var aim_vector: Vector2 = Vector2.ZERO
	if input_frame.has_aim_intent():
		var aim_intent: Object = input_frame.aim_intent
		aim_vector = aim_intent.get("aim_vector")

	var attached_hand_count: int = 0
	if _controller != null:
		attached_hand_count = _controller.get_attachment_state().get_attached_hand_count()

	var stamina_seconds: float = 0.0
	if _stamina != null:
		stamina_seconds = _stamina.get_current_stamina_seconds()

	_debug_label.text = "Aim: %s  Attached: %d  Stamina: %.1f  State: %d" % [
		str(aim_vector),
		attached_hand_count,
		stamina_seconds,
		_run_session.get_state()
	]

func _update_camera_follow() -> void:
	var target_y: float = _player_body.global_position.y - _get_climb_tuning_float(&"camera_player_lower_screen_offset_pixels")
	if target_y < _camera.global_position.y:
		_camera.global_position.y = target_y

func _resolve_bottom_screen_fall_if_needed() -> bool:
	if _run_session.get_state() != RunStateScript.Value.CLIMBING:
		return false

	var viewport_size: Vector2 = get_viewport_rect().size
	var bottom_fall_y: float = _camera.global_position.y + (viewport_size.y * 0.5) + _get_climb_tuning_float(&"bottom_fall_margin_pixels")
	if _player_body.global_position.y <= bottom_fall_y:
		return false

	_controller.get_attachment_state().release_all()
	_clear_grip_links()
	_run_session.begin_fall()
	_run_session.resolve_fall(RunEndReasonScript.Value.BOTTOM_SCREEN_FALL)
	return true

func _find_nearest_handhold(anchor_position: Vector2) -> RefCounted:
	var nearest_target: HandholdTargetScript = null
	var nearest_distance: float = climb_tuning.handhold_detection_radius_pixels

	for handhold in get_tree().get_nodes_in_group(climb_tuning.handhold_group_name):
		Validation.require_condition(handhold is Node2D, "DevPlayground handholds must be Node2D instances.")
		var handhold_node: Node2D = handhold
		var distance: float = anchor_position.distance_to(handhold_node.global_position)

		if distance <= nearest_distance:
			nearest_target = HandholdTargetScript.new(StringName(handhold_node.name), handhold_node.global_position, handhold_node.get_path())
			nearest_distance = distance

	return nearest_target

func _apply_prototype_motion(result: ClimbPrototypeFrameResultScript) -> void:
	if result.attached_hand_count > 0:
		_apply_virtual_grip_forces(result)

	if result.control_force != Vector2.ZERO:
		_player_body.apply_central_force(result.control_force)

	if _player_body.linear_velocity.length() > climb_tuning.max_player_speed_pixels_per_second:
		_player_body.linear_velocity = _player_body.linear_velocity.normalized() * climb_tuning.max_player_speed_pixels_per_second

	if result.attached_hand_count == 2:
		_player_body.linear_velocity *= climb_tuning.two_hand_velocity_damping

func _apply_virtual_grip_forces(result: ClimbPrototypeFrameResultScript) -> void:
	var attachment_state: HandAttachmentState = _controller.get_attachment_state()
	var target_position: Vector2 = _calculate_grip_target_position(attachment_state, result.control_force)
	var displacement: Vector2 = target_position - _player_body.global_position

	_player_body.apply_central_force(Vector2.UP * climb_tuning.attached_gravity_compensation_force * _player_body.mass * _player_body.gravity_scale)
	_player_body.apply_central_force(displacement * climb_tuning.grip_pull_stiffness)
	_player_body.linear_velocity *= climb_tuning.grip_velocity_damping

func _calculate_grip_target_position(attachment_state: HandAttachmentState, control_force: Vector2) -> Vector2:
	var attached_count: int = attachment_state.get_attached_hand_count()
	Validation.require_condition(attached_count > 0, "Grip target position requires an attached hand.")

	var hold_position_sum: Vector2 = Vector2.ZERO
	if attachment_state.is_attached(HandSideScript.Value.LEFT):
		hold_position_sum += attachment_state.get_attach_position(HandSideScript.Value.LEFT)

	if attachment_state.is_attached(HandSideScript.Value.RIGHT):
		hold_position_sum += attachment_state.get_attach_position(HandSideScript.Value.RIGHT)

	var average_hold_position: Vector2 = hold_position_sum / float(attached_count)
	var aim_offset: Vector2 = Vector2.ZERO
	if control_force != Vector2.ZERO:
		aim_offset = control_force.normalized() * climb_tuning.grip_aim_target_offset_pixels

	return average_hold_position + Vector2.DOWN * climb_tuning.grip_hang_offset_pixels + aim_offset

func _sync_grip_links() -> void:
	var attachment_state: HandAttachmentState = _controller.get_attachment_state()
	_left_grip_link = _sync_hand_link(HandSideScript.Value.LEFT, _left_grip_link, attachment_state, _left_hand_anchor, &"LeftGripLink")
	_right_grip_link = _sync_hand_link(HandSideScript.Value.RIGHT, _right_grip_link, attachment_state, _right_hand_anchor, &"RightGripLink")

func _sync_hand_link(hand_side: int, current_link: Line2D, attachment_state: HandAttachmentState, hand_anchor: Marker2D, link_name: StringName) -> Line2D:
	if not attachment_state.is_attached(hand_side):
		if current_link != null:
			current_link.queue_free()
		return null

	var active_link: Line2D = current_link
	if active_link == null:
		active_link = Line2D.new()
		active_link.name = link_name
		active_link.width = 4.0
		active_link.default_color = Color(0.72, 0.9, 1.0, 0.8)
		add_child(active_link)

	var hold_node: Node = get_node_or_null(attachment_state.get_hold_path(hand_side))
	Validation.require_condition(hold_node != null, "DevPlayground grip link requires an attached handhold node.")
	Validation.require_condition(hold_node is Node2D, "DevPlayground grip link requires a Node2D handhold.")

	active_link.points = PackedVector2Array([
		to_local(attachment_state.get_attach_position(hand_side)),
		to_local(hand_anchor.global_position)
	])
	return active_link

func _record_height() -> void:
	var height_pixels: float = maxf(0.0, _start_y - _player_body.global_position.y)
	_run_session.record_height(height_pixels / climb_tuning.pixels_per_meter)

func _reset_playground() -> void:
	_clear_grip_links()

	if _controller != null:
		_controller.reset()

	_desktop_input.reset()
	_mobile_input.reset()
	_active_touch_positions = PackedVector2Array()
	_run_session = RunSessionScript.new()
	_run_session.start_run()
	_player_body.global_position = _reset_anchor.global_position
	_player_body.linear_velocity = Vector2.ZERO
	_player_body.angular_velocity = 0.0
	_camera.global_position = Vector2(
		_reset_anchor.global_position.x,
		_reset_anchor.global_position.y - _get_climb_tuning_float(&"camera_player_lower_screen_offset_pixels")
	)

func _get_climb_tuning_float(property_name: StringName) -> float:
	var property_value: Variant = climb_tuning.get(property_name)
	if property_value is float:
		return property_value

	if property_value is int:
		var int_value: int = property_value
		return float(int_value)

	Validation.require_condition(false, "Climb tuning property %s must be numeric." % String(property_name))
	return 0.0

func _clear_grip_links() -> void:
	if _left_grip_link != null:
		_left_grip_link.queue_free()
		_left_grip_link = null

	if _right_grip_link != null:
		_right_grip_link.queue_free()
		_right_grip_link = null

func _update_touch_position(event: InputEventScreenTouch) -> void:
	if event.pressed:
		var _append_result: bool = _active_touch_positions.append(event.position)
		return

	var updated_positions: PackedVector2Array = PackedVector2Array()
	for touch_position in _active_touch_positions:
		if not touch_position.is_equal_approx(event.position):
			var _append_result: bool = updated_positions.append(touch_position)

	_active_touch_positions = updated_positions
