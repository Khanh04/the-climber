extends GutTest

const ChunkDifficultyBandScript = preload("res://src/gameplay/generation/chunk_difficulty_band.gd")
const ChunkRouteLayoutEmitterScript: GDScript = preload("res://src/gameplay/generation/chunk_route_layout_emitter.gd")
const ChunkRoutePathSolutionScript = preload("res://src/gameplay/generation/chunk_route_path_solution.gd")
const ChunkRoutePathSolverScript = preload("res://src/gameplay/generation/chunk_route_path_solver.gd")
const ChunkRoutePlanBuilderScript = preload("res://src/gameplay/generation/chunk_route_plan_builder.gd")
const ChunkRoutePlanScript = preload("res://src/gameplay/generation/chunk_route_plan.gd")
const ChunkRoutePopulationBuilderScript: GDScript = preload("res://src/gameplay/generation/chunk_route_population_builder.gd")
const ChunkRouteSlotScript = preload("res://src/gameplay/generation/chunk_route_slot.gd")
const ChunkTypeScript = preload("res://src/gameplay/generation/chunk_type.gd")
const GeneratedChunkLayoutScript = preload("res://src/gameplay/generation/generated_chunk_layout.gd")
const GeneratedHazardKindScript = preload("res://src/gameplay/generation/generated_hazard_kind.gd")
const GenerationTuningScript = preload("res://resources/config/generation_tuning.gd")
const HandholdLifecycleRuleScript = preload("res://resources/config/handhold_lifecycle_rule.gd")
const HandholdMovementRuleScript = preload("res://resources/config/handhold_movement_rule.gd")
const HandholdSurfaceProfileScript = preload("res://resources/config/handhold_surface_profile.gd")
const HandholdTypeDefinitionScript = preload("res://resources/config/handhold_type_definition.gd")
const RouteAnchorGraphBuilderScript = preload("res://src/gameplay/generation/route_anchor_graph_builder.gd")
const RouteAnchorGraphScript = preload("res://src/gameplay/generation/route_anchor_graph.gd")
const RouteRoleScript = preload("res://src/gameplay/generation/route_role.gd")

func test_emitter_builds_valid_layout_with_route_first_metadata() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var plan: ChunkRoutePlanScript = _build_plan(7, ChunkRouteSlotScript.Value.RISK, ChunkDifficultyBandScript.Value.BASELINE)
    var population: RefCounted = _build_population(plan)
    var layout: GeneratedChunkLayoutScript = _emit_layout(tuning, plan, population)

    layout.assert_valid()
    assert_eq(layout.seed_key, _seed_key())
    assert_eq(layout.generator_version, tuning.generator_version)
    assert_eq(layout.chunk_index, plan.chunk_index)
    assert_eq(layout.route_slot, plan.route_slot)
    assert_eq(layout.difficulty_band, plan.difficulty_band)
    assert_eq(layout.chunk_type, ChunkTypeScript.Value.RISK_LANE)
    assert_almost_eq(layout.start_height_meters, float(plan.chunk_index) * tuning.segment_height_meters, 0.001)
    assert_eq(layout.handholds.size(), _call_int(population, &"get_hold_count"))
    assert_gt(layout.route_entry_hold_ids.size(), 0)
    assert_gt(layout.route_exit_hold_ids.size(), 0)

func test_emitter_preserves_route_roles_and_handhold_definition_data() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var plan: ChunkRoutePlanScript = _build_plan(12, ChunkRouteSlotScript.Value.PRESSURE, ChunkDifficultyBandScript.Value.CHALLENGE)
    var population: RefCounted = _build_population(plan)
    var layout: GeneratedChunkLayoutScript = _emit_layout(tuning, plan, population)

    for handhold in layout.handholds:
        var definition: HandholdTypeDefinitionScript = tuning.get_required_handhold_definition(handhold.handhold_type)
        var surface_profile: HandholdSurfaceProfileScript = definition.surface_profile as HandholdSurfaceProfileScript
        var lifecycle_rule: HandholdLifecycleRuleScript = definition.lifecycle_rule as HandholdLifecycleRuleScript
        var movement_rule: HandholdMovementRuleScript = definition.movement_rule as HandholdMovementRuleScript

        assert_eq(handhold.definition_id, definition.definition_id)
        assert_true(handhold.physical_size_meters.is_equal_approx(definition.physical_size_meters))
        assert_eq(handhold.visual_color, definition.visual_color)
        assert_almost_eq(handhold.stamina_drain_multiplier, surface_profile.stamina_drain_multiplier, 0.001)
        assert_almost_eq(handhold.break_after_attach_seconds, lifecycle_rule.break_after_attach_seconds, 0.001)
        assert_eq(handhold.breaks_on_release, lifecycle_rule.breaks_on_release)
        assert_true(handhold.release_impulse_vector_pixels.is_equal_approx(movement_rule.release_impulse_vector))
        RouteRoleScript.assert_valid(handhold.route_role)

