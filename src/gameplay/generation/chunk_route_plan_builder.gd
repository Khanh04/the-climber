class_name ChunkRoutePlanBuilder
extends RefCounted

const ChunkDifficultyBandScript = preload("res://src/gameplay/generation/chunk_difficulty_band.gd")
const ChunkRoutePlanScript = preload("res://src/gameplay/generation/chunk_route_plan.gd")
const ChunkRouteSlotScript = preload("res://src/gameplay/generation/chunk_route_slot.gd")
const GeneratedHazardIntentScript = preload("res://src/gameplay/generation/generated_hazard_intent.gd")
const HandholdTypeScript = preload("res://src/gameplay/generation/handhold_type.gd")
const RouteBranchSideScript = preload("res://src/gameplay/generation/route_branch_side.gd")
const RouteMovementStyleScript = preload("res://src/gameplay/generation/route_movement_style.gd")
const RouteRowRoleScript = preload("res://src/gameplay/generation/route_row_role.gd")

func build_plan(seed_key: String, chunk_index: int, route_slot: int, difficulty_band: int) -> ChunkRoutePlanScript:
	Validation.require_condition(seed_key != "", "ChunkRoutePlanBuilder requires a seed key.")
	Validation.require_condition(chunk_index >= 0, "ChunkRoutePlanBuilder chunk index cannot be negative.")
	ChunkRouteSlotScript.assert_valid(route_slot)
	ChunkDifficultyBandScript.assert_valid(difficulty_band)

	var movement_style: int = _select_movement_style(seed_key, chunk_index, route_slot, difficulty_band)
	var row_roles: Array[int] = _build_row_roles(route_slot, difficulty_band)
	var optional_route_required: bool = _route_slot_requires_optional_route(route_slot)
	var branch_side: int = RouteBranchSideScript.Value.NONE
	var split_row_index: int = -1
	var merge_row_index: int = -1
	var minimum_branch_separation_rows: int = 0
	var minimum_outer_lane_rows: int = 0

	if optional_route_required:
		branch_side = _select_branch_side(seed_key, chunk_index, route_slot)
		split_row_index = _get_split_row_index(difficulty_band)
		merge_row_index = _get_merge_row_index(row_roles, difficulty_band)
		minimum_branch_separation_rows = _get_minimum_branch_separation_rows(difficulty_band)
		minimum_outer_lane_rows = _get_minimum_outer_lane_rows(difficulty_band)

	return ChunkRoutePlanScript.new(
		chunk_index,
		route_slot,
		difficulty_band,
		movement_style,
		row_roles,
		optional_route_required,
		branch_side,
		split_row_index,
		merge_row_index,
		minimum_branch_separation_rows,
		minimum_outer_lane_rows,
		_get_max_sparse_row_streak(difficulty_band),
		_get_target_difficulty_score(route_slot, difficulty_band),
		_get_target_support_score(route_slot, difficulty_band),
		_build_hazard_intents(route_slot),
		_build_safe_path_allowed_handhold_types(difficulty_band),
		_build_optional_path_allowed_handhold_types(difficulty_band)
	)

func _select_movement_style(seed_key: String, chunk_index: int, route_slot: int, difficulty_band: int) -> int:
	ChunkRouteSlotScript.assert_valid(route_slot)
	ChunkDifficultyBandScript.assert_valid(difficulty_band)

	match route_slot:
		ChunkRouteSlotScript.Value.OPENER:
			return RouteMovementStyleScript.Value.LADDER
		ChunkRouteSlotScript.Value.RECOVERY:
			return RouteMovementStyleScript.Value.RECOVERY
		ChunkRouteSlotScript.Value.SKILL:
			if difficulty_band == ChunkDifficultyBandScript.Value.EASY:
				return RouteMovementStyleScript.Value.ZIGZAG
			return RouteMovementStyleScript.Value.TRAVERSE_BRANCH
		ChunkRouteSlotScript.Value.RISK:
			return RouteMovementStyleScript.Value.RISK_LANE
		ChunkRouteSlotScript.Value.PRESSURE:
			return RouteMovementStyleScript.Value.PRESSURE
		ChunkRouteSlotScript.Value.BASELINE:
			if (_hash_int("%s:movement:%d" % [seed_key, chunk_index]) % 2) == 0:
				return RouteMovementStyleScript.Value.LADDER
			return RouteMovementStyleScript.Value.ZIGZAG
		_:
			Validation.require_condition(false, "ChunkRoutePlanBuilder requires a supported route slot.")
			return RouteMovementStyleScript.Value.LADDER

