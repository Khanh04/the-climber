class_name ChunkRoutePlan
extends RefCounted

const ChunkDifficultyBandScript = preload("res://src/gameplay/generation/chunk_difficulty_band.gd")
const ChunkRouteSlotScript = preload("res://src/gameplay/generation/chunk_route_slot.gd")
const GeneratedHazardIntentScript = preload("res://src/gameplay/generation/generated_hazard_intent.gd")
const HandholdTypeScript = preload("res://src/gameplay/generation/handhold_type.gd")
const RouteBranchSideScript = preload("res://src/gameplay/generation/route_branch_side.gd")
const RouteMovementStyleScript = preload("res://src/gameplay/generation/route_movement_style.gd")
const RouteRowRoleScript = preload("res://src/gameplay/generation/route_row_role.gd")

var chunk_index: int
var route_slot: int
var difficulty_band: int
var movement_style: int
var row_roles: Array[int]
var optional_route_required: bool
var route_branch_side: int
var split_row_index: int
var merge_row_index: int
var minimum_branch_separation_rows: int
var minimum_outer_lane_rows: int
var target_difficulty_score: float
## Continuous altitude component already folded into target_difficulty_score, kept
## separately so population can tell "hard band" from "hard because high up".
var altitude_difficulty_bonus: float
var hazard_intents: Array[int]
var safe_path_allowed_handhold_types: Array[int]
var optional_path_allowed_handhold_types: Array[int]

func _init(
	chunk_index_value: int,
	route_slot_value: int,
	difficulty_band_value: int,
	movement_style_value: int,
	row_roles_value: Array[int],
	optional_route_required_value: bool,
	route_branch_side_value: int,
	split_row_index_value: int,
	merge_row_index_value: int,
	minimum_branch_separation_rows_value: int,
	minimum_outer_lane_rows_value: int,
	target_difficulty_score_value: float,
	altitude_difficulty_bonus_value: float,
	hazard_intents_value: Array[int],
	safe_path_allowed_handhold_types_value: Array[int],
	optional_path_allowed_handhold_types_value: Array[int]
) -> void:
	chunk_index = chunk_index_value
	route_slot = route_slot_value
	difficulty_band = difficulty_band_value
	movement_style = movement_style_value
	row_roles = _duplicate_int_array(row_roles_value)
	optional_route_required = optional_route_required_value
	route_branch_side = route_branch_side_value
	split_row_index = split_row_index_value
	merge_row_index = merge_row_index_value
	minimum_branch_separation_rows = minimum_branch_separation_rows_value
	minimum_outer_lane_rows = minimum_outer_lane_rows_value
	target_difficulty_score = target_difficulty_score_value
	altitude_difficulty_bonus = altitude_difficulty_bonus_value
	hazard_intents = _duplicate_int_array(hazard_intents_value)
	safe_path_allowed_handhold_types = _duplicate_int_array(safe_path_allowed_handhold_types_value)
	optional_path_allowed_handhold_types = _duplicate_int_array(optional_path_allowed_handhold_types_value)
	assert_valid()

func is_valid() -> bool:
	return chunk_index >= 0 \
		and ChunkRouteSlotScript.is_valid(route_slot) \
		and ChunkDifficultyBandScript.is_valid(difficulty_band) \
		and RouteMovementStyleScript.is_valid(movement_style) \
		and _row_roles_are_valid() \
		and _branch_contract_is_valid() \
		and target_difficulty_score >= 0.0 \
		and altitude_difficulty_bonus >= 0.0 \
		and _hazard_intents_are_valid() \
		and _handhold_types_are_valid(safe_path_allowed_handhold_types) \
		and _handhold_types_are_valid(optional_path_allowed_handhold_types)

func assert_valid() -> void:
	Validation.require_condition(chunk_index >= 0, "ChunkRoutePlan chunk index cannot be negative.")
	ChunkRouteSlotScript.assert_valid(route_slot)
	ChunkDifficultyBandScript.assert_valid(difficulty_band)
	RouteMovementStyleScript.assert_valid(movement_style)
	_assert_valid_row_roles()
	_assert_valid_branch_contract()
	Validation.require_condition(target_difficulty_score >= 0.0, "ChunkRoutePlan target difficulty score cannot be negative.")
	Validation.require_condition(altitude_difficulty_bonus >= 0.0, "ChunkRoutePlan altitude difficulty bonus cannot be negative.")
	_assert_valid_hazard_intents()
	_assert_valid_handhold_types(safe_path_allowed_handhold_types, "safe path")
	_assert_valid_handhold_types(optional_path_allowed_handhold_types, "optional path")

func get_row_count() -> int:
	return row_roles.size()

func count_row_role(row_role: int) -> int:
	RouteRowRoleScript.assert_valid(row_role)
	var row_count: int = 0
	for candidate_role in row_roles:
		if candidate_role == row_role:
			row_count += 1
	return row_count

func get_sparse_row_count() -> int:
	var row_count: int = 0
	for row_role in row_roles:
		if RouteRowRoleScript.is_sparse(row_role):
			row_count += 1
	return row_count

