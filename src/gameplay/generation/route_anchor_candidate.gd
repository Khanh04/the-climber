class_name RouteAnchorCandidate
extends RefCounted

const RouteLaneScript = preload("res://src/gameplay/generation/route_lane.gd")
const RouteRowRoleScript = preload("res://src/gameplay/generation/route_row_role.gd")

var anchor_id: StringName
var row_index: int
var lane: int
var local_position: Vector2
var row_role: int

func _init(
	anchor_id_value: StringName,
	row_index_value: int,
	lane_value: int,
	local_position_value: Vector2,
	row_role_value: int
) -> void:
	anchor_id = anchor_id_value
	row_index = row_index_value
	lane = lane_value
	local_position = local_position_value
	row_role = row_role_value
	assert_valid()

func assert_valid() -> void:
	Validation.require_condition(not String(anchor_id).is_empty(), "RouteAnchorCandidate requires an anchor id.")
	Validation.require_condition(row_index >= 0, "RouteAnchorCandidate row index cannot be negative.")
	RouteLaneScript.assert_valid(lane)
	RouteRowRoleScript.assert_valid(row_role)