func _build_row_roles(route_slot: int, difficulty_band: int) -> Array[int]:
	ChunkRouteSlotScript.assert_valid(route_slot)
	ChunkDifficultyBandScript.assert_valid(difficulty_band)

	if route_slot == ChunkRouteSlotScript.Value.OPENER:
		return _opener_row_roles()

	if route_slot == ChunkRouteSlotScript.Value.RECOVERY:
		return _recovery_row_roles()

	if _route_slot_requires_optional_route(route_slot):
		return _branch_row_roles(difficulty_band)

	return _baseline_row_roles(difficulty_band)

func _opener_row_roles() -> Array[int]:
	return [
		RouteRowRoleScript.Value.SUPPORT,
		RouteRowRoleScript.Value.SUPPORT,
		RouteRowRoleScript.Value.SUPPORT,
		RouteRowRoleScript.Value.DECISION,
		RouteRowRoleScript.Value.SUPPORT,
		RouteRowRoleScript.Value.CATCH,
		RouteRowRoleScript.Value.SUPPORT,
		RouteRowRoleScript.Value.DECISION,
		RouteRowRoleScript.Value.SUPPORT,
		RouteRowRoleScript.Value.CATCH,
		RouteRowRoleScript.Value.TOP_OUT,
	]

func _recovery_row_roles() -> Array[int]:
	return [
		RouteRowRoleScript.Value.SUPPORT,
		RouteRowRoleScript.Value.SUPPORT,
		RouteRowRoleScript.Value.CATCH,
		RouteRowRoleScript.Value.SUPPORT,
		RouteRowRoleScript.Value.DECISION,
		RouteRowRoleScript.Value.CATCH,
		RouteRowRoleScript.Value.SUPPORT,
		RouteRowRoleScript.Value.CATCH,
		RouteRowRoleScript.Value.SUPPORT,
		RouteRowRoleScript.Value.CATCH,
		RouteRowRoleScript.Value.TOP_OUT,
	]

func _baseline_row_roles(difficulty_band: int) -> Array[int]:
	match difficulty_band:
		ChunkDifficultyBandScript.Value.EASY:
			return [
				RouteRowRoleScript.Value.SUPPORT,
				RouteRowRoleScript.Value.SUPPORT,
				RouteRowRoleScript.Value.DECISION,
				RouteRowRoleScript.Value.SUPPORT,
				RouteRowRoleScript.Value.CRUX,
				RouteRowRoleScript.Value.CATCH,
				RouteRowRoleScript.Value.SUPPORT,
				RouteRowRoleScript.Value.CRUX,
				RouteRowRoleScript.Value.CATCH,
				RouteRowRoleScript.Value.SUPPORT,
				RouteRowRoleScript.Value.TOP_OUT,
			]
		ChunkDifficultyBandScript.Value.BASELINE:
			return [
				RouteRowRoleScript.Value.SUPPORT,
				RouteRowRoleScript.Value.DECISION,
				RouteRowRoleScript.Value.TRAVERSE,
				RouteRowRoleScript.Value.SUPPORT,
				RouteRowRoleScript.Value.CRUX,
				RouteRowRoleScript.Value.CATCH,
				RouteRowRoleScript.Value.TRAVERSE,
				RouteRowRoleScript.Value.CRUX,
				RouteRowRoleScript.Value.CATCH,
				RouteRowRoleScript.Value.SUPPORT,
				RouteRowRoleScript.Value.TOP_OUT,
			]
		ChunkDifficultyBandScript.Value.CHALLENGE:
			return [
				RouteRowRoleScript.Value.SUPPORT,
				RouteRowRoleScript.Value.DECISION,
				RouteRowRoleScript.Value.TRAVERSE,
				RouteRowRoleScript.Value.CRUX,
				RouteRowRoleScript.Value.PRESSURE,
				RouteRowRoleScript.Value.CATCH,
				RouteRowRoleScript.Value.TRAVERSE,
				RouteRowRoleScript.Value.CRUX,
				RouteRowRoleScript.Value.PRESSURE,
				RouteRowRoleScript.Value.CATCH,
				RouteRowRoleScript.Value.TOP_OUT,
			]
		_:
			Validation.require_condition(false, "ChunkRoutePlanBuilder baseline rows require a supported difficulty band.")
			return []

