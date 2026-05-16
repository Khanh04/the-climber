class_name RoutePathValidator
extends RefCounted

const GeneratedChunkSeamValidationResultScript: GDScript = preload("res://src/gameplay/generation/generated_chunk_seam_validation_result.gd")
const GeneratedRouteValidationResultScript: GDScript = preload("res://src/gameplay/generation/generated_route_validation_result.gd")

var _max_move_distance_meters: float
var _max_downward_move_meters: float

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

    var handholds: Array[RefCounted] = _require_handholds(layout)
    var exit_port_hold_ids: PackedStringArray = _require_route_port_hold_ids(layout, &"route_exit_hold_ids")
    var preferred_exit_hold: RefCounted = _find_highest_route_port_handhold(handholds, exit_port_hold_ids)
    var predecessors: PackedInt32Array = PackedInt32Array()
    var visited: Array[bool] = []
    var frontier: Array[int] = []

    for _index in range(handholds.size()):
        var _append_predecessor_result: bool = predecessors.append(-1)
        visited.append(false)

    for handhold_index in range(handholds.size()):
        var handhold: RefCounted = handholds[handhold_index]
        if _is_reachable_from_any_anchor(handhold, entry_anchor_positions):
            visited[handhold_index] = true
            frontier.append(handhold_index)

    if frontier.is_empty():
        return GeneratedRouteValidationResultScript.new(
            false,
            "No handhold is reachable from the provided entry anchors.",
            _require_hold_id(preferred_exit_hold),
            PackedStringArray()
        )

    while not frontier.is_empty():
        var current_index: int = frontier.pop_front()
        var current_hold_id: StringName = _require_hold_id(handholds[current_index])
        if exit_port_hold_ids.has(String(current_hold_id)):
            return GeneratedRouteValidationResultScript.new(
                true,
                "",
                current_hold_id,
                _build_path_hold_ids(handholds, predecessors, current_index)
            )

        var current_handhold: RefCounted = handholds[current_index]
        for next_index in range(handholds.size()):
            if visited[next_index]:
                continue

            var next_handhold: RefCounted = handholds[next_index]
            if not _can_move_between(current_handhold, next_handhold):
                continue

            visited[next_index] = true
            predecessors[next_index] = current_index
            frontier.append(next_index)

    return GeneratedRouteValidationResultScript.new(
        false,
        "No path reaches a generated route exit hold within the configured move envelope.",
        _require_hold_id(preferred_exit_hold),
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

    var current_handholds: Array[RefCounted] = _require_handholds(current_layout)
    var next_handholds: Array[RefCounted] = _require_handholds(next_layout)
    var current_exit_hold_ids: PackedStringArray = _require_route_port_hold_ids(current_layout, &"route_exit_hold_ids")
    var next_entry_hold_ids: PackedStringArray = _require_route_port_hold_ids(next_layout, &"route_entry_hold_ids")
    var current_start_height_meters: float = _require_start_height_meters(current_layout)
    var next_start_height_meters: float = _require_start_height_meters(next_layout)
    var exit_hold: RefCounted = _find_handhold_by_hold_id(current_handholds, current_exit_hold_ids[0])
    var closest_entry_hold: RefCounted = _find_handhold_by_hold_id(next_handholds, next_entry_hold_ids[0])
    var closest_gap_distance: float = INF

    for current_exit_hold_id in current_exit_hold_ids:
        var current_exit_hold: RefCounted = _find_handhold_by_hold_id(current_handholds, current_exit_hold_id)
        var exit_world_position: Vector2 = _to_world_position(current_start_height_meters, _require_local_position(current_exit_hold))
        for next_entry_hold_id in next_entry_hold_ids:
            var entry_hold: RefCounted = _find_handhold_by_hold_id(next_handholds, next_entry_hold_id)
            var entry_world_position: Vector2 = _to_world_position(next_start_height_meters, _require_local_position(entry_hold))
            var gap_distance: float = _measure_gap_distance(
                exit_world_position,
                _require_physical_size(current_exit_hold),
                entry_world_position,
                _require_physical_size(entry_hold)
            )
            if gap_distance < closest_gap_distance:
                closest_gap_distance = gap_distance
                exit_hold = current_exit_hold
                closest_entry_hold = entry_hold

            if gap_distance <= _max_move_distance_meters:
                return GeneratedChunkSeamValidationResultScript.new(
                    true,
                    "",
                    current_chunk_index,
                    next_chunk_index,
                    _require_hold_id(current_exit_hold),
                    _require_hold_id(entry_hold)
                )

    return GeneratedChunkSeamValidationResultScript.new(
        false,
        "No reachable seam connects the current chunk exit ports to the next chunk entry ports within the configured move envelope.",
        current_chunk_index,
        next_chunk_index,
        _require_hold_id(exit_hold),
        _require_hold_id(closest_entry_hold)
    )

func _require_handholds(layout: RefCounted) -> Array[RefCounted]:
    var raw_handholds: Variant = layout.get("handholds")
    Validation.require_condition(raw_handholds is Array, "RoutePathValidator layout handholds must be an Array.")
    var handhold_variants: Array = raw_handholds
    Validation.require_condition(handhold_variants.size() > 0, "RoutePathValidator requires at least one handhold.")

    var handholds: Array[RefCounted] = []
    for raw_handhold in handhold_variants:
        Validation.require_condition(raw_handhold is RefCounted, "RoutePathValidator handholds must be RefCounted instances.")
        var handhold: RefCounted = raw_handhold
        Validation.require_condition(handhold.has_method("assert_valid"), "RoutePathValidator handholds must expose assert_valid().")
        handhold.call("assert_valid")
        handholds.append(handhold)

    return handholds

func _find_handhold_by_hold_id(handholds: Array[RefCounted], hold_id_text: String) -> RefCounted:
    Validation.require_condition(hold_id_text != "", "RoutePathValidator hold lookup requires a non-empty hold id.")
    for handhold in handholds:
        if String(_require_hold_id(handhold)) == hold_id_text:
            return handhold

    Validation.require_condition(false, "RoutePathValidator could not find the requested hold id in the layout.")
    return null

func _find_highest_route_port_handhold(handholds: Array[RefCounted], route_port_hold_ids: PackedStringArray) -> RefCounted:
    Validation.require_condition(route_port_hold_ids.size() > 0, "RoutePathValidator requires at least one route port hold id.")

    var selected_handhold: RefCounted = _find_handhold_by_hold_id(handholds, route_port_hold_ids[0])
    var selected_position: Vector2 = _require_local_position(selected_handhold)

    for route_port_hold_id in route_port_hold_ids:
        var candidate_handhold: RefCounted = _find_handhold_by_hold_id(handholds, route_port_hold_id)
        var candidate_position: Vector2 = _require_local_position(candidate_handhold)
        if candidate_position.y < selected_position.y:
            selected_handhold = candidate_handhold
            selected_position = candidate_position

    return selected_handhold

func _is_reachable_from_any_anchor(handhold: RefCounted, entry_anchor_positions: Array[Vector2]) -> bool:
    var handhold_position: Vector2 = _require_local_position(handhold)
    var handhold_size: Vector2 = _require_physical_size(handhold)
    for anchor_position in entry_anchor_positions:
        if _measure_gap_distance(anchor_position, Vector2.ZERO, handhold_position, handhold_size) <= _max_move_distance_meters:
            return true

    return false

func _can_move_between(from_handhold: RefCounted, to_handhold: RefCounted) -> bool:
    var from_position: Vector2 = _require_local_position(from_handhold)
    var to_position: Vector2 = _require_local_position(to_handhold)
    if from_position == to_position:
        return false

    if _measure_gap_distance(
        from_position,
        _require_physical_size(from_handhold),
        to_position,
        _require_physical_size(to_handhold)
    ) > _max_move_distance_meters:
        return false

    var downward_gap: float = _measure_downward_gap(
        from_position,
        _require_physical_size(from_handhold),
        to_position,
        _require_physical_size(to_handhold)
    )
    if downward_gap > _max_downward_move_meters:
        return false

    return true

func _build_path_hold_ids(
    handholds: Array[RefCounted],
    predecessors: PackedInt32Array,
    target_index: int
) -> PackedStringArray:
    var reversed_path: PackedStringArray = PackedStringArray()
    var current_index: int = target_index

    while current_index >= 0:
        var _append_reversed_path_result: bool = reversed_path.append(String(_require_hold_id(handholds[current_index])))
        current_index = predecessors[current_index]

    var path_hold_ids: PackedStringArray = PackedStringArray()
    for path_index in range(reversed_path.size() - 1, -1, -1):
        var _append_path_result: bool = path_hold_ids.append(reversed_path[path_index])

    return path_hold_ids

func _require_local_position(handhold: RefCounted) -> Vector2:
    var raw_local_position: Variant = handhold.get("local_position")
    Validation.require_condition(raw_local_position is Vector2, "RoutePathValidator handholds must expose a Vector2 local_position.")
    var local_position: Vector2 = raw_local_position
    return local_position

func _require_hold_id(handhold: RefCounted) -> StringName:
    var raw_hold_id: Variant = handhold.get("hold_id")
    Validation.require_condition(raw_hold_id is StringName, "RoutePathValidator handholds must expose a StringName hold_id.")
    var hold_id: StringName = raw_hold_id
    return hold_id

func _require_physical_size(handhold: RefCounted) -> Vector2:
    var raw_physical_size: Variant = handhold.get("physical_size_meters")
    Validation.require_condition(raw_physical_size is Vector2, "RoutePathValidator handholds must expose a Vector2 physical_size_meters.")
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
