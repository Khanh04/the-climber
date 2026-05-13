class_name ChaserKillZone
extends Area2D

const ChaserFeedbackSnapshotScript = preload("res://src/gameplay/chaser/chaser_feedback_snapshot.gd")
const ChaserTuningScript = preload("res://resources/config/chaser_tuning.gd")

signal chaser_contacted(body: Node)
signal feedback_intensity_changed(intensity_ratio: float)

@export var chaser_tuning: ChaserTuningScript
@export var width_padding_pixels: float = 256.0
@export var kill_zone_height_pixels: float = 192.0

@onready var _collision_shape: CollisionShape2D = get_node("CollisionShape2D") as CollisionShape2D
@onready var _visual: Polygon2D = get_node("Visual") as Polygon2D
@onready var _audio_player: AudioStreamPlayer2D = get_node("IntensityAudioPlayer") as AudioStreamPlayer2D

var _feedback_intensity_ratio: float = -1.0

func _ready() -> void:
	_validate_required_state()

func _exit_tree() -> void:
	if _audio_player == null:
		return

	if _audio_player.playing:
		_audio_player.stop()

func reset_to_player_position(player_body_y: float, pixels_per_meter: float, center_x: float, viewport_width: float) -> void:
	Validation.require_condition(pixels_per_meter > 0.0, "ChaserKillZone pixels per meter must be positive.")
	Validation.require_condition(viewport_width > 0.0, "ChaserKillZone viewport width must be positive.")

	_resize_to_cover_width(viewport_width + width_padding_pixels)
	var spawn_offset_pixels: float = chaser_tuning.initial_spawn_offset_meters * pixels_per_meter
	global_position = Vector2(center_x, player_body_y + spawn_offset_pixels + (kill_zone_height_pixels * 0.5))

func advance_rise(rise_speed_meters_per_second: float, pixels_per_meter: float, delta_seconds: float) -> void:
	Validation.require_condition(rise_speed_meters_per_second >= 0.0, "ChaserKillZone rise speed cannot be negative.")
	Validation.require_condition(pixels_per_meter > 0.0, "ChaserKillZone pixels per meter must be positive.")
	Validation.require_condition(delta_seconds >= 0.0, "ChaserKillZone delta seconds cannot be negative.")

	global_position.y -= rise_speed_meters_per_second * pixels_per_meter * delta_seconds

func sync_feedback(feedback_snapshot: RefCounted, player_body_y: float, pixels_per_meter: float) -> void:
	Validation.require_condition(feedback_snapshot != null, "ChaserKillZone feedback sync requires a snapshot.")
	Validation.require_condition(feedback_snapshot is ChaserFeedbackSnapshotScript, "ChaserKillZone feedback sync requires a ChaserFeedbackSnapshot implementation.")
	Validation.require_condition(pixels_per_meter > 0.0, "ChaserKillZone pixels per meter must be positive.")

	if _should_use_runtime_audio():
		_ensure_audio_playback()

	var typed_feedback_snapshot: ChaserFeedbackSnapshotScript = feedback_snapshot as ChaserFeedbackSnapshotScript
	typed_feedback_snapshot.assert_valid()

	var proximity_intensity_ratio: float = calculate_proximity_intensity_ratio(player_body_y, pixels_per_meter)
	var next_feedback_intensity_ratio: float = maxf(typed_feedback_snapshot.speed_intensity_ratio, proximity_intensity_ratio)
	_apply_feedback_intensity(next_feedback_intensity_ratio)

func calculate_proximity_intensity_ratio(player_body_y: float, pixels_per_meter: float) -> float:
	Validation.require_condition(pixels_per_meter > 0.0, "ChaserKillZone pixels per meter must be positive.")

	var distance_to_player_meters: float = maxf(0.0, get_top_edge_y() - player_body_y) / pixels_per_meter
	if distance_to_player_meters <= chaser_tuning.near_distance_for_max_intensity_meters:
		return 1.0

	if distance_to_player_meters >= chaser_tuning.far_distance_for_min_intensity_meters:
		return 0.0

	return 1.0 - inverse_lerp(
		chaser_tuning.near_distance_for_max_intensity_meters,
		chaser_tuning.far_distance_for_min_intensity_meters,
		distance_to_player_meters
	)

