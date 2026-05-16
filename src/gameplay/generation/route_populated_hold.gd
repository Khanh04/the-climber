class_name RoutePopulatedHold
extends RefCounted

const HandholdTypeScript = preload("res://src/gameplay/generation/handhold_type.gd")
const RouteLaneScript = preload("res://src/gameplay/generation/route_lane.gd")
const RouteRoleScript = preload("res://src/gameplay/generation/route_role.gd")
const RouteRowRoleScript = preload("res://src/gameplay/generation/route_row_role.gd")

var hold_id: StringName
var anchor_id: StringName
var row_index: int
var lane: int
var local_position: Vector2
var row_role: int
var route_role: int
var handhold_type: int
var is_safe_path: bool
var is_optional_path: bool
var is_support_hold: bool

func _init(
	hold_id_value: StringName,
	anchor_id_value: StringName,
	row_index_value: int,
	lane_value: int,
	local_position_value: Vector2,
	row_role_value: int,
	route_role_value: int,
	handhold_type_value: int,
	is_safe_path_value: bool,
	is_optional_path_value: bool,
	is_support_hold_value: bool
) -> void:
	hold_id = hold_id_value
	anchor_id = anchor_id_value
	row_index = row_index_value
	lane = lane_value
	local_position = local_position_value
	row_role = row_role_value
	route_role = route_role_value
	handhold_type = handhold_type_value
	is_safe_path = is_safe_path_value
	is_optional_path = is_optional_path_value
	is_support_hold = is_support_hold_value
	assert_valid()

func assert_valid() -> void:
	Validation.require_condition(not String(hold_id).is_empty(), "RoutePopulatedHold requires a hold id.")
	Validation.require_condition(not String(anchor_id).is_empty(), "RoutePopulatedHold requires an anchor id.")
	Validation.require_condition(row_index >= 0, "RoutePopulatedHold row index cannot be negative.")
	RouteLaneScript.assert_valid(lane)
	RouteRowRoleScript.assert_valid(row_role)
	RouteRoleScript.assert_valid(route_role)
	HandholdTypeScript.assert_valid(handhold_type)
	Validation.require_condition(
		is_safe_path or is_optional_path or is_support_hold,
		"RoutePopulatedHold must belong to a safe path, optional path, or support set."
	)