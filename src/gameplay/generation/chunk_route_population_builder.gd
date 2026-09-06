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
const RoutePlannedPathScript = preload("res://src/gameplay/generation/route_planned_path.gd")
const RoutePopulatedHoldScript: GDScript = preload("res://src/gameplay/generation/route_populated_hold.gd")
const RouteRewardPlacementScript: GDScript = preload("res://src/gameplay/generation/route_reward_placement.gd")
const RouteRoleScript = preload("res://src/gameplay/generation/route_role.gd")
const RouteRowRoleScript = preload("res://src/gameplay/generation/route_row_role.gd")

func populate(
	plan: ChunkRoutePlanScript,
	anchor_graph: RouteAnchorGraphScript,
	path_solution: ChunkRoutePathSolutionScript,
	player_body_width_meters: float,
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

	_add_support_holds(plan, anchor_graph, path_solution, player_body_width_meters, selection_seed, holds, support_hold_ids)

	var reward_placements: Array[RefCounted] = _build_reward_placements(plan, anchor_graph, path_solution, holds, selection_seed)
	var hazard_placements: Array[RefCounted] = _build_hazard_placements(plan, anchor_graph, path_solution, reward_placements, selection_seed)

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
	player_body_width_meters: float,
	selection_seed: String,
	holds: Array[RefCounted],
	support_hold_ids: PackedStringArray
) -> void:
	Validation.require_condition(path_solution != null, "ChunkRoutePopulationBuilder support holds require a path solution.")
	for row_index in range(plan.get_row_count()):
		var support_lanes: Array[int] = _get_support_lanes_for_row(plan, anchor_graph, path_solution, row_index, player_body_width_meters)
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

## Picks 0-2 non-path lanes to decorate a row with, favoring lanes closest to the lanes the
## path already uses (keeps support holds visually grouped near the climb) and clear of the
## player's swing envelope around whichever path anchor sits on this row. How many is driven by
## row purpose and difficulty band -- generous on easy rest/decision rows, sparse to none once
## crux/pressure/traverse rows or higher bands ask for a cleaner wall.
func _get_support_lanes_for_row(
	plan: ChunkRoutePlanScript,
	anchor_graph: RouteAnchorGraphScript,
	path_solution: ChunkRoutePathSolutionScript,
	row_index: int,
	player_body_width_meters: float
) -> Array[int]:
	var row_role: int = plan.row_roles[row_index]
	var max_support_lanes: int = _get_max_support_lane_count(plan, row_role)
	if max_support_lanes <= 0:
		return []

	var safe_lane: int = path_solution.safe_path.get_lane_at_row(row_index)
	var excluded_lanes: Array[int] = [safe_lane]
	if plan.optional_route_required:
		var optional_lane: int = path_solution.optional_path.get_lane_at_row(row_index)
		if not excluded_lanes.has(optional_lane):
			excluded_lanes.append(optional_lane)

	var path_position: Vector2 = anchor_graph.get_anchor_for_row_and_lane(row_index, safe_lane).local_position
	var candidate_lanes: Array[int] = []
	for lane in RouteLaneScript.get_all_values():
		if excluded_lanes.has(lane):
			continue

		var anchor: RouteAnchorCandidateScript = anchor_graph.get_anchor_for_row_and_lane(row_index, lane)
		if anchor == null:
			continue

		if absf(anchor.local_position.x - path_position.x) < player_body_width_meters:
			continue

		candidate_lanes.append(lane)

	candidate_lanes.sort_custom(func(a: int, b: int) -> bool: return _get_support_lane_pick_priority(a, safe_lane) < _get_support_lane_pick_priority(b, safe_lane))
	if candidate_lanes.size() > max_support_lanes:
		candidate_lanes = candidate_lanes.slice(0, max_support_lanes)
	return candidate_lanes

## The path's mirror lane (same distance, opposite side) ranks first -- it frames the path
## symmetrically, e.g. row 0's fixed INNER_LEFT entry pairs with an INNER_RIGHT support hold so
## the centre corridor between them stays clear for the player's body. CENTER has no mirror;
## everything else ranks by how close it sits to the middle of the wall.
func _get_support_lane_pick_priority(lane: int, safe_lane: int) -> int:
	if lane == _get_mirror_lane(safe_lane):
		return 0
	return 1 + absi(RouteLaneScript.to_offset(lane))

func _get_mirror_lane(lane: int) -> int:
	match lane:
		RouteLaneScript.Value.INNER_LEFT:
			return RouteLaneScript.Value.INNER_RIGHT
		RouteLaneScript.Value.INNER_RIGHT:
			return RouteLaneScript.Value.INNER_LEFT
		RouteLaneScript.Value.OUTER_LEFT:
			return RouteLaneScript.Value.OUTER_RIGHT
		RouteLaneScript.Value.OUTER_RIGHT:
			return RouteLaneScript.Value.OUTER_LEFT
		_:
			return -1