func _branch_row_roles(difficulty_band: int) -> Array[int]:
	match difficulty_band:
		ChunkDifficultyBandScript.Value.EASY:
			return [
				RouteRowRoleScript.Value.SUPPORT,
				RouteRowRoleScript.Value.SUPPORT,
				RouteRowRoleScript.Value.DECISION,
				RouteRowRoleScript.Value.TRAVERSE,
				RouteRowRoleScript.Value.SUPPORT,
				RouteRowRoleScript.Value.CRUX,
				RouteRowRoleScript.Value.TRAVERSE,
				RouteRowRoleScript.Value.CATCH,
				RouteRowRoleScript.Value.SUPPORT,
				RouteRowRoleScript.Value.CATCH,
				RouteRowRoleScript.Value.TOP_OUT,
			]
		ChunkDifficultyBandScript.Value.BASELINE:
			return [
				RouteRowRoleScript.Value.SUPPORT,
				RouteRowRoleScript.Value.DECISION,
				RouteRowRoleScript.Value.TRAVERSE,
				RouteRowRoleScript.Value.SUPPORT,
				RouteRowRoleScript.Value.CRUX,
				RouteRowRoleScript.Value.TRAVERSE,
				RouteRowRoleScript.Value.CATCH,
				RouteRowRoleScript.Value.TRAVERSE,
				RouteRowRoleScript.Value.CRUX,
				RouteRowRoleScript.Value.CATCH,
				RouteRowRoleScript.Value.TOP_OUT,
			]
		ChunkDifficultyBandScript.Value.CHALLENGE:
			return [
				RouteRowRoleScript.Value.SUPPORT,
				RouteRowRoleScript.Value.DECISION,
				RouteRowRoleScript.Value.TRAVERSE,
				RouteRowRoleScript.Value.CRUX,
				RouteRowRoleScript.Value.PRESSURE,
				RouteRowRoleScript.Value.TRAVERSE,
				RouteRowRoleScript.Value.CATCH,
				RouteRowRoleScript.Value.TRAVERSE,
				RouteRowRoleScript.Value.CRUX,
				RouteRowRoleScript.Value.CATCH,
				RouteRowRoleScript.Value.TOP_OUT,
			]
		_:
			Validation.require_condition(false, "ChunkRoutePlanBuilder branch rows require a supported difficulty band.")
			return []

func _route_slot_requires_optional_route(route_slot: int) -> bool:
	match route_slot:
		ChunkRouteSlotScript.Value.SKILL:
			return true
		ChunkRouteSlotScript.Value.RISK:
			return true
		ChunkRouteSlotScript.Value.PRESSURE:
			return true
		_:
			ChunkRouteSlotScript.assert_valid(route_slot)
			return false

func _select_branch_side(seed_key: String, chunk_index: int, route_slot: int) -> int:
	var side_seed_hash: int = _hash_int("%s:route_plan:%d:%d:branch_side" % [seed_key, chunk_index, route_slot])
	if (side_seed_hash % 2) == 0:
		return RouteBranchSideScript.Value.LEFT
	return RouteBranchSideScript.Value.RIGHT

func _get_split_row_index(difficulty_band: int) -> int:
	ChunkDifficultyBandScript.assert_valid(difficulty_band)
	if difficulty_band == ChunkDifficultyBandScript.Value.EASY:
		return 2
	return 1

func _get_merge_row_index(row_roles: Array[int], difficulty_band: int) -> int:
	Validation.require_condition(row_roles.size() >= 2, "ChunkRoutePlanBuilder merge rows require route rows.")
	ChunkDifficultyBandScript.assert_valid(difficulty_band)
	return row_roles.size() - 2

func _get_minimum_branch_separation_rows(difficulty_band: int) -> int:
	match difficulty_band:
		ChunkDifficultyBandScript.Value.EASY:
			return 2
		ChunkDifficultyBandScript.Value.BASELINE:
			return 3
		ChunkDifficultyBandScript.Value.CHALLENGE:
			return 4
		_:
			Validation.require_condition(false, "ChunkRoutePlanBuilder branch separation requires a supported difficulty band.")
			return 0

func _get_minimum_outer_lane_rows(difficulty_band: int) -> int:
	match difficulty_band:
		ChunkDifficultyBandScript.Value.EASY:
			return 1
		ChunkDifficultyBandScript.Value.BASELINE:
			return 2
		ChunkDifficultyBandScript.Value.CHALLENGE:
			return 3
		_:
			Validation.require_condition(false, "ChunkRoutePlanBuilder outer lane rows require a supported difficulty band.")
			return 0

func _get_max_sparse_row_streak(difficulty_band: int) -> int:
	match difficulty_band:
		ChunkDifficultyBandScript.Value.EASY:
			return 1
		ChunkDifficultyBandScript.Value.BASELINE:
			return 2
		ChunkDifficultyBandScript.Value.CHALLENGE:
			return 3
		_:
			Validation.require_condition(false, "ChunkRoutePlanBuilder sparse row limits require a supported difficulty band.")
			return 0

func _get_target_difficulty_score(route_slot: int, difficulty_band: int) -> float:
	var score: float = 0.25
	match difficulty_band:
		ChunkDifficultyBandScript.Value.EASY:
			score = 0.25
		ChunkDifficultyBandScript.Value.BASELINE:
			score = 0.55
		ChunkDifficultyBandScript.Value.CHALLENGE:
			score = 0.85
		_:
			Validation.require_condition(false, "ChunkRoutePlanBuilder difficulty score requires a supported difficulty band.")

	if route_slot == ChunkRouteSlotScript.Value.RECOVERY:
		score -= 0.15
	elif route_slot == ChunkRouteSlotScript.Value.RISK:
		score += 0.1
	elif route_slot == ChunkRouteSlotScript.Value.PRESSURE:
		score += 0.18

	return clampf(score, 0.0, 1.0)

