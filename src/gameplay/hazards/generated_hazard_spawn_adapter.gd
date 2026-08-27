class_name GeneratedHazardSpawnAdapter
extends Area2D

const GeneratedHazardKindScript = preload("res://src/gameplay/generation/generated_hazard_kind.gd")
const HazardPresentationDefinitionScript = preload("res://resources/config/hazard_presentation_definition.gd")
const PresentationSceneValidatorScript = preload("res://resources/config/presentation_scene_validator.gd")

signal triggered(body: Node)

const GROUP_NAME: StringName = &"generated_hazard"
const SPIKE_CLUSTER_GROUP_NAME: StringName = &"generated_spike_cluster_hazard"
const WIND_GUST_GROUP_NAME: StringName = &"generated_wind_gust_hazard"
const DOWNDRAFT_GROUP_NAME: StringName = &"generated_downdraft_hazard"
const UPDRAFT_GROUP_NAME: StringName = &"generated_updraft_hazard"
const FALLING_ROCK_GROUP_NAME: StringName = &"generated_falling_rock_hazard"
const PENDULUM_LOG_GROUP_NAME: StringName = &"generated_pendulum_log_hazard"
const WANDERING_CRITTER_GROUP_NAME: StringName = &"generated_wandering_critter_hazard"
const STARTLE_PUFF_GROUP_NAME: StringName = &"generated_startle_puff_hazard"
const BUG_SWARM_GROUP_NAME: StringName = &"generated_bug_swarm_hazard"

const PENDULUM_ARM_LENGTH_PIXELS: float = 48.0
const PENDULUM_SWING_AMPLITUDE_RADIANS: float = 0.9
const PENDULUM_SWING_FREQUENCY_HZ: float = 0.4
const ROAM_SPAN_PIXELS: float = 140.0
const ROAM_FREQUENCY_HZ: float = 0.25
const FALLING_ROCK_DISTANCE_PIXELS: float = 180.0
const FALLING_ROCK_CYCLE_SECONDS: float = 1.5

var socket_id: StringName = StringName()
var hazard_kind: int = -1
var impulse_vector_pixels: Vector2 = Vector2.ZERO
var _motion_origin_position: Vector2 = Vector2.ZERO
var _motion_time_seconds: float = 0.0
var _presentation_definition: HazardPresentationDefinitionScript

func configure_hazard(
	socket_id_value: StringName,
	hazard_kind_value: int,
	local_position_pixels_value: Vector2,
	impulse_vector_pixels_value: Vector2 = Vector2.ZERO,
	presentation_definition_value: HazardPresentationDefinitionScript = null,
	collision_layer_value: int = 16,
	collision_mask_value: int = 1
) -> void:
	Validation.require_condition(not String(socket_id_value).is_empty(), "GeneratedHazardSpawnAdapter requires a socket id.")
	GeneratedHazardKindScript.assert_valid(hazard_kind_value)
	Validation.require_condition(collision_layer_value > 0, "GeneratedHazardSpawnAdapter collision layer must be positive.")
	Validation.require_condition(collision_mask_value > 0, "GeneratedHazardSpawnAdapter collision mask must be positive.")
	if _hazard_kind_requires_impulse_vector(hazard_kind_value):
		Validation.require_condition(impulse_vector_pixels_value != Vector2.ZERO, "GeneratedHazardSpawnAdapter force hazards require a non-zero impulse vector.")
	Validation.require_condition(presentation_definition_value != null, "GeneratedHazardSpawnAdapter requires a presentation definition.")
	presentation_definition_value.assert_valid()
	Validation.require_condition(
		presentation_definition_value.hazard_kind == hazard_kind_value,
		"GeneratedHazardSpawnAdapter presentation kind must match its gameplay kind."
	)

	socket_id = socket_id_value
	hazard_kind = hazard_kind_value
	impulse_vector_pixels = impulse_vector_pixels_value
	_presentation_definition = presentation_definition_value
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
	_ensure_runtime_nodes()
	_motion_origin_position = position
	_motion_time_seconds = 0.0

func _ready() -> void:
	_validate_required_state()
	if not body_entered.is_connected(_on_body_entered):
		var _connect_result: int = body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if hazard_kind == GeneratedHazardKindScript.Value.FALLING_ROCK:
		_advance_falling_rock_motion(delta)
	elif hazard_kind == GeneratedHazardKindScript.Value.PENDULUM_LOG:
		_advance_pendulum_motion(delta)
	elif hazard_kind == GeneratedHazardKindScript.Value.WANDERING_CRITTER:
		_advance_roaming_motion(delta)

func _advance_falling_rock_motion(delta: float) -> void:
	_motion_time_seconds = fmod(_motion_time_seconds + delta, FALLING_ROCK_CYCLE_SECONDS)
	var fall_progress: float = _motion_time_seconds / FALLING_ROCK_CYCLE_SECONDS
	position = _motion_origin_position + Vector2.DOWN * FALLING_ROCK_DISTANCE_PIXELS * fall_progress

