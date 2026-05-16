class_name ChunkRoutePathSolver
extends RefCounted

const ChunkRoutePathSolutionScript = preload("res://src/gameplay/generation/chunk_route_path_solution.gd")
const ChunkRoutePlanScript = preload("res://src/gameplay/generation/chunk_route_plan.gd")
const RouteAnchorCandidateScript = preload("res://src/gameplay/generation/route_anchor_candidate.gd")
const RouteAnchorGraphScript = preload("res://src/gameplay/generation/route_anchor_graph.gd")
const RouteBranchSideScript = preload("res://src/gameplay/generation/route_branch_side.gd")
const RouteLaneScript = preload("res://src/gameplay/generation/route_lane.gd")
const RoutePlannedPathScript = preload("res://src/gameplay/generation/route_planned_path.gd")

func solve(plan: ChunkRoutePlanScript, anchor_graph: RouteAnchorGraphScript) -> ChunkRoutePathSolutionScript:
	Validation.require_condition(plan != null, "ChunkRoutePathSolver requires a route plan.")
	Validation.require_condition(anchor_graph != null, "ChunkRoutePathSolver requires an anchor graph.")
	plan.assert_valid()
	anchor_graph.assert_valid()
	Validation.require_condition(
		anchor_graph.row_count == plan.get_row_count(),
		"ChunkRoutePathSolver anchor graph row count must match the plan."
	)

	var safe_path: RoutePlannedPathScript = _build_safe_path(plan, anchor_graph)
	if safe_path == null:
		return ChunkRoutePathSolutionScript.new(false, "No safe center path can be built from the anchor graph.", null, null, 0, 0)

	if not plan.optional_route_required:
		return ChunkRoutePathSolutionScript.new(true, "", safe_path, null, 0, 0)

	var optional_path: RoutePlannedPathScript = _build_optional_path(plan, anchor_graph)
	if optional_path == null:
		return ChunkRoutePathSolutionScript.new(false, "No optional branch path can satisfy the route plan anchors.", safe_path, null, 0, 0)

	var branch_first_row: int = plan.split_row_index + 1
	var branch_last_row: int = plan.merge_row_index - 1
	var branch_separation_rows: int = optional_path.count_separated_rows(safe_path, branch_first_row, branch_last_row)
	var optional_outer_lane_rows: int = optional_path.count_outer_lane_rows_for_side(
		plan.route_branch_side,
		branch_first_row,
		branch_last_row
	)

	if branch_separation_rows < plan.minimum_branch_separation_rows:
		return ChunkRoutePathSolutionScript.new(
			false,
			"Optional branch path does not stay separated for enough rows.",
			safe_path,
			optional_path,
			branch_separation_rows,
			optional_outer_lane_rows
		)

	if optional_outer_lane_rows < plan.minimum_outer_lane_rows:
		return ChunkRoutePathSolutionScript.new(
			false,
			"Optional branch path does not occupy outer lanes for enough rows.",
			safe_path,
			optional_path,
			branch_separation_rows,
			optional_outer_lane_rows
		)

	return ChunkRoutePathSolutionScript.new(true, "", safe_path, optional_path, branch_separation_rows, optional_outer_lane_rows)

func _build_safe_path(plan: ChunkRoutePlanScript, anchor_graph: RouteAnchorGraphScript) -> RoutePlannedPathScript:
	var lanes: Array[int] = []
	for _row_index in range(plan.get_row_count()):
		lanes.append(RouteLaneScript.Value.CENTER)
	return _build_path_from_lanes(&"safe_path", lanes, anchor_graph)

func _build_optional_path(plan: ChunkRoutePlanScript, anchor_graph: RouteAnchorGraphScript) -> RoutePlannedPathScript:
	var lanes: Array[int] = []
	var branch_span: int = plan.merge_row_index - plan.split_row_index - 1
	var outer_start_branch_index: int = maxi(0, branch_span - plan.minimum_outer_lane_rows)

	for row_index in range(plan.get_row_count()):
		var lane: int = RouteLaneScript.Value.CENTER
		if row_index > plan.split_row_index and row_index < plan.merge_row_index:
			var branch_row_index: int = row_index - plan.split_row_index - 1
			var use_outer_lane: bool = branch_row_index >= outer_start_branch_index
			lane = _get_branch_lane(plan.route_branch_side, use_outer_lane)

		lanes.append(lane)

	return _build_path_from_lanes(&"optional_path", lanes, anchor_graph)

func _get_branch_lane(branch_side: int, use_outer_lane: bool) -> int:
	RouteBranchSideScript.assert_valid(branch_side)
	Validation.require_condition(branch_side != RouteBranchSideScript.Value.NONE, "ChunkRoutePathSolver branch lane requires a branch side.")

	if branch_side == RouteBranchSideScript.Value.LEFT:
		if use_outer_lane:
			return RouteLaneScript.Value.OUTER_LEFT
		return RouteLaneScript.Value.INNER_LEFT

	if use_outer_lane:
		return RouteLaneScript.Value.OUTER_RIGHT
	return RouteLaneScript.Value.INNER_RIGHT

func _build_path_from_lanes(path_id: StringName, lanes: Array[int], anchor_graph: RouteAnchorGraphScript) -> RoutePlannedPathScript:
	var anchor_ids: PackedStringArray = PackedStringArray()
	var row_indices: PackedInt32Array = PackedInt32Array()

	for row_index in range(lanes.size()):
		var lane: int = lanes[row_index]
		var anchor: RouteAnchorCandidateScript = anchor_graph.get_anchor_for_row_and_lane(row_index, lane)
		if anchor == null:
			return null

		var _append_anchor_result: bool = anchor_ids.append(String(anchor.anchor_id))
		var _append_row_result: bool = row_indices.append(row_index)

	return RoutePlannedPathScript.new(path_id, anchor_ids, row_indices, lanes)
