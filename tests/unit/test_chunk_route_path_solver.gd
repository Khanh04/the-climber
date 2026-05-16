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

func test_solver_accepts_non_branch_opener_with_center_safe_path() -> void:
    var plan: ChunkRoutePlanScript = _build_plan(0, ChunkRouteSlotScript.Value.OPENER, ChunkDifficultyBandScript.Value.EASY)
    var solution: ChunkRoutePathSolutionScript = _solve(plan, _build_graph(plan))

    assert_true(solution.is_valid)
    assert_eq(solution.failure_reason, "")
    assert_not_null(solution.safe_path)
    assert_eq(solution.optional_path, null)
    assert_eq(solution.safe_path.get_row_count(), plan.get_row_count())
    assert_eq(solution.safe_path.total_lateral_lane_steps, 0)

    for row_index in range(plan.get_row_count()):
        assert_eq(solution.safe_path.get_lane_at_row(row_index), RouteLaneScript.Value.CENTER)

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

func test_solver_rejects_graph_without_safe_center_path() -> void:
    var plan: ChunkRoutePlanScript = _build_plan(3, ChunkRouteSlotScript.Value.BASELINE, ChunkDifficultyBandScript.Value.EASY)
    var anchor_graph: RouteAnchorGraphScript = _build_graph_without_lane(_build_graph(plan), RouteLaneScript.Value.CENTER)
    var solution: ChunkRoutePathSolutionScript = _solve(plan, anchor_graph)

    assert_false(solution.is_valid)
    assert_eq(solution.failure_reason, "No safe center path can be built from the anchor graph.")
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
    return builder.build_plan(DailySeedKey.from_utc_date(2026, 5, 16), chunk_index, route_slot, difficulty_band)

func _build_graph(plan: ChunkRoutePlanScript) -> RouteAnchorGraphScript:
    var graph_builder: RouteAnchorGraphBuilderScript = RouteAnchorGraphBuilderScript.new(4.0, 0.8)
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