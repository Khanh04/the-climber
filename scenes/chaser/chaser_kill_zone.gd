class_name ChaserKillZone
extends Area2D

const ChaserFeedbackSnapshotScript = preload("res://src/gameplay/chaser/chaser_feedback_snapshot.gd")
const ChaserThemeScript = preload("res://resources/config/chaser_theme.gd")
const ChaserTuningScript = preload("res://resources/config/chaser_tuning.gd")

signal chaser_contacted(body: Node)
signal feedback_intensity_changed(intensity_ratio: float)

@export var chaser_tuning: ChaserTuningScript
@export var chaser_theme: ChaserThemeScript
@export var width_padding_pixels: float = 256.0
@export var kill_zone_height_pixels: float = 192.0

@onready var _collision_shape: CollisionShape2D = get_node("CollisionShape2D") as CollisionShape2D
@onready var _glow_visual: Polygon2D = get_node("GlowVisual") as Polygon2D
@onready var _visual: Polygon2D = get_node("Visual") as Polygon2D
@onready var _crest_visual: Polygon2D = get_node("CrestVisual") as Polygon2D
@onready var _audio_player: AudioStreamPlayer2D = get_node("IntensityAudioPlayer") as AudioStreamPlayer2D
@onready var _animated_sprite: AnimatedSprite2D = get_node("AnimatedSprite2D") as AnimatedSprite2D

var _feedback_intensity_ratio: float = -1.0
var _presentation_time_seconds: float = 0.0

func _ready() -> void:
	_validate_required_state()
	set_process(true)

func _process(delta: float) -> void:
	Validation.require_condition(delta >= 0.0, "ChaserKillZone process delta cannot be negative.")
	if _feedback_intensity_ratio < 0.0:
		return

	_presentation_time_seconds += delta
	_refresh_presentation()

func _exit_tree() -> void:
	if _audio_player == null:
		return

	if _audio_player.playing:
		_audio_player.stop()

func apply_theme(theme: Resource) -> void:
	chaser_theme = _require_theme(theme)
	if not is_node_ready():
		return

	_apply_theme_resource()
	_resize_to_cover_width(_get_rectangle_shape().size.x)
	_presentation_time_seconds = 0.0
	_refresh_audio_feedback()
	_refresh_presentation()

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
	Validation.require_condition(chaser_theme != null, "ChaserKillZone requires a chaser theme.")
	chaser_theme.assert_valid()
	Validation.require_condition(width_padding_pixels >= 0.0, "ChaserKillZone width padding cannot be negative.")
	Validation.require_condition(kill_zone_height_pixels > 0.0, "ChaserKillZone height must be positive.")
	Validation.require_condition(_collision_shape != null, "ChaserKillZone requires CollisionShape2D.")
	Validation.require_condition(_collision_shape.shape != null, "ChaserKillZone CollisionShape2D requires a shape.")
	Validation.require_condition(_collision_shape.shape is RectangleShape2D, "ChaserKillZone requires a RectangleShape2D collision shape.")
	Validation.require_condition(_glow_visual != null, "ChaserKillZone requires GlowVisual.")
	Validation.require_condition(_visual != null, "ChaserKillZone requires Visual.")
	Validation.require_condition(_crest_visual != null, "ChaserKillZone requires CrestVisual.")
	Validation.require_condition(_audio_player != null, "ChaserKillZone requires IntensityAudioPlayer.")
	Validation.require_condition(_animated_sprite != null, "ChaserKillZone requires AnimatedSprite2D.")
	_apply_theme_resource()
	Validation.require_condition(_audio_player.stream != null, "ChaserKillZone requires an assigned audio loop stream.")
	Validation.require_condition(_animated_sprite.sprite_frames != null, "ChaserKillZone requires assigned chaser sprite frames.")
	_resize_to_cover_width(_get_rectangle_shape().size.x)
	_apply_feedback_intensity(0.0)

func _resize_to_cover_width(width_pixels: float) -> void:
	Validation.require_condition(width_pixels > 0.0, "ChaserKillZone width must be positive.")
	var shape: RectangleShape2D = _get_rectangle_shape()
	shape.size = Vector2(width_pixels, kill_zone_height_pixels)
	var glow_width_pixels: float = width_pixels + chaser_theme.glow_extra_width_pixels
	var glow_height_pixels: float = kill_zone_height_pixels + chaser_theme.glow_extra_height_pixels
	_glow_visual.polygon = PackedVector2Array([
		Vector2(-glow_width_pixels * 0.5, -glow_height_pixels * 0.5),
		Vector2(glow_width_pixels * 0.5, -glow_height_pixels * 0.5),
		Vector2(glow_width_pixels * 0.5, glow_height_pixels * 0.5),
		Vector2(-glow_width_pixels * 0.5, glow_height_pixels * 0.5),
	])
	_visual.polygon = PackedVector2Array([
		Vector2(-width_pixels * 0.5, -kill_zone_height_pixels * 0.5),
		Vector2(width_pixels * 0.5, -kill_zone_height_pixels * 0.5),
		Vector2(width_pixels * 0.5, kill_zone_height_pixels * 0.5),
		Vector2(-width_pixels * 0.5, kill_zone_height_pixels * 0.5),
	])
	var crest_half_width_pixels: float = maxf(0.0, (width_pixels * 0.5) - chaser_theme.crest_side_inset_pixels)
	_crest_visual.polygon = PackedVector2Array([
		Vector2(-crest_half_width_pixels, -chaser_theme.crest_height_pixels * 0.5),
		Vector2(crest_half_width_pixels, -chaser_theme.crest_height_pixels * 0.5),
		Vector2(crest_half_width_pixels, chaser_theme.crest_height_pixels * 0.5),
		Vector2(-crest_half_width_pixels, chaser_theme.crest_height_pixels * 0.5),
	])

	if _feedback_intensity_ratio >= 0.0:
		_refresh_presentation()

