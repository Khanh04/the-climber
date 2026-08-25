class_name GeneratedHazardSpawnAdapter
extends Area2D

const GeneratedHazardKindScript = preload("res://src/gameplay/generation/generated_hazard_kind.gd")
const SpriteFrameSequenceLoaderScript = preload("res://src/core/sprite_frame_sequence_loader.gd")

signal triggered(body: Node)

const GROUP_NAME: StringName = &"generated_hazard"
const WIND_GUST_ANIMATION_FRAME_PATH_FORMAT: String = "res://assets/PNG/UI/run_sence/obstacles/wind_animation/wind/frame_%02d.png"
const WIND_GUST_ANIMATION_FRAME_COUNT: int = 50
const WIND_GUST_ANIMATION_NAME: StringName = &"wind"
const WIND_GUST_ANIMATION_FRAMES_PER_SECOND: float = 30.0
const SPIKE_CLUSTER_GROUP_NAME: StringName = &"generated_spike_cluster_hazard"
const WIND_GUST_GROUP_NAME: StringName = &"generated_wind_gust_hazard"
const DOWNDRAFT_GROUP_NAME: StringName = &"generated_downdraft_hazard"
const UPDRAFT_GROUP_NAME: StringName = &"generated_updraft_hazard"

var socket_id: StringName = StringName()
var hazard_kind: int = -1
var impulse_vector_pixels: Vector2 = Vector2.ZERO

func configure_hazard(
	socket_id_value: StringName,
	hazard_kind_value: int,
	local_position_pixels_value: Vector2,
	impulse_vector_pixels_value: Vector2 = Vector2.ZERO,
	collision_layer_value: int = 16,
	collision_mask_value: int = 1
) -> void:
	Validation.require_condition(not String(socket_id_value).is_empty(), "GeneratedHazardSpawnAdapter requires a socket id.")
	GeneratedHazardKindScript.assert_valid(hazard_kind_value)
	Validation.require_condition(collision_layer_value > 0, "GeneratedHazardSpawnAdapter collision layer must be positive.")
	Validation.require_condition(collision_mask_value > 0, "GeneratedHazardSpawnAdapter collision mask must be positive.")
	if _hazard_kind_requires_impulse_vector(hazard_kind_value):
		Validation.require_condition(impulse_vector_pixels_value != Vector2.ZERO, "GeneratedHazardSpawnAdapter force hazards require a non-zero impulse vector.")

	socket_id = socket_id_value
	hazard_kind = hazard_kind_value
	impulse_vector_pixels = impulse_vector_pixels_value
	position = local_position_pixels_value
	collision_layer = collision_layer_value
	collision_mask = collision_mask_value
	monitoring = true
	monitorable = true
	add_to_group(GROUP_NAME)
	add_to_group(_get_specific_group_name())
	set_meta(&"socket_kind", &"hazard")
	set_meta(&"hazard_kind", GeneratedHazardKindScript.to_label(hazard_kind))
	set_meta(&"impulse_vector_x", impulse_vector_pixels.x)
	set_meta(&"impulse_vector_y", impulse_vector_pixels.y)
	_ensure_presentation()

func _ready() -> void:
	_validate_required_state()
	if not body_entered.is_connected(_on_body_entered):
		var _connect_result: int = body_entered.connect(_on_body_entered)

func _validate_required_state() -> void:
	Validation.require_condition(not String(socket_id).is_empty(), "GeneratedHazardSpawnAdapter must be configured before entering the scene tree.")
	GeneratedHazardKindScript.assert_valid(hazard_kind)
	if _hazard_kind_requires_impulse_vector(hazard_kind):
		Validation.require_condition(impulse_vector_pixels != Vector2.ZERO, "GeneratedHazardSpawnAdapter force hazards require a non-zero impulse vector.")
	Validation.require_condition(get_node_or_null("CollisionShape2D") is CollisionShape2D, "GeneratedHazardSpawnAdapter requires CollisionShape2D.")
	Validation.require_condition(get_node_or_null("Visual") is Polygon2D, "GeneratedHazardSpawnAdapter requires Visual.")
	if hazard_kind == GeneratedHazardKindScript.Value.WIND_GUST:
		Validation.require_condition(get_node_or_null("AnimatedSprite2D") is AnimatedSprite2D, "GeneratedHazardSpawnAdapter wind gust hazards require AnimatedSprite2D.")

func get_impulse_vector_pixels() -> Vector2:
	return impulse_vector_pixels

func _build_collision_shape() -> Shape2D:
	var rectangle_shape: RectangleShape2D = RectangleShape2D.new()
	rectangle_shape.size = _get_collision_size_for_kind()
	return rectangle_shape

