class_name RouteGraphEdge
extends RefCounted

const RouteMoveKindScript = preload("res://src/gameplay/generation/route_move_kind.gd")

var from_node_index: int
var to_node_index: int
var move_kind: int
var gap_distance_meters: float
var downward_gap_meters: float

func _init(
	from_node_index_value: int,
	to_node_index_value: int,
	move_kind_value: int,
	gap_distance_meters_value: float,
	downward_gap_meters_value: float
) -> void:
	from_node_index = from_node_index_value
	to_node_index = to_node_index_value
	move_kind = move_kind_value
	gap_distance_meters = gap_distance_meters_value
	downward_gap_meters = downward_gap_meters_value
	assert_valid()

func assert_valid() -> void:
	Validation.require_condition(from_node_index >= 0, "RouteGraphEdge source node index cannot be negative.")
	Validation.require_condition(to_node_index >= 0, "RouteGraphEdge target node index cannot be negative.")
	Validation.require_condition(from_node_index != to_node_index, "RouteGraphEdge cannot connect a node to itself.")
	RouteMoveKindScript.assert_valid(move_kind)
	Validation.require_condition(gap_distance_meters >= 0.0, "RouteGraphEdge gap distance cannot be negative.")
	Validation.require_condition(downward_gap_meters >= 0.0, "RouteGraphEdge downward gap cannot be negative.")