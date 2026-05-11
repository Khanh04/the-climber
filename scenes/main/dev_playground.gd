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

var _run_session: RunSessionScript = RunSessionScript.new()
var _stamina: StaminaRuntimeScript
var _desktop_input: DesktopDebugInputAdapterScript = DesktopDebugInputAdapterScript.new()
var _mobile_input: MobileTouchInputAdapterScript = MobileTouchInputAdapterScript.new()
var _controller: ClimbPrototypeControllerScript
var _active_touch_positions: PackedVector2Array = PackedVector2Array()
var _start_y: float = 0.0

func _ready() -> void:
	_validate_required_state()
	_stamina = StaminaRuntimeScript.new(stamina_tuning)
	_controller = ClimbPrototypeControllerScript.new(climb_tuning, _stamina)
	_start_y = _reset_anchor.global_position.y
	_reset_playground()

func _physics_process(delta: float) -> void:
	var input_frame: PlayerInputFrameScript = _create_input_frame()

	if input_frame.has_debug_reset_intent():
		_reset_playground()
		return

	if _run_session.get_state() != RunStateScript.Value.CLIMBING:
		return

	var left_target: RefCounted = _find_nearest_handhold(_left_hand_anchor.global_position)
	var right_target: RefCounted = _find_nearest_handhold(_right_hand_anchor.global_position)
	var result: ClimbPrototypeFrameResultScript = _controller.apply_input_frame(input_frame, left_target, right_target, delta)

	_apply_prototype_motion(result)
	_record_height()

	if result.stamina_depleted_now:
		_run_session.begin_stamina_fall()
		_run_session.resolve_stamina_fall()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_update_touch_position(event as InputEventScreenTouch)

func reset_for_test() -> void:
	_reset_playground()

func get_run_session_for_test() -> RunSessionScript:
	return _run_session

func get_controller_for_test() -> ClimbPrototypeControllerScript:
	return _controller

func _validate_required_state() -> void:
	Validation.require_condition(climb_tuning != null, "DevPlayground requires climb tuning.")
	Validation.require_condition(stamina_tuning != null, "DevPlayground requires stamina tuning.")
	climb_tuning.assert_valid()
	stamina_tuning.assert_valid()
	Validation.require_condition(_player_body != null, "DevPlayground requires PlayerBody.")
	Validation.require_condition(_left_hand_anchor != null, "DevPlayground requires LeftHandAnchor.")
	Validation.require_condition(_right_hand_anchor != null, "DevPlayground requires RightHandAnchor.")
	Validation.require_condition(_reset_anchor != null, "DevPlayground requires ResetAnchor.")
	Validation.require_condition(get_tree().get_nodes_in_group(climb_tuning.handhold_group_name).size() > 0, "DevPlayground requires at least one handhold.")

func _create_input_frame() -> PlayerInputFrameScript:
	if _active_touch_positions.size() > 0:
		return _mobile_input.create_input_frame(get_viewport_rect().size, _active_touch_positions, _get_debug_aim_vector())

	return _desktop_input.create_input_frame(
		Input.is_action_pressed(&"debug_left_grip"),
		Input.is_action_pressed(&"debug_right_grip"),
		_get_debug_aim_vector(),
		Input.is_action_pressed(&"debug_reset_run")
	)

func _get_debug_aim_vector() -> Vector2:
	var aim_vector: Vector2 = Vector2.ZERO

	if Input.is_action_pressed(&"debug_aim_left"):
		aim_vector.x -= 1.0

	if Input.is_action_pressed(&"debug_aim_right"):
		aim_vector.x += 1.0

	if Input.is_action_pressed(&"debug_aim_up"):
		aim_vector.y -= 1.0

	return aim_vector

func _find_nearest_handhold(anchor_position: Vector2) -> RefCounted:
	var nearest_target: HandholdTargetScript = null
	var nearest_distance: float = climb_tuning.handhold_detection_radius_pixels

	for handhold in get_tree().get_nodes_in_group(climb_tuning.handhold_group_name):
		Validation.require_condition(handhold is Node2D, "DevPlayground handholds must be Node2D instances.")
		var handhold_node: Node2D = handhold
		var distance: float = anchor_position.distance_to(handhold_node.global_position)

		if distance <= nearest_distance:
			nearest_target = HandholdTargetScript.new(StringName(handhold_node.name), handhold_node.global_position)
			nearest_distance = distance

	return nearest_target

func _apply_prototype_motion(result: ClimbPrototypeFrameResultScript) -> void:
	if result.impulse != Vector2.ZERO:
		_player_body.apply_central_impulse(result.impulse)

	if _player_body.linear_velocity.length() > climb_tuning.max_player_speed_pixels_per_second:
		_player_body.linear_velocity = _player_body.linear_velocity.normalized() * climb_tuning.max_player_speed_pixels_per_second

	if result.attached_hand_count > 0 and result.impulse == Vector2.ZERO:
		_player_body.linear_velocity = Vector2.ZERO

func _record_height() -> void:
	var height_pixels: float = maxf(0.0, _start_y - _player_body.global_position.y)
	_run_session.record_height(height_pixels / climb_tuning.pixels_per_meter)

func _reset_playground() -> void:
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

func _update_touch_position(event: InputEventScreenTouch) -> void:
	if event.pressed:
		var _append_result: bool = _active_touch_positions.append(event.position)
		return

	var updated_positions: PackedVector2Array = PackedVector2Array()
	for touch_position in _active_touch_positions:
		if not touch_position.is_equal_approx(event.position):
			var _append_result: bool = updated_positions.append(touch_position)

	_active_touch_positions = updated_positions