## Once altitude has pushed the target difficulty past the top authored band, thin
## the wall by one more support lane per row -- see docs/route-generation-audit.md C6.
const HIGH_ALTITUDE_SUPPORT_CUTOFF: float = 0.1

func _get_max_support_lane_count(plan: ChunkRoutePlanScript, row_role: int) -> int:
	var base_support_lane_count: int = _base_max_support_lane_count(plan.difficulty_band, row_role)
	if plan.altitude_difficulty_bonus >= HIGH_ALTITUDE_SUPPORT_CUTOFF:
		return maxi(0, base_support_lane_count - 1)
	return base_support_lane_count

func _base_max_support_lane_count(difficulty_band: int, row_role: int) -> int:
	RouteRowRoleScript.assert_valid(row_role)
	match difficulty_band:
		ChunkDifficultyBandScript.Value.EASY:
			match row_role:
				RouteRowRoleScript.Value.CRUX, RouteRowRoleScript.Value.PRESSURE, RouteRowRoleScript.Value.TRAVERSE:
					return 0
				RouteRowRoleScript.Value.DECISION:
					return 2
				_:
					return 1
		ChunkDifficultyBandScript.Value.BASELINE:
			match row_role:
				RouteRowRoleScript.Value.SUPPORT, RouteRowRoleScript.Value.CATCH, RouteRowRoleScript.Value.TOP_OUT:
					return 1
				_:
					return 0
		ChunkDifficultyBandScript.Value.CHALLENGE:
			match row_role:
				RouteRowRoleScript.Value.CATCH:
					return 1
				_:
					return 0
		_:
			Validation.require_condition(false, "ChunkRoutePopulationBuilder support lanes require a supported difficulty band.")
			return 0

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

	var selected_index: int = DeterministicHash.of_string(selection_context) % weighted_types.size()
	return weighted_types[selected_index]

func _build_reward_placements(
	plan: ChunkRoutePlanScript,
	anchor_graph: RouteAnchorGraphScript,
	path_solution: ChunkRoutePathSolutionScript,
	holds: Array[RefCounted],
	selection_seed: String
) -> Array[RefCounted]:
	var reward_placements: Array[RefCounted] = []
	var reward_count: int = _get_reward_count(plan, selection_seed)
	if reward_count <= 0:
		return reward_placements

	for reward_anchor in _select_reward_anchors(plan, anchor_graph, path_solution, reward_count, selection_seed):
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

## Seeded, band-scaled coin count. Opener stays sparse (onboarding); higher bands
## carry more. No slot is excluded any more -- see docs/route-generation-audit.md A9.
func _get_reward_count(plan: ChunkRoutePlanScript, selection_seed: String) -> int:
	var base_reward_count: int = 1
	if plan.difficulty_band == ChunkDifficultyBandScript.Value.CHALLENGE:
		base_reward_count = 2
	if plan.route_slot == ChunkRouteSlotScript.Value.OPENER:
		base_reward_count = maxi(0, base_reward_count - 1)
	var seeded_bump: int = DeterministicHash.of_string("%s:reward_count:%d" % [selection_seed, plan.chunk_index]) % 2
	return base_reward_count + seeded_bump

func _select_reward_anchors(
	plan: ChunkRoutePlanScript,
	anchor_graph: RouteAnchorGraphScript,
	path_solution: ChunkRoutePathSolutionScript,
	reward_count: int,
	selection_seed: String
) -> Array[RouteAnchorCandidateScript]:
	var reward_anchors: Array[RouteAnchorCandidateScript] = []
	var used_anchor_ids: Dictionary[StringName, bool] = {}
	var primary_anchor: RouteAnchorCandidateScript = _select_reward_anchor(plan, anchor_graph, path_solution)
	reward_anchors.append(primary_anchor)
	used_anchor_ids[primary_anchor.anchor_id] = true
	if reward_count <= 1:
		return reward_anchors

	# Extras go off the safe path where a branch exists -- the optional line's outer
	# rows -- so the coins pull players onto the risky route; otherwise onto other
	# catch rows.
	var extra_anchors: Array[RouteAnchorCandidateScript] = _collect_extra_reward_anchors(plan, anchor_graph, path_solution, primary_anchor)
	if extra_anchors.is_empty():
		return reward_anchors

	var start_offset: int = DeterministicHash.of_string("%s:reward_offset:%d" % [selection_seed, plan.chunk_index]) % extra_anchors.size()
	for step in range(extra_anchors.size()):
		if reward_anchors.size() >= reward_count:
			break
		var candidate: RouteAnchorCandidateScript = extra_anchors[(start_offset + step) % extra_anchors.size()]
		if candidate != null and not used_anchor_ids.has(candidate.anchor_id):
			reward_anchors.append(candidate)
			used_anchor_ids[candidate.anchor_id] = true
	return reward_anchors

