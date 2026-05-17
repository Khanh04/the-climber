extends GutTest

const ChunkDifficultyBandScript = preload("res://src/gameplay/generation/chunk_difficulty_band.gd")
const ChunkRoutePathSolutionScript = preload("res://src/gameplay/generation/chunk_route_path_solution.gd")
const ChunkRoutePathSolverScript = preload("res://src/gameplay/generation/chunk_route_path_solver.gd")
const ChunkRoutePlanBuilderScript = preload("res://src/gameplay/generation/chunk_route_plan_builder.gd")
const ChunkRoutePlanScript = preload("res://src/gameplay/generation/chunk_route_plan.gd")
const ChunkRoutePopulationBuilderScript: GDScript = preload("res://src/gameplay/generation/chunk_route_population_builder.gd")
const ChunkRouteSlotScript = preload("res://src/gameplay/generation/chunk_route_slot.gd")
const GeneratedHazardIntentScript = preload("res://src/gameplay/generation/generated_hazard_intent.gd")
const GeneratedHazardKindScript = preload("res://src/gameplay/generation/generated_hazard_kind.gd")
const RouteAnchorGraphBuilderScript = preload("res://src/gameplay/generation/route_anchor_graph_builder.gd")
const RouteAnchorGraphScript = preload("res://src/gameplay/generation/route_anchor_graph.gd")
const RouteBranchSideScript = preload("res://src/gameplay/generation/route_branch_side.gd")
const RouteLaneScript = preload("res://src/gameplay/generation/route_lane.gd")
const RouteRoleScript = preload("res://src/gameplay/generation/route_role.gd")

func test_easy_opener_population_adds_beginner_support_without_flat_bars() -> void:
    var plan: ChunkRoutePlanScript = _build_plan(0, ChunkRouteSlotScript.Value.OPENER, ChunkDifficultyBandScript.Value.EASY)
    var population: RefCounted = _build_population(plan)

    assert_eq(_call_int(population, &"count_safe_path_holds"), plan.get_row_count())
    assert_eq(_call_int(population, &"count_optional_path_holds"), 0)
    assert_eq(_call_int(population, &"count_support_holds"), plan.get_row_count() + 2)

    for row_index in range(plan.get_row_count()):
        assert_gte(_call_int_with_argument(population, &"count_holds_in_row", row_index), 2)

    assert_gte(_call_int_with_argument(population, &"count_holds_in_row", 0), 3)
    assert_gte(_call_int_with_argument(population, &"count_holds_in_row", plan.get_row_count() - 1), 3)

    for hold in _require_ref_counted_array_property(population, &"holds"):
        if _require_bool_property(hold, &"is_safe_path"):
            assert_true(plan.safe_path_allows_handhold_type(_require_int_property(hold, &"handhold_type")))

func test_skill_population_marks_horizontal_branch_as_optional_beta() -> void:
    var plan: ChunkRoutePlanScript = _build_plan(2, ChunkRouteSlotScript.Value.SKILL, ChunkDifficultyBandScript.Value.EASY)
    var population: RefCounted = _build_population(plan)

    assert_eq(_call_int(population, &"count_safe_path_holds"), plan.get_row_count())
    assert_eq(_call_int(population, &"count_optional_path_holds"), plan.get_row_count())
    assert_gte(_call_int_with_argument(population, &"count_holds_with_route_role", RouteRoleScript.Value.OPTIONAL_BETA), plan.minimum_branch_separation_rows)

    for hold in _require_ref_counted_array_property(population, &"holds"):
        if _require_bool_property(hold, &"is_optional_path") and not _require_bool_property(hold, &"is_safe_path"):
            assert_true(plan.optional_path_allows_handhold_type(_require_int_property(hold, &"handhold_type")))
            assert_eq(_require_int_property(hold, &"route_role"), RouteRoleScript.Value.OPTIONAL_BETA)

func test_risk_population_places_reward_and_branch_denial_hazard_on_outer_branch() -> void:
    var plan: ChunkRoutePlanScript = _build_plan(7, ChunkRouteSlotScript.Value.RISK, ChunkDifficultyBandScript.Value.BASELINE)
    var population: RefCounted = _build_population(plan)
    var reward_placements: Array[RefCounted] = _require_ref_counted_array_property(population, &"reward_placements")
    var denial_hazard: RefCounted = _call_ref_counted_with_argument(
        population,
        &"find_hazard_placement_for_intent",
        GeneratedHazardIntentScript.Value.OPTIONAL_BRANCH_DENIAL
    )

    assert_eq(reward_placements.size(), 1)
    assert_gte(_call_int_with_argument(population, &"count_holds_with_route_role", RouteRoleScript.Value.HAZARD_DENIAL), plan.minimum_branch_separation_rows)
    assert_not_null(denial_hazard)
    assert_eq(_require_int_property(denial_hazard, &"hazard_kind"), GeneratedHazardKindScript.Value.SPIKE_CLUSTER)
    assert_eq(RouteLaneScript.to_branch_side(_require_int_property(denial_hazard, &"lane")), plan.route_branch_side)
    assert_true(RouteLaneScript.is_outer(_require_int_property(denial_hazard, &"lane")))

