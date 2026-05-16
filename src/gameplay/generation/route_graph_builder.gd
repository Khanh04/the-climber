class_name RouteGraphBuilder
extends RefCounted

const RouteGraphScript: GDScript = preload("res://src/gameplay/generation/route_graph.gd")
const RouteGraphEdgeScript: GDScript = preload("res://src/gameplay/generation/route_graph_edge.gd")
const RouteGraphNodeScript: GDScript = preload("res://src/gameplay/generation/route_graph_node.gd")
const RouteMoveKindScript = preload("res://src/gameplay/generation/route_move_kind.gd")
const RouteRoleScript = preload("res://src/gameplay/generation/route_role.gd")

var _max_move_distance_meters: float
var _max_downward_move_meters: float

func _init(
	max_move_distance_meters_value: float,
	max_downward_move_meters_value: float = 0.12
) -> void:
	Validation.require_condition(max_move_distance_meters_value > 0.0, "RouteGraphBuilder max move distance must be positive.")
	Validation.require_condition(max_downward_move_meters_value >= 0.0, "RouteGraphBuilder max downward move cannot be negative.")
	_max_move_distance_meters = max_move_distance_meters_value
	_max_downward_move_meters = max_downward_move_meters_value

func build_layout_graph(layout: RefCounted) -> RefCounted:
	Validation.require_condition(layout != null, "RouteGraphBuilder requires a layout.")
	Validation.require_condition(layout.has_method("assert_valid"), "RouteGraphBuilder layout must expose assert_valid().")
	layout.call("assert_valid")

	var nodes: Array[RefCounted] = _build_nodes(layout)
	var edges: Array[RefCounted] = _build_edges(nodes)
	var entry_port_hold_ids: PackedStringArray = _require_route_port_hold_ids(layout, &"route_entry_hold_ids")
	var exit_port_hold_ids: PackedStringArray = _require_route_port_hold_ids(layout, &"route_exit_hold_ids")
	var route_graph_variant: Variant = RouteGraphScript.new(nodes, edges, entry_port_hold_ids, exit_port_hold_ids)
	Validation.require_condition(route_graph_variant is RefCounted, "RouteGraphBuilder must create RefCounted route graph instances.")
	var route_graph: RefCounted = route_graph_variant
	return route_graph

func _build_nodes(layout: RefCounted) -> Array[RefCounted]:
	var raw_handholds: Variant = layout.get("handholds")
	Validation.require_condition(raw_handholds is Array, "RouteGraphBuilder layout handholds must be an Array.")
	var handhold_variants: Array = raw_handholds
	Validation.require_condition(handhold_variants.size() > 0, "RouteGraphBuilder requires at least one handhold.")

	var nodes: Array[RefCounted] = []
	for raw_handhold in handhold_variants:
		Validation.require_condition(raw_handhold is RefCounted, "RouteGraphBuilder handholds must be RefCounted instances.")
		var handhold: RefCounted = raw_handhold
		Validation.require_condition(handhold.has_method("assert_valid"), "RouteGraphBuilder handholds must expose assert_valid().")
		handhold.call("assert_valid")
		var node_variant: Variant = RouteGraphNodeScript.new(
			_require_hold_id(handhold),
			_require_local_position(handhold),
			_require_physical_size(handhold),
			_require_route_role(handhold)
		)
		Validation.require_condition(node_variant is RefCounted, "RouteGraphBuilder must create RefCounted route graph nodes.")
		var node: RefCounted = node_variant
		nodes.append(node)

	return nodes

