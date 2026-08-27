extends GutTest

const ChunkDifficultyBandScript = preload("res://src/gameplay/generation/chunk_difficulty_band.gd")
const ChunkRouteSlotScript = preload("res://src/gameplay/generation/chunk_route_slot.gd")
const ChunkTypeScript = preload("res://src/gameplay/generation/chunk_type.gd")
const GenerationTuningScript = preload("res://resources/config/generation_tuning.gd")
const GeneratedChunkLayoutScript = preload("res://src/gameplay/generation/generated_chunk_layout.gd")
const GeneratedHandholdSocketScript = preload("res://src/gameplay/generation/generated_handhold_socket.gd")
const HandholdLifecycleRuleScript = preload("res://resources/config/handhold_lifecycle_rule.gd")
const HandholdMovementRuleScript = preload("res://resources/config/handhold_movement_rule.gd")
const HandholdSurfaceProfileScript = preload("res://resources/config/handhold_surface_profile.gd")
const HandholdTypeDefinitionScript = preload("res://resources/config/handhold_type_definition.gd")
const HandholdTypeScript = preload("res://src/gameplay/generation/handhold_type.gd")
const RouteGraphBuilderScript = preload("res://src/gameplay/generation/route_graph_builder.gd")
const RouteMoveKindScript = preload("res://src/gameplay/generation/route_move_kind.gd")
const RouteRoleScript = preload("res://src/gameplay/generation/route_role.gd")

func test_builder_creates_static_reach_edges_for_reachable_layout() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var builder: RefCounted = RouteGraphBuilderScript.new(0.96)
    var layout: GeneratedChunkLayoutScript = _build_layout_fixture(
        tuning,
        [
            _build_handhold_socket(tuning, StringName("first"), Vector2(-0.42, -0.42), RouteRoleScript.Value.ENTRY),
            _build_handhold_socket(tuning, StringName("second"), Vector2(0.10, -1.08), RouteRoleScript.Value.SETUP),
            _build_handhold_socket(tuning, StringName("top"), Vector2(0.34, -1.84), RouteRoleScript.Value.TOP_OUT),
        ],
        PackedStringArray(["first"]),
        PackedStringArray(["top"])
    )

    var route_graph_variant: Variant = builder.call("build_layout_graph", layout)
    assert_true(route_graph_variant is RefCounted)
    var route_graph: RefCounted = route_graph_variant
    var first_index_variant: Variant = route_graph.call("get_required_node_index_by_hold_id", "first")
    var second_index_variant: Variant = route_graph.call("get_required_node_index_by_hold_id", "second")
    assert_true(first_index_variant is int)
    assert_true(second_index_variant is int)
    var first_index: int = first_index_variant
    var second_index: int = second_index_variant
    var first_outgoing_edges_variant: Variant = route_graph.call("get_outgoing_edges", first_index)
    assert_true(first_outgoing_edges_variant is Array)
    var first_outgoing_edges: Array = first_outgoing_edges_variant
    var graph_nodes: Array = _require_array_property(route_graph, &"nodes")
    var entry_port_hold_ids: PackedStringArray = _require_packed_string_array_property(route_graph, &"entry_port_hold_ids")
    var exit_port_hold_ids: PackedStringArray = _require_packed_string_array_property(route_graph, &"exit_port_hold_ids")
    var has_expected_edge: bool = false

    assert_eq(graph_nodes.size(), 3)
    assert_eq(entry_port_hold_ids, PackedStringArray(["first"]))
    assert_eq(exit_port_hold_ids, PackedStringArray(["top"]))
    for edge_variant in first_outgoing_edges:
        assert_true(edge_variant is RefCounted)
        var edge: RefCounted = edge_variant
        var to_node_index: int = _require_int_property(edge, &"to_node_index")
        if to_node_index == second_index:
            var move_kind: int = _require_int_property(edge, &"move_kind")
            assert_eq(move_kind, RouteMoveKindScript.Value.STATIC_REACH)
            has_expected_edge = true
            break

    assert_true(has_expected_edge)

func test_builder_rejects_edges_that_exceed_downward_move_limit() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var builder: RefCounted = RouteGraphBuilderScript.new(1.5, 0.12)
    var layout: GeneratedChunkLayoutScript = _build_layout_fixture(
        tuning,
        [
            _build_handhold_socket(tuning, StringName("top"), Vector2(0.05, -1.50), RouteRoleScript.Value.TOP_OUT),
            _build_handhold_socket(tuning, StringName("lower"), Vector2(-0.10, -0.20), RouteRoleScript.Value.SETUP),
        ],
        PackedStringArray(["top"]),
        PackedStringArray(["lower"])
    )

    var route_graph_variant: Variant = builder.call("build_layout_graph", layout)
    assert_true(route_graph_variant is RefCounted)
    var route_graph: RefCounted = route_graph_variant
    var top_index_variant: Variant = route_graph.call("get_required_node_index_by_hold_id", "top")
    var lower_index_variant: Variant = route_graph.call("get_required_node_index_by_hold_id", "lower")
    assert_true(top_index_variant is int)
    assert_true(lower_index_variant is int)
    var top_index: int = top_index_variant
    var lower_index: int = lower_index_variant
    var top_outgoing_edges_variant: Variant = route_graph.call("get_outgoing_edges", top_index)
    assert_true(top_outgoing_edges_variant is Array)
    var top_outgoing_edges: Array = top_outgoing_edges_variant

    for edge_variant in top_outgoing_edges:
        assert_true(edge_variant is RefCounted)
        var edge: RefCounted = edge_variant
        var to_node_index: int = _require_int_property(edge, &"to_node_index")
        assert_ne(to_node_index, lower_index)