func _get_target_support_score(route_slot: int, difficulty_band: int) -> float:
	var score: float = 0.85
	match difficulty_band:
		ChunkDifficultyBandScript.Value.EASY:
			score = 0.85
		ChunkDifficultyBandScript.Value.BASELINE:
			score = 0.65
		ChunkDifficultyBandScript.Value.CHALLENGE:
			score = 0.45
		_:
			Validation.require_condition(false, "ChunkRoutePlanBuilder support score requires a supported difficulty band.")

	if route_slot == ChunkRouteSlotScript.Value.RECOVERY:
		score += 0.15
	elif route_slot == ChunkRouteSlotScript.Value.PRESSURE:
		score -= 0.1

	return clampf(score, 0.0, 1.0)

func _build_hazard_intents(route_slot: int) -> Array[int]:
	match route_slot:
		ChunkRouteSlotScript.Value.OPENER:
			return [GeneratedHazardIntentScript.Value.RECOVERY_LIFT]
		ChunkRouteSlotScript.Value.RECOVERY:
			return [GeneratedHazardIntentScript.Value.RECOVERY_LIFT, GeneratedHazardIntentScript.Value.SAFE_ROUTE_RELIEF]
		ChunkRouteSlotScript.Value.SKILL:
			return [GeneratedHazardIntentScript.Value.TRAVERSE_FORCE, GeneratedHazardIntentScript.Value.CRUX_PRESSURE]
		ChunkRouteSlotScript.Value.RISK:
			return [GeneratedHazardIntentScript.Value.OPTIONAL_BRANCH_DENIAL, GeneratedHazardIntentScript.Value.REWARD_GREED_PRESSURE]
		ChunkRouteSlotScript.Value.PRESSURE:
			return [GeneratedHazardIntentScript.Value.CRUX_PRESSURE, GeneratedHazardIntentScript.Value.OPTIONAL_BRANCH_DENIAL]
		ChunkRouteSlotScript.Value.BASELINE:
			return [GeneratedHazardIntentScript.Value.SAFE_ROUTE_RELIEF, GeneratedHazardIntentScript.Value.TRAVERSE_FORCE]
		_:
			Validation.require_condition(false, "ChunkRoutePlanBuilder hazard intents require a supported route slot.")
			return []

func _build_safe_path_allowed_handhold_types(difficulty_band: int) -> Array[int]:
	match difficulty_band:
		ChunkDifficultyBandScript.Value.EASY:
			return [HandholdTypeScript.Value.NORMAL, HandholdTypeScript.Value.REST]
		ChunkDifficultyBandScript.Value.BASELINE:
			return [HandholdTypeScript.Value.NORMAL, HandholdTypeScript.Value.REST, HandholdTypeScript.Value.BURN]
		ChunkDifficultyBandScript.Value.CHALLENGE:
			return [
				HandholdTypeScript.Value.NORMAL,
				HandholdTypeScript.Value.REST,
				HandholdTypeScript.Value.BURN,
				HandholdTypeScript.Value.BREAK,
				HandholdTypeScript.Value.BOOST,
			]
		_:
			Validation.require_condition(false, "ChunkRoutePlanBuilder safe hold types require a supported difficulty band.")
			return []

func _build_optional_path_allowed_handhold_types(difficulty_band: int) -> Array[int]:
	match difficulty_band:
		ChunkDifficultyBandScript.Value.EASY:
			return [HandholdTypeScript.Value.NORMAL, HandholdTypeScript.Value.REST, HandholdTypeScript.Value.BURN]
		ChunkDifficultyBandScript.Value.BASELINE:
			return [HandholdTypeScript.Value.NORMAL, HandholdTypeScript.Value.BURN, HandholdTypeScript.Value.BOOST, HandholdTypeScript.Value.ROCKET]
		ChunkDifficultyBandScript.Value.CHALLENGE:
			return [
				HandholdTypeScript.Value.NORMAL,
				HandholdTypeScript.Value.BURN,
				HandholdTypeScript.Value.BREAK,
				HandholdTypeScript.Value.BOOST,
				HandholdTypeScript.Value.GHOST,
				HandholdTypeScript.Value.ROCKET,
			]
		_:
			Validation.require_condition(false, "ChunkRoutePlanBuilder optional hold types require a supported difficulty band.")
			return []

func _hash_int(seed_text: String) -> int:
	var seed_hash: int = seed_text.hash()
	if seed_hash < 0:
		seed_hash = -seed_hash
	return seed_hash