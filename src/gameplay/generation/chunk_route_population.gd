class_name ChunkRoutePopulation
extends RefCounted

const RouteHazardPlacementScript: GDScript = preload("res://src/gameplay/generation/route_hazard_placement.gd")
const RoutePopulatedHoldScript: GDScript = preload("res://src/gameplay/generation/route_populated_hold.gd")
const RouteRewardPlacementScript: GDScript = preload("res://src/gameplay/generation/route_reward_placement.gd")
const RouteRoleScript = preload("res://src/gameplay/generation/route_role.gd")

var holds: Array[RefCounted]
var reward_placements: Array[RefCounted]
var hazard_placements: Array[RefCounted]
var safe_hold_ids: PackedStringArray
var optional_hold_ids: PackedStringArray
var support_hold_ids: PackedStringArray

func _init(
	holds_value: Array[RefCounted],
	reward_placements_value: Array[RefCounted],
	hazard_placements_value: Array[RefCounted],
	safe_hold_ids_value: PackedStringArray,
	optional_hold_ids_value: PackedStringArray,
	support_hold_ids_value: PackedStringArray
) -> void:
	holds = _duplicate_holds(holds_value)
	reward_placements = _duplicate_reward_placements(reward_placements_value)
	hazard_placements = _duplicate_hazard_placements(hazard_placements_value)
	safe_hold_ids = PackedStringArray(safe_hold_ids_value)
	optional_hold_ids = PackedStringArray(optional_hold_ids_value)
	support_hold_ids = PackedStringArray(support_hold_ids_value)
	assert_valid()

func assert_valid() -> void:
	Validation.require_condition(not holds.is_empty(), "ChunkRoutePopulation requires holds.")
	Validation.require_condition(safe_hold_ids.size() > 0, "ChunkRoutePopulation requires safe hold ids.")

	for hold in holds:
		Validation.require_condition(hold != null, "ChunkRoutePopulation holds cannot contain null entries.")
		var hold_uses_expected_script: bool = hold.get_script() == RoutePopulatedHoldScript
		Validation.require_condition(hold_uses_expected_script, "ChunkRoutePopulation holds must use RoutePopulatedHold instances.")
		hold.call("assert_valid")
		Validation.require_condition(_count_holds_with_id(_require_string_name_property(hold, &"hold_id")) == 1, "ChunkRoutePopulation hold ids must be unique.")

	for safe_hold_id in safe_hold_ids:
		Validation.require_condition(_has_hold_id(StringName(safe_hold_id)), "ChunkRoutePopulation safe hold ids must reference selected holds.")

	for optional_hold_id in optional_hold_ids:
		Validation.require_condition(_has_hold_id(StringName(optional_hold_id)), "ChunkRoutePopulation optional hold ids must reference selected holds.")

	for support_hold_id in support_hold_ids:
		Validation.require_condition(_has_hold_id(StringName(support_hold_id)), "ChunkRoutePopulation support hold ids must reference selected holds.")

	for reward_placement in reward_placements:
		Validation.require_condition(reward_placement != null, "ChunkRoutePopulation reward placements cannot contain null entries.")
		var reward_uses_expected_script: bool = reward_placement.get_script() == RouteRewardPlacementScript
		Validation.require_condition(reward_uses_expected_script, "ChunkRoutePopulation rewards must use RouteRewardPlacement instances.")
		reward_placement.call("assert_valid")
		Validation.require_condition(_has_anchor_id(_require_string_name_property(reward_placement, &"anchor_id")), "ChunkRoutePopulation rewards must anchor to selected holds.")

	for hazard_placement in hazard_placements:
		Validation.require_condition(hazard_placement != null, "ChunkRoutePopulation hazard placements cannot contain null entries.")
		var hazard_uses_expected_script: bool = hazard_placement.get_script() == RouteHazardPlacementScript
		Validation.require_condition(hazard_uses_expected_script, "ChunkRoutePopulation hazards must use RouteHazardPlacement instances.")
		hazard_placement.call("assert_valid")
		Validation.require_condition(_has_anchor_id(_require_string_name_property(hazard_placement, &"anchor_id")), "ChunkRoutePopulation hazards must anchor to selected holds.")

