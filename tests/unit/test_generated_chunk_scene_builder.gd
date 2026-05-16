extends GutTest

const ChunkDifficultyBandScript = preload("res://src/gameplay/generation/chunk_difficulty_band.gd")
const GeneratedHazardKindScript = preload("res://src/gameplay/generation/generated_hazard_kind.gd")
const GeneratedHandholdAdapterScript = preload("res://src/gameplay/generation/generated_handhold_adapter.gd")
const ChunkRouteSlotScript = preload("res://src/gameplay/generation/chunk_route_slot.gd")
const ChunkTypeScript = preload("res://src/gameplay/generation/chunk_type.gd")
const GeneratedCoinPickupSpawnAdapterScript = preload("res://src/gameplay/pickups/generated_coin_pickup_spawn_adapter.gd")
const GeneratedHazardSpawnAdapterScript = preload("res://src/gameplay/hazards/generated_hazard_spawn_adapter.gd")
const GeneratedChunkLayoutScript = preload("res://src/gameplay/generation/generated_chunk_layout.gd")
const GeneratedChunkSceneBuilderScript = preload("res://src/gameplay/generation/generated_chunk_scene_builder.gd")
const GeneratedHandholdSocketScript = preload("res://src/gameplay/generation/generated_handhold_socket.gd")
const GeneratedHazardSocketScript = preload("res://src/gameplay/generation/generated_hazard_socket.gd")
const GeneratedRouteValidationResultScript: GDScript = preload("res://src/gameplay/generation/generated_route_validation_result.gd")
const HandholdTypeScript = preload("res://src/gameplay/generation/handhold_type.gd")
const RouteRoleScript = preload("res://src/gameplay/generation/route_role.gd")
const HandholdSurfaceProfileScript = preload("res://resources/config/handhold_surface_profile.gd")
const HandholdTypeDefinitionScript = preload("res://resources/config/handhold_type_definition.gd")
const GenerationTuningScript = preload("res://resources/config/generation_tuning.gd")
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
    assert_eq(seed_key, "generator_v2:2026-05-14")
    assert_eq(chunk_type_label, "ZIGZAG")
    var route_entry_hold_ids_meta: Variant = chunk_node.get_meta(&"route_entry_hold_ids")
    var route_exit_hold_ids_meta: Variant = chunk_node.get_meta(&"route_exit_hold_ids")
    assert_true(route_entry_hold_ids_meta is PackedStringArray)
    assert_true(route_exit_hold_ids_meta is PackedStringArray)
    var typed_route_entry_hold_ids: PackedStringArray = route_entry_hold_ids_meta
    var typed_route_exit_hold_ids: PackedStringArray = route_exit_hold_ids_meta
    var route_validation_is_valid: bool = _get_bool_meta(chunk_node, &"route_validation_is_valid")
    var route_validation_path_length: int = _get_int_meta(chunk_node, &"route_validation_path_length")
    var selected_candidate_attempt_index: int = _get_int_meta(chunk_node, &"selected_candidate_attempt_index")
    var candidate_score: float = _get_float_meta(chunk_node, &"candidate_score")
    var route_validation_path_hold_ids_meta: Variant = chunk_node.get_meta(&"route_validation_path_hold_ids")
    assert_true(route_validation_path_hold_ids_meta is PackedStringArray)
    var typed_route_validation_path_hold_ids: PackedStringArray = route_validation_path_hold_ids_meta
    assert_eq(typed_route_entry_hold_ids, PackedStringArray(["chunk_02_hold_00"]))
    assert_eq(typed_route_exit_hold_ids, PackedStringArray(["chunk_02_hold_01"]))
    assert_eq(route_validation_is_valid, true)
    assert_eq(_get_string_meta(chunk_node, &"route_validation_target_hold_id"), "chunk_02_hold_01")
    assert_eq(_get_string_meta(chunk_node, &"route_validation_failure_reason"), "")
    assert_eq(typed_route_validation_path_hold_ids, PackedStringArray(["chunk_02_hold_00", "chunk_02_hold_01"]))
    assert_eq(route_validation_path_length, 2)
    assert_eq(selected_candidate_attempt_index, 1)
    assert_eq(candidate_score, 1234.5)
    assert_not_null(chunk_node.get_node_or_null("Handholds"))
    assert_not_null(chunk_node.get_node_or_null("Pickups"))
    assert_not_null(chunk_node.get_node_or_null("Hazards"))

