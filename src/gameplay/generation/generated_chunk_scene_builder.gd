class_name GeneratedChunkSceneBuilder
extends RefCounted

const GeneratedCoinPickupSpawnAdapterScript = preload("res://src/gameplay/pickups/generated_coin_pickup_spawn_adapter.gd")
const GeneratedHazardKindScript = preload("res://src/gameplay/generation/generated_hazard_kind.gd")
const GeneratedHazardSpawnAdapterScript = preload("res://src/gameplay/hazards/generated_hazard_spawn_adapter.gd")

const PICKUP_GROUP_NAME: StringName = GeneratedCoinPickupSpawnAdapterScript.GROUP_NAME
const HAZARD_GROUP_NAME: StringName = GeneratedHazardSpawnAdapterScript.GROUP_NAME

var _pixels_per_meter: float
var _handhold_group_name: StringName
var _hold_size_pixels: Vector2
var _hold_collision_layer: int
var _hold_collision_mask: int

func _init(
    pixels_per_meter_value: float,
    handhold_group_name_value: StringName = &"handhold",
    hold_size_pixels_value: Vector2 = Vector2(128.0, 34.0),
    hold_collision_layer_value: int = 2,
    hold_collision_mask_value: int = 0
) -> void:
    _pixels_per_meter = pixels_per_meter_value
    _handhold_group_name = handhold_group_name_value
    _hold_size_pixels = hold_size_pixels_value
    _hold_collision_layer = hold_collision_layer_value
    _hold_collision_mask = hold_collision_mask_value
    _assert_valid()

func build_chunk_node(layout: GeneratedChunkLayout) -> Node2D:
    Validation.require_condition(layout != null, "GeneratedChunkSceneBuilder requires a generated chunk layout.")
    layout.assert_valid()

    var chunk_root: Node2D = Node2D.new()
    chunk_root.name = StringName("GeneratedChunk_%02d_%s" % [layout.chunk_index, ChunkType.to_label(layout.chunk_type)])
    chunk_root.position = Vector2(0.0, -(layout.start_height_meters * _pixels_per_meter))
    _apply_chunk_metadata(chunk_root, layout)

    var handhold_root: Node2D = Node2D.new()
    handhold_root.name = &"Handholds"
    chunk_root.add_child(handhold_root)

    var pickup_root: Node2D = Node2D.new()
    pickup_root.name = &"Pickups"
    chunk_root.add_child(pickup_root)

    var hazard_root: Node2D = Node2D.new()
    hazard_root.name = &"Hazards"
    chunk_root.add_child(hazard_root)

    for handhold_socket in layout.handholds:
        var handhold_body: StaticBody2D = _build_handhold_body(handhold_socket)
        handhold_root.add_child(handhold_body)

    for pickup_socket in layout.pickup_sockets:
        var pickup_spawn: GeneratedCoinPickupSpawnAdapterScript = _build_pickup_spawn(pickup_socket)
        pickup_root.add_child(pickup_spawn)

    for hazard_socket in layout.hazard_sockets:
        var hazard_spawn: GeneratedHazardSpawnAdapterScript = _build_hazard_spawn(hazard_socket)
        hazard_root.add_child(hazard_spawn)

    return chunk_root

func _assert_valid() -> void:
    Validation.require_condition(_pixels_per_meter > 0.0, "GeneratedChunkSceneBuilder pixels-per-meter must be positive.")
    Validation.require_condition(not String(_handhold_group_name).is_empty(), "GeneratedChunkSceneBuilder requires a handhold group name.")
    Validation.require_condition(_hold_size_pixels.x > 0.0 and _hold_size_pixels.y > 0.0, "GeneratedChunkSceneBuilder hold size must be positive.")
    Validation.require_condition(_hold_collision_layer > 0, "GeneratedChunkSceneBuilder hold collision layer must be positive.")
    Validation.require_condition(_hold_collision_mask >= 0, "GeneratedChunkSceneBuilder hold collision mask cannot be negative.")

