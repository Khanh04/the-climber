class_name ChunkRoutePathSolver
extends RefCounted

const ChunkRoutePathSolutionScript = preload("res://src/gameplay/generation/chunk_route_path_solution.gd")
const ChunkRoutePlanScript = preload("res://src/gameplay/generation/chunk_route_plan.gd")
const RouteAnchorCandidateScript = preload("res://src/gameplay/generation/route_anchor_candidate.gd")
const RouteAnchorGraphScript = preload("res://src/gameplay/generation/route_anchor_graph.gd")
const RouteBranchSideScript = preload("res://src/gameplay/generation/route_branch_side.gd")
const RouteLaneScript = preload("res://src/gameplay/generation/route_lane.gd")
const RoutePlannedPathScript = preload("res://src/gameplay/generation/route_planned_path.gd")
const RouteRowRoleScript = preload("res://src/gameplay/generation/route_row_role.gd")

## Lane every chunk enters through (row 0 of both the safe and optional path), instead of
## CENTER. Shared by _build_safe_path() and _build_optional_path() so the two paths still
## collapse onto the same row-0 hold, keeping exactly two holds there for the player to swing
## between.
const CHUNK_ENTRY_LANE: int = RouteLaneScript.Value.INNER_LEFT

## Solves the safe path as a deterministic walk: each row's lane is chosen only from lanes
## actually reachable (real anchor distance) from the previous row, with a minimum lateral
## clearance so a lateral move always leaves room for the player's body to swing rather than
## squeeze past the wall. Row purpose (CRUX/CATCH/DECISION/...) weights the choice among
## whatever survives that filter -- so reachability is a generation-time guarantee, not a
## pass/fail check applied after the fact.
##
## The optional (branch) path keeps its original deterministic alternating pattern: it has a
## hard downstream requirement (at least one outer-lane row, or hazard/reward placement fails)
## that pattern already guarantees by construction, and it stays on the branch side opposite
## the safe path's own restricted lanes -- so the two paths can never collide.
func solve(
	plan: ChunkRoutePlanScript,
	anchor_graph: RouteAnchorGraphScript,
	selection_seed: String,
	max_move_distance_meters: float,
	player_body_width_meters: float
) -> ChunkRoutePathSolutionScript:
	Validation.require_condition(plan != null, "ChunkRoutePathSolver requires a route plan.")
	Validation.require_condition(anchor_graph != null, "ChunkRoutePathSolver requires an anchor graph.")
	Validation.require_condition(selection_seed != "", "ChunkRoutePathSolver requires a selection seed.")
	Validation.require_condition(max_move_distance_meters > 0.0, "ChunkRoutePathSolver max move distance must be positive.")
	Validation.require_condition(player_body_width_meters > 0.0, "ChunkRoutePathSolver player body width must be positive.")
	plan.assert_valid()
	anchor_graph.assert_valid()
	Validation.require_condition(
		anchor_graph.row_count == plan.get_row_count(),
		"ChunkRoutePathSolver anchor graph row count must match the plan."
	)

	var safe_path: RoutePlannedPathScript = _build_safe_path(plan, anchor_graph, selection_seed, max_move_distance_meters, player_body_width_meters)
	if safe_path == null:
		return ChunkRoutePathSolutionScript.new(false, "No safe path can be built from the anchor graph.", null, null, 0, 0)

	if not plan.optional_route_required:
		return ChunkRoutePathSolutionScript.new(true, "", safe_path, null, 0, 0)

	var optional_path: RoutePlannedPathScript = _build_optional_path(plan, anchor_graph, selection_seed)
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

# ---------------------------------------------------------------------------
# Safe path: reachability + clearance-filtered, row-purpose-weighted walk.
# ---------------------------------------------------------------------------