func _build_edges(nodes: Array[RefCounted]) -> Array[RefCounted]:
	Validation.require_condition(nodes.size() > 0, "RouteGraphBuilder edge creation requires nodes.")
	var edges: Array[RefCounted] = []
	for from_index in range(nodes.size()):
		for to_index in range(nodes.size()):
			if from_index == to_index:
				continue

			var from_node: RefCounted = nodes[from_index]
			var to_node: RefCounted = nodes[to_index]
			var gap_distance_meters: float = _measure_gap_distance(
				_require_graph_node_local_position(from_node),
				_require_graph_node_physical_size(from_node),
				_require_graph_node_local_position(to_node),
				_require_graph_node_physical_size(to_node)
			)
			if gap_distance_meters > _max_move_distance_meters:
				continue

			var downward_gap_meters: float = _measure_downward_gap(
				_require_graph_node_local_position(from_node),
				_require_graph_node_physical_size(from_node),
				_require_graph_node_local_position(to_node),
				_require_graph_node_physical_size(to_node)
			)
			if downward_gap_meters > _max_downward_move_meters:
				continue

			var edge_variant: Variant = RouteGraphEdgeScript.new(
				from_index,
				to_index,
				RouteMoveKindScript.Value.STATIC_REACH,
				gap_distance_meters,
				downward_gap_meters
			)
			Validation.require_condition(edge_variant is RefCounted, "RouteGraphBuilder must create RefCounted route graph edges.")
			var edge: RefCounted = edge_variant
			edges.append(edge)

	return edges

func _require_route_port_hold_ids(layout: RefCounted, property_name: StringName) -> PackedStringArray:
	var raw_hold_ids: Variant = layout.get(property_name)
	Validation.require_condition(raw_hold_ids is PackedStringArray, "RouteGraphBuilder layouts must expose PackedStringArray route ports.")
	var hold_ids: PackedStringArray = raw_hold_ids
	Validation.require_condition(hold_ids.size() > 0, "RouteGraphBuilder route ports cannot be empty.")
	return hold_ids

func _require_local_position(handhold: RefCounted) -> Vector2:
	var raw_local_position: Variant = handhold.get("local_position")
	Validation.require_condition(raw_local_position is Vector2, "RouteGraphBuilder handholds must expose a Vector2 local_position.")
	var local_position: Vector2 = raw_local_position
	return local_position

func _require_hold_id(handhold: RefCounted) -> StringName:
	var raw_hold_id: Variant = handhold.get("hold_id")
	Validation.require_condition(raw_hold_id is StringName, "RouteGraphBuilder handholds must expose a StringName hold_id.")
	var hold_id: StringName = raw_hold_id
	return hold_id

func _require_physical_size(handhold: RefCounted) -> Vector2:
	var raw_physical_size: Variant = handhold.get("physical_size_meters")
	Validation.require_condition(raw_physical_size is Vector2, "RouteGraphBuilder handholds must expose a Vector2 physical_size_meters.")
	var physical_size: Vector2 = raw_physical_size
	return physical_size

func _require_route_role(handhold: RefCounted) -> int:
	var raw_route_role: Variant = handhold.get("route_role")
	Validation.require_condition(raw_route_role is int, "RouteGraphBuilder handholds must expose an int route_role.")
	var route_role: int = raw_route_role
	RouteRoleScript.assert_valid(route_role)
	return route_role

func _require_graph_node_local_position(node: RefCounted) -> Vector2:
	var raw_local_position: Variant = node.get("local_position")
	Validation.require_condition(raw_local_position is Vector2, "RouteGraphBuilder nodes must expose a Vector2 local_position.")
	var local_position: Vector2 = raw_local_position
	return local_position

func _require_graph_node_physical_size(node: RefCounted) -> Vector2:
	var raw_physical_size: Variant = node.get("physical_size_meters")
	Validation.require_condition(raw_physical_size is Vector2, "RouteGraphBuilder nodes must expose a Vector2 physical_size_meters.")
	var physical_size: Vector2 = raw_physical_size
	return physical_size

func _measure_gap_distance(
	from_position: Vector2,
	from_size: Vector2,
	to_position: Vector2,
	to_size: Vector2
) -> float:
	var horizontal_gap: float = maxf(0.0, absf(to_position.x - from_position.x) - ((from_size.x + to_size.x) * 0.5))
	var vertical_gap: float = maxf(0.0, absf(to_position.y - from_position.y) - ((from_size.y + to_size.y) * 0.5))
	return Vector2(horizontal_gap, vertical_gap).length()

func _measure_downward_gap(
	from_position: Vector2,
	from_size: Vector2,
	to_position: Vector2,
	to_size: Vector2
) -> float:
	return maxf(0.0, (to_position.y - from_position.y) - ((from_size.y + to_size.y) * 0.5))