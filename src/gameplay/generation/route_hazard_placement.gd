class_name RouteHazardPlacement
extends RefCounted

const GeneratedHazardIntentScript = preload("res://src/gameplay/generation/generated_hazard_intent.gd")
const GeneratedHazardKindScript = preload("res://src/gameplay/generation/generated_hazard_kind.gd")
const RouteLaneScript = preload("res://src/gameplay/generation/route_lane.gd")

var placement_id: StringName
var anchor_id: StringName
var hazard_intent: int
var hazard_kind: int
var row_index: int
var lane: int
var local_position: Vector2

func _init(
	placement_id_value: StringName,
	anchor_id_value: StringName,
	hazard_intent_value: int,
	hazard_kind_value: int,
	row_index_value: int,
	lane_value: int,
	local_position_value: Vector2
) -> void:
	placement_id = placement_id_value
	anchor_id = anchor_id_value
	hazard_intent = hazard_intent_value
	hazard_kind = hazard_kind_value
	row_index = row_index_value
	lane = lane_value
	local_position = local_position_value
	assert_valid()

func assert_valid() -> void:
	Validation.require_condition(not String(placement_id).is_empty(), "RouteHazardPlacement requires a placement id.")
	Validation.require_condition(not String(anchor_id).is_empty(), "RouteHazardPlacement requires an anchor id.")
	GeneratedHazardIntentScript.assert_valid(hazard_intent)
	GeneratedHazardKindScript.assert_valid(hazard_kind)
	Validation.require_condition(row_index >= 0, "RouteHazardPlacement row index cannot be negative.")
	RouteLaneScript.assert_valid(lane)