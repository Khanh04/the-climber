class_name ChunkRoutePopulationBuilder
extends RefCounted

const ChunkDifficultyBandScript = preload("res://src/gameplay/generation/chunk_difficulty_band.gd")
const ChunkRoutePathSolutionScript = preload("res://src/gameplay/generation/chunk_route_path_solution.gd")
const ChunkRoutePlanScript = preload("res://src/gameplay/generation/chunk_route_plan.gd")
const ChunkRoutePopulationScript = preload("res://src/gameplay/generation/chunk_route_population.gd")
const ChunkRouteSlotScript = preload("res://src/gameplay/generation/chunk_route_slot.gd")
const GeneratedHazardIntentScript = preload("res://src/gameplay/generation/generated_hazard_intent.gd")
const GeneratedHazardKindScript = preload("res://src/gameplay/generation/generated_hazard_kind.gd")
const HandholdTypeScript = preload("res://src/gameplay/generation/handhold_type.gd")
const RouteAnchorCandidateScript = preload("res://src/gameplay/generation/route_anchor_candidate.gd")
const RouteAnchorGraphScript = preload("res://src/gameplay/generation/route_anchor_graph.gd")
const RouteBranchSideScript = preload("res://src/gameplay/generation/route_branch_side.gd")
const RouteHazardPlacementScript: GDScript = preload("res://src/gameplay/generation/route_hazard_placement.gd")
const RouteLaneScript = preload("res://src/gameplay/generation/route_lane.gd")
const RouteMovementStyleScript = preload("res://src/gameplay/generation/route_movement_style.gd")
const RoutePlannedPathScript = preload("res://src/gameplay/generation/route_planned_path.gd")
const RoutePopulatedHoldScript: GDScript = preload("res://src/gameplay/generation/route_populated_hold.gd")
const RouteRewardPlacementScript: GDScript = preload("res://src/gameplay/generation/route_reward_placement.gd")
const RouteRoleScript = preload("res://src/gameplay/generation/route_role.gd")
const RouteRowRoleScript = preload("res://src/gameplay/generation/route_row_role.gd")

func populate(
	plan: ChunkRoutePlanScript,
	anchor_graph: RouteAnchorGraphScript,
	path_solution: ChunkRoutePathSolutionScript,
	selection_seed: String = ""
) -> RefCounted:
	Validation.require_condition(plan != null, "ChunkRoutePopulationBuilder requires a route plan.")
	Validation.require_condition(anchor_graph != null, "ChunkRoutePopulationBuilder requires an anchor graph.")
	Validation.require_condition(path_solution != null, "ChunkRoutePopulationBuilder requires a path solution.")
	plan.assert_valid()
	anchor_graph.assert_valid()
	path_solution.assert_valid()
	Validation.require_condition(path_solution.is_valid, "ChunkRoutePopulationBuilder requires a valid path solution.")
	Validation.require_condition(anchor_graph.row_count == plan.get_row_count(), "ChunkRoutePopulationBuilder graph row count must match the plan.")
	Validation.require_condition(path_solution.safe_path.get_row_count() == plan.get_row_count(), "ChunkRoutePopulationBuilder safe path must cover every route row.")

	var holds: Array[RefCounted] = []
	var safe_hold_ids: PackedStringArray = PackedStringArray()
	var optional_hold_ids: PackedStringArray = PackedStringArray()
	var support_hold_ids: PackedStringArray = PackedStringArray()

	_add_path_holds(plan, anchor_graph, path_solution.safe_path, false, selection_seed, holds, safe_hold_ids)
	if path_solution.optional_path != null:
		_add_path_holds(plan, anchor_graph, path_solution.optional_path, true, selection_seed, holds, optional_hold_ids)

	_add_support_holds(plan, anchor_graph, path_solution, selection_seed, holds, support_hold_ids)

	var reward_placements: Array[RefCounted] = _build_reward_placements(plan, anchor_graph, path_solution, holds)
	var hazard_placements: Array[RefCounted] = _build_hazard_placements(plan, anchor_graph, path_solution, reward_placements)

	var population_variant: Variant = ChunkRoutePopulationScript.new(holds, reward_placements, hazard_placements, safe_hold_ids, optional_hold_ids, support_hold_ids)
	Validation.require_condition(population_variant is RefCounted, "ChunkRoutePopulationBuilder must create RefCounted population instances.")
	var population: RefCounted = population_variant
	return population

func _add_path_holds(
	plan: ChunkRoutePlanScript,
	anchor_graph: RouteAnchorGraphScript,
	path: RoutePlannedPathScript,
	is_optional_path: bool,
	selection_seed: String,
	holds: Array[RefCounted],
	hold_ids: PackedStringArray
) -> void:
	Validation.require_condition(path != null, "ChunkRoutePopulationBuilder path population requires a path.")
	for row_index in range(plan.get_row_count()):
		var anchor_id: StringName = StringName(path.get_anchor_id_at_row(row_index))
		var existing_hold: RefCounted = _find_hold_by_anchor_id(holds, anchor_id)
		if existing_hold != null:
			if is_optional_path:
				existing_hold.set(&"is_optional_path", true)
			else:
				existing_hold.set(&"is_safe_path", true)
			_append_unique_hold_id(hold_ids, _require_string_name_property(existing_hold, &"hold_id"))
			continue

		var anchor: RouteAnchorCandidateScript = _get_required_anchor_for_path_row(anchor_graph, path, row_index)
		var route_role: int = _select_path_route_role(plan, anchor, is_optional_path)
		var handhold_selection_context: String = "%s:%d:%d:%d:%s:%d:%d:%d" % [
			selection_seed,
			plan.chunk_index,
			plan.route_slot,
			plan.difficulty_band,
			String(anchor.anchor_id),
			anchor.row_index,
			anchor.lane,
			int(is_optional_path)
		]
		var handhold_type: int = _select_path_handhold_type(plan, anchor.row_role, is_optional_path, handhold_selection_context)
		var hold_variant: Variant = RoutePopulatedHoldScript.new(
			anchor.anchor_id,
			anchor.anchor_id,
			anchor.row_index,
			anchor.lane,
			anchor.local_position,
			anchor.row_role,
			route_role,
			handhold_type,
			not is_optional_path,
			is_optional_path,
			false
		)
		Validation.require_condition(hold_variant is RefCounted, "ChunkRoutePopulationBuilder must create RefCounted populated holds.")
		var hold: RefCounted = hold_variant
		holds.append(hold)
		_append_unique_hold_id(hold_ids, _require_string_name_property(hold, &"hold_id"))

