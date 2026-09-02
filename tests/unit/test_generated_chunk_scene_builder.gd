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
    assert_eq(seed_key, "generator_v1:2026-05-14")
    assert_eq(chunk_type_label, "ZIGZAG")
    var route_entry_hold_ids_meta: Variant = chunk_node.get_meta(&"route_entry_hold_ids")
    var route_exit_hold_ids_meta: Variant = chunk_node.get_meta(&"route_exit_hold_ids")
    assert_true(route_entry_hold_ids_meta is PackedStringArray)
    assert_true(route_exit_hold_ids_meta is PackedStringArray)
    var typed_route_entry_hold_ids: PackedStringArray = route_entry_hold_ids_meta
    var typed_route_exit_hold_ids: PackedStringArray = route_exit_hold_ids_meta
    var route_validation_is_valid: bool = _get_bool_meta(chunk_node, &"route_validation_is_valid")
    var route_validation_path_length: int = _get_int_meta(chunk_node, &"route_validation_path_length")
    assert_eq(typed_route_entry_hold_ids, PackedStringArray(["chunk_02_hold_00"]))
    assert_eq(typed_route_exit_hold_ids, PackedStringArray(["chunk_02_hold_01"]))
    assert_eq(route_validation_is_valid, true)
    assert_eq(_get_string_meta(chunk_node, &"route_validation_target_hold_id"), "chunk_02_hold_01")
    assert_eq(_get_string_meta(chunk_node, &"route_validation_failure_reason"), "")
    assert_eq(route_validation_path_length, 2)
    assert_not_null(chunk_node.get_node_or_null("Handholds"))
    assert_not_null(chunk_node.get_node_or_null("Pickups"))
    assert_not_null(chunk_node.get_node_or_null("Hazards"))