func _build_safe_path(
	plan: ChunkRoutePlanScript,
	anchor_graph: RouteAnchorGraphScript,
	selection_seed: String,
	max_move_distance_meters: float,
	player_body_width_meters: float
) -> RoutePlannedPathScript:
	var lanes: Array[int] = []
	for row_index in range(plan.get_row_count()):
		var lane: int
		if _row_is_fixed(plan, row_index):
			lane = _get_fixed_lane(row_index)
		else:
			var previous_position: Vector2 = anchor_graph.get_anchor_for_row_and_lane(row_index - 1, lanes[row_index - 1]).local_position
			var allowed_lanes: Array[int] = RouteLaneScript.get_all_values()
			var is_branch_interior: bool = plan.optional_route_required and row_index > plan.split_row_index and row_index < plan.merge_row_index
			if is_branch_interior:
				# Stay on the side opposite the optional path's branch side so the two lines
				# can never land on the same lane -- disjoint lane pools, not a runtime check.
				var opposite_side: int = _get_opposite_branch_side(plan.route_branch_side)
				allowed_lanes = [_get_inner_lane_for_side(opposite_side), _get_outer_lane_for_side(opposite_side)]

			if is_branch_interior and row_index == plan.split_row_index + 1:
				# The one transition with no "stay on this lane" fallback: leaving the fixed
				# CENTER pivot for the branch side. INNER is always the closer of the two (the
				# same conservative choice the old fixed pattern always made here), so pick it
				# directly rather than filtering -- reachability into a wider OUTER lane from a
				# jittered CENTER anchor isn't reliably provable, and doesn't need to be.
				lane = _get_inner_lane_for_side(_get_opposite_branch_side(plan.route_branch_side))
			else:
				var next_fixed_anchor: RouteAnchorCandidateScript = null
				if _row_is_fixed(plan, row_index + 1):
					next_fixed_anchor = anchor_graph.get_anchor_for_row_and_lane(row_index + 1, _get_fixed_lane(row_index + 1))
				var candidates: Array[RouteAnchorCandidateScript] = _get_valid_candidates(
					anchor_graph,
					row_index,
					previous_position,
					lanes[row_index - 1],
					next_fixed_anchor,
					max_move_distance_meters,
					player_body_width_meters,
					allowed_lanes
				)
				var two_rows_back_lane: int = lanes[row_index - 2] if row_index >= 2 else -1
				var weights: Array[float] = []
				for candidate in candidates:
					weights.append(_get_row_weight(candidate, previous_position, plan.row_roles[row_index], max_move_distance_meters, two_rows_back_lane))

				var selection_context: String = "%s:safe:%d:%d" % [selection_seed, plan.chunk_index, row_index]
				lane = _pick_weighted_anchor(candidates, weights, selection_context).lane
		lanes.append(lane)

	return _build_path_from_lanes(&"safe_path", lanes, anchor_graph)

## Row 0 always enters through CHUNK_ENTRY_LANE and the last row always exits through CENTER
## (CENTER's world x is fan-invariant, keeping the exit seam-aligned with the next chunk's
## entry). When a branch is required, every row at or outside [split_row_index, merge_row_index]
## also collapses onto CENTER -- the shared pivot the two paths split from and rejoin at.
func _row_is_fixed(plan: ChunkRoutePlanScript, row_index: int) -> bool:
	if row_index == 0 or row_index == plan.get_row_count() - 1:
		return true
	if plan.optional_route_required and (row_index <= plan.split_row_index or row_index >= plan.merge_row_index):
		return true
	return false

func _get_fixed_lane(row_index: int) -> int:
	if row_index == 0:
		return CHUNK_ENTRY_LANE
	return RouteLaneScript.Value.CENTER