func _collect_extra_reward_anchors(
	plan: ChunkRoutePlanScript,
	anchor_graph: RouteAnchorGraphScript,
	path_solution: ChunkRoutePathSolutionScript,
	primary_anchor: RouteAnchorCandidateScript
) -> Array[RouteAnchorCandidateScript]:
	var extra_anchors: Array[RouteAnchorCandidateScript] = []
	if path_solution.optional_path != null:
		# The first and last outer branch rows carry the traverse-force / branch-denial
		# hazards; leave them so an extra coin never lands on top of a hazard.
		var first_outer_row_index: int = _find_first_outer_lane_row_for_path(plan, path_solution.optional_path, plan.route_branch_side)
		var last_outer_row_index: int = _find_last_outer_lane_row_for_path(plan, path_solution.optional_path, plan.route_branch_side)
		for row_index in range(plan.split_row_index + 1, plan.merge_row_index):
			if row_index == primary_anchor.row_index or row_index == first_outer_row_index or row_index == last_outer_row_index:
				continue
			var branch_lane: int = path_solution.optional_path.get_lane_at_row(row_index)
			if RouteLaneScript.is_outer(branch_lane):
				extra_anchors.append(anchor_graph.get_anchor_for_row_and_lane(row_index, branch_lane))
		return extra_anchors

	# The first and last catch rows carry the recovery-lift and safe-relief hazards;
	# only interior catch rows are free for an extra coin.
	var last_catch_row_index: int = _find_last_row_with_role(plan, RouteRowRoleScript.Value.CATCH)
	for row_index in range(1, plan.get_row_count() - 1):
		if row_index == primary_anchor.row_index or row_index == last_catch_row_index:
			continue
		if plan.row_roles[row_index] == RouteRowRoleScript.Value.CATCH:
			extra_anchors.append(anchor_graph.get_anchor_for_row_and_lane(row_index, path_solution.safe_path.get_lane_at_row(row_index)))
	return extra_anchors

func _build_hazard_placements(
	plan: ChunkRoutePlanScript,
	anchor_graph: RouteAnchorGraphScript,
	path_solution: ChunkRoutePathSolutionScript,
	reward_placements: Array[RefCounted],
	selection_seed: String
) -> Array[RefCounted]:
	var hazard_placements: Array[RefCounted] = []
	var placed_hazard_anchor_ids: Dictionary[StringName, bool] = {}
	for hazard_intent in plan.hazard_intents:
		var anchor: RouteAnchorCandidateScript = _select_hazard_anchor(plan, anchor_graph, path_solution, reward_placements, hazard_intent)
		anchor = _nudge_hazard_anchor_clear_of_placed_hazards(plan, anchor_graph, path_solution, anchor, placed_hazard_anchor_ids)
		placed_hazard_anchor_ids[anchor.anchor_id] = true
		var hazard_selection_context: String = "%s:%d:%d:%d:%d:%s:hazard_kind" % [
			selection_seed,
			plan.chunk_index,
			plan.route_slot,
			plan.difficulty_band,
			hazard_intent,
			String(anchor.anchor_id),
		]
		var hazard_kind: int = _get_hazard_kind_for_intent(hazard_intent, hazard_selection_context)
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

## Two hazard intents can resolve to the same anchor (e.g. a RISK chunk's branch
## denial and reward-greed pressure both land on the last outer branch row). Move
## the second one one or two rows off along a path it can stay on, so hazards never
## stack (audit B4). Prefer the optional path -- keeping a branch-side hazard on the
## branch side -- then fall back to the safe path; both hold a placed hold on every
## row they cover, which the ChunkRoutePopulation contract requires.
func _nudge_hazard_anchor_clear_of_placed_hazards(
	plan: ChunkRoutePlanScript,
	anchor_graph: RouteAnchorGraphScript,
	path_solution: ChunkRoutePathSolutionScript,
	preferred_anchor: RouteAnchorCandidateScript,
	placed_hazard_anchor_ids: Dictionary[StringName, bool]
) -> RouteAnchorCandidateScript:
	Validation.require_condition(preferred_anchor != null, "ChunkRoutePopulationBuilder hazard nudge requires an anchor.")
	if not placed_hazard_anchor_ids.has(preferred_anchor.anchor_id):
		return preferred_anchor

	if path_solution.optional_path != null:
		var branch_nudge: RouteAnchorCandidateScript = _nudge_along_path(
			anchor_graph, path_solution.optional_path, preferred_anchor, placed_hazard_anchor_ids,
			plan.split_row_index + 1, plan.merge_row_index - 1
		)
		if branch_nudge != null:
			return branch_nudge

	var safe_nudge: RouteAnchorCandidateScript = _nudge_along_path(
		anchor_graph, path_solution.safe_path, preferred_anchor, placed_hazard_anchor_ids,
		1, path_solution.safe_path.get_row_count() - 2
	)
	if safe_nudge != null:
		return safe_nudge

	return preferred_anchor

