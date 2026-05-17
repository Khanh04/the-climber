extends GutTest

const ChunkDifficultyBandScript = preload("res://src/gameplay/generation/chunk_difficulty_band.gd")
const ChunkRoutePathSolutionScript = preload("res://src/gameplay/generation/chunk_route_path_solution.gd")
const ChunkRoutePathSolverScript = preload("res://src/gameplay/generation/chunk_route_path_solver.gd")
const ChunkRoutePlanBuilderScript = preload("res://src/gameplay/generation/chunk_route_plan_builder.gd")
const ChunkRoutePlanScript = preload("res://src/gameplay/generation/chunk_route_plan.gd")
const ChunkRouteSlotScript = preload("res://src/gameplay/generation/chunk_route_slot.gd")
const RouteAnchorCandidateScript = preload("res://src/gameplay/generation/route_anchor_candidate.gd")
const RouteAnchorGraphBuilderScript = preload("res://src/gameplay/generation/route_anchor_graph_builder.gd")
const RouteAnchorGraphScript = preload("res://src/gameplay/generation/route_anchor_graph.gd")
const RouteBranchSideScript = preload("res://src/gameplay/generation/route_branch_side.gd")
const RouteLaneScript = preload("res://src/gameplay/generation/route_lane.gd")

func test_anchor_graph_builder_creates_five_lane_rows_from_plan() -> void:
    var plan: ChunkRoutePlanScript = _build_plan(1, ChunkRouteSlotScript.Value.BASELINE, ChunkDifficultyBandScript.Value.EASY)
    var anchor_graph: RouteAnchorGraphScript = _build_graph(plan)
    var center_anchor: RouteAnchorCandidateScript = anchor_graph.get_anchor_for_row_and_lane(0, RouteLaneScript.Value.CENTER)
    var outer_left_anchor: RouteAnchorCandidateScript = anchor_graph.get_anchor_for_row_and_lane(0, RouteLaneScript.Value.OUTER_LEFT)
    var inner_left_anchor: RouteAnchorCandidateScript = anchor_graph.get_anchor_for_row_and_lane(0, RouteLaneScript.Value.INNER_LEFT)
    var outer_right_anchor: RouteAnchorCandidateScript = anchor_graph.get_anchor_for_row_and_lane(0, RouteLaneScript.Value.OUTER_RIGHT)

    assert_eq(anchor_graph.row_count, plan.get_row_count())
    assert_eq(anchor_graph.get_anchor_count(), plan.get_row_count() * 5)
    assert_not_null(center_anchor)
    assert_not_null(outer_left_anchor)
    assert_not_null(inner_left_anchor)
    assert_not_null(outer_right_anchor)
    assert_true(center_anchor.local_position.is_equal_approx(Vector2(0.0, -0.8)))
    assert_lt(outer_left_anchor.local_position.x, inner_left_anchor.local_position.x)
    assert_gt(outer_right_anchor.local_position.x, center_anchor.local_position.x)

func test_anchor_graph_builder_applies_seeded_coordinate_noise() -> void:
    var plan: ChunkRoutePlanScript = _build_plan(1, ChunkRouteSlotScript.Value.BASELINE, ChunkDifficultyBandScript.Value.EASY)
    var jittered_graph: RouteAnchorGraphScript = _build_jittered_graph(plan, _seed_key())
    var repeated_graph: RouteAnchorGraphScript = _build_jittered_graph(plan, _seed_key())
    var row_one_center: RouteAnchorCandidateScript = jittered_graph.get_anchor_for_row_and_lane(1, RouteLaneScript.Value.CENTER)
    var repeated_row_one_center: RouteAnchorCandidateScript = repeated_graph.get_anchor_for_row_and_lane(1, RouteLaneScript.Value.CENTER)
    var row_one_inner_left: RouteAnchorCandidateScript = jittered_graph.get_anchor_for_row_and_lane(1, RouteLaneScript.Value.INNER_LEFT)
    var row_one_outer_right: RouteAnchorCandidateScript = jittered_graph.get_anchor_for_row_and_lane(1, RouteLaneScript.Value.OUTER_RIGHT)
    var row_zero_center: RouteAnchorCandidateScript = jittered_graph.get_anchor_for_row_and_lane(0, RouteLaneScript.Value.CENTER)

    assert_not_null(row_one_center)
    assert_not_null(repeated_row_one_center)
    assert_not_null(row_one_inner_left)
    assert_not_null(row_one_outer_right)
    assert_not_null(row_zero_center)
    assert_true(row_one_center.local_position.is_equal_approx(repeated_row_one_center.local_position))
    assert_false(row_one_center.local_position.is_equal_approx(Vector2(0.0, -1.6)))
    assert_lte(absf(row_one_center.local_position.x), 0.1)
    assert_gt(_get_float_range([
        row_one_center.local_position.y,
        row_one_inner_left.local_position.y,
        row_one_outer_right.local_position.y,
    ]), 0.001)
    assert_lte(absf(row_one_center.local_position.y + 1.6), 0.05)
    assert_lte(absf(row_one_inner_left.local_position.y + 1.6), 0.05)
    assert_lte(absf(row_one_outer_right.local_position.y + 1.6), 0.05)
    assert_true(is_equal_approx(row_zero_center.local_position.y, -0.8))

