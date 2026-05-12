class_name RunScene
extends Node2D

const ChaserContactServiceScript = preload("res://src/gameplay/chaser/chaser_contact_service.gd")
const ChaserKillZoneScript = preload("res://scenes/chaser/chaser_kill_zone.gd")
const ChaserPacingModelScript = preload("res://src/gameplay/chaser/chaser_pacing_model.gd")
const ClimbPrototypeControllerScript = preload("res://src/gameplay/player/climb_prototype_controller.gd")
const ClimbPrototypeFrameResultScript = preload("res://src/gameplay/player/climb_prototype_frame_result.gd")
const ClimbPrototypeTuningScript = preload("res://resources/config/climb_prototype_tuning.gd")
const DesktopDebugInputAdapterScript = preload("res://src/gameplay/player/desktop_debug_input_adapter.gd")
const HandSideScript = preload("res://src/gameplay/player/hand_side.gd")
const HandholdTargetScript = preload("res://src/gameplay/player/handhold_target.gd")
const MobileTouchInputAdapterScript = preload("res://src/gameplay/player/mobile_touch_input_adapter.gd")
const PlayerCharacterScript = preload("res://scenes/player/player_character.gd")
const PlayerInputFrameScript = preload("res://src/gameplay/player/player_input_frame.gd")
const PlayerPhysicsModeTransitionsScript = preload("res://src/gameplay/player/player_physics_mode_transitions.gd")
const RunEndReasonScript = preload("res://src/core/run_end_reason.gd")
const BottomScreenFallServiceScript = preload("res://src/gameplay/run/bottom_screen_fall_service.gd")
const RunLoopCoordinatorScript = preload("res://src/gameplay/run/run_loop_coordinator.gd")
const RunSessionScript = preload("res://src/gameplay/run/run_session.gd")
const StaminaFallServiceScript = preload("res://src/gameplay/run/stamina_fall_service.gd")
const RunStateScript = preload("res://src/gameplay/run/run_state.gd")
const StaminaRuntimeScript = preload("res://src/gameplay/player/stamina_runtime.gd")
const StaminaTuningScript = preload("res://resources/config/stamina_tuning.gd")
const RunUiPresenterScript = preload("res://src/ui/run_ui_presenter.gd")
const RunUiViewScript = preload("res://src/ui/run_ui_view.gd")

@export var climb_tuning: ClimbPrototypeTuningScript
@export var stamina_tuning: StaminaTuningScript

@onready var _player: PlayerCharacterScript = %PlayerCharacter
@onready var _chaser_kill_zone: ChaserKillZoneScript = get_node("ChaserKillZone") as ChaserKillZoneScript
@onready var _reset_anchor: Marker2D = %ResetAnchor
@onready var _camera: Camera2D = %DevCamera
@onready var _run_hud: Control = %RunHud
@onready var _run_end_screen: Control = %RunEndScreen
@onready var _run_ui_view = RunUiViewScript.new(_run_hud, _run_end_screen)

var _run_session: RunSessionScript = RunSessionScript.new()
var _stamina: StaminaRuntimeScript
var _desktop_input: DesktopDebugInputAdapterScript = DesktopDebugInputAdapterScript.new()
var _mobile_input: MobileTouchInputAdapterScript = MobileTouchInputAdapterScript.new()
var _controller: ClimbPrototypeControllerScript
var _chaser_contact_service: ChaserContactServiceScript = ChaserContactServiceScript.new()
var _chaser_pacing_model: ChaserPacingModelScript
var _bottom_screen_fall_service: BottomScreenFallServiceScript = BottomScreenFallServiceScript.new()
var _run_loop_coordinator: RunLoopCoordinatorScript = RunLoopCoordinatorScript.new()
var _run_ui_presenter: RunUiPresenterScript = RunUiPresenterScript.new(_run_loop_coordinator)
var _stamina_fall_service: StaminaFallServiceScript = StaminaFallServiceScript.new()
var _active_touch_positions: PackedVector2Array = PackedVector2Array()
var _left_aim_preview: Line2D = null
var _right_aim_preview: Line2D = null
var _aim_target_marker: Polygon2D = null
var _debug_reset_pressed: bool = false
var _start_y: float = 0.0