func _add_support_holds(
	plan: ChunkRoutePlanScript,
	anchor_graph: RouteAnchorGraphScript,
	path_solution: ChunkRoutePathSolutionScript,
	selection_seed: String,
	holds: Array[RefCounted],
	support_hold_ids: PackedStringArray
) -> void:
	Validation.require_condition(path_solution != null, "ChunkRoutePopulationBuilder support holds require a path solution.")
	for row_index in range(plan.get_row_count()):
		var support_lanes: Array[int] = _get_support_lanes_for_row(plan, path_solution, row_index)
		for support_lane in support_lanes:
			var support_anchor: RouteAnchorCandidateScript = anchor_graph.get_anchor_for_row_and_lane(row_index, support_lane)
			Validation.require_condition(support_anchor != null, "ChunkRoutePopulationBuilder support anchor must exist in the graph.")
			if _find_hold_by_anchor_id(holds, support_anchor.anchor_id) != null:
				continue

			var handhold_selection_context: String = "%s:%d:%d:%d:%s:%d:%d:support" % [
				selection_seed,
				plan.chunk_index,
				plan.route_slot,
				plan.difficulty_band,
				String(support_anchor.anchor_id),
				support_anchor.row_index,
				support_anchor.lane
			]

			var support_hold_variant: Variant = RoutePopulatedHoldScript.new(
				support_anchor.anchor_id,
				support_anchor.anchor_id,
				support_anchor.row_index,
				support_anchor.lane,
				support_anchor.local_position,
				support_anchor.row_role,
				_select_support_route_role(support_anchor.row_role),
				_select_support_handhold_type(plan, support_anchor.row_role, handhold_selection_context),
				false,
				false,
				true
			)
			Validation.require_condition(support_hold_variant is RefCounted, "ChunkRoutePopulationBuilder must create RefCounted support holds.")
			var support_hold: RefCounted = support_hold_variant
			holds.append(support_hold)
			_append_unique_hold_id(support_hold_ids, _require_string_name_property(support_hold, &"hold_id"))

func _get_support_lanes_for_row(
	plan: ChunkRoutePlanScript,
	path_solution: ChunkRoutePathSolutionScript,
	row_index: int
) -> Array[int]:
	var row_role: int = plan.row_roles[row_index]
	match plan.difficulty_band:
		ChunkDifficultyBandScript.Value.EASY:
			if row_role == RouteRowRoleScript.Value.SUPPORT or row_role == RouteRowRoleScript.Value.DECISION or row_role == RouteRowRoleScript.Value.CATCH or row_role == RouteRowRoleScript.Value.TOP_OUT:
				return _get_easy_support_lanes_for_row(plan, path_solution, row_index, row_role)
		ChunkDifficultyBandScript.Value.BASELINE:
			if row_role == RouteRowRoleScript.Value.SUPPORT or row_role == RouteRowRoleScript.Value.CATCH or row_role == RouteRowRoleScript.Value.TOP_OUT:
				return [_get_support_lane_opposite_branch(plan, row_index)]
		ChunkDifficultyBandScript.Value.CHALLENGE:
			if row_role == RouteRowRoleScript.Value.CATCH:
				return [_get_support_lane_opposite_branch(plan, row_index)]
		_:
			Validation.require_condition(false, "ChunkRoutePopulationBuilder support lanes require a supported difficulty band.")

	return []

func _get_easy_support_lanes_for_row(
	plan: ChunkRoutePlanScript,
	path_solution: ChunkRoutePathSolutionScript,
	row_index: int,
	row_role: int
) -> Array[int]:
	var safe_lane: int = path_solution.safe_path.get_lane_at_row(row_index)
	var support_lanes: Array[int] = []
	if row_index == 0 or row_index == plan.get_row_count() - 1:
		_append_unique_support_lane(support_lanes, RouteLaneScript.Value.INNER_LEFT, safe_lane)
		_append_unique_support_lane(support_lanes, RouteLaneScript.Value.INNER_RIGHT, safe_lane)
		return support_lanes

	RouteRowRoleScript.assert_valid(row_role)
	if row_role == RouteRowRoleScript.Value.DECISION:
		return _get_easy_decision_support_lanes(plan, row_index, safe_lane)
	if row_role == RouteRowRoleScript.Value.CATCH:
		return _get_easy_catch_support_lanes(plan, row_index, safe_lane)

	_append_unique_support_lane(support_lanes, _get_easy_single_support_lane(plan, row_index, safe_lane), safe_lane)
	return support_lanes