func test_solver_accepts_non_branch_opener_with_gentle_safe_path_spread() -> void:
    var plan: ChunkRoutePlanScript = _build_plan(0, ChunkRouteSlotScript.Value.OPENER, ChunkDifficultyBandScript.Value.EASY)
    var solution: ChunkRoutePathSolutionScript = _solve(plan, _build_graph(plan))

    assert_true(solution.is_valid)
    assert_eq(solution.failure_reason, "")
    assert_not_null(solution.safe_path)
    assert_eq(solution.optional_path, null)
    assert_eq(solution.safe_path.get_row_count(), plan.get_row_count())
    assert_gt(solution.safe_path.total_lateral_lane_steps, 0)
    assert_eq(solution.safe_path.get_lane_at_row(0), RouteLaneScript.Value.CENTER)
    assert_eq(solution.safe_path.get_lane_at_row(plan.get_row_count() - 1), RouteLaneScript.Value.CENTER)
    assert_true(_path_has_lane(solution.safe_path, RouteLaneScript.Value.INNER_LEFT))
    assert_true(_path_has_lane(solution.safe_path, RouteLaneScript.Value.INNER_RIGHT))

func test_solver_builds_branch_path_with_required_separation_and_outer_lane_rows() -> void:
    var plan: ChunkRoutePlanScript = _build_plan(7, ChunkRouteSlotScript.Value.RISK, ChunkDifficultyBandScript.Value.BASELINE)
    var solution: ChunkRoutePathSolutionScript = _solve(plan, _build_graph(plan))

    assert_true(solution.is_valid)
    assert_not_null(solution.safe_path)
    assert_not_null(solution.optional_path)
    assert_gte(solution.branch_separation_rows, plan.minimum_branch_separation_rows)
    assert_gte(solution.optional_outer_lane_rows, plan.minimum_outer_lane_rows)
    assert_gt(solution.optional_path.total_lateral_lane_steps, solution.safe_path.total_lateral_lane_steps)
    assert_eq(solution.optional_path.get_lane_at_row(plan.split_row_index), RouteLaneScript.Value.CENTER)
    assert_eq(solution.optional_path.get_lane_at_row(plan.merge_row_index), RouteLaneScript.Value.CENTER)

    var branch_outer_lane: int = _get_outer_lane_for_branch_side(plan.route_branch_side)
    var outer_lane_rows: int = solution.optional_path.count_outer_lane_rows_for_side(
        plan.route_branch_side,
        plan.split_row_index + 1,
        plan.merge_row_index - 1
    )

    assert_eq(outer_lane_rows, solution.optional_outer_lane_rows)
    assert_eq(solution.optional_path.get_lane_at_row(plan.merge_row_index - 1), branch_outer_lane)

func test_solver_rejects_graph_without_required_safe_path_lane() -> void:
    var plan: ChunkRoutePlanScript = _build_plan(3, ChunkRouteSlotScript.Value.BASELINE, ChunkDifficultyBandScript.Value.EASY)
    var anchor_graph: RouteAnchorGraphScript = _build_graph_without_lane(_build_graph(plan), RouteLaneScript.Value.CENTER)
    var solution: ChunkRoutePathSolutionScript = _solve(plan, anchor_graph)

    assert_false(solution.is_valid)
    assert_eq(solution.failure_reason, "No safe path can be built from the anchor graph.")
    assert_eq(solution.safe_path, null)