## Filters the row's lanes down to those actually reachable from the previous row's chosen
## anchor. Staying on previous_lane always passes -- it's a pure vertical move (jitter aside),
## always inside the envelope -- so every row always has at least one candidate. Moving to a
## different lane must clear player_body_width_meters laterally so a swing never squeezes past
## the wall; lane identity (not a positional epsilon) decides "same lane", since horizontal
## jitter alone can shift one lane's x by more than a naive distance threshold would allow.
##
## When the next row is fixed (the chunk's exit, or a branch split/merge pivot), candidates are
## further narrowed to those that can also reach it -- an OUTER lane is otherwise a dead end
## right before the walk is forced back onto CENTER. If that narrowing would leave nothing (a
## real but rare jitter edge case), it's dropped rather than asserted on: the post-hoc route
## validator already exists to catch a genuinely unreachable seam and have the caller reroll
## with a new candidate salt, the same safety net the layout has always relied on for jitter.
func _get_valid_candidates(
	anchor_graph: RouteAnchorGraphScript,
	row_index: int,
	previous_position: Vector2,
	previous_lane: int,
	next_fixed_anchor: RouteAnchorCandidateScript,
	max_move_distance_meters: float,
	player_body_width_meters: float,
	allowed_lanes: Array[int]
) -> Array[RouteAnchorCandidateScript]:
	var candidates: Array[RouteAnchorCandidateScript] = []
	var candidates_reaching_next_fixed_anchor: Array[RouteAnchorCandidateScript] = []
	for lane in allowed_lanes:
		var anchor: RouteAnchorCandidateScript = anchor_graph.get_anchor_for_row_and_lane(row_index, lane)
		if anchor == null:
			continue

		if anchor.local_position.distance_to(previous_position) > max_move_distance_meters:
			continue

		if lane != previous_lane:
			var lateral_delta: float = absf(anchor.local_position.x - previous_position.x)
			if lateral_delta < player_body_width_meters:
				continue

		candidates.append(anchor)
		if next_fixed_anchor == null or anchor.local_position.distance_to(next_fixed_anchor.local_position) <= max_move_distance_meters:
			candidates_reaching_next_fixed_anchor.append(anchor)

	Validation.require_condition(
		not candidates.is_empty(),
		"ChunkRoutePathSolver could not find a reachable lane for row %d; check that row-step height and lane spread stay inside the move envelope." % row_index
	)
	if not candidates_reaching_next_fixed_anchor.is_empty():
		return candidates_reaching_next_fixed_anchor
	return candidates

## Weights a candidate by how well its move distance suits the row's purpose: CRUX/PRESSURE
## rows favor bigger, more committing moves; CATCH rows favor a short "rest" move; DECISION and
## TRAVERSE rows favor lateral movement. A mild penalty discourages repeating the lane from two
## rows back, so a run of SUPPORT/TOP_OUT rows doesn't settle into a straight ladder.
func _get_row_weight(
	anchor: RouteAnchorCandidateScript,
	previous_position: Vector2,
	row_role: int,
	max_move_distance_meters: float,
	two_rows_back_lane: int
) -> float:
	var distance: float = anchor.local_position.distance_to(previous_position)
	var reach_fraction: float = clampf(distance / max_move_distance_meters, 0.0, 1.0)
	var lateral_fraction: float = clampf(absf(anchor.local_position.x - previous_position.x) / max_move_distance_meters, 0.0, 1.0)

	var weight: float = 1.0
	match row_role:
		RouteRowRoleScript.Value.CRUX, RouteRowRoleScript.Value.PRESSURE:
			weight = 0.2 + reach_fraction
		RouteRowRoleScript.Value.CATCH:
			weight = 1.2 - reach_fraction
		RouteRowRoleScript.Value.DECISION:
			weight = 0.3 + lateral_fraction
		RouteRowRoleScript.Value.TRAVERSE:
			weight = 0.15 + (lateral_fraction * 1.5)
		RouteRowRoleScript.Value.SUPPORT, RouteRowRoleScript.Value.TOP_OUT:
			# Mild lateral preference rather than flat neutrality -- SUPPORT is the majority
			# role in most chunks (openers especially), so a pure coin-flip here can still
			# leave a chunk hugging the centre for its whole length. This nudges the wall's
			# width into use without committing as hard as DECISION/TRAVERSE do.
			weight = 0.6 + lateral_fraction
		_:
			RouteRowRoleScript.assert_valid(row_role)
			weight = 1.0

	if two_rows_back_lane != -1 and anchor.lane == two_rows_back_lane:
		weight *= 0.5

	return maxf(weight, 0.05)