func _get_easy_single_support_lane(plan: ChunkRoutePlanScript, row_index: int, safe_lane: int) -> int:
	Validation.require_condition(plan != null, "ChunkRoutePopulationBuilder easy single supports require a route plan.")
	RouteLaneScript.assert_valid(safe_lane)
	match plan.movement_style:
		RouteMovementStyleScript.Value.LADDER:
			return _get_beginner_single_support_lane(plan, row_index, safe_lane)
		RouteMovementStyleScript.Value.ZIGZAG:
			return _get_easy_zigzag_support_lane(plan, row_index, safe_lane)
		RouteMovementStyleScript.Value.RECOVERY:
			return _get_easy_recovery_support_lane(plan, row_index, safe_lane)
		_:
			RouteMovementStyleScript.assert_valid(plan.movement_style)
			return _get_beginner_single_support_lane(plan, row_index, safe_lane)

func _get_easy_decision_support_lanes(plan: ChunkRoutePlanScript, row_index: int, safe_lane: int) -> Array[int]:
	Validation.require_condition(plan != null, "ChunkRoutePopulationBuilder easy decision supports require a route plan.")
	RouteLaneScript.assert_valid(safe_lane)
	match plan.movement_style:
		RouteMovementStyleScript.Value.LADDER:
			return _get_easy_wide_side_support_lanes(safe_lane)
		RouteMovementStyleScript.Value.ZIGZAG:
			return _get_easy_zigzag_decision_support_lanes(plan, row_index, safe_lane)
		RouteMovementStyleScript.Value.RECOVERY:
			return _get_easy_recovery_decision_support_lanes(safe_lane)
		_:
			RouteMovementStyleScript.assert_valid(plan.movement_style)
			return _get_easy_wide_side_support_lanes(safe_lane)

func _get_easy_wide_side_support_lanes(safe_lane: int) -> Array[int]:
	RouteLaneScript.assert_valid(safe_lane)
	var support_lanes: Array[int] = []
	match safe_lane:
		RouteLaneScript.Value.CENTER:
			_append_unique_support_lane(support_lanes, RouteLaneScript.Value.OUTER_LEFT, safe_lane)
			_append_unique_support_lane(support_lanes, RouteLaneScript.Value.OUTER_RIGHT, safe_lane)
		RouteLaneScript.Value.INNER_LEFT:
			_append_unique_support_lane(support_lanes, RouteLaneScript.Value.OUTER_LEFT, safe_lane)
			_append_unique_support_lane(support_lanes, RouteLaneScript.Value.OUTER_RIGHT, safe_lane)
		RouteLaneScript.Value.OUTER_LEFT:
			_append_unique_support_lane(support_lanes, RouteLaneScript.Value.INNER_LEFT, safe_lane)
			_append_unique_support_lane(support_lanes, RouteLaneScript.Value.OUTER_RIGHT, safe_lane)
		RouteLaneScript.Value.INNER_RIGHT:
			_append_unique_support_lane(support_lanes, RouteLaneScript.Value.OUTER_LEFT, safe_lane)
			_append_unique_support_lane(support_lanes, RouteLaneScript.Value.OUTER_RIGHT, safe_lane)
		RouteLaneScript.Value.OUTER_RIGHT:
			_append_unique_support_lane(support_lanes, RouteLaneScript.Value.OUTER_LEFT, safe_lane)
			_append_unique_support_lane(support_lanes, RouteLaneScript.Value.INNER_RIGHT, safe_lane)
		_:
			Validation.require_condition(false, "ChunkRoutePopulationBuilder easy wide supports require a supported safe lane.")

	return support_lanes

func _get_easy_zigzag_decision_support_lanes(plan: ChunkRoutePlanScript, row_index: int, safe_lane: int) -> Array[int]:
	Validation.require_condition(plan != null, "ChunkRoutePopulationBuilder zigzag decision supports require a route plan.")
	RouteLaneScript.assert_valid(safe_lane)
	var support_lanes: Array[int] = []
	var leans_left: bool = ((row_index + plan.chunk_index) % 2) == 0
	match safe_lane:
		RouteLaneScript.Value.CENTER:
			if leans_left:
				_append_unique_support_lane(support_lanes, RouteLaneScript.Value.OUTER_LEFT, safe_lane)
				_append_unique_support_lane(support_lanes, RouteLaneScript.Value.INNER_RIGHT, safe_lane)
			else:
				_append_unique_support_lane(support_lanes, RouteLaneScript.Value.INNER_LEFT, safe_lane)
				_append_unique_support_lane(support_lanes, RouteLaneScript.Value.OUTER_RIGHT, safe_lane)
		RouteLaneScript.Value.INNER_LEFT:
			_append_unique_support_lane(support_lanes, RouteLaneScript.Value.OUTER_LEFT, safe_lane)
			_append_unique_support_lane(support_lanes, RouteLaneScript.Value.INNER_RIGHT, safe_lane)
		RouteLaneScript.Value.OUTER_LEFT:
			_append_unique_support_lane(support_lanes, RouteLaneScript.Value.INNER_LEFT, safe_lane)
			_append_unique_support_lane(support_lanes, RouteLaneScript.Value.INNER_RIGHT, safe_lane)
		RouteLaneScript.Value.INNER_RIGHT:
			_append_unique_support_lane(support_lanes, RouteLaneScript.Value.INNER_LEFT, safe_lane)
			_append_unique_support_lane(support_lanes, RouteLaneScript.Value.OUTER_RIGHT, safe_lane)
		RouteLaneScript.Value.OUTER_RIGHT:
			_append_unique_support_lane(support_lanes, RouteLaneScript.Value.INNER_LEFT, safe_lane)
			_append_unique_support_lane(support_lanes, RouteLaneScript.Value.INNER_RIGHT, safe_lane)
		_:
			Validation.require_condition(false, "ChunkRoutePopulationBuilder zigzag decision supports require a supported safe lane.")

	return support_lanes