func test_solver_rejects_branch_graph_without_required_outer_lane() -> void:
    var plan: ChunkRoutePlanScript = _build_plan(12, ChunkRouteSlotScript.Value.PRESSURE, ChunkDifficultyBandScript.Value.CHALLENGE)
    var branch_outer_lane: int = _get_outer_lane_for_branch_side(plan.route_branch_side)
    var anchor_graph: RouteAnchorGraphScript = _build_graph_without_lane(_build_graph(plan), branch_outer_lane)
    var solution: ChunkRoutePathSolutionScript = _solve(plan, anchor_graph)

    assert_false(solution.is_valid)
    assert_eq(solution.failure_reason, "No optional branch path can satisfy the route plan anchors.")
    assert_not_null(solution.safe_path)
    assert_eq(solution.optional_path, null)

func _build_plan(chunk_index: int, route_slot: int, difficulty_band: int) -> ChunkRoutePlanScript:
    var builder: ChunkRoutePlanBuilderScript = ChunkRoutePlanBuilderScript.new()
    return builder.build_plan(_seed_key(), chunk_index, route_slot, difficulty_band)

func _seed_key() -> String:
    return DailySeedKey.from_utc_date(2026, 5, 16)

func _build_graph(plan: ChunkRoutePlanScript) -> RouteAnchorGraphScript:
    var graph_builder: RouteAnchorGraphBuilderScript = RouteAnchorGraphBuilderScript.new(4.0, 0.8)
    return graph_builder.build_graph(plan)

func _build_jittered_graph(plan: ChunkRoutePlanScript, seed_key: String) -> RouteAnchorGraphScript:
    var graph_builder: RouteAnchorGraphBuilderScript = RouteAnchorGraphBuilderScript.new(4.0, 0.8, 0.8, 0.1, 0.05, seed_key)
    return graph_builder.build_graph(plan)

func _solve(plan: ChunkRoutePlanScript, anchor_graph: RouteAnchorGraphScript) -> ChunkRoutePathSolutionScript:
    var solver: ChunkRoutePathSolverScript = ChunkRoutePathSolverScript.new()
    return solver.solve(plan, anchor_graph)

func _build_graph_without_lane(anchor_graph: RouteAnchorGraphScript, lane: int) -> RouteAnchorGraphScript:
    RouteLaneScript.assert_valid(lane)
    var filtered_anchors: Array[RouteAnchorCandidateScript] = []
    for anchor in anchor_graph.anchors:
        if anchor.lane != lane:
            filtered_anchors.append(anchor)

    return RouteAnchorGraphScript.new(anchor_graph.row_count, filtered_anchors)

func _get_outer_lane_for_branch_side(branch_side: int) -> int:
    RouteBranchSideScript.assert_valid(branch_side)
    Validation.require_condition(branch_side != RouteBranchSideScript.Value.NONE, "Test helper requires a branch side.")
    if branch_side == RouteBranchSideScript.Value.LEFT:
        return RouteLaneScript.Value.OUTER_LEFT

    return RouteLaneScript.Value.OUTER_RIGHT

func _get_float_range(values: Array[float]) -> float:
    Validation.require_condition(not values.is_empty(), "Test float range helper requires at least one value.")
    var minimum_value: float = values[0]
    var maximum_value: float = values[0]
    for value in values:
        minimum_value = minf(minimum_value, value)
        maximum_value = maxf(maximum_value, value)

    return maximum_value - minimum_value

func _path_has_lane(path: RefCounted, lane: int) -> bool:
    RouteLaneScript.assert_valid(lane)
    Validation.require_condition(path != null, "Test path lane helper requires a path.")
    var raw_row_count: Variant = path.call("get_row_count")
    assert_true(raw_row_count is int)
    var row_count: int = raw_row_count
    for row_index in range(row_count):
        var raw_lane: Variant = path.call("get_lane_at_row", row_index)
        assert_true(raw_lane is int)
        var typed_lane: int = raw_lane
        if typed_lane == lane:
            return true

    return false