func test_scene_builder_creates_passive_handhold_collision_bodies_and_runtime_spawn_adapters() -> void:
    var builder: GeneratedChunkSceneBuilderScript = GeneratedChunkSceneBuilderScript.new(100.0)
    var layout: GeneratedChunkLayoutScript = _build_layout_fixture()

    var chunk_node: Node2D = builder.build_chunk_node(layout)
    add_child_autofree(chunk_node)

    var handhold: GeneratedHandholdAdapterScript = chunk_node.get_node("Handholds/chunk_02_hold_00") as GeneratedHandholdAdapterScript
    var collision_shape: CollisionShape2D = handhold.get_node("CollisionShape2D") as CollisionShape2D
    var rectangle_shape: RectangleShape2D = collision_shape.shape as RectangleShape2D
    var handhold_presentation: Node2D = handhold.get_node("PresentationRoot/Asset") as Node2D
    var pickup_spawn: GeneratedCoinPickupSpawnAdapterScript = chunk_node.get_node("Pickups/chunk_02_pickup_00") as GeneratedCoinPickupSpawnAdapterScript
    var pickup_collision_shape: CollisionShape2D = pickup_spawn.get_node("CollisionShape2D") as CollisionShape2D
    var pickup_circle_shape: CircleShape2D = pickup_collision_shape.shape as CircleShape2D
    var pickup_visual: Polygon2D = pickup_spawn.get_node("Visual") as Polygon2D
    var pickup_animated_sprite: AnimatedSprite2D = pickup_spawn.get_node("AnimatedSprite2D") as AnimatedSprite2D
    var wind_gust_spawn: GeneratedHazardSpawnAdapterScript = chunk_node.get_node("Hazards/chunk_02_hazard_00") as GeneratedHazardSpawnAdapterScript
    var wind_collision_shape: CollisionShape2D = wind_gust_spawn.get_node("CollisionShape2D") as CollisionShape2D
    var wind_rectangle_shape: RectangleShape2D = wind_collision_shape.shape as RectangleShape2D
    var wind_presentation: Node2D = wind_gust_spawn.get_node("PresentationRoot/Asset") as Node2D
    var wind_animated_sprite: AnimatedSprite2D = wind_presentation.get_node("AnimatedSprite2D") as AnimatedSprite2D
    var spike_cluster_spawn: GeneratedHazardSpawnAdapterScript = chunk_node.get_node("Hazards/chunk_02_hazard_01") as GeneratedHazardSpawnAdapterScript
    var spike_collision_shape: CollisionShape2D = spike_cluster_spawn.get_node("CollisionShape2D") as CollisionShape2D
    var spike_rectangle_shape: RectangleShape2D = spike_collision_shape.shape as RectangleShape2D
    var spike_presentation: Node2D = spike_cluster_spawn.get_node("PresentationRoot/Asset") as Node2D
    var downdraft_spawn: GeneratedHazardSpawnAdapterScript = chunk_node.get_node("Hazards/chunk_02_hazard_02") as GeneratedHazardSpawnAdapterScript
    var downdraft_collision_shape: CollisionShape2D = downdraft_spawn.get_node("CollisionShape2D") as CollisionShape2D
    var downdraft_rectangle_shape: RectangleShape2D = downdraft_collision_shape.shape as RectangleShape2D
    var downdraft_presentation: Node2D = downdraft_spawn.get_node("PresentationRoot/Asset") as Node2D
    var updraft_spawn: GeneratedHazardSpawnAdapterScript = chunk_node.get_node("Hazards/chunk_02_hazard_03") as GeneratedHazardSpawnAdapterScript
    var updraft_collision_shape: CollisionShape2D = updraft_spawn.get_node("CollisionShape2D") as CollisionShape2D
    var updraft_rectangle_shape: RectangleShape2D = updraft_collision_shape.shape as RectangleShape2D
    var updraft_presentation: Node2D = updraft_spawn.get_node("PresentationRoot/Asset") as Node2D
    var falling_rock_spawn: GeneratedHazardSpawnAdapterScript = chunk_node.get_node("Hazards/chunk_02_hazard_04") as GeneratedHazardSpawnAdapterScript
    var falling_rock_collision_shape: CollisionShape2D = falling_rock_spawn.get_node("CollisionShape2D") as CollisionShape2D
    var falling_rock_rectangle_shape: RectangleShape2D = falling_rock_collision_shape.shape as RectangleShape2D
    var falling_rock_presentation: Node2D = falling_rock_spawn.get_node("PresentationRoot/Asset") as Node2D
    var pendulum_log_spawn: GeneratedHazardSpawnAdapterScript = chunk_node.get_node("Hazards/chunk_02_hazard_05") as GeneratedHazardSpawnAdapterScript
    var pendulum_log_collision_shape: CollisionShape2D = pendulum_log_spawn.get_node("CollisionShape2D") as CollisionShape2D
    var pendulum_log_rectangle_shape: RectangleShape2D = pendulum_log_collision_shape.shape as RectangleShape2D
    var pendulum_log_presentation: Node2D = pendulum_log_spawn.get_node("PresentationRoot/Asset") as Node2D
    var wandering_critter_spawn: GeneratedHazardSpawnAdapterScript = chunk_node.get_node("Hazards/chunk_02_hazard_06") as GeneratedHazardSpawnAdapterScript
    var wandering_critter_collision_shape: CollisionShape2D = wandering_critter_spawn.get_node("CollisionShape2D") as CollisionShape2D
    var wandering_critter_rectangle_shape: RectangleShape2D = wandering_critter_collision_shape.shape as RectangleShape2D
    var wandering_critter_presentation: Node2D = wandering_critter_spawn.get_node("PresentationRoot/Asset") as Node2D
    var startle_puff_spawn: GeneratedHazardSpawnAdapterScript = chunk_node.get_node("Hazards/chunk_02_hazard_07") as GeneratedHazardSpawnAdapterScript
    var startle_puff_collision_shape: CollisionShape2D = startle_puff_spawn.get_node("CollisionShape2D") as CollisionShape2D
    var startle_puff_rectangle_shape: RectangleShape2D = startle_puff_collision_shape.shape as RectangleShape2D
    var startle_puff_presentation: Node2D = startle_puff_spawn.get_node("PresentationRoot/Asset") as Node2D
    var bug_swarm_spawn: GeneratedHazardSpawnAdapterScript = chunk_node.get_node("Hazards/chunk_02_hazard_08") as GeneratedHazardSpawnAdapterScript
    var bug_swarm_collision_shape: CollisionShape2D = bug_swarm_spawn.get_node("CollisionShape2D") as CollisionShape2D
    var bug_swarm_rectangle_shape: RectangleShape2D = bug_swarm_collision_shape.shape as RectangleShape2D
    var bug_swarm_presentation: Node2D = bug_swarm_spawn.get_node("PresentationRoot/Asset") as Node2D

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
    assert_true(rectangle_shape.size.is_equal_approx(Vector2(96.0, 34.0)))
    var handhold_type_meta: Variant = handhold.get_meta(&"handhold_type")
    var handhold_route_role_meta: Variant = handhold.get_meta(&"route_role")
    assert_true(handhold_type_meta is String)
    assert_true(handhold_route_role_meta is String)
    var typed_handhold_type_meta: String = handhold_type_meta
    var typed_handhold_route_role_meta: String = handhold_route_role_meta
    assert_eq(typed_handhold_type_meta, "REST")
    assert_eq(typed_handhold_route_role_meta, "ENTRY")
    assert_not_null(handhold_presentation)

    assert_not_null(pickup_spawn)
    assert_true(pickup_spawn.is_in_group(GeneratedChunkSceneBuilderScript.PICKUP_GROUP_NAME))
    assert_true(pickup_spawn.position.is_equal_approx(Vector2(-60.0, -240.0)))
    assert_not_null(pickup_collision_shape)
    assert_not_null(pickup_circle_shape)
    assert_eq(pickup_circle_shape.radius, 18.0)
    assert_eq(pickup_spawn.coin_amount, 1)
    assert_not_null(pickup_visual)
    assert_not_null(pickup_animated_sprite)
    assert_not_null(pickup_animated_sprite.sprite_frames)
    assert_eq(pickup_animated_sprite.sprite_frames.get_frame_count(&"buff"), 48)

    assert_not_null(wind_gust_spawn)
    assert_true(wind_gust_spawn.is_in_group(GeneratedChunkSceneBuilderScript.HAZARD_GROUP_NAME))
    assert_true(wind_gust_spawn.is_in_group(GeneratedHazardSpawnAdapterScript.WIND_GUST_GROUP_NAME))
    assert_eq(wind_gust_spawn.hazard_kind, GeneratedHazardKindScript.Value.WIND_GUST)
    assert_true(wind_gust_spawn.position.is_equal_approx(Vector2(-40.0, -210.0)))
    assert_not_null(wind_collision_shape)
    assert_not_null(wind_rectangle_shape)
    assert_eq(wind_rectangle_shape.size, Vector2(96.0, 56.0))
    assert_true(wind_gust_spawn.get_impulse_vector_pixels().is_equal_approx(Vector2(220.0, -140.0)))
    assert_not_null(wind_presentation)
    assert_not_null(wind_animated_sprite)
    assert_not_null(wind_animated_sprite.sprite_frames)
    assert_eq(wind_animated_sprite.sprite_frames.get_frame_count(&"wind"), 50)

    assert_not_null(spike_cluster_spawn)
    assert_true(spike_cluster_spawn.is_in_group(GeneratedChunkSceneBuilderScript.HAZARD_GROUP_NAME))
    assert_true(spike_cluster_spawn.is_in_group(GeneratedHazardSpawnAdapterScript.SPIKE_CLUSTER_GROUP_NAME))
    assert_eq(spike_cluster_spawn.hazard_kind, GeneratedHazardKindScript.Value.SPIKE_CLUSTER)
    assert_true(spike_cluster_spawn.position.is_equal_approx(Vector2(90.0, -310.0)))
    assert_not_null(spike_collision_shape)
    assert_not_null(spike_rectangle_shape)
    assert_eq(spike_rectangle_shape.size, Vector2(36.0, 30.0))
    assert_not_null(spike_presentation)

    assert_not_null(downdraft_spawn)
    assert_true(downdraft_spawn.is_in_group(GeneratedChunkSceneBuilderScript.HAZARD_GROUP_NAME))
    assert_true(downdraft_spawn.is_in_group(GeneratedHazardSpawnAdapterScript.DOWNDRAFT_GROUP_NAME))
    assert_eq(downdraft_spawn.hazard_kind, GeneratedHazardKindScript.Value.DOWNDRAFT)
    assert_true(downdraft_spawn.position.is_equal_approx(Vector2(10.0, -260.0)))
    assert_not_null(downdraft_collision_shape)
    assert_not_null(downdraft_rectangle_shape)
    assert_eq(downdraft_rectangle_shape.size, Vector2(72.0, 96.0))
    assert_true(downdraft_spawn.get_impulse_vector_pixels().is_equal_approx(Vector2(-90.0, 260.0)))
    assert_not_null(downdraft_presentation)

    assert_not_null(updraft_spawn)
    assert_true(updraft_spawn.is_in_group(GeneratedChunkSceneBuilderScript.HAZARD_GROUP_NAME))
    assert_true(updraft_spawn.is_in_group(GeneratedHazardSpawnAdapterScript.UPDRAFT_GROUP_NAME))
    assert_eq(updraft_spawn.hazard_kind, GeneratedHazardKindScript.Value.UPDRAFT)
    assert_true(updraft_spawn.position.is_equal_approx(Vector2(-110.0, -180.0)))
    assert_not_null(updraft_collision_shape)
    assert_not_null(updraft_rectangle_shape)
    assert_eq(updraft_rectangle_shape.size, Vector2(68.0, 92.0))
    assert_true(updraft_spawn.get_impulse_vector_pixels().is_equal_approx(Vector2(110.0, -320.0)))
    assert_not_null(updraft_presentation)

    assert_not_null(falling_rock_spawn)
    assert_true(falling_rock_spawn.is_in_group(GeneratedChunkSceneBuilderScript.HAZARD_GROUP_NAME))
    assert_true(falling_rock_spawn.is_in_group(GeneratedHazardSpawnAdapterScript.FALLING_ROCK_GROUP_NAME))
    assert_eq(falling_rock_spawn.hazard_kind, GeneratedHazardKindScript.Value.FALLING_ROCK)
    assert_true(falling_rock_spawn.position.is_equal_approx(Vector2(50.0, -290.0)))
    assert_not_null(falling_rock_collision_shape)
    assert_not_null(falling_rock_rectangle_shape)
    assert_eq(falling_rock_rectangle_shape.size, Vector2(38.0, 36.0))
    assert_not_null(falling_rock_presentation)

    assert_not_null(pendulum_log_spawn)
    assert_true(pendulum_log_spawn.is_in_group(GeneratedChunkSceneBuilderScript.HAZARD_GROUP_NAME))
    assert_true(pendulum_log_spawn.is_in_group(GeneratedHazardSpawnAdapterScript.PENDULUM_LOG_GROUP_NAME))
    assert_eq(pendulum_log_spawn.hazard_kind, GeneratedHazardKindScript.Value.PENDULUM_LOG)
    assert_true(pendulum_log_spawn.position.is_equal_approx(Vector2(-90.0, -220.0)))
    assert_not_null(pendulum_log_collision_shape)
    assert_not_null(pendulum_log_rectangle_shape)
    assert_eq(pendulum_log_rectangle_shape.size, Vector2(56.0, 26.0))
    assert_not_null(pendulum_log_presentation)

    assert_not_null(wandering_critter_spawn)
    assert_true(wandering_critter_spawn.is_in_group(GeneratedChunkSceneBuilderScript.HAZARD_GROUP_NAME))
    assert_true(wandering_critter_spawn.is_in_group(GeneratedHazardSpawnAdapterScript.WANDERING_CRITTER_GROUP_NAME))
    assert_eq(wandering_critter_spawn.hazard_kind, GeneratedHazardKindScript.Value.WANDERING_CRITTER)
    assert_true(wandering_critter_spawn.position.is_equal_approx(Vector2(30.0, -160.0)))
    assert_not_null(wandering_critter_collision_shape)
    assert_not_null(wandering_critter_rectangle_shape)
    assert_eq(wandering_critter_rectangle_shape.size, Vector2(32.0, 24.0))
    assert_true(wandering_critter_spawn.get_impulse_vector_pixels().is_equal_approx(Vector2(-150.0, -60.0)))
    assert_not_null(wandering_critter_presentation)

    assert_not_null(startle_puff_spawn)
    assert_true(startle_puff_spawn.is_in_group(GeneratedChunkSceneBuilderScript.HAZARD_GROUP_NAME))
    assert_true(startle_puff_spawn.is_in_group(GeneratedHazardSpawnAdapterScript.STARTLE_PUFF_GROUP_NAME))
    assert_eq(startle_puff_spawn.hazard_kind, GeneratedHazardKindScript.Value.STARTLE_PUFF)
    assert_true(startle_puff_spawn.position.is_equal_approx(Vector2(-20.0, -340.0)))
    assert_not_null(startle_puff_collision_shape)
    assert_not_null(startle_puff_rectangle_shape)
    assert_eq(startle_puff_rectangle_shape.size, Vector2(36.0, 36.0))
    assert_not_null(startle_puff_presentation)

    assert_not_null(bug_swarm_spawn)
    assert_true(bug_swarm_spawn.is_in_group(GeneratedChunkSceneBuilderScript.HAZARD_GROUP_NAME))
    assert_true(bug_swarm_spawn.is_in_group(GeneratedHazardSpawnAdapterScript.BUG_SWARM_GROUP_NAME))
    assert_eq(bug_swarm_spawn.hazard_kind, GeneratedHazardKindScript.Value.BUG_SWARM)
    assert_true(bug_swarm_spawn.position.is_equal_approx(Vector2(130.0, -200.0)))
    assert_not_null(bug_swarm_collision_shape)
    assert_not_null(bug_swarm_rectangle_shape)
    assert_eq(bug_swarm_rectangle_shape.size, Vector2(40.0, 30.0))
    assert_not_null(bug_swarm_presentation)

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
        GeneratedHazardSocketScript.new(&"chunk_02_hazard_04", GeneratedHazardKindScript.Value.FALLING_ROCK, Vector2(0.5, -2.9)),
        GeneratedHazardSocketScript.new(&"chunk_02_hazard_05", GeneratedHazardKindScript.Value.PENDULUM_LOG, Vector2(-0.9, -2.2)),
        GeneratedHazardSocketScript.new(&"chunk_02_hazard_06", GeneratedHazardKindScript.Value.WANDERING_CRITTER, Vector2(0.3, -1.6)),
        GeneratedHazardSocketScript.new(&"chunk_02_hazard_07", GeneratedHazardKindScript.Value.STARTLE_PUFF, Vector2(-0.2, -3.4)),
        GeneratedHazardSocketScript.new(&"chunk_02_hazard_08", GeneratedHazardKindScript.Value.BUG_SWARM, Vector2(1.3, -2.0)),
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
        "generator_v1:2026-05-14",
        "generator_v1",
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
        route_validation_result
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
