class_name RoutePathValidator
extends RefCounted

const GeneratedChunkSeamValidationResultScript: GDScript = preload("res://src/gameplay/generation/generated_chunk_seam_validation_result.gd")
const GeneratedRouteValidationResultScript: GDScript = preload("res://src/gameplay/generation/generated_route_validation_result.gd")
const RouteGraphBuilderScript: GDScript = preload("res://src/gameplay/generation/route_graph_builder.gd")

var _max_move_distance_meters: float
var _max_downward_move_meters: float
var _route_graph_builder: RefCounted

func _init(
    max_move_distance_meters_value: float,
    max_downward_move_meters_value: float = 0.12
) -> void:
    Validation.require_condition(
        max_move_distance_meters_value > 0.0,
        "RoutePathValidator max move distance must be positive."
    )
    Validation.require_condition(
        max_downward_move_meters_value >= 0.0,
        "RoutePathValidator max downward move cannot be negative."
    )
    _max_move_distance_meters = max_move_distance_meters_value
    _max_downward_move_meters = max_downward_move_meters_value
    var route_graph_builder_variant: Variant = RouteGraphBuilderScript.new(
        max_move_distance_meters_value,
        max_downward_move_meters_value
    )
    Validation.require_condition(route_graph_builder_variant is RefCounted, "RoutePathValidator must create a RefCounted route graph builder.")
    _route_graph_builder = route_graph_builder_variant

func validate_layout(
    layout: RefCounted,
    entry_anchor_positions: Array[Vector2]
) -> RefCounted:
    Validation.require_condition(layout != null, "RoutePathValidator requires a layout.")
    Validation.require_condition(layout.has_method("assert_valid"), "RoutePathValidator layout must expose assert_valid().")
    layout.call("assert_valid")
    Validation.require_condition(
        entry_anchor_positions.size() > 0,
        "RoutePathValidator requires at least one entry anchor position."
    )

    Validation.require_condition(_route_graph_builder != null, "RoutePathValidator requires a route graph builder.")
    var route_graph_variant: Variant = _route_graph_builder.call("build_layout_graph", layout)
    Validation.require_condition(route_graph_variant is RefCounted, "RoutePathValidator layout graph builder must return a RefCounted route graph.")
    var route_graph: RefCounted = route_graph_variant
    var graph_nodes: Array = _require_graph_nodes(route_graph)
    var preferred_exit_node: RefCounted = _require_graph_node(route_graph.call("get_highest_exit_port_node"))
    var exit_port_hold_ids: PackedStringArray = _require_graph_route_port_hold_ids(route_graph, &"exit_port_hold_ids")
    var predecessors: PackedInt32Array = PackedInt32Array()
    var visited: Array[bool] = []
    var frontier: Array[int] = []

    for _index in range(graph_nodes.size()):
        var _append_predecessor_result: bool = predecessors.append(-1)
        visited.append(false)

    for node_index in range(graph_nodes.size()):
        var node: RefCounted = _require_graph_node(graph_nodes[node_index])
        if _is_reachable_from_any_anchor(node, entry_anchor_positions):
            visited[node_index] = true
            frontier.append(node_index)

    if frontier.is_empty():
        return GeneratedRouteValidationResultScript.new(
            false,
            "No handhold is reachable from the provided entry anchors.",
            _require_graph_node_hold_id(preferred_exit_node),
            PackedStringArray()
        )

    while not frontier.is_empty():
        var current_index: int = frontier.pop_front()
        var current_node: RefCounted = _require_graph_node(graph_nodes[current_index])
        if exit_port_hold_ids.has(String(_require_graph_node_hold_id(current_node))):
            return GeneratedRouteValidationResultScript.new(
                true,
                "",
                _require_graph_node_hold_id(current_node),
                _build_path_hold_ids(route_graph, predecessors, current_index)
            )

        for edge_variant in _require_graph_outgoing_edges(route_graph, current_index):
            var edge: RefCounted = _require_graph_edge(edge_variant)
            var next_index: int = _require_graph_edge_to_node_index(edge)
            if visited[next_index]:
                continue

            visited[next_index] = true
            predecessors[next_index] = current_index
            frontier.append(next_index)

    return GeneratedRouteValidationResultScript.new(
        false,
        "No path reaches a generated route exit hold within the configured move envelope.",
        _require_graph_node_hold_id(preferred_exit_node),
        PackedStringArray()
    )

