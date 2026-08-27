class_name ChunkRoutePathSolver
extends RefCounted

const ChunkRoutePathSolutionScript = preload("res://src/gameplay/generation/chunk_route_path_solution.gd")
const ChunkRoutePlanScript = preload("res://src/gameplay/generation/chunk_route_plan.gd")
const RouteAnchorCandidateScript = preload("res://src/gameplay/generation/route_anchor_candidate.gd")
const RouteAnchorGraphScript = preload("res://src/gameplay/generation/route_anchor_graph.gd")
const RouteBranchSideScript = preload("res://src/gameplay/generation/route_branch_side.gd")
const RouteLaneScript = preload("res://src/gameplay/generation/route_lane.gd")
const RouteMovementStyleScript = preload("res://src/gameplay/generation/route_movement_style.gd")
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
		return ChunkRoutePathSolutionScript.new(false, "No safe path can be built from the anchor graph.", null, null, 0, 0)

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
	for row_index in range(plan.get_row_count()):
		lanes.append(_select_safe_lane(plan, row_index))
	return _build_path_from_lanes(&"safe_path", lanes, anchor_graph)

func _select_safe_lane(plan: ChunkRoutePlanScript, row_index: int) -> int:
	Validation.require_condition(row_index >= 0, "ChunkRoutePathSolver safe lane row cannot be negative.")
	Validation.require_condition(row_index < plan.get_row_count(), "ChunkRoutePathSolver safe lane row must exist in the plan.")
	if row_index == 0 or row_index == plan.get_row_count() - 1:
		return RouteLaneScript.Value.CENTER

	if plan.optional_route_required:
		return _select_branch_safe_lane(plan, row_index)

	match plan.movement_style:
		RouteMovementStyleScript.Value.LADDER:
			return _select_ladder_safe_lane(plan, row_index)
		RouteMovementStyleScript.Value.ZIGZAG:
			return _select_zigzag_safe_lane(plan, row_index)
		RouteMovementStyleScript.Value.RECOVERY:
			return _select_recovery_safe_lane(plan, row_index)
		_:
			RouteMovementStyleScript.assert_valid(plan.movement_style)
			return RouteLaneScript.Value.CENTER

func _select_ladder_safe_lane(plan: ChunkRoutePlanScript, row_index: int) -> int:
	return _select_wide_safe_lane(plan, row_index)

func _select_zigzag_safe_lane(plan: ChunkRoutePlanScript, row_index: int) -> int:
	return _select_wide_safe_lane(plan, row_index)

func _select_recovery_safe_lane(plan: ChunkRoutePlanScript, row_index: int) -> int:
	var side: int = _get_recovery_arm_side(plan, row_index)
	if row_index == plan.get_row_count() - 2:
		return _get_inner_lane_for_side(side)

	if (row_index % 4) == 1:
		return _get_outer_lane_for_side(side)

	if (row_index % 2) == 0:
		return _get_inner_lane_for_side(side)

	return RouteLaneScript.Value.CENTER

func _select_wide_safe_lane(plan: ChunkRoutePlanScript, row_index: int) -> int:
	var sequence_index: int = (row_index - 1) % 8
	var primary_side: int = _get_alternating_branch_side(plan, row_index)
	var secondary_side: int = _get_opposite_branch_side(primary_side)
	match sequence_index:
		0:
			return _get_inner_lane_for_side(primary_side)
		1:
			return _get_outer_lane_for_side(primary_side)
		2:
			return _get_inner_lane_for_side(primary_side)
		3:
			return RouteLaneScript.Value.CENTER
		4:
			return _get_inner_lane_for_side(secondary_side)
		5:
			return _get_outer_lane_for_side(secondary_side)
		6:
			return _get_inner_lane_for_side(secondary_side)
		_:
			return RouteLaneScript.Value.CENTER

