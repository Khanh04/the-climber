class_name ChaserKillZone
extends Area2D

const ChaserTuningScript = preload("res://resources/config/chaser_tuning.gd")

signal chaser_contacted(body: Node)

@export var chaser_tuning: ChaserTuningScript
@export var width_padding_pixels: float = 256.0
@export var kill_zone_height_pixels: float = 192.0

@onready var _collision_shape: CollisionShape2D = get_node("CollisionShape2D") as CollisionShape2D
@onready var _visual: Polygon2D = get_node("Visual") as Polygon2D

func _ready() -> void:
	_validate_required_state()

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
	_resize_to_cover_width(_get_rectangle_shape().size.x)

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

func _on_body_entered(body: Node) -> void:
	Validation.require_condition(body != null, "ChaserKillZone body_entered requires a body.")
	chaser_contacted.emit(body)