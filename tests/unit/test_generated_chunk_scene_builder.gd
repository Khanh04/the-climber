extends GutTest

const ChunkDifficultyBandScript = preload("res://src/gameplay/generation/chunk_difficulty_band.gd")
const ChunkRouteSlotScript = preload("res://src/gameplay/generation/chunk_route_slot.gd")
const ChunkTypeScript = preload("res://src/gameplay/generation/chunk_type.gd")
const GeneratedChunkLayoutScript = preload("res://src/gameplay/generation/generated_chunk_layout.gd")
const GeneratedChunkSceneBuilderScript = preload("res://src/gameplay/generation/generated_chunk_scene_builder.gd")
const GeneratedHandholdSocketScript = preload("res://src/gameplay/generation/generated_handhold_socket.gd")
const GeneratedHazardSocketScript = preload("res://src/gameplay/generation/generated_hazard_socket.gd")
const GeneratedPickupSocketScript = preload("res://src/gameplay/generation/generated_pickup_socket.gd")

func test_scene_builder_creates_chunk_root_with_metadata_and_scaled_position() -> void:
    var builder: GeneratedChunkSceneBuilderScript = GeneratedChunkSceneBuilderScript.new(100.0)
    var layout: GeneratedChunkLayoutScript = _build_layout_fixture()

    var chunk_node: Node2D = builder.build_chunk_node(layout)
    add_child_autofree(chunk_node)
    var seed_key: String = _get_string_meta(chunk_node, &"seed_key")
    var chunk_type_label: String = _get_string_meta(chunk_node, &"chunk_type")

    assert_eq(chunk_node.name, &"GeneratedChunk_02_ZIGZAG")
    assert_eq(chunk_node.position, Vector2(0.0, -4800.0))
    assert_eq(seed_key, "generator_v1:2026-05-14")
    assert_eq(chunk_type_label, "ZIGZAG")
    assert_not_null(chunk_node.get_node_or_null("Handholds"))
    assert_not_null(chunk_node.get_node_or_null("PickupSocketMarkers"))
    assert_not_null(chunk_node.get_node_or_null("HazardSocketMarkers"))

func test_scene_builder_creates_non_blocking_handholds_and_visible_socket_markers() -> void:
    var builder: GeneratedChunkSceneBuilderScript = GeneratedChunkSceneBuilderScript.new(100.0)
    var layout: GeneratedChunkLayoutScript = _build_layout_fixture()

    var chunk_node: Node2D = builder.build_chunk_node(layout)
    add_child_autofree(chunk_node)

    var handhold: StaticBody2D = chunk_node.get_node("Handholds/chunk_02_hold_00") as StaticBody2D
    var collision_shape: CollisionShape2D = handhold.get_node("CollisionShape2D") as CollisionShape2D
    var rectangle_shape: RectangleShape2D = collision_shape.shape as RectangleShape2D
    var handhold_visual: Polygon2D = handhold.get_node("Visual") as Polygon2D
    var pickup_marker: Node2D = chunk_node.get_node("PickupSocketMarkers/chunk_02_pickup_00") as Node2D
    var pickup_visual: Polygon2D = pickup_marker.get_node("Visual") as Polygon2D
    var hazard_marker: Node2D = chunk_node.get_node("HazardSocketMarkers/chunk_02_hazard_00") as Node2D
    var hazard_visual: Polygon2D = hazard_marker.get_node("Visual") as Polygon2D

    assert_not_null(handhold)
    assert_true(handhold.is_in_group(&"handhold"))
    assert_true(handhold.position.is_equal_approx(Vector2(-120.0, -150.0)))
    assert_eq(handhold.collision_layer, 2)
    assert_eq(handhold.collision_mask, 0)
    assert_not_null(collision_shape)
    assert_not_null(rectangle_shape)
    assert_eq(rectangle_shape.size, Vector2(128.0, 34.0))
    assert_not_null(handhold_visual)

    assert_not_null(pickup_marker)
    assert_true(pickup_marker.is_in_group(GeneratedChunkSceneBuilderScript.PICKUP_SOCKET_MARKER_GROUP_NAME))
    assert_true(pickup_marker.position.is_equal_approx(Vector2(-60.0, -240.0)))
    assert_not_null(pickup_visual)

    assert_not_null(hazard_marker)
    assert_true(hazard_marker.is_in_group(GeneratedChunkSceneBuilderScript.HAZARD_SOCKET_MARKER_GROUP_NAME))
    assert_true(hazard_marker.position.is_equal_approx(Vector2(90.0, -310.0)))
    assert_not_null(hazard_visual)

func _build_layout_fixture() -> GeneratedChunkLayoutScript:
    var handholds: Array[GeneratedHandholdSocketScript] = [
        GeneratedHandholdSocketScript.new(&"chunk_02_hold_00", Vector2(-1.2, -1.5)),
        GeneratedHandholdSocketScript.new(&"chunk_02_hold_01", Vector2(1.1, -2.8)),
    ]
    var pickup_sockets: Array[GeneratedPickupSocketScript] = [
        GeneratedPickupSocketScript.new(&"chunk_02_pickup_00", Vector2(-0.6, -2.4)),
    ]
    var hazard_sockets: Array[GeneratedHazardSocketScript] = [
        GeneratedHazardSocketScript.new(&"chunk_02_hazard_00", Vector2(0.9, -3.1)),
    ]

    return GeneratedChunkLayoutScript.new(
        "generator_v1:2026-05-14",
        "generator_v1",
        2,
        ChunkTypeScript.Value.ZIGZAG,
        ChunkRouteSlotScript.Value.SKILL,
        ChunkDifficultyBandScript.Value.BASELINE,
        48.0,
        handholds,
        pickup_sockets,
        hazard_sockets
    )

func _get_string_meta(node: Node, key: StringName) -> String:
    var raw_value: Variant = node.get_meta(key)

    if raw_value is String:
        var typed_string: String = raw_value
        return typed_string

    if raw_value is StringName:
        var typed_name: StringName = raw_value
        return String(typed_name)

    fail_test("Expected string-like metadata for %s." % String(key))
    return ""