func test_builder_marks_moves_beyond_runtime_grip_radius_as_swing_reach() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var builder: RefCounted = RouteGraphBuilderScript.new(2.2, 0.12, 0.96)
    var layout: GeneratedChunkLayoutScript = _build_layout_fixture(
        tuning,
        [
            _build_handhold_socket(tuning, &"first", Vector2.ZERO, RouteRoleScript.Value.ENTRY),
            _build_handhold_socket(tuning, &"swing", Vector2(1.4, -0.6), RouteRoleScript.Value.TOP_OUT),
        ],
        PackedStringArray(["first"]),
        PackedStringArray(["swing"])
    )

    var route_graph: RefCounted = builder.call("build_layout_graph", layout)
    var first_index: int = route_graph.call("get_required_node_index_by_hold_id", "first")
    var swing_index: int = route_graph.call("get_required_node_index_by_hold_id", "swing")
    var first_outgoing_edges: Array = route_graph.call("get_outgoing_edges", first_index)
    var found_swing_edge: bool = false
    for edge_variant in first_outgoing_edges:
        var edge: RefCounted = edge_variant
        if _require_int_property(edge, &"to_node_index") != swing_index:
            continue
        assert_eq(_require_int_property(edge, &"move_kind"), RouteMoveKindScript.Value.SWING_REACH)
        found_swing_edge = true

    assert_true(found_swing_edge)

func _require_array_property(source: Object, property_name: StringName) -> Array:
    var raw_value: Variant = source.get(property_name)
    assert_true(raw_value is Array)
    if not raw_value is Array:
        return []

    var values: Array = raw_value
    return values

func _require_int_property(source: Object, property_name: StringName) -> int:
    var raw_value: Variant = source.get(property_name)
    assert_true(raw_value is int)
    if not raw_value is int:
        return -1

    var value: int = raw_value
    return value

func _require_packed_string_array_property(source: Object, property_name: StringName) -> PackedStringArray:
    var raw_value: Variant = source.get(property_name)
    assert_true(raw_value is PackedStringArray)
    if not raw_value is PackedStringArray:
        return PackedStringArray()

    var value: PackedStringArray = raw_value
    return value

func _build_layout_fixture(
    tuning: GenerationTuningScript,
    handholds: Array[GeneratedHandholdSocket],
    route_entry_hold_ids: PackedStringArray,
    route_exit_hold_ids: PackedStringArray
) -> GeneratedChunkLayoutScript:
    var pickup_sockets: Array[GeneratedPickupSocket] = []
    var hazard_sockets: Array[GeneratedHazardSocket] = []
    return GeneratedChunkLayoutScript.new(
        DailySeedKey.from_utc_date(2026, 5, 14),
        DailySeedKey.GENERATOR_VERSION,
        0,
        ChunkTypeScript.Value.LADDER,
        ChunkRouteSlotScript.Value.OPENER,
        ChunkDifficultyBandScript.Value.EASY,
        0.0,
        handholds,
        pickup_sockets,
        hazard_sockets,
        route_entry_hold_ids,
        route_exit_hold_ids
    )

func _build_handhold_socket(
    tuning: GenerationTuningScript,
    hold_id: StringName,
    local_position: Vector2,
    route_role: int
) -> GeneratedHandholdSocketScript:
    var definition: HandholdTypeDefinitionScript = tuning.get_required_handhold_definition(HandholdTypeScript.Value.NORMAL)
    var surface_profile: HandholdSurfaceProfileScript = definition.surface_profile as HandholdSurfaceProfileScript
    var lifecycle_rule: HandholdLifecycleRuleScript = definition.lifecycle_rule as HandholdLifecycleRuleScript
    var movement_rule: HandholdMovementRuleScript = definition.movement_rule as HandholdMovementRuleScript
    return GeneratedHandholdSocketScript.new(
        hold_id,
        definition.definition_id,
        local_position,
        HandholdTypeScript.Value.NORMAL,
        surface_profile.stamina_drain_multiplier,
        definition.physical_size_meters,
        definition.visual_color,
        lifecycle_rule.break_after_attach_seconds,
        lifecycle_rule.breaks_on_release,
        movement_rule.release_impulse_vector,
        route_role
    )