func _get_easy_recovery_decision_support_lanes(safe_lane: int) -> Array[int]:
	RouteLaneScript.assert_valid(safe_lane)
	var support_lanes: Array[int] = []
	match safe_lane:
		RouteLaneScript.Value.CENTER:
			_append_unique_support_lane(support_lanes, RouteLaneScript.Value.INNER_LEFT, safe_lane)
			_append_unique_support_lane(support_lanes, RouteLaneScript.Value.INNER_RIGHT, safe_lane)
		RouteLaneScript.Value.INNER_LEFT:
			_append_unique_support_lane(support_lanes, RouteLaneScript.Value.OUTER_LEFT, safe_lane)
			_append_unique_support_lane(support_lanes, RouteLaneScript.Value.INNER_RIGHT, safe_lane)
		RouteLaneScript.Value.OUTER_LEFT:
			_append_unique_support_lane(support_lanes, RouteLaneScript.Value.INNER_LEFT, safe_lane)
			_append_unique_support_lane(support_lanes, RouteLaneScript.Value.INNER_RIGHT, safe_lane)
		RouteLaneScript.Value.INNER_RIGHT:
			_append_unique_support_lane(support_lanes, RouteLaneScript.Value.INNER_LEFT, safe_lane)
			_append_unique_support_lane(support_lanes, RouteLaneScript.Value.OUTER_RIGHT, safe_lane)
		RouteLaneScript.Value.OUTER_RIGHT:
			_append_unique_support_lane(support_lanes, RouteLaneScript.Value.INNER_LEFT, safe_lane)
			_append_unique_support_lane(support_lanes, RouteLaneScript.Value.INNER_RIGHT, safe_lane)
		_:
			Validation.require_condition(false, "ChunkRoutePopulationBuilder recovery decision supports require a supported safe lane.")

	return support_lanes

func _get_easy_catch_support_lanes(plan: ChunkRoutePlanScript, row_index: int, safe_lane: int) -> Array[int]:
	Validation.require_condition(plan != null, "ChunkRoutePopulationBuilder easy catch supports require a route plan.")
	RouteLaneScript.assert_valid(safe_lane)
	var support_lanes: Array[int] = []
	match safe_lane:
		RouteLaneScript.Value.CENTER:
			if ((row_index + plan.chunk_index) % 2) == 0:
				_append_unique_support_lane(support_lanes, RouteLaneScript.Value.INNER_LEFT, safe_lane)
				_append_unique_support_lane(support_lanes, RouteLaneScript.Value.OUTER_RIGHT, safe_lane)
			else:
				_append_unique_support_lane(support_lanes, RouteLaneScript.Value.OUTER_LEFT, safe_lane)
				_append_unique_support_lane(support_lanes, RouteLaneScript.Value.INNER_RIGHT, safe_lane)
		RouteLaneScript.Value.INNER_LEFT:
			_append_unique_support_lane(support_lanes, RouteLaneScript.Value.OUTER_LEFT, safe_lane)
			_append_unique_support_lane(support_lanes, RouteLaneScript.Value.INNER_RIGHT, safe_lane)
		RouteLaneScript.Value.OUTER_LEFT:
			_append_unique_support_lane(support_lanes, RouteLaneScript.Value.INNER_LEFT, safe_lane)
			_append_unique_support_lane(support_lanes, RouteLaneScript.Value.INNER_RIGHT, safe_lane)
		RouteLaneScript.Value.INNER_RIGHT:
			_append_unique_support_lane(support_lanes, RouteLaneScript.Value.INNER_LEFT, safe_lane)
			_append_unique_support_lane(support_lanes, RouteLaneScript.Value.OUTER_RIGHT, safe_lane)
		RouteLaneScript.Value.OUTER_RIGHT:
			_append_unique_support_lane(support_lanes, RouteLaneScript.Value.INNER_LEFT, safe_lane)
			_append_unique_support_lane(support_lanes, RouteLaneScript.Value.INNER_RIGHT, safe_lane)
		_:
			Validation.require_condition(false, "ChunkRoutePopulationBuilder easy catch supports require a supported safe lane.")

	return support_lanes

func _get_beginner_single_support_lane(plan: ChunkRoutePlanScript, row_index: int, safe_lane: int) -> int:
	RouteLaneScript.assert_valid(safe_lane)
	match safe_lane:
		RouteLaneScript.Value.CENTER:
			if plan.optional_route_required:
				return _get_wide_support_lane_opposite_branch(plan, row_index)

			return _get_alternating_beginner_outer_lane(plan, row_index)
		RouteLaneScript.Value.INNER_LEFT:
			return RouteLaneScript.Value.OUTER_LEFT
		RouteLaneScript.Value.OUTER_LEFT:
			return RouteLaneScript.Value.INNER_LEFT
		RouteLaneScript.Value.INNER_RIGHT:
			return RouteLaneScript.Value.OUTER_RIGHT
		RouteLaneScript.Value.OUTER_RIGHT:
			return RouteLaneScript.Value.INNER_RIGHT
		_:
			Validation.require_condition(false, "ChunkRoutePopulationBuilder beginner support lanes require a supported safe lane.")
			return RouteLaneScript.Value.CENTER