func _ready() -> void:
	_validate_required_state()
	var _connect_result: int = _run_end_screen.connect(&"restart_requested", _on_run_end_restart_requested)
	var _chaser_connect_result: int = _chaser_kill_zone.connect(&"chaser_contacted", _on_chaser_contacted)
	_player.set_climb_tuning(climb_tuning)
	_stamina = StaminaRuntimeScript.new(stamina_tuning)
	_controller = ClimbPrototypeControllerScript.new(climb_tuning, _stamina)
	_chaser_pacing_model = ChaserPacingModelScript.new(_chaser_kill_zone.chaser_tuning)
	_start_y = _reset_anchor.global_position.y
	_reset_playground()
	_refresh_ui()

func _physics_process(delta: float) -> void:
	if _consume_debug_reset_input():
		_reset_playground()
		_refresh_ui()
		return

	var input_frame: PlayerInputFrameScript = _create_input_frame()
	_update_camera_follow()
	_update_chaser(delta)

	if _resolve_bottom_screen_fall_if_needed():
		_clear_aim_preview()
		_refresh_ui()
		return

	if _run_session.get_state() != RunStateScript.Value.CLIMBING:
		_clear_aim_preview()
		_refresh_ui()
		return

	var left_target: RefCounted = _find_nearest_handhold(_player.get_left_hand_anchor_global_position())
	var right_target: RefCounted = _find_nearest_handhold(_player.get_right_hand_anchor_global_position())
	var result: ClimbPrototypeFrameResultScript = _controller.apply_input_frame(input_frame, left_target, right_target, delta)

	_player.apply_frame_motion(result, _controller.get_attachment_state())
	_sync_aim_preview(input_frame)
	_record_height()

	if result.stamina_depleted_now:
		var stamina_fall_service: Object = _stamina_fall_service
		stamina_fall_service.call("resolve", _player, _run_session)
		_clear_aim_preview()

	_refresh_ui()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"debug_reset_run"):
		_reset_playground()
		_refresh_ui()
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

func get_player_for_test() -> PlayerCharacterScript:
	return _player

func get_player_body_for_test() -> RigidBody2D:
	return _player.get_player_body()

func get_left_hand_anchor_for_test() -> Marker2D:
	return _player.get_left_hand_anchor()

func get_right_hand_anchor_for_test() -> Marker2D:
	return _player.get_right_hand_anchor()

func get_chaser_for_test() -> ChaserKillZoneScript:
	return _chaser_kill_zone

func resolve_chaser_contact_for_test() -> void:
	_on_chaser_contacted(_player.get_player_body())

func sync_grip_links_for_test() -> void:
	_player.sync_runtime_grip_links(_controller.get_attachment_state())

func sync_aim_preview_for_test(input_frame: PlayerInputFrameScript) -> void:
	_sync_aim_preview(input_frame)

func get_camera_player_lower_screen_offset_for_test() -> float:
	return _get_climb_tuning_float(&"camera_player_lower_screen_offset_pixels")

func get_bottom_fall_margin_for_test() -> float:
	return _get_climb_tuning_float(&"bottom_fall_margin_pixels")

func _validate_required_state() -> void:
	Validation.require_condition(climb_tuning != null, "RunScene requires climb tuning.")
	Validation.require_condition(stamina_tuning != null, "RunScene requires stamina tuning.")
	climb_tuning.assert_valid()
	stamina_tuning.assert_valid()
	Validation.require_condition(_player != null, "RunScene requires PlayerCharacter.")
	Validation.require_condition(_chaser_kill_zone != null, "RunScene requires ChaserKillZone.")
	Validation.require_condition(_reset_anchor != null, "RunScene requires ResetAnchor.")
	Validation.require_condition(_camera != null, "RunScene requires DevCamera.")
	Validation.require_condition(_run_hud != null, "RunScene requires RunHud.")
	Validation.require_condition(_run_end_screen != null, "RunScene requires RunEndScreen.")
	Validation.require_condition(get_tree().get_nodes_in_group(climb_tuning.handhold_group_name).size() > 0, "RunScene requires at least one handhold.")

func _create_input_frame() -> PlayerInputFrameScript:
	if _active_touch_positions.size() > 0:
		return _mobile_input.create_input_frame(get_viewport_rect().size, _active_touch_positions)

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

