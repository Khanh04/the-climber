class_name GeneratedHandholdAdapter
extends StaticBody2D

const HandholdTypeScript = preload("res://src/gameplay/generation/handhold_type.gd")

var hold_id: StringName = StringName()
var definition_id: StringName = StringName()
var handhold_type: int = HandholdTypeScript.Value.NORMAL
var stamina_drain_multiplier: float = 1.0
var body_size_pixels: Vector2 = Vector2.ZERO

func configure_handhold(
	hold_id_value: StringName,
	definition_id_value: StringName,
	handhold_type_value: int,
	local_position_pixels_value: Vector2,
	body_size_pixels_value: Vector2,
	stamina_drain_multiplier_value: float,
	handhold_group_name_value: StringName = &"handhold",
	collision_layer_value: int = 2,
	collision_mask_value: int = 0
) -> void:
	Validation.require_condition(not String(hold_id_value).is_empty(), "GeneratedHandholdAdapter requires a hold id.")
	Validation.require_condition(not String(definition_id_value).is_empty(), "GeneratedHandholdAdapter requires a definition id.")
	HandholdTypeScript.assert_valid(handhold_type_value)
	Validation.require_condition(
		body_size_pixels_value.x > 0.0 and body_size_pixels_value.y > 0.0,
		"GeneratedHandholdAdapter body size must be positive."
	)
	Validation.require_condition(
		stamina_drain_multiplier_value > 0.0,
		"GeneratedHandholdAdapter stamina drain multiplier must be positive."
	)
	Validation.require_condition(not String(handhold_group_name_value).is_empty(), "GeneratedHandholdAdapter requires a handhold group name.")
	Validation.require_condition(collision_layer_value > 0, "GeneratedHandholdAdapter collision layer must be positive.")
	Validation.require_condition(collision_mask_value >= 0, "GeneratedHandholdAdapter collision mask cannot be negative.")

	hold_id = hold_id_value
	definition_id = definition_id_value
	handhold_type = handhold_type_value
	stamina_drain_multiplier = stamina_drain_multiplier_value
	body_size_pixels = body_size_pixels_value
	position = local_position_pixels_value
	collision_layer = collision_layer_value
	collision_mask = collision_mask_value
	add_to_group(handhold_group_name_value)
	set_meta(&"definition_id", String(definition_id))
	set_meta(&"handhold_type", HandholdTypeScript.to_label(handhold_type))
	set_meta(&"stamina_drain_multiplier", stamina_drain_multiplier)
	set_meta(&"body_width_pixels", body_size_pixels.x)
	set_meta(&"body_height_pixels", body_size_pixels.y)
	_ensure_presentation()

func _ready() -> void:
	_validate_required_state()

func get_body_size_pixels() -> Vector2:
	return body_size_pixels

func _validate_required_state() -> void:
	Validation.require_condition(not String(hold_id).is_empty(), "GeneratedHandholdAdapter must be configured before entering the scene tree.")
	Validation.require_condition(not String(definition_id).is_empty(), "GeneratedHandholdAdapter definition id must be configured before entering the scene tree.")
	HandholdTypeScript.assert_valid(handhold_type)
	Validation.require_condition(stamina_drain_multiplier > 0.0, "GeneratedHandholdAdapter stamina drain multiplier must remain positive.")
	Validation.require_condition(
		body_size_pixels.x > 0.0 and body_size_pixels.y > 0.0,
		"GeneratedHandholdAdapter body size must remain positive."
	)
	Validation.require_condition(get_node_or_null("CollisionShape2D") is CollisionShape2D, "GeneratedHandholdAdapter requires CollisionShape2D.")
	Validation.require_condition(get_node_or_null("Visual") is Polygon2D, "GeneratedHandholdAdapter requires Visual.")

func _ensure_presentation() -> void:
	var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape == null:
		collision_shape = CollisionShape2D.new()
		collision_shape.name = &"CollisionShape2D"
		add_child(collision_shape)

	var rectangle_shape: RectangleShape2D = RectangleShape2D.new()
	rectangle_shape.size = body_size_pixels
	collision_shape.shape = rectangle_shape

	var visual: Polygon2D = get_node_or_null("Visual") as Polygon2D
	if visual == null:
		visual = Polygon2D.new()
		visual.name = &"Visual"
		add_child(visual)

	visual.color = HandholdTypeScript.get_default_color(handhold_type)
	visual.polygon = _build_rectangle_polygon(body_size_pixels)

func _build_rectangle_polygon(size_pixels: Vector2) -> PackedVector2Array:
	var half_width: float = size_pixels.x * 0.5
	var half_height: float = size_pixels.y * 0.5
	return PackedVector2Array([
		Vector2(-half_width, -half_height),
		Vector2(half_width, -half_height),
		Vector2(half_width, half_height),
		Vector2(-half_width, half_height),
	])