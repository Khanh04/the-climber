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
const RouteRowRoleScript = preload("res://src/gameplay/generation/route_row_role.gd")

func test_easy_opener_population_adds_beginner_support_without_flat_bars() -> void:
    var plan: ChunkRoutePlanScript = _build_plan(0, ChunkRouteSlotScript.Value.OPENER, ChunkDifficultyBandScript.Value.EASY)
    var population: RefCounted = _build_population(plan)

    assert_eq(_call_int(population, &"count_safe_path_holds"), plan.get_row_count())
    assert_eq(_call_int(population, &"count_optional_path_holds"), 0)
    assert_gt(_call_int(population, &"count_support_holds"), 0)

    for row_index in range(plan.get_row_count()):
        assert_gte(_call_int_with_argument(population, &"count_holds_in_row", row_index), 1)

    for hold in _require_ref_counted_array_property(population, &"holds"):
        if _require_bool_property(hold, &"is_safe_path"):
            assert_true(plan.safe_path_allows_handhold_type(_require_int_property(hold, &"handhold_type")))

func test_row_zero_support_mirrors_the_fixed_entry_lane() -> void:
    # Row 0 always enters through INNER_LEFT; its one support hold should be the mirrored
    # INNER_RIGHT, leaving the centre corridor between them clear for the player's body.
    var plan: ChunkRoutePlanScript = _build_plan(0, ChunkRouteSlotScript.Value.OPENER, ChunkDifficultyBandScript.Value.EASY)
    var population: RefCounted = _build_population(plan)

    assert_eq(_call_int_with_argument(population, &"count_holds_in_row", 0), 2)
    assert_eq(_get_support_lanes_in_row(population, 0), [RouteLaneScript.Value.INNER_RIGHT])

func test_support_lanes_never_collide_with_the_safe_or_optional_path() -> void:
    var plan: ChunkRoutePlanScript = _build_plan(7, ChunkRouteSlotScript.Value.RISK, ChunkDifficultyBandScript.Value.BASELINE)
    var anchor_graph: RouteAnchorGraphScript = _build_graph(plan)
    var path_solution: ChunkRoutePathSolutionScript = _solve(plan, anchor_graph)
    var population: RefCounted = _build_population(plan)

    for row_index in range(plan.get_row_count()):
        var safe_lane: int = path_solution.safe_path.get_lane_at_row(row_index)
        var optional_lane: int = path_solution.optional_path.get_lane_at_row(row_index)
        for support_lane in _get_support_lanes_in_row(population, row_index):
            assert_ne(support_lane, safe_lane, "row %d support collided with the safe path" % row_index)
            assert_ne(support_lane, optional_lane, "row %d support collided with the optional path" % row_index)

func test_support_lanes_keep_swing_clearance_from_the_safe_path() -> void:
    var plan: ChunkRoutePlanScript = _build_plan(2, ChunkRouteSlotScript.Value.SKILL, ChunkDifficultyBandScript.Value.EASY)
    var anchor_graph: RouteAnchorGraphScript = _build_graph(plan)
    var path_solution: ChunkRoutePathSolutionScript = _solve(plan, anchor_graph)
    var population: RefCounted = _build_population(plan)
    var player_body_width_meters: float = 0.48

    for row_index in range(plan.get_row_count()):
        var safe_lane: int = path_solution.safe_path.get_lane_at_row(row_index)
        var safe_position: Vector2 = anchor_graph.get_anchor_for_row_and_lane(row_index, safe_lane).local_position
        for support_lane in _get_support_lanes_in_row(population, row_index):
            var support_position: Vector2 = anchor_graph.get_anchor_for_row_and_lane(row_index, support_lane).local_position
            assert_gte(absf(support_position.x - safe_position.x), player_body_width_meters)

func test_crux_pressure_and_traverse_rows_stay_clear_of_support_holds() -> void:
    var plan: ChunkRoutePlanScript = _build_plan(4, ChunkRouteSlotScript.Value.PRESSURE, ChunkDifficultyBandScript.Value.CHALLENGE)
    var population: RefCounted = _build_population(plan)

    for row_index in range(plan.get_row_count()):
        var row_role: int = plan.row_roles[row_index]
        if row_role == RouteRowRoleScript.Value.CRUX or row_role == RouteRowRoleScript.Value.PRESSURE or row_role == RouteRowRoleScript.Value.TRAVERSE:
            assert_eq(_get_support_lanes_in_row(population, row_index).size(), 0)