func _get_easy_zigzag_support_lane(plan: ChunkRoutePlanScript, row_index: int, safe_lane: int) -> int:
	Validation.require_condition(plan != null, "ChunkRoutePopulationBuilder zigzag supports require a route plan.")
	RouteLaneScript.assert_valid(safe_lane)
	match safe_lane:
		RouteLaneScript.Value.CENTER:
			return _get_alternating_beginner_inner_lane(plan, row_index)
		RouteLaneScript.Value.INNER_LEFT:
			return RouteLaneScript.Value.INNER_RIGHT
		RouteLaneScript.Value.OUTER_LEFT:
			return RouteLaneScript.Value.INNER_LEFT
		RouteLaneScript.Value.INNER_RIGHT:
			return RouteLaneScript.Value.INNER_LEFT
		RouteLaneScript.Value.OUTER_RIGHT:
			return RouteLaneScript.Value.INNER_RIGHT
		_:
			Validation.require_condition(false, "ChunkRoutePopulationBuilder zigzag supports require a supported safe lane.")
			return RouteLaneScript.Value.CENTER

func _get_easy_recovery_support_lane(plan: ChunkRoutePlanScript, row_index: int, safe_lane: int) -> int:
	Validation.require_condition(plan != null, "ChunkRoutePopulationBuilder recovery supports require a route plan.")
	RouteLaneScript.assert_valid(safe_lane)
	match safe_lane:
		RouteLaneScript.Value.CENTER:
			return _get_alternating_beginner_inner_lane(plan, row_index)
		RouteLaneScript.Value.INNER_LEFT:
			return RouteLaneScript.Value.OUTER_LEFT
		RouteLaneScript.Value.OUTER_LEFT:
			return RouteLaneScript.Value.INNER_LEFT
		RouteLaneScript.Value.INNER_RIGHT:
			return RouteLaneScript.Value.OUTER_RIGHT
		RouteLaneScript.Value.OUTER_RIGHT:
			return RouteLaneScript.Value.INNER_RIGHT
		_:
			Validation.require_condition(false, "ChunkRoutePopulationBuilder recovery supports require a supported safe lane.")
			return RouteLaneScript.Value.CENTER

func _get_alternating_beginner_inner_lane(plan: ChunkRoutePlanScript, row_index: int) -> int:
	Validation.require_condition(plan != null, "ChunkRoutePopulationBuilder alternating inner supports require a route plan.")
	var lane_index: int = (row_index + plan.chunk_index) % 2
	if lane_index == 0:
		return RouteLaneScript.Value.INNER_LEFT

	return RouteLaneScript.Value.INNER_RIGHT

func _get_alternating_beginner_outer_lane(plan: ChunkRoutePlanScript, row_index: int) -> int:
	var lane_index: int = (row_index + plan.chunk_index) % 2
	if lane_index == 0:
		return RouteLaneScript.Value.OUTER_LEFT

	return RouteLaneScript.Value.OUTER_RIGHT

func _get_wide_support_lane_opposite_branch(plan: ChunkRoutePlanScript, row_index: int) -> int:
	Validation.require_condition(plan.optional_route_required, "ChunkRoutePopulationBuilder wide branch supports require an optional route plan.")
	if plan.route_branch_side == RouteBranchSideScript.Value.LEFT:
		if ((row_index + plan.chunk_index) % 2) == 0:
			return RouteLaneScript.Value.OUTER_RIGHT
		return RouteLaneScript.Value.INNER_RIGHT

	if ((row_index + plan.chunk_index) % 2) == 0:
		return RouteLaneScript.Value.OUTER_LEFT
	return RouteLaneScript.Value.INNER_LEFT

func _append_unique_support_lane(support_lanes: Array[int], candidate_lane: int, excluded_lane: int) -> void:
	RouteLaneScript.assert_valid(candidate_lane)
	RouteLaneScript.assert_valid(excluded_lane)
	if candidate_lane == excluded_lane:
		return

	if support_lanes.has(candidate_lane):
		return

	support_lanes.append(candidate_lane)

func _get_support_lane_opposite_branch(plan: ChunkRoutePlanScript, row_index: int) -> int:
	if plan.optional_route_required:
		if plan.route_branch_side == RouteBranchSideScript.Value.LEFT:
			return RouteLaneScript.Value.INNER_RIGHT
		return RouteLaneScript.Value.INNER_LEFT

	if (row_index % 2) == 0:
		return RouteLaneScript.Value.INNER_LEFT
	return RouteLaneScript.Value.INNER_RIGHT

func _select_path_route_role(plan: ChunkRoutePlanScript, anchor: RouteAnchorCandidateScript, is_optional_path: bool) -> int:
	if anchor.row_index == 0:
		return RouteRoleScript.Value.ENTRY

	if anchor.row_index == plan.get_row_count() - 1 or anchor.row_role == RouteRowRoleScript.Value.TOP_OUT:
		return RouteRoleScript.Value.TOP_OUT

	if is_optional_path and anchor.lane != RouteLaneScript.Value.CENTER:
		match plan.route_slot:
			ChunkRouteSlotScript.Value.RISK, ChunkRouteSlotScript.Value.PRESSURE:
				return RouteRoleScript.Value.HAZARD_DENIAL
			_:
				return RouteRoleScript.Value.OPTIONAL_BETA

	match anchor.row_role:
		RouteRowRoleScript.Value.CRUX, RouteRowRoleScript.Value.PRESSURE:
			return RouteRoleScript.Value.CRUX
		RouteRowRoleScript.Value.CATCH:
			return RouteRoleScript.Value.RECOVERY
		RouteRowRoleScript.Value.TOP_OUT:
			return RouteRoleScript.Value.TOP_OUT
		_:
			RouteRowRoleScript.assert_valid(anchor.row_role)
			return RouteRoleScript.Value.SETUP