func _get_rectangle_shape() -> RectangleShape2D:
	Validation.require_condition(_collision_shape.shape is RectangleShape2D, "ChaserKillZone requires a RectangleShape2D collision shape.")
	return _collision_shape.shape as RectangleShape2D

func _apply_feedback_intensity(intensity_ratio: float) -> void:
	Validation.require_condition(intensity_ratio >= 0.0 and intensity_ratio <= 1.0, "ChaserKillZone feedback intensity ratio must be between 0.0 and 1.0.")

	if is_equal_approx(_feedback_intensity_ratio, intensity_ratio):
		return

	_feedback_intensity_ratio = intensity_ratio
	_refresh_audio_feedback()
	_refresh_presentation()
	feedback_intensity_changed.emit(intensity_ratio)

func _apply_theme_resource() -> void:
	_audio_player.stream = chaser_theme.audio_loop_stream
	_animated_sprite.sprite_frames = chaser_theme.chaser_sprite_frames
	_animated_sprite.play(&"chase")

func _refresh_audio_feedback() -> void:
	if _feedback_intensity_ratio < 0.0:
		return

	var volume_intensity_ratio: float = chaser_theme.evaluate_audio_volume_intensity_ratio(_feedback_intensity_ratio)
	var pitch_intensity_ratio: float = chaser_theme.evaluate_audio_pitch_intensity_ratio(_feedback_intensity_ratio)
	_audio_player.volume_db = lerpf(chaser_tuning.min_audio_volume_db, chaser_tuning.max_audio_volume_db, volume_intensity_ratio)
	_audio_player.pitch_scale = lerpf(chaser_tuning.min_audio_pitch_scale, chaser_tuning.max_audio_pitch_scale, pitch_intensity_ratio)

func _refresh_presentation() -> void:
	var pulse_frequency_hz: float = lerpf(chaser_theme.pulse_min_frequency_hz, chaser_theme.pulse_max_frequency_hz, _feedback_intensity_ratio)
	var pulse_ratio: float = 0.5 + (0.5 * sin(TAU * pulse_frequency_hz * _presentation_time_seconds))

	var visual_color: Color = chaser_theme.base_fill_color.lerp(chaser_theme.high_pressure_fill_color, _feedback_intensity_ratio * 0.75)
	visual_color.a = lerpf(chaser_tuning.min_visual_alpha, chaser_tuning.max_visual_alpha, _feedback_intensity_ratio)
	_visual.color = visual_color

	var glow_color: Color = chaser_theme.glow_color
	var glow_alpha: float = lerpf(chaser_theme.glow_min_alpha, chaser_theme.glow_max_alpha, _feedback_intensity_ratio) * lerpf(0.82, 1.18, pulse_ratio)
	glow_color.a = clampf(glow_alpha, 0.0, 1.0)
	_glow_visual.color = glow_color
	var glow_scale: float = 1.0 + (chaser_theme.glow_max_scale_delta * _feedback_intensity_ratio * pulse_ratio)
	_glow_visual.scale = Vector2(glow_scale, glow_scale)

	var crest_color: Color = chaser_theme.crest_color
	var crest_alpha: float = lerpf(chaser_theme.crest_min_alpha, chaser_theme.crest_max_alpha, _feedback_intensity_ratio) * lerpf(0.80, 1.20, pulse_ratio)
	crest_color.a = clampf(crest_alpha, 0.0, 1.0)
	_crest_visual.color = crest_color
	_crest_visual.scale = Vector2(1.0, 1.0 + (chaser_theme.crest_max_scale_delta * _feedback_intensity_ratio * pulse_ratio))
	_crest_visual.position = Vector2(
		0.0,
		(-kill_zone_height_pixels * 0.5) + (chaser_theme.crest_height_pixels * 0.5) - (chaser_theme.crest_max_lift_pixels * _feedback_intensity_ratio * pulse_ratio)
	)

func _require_theme(theme: Resource) -> ChaserThemeScript:
	Validation.require_condition(theme != null, "ChaserKillZone requires a ChaserTheme resource.")
	Validation.require_condition(theme is ChaserThemeScript, "ChaserKillZone theme must implement ChaserTheme.")
	var typed_theme: ChaserThemeScript = theme as ChaserThemeScript
	typed_theme.assert_valid()
	return typed_theme

func _ensure_audio_playback() -> void:
	if not _audio_player.playing:
		_audio_player.play()

func _should_use_runtime_audio() -> bool:
	return DisplayServer.get_name() != "headless"

func _on_body_entered(body: Node) -> void:
	Validation.require_condition(body != null, "ChaserKillZone body_entered requires a body.")
	chaser_contacted.emit(body)