func test_easier_bands_place_at_least_as_much_support_as_challenge() -> void:
    var easy_plan: ChunkRoutePlanScript = _build_plan(1, ChunkRouteSlotScript.Value.BASELINE, ChunkDifficultyBandScript.Value.EASY)
    var challenge_plan: ChunkRoutePlanScript = _build_plan(1, ChunkRouteSlotScript.Value.BASELINE, ChunkDifficultyBandScript.Value.CHALLENGE)
    var easy_population: RefCounted = _build_population(easy_plan)
    var challenge_population: RefCounted = _build_population(challenge_plan)

    assert_gt(_call_int(easy_population, &"count_support_holds"), _call_int(challenge_population, &"count_support_holds"))

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
    var greed_hazard: RefCounted = _call_ref_counted_with_argument(
        population,
        &"find_hazard_placement_for_intent",
        GeneratedHazardIntentScript.Value.REWARD_GREED_PRESSURE
    )

    assert_eq(reward_placements.size(), 1)
    assert_gte(_call_int_with_argument(population, &"count_holds_with_route_role", RouteRoleScript.Value.HAZARD_DENIAL), plan.minimum_branch_separation_rows)
    assert_not_null(denial_hazard)
    assert_not_null(greed_hazard)
    assert_true([GeneratedHazardKindScript.Value.SPIKE_CLUSTER, GeneratedHazardKindScript.Value.FALLING_ROCK, GeneratedHazardKindScript.Value.PENDULUM_LOG].has(_require_int_property(denial_hazard, &"hazard_kind")))
    assert_eq(_require_int_property(greed_hazard, &"hazard_kind"), GeneratedHazardKindScript.Value.BUG_SWARM)
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
    assert_true([GeneratedHazardKindScript.Value.SPIKE_CLUSTER, GeneratedHazardKindScript.Value.FALLING_ROCK, GeneratedHazardKindScript.Value.PENDULUM_LOG].has(_require_int_property(denial_hazard, &"hazard_kind")))
    assert_eq(RouteLaneScript.to_branch_side(_require_int_property(crux_hazard, &"lane")), _get_opposite_branch_side(plan.route_branch_side))
    assert_eq(RouteLaneScript.to_branch_side(_require_int_property(denial_hazard, &"lane")), plan.route_branch_side)

func test_recovery_population_places_semantic_hazards_on_distinct_first_and_last_catches() -> void:
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
    assert_eq(_require_int_property(safe_relief_hazard, &"hazard_kind"), GeneratedHazardKindScript.Value.STARTLE_PUFF)
    var lift_row_index: int = _require_int_property(recovery_lift_hazard, &"row_index")
    var relief_row_index: int = _require_int_property(safe_relief_hazard, &"row_index")
    assert_eq(plan.row_roles[lift_row_index], RouteRowRoleScript.Value.CATCH)
    assert_eq(plan.row_roles[relief_row_index], RouteRowRoleScript.Value.CATCH)
    assert_lt(lift_row_index, relief_row_index)
    assert_ne(_require_string_name_property(recovery_lift_hazard, &"anchor_id"), _require_string_name_property(safe_relief_hazard, &"anchor_id"))
    assert_false(RouteLaneScript.is_outer(_require_int_property(recovery_lift_hazard, &"lane")))