func test_scene_builder_creates_non_blocking_handholds_and_runtime_spawn_adapters() -> void:
    var builder: GeneratedChunkSceneBuilderScript = GeneratedChunkSceneBuilderScript.new(100.0)
    var layout: GeneratedChunkLayoutScript = _build_layout_fixture()

    var chunk_node: Node2D = builder.build_chunk_node(layout)
    add_child_autofree(chunk_node)

    var handhold: GeneratedHandholdAdapterScript = chunk_node.get_node("Handholds/chunk_02_hold_00") as GeneratedHandholdAdapterScript
    var collision_shape: CollisionShape2D = handhold.get_node("CollisionShape2D") as CollisionShape2D
    var rectangle_shape: RectangleShape2D = collision_shape.shape as RectangleShape2D
    var handhold_visual: Polygon2D = handhold.get_node("Visual") as Polygon2D
    var pickup_spawn: GeneratedCoinPickupSpawnAdapterScript = chunk_node.get_node("Pickups/chunk_02_pickup_00") as GeneratedCoinPickupSpawnAdapterScript
    var pickup_collision_shape: CollisionShape2D = pickup_spawn.get_node("CollisionShape2D") as CollisionShape2D
    var pickup_circle_shape: CircleShape2D = pickup_collision_shape.shape as CircleShape2D
    var pickup_visual: Polygon2D = pickup_spawn.get_node("Visual") as Polygon2D
    var wind_gust_spawn: GeneratedHazardSpawnAdapterScript = chunk_node.get_node("Hazards/chunk_02_hazard_00") as GeneratedHazardSpawnAdapterScript
    var wind_collision_shape: CollisionShape2D = wind_gust_spawn.get_node("CollisionShape2D") as CollisionShape2D
    var wind_rectangle_shape: RectangleShape2D = wind_collision_shape.shape as RectangleShape2D
    var wind_visual: Polygon2D = wind_gust_spawn.get_node("Visual") as Polygon2D
    var spike_cluster_spawn: GeneratedHazardSpawnAdapterScript = chunk_node.get_node("Hazards/chunk_02_hazard_01") as GeneratedHazardSpawnAdapterScript
    var spike_collision_shape: CollisionShape2D = spike_cluster_spawn.get_node("CollisionShape2D") as CollisionShape2D
    var spike_rectangle_shape: RectangleShape2D = spike_collision_shape.shape as RectangleShape2D
    var spike_visual: Polygon2D = spike_cluster_spawn.get_node("Visual") as Polygon2D
    var downdraft_spawn: GeneratedHazardSpawnAdapterScript = chunk_node.get_node("Hazards/chunk_02_hazard_02") as GeneratedHazardSpawnAdapterScript
    var downdraft_collision_shape: CollisionShape2D = downdraft_spawn.get_node("CollisionShape2D") as CollisionShape2D
    var downdraft_rectangle_shape: RectangleShape2D = downdraft_collision_shape.shape as RectangleShape2D
    var downdraft_visual: Polygon2D = downdraft_spawn.get_node("Visual") as Polygon2D
    var updraft_spawn: GeneratedHazardSpawnAdapterScript = chunk_node.get_node("Hazards/chunk_02_hazard_03") as GeneratedHazardSpawnAdapterScript
    var updraft_collision_shape: CollisionShape2D = updraft_spawn.get_node("CollisionShape2D") as CollisionShape2D
    var updraft_rectangle_shape: RectangleShape2D = updraft_collision_shape.shape as RectangleShape2D
    var updraft_visual: Polygon2D = updraft_spawn.get_node("Visual") as Polygon2D

    assert_not_null(handhold)
    assert_true(handhold is StaticBody2D)
    assert_true(handhold.is_in_group(&"handhold"))
    assert_true(handhold.position.is_equal_approx(Vector2(-120.0, -150.0)))
    assert_eq(handhold.collision_layer, 2)
    assert_eq(handhold.collision_mask, 0)
    assert_eq(handhold.handhold_type, HandholdTypeScript.Value.REST)
    assert_eq(handhold.stamina_drain_multiplier, 0.75)
    assert_eq(handhold.definition_id, &"REST")
    assert_not_null(collision_shape)
    assert_not_null(rectangle_shape)
    assert_true(rectangle_shape.size.is_equal_approx(Vector2(124.0, 30.0)))
    var handhold_type_meta: Variant = handhold.get_meta(&"handhold_type")
    var handhold_route_role_meta: Variant = handhold.get_meta(&"route_role")
    assert_true(handhold_type_meta is String)
    assert_true(handhold_route_role_meta is String)
    var typed_handhold_type_meta: String = handhold_type_meta
    var typed_handhold_route_role_meta: String = handhold_route_role_meta
    assert_eq(typed_handhold_type_meta, "REST")
    assert_eq(typed_handhold_route_role_meta, "ENTRY")
    assert_not_null(handhold_visual)

    assert_not_null(pickup_spawn)
    assert_true(pickup_spawn.is_in_group(GeneratedChunkSceneBuilderScript.PICKUP_GROUP_NAME))
    assert_true(pickup_spawn.position.is_equal_approx(Vector2(-60.0, -240.0)))
    assert_not_null(pickup_collision_shape)
    assert_not_null(pickup_circle_shape)
    assert_eq(pickup_spawn.coin_amount, 1)
    assert_not_null(pickup_visual)

    assert_not_null(wind_gust_spawn)
    assert_true(wind_gust_spawn.is_in_group(GeneratedChunkSceneBuilderScript.HAZARD_GROUP_NAME))
    assert_true(wind_gust_spawn.is_in_group(GeneratedHazardSpawnAdapterScript.WIND_GUST_GROUP_NAME))
    assert_eq(wind_gust_spawn.hazard_kind, GeneratedHazardKindScript.Value.WIND_GUST)
    assert_true(wind_gust_spawn.position.is_equal_approx(Vector2(-40.0, -210.0)))
    assert_not_null(wind_collision_shape)
    assert_not_null(wind_rectangle_shape)
    assert_eq(wind_rectangle_shape.size, Vector2(96.0, 56.0))
    assert_true(wind_gust_spawn.get_impulse_vector_pixels().is_equal_approx(Vector2(220.0, -140.0)))
    assert_not_null(wind_visual)

    assert_not_null(spike_cluster_spawn)
    assert_true(spike_cluster_spawn.is_in_group(GeneratedChunkSceneBuilderScript.HAZARD_GROUP_NAME))
    assert_true(spike_cluster_spawn.is_in_group(GeneratedHazardSpawnAdapterScript.SPIKE_CLUSTER_GROUP_NAME))
    assert_eq(spike_cluster_spawn.hazard_kind, GeneratedHazardKindScript.Value.SPIKE_CLUSTER)
    assert_true(spike_cluster_spawn.position.is_equal_approx(Vector2(90.0, -310.0)))
    assert_not_null(spike_collision_shape)
    assert_not_null(spike_rectangle_shape)
    assert_eq(spike_rectangle_shape.size, Vector2(28.0, 24.0))
    assert_not_null(spike_visual)

    assert_not_null(downdraft_spawn)
    assert_true(downdraft_spawn.is_in_group(GeneratedChunkSceneBuilderScript.HAZARD_GROUP_NAME))
    assert_true(downdraft_spawn.is_in_group(GeneratedHazardSpawnAdapterScript.DOWNDRAFT_GROUP_NAME))
    assert_eq(downdraft_spawn.hazard_kind, GeneratedHazardKindScript.Value.DOWNDRAFT)
    assert_true(downdraft_spawn.position.is_equal_approx(Vector2(10.0, -260.0)))
    assert_not_null(downdraft_collision_shape)
    assert_not_null(downdraft_rectangle_shape)
    assert_eq(downdraft_rectangle_shape.size, Vector2(72.0, 96.0))
    assert_true(downdraft_spawn.get_impulse_vector_pixels().is_equal_approx(Vector2(-90.0, 260.0)))
    assert_not_null(downdraft_visual)

    assert_not_null(updraft_spawn)
    assert_true(updraft_spawn.is_in_group(GeneratedChunkSceneBuilderScript.HAZARD_GROUP_NAME))
    assert_true(updraft_spawn.is_in_group(GeneratedHazardSpawnAdapterScript.UPDRAFT_GROUP_NAME))
    assert_eq(updraft_spawn.hazard_kind, GeneratedHazardKindScript.Value.UPDRAFT)
    assert_true(updraft_spawn.position.is_equal_approx(Vector2(-110.0, -180.0)))
    assert_not_null(updraft_collision_shape)
    assert_not_null(updraft_rectangle_shape)
    assert_eq(updraft_rectangle_shape.size, Vector2(68.0, 92.0))
    assert_true(updraft_spawn.get_impulse_vector_pixels().is_equal_approx(Vector2(110.0, -320.0)))
    assert_not_null(updraft_visual)