func _update_chaser(delta: float) -> void:
	if _chaser_kill_zone == null or _chaser_pacing_model == null:
		return

	var run_state: int = _run_session.get_state()
	if run_state == RunStateScript.Value.READY or run_state == RunStateScript.Value.ENDED:
		return

	_chaser_pacing_model.record_height(_calculate_current_height_meters(), delta)
	_chaser_kill_zone.advance_rise(
		_chaser_pacing_model.get_current_rise_speed_meters_per_second(),
		_get_climb_tuning_float(&"pixels_per_meter"),
		delta
	)

func _update_camera_follow() -> void:
	_camera.global_position.y = _run_loop_coordinator.calculate_camera_target_y(
		_camera.global_position.y,
		_player.get_body_global_position().y,
		_get_climb_tuning_float(&"camera_player_lower_screen_offset_pixels"),
		_run_session.get_state()
	)

func _resolve_bottom_screen_fall_if_needed() -> bool:
	var run_loop_coordinator: Object = _run_loop_coordinator
	var should_resolve_bottom_fall: bool = run_loop_coordinator.call(
		"should_resolve_bottom_screen_fall",
		_run_session.get_state(),
		_player.get_body_global_position().y,
		_camera.global_position.y,
		get_viewport_rect().size.y,
		_get_climb_tuning_float(&"bottom_fall_margin_pixels")
	)
	if not should_resolve_bottom_fall:
		return false

	var bottom_screen_fall_service: Object = _bottom_screen_fall_service
	bottom_screen_fall_service.call("resolve", _controller, _player, _run_session)
	return true

func _find_nearest_handhold(anchor_position: Vector2) -> RefCounted:
	var nearest_target: HandholdTargetScript = null
	var nearest_distance: float = climb_tuning.handhold_detection_radius_pixels

	for handhold in get_tree().get_nodes_in_group(climb_tuning.handhold_group_name):
		Validation.require_condition(handhold is Node2D, "RunScene handholds must be Node2D instances.")
		var handhold_node: Node2D = handhold
		var distance: float = anchor_position.distance_to(handhold_node.global_position)

		if distance <= nearest_distance:
			nearest_target = HandholdTargetScript.new(StringName(handhold_node.name), handhold_node.global_position, handhold_node.get_path())
			nearest_distance = distance

	return nearest_target

func _sync_aim_preview(input_frame: PlayerInputFrameScript) -> void:
	if not input_frame.has_aim_intent():
		_clear_aim_preview()
		return

	var attachment_state: HandAttachmentState = _controller.get_attachment_state()
	var aim_intent: Object = input_frame.aim_intent
	var aim_vector: Vector2 = aim_intent.get("aim_vector")
	var aim_target_position: Vector2 = _calculate_aim_preview_target_position(aim_vector)
	var left_visible: bool = not attachment_state.is_attached(HandSideScript.Value.LEFT)
	var right_visible: bool = not attachment_state.is_attached(HandSideScript.Value.RIGHT)

	_left_aim_preview = _sync_aim_preview_line(_left_aim_preview, left_visible, _player.get_left_hand_anchor_global_position(), aim_target_position, &"LeftAimPreview")
	_right_aim_preview = _sync_aim_preview_line(_right_aim_preview, right_visible, _player.get_right_hand_anchor_global_position(), aim_target_position, &"RightAimPreview")
	_aim_target_marker = _sync_aim_target_marker(_aim_target_marker, left_visible or right_visible, aim_target_position)

func _calculate_aim_preview_target_position(aim_vector: Vector2) -> Vector2:
	Validation.require_condition(aim_vector != Vector2.ZERO, "Aim preview target requires a non-zero aim vector.")
	var preview_distance: float = maxf(160.0, climb_tuning.handhold_detection_radius_pixels * 1.75)
	var hand_midpoint: Vector2 = (_player.get_left_hand_anchor_global_position() + _player.get_right_hand_anchor_global_position()) * 0.5
	return hand_midpoint + (aim_vector.normalized() * preview_distance)

func _sync_aim_preview_line(current_line: Line2D, should_show: bool, anchor_position: Vector2, target_position: Vector2, line_name: StringName) -> Line2D:
	if not should_show:
		if current_line != null:
			current_line.queue_free()
		return null

	var active_line: Line2D = current_line
	if active_line == null:
		active_line = Line2D.new()
		active_line.name = line_name
		active_line.width = 3.0
		active_line.default_color = Color(1.0, 0.87, 0.47, 0.85)
		add_child(active_line)

	active_line.points = PackedVector2Array([
		to_local(anchor_position),
		to_local(target_position)
	])
	return active_line