func get_feedback_intensity_ratio() -> float:
	return _feedback_intensity_ratio

func get_top_edge_y() -> float:
	return global_position.y - (kill_zone_height_pixels * 0.5)

func get_collision_width_pixels() -> float:
	return _get_rectangle_shape().size.x

func get_collision_height_pixels() -> float:
	return _get_rectangle_shape().size.y

func _validate_required_state() -> void:
	Validation.require_condition(chaser_tuning != null, "ChaserKillZone requires chaser tuning.")
	chaser_tuning.assert_valid()
	Validation.require_condition(width_padding_pixels >= 0.0, "ChaserKillZone width padding cannot be negative.")
	Validation.require_condition(kill_zone_height_pixels > 0.0, "ChaserKillZone height must be positive.")
	Validation.require_condition(_collision_shape != null, "ChaserKillZone requires CollisionShape2D.")
	Validation.require_condition(_collision_shape.shape != null, "ChaserKillZone CollisionShape2D requires a shape.")
	Validation.require_condition(_collision_shape.shape is RectangleShape2D, "ChaserKillZone requires a RectangleShape2D collision shape.")
	Validation.require_condition(_visual != null, "ChaserKillZone requires Visual.")
	Validation.require_condition(_audio_player != null, "ChaserKillZone requires IntensityAudioPlayer.")
	Validation.require_condition(_audio_player.stream != null, "ChaserKillZone requires an assigned audio loop stream.")
	_resize_to_cover_width(_get_rectangle_shape().size.x)
	_apply_feedback_intensity(0.0)

func _resize_to_cover_width(width_pixels: float) -> void:
	Validation.require_condition(width_pixels > 0.0, "ChaserKillZone width must be positive.")
	var shape: RectangleShape2D = _get_rectangle_shape()
	shape.size = Vector2(width_pixels, kill_zone_height_pixels)
	_visual.polygon = PackedVector2Array([
		Vector2(-width_pixels * 0.5, -kill_zone_height_pixels * 0.5),
		Vector2(width_pixels * 0.5, -kill_zone_height_pixels * 0.5),
		Vector2(width_pixels * 0.5, kill_zone_height_pixels * 0.5),
		Vector2(-width_pixels * 0.5, kill_zone_height_pixels * 0.5),
	])

func _get_rectangle_shape() -> RectangleShape2D:
	Validation.require_condition(_collision_shape.shape is RectangleShape2D, "ChaserKillZone requires a RectangleShape2D collision shape.")
	return _collision_shape.shape as RectangleShape2D

func _apply_feedback_intensity(intensity_ratio: float) -> void:
	Validation.require_condition(intensity_ratio >= 0.0 and intensity_ratio <= 1.0, "ChaserKillZone feedback intensity ratio must be between 0.0 and 1.0.")

	if is_equal_approx(_feedback_intensity_ratio, intensity_ratio):
		return

	_feedback_intensity_ratio = intensity_ratio
	var visual_color: Color = _visual.color
	visual_color.a = lerpf(chaser_tuning.min_visual_alpha, chaser_tuning.max_visual_alpha, intensity_ratio)
	_visual.color = visual_color
	_audio_player.volume_db = lerpf(chaser_tuning.min_audio_volume_db, chaser_tuning.max_audio_volume_db, intensity_ratio)
	_audio_player.pitch_scale = lerpf(chaser_tuning.min_audio_pitch_scale, chaser_tuning.max_audio_pitch_scale, intensity_ratio)
	feedback_intensity_changed.emit(intensity_ratio)

func _ensure_audio_playback() -> void:
	if not _audio_player.playing:
		_audio_player.play()

func _should_use_runtime_audio() -> bool:
	return DisplayServer.get_name() != "headless"

func _on_body_entered(body: Node) -> void:
	Validation.require_condition(body != null, "ChaserKillZone body_entered requires a body.")
	chaser_contacted.emit(body)