func _build_layout_fixture() -> GeneratedChunkLayoutScript:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var rest_definition: HandholdTypeDefinitionScript = tuning.get_required_handhold_definition(HandholdTypeScript.Value.REST)
    var burn_definition: HandholdTypeDefinitionScript = tuning.get_required_handhold_definition(HandholdTypeScript.Value.BURN)
    var rest_surface_profile: HandholdSurfaceProfileScript = rest_definition.surface_profile as HandholdSurfaceProfileScript
    var burn_surface_profile: HandholdSurfaceProfileScript = burn_definition.surface_profile as HandholdSurfaceProfileScript
    var handholds: Array[GeneratedHandholdSocketScript] = [
        GeneratedHandholdSocketScript.new(
            &"chunk_02_hold_00",
            rest_definition.definition_id,
            Vector2(-1.2, -1.5),
            HandholdTypeScript.Value.REST,
            rest_surface_profile.stamina_drain_multiplier,
            rest_definition.physical_size_meters,
            rest_definition.visual_color,
            0.0,
            false,
            Vector2.ZERO,
            RouteRoleScript.Value.ENTRY
        ),
        GeneratedHandholdSocketScript.new(
            &"chunk_02_hold_01",
            burn_definition.definition_id,
            Vector2(1.1, -2.8),
            HandholdTypeScript.Value.BURN,
            burn_surface_profile.stamina_drain_multiplier,
            burn_definition.physical_size_meters,
            burn_definition.visual_color,
            0.0,
            false,
            Vector2.ZERO,
            RouteRoleScript.Value.TOP_OUT
        ),
    ]
    var pickup_sockets: Array[GeneratedPickupSocketScript] = [
        GeneratedPickupSocketScript.new(&"chunk_02_pickup_00", Vector2(-0.6, -2.4)),
    ]
    var hazard_sockets: Array[GeneratedHazardSocketScript] = [
        GeneratedHazardSocketScript.new(&"chunk_02_hazard_00", GeneratedHazardKindScript.Value.WIND_GUST, Vector2(-0.4, -2.1)),
        GeneratedHazardSocketScript.new(&"chunk_02_hazard_01", GeneratedHazardKindScript.Value.SPIKE_CLUSTER, Vector2(0.9, -3.1)),
        GeneratedHazardSocketScript.new(&"chunk_02_hazard_02", GeneratedHazardKindScript.Value.DOWNDRAFT, Vector2(0.1, -2.6)),
        GeneratedHazardSocketScript.new(&"chunk_02_hazard_03", GeneratedHazardKindScript.Value.UPDRAFT, Vector2(-1.1, -1.8)),
    ]
    var route_validation_result_variant: Variant = GeneratedRouteValidationResultScript.new(
        true,
        "",
        &"chunk_02_hold_01",
        PackedStringArray(["chunk_02_hold_00", "chunk_02_hold_01"])
    )
    assert_true(route_validation_result_variant is RefCounted)
    var route_validation_result: RefCounted = route_validation_result_variant

    return GeneratedChunkLayoutScript.new(
        "generator_v2:2026-05-14",
        "generator_v2",
        2,
        ChunkTypeScript.Value.ZIGZAG,
        ChunkRouteSlotScript.Value.SKILL,
        ChunkDifficultyBandScript.Value.BASELINE,
        48.0,
        handholds,
        pickup_sockets,
        hazard_sockets,
        PackedStringArray(["chunk_02_hold_00"]),
        PackedStringArray(["chunk_02_hold_01"]),
        route_validation_result,
        1,
        1234.5
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

func _get_bool_meta(node: Node, key: StringName) -> bool:
    var raw_value: Variant = node.get_meta(key)
    if not raw_value is bool:
        fail_test("Expected bool metadata for %s." % String(key))
        return false

    var typed_value: bool = raw_value
    return typed_value

func _get_int_meta(node: Node, key: StringName) -> int:
    var raw_value: Variant = node.get_meta(key)
    if not raw_value is int:
        fail_test("Expected int metadata for %s." % String(key))
        return 0

    var typed_value: int = raw_value
    return typed_value

func _get_float_meta(node: Node, key: StringName) -> float:
    var raw_value: Variant = node.get_meta(key)
    if not raw_value is float:
        fail_test("Expected float metadata for %s." % String(key))
        return 0.0

    var typed_value: float = raw_value
    return typed_value