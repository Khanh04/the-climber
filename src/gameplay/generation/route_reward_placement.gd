class_name RouteRewardPlacement
extends RefCounted

const RouteLaneScript = preload("res://src/gameplay/generation/route_lane.gd")

var placement_id: StringName
var anchor_id: StringName
var row_index: int
var lane: int
var local_position: Vector2

func _init(
	placement_id_value: StringName,
	anchor_id_value: StringName,
	row_index_value: int,
	lane_value: int,
	local_position_value: Vector2
) -> void:
	placement_id = placement_id_value
	anchor_id = anchor_id_value
	row_index = row_index_value
	lane = lane_value
	local_position = local_position_value
	assert_valid()

func assert_valid() -> void:
	Validation.require_condition(not String(placement_id).is_empty(), "RouteRewardPlacement requires a placement id.")
	Validation.require_condition(not String(anchor_id).is_empty(), "RouteRewardPlacement requires an anchor id.")
	Validation.require_condition(row_index >= 0, "RouteRewardPlacement row index cannot be negative.")
	RouteLaneScript.assert_valid(lane)