## Deterministic weighted pick: hashes selection_context to a stable value in [0, 1) and walks
## the cumulative weights, so the same (seed, chunk, row) always resolves to the same anchor.
func _pick_weighted_anchor(
	candidates: Array[RouteAnchorCandidateScript],
	weights: Array[float],
	selection_context: String
) -> RouteAnchorCandidateScript:
	Validation.require_condition(not candidates.is_empty(), "ChunkRoutePathSolver weighted selection requires candidates.")
	Validation.require_condition(candidates.size() == weights.size(), "ChunkRoutePathSolver weighted selection requires aligned weights.")

	var total_weight: float = 0.0
	for weight in weights:
		total_weight += maxf(weight, 0.0001)

	var selection_value: float = _hash_unit_float(selection_context) * total_weight
	var accumulated_weight: float = 0.0
	for candidate_index in range(candidates.size()):
		accumulated_weight += maxf(weights[candidate_index], 0.0001)
		if selection_value <= accumulated_weight:
			return candidates[candidate_index]

	return candidates[candidates.size() - 1]

static func _hash_unit_float(context: String) -> float:
	return DeterministicHash.unit_float(context)

# ---------------------------------------------------------------------------
# Optional (branch) path: a seeded inner/outer walk on the branch side, opposite the safe
# path's restricted lanes above -- so the two paths never collide. The first and last branch
# rows stay INNER (the only lanes reachable to/from the fixed CENTER pivot in production
# geometry); the interior rows are seeded, keeping at least minimum_outer_lane_rows on OUTER.
# ---------------------------------------------------------------------------

func _build_optional_path(plan: ChunkRoutePlanScript, anchor_graph: RouteAnchorGraphScript, selection_seed: String) -> RoutePlannedPathScript:
	var lanes: Array[int] = []
	var branch_span: int = plan.merge_row_index - plan.split_row_index - 1
	var branch_lane_sequence: Array[int] = _build_branch_lane_sequence(plan, selection_seed, branch_span)

	for row_index in range(plan.get_row_count()):
		var lane: int = RouteLaneScript.Value.CENTER
		if row_index == 0:
			# Mirror the safe path's entry lane so the two paths still collapse onto the same
			# row-0 hold instead of adding a second one.
			lane = CHUNK_ENTRY_LANE
		elif row_index > plan.split_row_index and row_index < plan.merge_row_index:
			lane = branch_lane_sequence[row_index - plan.split_row_index - 1]

		lanes.append(lane)

	return _build_path_from_lanes(&"optional_path", lanes, anchor_graph)

func _build_branch_lane_sequence(plan: ChunkRoutePlanScript, selection_seed: String, branch_span: int) -> Array[int]:
	Validation.require_condition(branch_span > 0, "ChunkRoutePathSolver branch span must be positive.")
	var inner_lane: int = _get_inner_lane_for_side(plan.route_branch_side)
	var outer_lane: int = _get_outer_lane_for_side(plan.route_branch_side)

	var branch_lanes: Array[int] = []
	for _branch_row_index in range(branch_span):
		branch_lanes.append(inner_lane)

	var middle_count: int = branch_span - 2
	if middle_count <= 0:
		return branch_lanes

	var outer_start: int = DeterministicHash.of_string("%s:branch_lane:%d" % [selection_seed, plan.chunk_index]) % middle_count
	var extra_outer_rows: int = DeterministicHash.of_string("%s:branch_outer_extra:%d" % [selection_seed, plan.chunk_index]) % 2
	var outer_row_count: int = mini(middle_count, plan.minimum_outer_lane_rows + extra_outer_rows)
	for offset in range(outer_row_count):
		branch_lanes[1 + ((outer_start + offset) % middle_count)] = outer_lane

	return branch_lanes

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