func _select_support_route_role(row_role: int) -> int:
	match row_role:
		RouteRowRoleScript.Value.CATCH:
			return RouteRoleScript.Value.RECOVERY
		RouteRowRoleScript.Value.TOP_OUT:
			return RouteRoleScript.Value.TOP_OUT
		_:
			RouteRowRoleScript.assert_valid(row_role)
			return RouteRoleScript.Value.SETUP

func _select_path_handhold_type(plan: ChunkRoutePlanScript, row_role: int, is_optional_path: bool, selection_context: String) -> int:
	if is_optional_path:
		match row_role:
			RouteRowRoleScript.Value.CRUX, RouteRowRoleScript.Value.PRESSURE:
				if plan.difficulty_band == ChunkDifficultyBandScript.Value.CHALLENGE:
					return _select_allowed_handhold_type([HandholdTypeScript.Value.GHOST, HandholdTypeScript.Value.BREAK, HandholdTypeScript.Value.BURN, HandholdTypeScript.Value.NORMAL], plan.optional_path_allowed_handhold_types, selection_context)
				return _select_allowed_handhold_type([HandholdTypeScript.Value.BREAK, HandholdTypeScript.Value.BURN, HandholdTypeScript.Value.NORMAL], plan.optional_path_allowed_handhold_types, selection_context)
			RouteRowRoleScript.Value.TRAVERSE:
				return _select_allowed_handhold_type([HandholdTypeScript.Value.ROCKET, HandholdTypeScript.Value.BOOST, HandholdTypeScript.Value.BURN, HandholdTypeScript.Value.NORMAL], plan.optional_path_allowed_handhold_types, selection_context)
			RouteRowRoleScript.Value.CATCH:
				return _select_allowed_handhold_type([HandholdTypeScript.Value.REST, HandholdTypeScript.Value.NORMAL], plan.optional_path_allowed_handhold_types, selection_context)
			_:
				RouteRowRoleScript.assert_valid(row_role)
				return _select_allowed_handhold_type([HandholdTypeScript.Value.NORMAL, HandholdTypeScript.Value.BURN], plan.optional_path_allowed_handhold_types, selection_context)

	match row_role:
		RouteRowRoleScript.Value.CATCH:
			return _select_allowed_handhold_type([HandholdTypeScript.Value.REST, HandholdTypeScript.Value.NORMAL], plan.safe_path_allowed_handhold_types, selection_context)
		RouteRowRoleScript.Value.CRUX:
			return _select_allowed_handhold_type([HandholdTypeScript.Value.BURN, HandholdTypeScript.Value.NORMAL], plan.safe_path_allowed_handhold_types, selection_context)
		RouteRowRoleScript.Value.PRESSURE:
			return _select_allowed_handhold_type([HandholdTypeScript.Value.BURN, HandholdTypeScript.Value.NORMAL], plan.safe_path_allowed_handhold_types, selection_context)
		_:
			RouteRowRoleScript.assert_valid(row_role)
			return _select_allowed_handhold_type([HandholdTypeScript.Value.NORMAL, HandholdTypeScript.Value.REST], plan.safe_path_allowed_handhold_types, selection_context)

func _select_support_handhold_type(plan: ChunkRoutePlanScript, row_role: int, selection_context: String) -> int:
	if row_role == RouteRowRoleScript.Value.CATCH or row_role == RouteRowRoleScript.Value.SUPPORT:
		return _select_allowed_handhold_type([HandholdTypeScript.Value.REST, HandholdTypeScript.Value.NORMAL], plan.safe_path_allowed_handhold_types, selection_context)

	RouteRowRoleScript.assert_valid(row_role)
	return _select_allowed_handhold_type([HandholdTypeScript.Value.NORMAL, HandholdTypeScript.Value.REST], plan.safe_path_allowed_handhold_types, selection_context)

func _select_allowed_handhold_type(preferred_types: Array[int], allowed_types: Array[int], selection_context: String) -> int:
	Validation.require_condition(not preferred_types.is_empty(), "ChunkRoutePopulationBuilder handhold type selection requires preferences.")
	Validation.require_condition(not allowed_types.is_empty(), "ChunkRoutePopulationBuilder handhold type selection requires allowed types.")
	var eligible_types: Array[int] = []
	for preferred_type in preferred_types:
		HandholdTypeScript.assert_valid(preferred_type)
		if allowed_types.has(preferred_type):
			eligible_types.append(preferred_type)

	Validation.require_condition(not eligible_types.is_empty(), "ChunkRoutePopulationBuilder could not select an allowed handhold type.")
	if selection_context == "" or eligible_types.size() == 1:
		return eligible_types[0]

	var weighted_types: Array[int] = []
	var eligible_count: int = eligible_types.size()
	for eligible_index in range(eligible_count):
		var eligible_type: int = eligible_types[eligible_index]
		var weight: int = (eligible_count - eligible_index) * (eligible_count - eligible_index)
		for weight_index in range(weight):
			weighted_types.append(eligible_type)

	var selected_index: int = abs(selection_context.hash()) % weighted_types.size()
	return weighted_types[selected_index]