func test_emitter_turns_reward_placements_into_pickup_sockets_above_anchor() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var plan: ChunkRoutePlanScript = _build_plan(3, ChunkRouteSlotScript.Value.RECOVERY, ChunkDifficultyBandScript.Value.EASY)
    var population: RefCounted = _build_population(plan)
    var layout: GeneratedChunkLayoutScript = _emit_layout(tuning, plan, population)
    var reward_placements: Array[RefCounted] = _require_ref_counted_array_property(population, &"reward_placements")
    var reward_position: Vector2 = _require_vector2_property(reward_placements[0], &"local_position")

    assert_eq(layout.pickup_sockets.size(), reward_placements.size())
    assert_eq(String(layout.pickup_sockets[0].socket_id), "chunk_03_pickup_00")
    assert_almost_eq(layout.pickup_sockets[0].local_position.x, reward_position.x, 0.001)
    assert_lt(layout.pickup_sockets[0].local_position.y, reward_position.y)
    assert_gte(layout.pickup_sockets[0].local_position.x, -tuning.chunk_width_meters * 0.5)
    assert_lte(layout.pickup_sockets[0].local_position.x, tuning.chunk_width_meters * 0.5)

func test_emitter_turns_hazard_placements_into_socket_kinds_and_offsets() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var plan: ChunkRoutePlanScript = _build_plan(12, ChunkRouteSlotScript.Value.PRESSURE, ChunkDifficultyBandScript.Value.CHALLENGE)
    var population: RefCounted = _build_population(plan)
    var layout: GeneratedChunkLayoutScript = _emit_layout(tuning, plan, population)
    var hazard_placements: Array[RefCounted] = _require_ref_counted_array_property(population, &"hazard_placements")

    assert_eq(layout.hazard_sockets.size(), hazard_placements.size())
    for socket_index in range(layout.hazard_sockets.size()):
        var hazard_placement: RefCounted = hazard_placements[socket_index]
        var hazard_kind: int = _require_int_property(hazard_placement, &"hazard_kind")
        var expected_position: Vector2 = _expected_hazard_position(tuning, hazard_placement)

        assert_eq(layout.hazard_sockets[socket_index].hazard_kind, hazard_kind)
        assert_eq(String(layout.hazard_sockets[socket_index].socket_id), "chunk_12_hazard_%02d" % socket_index)
        assert_true(layout.hazard_sockets[socket_index].local_position.is_equal_approx(expected_position))

func test_emitter_maps_route_movement_styles_to_existing_chunk_type_metadata() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var recovery_plan: ChunkRoutePlanScript = _build_plan(3, ChunkRouteSlotScript.Value.RECOVERY, ChunkDifficultyBandScript.Value.EASY)
    var pressure_plan: ChunkRoutePlanScript = _build_plan(12, ChunkRouteSlotScript.Value.PRESSURE, ChunkDifficultyBandScript.Value.CHALLENGE)
    var skill_plan: ChunkRoutePlanScript = _build_plan(8, ChunkRouteSlotScript.Value.SKILL, ChunkDifficultyBandScript.Value.BASELINE)

    assert_eq(_emit_layout(tuning, recovery_plan, _build_population(recovery_plan)).chunk_type, ChunkTypeScript.Value.DENSE_RECOVERY)
    assert_eq(_emit_layout(tuning, pressure_plan, _build_population(pressure_plan)).chunk_type, ChunkTypeScript.Value.SWING_GAP)
    assert_eq(_emit_layout(tuning, skill_plan, _build_population(skill_plan)).chunk_type, ChunkTypeScript.Value.WIDE_TRAVERSE)

func _build_plan(chunk_index: int, route_slot: int, difficulty_band: int) -> ChunkRoutePlanScript:
    var builder: ChunkRoutePlanBuilderScript = ChunkRoutePlanBuilderScript.new()
    return builder.build_plan(_seed_key(), chunk_index, route_slot, difficulty_band)