func _apply_chunk_metadata(chunk_root: Node2D, layout: GeneratedChunkLayout) -> void:
    chunk_root.set_meta(&"seed_key", layout.seed_key)
    chunk_root.set_meta(&"generator_version", layout.generator_version)
    chunk_root.set_meta(&"chunk_index", layout.chunk_index)
    chunk_root.set_meta(&"chunk_type", ChunkType.to_label(layout.chunk_type))
    chunk_root.set_meta(&"route_slot", ChunkRouteSlot.to_label(layout.route_slot))
    chunk_root.set_meta(&"difficulty_band", ChunkDifficultyBand.to_label(layout.difficulty_band))

func _build_handhold_body(handhold_socket: GeneratedHandholdSocket) -> StaticBody2D:
    handhold_socket.assert_valid()

    var handhold_body: StaticBody2D = StaticBody2D.new()
    handhold_body.name = handhold_socket.hold_id
    handhold_body.position = _meters_to_pixels(handhold_socket.local_position)
    handhold_body.collision_layer = _hold_collision_layer
    handhold_body.collision_mask = _hold_collision_mask
    handhold_body.add_to_group(_handhold_group_name)
    handhold_body.set_meta(&"stamina_drain_multiplier", handhold_socket.stamina_drain_multiplier)

    var collision_shape: CollisionShape2D = CollisionShape2D.new()
    collision_shape.name = &"CollisionShape2D"
    var rectangle_shape: RectangleShape2D = RectangleShape2D.new()
    rectangle_shape.size = _hold_size_pixels
    collision_shape.shape = rectangle_shape
    handhold_body.add_child(collision_shape)

    var visual: Polygon2D = Polygon2D.new()
    visual.name = &"Visual"
    visual.color = Color(0.92, 0.72, 0.23, 1.0)
    visual.polygon = _build_rectangle_polygon(_hold_size_pixels)
    handhold_body.add_child(visual)

    return handhold_body

func _build_pickup_spawn(pickup_socket: GeneratedPickupSocket) -> GeneratedCoinPickupSpawnAdapterScript:
    pickup_socket.assert_valid()

    var pickup_spawn: GeneratedCoinPickupSpawnAdapterScript = GeneratedCoinPickupSpawnAdapterScript.new()
    pickup_spawn.name = pickup_socket.socket_id
    pickup_spawn.configure(pickup_socket.socket_id, _meters_to_pixels(pickup_socket.local_position))
    return pickup_spawn

func _build_hazard_spawn(hazard_socket: GeneratedHazardSocket) -> GeneratedHazardSpawnAdapterScript:
    hazard_socket.assert_valid()

    var hazard_spawn: GeneratedHazardSpawnAdapterScript = GeneratedHazardSpawnAdapterScript.new()
    hazard_spawn.name = hazard_socket.socket_id
    hazard_spawn.configure_hazard(
        hazard_socket.socket_id,
        hazard_socket.hazard_kind,
        _meters_to_pixels(hazard_socket.local_position),
        _build_hazard_impulse_vector(hazard_socket)
    )
    return hazard_spawn

func _build_hazard_impulse_vector(hazard_socket: GeneratedHazardSocket) -> Vector2:
    hazard_socket.assert_valid()
    if hazard_socket.hazard_kind != GeneratedHazardKindScript.Value.WIND_GUST:
        return Vector2.ZERO

    var horizontal_impulse: float = 220.0
    if hazard_socket.local_position.x < 0.0:
        return Vector2(horizontal_impulse, -140.0)

    return Vector2(-horizontal_impulse, -140.0)

func _meters_to_pixels(local_position_meters: Vector2) -> Vector2:
    return local_position_meters * _pixels_per_meter

func _build_rectangle_polygon(size_pixels: Vector2) -> PackedVector2Array:
    var half_width: float = size_pixels.x * 0.5
    var half_height: float = size_pixels.y * 0.5
    return PackedVector2Array([
        Vector2(-half_width, -half_height),
        Vector2(half_width, -half_height),
        Vector2(half_width, half_height),
        Vector2(-half_width, half_height),
    ])