func _build_reward_placements(
	plan: ChunkRoutePlanScript,
	anchor_graph: RouteAnchorGraphScript,
	path_solution: ChunkRoutePathSolutionScript,
	holds: Array[RefCounted]
) -> Array[RefCounted]:
	var reward_placements: Array[RefCounted] = []
	if plan.route_slot == ChunkRouteSlotScript.Value.OPENER or plan.route_slot == ChunkRouteSlotScript.Value.BASELINE:
		return reward_placements

	var reward_anchor: RouteAnchorCandidateScript = _select_reward_anchor(plan, anchor_graph, path_solution)
	Validation.require_condition(reward_anchor != null, "ChunkRoutePopulationBuilder reward anchor must exist.")
	Validation.require_condition(_find_hold_by_anchor_id(holds, reward_anchor.anchor_id) != null, "ChunkRoutePopulationBuilder reward anchor must reference a selected hold.")
	var reward_placement_variant: Variant = RouteRewardPlacementScript.new(
		StringName("reward_%s" % String(reward_anchor.anchor_id)),
		reward_anchor.anchor_id,
		reward_anchor.row_index,
		reward_anchor.lane,
		reward_anchor.local_position
	)
	Validation.require_condition(reward_placement_variant is RefCounted, "ChunkRoutePopulationBuilder must create RefCounted reward placements.")
	var reward_placement: RefCounted = reward_placement_variant
	reward_placements.append(reward_placement)
	return reward_placements

func _build_hazard_placements(
	plan: ChunkRoutePlanScript,
	anchor_graph: RouteAnchorGraphScript,
	path_solution: ChunkRoutePathSolutionScript,
	reward_placements: Array[RefCounted]
) -> Array[RefCounted]:
	var hazard_placements: Array[RefCounted] = []
	for hazard_intent in plan.hazard_intents:
		var anchor: RouteAnchorCandidateScript = _select_hazard_anchor(plan, anchor_graph, path_solution, reward_placements, hazard_intent)
		var hazard_kind: int = _get_hazard_kind_for_intent(hazard_intent)
		var hazard_placement_variant: Variant = RouteHazardPlacementScript.new(
			StringName("hazard_%s_%s" % [GeneratedHazardIntentScript.to_label(hazard_intent).to_lower(), String(anchor.anchor_id)]),
			anchor.anchor_id,
			hazard_intent,
			hazard_kind,
			anchor.row_index,
			anchor.lane,
			anchor.local_position
		)
		Validation.require_condition(hazard_placement_variant is RefCounted, "ChunkRoutePopulationBuilder must create RefCounted hazard placements.")
		var hazard_placement: RefCounted = hazard_placement_variant
		hazard_placements.append(hazard_placement)

	return hazard_placements

func _select_reward_anchor(
	plan: ChunkRoutePlanScript,
	anchor_graph: RouteAnchorGraphScript,
	path_solution: ChunkRoutePathSolutionScript
) -> RouteAnchorCandidateScript:
	if path_solution.optional_path != null:
		var branch_row_index: int = _find_last_outer_lane_row_for_path(plan, path_solution.optional_path, plan.route_branch_side)
		return _get_required_anchor_for_path_row(anchor_graph, path_solution.optional_path, branch_row_index)

	var catch_row_index: int = _find_first_row_with_role(plan, RouteRowRoleScript.Value.CATCH)
	return _get_required_anchor_for_path_row(anchor_graph, path_solution.safe_path, catch_row_index)

func _select_hazard_anchor(
	plan: ChunkRoutePlanScript,
	anchor_graph: RouteAnchorGraphScript,
	path_solution: ChunkRoutePathSolutionScript,
	reward_placements: Array[RefCounted],
	hazard_intent: int
) -> RouteAnchorCandidateScript:
	GeneratedHazardIntentScript.assert_valid(hazard_intent)
	match hazard_intent:
		GeneratedHazardIntentScript.Value.OPTIONAL_BRANCH_DENIAL:
			Validation.require_condition(path_solution.optional_path != null, "Optional branch denial requires an optional path.")
			return _get_required_anchor_for_path_row(
				anchor_graph,
				path_solution.optional_path,
				_find_last_outer_lane_row_for_path(plan, path_solution.optional_path, plan.route_branch_side)
			)
		GeneratedHazardIntentScript.Value.REWARD_GREED_PRESSURE:
			Validation.require_condition(not reward_placements.is_empty(), "Reward greed pressure requires a reward placement.")
			var reward_placement: RefCounted = reward_placements[0]
			return anchor_graph.get_anchor_for_row_and_lane(
				_require_int_property(reward_placement, &"row_index"),
				_require_int_property(reward_placement, &"lane")
			)
		GeneratedHazardIntentScript.Value.CRUX_PRESSURE:
			return _get_required_anchor_for_path_row(anchor_graph, path_solution.safe_path, _find_pressure_row(plan))
		GeneratedHazardIntentScript.Value.TRAVERSE_FORCE:
			if path_solution.optional_path != null:
				return _get_required_anchor_for_path_row(
					anchor_graph,
					path_solution.optional_path,
					_find_first_outer_lane_row_for_path(plan, path_solution.optional_path, plan.route_branch_side)
				)
			return _get_required_anchor_for_path_row(anchor_graph, path_solution.safe_path, _find_traverse_force_row(plan))
		GeneratedHazardIntentScript.Value.RECOVERY_LIFT, GeneratedHazardIntentScript.Value.SAFE_ROUTE_RELIEF:
			return _get_required_anchor_for_path_row(anchor_graph, path_solution.safe_path, _find_first_row_with_role(plan, RouteRowRoleScript.Value.CATCH))
		_:
			Validation.require_condition(false, "ChunkRoutePopulationBuilder requires a supported hazard intent.")
			return null

