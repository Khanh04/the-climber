class_name GeneratedHandholdAdapter
extends StaticBody2D

const HandholdTypeScript = preload("res://src/gameplay/generation/handhold_type.gd")
const HandholdPresentationDefinitionScript = preload("res://resources/config/handhold_presentation_definition.gd")
const PresentationSceneValidatorScript = preload("res://resources/config/presentation_scene_validator.gd")

var hold_id: StringName = StringName()
var definition_id: StringName = StringName()
var handhold_type: int = HandholdTypeScript.Value.NORMAL
var stamina_drain_multiplier: float = 1.0
var body_size_pixels: Vector2 = Vector2.ZERO
var break_after_attach_seconds: float = 0.0
var breaks_on_release: bool = false
var release_impulse_vector_pixels: Vector2 = Vector2.ZERO

var _handhold_group_name: StringName = &"handhold"
var _attached_hand_count: int = 0
var _remaining_break_seconds: float = 0.0
var _is_broken: bool = false
var _presentation_definition: HandholdPresentationDefinitionScript

func configure_handhold(
	hold_id_value: StringName,
	definition_id_value: StringName,
	handhold_type_value: int,
	local_position_pixels_value: Vector2,
	body_size_pixels_value: Vector2,
	stamina_drain_multiplier_value: float,
	break_after_attach_seconds_value: float,
	breaks_on_release_value: bool,
	release_impulse_vector_pixels_value: Vector2,
	presentation_definition_value: HandholdPresentationDefinitionScript,
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
	Validation.require_condition(
		break_after_attach_seconds_value >= 0.0,
		"GeneratedHandholdAdapter break-after-attach seconds cannot be negative."
	)
	Validation.require_condition(presentation_definition_value != null, "GeneratedHandholdAdapter requires a presentation definition.")
	presentation_definition_value.assert_valid()
	Validation.require_condition(
		presentation_definition_value.handhold_type == handhold_type_value,
		"GeneratedHandholdAdapter presentation type must match its gameplay type."
	)
	Validation.require_condition(not String(handhold_group_name_value).is_empty(), "GeneratedHandholdAdapter requires a handhold group name.")
	Validation.require_condition(collision_layer_value > 0, "GeneratedHandholdAdapter collision layer must be positive.")
	Validation.require_condition(collision_mask_value >= 0, "GeneratedHandholdAdapter collision mask cannot be negative.")

	hold_id = hold_id_value
	definition_id = definition_id_value
	handhold_type = handhold_type_value
	stamina_drain_multiplier = stamina_drain_multiplier_value
	body_size_pixels = body_size_pixels_value
	break_after_attach_seconds = break_after_attach_seconds_value
	breaks_on_release = breaks_on_release_value
	release_impulse_vector_pixels = release_impulse_vector_pixels_value
	_presentation_definition = presentation_definition_value
	_handhold_group_name = handhold_group_name_value
	_attached_hand_count = 0
	_remaining_break_seconds = break_after_attach_seconds
	_is_broken = false
	position = local_position_pixels_value
	collision_layer = collision_layer_value
	collision_mask = collision_mask_value
	add_to_group(handhold_group_name_value)
	set_meta(&"definition_id", String(definition_id))
	set_meta(&"handhold_type", HandholdTypeScript.to_label(handhold_type))
	set_meta(&"stamina_drain_multiplier", stamina_drain_multiplier)
	set_meta(&"body_width_pixels", body_size_pixels.x)
	set_meta(&"body_height_pixels", body_size_pixels.y)
	set_meta(&"break_after_attach_seconds", break_after_attach_seconds)
	set_meta(&"breaks_on_release", breaks_on_release)
	set_meta(&"release_impulse_x", release_impulse_vector_pixels.x)
	set_meta(&"release_impulse_y", release_impulse_vector_pixels.y)
	set_meta(&"is_broken", false)
	_ensure_runtime_nodes()

func _ready() -> void:
	_validate_required_state()
	_ensure_runtime_nodes()

func get_body_size_pixels() -> Vector2:
	return body_size_pixels

func get_release_impulse_vector_pixels() -> Vector2:
	return release_impulse_vector_pixels

func is_broken() -> bool:
	return _is_broken

func notify_hand_attached() -> void:
	Validation.require_condition(not _is_broken, "GeneratedHandholdAdapter cannot attach to a broken handhold.")
	_attached_hand_count += 1
	if _attached_hand_count == 1:
		_remaining_break_seconds = break_after_attach_seconds

func notify_hand_released() -> Vector2:
	Validation.require_condition(_attached_hand_count > 0, "GeneratedHandholdAdapter cannot release a hand when none are attached.")
	_attached_hand_count -= 1
	if _attached_hand_count > 0:
		return Vector2.ZERO

	_remaining_break_seconds = break_after_attach_seconds
	var release_impulse: Vector2 = release_impulse_vector_pixels
	if breaks_on_release and not _is_broken:
		_break_handhold()
	return release_impulse

func advance_attached_lifecycle(delta_seconds: float) -> bool:
	Validation.require_condition(delta_seconds >= 0.0, "GeneratedHandholdAdapter lifecycle advance cannot use a negative delta.")
	if _is_broken or _attached_hand_count <= 0 or break_after_attach_seconds <= 0.0:
		return false

	_remaining_break_seconds -= delta_seconds
	if _remaining_break_seconds > 0.0:
		return false

	_break_handhold()
	return true

func _validate_required_state() -> void:
	Validation.require_condition(not String(hold_id).is_empty(), "GeneratedHandholdAdapter must be configured before entering the scene tree.")
	Validation.require_condition(not String(definition_id).is_empty(), "GeneratedHandholdAdapter definition id must be configured before entering the scene tree.")
	HandholdTypeScript.assert_valid(handhold_type)
	Validation.require_condition(stamina_drain_multiplier > 0.0, "GeneratedHandholdAdapter stamina drain multiplier must remain positive.")
	Validation.require_condition(
		break_after_attach_seconds >= 0.0,
		"GeneratedHandholdAdapter break-after-attach seconds must remain non-negative."
	)
	Validation.require_condition(
		body_size_pixels.x > 0.0 and body_size_pixels.y > 0.0,
		"GeneratedHandholdAdapter body size must remain positive."
	)
	Validation.require_condition(get_node_or_null("CollisionShape2D") is CollisionShape2D, "GeneratedHandholdAdapter requires CollisionShape2D.")
	Validation.require_condition(get_node_or_null("PresentationRoot") is Node2D, "GeneratedHandholdAdapter requires PresentationRoot.")
	Validation.require_condition(get_node_or_null("PresentationRoot/Asset") is Node2D, "GeneratedHandholdAdapter requires a presentation asset.")
	PresentationSceneValidatorScript.assert_live_tree_valid(
		get_node("PresentationRoot/Asset"),
		"Generated handhold %s" % String(hold_id)
	)

func _ensure_runtime_nodes() -> void:
	var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape == null:
		collision_shape = CollisionShape2D.new()
		collision_shape.name = &"CollisionShape2D"
		add_child(collision_shape)

	var presentation_root: Node2D = get_node_or_null("PresentationRoot") as Node2D
	if presentation_root == null:
		presentation_root = Node2D.new()
		presentation_root.name = &"PresentationRoot"
		add_child(presentation_root)

	if presentation_root.get_node_or_null("Asset") == null:
		Validation.require_condition(_presentation_definition != null, "GeneratedHandholdAdapter requires presentation before creating runtime nodes.")
		var presentation: Node2D = _presentation_definition.instantiate_presentation()
		presentation.name = &"Asset"
		presentation_root.add_child(presentation)
	presentation_root.visible = not _is_broken

	# The passive collider mirrors the presentation art's drawn size so the player collides with
	# exactly what is on screen. body_size_pixels (the route-planning footprint from
	# physical_size_meters) is the fallback when there is no measurable sprite yet -- an animated
	# presentation seen before its SpriteFrames are built, or a placeholder Polygon2D scene.
	var rectangle_shape: RectangleShape2D = RectangleShape2D.new()
	rectangle_shape.size = _resolve_collider_size_pixels(presentation_root.get_node_or_null("Asset") as Node2D)
	collision_shape.shape = rectangle_shape


func _resolve_collider_size_pixels(asset: Node2D) -> Vector2:
	if asset == null:
		return body_size_pixels
	var measured: Vector2 = _measure_presentation_size_pixels(asset)
	if measured.x > 0.0 and measured.y > 0.0:
		return measured
	return body_size_pixels


func _measure_presentation_size_pixels(node: Node) -> Vector2:
	var intrinsic: Vector2 = _visual_intrinsic_size_pixels(node)
	if intrinsic.x > 0.0 and intrinsic.y > 0.0:
		var presentation_scale: Vector2 = Vector2.ONE
		if _presentation_definition != null:
			presentation_scale = _presentation_definition.visual_scale
		return (intrinsic * presentation_scale).abs()
	for child in node.get_children():
		var child_size: Vector2 = _measure_presentation_size_pixels(child)
		if child_size.x > 0.0 and child_size.y > 0.0:
			return child_size
	return Vector2.ZERO


func _visual_intrinsic_size_pixels(node: Node) -> Vector2:
	if node is Sprite2D:
		var sprite: Sprite2D = node
		if sprite.texture == null:
			return Vector2.ZERO
		var sprite_size: Vector2 = sprite.region_rect.size if sprite.region_enabled else sprite.texture.get_size()
		return (sprite_size * sprite.scale).abs()
	if node is AnimatedSprite2D:
		var animated: AnimatedSprite2D = node
		var frames: SpriteFrames = animated.sprite_frames
		if frames == null or not frames.has_animation(animated.animation) or frames.get_frame_count(animated.animation) == 0:
			return Vector2.ZERO
		var frame_texture: Texture2D = frames.get_frame_texture(animated.animation, 0)
		if frame_texture == null:
			return Vector2.ZERO
		return (frame_texture.get_size() * animated.scale).abs()
	if node is Polygon2D:
		var points: PackedVector2Array = (node as Polygon2D).polygon
		if points.size() < 3:
			return Vector2.ZERO
		var bounds: Rect2 = Rect2(points[0], Vector2.ZERO)
		for point in points:
			bounds = bounds.expand(point)
		return (bounds.size * (node as Polygon2D).scale).abs()
	return Vector2.ZERO

func _break_handhold() -> void:
	if _is_broken:
		return

	_is_broken = true
	_attached_hand_count = 0
	_remaining_break_seconds = 0.0
	set_meta(&"is_broken", true)
	if is_in_group(_handhold_group_name):
		remove_from_group(_handhold_group_name)

	var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape != null:
		collision_shape.disabled = true

	var presentation_root: Node2D = get_node_or_null("PresentationRoot") as Node2D
	if presentation_root != null:
		presentation_root.visible = false
