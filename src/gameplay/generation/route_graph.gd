class_name RouteGraph
extends RefCounted

var nodes: Array[RefCounted]
var edges: Array[RefCounted]
var entry_port_hold_ids: PackedStringArray
var exit_port_hold_ids: PackedStringArray

func _init(
	nodes_value: Array[RefCounted],
	edges_value: Array[RefCounted],
	entry_port_hold_ids_value: PackedStringArray,
	exit_port_hold_ids_value: PackedStringArray
) -> void:
	nodes = nodes_value
	edges = edges_value
	entry_port_hold_ids = entry_port_hold_ids_value
	exit_port_hold_ids = exit_port_hold_ids_value
	assert_valid()

func assert_valid() -> void:
	Validation.require_condition(nodes.size() > 0, "RouteGraph requires at least one node.")
	Validation.require_condition(entry_port_hold_ids.size() > 0, "RouteGraph requires at least one entry port hold id.")
	Validation.require_condition(exit_port_hold_ids.size() > 0, "RouteGraph requires at least one exit port hold id.")

	for node in nodes:
		Validation.require_condition(node != null, "RouteGraph nodes cannot contain null entries.")
		Validation.require_condition(node.has_method("assert_valid"), "RouteGraph nodes must expose assert_valid().")
		node.call("assert_valid")

	for edge in edges:
		Validation.require_condition(edge != null, "RouteGraph edges cannot contain null entries.")
		Validation.require_condition(edge.has_method("assert_valid"), "RouteGraph edges must expose assert_valid().")
		edge.call("assert_valid")
		Validation.require_condition(_require_edge_from_node_index(edge) < nodes.size(), "RouteGraph edge source index is out of bounds.")
		Validation.require_condition(_require_edge_to_node_index(edge) < nodes.size(), "RouteGraph edge target index is out of bounds.")

	for entry_hold_id in entry_port_hold_ids:
		Validation.require_condition(_has_node_with_hold_id(entry_hold_id), "RouteGraph entry ports must reference graph nodes.")

	for exit_hold_id in exit_port_hold_ids:
		Validation.require_condition(_has_node_with_hold_id(exit_hold_id), "RouteGraph exit ports must reference graph nodes.")

	for first_index in range(nodes.size()):
		for second_index in range(first_index + 1, nodes.size()):
			Validation.require_condition(
				_require_node_hold_id(nodes[first_index]) != _require_node_hold_id(nodes[second_index]),
				"RouteGraph node hold ids must be unique."
			)

func get_required_node_index_by_hold_id(hold_id_text: String) -> int:
	Validation.require_condition(hold_id_text != "", "RouteGraph node lookup requires a non-empty hold id.")
	for node_index in range(nodes.size()):
		if String(_require_node_hold_id(nodes[node_index])) == hold_id_text:
			return node_index

	Validation.require_condition(false, "RouteGraph could not find the requested hold id.")
	return -1

func get_required_node_by_hold_id(hold_id_text: String) -> RefCounted:
	return nodes[get_required_node_index_by_hold_id(hold_id_text)]

func get_outgoing_edges(from_node_index: int) -> Array[RefCounted]:
	Validation.require_condition(from_node_index >= 0 and from_node_index < nodes.size(), "RouteGraph outgoing edge lookup index is out of bounds.")
	var outgoing_edges: Array[RefCounted] = []
	for edge in edges:
		if _require_edge_from_node_index(edge) == from_node_index:
			outgoing_edges.append(edge)
	return outgoing_edges

func get_highest_exit_port_node() -> RefCounted:
	var selected_node: RefCounted = get_required_node_by_hold_id(exit_port_hold_ids[0])
	for exit_hold_id in exit_port_hold_ids:
		var candidate_node: RefCounted = get_required_node_by_hold_id(exit_hold_id)
		if _require_node_local_position(candidate_node).y < _require_node_local_position(selected_node).y:
			selected_node = candidate_node
	return selected_node

func _has_node_with_hold_id(hold_id_text: String) -> bool:
	for node in nodes:
		if String(_require_node_hold_id(node)) == hold_id_text:
			return true
	return false

func _require_edge_from_node_index(edge: RefCounted) -> int:
	var raw_from_node_index: Variant = edge.get("from_node_index")
	Validation.require_condition(raw_from_node_index is int, "RouteGraph edges must expose an int from_node_index.")
	var from_node_index: int = raw_from_node_index
	return from_node_index

func _require_edge_to_node_index(edge: RefCounted) -> int:
	var raw_to_node_index: Variant = edge.get("to_node_index")
	Validation.require_condition(raw_to_node_index is int, "RouteGraph edges must expose an int to_node_index.")
	var to_node_index: int = raw_to_node_index
	return to_node_index

func _require_node_hold_id(node: RefCounted) -> StringName:
	var raw_hold_id: Variant = node.get("hold_id")
	Validation.require_condition(raw_hold_id is StringName, "RouteGraph nodes must expose a StringName hold_id.")
	var hold_id: StringName = raw_hold_id
	return hold_id

func _require_node_local_position(node: RefCounted) -> Vector2:
	var raw_local_position: Variant = node.get("local_position")
	Validation.require_condition(raw_local_position is Vector2, "RouteGraph nodes must expose a Vector2 local_position.")
	var local_position: Vector2 = raw_local_position
	return local_position