func _nudge_along_path(
	anchor_graph: RouteAnchorGraphScript,
	path: RoutePlannedPathScript,
	preferred_anchor: RouteAnchorCandidateScript,
	placed_hazard_anchor_ids: Dictionary[StringName, bool],
	minimum_row_index: int,
	maximum_row_index: int
) -> RouteAnchorCandidateScript:
	for row_offset in [1, -1, 2, -2]:
		var row_index: int = preferred_anchor.row_index + row_offset
		if row_index < minimum_row_index or row_index > maximum_row_index:
			continue
		var candidate: RouteAnchorCandidateScript = anchor_graph.get_anchor_for_row_and_lane(row_index, path.get_lane_at_row(row_index))
		if candidate != null and not placed_hazard_anchor_ids.has(candidate.anchor_id):
			return candidate
	return null

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
		GeneratedHazardIntentScript.Value.RECOVERY_LIFT:
			return _get_required_anchor_for_path_row(anchor_graph, path_solution.safe_path, _find_first_row_with_role(plan, RouteRowRoleScript.Value.CATCH))
		GeneratedHazardIntentScript.Value.SAFE_ROUTE_RELIEF:
			return _get_required_anchor_for_path_row(anchor_graph, path_solution.safe_path, _find_last_row_with_role(plan, RouteRowRoleScript.Value.CATCH))
		_:
			Validation.require_condition(false, "ChunkRoutePopulationBuilder requires a supported hazard intent.")
			return null

func _get_hazard_kind_for_intent(hazard_intent: int, selection_context: String) -> int:
	match hazard_intent:
		GeneratedHazardIntentScript.Value.OPTIONAL_BRANCH_DENIAL:
			return _select_hazard_kind([
				GeneratedHazardKindScript.Value.SPIKE_CLUSTER,
				GeneratedHazardKindScript.Value.FALLING_ROCK,
				GeneratedHazardKindScript.Value.PENDULUM_LOG,
			], selection_context)
		GeneratedHazardIntentScript.Value.CRUX_PRESSURE:
			return GeneratedHazardKindScript.Value.DOWNDRAFT
		GeneratedHazardIntentScript.Value.REWARD_GREED_PRESSURE:
			return GeneratedHazardKindScript.Value.BUG_SWARM
		GeneratedHazardIntentScript.Value.TRAVERSE_FORCE:
			return _select_hazard_kind([
				GeneratedHazardKindScript.Value.WIND_GUST,
				GeneratedHazardKindScript.Value.WANDERING_CRITTER,
			], selection_context)
		GeneratedHazardIntentScript.Value.RECOVERY_LIFT:
			return GeneratedHazardKindScript.Value.UPDRAFT
		GeneratedHazardIntentScript.Value.SAFE_ROUTE_RELIEF:
			return GeneratedHazardKindScript.Value.STARTLE_PUFF
		_:
			Validation.require_condition(false, "ChunkRoutePopulationBuilder requires a supported hazard intent kind.")
			return GeneratedHazardKindScript.Value.SPIKE_CLUSTER

func _select_hazard_kind(candidate_kinds: Array[int], selection_context: String) -> int:
	Validation.require_condition(not candidate_kinds.is_empty(), "ChunkRoutePopulationBuilder hazard kind selection requires candidates.")
	for candidate_kind in candidate_kinds:
		GeneratedHazardKindScript.assert_valid(candidate_kind)

	if selection_context == "" or candidate_kinds.size() == 1:
		return candidate_kinds[0]

	var weighted_kinds: Array[int] = []
	var candidate_count: int = candidate_kinds.size()
	for candidate_index in range(candidate_count):
		var candidate_kind: int = candidate_kinds[candidate_index]
		var weight: int = (candidate_count - candidate_index) * (candidate_count - candidate_index)
		for weight_index in range(weight):
			weighted_kinds.append(candidate_kind)

	var selected_index: int = DeterministicHash.of_string(selection_context) % weighted_kinds.size()
	return weighted_kinds[selected_index]

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

func _find_last_row_with_role(plan: ChunkRoutePlanScript, row_role: int) -> int:
	RouteRowRoleScript.assert_valid(row_role)
	for row_index in range(plan.row_roles.size() - 1, -1, -1):
		if plan.row_roles[row_index] == row_role:
			return row_index

	Validation.require_condition(false, "ChunkRoutePopulationBuilder could not find a required route row role.")
	return -1

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