func has_hazard_intent(hazard_intent: int) -> bool:
	GeneratedHazardIntentScript.assert_valid(hazard_intent)
	return hazard_intents.has(hazard_intent)

func safe_path_allows_handhold_type(handhold_type: int) -> bool:
	HandholdTypeScript.assert_valid(handhold_type)
	return safe_path_allowed_handhold_types.has(handhold_type)

func optional_path_allows_handhold_type(handhold_type: int) -> bool:
	HandholdTypeScript.assert_valid(handhold_type)
	return optional_path_allowed_handhold_types.has(handhold_type)

func _row_roles_are_valid() -> bool:
	if row_roles.size() < 2:
		return false

	for row_role in row_roles:
		if not RouteRowRoleScript.is_valid(row_role):
			return false

	return true

func _assert_valid_row_roles() -> void:
	Validation.require_condition(row_roles.size() >= 2, "ChunkRoutePlan requires at least two row roles.")
	for row_role in row_roles:
		RouteRowRoleScript.assert_valid(row_role)

func _branch_contract_is_valid() -> bool:
	if not RouteBranchSideScript.is_valid(route_branch_side):
		return false

	if optional_route_required:
		return route_branch_side != RouteBranchSideScript.Value.NONE \
			and split_row_index >= 0 \
			and split_row_index < row_roles.size() \
			and merge_row_index > split_row_index \
			and merge_row_index < row_roles.size() \
			and minimum_branch_separation_rows > 0 \
			and minimum_branch_separation_rows <= merge_row_index - split_row_index - 1 \
			and minimum_outer_lane_rows > 0 \
			and minimum_outer_lane_rows <= minimum_branch_separation_rows

	return route_branch_side == RouteBranchSideScript.Value.NONE \
		and split_row_index == -1 \
		and merge_row_index == -1 \
		and minimum_branch_separation_rows == 0 \
		and minimum_outer_lane_rows == 0

func _assert_valid_branch_contract() -> void:
	RouteBranchSideScript.assert_valid(route_branch_side)
	if optional_route_required:
		Validation.require_condition(route_branch_side != RouteBranchSideScript.Value.NONE, "ChunkRoutePlan optional routes require a branch side.")
		Validation.require_condition(split_row_index >= 0, "ChunkRoutePlan optional routes require a split row.")
		Validation.require_condition(split_row_index < row_roles.size(), "ChunkRoutePlan split row must be inside the chunk.")
		Validation.require_condition(merge_row_index > split_row_index, "ChunkRoutePlan merge row must be after the split row.")
		Validation.require_condition(merge_row_index < row_roles.size(), "ChunkRoutePlan merge row must be inside the chunk.")
		Validation.require_condition(minimum_branch_separation_rows > 0, "ChunkRoutePlan optional routes require separated branch rows.")
		Validation.require_condition(
			minimum_branch_separation_rows <= merge_row_index - split_row_index - 1,
			"ChunkRoutePlan branch separation must fit between split and merge rows."
		)
		Validation.require_condition(minimum_outer_lane_rows > 0, "ChunkRoutePlan optional routes require outer-lane rows.")
		Validation.require_condition(
			minimum_outer_lane_rows <= minimum_branch_separation_rows,
			"ChunkRoutePlan outer-lane rows cannot exceed separated branch rows."
		)
		return

	Validation.require_condition(route_branch_side == RouteBranchSideScript.Value.NONE, "ChunkRoutePlan non-branch plans cannot keep a branch side.")
	Validation.require_condition(split_row_index == -1, "ChunkRoutePlan non-branch plans cannot keep a split row.")
	Validation.require_condition(merge_row_index == -1, "ChunkRoutePlan non-branch plans cannot keep a merge row.")
	Validation.require_condition(minimum_branch_separation_rows == 0, "ChunkRoutePlan non-branch plans cannot require branch separation.")
	Validation.require_condition(minimum_outer_lane_rows == 0, "ChunkRoutePlan non-branch plans cannot require outer-lane rows.")

func _hazard_intents_are_valid() -> bool:
	if hazard_intents.is_empty():
		return false

	for hazard_intent in hazard_intents:
		if not GeneratedHazardIntentScript.is_valid(hazard_intent):
			return false

	return true

func _assert_valid_hazard_intents() -> void:
	Validation.require_condition(not hazard_intents.is_empty(), "ChunkRoutePlan requires at least one hazard intent.")
	for hazard_intent in hazard_intents:
		GeneratedHazardIntentScript.assert_valid(hazard_intent)

func _handhold_types_are_valid(handhold_types: Array[int]) -> bool:
	if handhold_types.is_empty():
		return false

	for handhold_type in handhold_types:
		if not HandholdTypeScript.is_valid(handhold_type):
			return false

	return true

func _assert_valid_handhold_types(handhold_types: Array[int], route_label: String) -> void:
	Validation.require_condition(not handhold_types.is_empty(), "ChunkRoutePlan %s requires at least one allowed handhold type." % route_label)
	for handhold_type in handhold_types:
		HandholdTypeScript.assert_valid(handhold_type)

static func _duplicate_int_array(source: Array[int]) -> Array[int]:
	var duplicated_values: Array[int] = []
	for value in source:
		duplicated_values.append(value)
	return duplicated_values