func validate_chunk_seam(current_layout: RefCounted, next_layout: RefCounted) -> RefCounted:
    Validation.require_condition(current_layout != null, "RoutePathValidator current layout cannot be null.")
    Validation.require_condition(next_layout != null, "RoutePathValidator next layout cannot be null.")
    Validation.require_condition(current_layout.has_method("assert_valid"), "RoutePathValidator current layout must expose assert_valid().")
    Validation.require_condition(next_layout.has_method("assert_valid"), "RoutePathValidator next layout must expose assert_valid().")
    current_layout.call("assert_valid")
    next_layout.call("assert_valid")

    var current_chunk_index: int = _require_chunk_index(current_layout, &"chunk_index")
    var next_chunk_index: int = _require_chunk_index(next_layout, &"chunk_index")
    Validation.require_condition(
        next_chunk_index == current_chunk_index + 1,
        "RoutePathValidator seam validation requires adjacent chunk indices."
    )

    Validation.require_condition(_route_graph_builder != null, "RoutePathValidator requires a route graph builder.")
    var current_route_graph_variant: Variant = _route_graph_builder.call("build_layout_graph", current_layout)
    var next_route_graph_variant: Variant = _route_graph_builder.call("build_layout_graph", next_layout)
    Validation.require_condition(current_route_graph_variant is RefCounted, "RoutePathValidator current layout graph builder must return a RefCounted route graph.")
    Validation.require_condition(next_route_graph_variant is RefCounted, "RoutePathValidator next layout graph builder must return a RefCounted route graph.")
    var current_route_graph: RefCounted = current_route_graph_variant
    var next_route_graph: RefCounted = next_route_graph_variant
    var current_exit_hold_ids: PackedStringArray = _require_graph_route_port_hold_ids(current_route_graph, &"exit_port_hold_ids")
    var next_entry_hold_ids: PackedStringArray = _require_graph_route_port_hold_ids(next_route_graph, &"entry_port_hold_ids")
    var current_start_height_meters: float = _require_start_height_meters(current_layout)
    var next_start_height_meters: float = _require_start_height_meters(next_layout)
    var exit_node: RefCounted = _get_required_graph_node_by_hold_id(current_route_graph, current_exit_hold_ids[0])
    var closest_entry_node: RefCounted = _get_required_graph_node_by_hold_id(next_route_graph, next_entry_hold_ids[0])
    var closest_gap_distance: float = INF

    for current_exit_hold_id in current_exit_hold_ids:
        var current_exit_node: RefCounted = _get_required_graph_node_by_hold_id(current_route_graph, current_exit_hold_id)
        var exit_world_position: Vector2 = _to_world_position(current_start_height_meters, _require_graph_node_local_position(current_exit_node))
        for next_entry_hold_id in next_entry_hold_ids:
            var entry_node: RefCounted = _get_required_graph_node_by_hold_id(next_route_graph, next_entry_hold_id)
            var entry_world_position: Vector2 = _to_world_position(next_start_height_meters, _require_graph_node_local_position(entry_node))
            var gap_distance: float = _measure_gap_distance(
                exit_world_position,
                _require_graph_node_physical_size(current_exit_node),
                entry_world_position,
                _require_graph_node_physical_size(entry_node)
            )
            if gap_distance < closest_gap_distance:
                closest_gap_distance = gap_distance
                exit_node = current_exit_node
                closest_entry_node = entry_node

            if gap_distance <= _max_move_distance_meters:
                return GeneratedChunkSeamValidationResultScript.new(
                    true,
                    "",
                    current_chunk_index,
                    next_chunk_index,
                    _require_graph_node_hold_id(current_exit_node),
                    _require_graph_node_hold_id(entry_node)
                )

    return GeneratedChunkSeamValidationResultScript.new(
        false,
        "No reachable seam connects the current chunk exit ports to the next chunk entry ports within the configured move envelope.",
        current_chunk_index,
        next_chunk_index,
        _require_graph_node_hold_id(exit_node),
        _require_graph_node_hold_id(closest_entry_node)
    )

func _is_reachable_from_any_anchor(node: RefCounted, entry_anchor_positions: Array[Vector2]) -> bool:
    for anchor_position in entry_anchor_positions:
        if _measure_gap_distance(anchor_position, Vector2.ZERO, _require_graph_node_local_position(node), _require_graph_node_physical_size(node)) <= _max_move_distance_meters:
            return true

    return false

func _build_path_hold_ids(
    route_graph: RefCounted,
    predecessors: PackedInt32Array,
    target_index: int
) -> PackedStringArray:
    var graph_nodes: Array = _require_graph_nodes(route_graph)
    var reversed_path: PackedStringArray = PackedStringArray()
    var current_index: int = target_index

    while current_index >= 0:
        var current_node: RefCounted = _require_graph_node(graph_nodes[current_index])
        var _append_reversed_path_result: bool = reversed_path.append(String(_require_graph_node_hold_id(current_node)))
        current_index = predecessors[current_index]

    var path_hold_ids: PackedStringArray = PackedStringArray()
    for path_index in range(reversed_path.size() - 1, -1, -1):
        var _append_path_result: bool = path_hold_ids.append(reversed_path[path_index])

    return path_hold_ids