func _advance_pendulum_motion(delta: float) -> void:
	_motion_time_seconds += delta
	var swing_angle_radians: float = PENDULUM_SWING_AMPLITUDE_RADIANS * sin(TAU * PENDULUM_SWING_FREQUENCY_HZ * _motion_time_seconds)
	position = _motion_origin_position + Vector2(
		PENDULUM_ARM_LENGTH_PIXELS * sin(swing_angle_radians),
		PENDULUM_ARM_LENGTH_PIXELS * (1.0 - cos(swing_angle_radians))
	)

func _advance_roaming_motion(delta: float) -> void:
	_motion_time_seconds += delta
	position = _motion_origin_position + Vector2(
		ROAM_SPAN_PIXELS * 0.5 * sin(TAU * ROAM_FREQUENCY_HZ * _motion_time_seconds),
		0.0
	)

func _validate_required_state() -> void:
	Validation.require_condition(not String(socket_id).is_empty(), "GeneratedHazardSpawnAdapter must be configured before entering the scene tree.")
	GeneratedHazardKindScript.assert_valid(hazard_kind)
	if _hazard_kind_requires_impulse_vector(hazard_kind):
		Validation.require_condition(impulse_vector_pixels != Vector2.ZERO, "GeneratedHazardSpawnAdapter force hazards require a non-zero impulse vector.")
	Validation.require_condition(get_node_or_null("CollisionShape2D") is CollisionShape2D, "GeneratedHazardSpawnAdapter requires CollisionShape2D.")
	Validation.require_condition(get_node_or_null("PresentationRoot") is Node2D, "GeneratedHazardSpawnAdapter requires PresentationRoot.")
	Validation.require_condition(get_node_or_null("PresentationRoot/Asset") is Node2D, "GeneratedHazardSpawnAdapter requires a presentation asset.")
	PresentationSceneValidatorScript.assert_live_tree_valid(
		get_node("PresentationRoot/Asset"),
		"Generated hazard %s" % String(socket_id)
	)

func get_impulse_vector_pixels() -> Vector2:
	return impulse_vector_pixels

func _build_collision_shape() -> Shape2D:
	var rectangle_shape: RectangleShape2D = RectangleShape2D.new()
	rectangle_shape.size = _get_collision_size_for_kind()
	return rectangle_shape

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
		GeneratedHazardKindScript.Value.FALLING_ROCK:
			return Vector2(30.0, 28.0)
		GeneratedHazardKindScript.Value.PENDULUM_LOG:
			return Vector2(44.0, 20.0)
		GeneratedHazardKindScript.Value.WANDERING_CRITTER:
			return Vector2(24.0, 18.0)
		GeneratedHazardKindScript.Value.STARTLE_PUFF:
			return Vector2(28.0, 28.0)
		GeneratedHazardKindScript.Value.BUG_SWARM:
			return Vector2(32.0, 24.0)
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
		GeneratedHazardKindScript.Value.FALLING_ROCK:
			return FALLING_ROCK_GROUP_NAME
		GeneratedHazardKindScript.Value.PENDULUM_LOG:
			return PENDULUM_LOG_GROUP_NAME
		GeneratedHazardKindScript.Value.WANDERING_CRITTER:
			return WANDERING_CRITTER_GROUP_NAME
		GeneratedHazardKindScript.Value.STARTLE_PUFF:
			return STARTLE_PUFF_GROUP_NAME
		GeneratedHazardKindScript.Value.BUG_SWARM:
			return BUG_SWARM_GROUP_NAME
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
		GeneratedHazardKindScript.Value.FALLING_ROCK:
			return false
		GeneratedHazardKindScript.Value.PENDULUM_LOG:
			return false
		GeneratedHazardKindScript.Value.WANDERING_CRITTER:
			return true
		GeneratedHazardKindScript.Value.STARTLE_PUFF:
			return false
		GeneratedHazardKindScript.Value.BUG_SWARM:
			return false
		_:
			Validation.require_condition(false, "GeneratedHazardSpawnAdapter requires a supported hazard kind when validating impulse state.")
			return false

func _ensure_runtime_nodes() -> void:
	var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape == null:
		collision_shape = CollisionShape2D.new()
		collision_shape.name = &"CollisionShape2D"
		add_child(collision_shape)

	collision_shape.shape = _build_collision_shape()

	var presentation_root: Node2D = get_node_or_null("PresentationRoot") as Node2D
	if presentation_root == null:
		presentation_root = Node2D.new()
		presentation_root.name = &"PresentationRoot"
		add_child(presentation_root)

	if presentation_root.get_node_or_null("Asset") == null:
		Validation.require_condition(_presentation_definition != null, "GeneratedHazardSpawnAdapter requires presentation before creating runtime nodes.")
		var presentation: Node2D = _presentation_definition.instantiate_presentation(impulse_vector_pixels)
		presentation.name = &"Asset"
		presentation_root.add_child(presentation)

func _on_body_entered(body: Node) -> void:
	Validation.require_condition(body != null, "GeneratedHazardSpawnAdapter body_entered requires a body.")
	triggered.emit(body)