func _get_hazard_kind_for_intent(hazard_intent: int) -> int:
	match hazard_intent:
		GeneratedHazardIntentScript.Value.OPTIONAL_BRANCH_DENIAL:
			return GeneratedHazardKindScript.Value.SPIKE_CLUSTER
		GeneratedHazardIntentScript.Value.CRUX_PRESSURE, GeneratedHazardIntentScript.Value.REWARD_GREED_PRESSURE:
			return GeneratedHazardKindScript.Value.DOWNDRAFT
		GeneratedHazardIntentScript.Value.TRAVERSE_FORCE:
			return GeneratedHazardKindScript.Value.WIND_GUST
		GeneratedHazardIntentScript.Value.RECOVERY_LIFT, GeneratedHazardIntentScript.Value.SAFE_ROUTE_RELIEF:
			return GeneratedHazardKindScript.Value.UPDRAFT
		_:
			Validation.require_condition(false, "ChunkRoutePopulationBuilder requires a supported hazard intent kind.")
			return GeneratedHazardKindScript.Value.SPIKE_CLUSTER

func _find_pressure_row(plan: ChunkRoutePlanScript) -> int:
	var pressure_row_index: int = _try_find_first_row_with_role(plan, RouteRowRoleScript.Value.PRESSURE)
	if pressure_row_index != -1:
		return pressure_row_index

	return _find_first_row_with_role(plan, RouteRowRoleScript.Value.CRUX)

func _find_traverse_force_row(plan: ChunkRoutePlanScript) -> int:
	var traverse_row_index: int = _try_find_first_row_with_role(plan, RouteRowRoleScript.Value.TRAVERSE)
	if traverse_row_index != -1:
		return traverse_row_index

	return _find_first_row_with_role(plan, RouteRowRoleScript.Value.DECISION)

func _find_first_outer_lane_row_for_path(plan: ChunkRoutePlanScript, path: RoutePlannedPathScript, branch_side: int) -> int:
	Validation.require_condition(plan.optional_route_required, "ChunkRoutePopulationBuilder outer branch rows require an optional route plan.")
	Validation.require_condition(path != null, "ChunkRoutePopulationBuilder outer branch rows require a path.")
	RouteBranchSideScript.assert_valid(branch_side)
	Validation.require_condition(branch_side != RouteBranchSideScript.Value.NONE, "ChunkRoutePopulationBuilder outer branch rows require a branch side.")
	for row_index in range(plan.split_row_index + 1, plan.merge_row_index):
		if _path_row_uses_outer_side(path, row_index, branch_side):
			return row_index

	Validation.require_condition(false, "ChunkRoutePopulationBuilder could not find an outer branch row.")
	return plan.split_row_index + 1

func _find_last_outer_lane_row_for_path(plan: ChunkRoutePlanScript, path: RoutePlannedPathScript, branch_side: int) -> int:
	Validation.require_condition(plan.optional_route_required, "ChunkRoutePopulationBuilder outer branch rows require an optional route plan.")
	Validation.require_condition(path != null, "ChunkRoutePopulationBuilder outer branch rows require a path.")
	RouteBranchSideScript.assert_valid(branch_side)
	Validation.require_condition(branch_side != RouteBranchSideScript.Value.NONE, "ChunkRoutePopulationBuilder outer branch rows require a branch side.")
	for row_index in range(plan.merge_row_index - 1, plan.split_row_index, -1):
		if _path_row_uses_outer_side(path, row_index, branch_side):
			return row_index

	Validation.require_condition(false, "ChunkRoutePopulationBuilder could not find an outer branch row.")
	return plan.merge_row_index - 1

func _path_row_uses_outer_side(path: RoutePlannedPathScript, row_index: int, branch_side: int) -> bool:
	RouteBranchSideScript.assert_valid(branch_side)
	var lane: int = path.get_lane_at_row(row_index)
	return RouteLaneScript.is_outer(lane) and RouteLaneScript.to_branch_side(lane) == branch_side

func _find_first_row_with_role(plan: ChunkRoutePlanScript, row_role: int) -> int:
	var row_index: int = _try_find_first_row_with_role(plan, row_role)
	Validation.require_condition(row_index != -1, "ChunkRoutePopulationBuilder could not find a required route row role.")
	return row_index

func _try_find_first_row_with_role(plan: ChunkRoutePlanScript, row_role: int) -> int:
	RouteRowRoleScript.assert_valid(row_role)
	for row_index in range(plan.row_roles.size()):
		if plan.row_roles[row_index] == row_role:
			return row_index
	return -1

func _get_required_anchor_for_path_row(
	anchor_graph: RouteAnchorGraphScript,
	path: RoutePlannedPathScript,
	row_index: int
) -> RouteAnchorCandidateScript:
	var lane: int = path.get_lane_at_row(row_index)
	var anchor: RouteAnchorCandidateScript = anchor_graph.get_anchor_for_row_and_lane(row_index, lane)
	Validation.require_condition(anchor != null, "ChunkRoutePopulationBuilder path anchor must exist in the graph.")
	return anchor

func _find_hold_by_anchor_id(holds: Array[RefCounted], anchor_id: StringName) -> RefCounted:
	for hold in holds:
		if _require_string_name_property(hold, &"anchor_id") == anchor_id:
			return hold
	return null

func _append_unique_hold_id(hold_ids: PackedStringArray, hold_id: StringName) -> void:
	if not hold_ids.has(String(hold_id)):
		var _append_result: bool = hold_ids.append(String(hold_id))

func _require_string_name_property(source: RefCounted, property_name: StringName) -> StringName:
	var raw_value: Variant = source.get(property_name)
	Validation.require_condition(raw_value is StringName, "ChunkRoutePopulationBuilder expected a StringName property.")
	var typed_value: StringName = raw_value
	return typed_value

func _require_int_property(source: RefCounted, property_name: StringName) -> int:
	var raw_value: Variant = source.get(property_name)
	Validation.require_condition(raw_value is int, "ChunkRoutePopulationBuilder expected an int property.")
	var typed_value: int = raw_value
	return typed_value