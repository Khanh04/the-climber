class_name GeneratedChunkSceneBuilder
extends RefCounted

const PICKUP_SOCKET_MARKER_GROUP_NAME: StringName = &"generated_pickup_socket_marker"
const HAZARD_SOCKET_MARKER_GROUP_NAME: StringName = &"generated_hazard_socket_marker"

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

    var pickup_marker_root: Node2D = Node2D.new()
    pickup_marker_root.name = &"PickupSocketMarkers"
    chunk_root.add_child(pickup_marker_root)

    var hazard_marker_root: Node2D = Node2D.new()
    hazard_marker_root.name = &"HazardSocketMarkers"
    chunk_root.add_child(hazard_marker_root)

    for handhold_socket in layout.handholds:
        var handhold_body: StaticBody2D = _build_handhold_body(handhold_socket)
        handhold_root.add_child(handhold_body)

    for pickup_socket in layout.pickup_sockets:
        var pickup_marker: Node2D = _build_pickup_socket_marker(pickup_socket)
        pickup_marker_root.add_child(pickup_marker)

    for hazard_socket in layout.hazard_sockets:
        var hazard_marker: Node2D = _build_hazard_socket_marker(hazard_socket)
        hazard_marker_root.add_child(hazard_marker)

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

func _build_pickup_socket_marker(pickup_socket: GeneratedPickupSocket) -> Node2D:
    pickup_socket.assert_valid()

    var marker_root: Node2D = Node2D.new()
    marker_root.name = pickup_socket.socket_id
    marker_root.position = _meters_to_pixels(pickup_socket.local_position)
    marker_root.add_to_group(PICKUP_SOCKET_MARKER_GROUP_NAME)
    marker_root.set_meta(&"socket_kind", &"pickup")

    var marker_visual: Polygon2D = Polygon2D.new()
    marker_visual.name = &"Visual"
    marker_visual.color = Color(0.96, 0.85, 0.24, 0.9)
    marker_visual.polygon = PackedVector2Array([
        Vector2(0.0, -12.0),
        Vector2(10.0, 0.0),
        Vector2(0.0, 12.0),
        Vector2(-10.0, 0.0),
    ])
    marker_root.add_child(marker_visual)

    return marker_root

func _build_hazard_socket_marker(hazard_socket: GeneratedHazardSocket) -> Node2D:
    hazard_socket.assert_valid()

    var marker_root: Node2D = Node2D.new()
    marker_root.name = hazard_socket.socket_id
    marker_root.position = _meters_to_pixels(hazard_socket.local_position)
    marker_root.add_to_group(HAZARD_SOCKET_MARKER_GROUP_NAME)
    marker_root.set_meta(&"socket_kind", &"hazard")

    var marker_visual: Polygon2D = Polygon2D.new()
    marker_visual.name = &"Visual"
    marker_visual.color = Color(0.93, 0.32, 0.27, 0.92)
    marker_visual.polygon = PackedVector2Array([
        Vector2(0.0, -12.0),
        Vector2(11.0, 10.0),
        Vector2(-11.0, 10.0),
    ])
    marker_root.add_child(marker_visual)

    return marker_root

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