func _sync_aim_target_marker(current_marker: Polygon2D, should_show: bool, target_position: Vector2) -> Polygon2D:
	if not should_show:
		if current_marker != null:
			current_marker.queue_free()
		return null

	var active_marker: Polygon2D = current_marker
	if active_marker == null:
		active_marker = Polygon2D.new()
		active_marker.name = &"AimTargetMarker"
		active_marker.color = Color(1.0, 0.95, 0.62, 0.9)
		active_marker.polygon = PackedVector2Array([Vector2(0.0, -8.0), Vector2(8.0, 0.0), Vector2(0.0, 8.0), Vector2(-8.0, 0.0)])
		add_child(active_marker)

	active_marker.global_position = target_position
	return active_marker

func _calculate_current_height_meters() -> float:
	var height_pixels: float = maxf(0.0, _start_y - _player.get_body_global_position().y)
	return height_pixels / _get_climb_tuning_float(&"pixels_per_meter")

func _record_height() -> void:
	_run_session.record_height(_calculate_current_height_meters())

func _reset_playground() -> void:
	_clear_aim_preview()

	if _controller != null:
		_controller.reset()

	_desktop_input.reset()
	_mobile_input.reset()
	_active_touch_positions = PackedVector2Array()
	_run_session = RunSessionScript.new()
	_run_session.start_run()
	if _chaser_pacing_model != null:
		_chaser_pacing_model.reset()
	_player.reset_physics(_reset_anchor.global_position)
	_camera.global_position = Vector2(
		_reset_anchor.global_position.x,
		_reset_anchor.global_position.y - _get_climb_tuning_float(&"camera_player_lower_screen_offset_pixels")
	)
	if _chaser_kill_zone != null:
		_chaser_kill_zone.reset_to_player_position(
			_player.get_body_global_position().y,
			_get_climb_tuning_float(&"pixels_per_meter"),
			_camera.global_position.x,
			get_viewport_rect().size.x
		)

func _refresh_ui() -> void:
	if _stamina == null or _run_ui_view == null:
		return

	var hud_state: RefCounted = _run_ui_presenter.build_hud_state(_run_session, _stamina)
	var run_end_state: RefCounted = _run_ui_presenter.build_run_end_screen_state(_run_session)
	_run_ui_view.apply_state_snapshots(hud_state, run_end_state)

func _on_run_end_restart_requested() -> void:
	_reset_playground()
	_refresh_ui()

func _on_chaser_contacted(body: Node) -> void:
	Validation.require_condition(body != null, "RunScene chaser contact requires a body.")
	if body != _player.get_player_body():
		return

	var run_state: int = _run_session.get_state()
	if run_state == RunStateScript.Value.READY or run_state == RunStateScript.Value.ENDED:
		return

	_chaser_contact_service.resolve(_controller, _player, _run_session)
	_clear_aim_preview()
	_refresh_ui()

func _get_climb_tuning_float(property_name: StringName) -> float:
	var property_value: Variant = climb_tuning.get(property_name)
	if property_value is float:
		return property_value

	if property_value is int:
		var int_value: int = property_value
		return float(int_value)

	Validation.require_condition(false, "Climb tuning property %s must be numeric." % String(property_name))
	return 0.0

func _clear_aim_preview() -> void:
	if _left_aim_preview != null:
		_left_aim_preview.queue_free()
		_left_aim_preview = null

	if _right_aim_preview != null:
		_right_aim_preview.queue_free()
		_right_aim_preview = null

	if _aim_target_marker != null:
		_aim_target_marker.queue_free()
		_aim_target_marker = null

func _update_touch_position(event: InputEventScreenTouch) -> void:
	if event.pressed:
		var _append_result: bool = _active_touch_positions.append(event.position)
		return

	var updated_positions: PackedVector2Array = PackedVector2Array()
	for touch_position in _active_touch_positions:
		if not touch_position.is_equal_approx(event.position):
			var _append_result: bool = updated_positions.append(touch_position)

	_active_touch_positions = updated_positions
