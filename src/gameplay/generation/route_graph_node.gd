class_name RouteGraphNode
extends RefCounted

const RouteRoleScript = preload("res://src/gameplay/generation/route_role.gd")

var hold_id: StringName
var local_position: Vector2
var physical_size_meters: Vector2
var route_role: int

func _init(
	hold_id_value: StringName,
	local_position_value: Vector2,
	physical_size_meters_value: Vector2,
	route_role_value: int
) -> void:
	hold_id = hold_id_value
	local_position = local_position_value
	physical_size_meters = physical_size_meters_value
	route_role = route_role_value
	assert_valid()

func assert_valid() -> void:
	Validation.require_condition(not String(hold_id).is_empty(), "RouteGraphNode requires a hold id.")
	Validation.require_condition(
		physical_size_meters.x > 0.0 and physical_size_meters.y > 0.0,
		"RouteGraphNode physical size must be positive."
	)
	RouteRoleScript.assert_valid(route_role)