func test_variable_hazard_kinds_are_repeatable_per_seed_and_vary_across_seeds() -> void:
    var pressure_plan: ChunkRoutePlanScript = _build_plan(12, ChunkRouteSlotScript.Value.PRESSURE, ChunkDifficultyBandScript.Value.CHALLENGE)
    var skill_plan: ChunkRoutePlanScript = _build_plan(2, ChunkRouteSlotScript.Value.SKILL, ChunkDifficultyBandScript.Value.EASY)
    var selected_denial_kinds: Array[int] = []
    var selected_traverse_kinds: Array[int] = []

    for seed_index in range(32):
        var selection_seed: String = "hazard-seed-%d" % seed_index
        var first_pressure_population: RefCounted = _build_population(pressure_plan, selection_seed)
        var repeated_pressure_population: RefCounted = _build_population(pressure_plan, selection_seed)
        var first_denial: RefCounted = _call_ref_counted_with_argument(first_pressure_population, &"find_hazard_placement_for_intent", GeneratedHazardIntentScript.Value.OPTIONAL_BRANCH_DENIAL)
        var repeated_denial: RefCounted = _call_ref_counted_with_argument(repeated_pressure_population, &"find_hazard_placement_for_intent", GeneratedHazardIntentScript.Value.OPTIONAL_BRANCH_DENIAL)
        var first_denial_kind: int = _require_int_property(first_denial, &"hazard_kind")
        var first_skill_population: RefCounted = _build_population(skill_plan, selection_seed)
        var repeated_skill_population: RefCounted = _build_population(skill_plan, selection_seed)
        var first_traverse: RefCounted = _call_ref_counted_with_argument(first_skill_population, &"find_hazard_placement_for_intent", GeneratedHazardIntentScript.Value.TRAVERSE_FORCE)
        var repeated_traverse: RefCounted = _call_ref_counted_with_argument(repeated_skill_population, &"find_hazard_placement_for_intent", GeneratedHazardIntentScript.Value.TRAVERSE_FORCE)
        var first_traverse_kind: int = _require_int_property(first_traverse, &"hazard_kind")

        assert_eq(first_denial_kind, _require_int_property(repeated_denial, &"hazard_kind"))
        assert_eq(first_traverse_kind, _require_int_property(repeated_traverse, &"hazard_kind"))
        if not selected_denial_kinds.has(first_denial_kind):
            selected_denial_kinds.append(first_denial_kind)
        if not selected_traverse_kinds.has(first_traverse_kind):
            selected_traverse_kinds.append(first_traverse_kind)

    assert_gt(selected_denial_kinds.size(), 1)
    assert_gt(selected_traverse_kinds.size(), 1)

func _build_plan(chunk_index: int, route_slot: int, difficulty_band: int) -> ChunkRoutePlanScript:
    var builder: ChunkRoutePlanBuilderScript = ChunkRoutePlanBuilderScript.new()
    return builder.build_plan(DailySeedKey.from_utc_date(2026, 5, 16), chunk_index, route_slot, difficulty_band)

func _build_graph(plan: ChunkRoutePlanScript) -> RouteAnchorGraphScript:
    var graph_builder: RouteAnchorGraphBuilderScript = RouteAnchorGraphBuilderScript.new(4.0, 0.8)
    return graph_builder.build_graph(plan)

func _solve(plan: ChunkRoutePlanScript, anchor_graph: RouteAnchorGraphScript) -> ChunkRoutePathSolutionScript:
    var solver: ChunkRoutePathSolverScript = ChunkRoutePathSolverScript.new()
    return solver.solve(plan, anchor_graph, DailySeedKey.from_utc_date(2026, 5, 16), 2.2, 0.48)

func _build_population(plan: ChunkRoutePlanScript, selection_seed: String = "") -> RefCounted:
    var anchor_graph: RouteAnchorGraphScript = _build_graph(plan)
    var path_solution: ChunkRoutePathSolutionScript = _solve(plan, anchor_graph)
    assert_true(path_solution.is_valid)

    var builder_variant: Variant = ChunkRoutePopulationBuilderScript.new()
    assert_true(builder_variant is RefCounted)
    var builder: RefCounted = builder_variant
    var population_variant: Variant = builder.call("populate", plan, anchor_graph, path_solution, 0.48, selection_seed)
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

func _require_string_name_property(source: RefCounted, property_name: StringName) -> StringName:
    var raw_value: Variant = source.get(property_name)
    assert_true(raw_value is StringName)
    var typed_value: StringName = raw_value
    return typed_value

func _require_bool_property(source: RefCounted, property_name: StringName) -> bool:
    var raw_value: Variant = source.get(property_name)
    assert_true(raw_value is bool)
    var typed_value: bool = raw_value
    return typed_value

func _get_support_lanes_in_row(population: RefCounted, row_index: int) -> Array[int]:
    var support_lanes: Array[int] = []
    for hold in _require_ref_counted_array_property(population, &"holds"):
        if _require_bool_property(hold, &"is_support_hold") and _require_int_property(hold, &"row_index") == row_index:
            support_lanes.append(_require_int_property(hold, &"lane"))

    return support_lanes

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