func get_hold_count() -> int:
	return holds.size()

func get_hold_for_anchor_id(anchor_id: StringName) -> RefCounted:
	Validation.require_condition(not String(anchor_id).is_empty(), "ChunkRoutePopulation anchor lookup requires an anchor id.")
	for hold in holds:
		if _require_string_name_property(hold, &"anchor_id") == anchor_id:
			return hold
	return null

func count_holds_with_route_role(route_role: int) -> int:
	RouteRoleScript.assert_valid(route_role)
	var hold_count: int = 0
	for hold in holds:
		if _require_int_property(hold, &"route_role") == route_role:
			hold_count += 1
	return hold_count

func count_safe_path_holds() -> int:
	var hold_count: int = 0
	for hold in holds:
		if _require_bool_property(hold, &"is_safe_path"):
			hold_count += 1
	return hold_count

func count_optional_path_holds() -> int:
	var hold_count: int = 0
	for hold in holds:
		if _require_bool_property(hold, &"is_optional_path"):
			hold_count += 1
	return hold_count

func count_support_holds() -> int:
	var hold_count: int = 0
	for hold in holds:
		if _require_bool_property(hold, &"is_support_hold"):
			hold_count += 1
	return hold_count

func count_holds_in_row(row_index: int) -> int:
	Validation.require_condition(row_index >= 0, "ChunkRoutePopulation row hold count cannot use a negative row.")
	var hold_count: int = 0
	for hold in holds:
		if _require_int_property(hold, &"row_index") == row_index:
			hold_count += 1
	return hold_count

func find_hazard_placement_for_intent(hazard_intent: int) -> RefCounted:
	for hazard_placement in hazard_placements:
		if _require_int_property(hazard_placement, &"hazard_intent") == hazard_intent:
			return hazard_placement
	return null

func _has_hold_id(hold_id: StringName) -> bool:
	return _count_holds_with_id(hold_id) == 1

func _has_anchor_id(anchor_id: StringName) -> bool:
	return get_hold_for_anchor_id(anchor_id) != null

func _count_holds_with_id(hold_id: StringName) -> int:
	var hold_count: int = 0
	for hold in holds:
		if _require_string_name_property(hold, &"hold_id") == hold_id:
			hold_count += 1
	return hold_count

func _require_string_name_property(source: RefCounted, property_name: StringName) -> StringName:
	var raw_value: Variant = source.get(property_name)
	Validation.require_condition(raw_value is StringName, "ChunkRoutePopulation expected a StringName property.")
	var typed_value: StringName = raw_value
	return typed_value

func _require_int_property(source: RefCounted, property_name: StringName) -> int:
	var raw_value: Variant = source.get(property_name)
	Validation.require_condition(raw_value is int, "ChunkRoutePopulation expected an int property.")
	var typed_value: int = raw_value
	return typed_value

func _require_bool_property(source: RefCounted, property_name: StringName) -> bool:
	var raw_value: Variant = source.get(property_name)
	Validation.require_condition(raw_value is bool, "ChunkRoutePopulation expected a bool property.")
	var typed_value: bool = raw_value
	return typed_value

static func _duplicate_holds(source: Array[RefCounted]) -> Array[RefCounted]:
	var duplicated_values: Array[RefCounted] = []
	for value in source:
		duplicated_values.append(value)
	return duplicated_values

static func _duplicate_reward_placements(source: Array[RefCounted]) -> Array[RefCounted]:
	var duplicated_values: Array[RefCounted] = []
	for value in source:
		duplicated_values.append(value)
	return duplicated_values

static func _duplicate_hazard_placements(source: Array[RefCounted]) -> Array[RefCounted]:
	var duplicated_values: Array[RefCounted] = []
	for value in source:
		duplicated_values.append(value)
	return duplicated_values