func test_pressure_population_maps_crux_and_branch_hazard_intents_to_specific_kinds() -> void:
    var plan: ChunkRoutePlanScript = _build_plan(12, ChunkRouteSlotScript.Value.PRESSURE, ChunkDifficultyBandScript.Value.CHALLENGE)
    var population: RefCounted = _build_population(plan)
    var crux_hazard: RefCounted = _call_ref_counted_with_argument(
        population,
        &"find_hazard_placement_for_intent",
        GeneratedHazardIntentScript.Value.CRUX_PRESSURE
    )
    var denial_hazard: RefCounted = _call_ref_counted_with_argument(
        population,
        &"find_hazard_placement_for_intent",
        GeneratedHazardIntentScript.Value.OPTIONAL_BRANCH_DENIAL
    )

    assert_not_null(crux_hazard)
    assert_not_null(denial_hazard)
    assert_eq(_require_int_property(crux_hazard, &"hazard_kind"), GeneratedHazardKindScript.Value.DOWNDRAFT)
    assert_eq(_require_int_property(denial_hazard, &"hazard_kind"), GeneratedHazardKindScript.Value.SPIKE_CLUSTER)
    assert_eq(RouteLaneScript.to_branch_side(_require_int_property(crux_hazard, &"lane")), _get_opposite_branch_side(plan.route_branch_side))
    assert_eq(RouteLaneScript.to_branch_side(_require_int_property(denial_hazard, &"lane")), plan.route_branch_side)

func test_recovery_population_places_reward_and_updraft_relief_on_safe_route() -> void:
    var plan: ChunkRoutePlanScript = _build_plan(3, ChunkRouteSlotScript.Value.RECOVERY, ChunkDifficultyBandScript.Value.EASY)
    var population: RefCounted = _build_population(plan)
    var reward_placements: Array[RefCounted] = _require_ref_counted_array_property(population, &"reward_placements")
    var recovery_lift_hazard: RefCounted = _call_ref_counted_with_argument(
        population,
        &"find_hazard_placement_for_intent",
        GeneratedHazardIntentScript.Value.RECOVERY_LIFT
    )
    var safe_relief_hazard: RefCounted = _call_ref_counted_with_argument(
        population,
        &"find_hazard_placement_for_intent",
        GeneratedHazardIntentScript.Value.SAFE_ROUTE_RELIEF
    )

    assert_eq(reward_placements.size(), 1)
    assert_not_null(recovery_lift_hazard)
    assert_not_null(safe_relief_hazard)
    assert_eq(_require_int_property(recovery_lift_hazard, &"hazard_kind"), GeneratedHazardKindScript.Value.UPDRAFT)
    assert_eq(_require_int_property(safe_relief_hazard, &"hazard_kind"), GeneratedHazardKindScript.Value.UPDRAFT)
    assert_false(RouteLaneScript.is_outer(_require_int_property(recovery_lift_hazard, &"lane")))

func _build_plan(chunk_index: int, route_slot: int, difficulty_band: int) -> ChunkRoutePlanScript:
    var builder: ChunkRoutePlanBuilderScript = ChunkRoutePlanBuilderScript.new()
    return builder.build_plan(DailySeedKey.from_utc_date(2026, 5, 16), chunk_index, route_slot, difficulty_band)

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

func _call_int(source: RefCounted, method_name: StringName) -> int:
    var raw_value: Variant = source.call(method_name)
    assert_true(raw_value is int)
    var typed_value: int = raw_value
    return typed_value

func _call_int_with_argument(source: RefCounted, method_name: StringName, argument: int) -> int:
    var raw_value: Variant = source.call(method_name, argument)
    assert_true(raw_value is int)
    var typed_value: int = raw_value
    return typed_value

func _call_ref_counted_with_argument(source: RefCounted, method_name: StringName, argument: int) -> RefCounted:
    var raw_value: Variant = source.call(method_name, argument)
    assert_true(raw_value is RefCounted)
    var typed_value: RefCounted = raw_value
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

func _require_bool_property(source: RefCounted, property_name: StringName) -> bool:
    var raw_value: Variant = source.get(property_name)
    assert_true(raw_value is bool)
    var typed_value: bool = raw_value
    return typed_value

func _get_outer_lane_for_branch_side(branch_side: int) -> int:
    RouteBranchSideScript.assert_valid(branch_side)
    Validation.require_condition(branch_side != RouteBranchSideScript.Value.NONE, "Test helper requires a branch side.")
    if branch_side == RouteBranchSideScript.Value.LEFT:
        return RouteLaneScript.Value.OUTER_LEFT

    return RouteLaneScript.Value.OUTER_RIGHT

func _get_opposite_branch_side(branch_side: int) -> int:
    RouteBranchSideScript.assert_valid(branch_side)
    Validation.require_condition(branch_side != RouteBranchSideScript.Value.NONE, "Test helper requires a branch side.")
    if branch_side == RouteBranchSideScript.Value.LEFT:
        return RouteBranchSideScript.Value.RIGHT

    return RouteBranchSideScript.Value.LEFT