func _get_required_graph_node_by_hold_id(route_graph: RefCounted, hold_id_text: String) -> RefCounted:
    var node_variant: Variant = route_graph.call("get_required_node_by_hold_id", hold_id_text)
    return _require_graph_node(node_variant)

func _require_graph_edge(edge_variant: Variant) -> RefCounted:
    Validation.require_condition(edge_variant is RefCounted, "RoutePathValidator graph edges must be RefCounted instances.")
    var edge: RefCounted = edge_variant
    return edge

func _require_graph_edge_to_node_index(edge: RefCounted) -> int:
    var raw_to_node_index: Variant = edge.get("to_node_index")
    Validation.require_condition(raw_to_node_index is int, "RoutePathValidator graph edges must expose an int to_node_index.")
    var to_node_index: int = raw_to_node_index
    return to_node_index

func _require_graph_node(node_variant: Variant) -> RefCounted:
    Validation.require_condition(node_variant is RefCounted, "RoutePathValidator graph nodes must be RefCounted instances.")
    var node: RefCounted = node_variant
    return node

func _require_graph_nodes(route_graph: RefCounted) -> Array:
    var raw_nodes: Variant = route_graph.get("nodes")
    Validation.require_condition(raw_nodes is Array, "RoutePathValidator route graph must expose an Array nodes property.")
    var graph_nodes: Array = raw_nodes
    return graph_nodes

func _require_graph_node_hold_id(node: RefCounted) -> StringName:
    var raw_hold_id: Variant = node.get("hold_id")
    Validation.require_condition(raw_hold_id is StringName, "RoutePathValidator graph nodes must expose a StringName hold_id.")
    var hold_id: StringName = raw_hold_id
    return hold_id

func _require_graph_node_local_position(node: RefCounted) -> Vector2:
    var raw_local_position: Variant = node.get("local_position")
    Validation.require_condition(raw_local_position is Vector2, "RoutePathValidator graph nodes must expose a Vector2 local_position.")
    var local_position: Vector2 = raw_local_position
    return local_position

func _require_graph_node_physical_size(node: RefCounted) -> Vector2:
    var raw_physical_size: Variant = node.get("physical_size_meters")
    Validation.require_condition(raw_physical_size is Vector2, "RoutePathValidator graph nodes must expose a Vector2 physical_size_meters.")
    var physical_size: Vector2 = raw_physical_size
    return physical_size

func _require_graph_outgoing_edges(route_graph: RefCounted, from_node_index: int) -> Array:
    var raw_outgoing_edges: Variant = route_graph.call("get_outgoing_edges", from_node_index)
    Validation.require_condition(raw_outgoing_edges is Array, "RoutePathValidator route graph must return outgoing edges as an Array.")
    var outgoing_edges: Array = raw_outgoing_edges
    return outgoing_edges

func _require_graph_route_port_hold_ids(route_graph: RefCounted, property_name: StringName) -> PackedStringArray:
    var raw_hold_ids: Variant = route_graph.get(property_name)
    Validation.require_condition(raw_hold_ids is PackedStringArray, "RoutePathValidator route graphs must expose PackedStringArray route ports.")
    var hold_ids: PackedStringArray = raw_hold_ids
    Validation.require_condition(hold_ids.size() > 0, "RoutePathValidator route graph ports cannot be empty.")
    return hold_ids

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

func _to_world_position(start_height_meters: float, local_position: Vector2) -> Vector2:
    return Vector2(local_position.x, local_position.y - start_height_meters)

func _require_start_height_meters(layout: RefCounted) -> float:
    var raw_start_height: Variant = layout.get("start_height_meters")
    Validation.require_condition(raw_start_height is float, "RoutePathValidator layouts must expose a float start_height_meters.")
    var start_height_meters: float = raw_start_height
    return start_height_meters

func _require_chunk_index(layout: RefCounted, property_name: StringName) -> int:
    var raw_chunk_index: Variant = layout.get(property_name)
    Validation.require_condition(raw_chunk_index is int, "RoutePathValidator layouts must expose an int chunk_index.")
    var chunk_index: int = raw_chunk_index
    return chunk_index

func _require_route_port_hold_ids(layout: RefCounted, property_name: StringName) -> PackedStringArray:
    var raw_hold_ids: Variant = layout.get(property_name)
    Validation.require_condition(raw_hold_ids is PackedStringArray, "RoutePathValidator layouts must expose PackedStringArray route ports.")
    var hold_ids: PackedStringArray = raw_hold_ids
    Validation.require_condition(hold_ids.size() > 0, "RoutePathValidator route ports cannot be empty.")
    return hold_ids