func _select_branch_safe_lane(plan: ChunkRoutePlanScript, row_index: int) -> int:
	Validation.require_condition(plan.optional_route_required, "ChunkRoutePathSolver branch safe lanes require an optional route plan.")
	if row_index <= plan.split_row_index or row_index >= plan.merge_row_index:
		return RouteLaneScript.Value.CENTER

	var branch_side: int = _get_opposite_branch_side(plan.route_branch_side)
	var branch_row_index: int = row_index - plan.split_row_index - 1
	var branch_span: int = plan.merge_row_index - plan.split_row_index - 1
	return _select_branch_lane(branch_side, branch_row_index, branch_span)

func _get_recovery_arm_side(plan: ChunkRoutePlanScript, row_index: int) -> int:
	var arm_index: int = floori(float(row_index) / 4.0)
	var side_index: int = (arm_index + plan.chunk_index) % 2
	if side_index == 0:
		return RouteBranchSideScript.Value.LEFT

	return RouteBranchSideScript.Value.RIGHT

func _get_alternating_branch_side(plan: ChunkRoutePlanScript, row_index: int) -> int:
	var side_index: int = (floori(float(row_index - 1) / 8.0) + plan.chunk_index) % 2
	if side_index == 0:
		return RouteBranchSideScript.Value.LEFT

	return RouteBranchSideScript.Value.RIGHT

func _build_optional_path(plan: ChunkRoutePlanScript, anchor_graph: RouteAnchorGraphScript) -> RoutePlannedPathScript:
	var lanes: Array[int] = []
	var branch_span: int = plan.merge_row_index - plan.split_row_index - 1

	for row_index in range(plan.get_row_count()):
		var lane: int = RouteLaneScript.Value.CENTER
		if row_index > plan.split_row_index and row_index < plan.merge_row_index:
			var branch_row_index: int = row_index - plan.split_row_index - 1
			lane = _select_branch_lane(plan.route_branch_side, branch_row_index, branch_span)

		lanes.append(lane)

	return _build_path_from_lanes(&"optional_path", lanes, anchor_graph)

func _select_branch_lane(branch_side: int, branch_row_index: int, branch_span: int) -> int:
	Validation.require_condition(branch_row_index >= 0, "ChunkRoutePathSolver branch row index cannot be negative.")
	Validation.require_condition(branch_span > 0, "ChunkRoutePathSolver branch span must be positive.")
	Validation.require_condition(branch_row_index < branch_span, "ChunkRoutePathSolver branch row index must be inside the branch span.")
	if branch_row_index == 0 or branch_row_index == branch_span - 1:
		return _get_inner_lane_for_side(branch_side)

	if (branch_row_index % 2) == 1:
		return _get_outer_lane_for_side(branch_side)

	return _get_inner_lane_for_side(branch_side)

func _get_inner_lane_for_side(branch_side: int) -> int:
	RouteBranchSideScript.assert_valid(branch_side)
	Validation.require_condition(branch_side != RouteBranchSideScript.Value.NONE, "ChunkRoutePathSolver branch lane requires a branch side.")

	if branch_side == RouteBranchSideScript.Value.LEFT:
		return RouteLaneScript.Value.INNER_LEFT

	return RouteLaneScript.Value.INNER_RIGHT

func _get_outer_lane_for_side(branch_side: int) -> int:
	RouteBranchSideScript.assert_valid(branch_side)
	Validation.require_condition(branch_side != RouteBranchSideScript.Value.NONE, "ChunkRoutePathSolver outer lane requires a branch side.")

	if branch_side == RouteBranchSideScript.Value.LEFT:
		return RouteLaneScript.Value.OUTER_LEFT

	return RouteLaneScript.Value.OUTER_RIGHT

func _get_opposite_branch_side(branch_side: int) -> int:
	RouteBranchSideScript.assert_valid(branch_side)
	Validation.require_condition(branch_side != RouteBranchSideScript.Value.NONE, "ChunkRoutePathSolver opposite side requires a branch side.")
	if branch_side == RouteBranchSideScript.Value.LEFT:
		return RouteBranchSideScript.Value.RIGHT

	return RouteBranchSideScript.Value.LEFT

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