func _build_visual_polygon() -> PackedVector2Array:
	match hazard_kind:
		GeneratedHazardKindScript.Value.SPIKE_CLUSTER:
			return PackedVector2Array([
				Vector2(0.0, -12.0),
				Vector2(11.0, 10.0),
				Vector2(-11.0, 10.0),
			])
		GeneratedHazardKindScript.Value.WIND_GUST:
			return PackedVector2Array([
				Vector2(-22.0, -16.0),
				Vector2(10.0, -16.0),
				Vector2(24.0, 0.0),
				Vector2(10.0, 16.0),
				Vector2(-22.0, 16.0),
				Vector2(-8.0, 0.0),
			])
		GeneratedHazardKindScript.Value.DOWNDRAFT:
			return PackedVector2Array([
				Vector2(-18.0, -30.0),
				Vector2(18.0, -30.0),
				Vector2(18.0, 8.0),
				Vector2(30.0, 8.0),
				Vector2(0.0, 32.0),
				Vector2(-30.0, 8.0),
				Vector2(-18.0, 8.0),
			])
		GeneratedHazardKindScript.Value.UPDRAFT:
			return PackedVector2Array([
				Vector2(0.0, -32.0),
				Vector2(30.0, -8.0),
				Vector2(18.0, -8.0),
				Vector2(18.0, 30.0),
				Vector2(-18.0, 30.0),
				Vector2(-18.0, -8.0),
				Vector2(-30.0, -8.0),
			])
		_:
			Validation.require_condition(false, "GeneratedHazardSpawnAdapter requires a supported hazard kind polygon.")
			return PackedVector2Array()

func _build_visual_color() -> Color:
	match hazard_kind:
		GeneratedHazardKindScript.Value.SPIKE_CLUSTER:
			return Color(0.93, 0.32, 0.27, 0.92)
		GeneratedHazardKindScript.Value.WIND_GUST:
			return Color(0.29, 0.72, 0.96, 0.88)
		GeneratedHazardKindScript.Value.DOWNDRAFT:
			return Color(0.96, 0.62, 0.24, 0.9)
		GeneratedHazardKindScript.Value.UPDRAFT:
			return Color(0.42, 0.92, 0.55, 0.9)
		_:
			Validation.require_condition(false, "GeneratedHazardSpawnAdapter requires a supported hazard kind color.")
			return Color.WHITE

func _get_collision_size_for_kind() -> Vector2:
	match hazard_kind:
		GeneratedHazardKindScript.Value.SPIKE_CLUSTER:
			return Vector2(28.0, 24.0)
		GeneratedHazardKindScript.Value.WIND_GUST:
			return Vector2(96.0, 56.0)
		GeneratedHazardKindScript.Value.DOWNDRAFT:
			return Vector2(72.0, 96.0)
		GeneratedHazardKindScript.Value.UPDRAFT:
			return Vector2(68.0, 92.0)
		_:
			Validation.require_condition(false, "GeneratedHazardSpawnAdapter requires a supported hazard kind collision size.")
			return Vector2.ZERO

func _get_specific_group_name() -> StringName:
	match hazard_kind:
		GeneratedHazardKindScript.Value.SPIKE_CLUSTER:
			return SPIKE_CLUSTER_GROUP_NAME
		GeneratedHazardKindScript.Value.WIND_GUST:
			return WIND_GUST_GROUP_NAME
		GeneratedHazardKindScript.Value.DOWNDRAFT:
			return DOWNDRAFT_GROUP_NAME
		GeneratedHazardKindScript.Value.UPDRAFT:
			return UPDRAFT_GROUP_NAME
		_:
			Validation.require_condition(false, "GeneratedHazardSpawnAdapter requires a supported hazard kind group.")
			return StringName()

func _hazard_kind_requires_impulse_vector(hazard_kind_value: int) -> bool:
	GeneratedHazardKindScript.assert_valid(hazard_kind_value)
	match hazard_kind_value:
		GeneratedHazardKindScript.Value.SPIKE_CLUSTER:
			return false
		GeneratedHazardKindScript.Value.WIND_GUST:
			return true
		GeneratedHazardKindScript.Value.DOWNDRAFT:
			return true
		GeneratedHazardKindScript.Value.UPDRAFT:
			return true
		_:
			Validation.require_condition(false, "GeneratedHazardSpawnAdapter requires a supported hazard kind when validating impulse state.")
			return false

func _ensure_presentation() -> void:
	var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape == null:
		collision_shape = CollisionShape2D.new()
		collision_shape.name = &"CollisionShape2D"
		add_child(collision_shape)

	collision_shape.shape = _build_collision_shape()

	var visual: Polygon2D = get_node_or_null("Visual") as Polygon2D
	if visual == null:
		visual = Polygon2D.new()
		visual.name = &"Visual"
		add_child(visual)

	visual.color = _build_visual_color()
	visual.polygon = _build_visual_polygon()

	if hazard_kind == GeneratedHazardKindScript.Value.WIND_GUST:
		var animated_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
		if animated_sprite == null:
			animated_sprite = AnimatedSprite2D.new()
			animated_sprite.name = &"AnimatedSprite2D"
			animated_sprite.sprite_frames = SpriteFrameSequenceLoaderScript.build_looping_animation(WIND_GUST_ANIMATION_FRAME_PATH_FORMAT, WIND_GUST_ANIMATION_FRAME_COUNT, WIND_GUST_ANIMATION_NAME, WIND_GUST_ANIMATION_FRAMES_PER_SECOND)
			animated_sprite.animation = WIND_GUST_ANIMATION_NAME
			add_child(animated_sprite)
			animated_sprite.play()

func _on_body_entered(body: Node) -> void:
	Validation.require_condition(body != null, "GeneratedHazardSpawnAdapter body_entered requires a body.")
	triggered.emit(body)