func _build_graph(plan: ChunkRoutePlanScript) -> RouteAnchorGraphScript:
    var graph_builder: RouteAnchorGraphBuilderScript = RouteAnchorGraphBuilderScript.new(4.0, 0.8)
    return graph_builder.build_graph(plan)

func _solve(plan: ChunkRoutePlanScript, anchor_graph: RouteAnchorGraphScript) -> ChunkRoutePathSolutionScript:
    var solver: ChunkRoutePathSolverScript = ChunkRoutePathSolverScript.new()
    return solver.solve(plan, anchor_graph)

func _build_population(plan: ChunkRoutePlanScript) -> RefCounted:
    var anchor_graph: RouteAnchorGraphScript = _build_graph(plan)
    var path_solution: ChunkRoutePathSolutionScript = _solve(plan, anchor_graph)
    assert_true(path_solution.is_valid)

    var builder_variant: Variant = ChunkRoutePopulationBuilderScript.new()
    assert_true(builder_variant is RefCounted)
    var builder: RefCounted = builder_variant
    var population_variant: Variant = builder.call("populate", plan, anchor_graph, path_solution)
    assert_true(population_variant is RefCounted)
    var population: RefCounted = population_variant
    return population

func _emit_layout(tuning: GenerationTuningScript, plan: ChunkRoutePlanScript, population: RefCounted) -> GeneratedChunkLayoutScript:
    var emitter_variant: Variant = ChunkRouteLayoutEmitterScript.new(tuning)
    assert_true(emitter_variant is RefCounted)
    var emitter: RefCounted = emitter_variant
    var layout_variant: Variant = emitter.call("emit_layout", _seed_key(), plan, population)
    assert_true(layout_variant is GeneratedChunkLayoutScript)
    var layout_ref: RefCounted = layout_variant
    var layout: GeneratedChunkLayoutScript = layout_ref as GeneratedChunkLayoutScript
    return layout

func _seed_key() -> String:
    return DailySeedKey.from_utc_date(2026, 5, 16)

func _call_int(source: RefCounted, method_name: StringName) -> int:
    var raw_value: Variant = source.call(method_name)
    assert_true(raw_value is int)
    var typed_value: int = raw_value
    return typed_value

func _require_ref_counted_array_property(source: RefCounted, property_name: StringName) -> Array[RefCounted]:
    var raw_value: Variant = source.get(property_name)
    assert_true(raw_value is Array)
    var raw_array: Array = raw_value
    var typed_values: Array[RefCounted] = []
    for value in raw_array:
        assert_true(value is RefCounted)
        var typed_value: RefCounted = value
        typed_values.append(typed_value)
    return typed_values

func _require_int_property(source: RefCounted, property_name: StringName) -> int:
    var raw_value: Variant = source.get(property_name)
    assert_true(raw_value is int)
    var typed_value: int = raw_value
    return typed_value

func _require_vector2_property(source: RefCounted, property_name: StringName) -> Vector2:
    var raw_value: Variant = source.get(property_name)
    assert_true(raw_value is Vector2)
    var typed_value: Vector2 = raw_value
    return typed_value

func _expected_hazard_position(tuning: GenerationTuningScript, hazard_placement: RefCounted) -> Vector2:
    var hazard_kind: int = _require_int_property(hazard_placement, &"hazard_kind")
    var anchor_position: Vector2 = _require_vector2_property(hazard_placement, &"local_position")
    var clamped_x: float = clampf(anchor_position.x, -tuning.chunk_width_meters * 0.5, tuning.chunk_width_meters * 0.5)

    match hazard_kind:
        GeneratedHazardKindScript.Value.SPIKE_CLUSTER:
            return Vector2(clamped_x, anchor_position.y + 0.4)
        GeneratedHazardKindScript.Value.WIND_GUST:
            return Vector2(clamped_x, anchor_position.y - 0.15)
        GeneratedHazardKindScript.Value.DOWNDRAFT:
            return Vector2(clamped_x, anchor_position.y - 0.55)
        GeneratedHazardKindScript.Value.UPDRAFT:
            return Vector2(clamped_x, anchor_position.y - 0.9)
        _:
            Validation.require_condition(false, "Test helper requires a supported hazard kind.")
            return anchor_position