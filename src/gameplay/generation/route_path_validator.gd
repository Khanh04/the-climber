class_name RoutePathValidator
extends RefCounted

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
    var target_index: int = _find_target_hold_index(handholds)
    var target_hold: RefCounted = handholds[target_index]
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
            _require_hold_id(target_hold),
            PackedStringArray()
        )

    while not frontier.is_empty():
        var current_index: int = frontier.pop_front()
        if current_index == target_index:
            return GeneratedRouteValidationResultScript.new(
                true,
                "",
                _require_hold_id(target_hold),
                _build_path_hold_ids(handholds, predecessors, target_index)
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
        "No path reaches the top-most generated handhold within the configured move envelope.",
        _require_hold_id(target_hold),
        PackedStringArray()
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

func _find_target_hold_index(handholds: Array[RefCounted]) -> int:
    Validation.require_condition(handholds.size() > 0, "RoutePathValidator requires at least one handhold.")

    var target_index: int = 0
    var target_position: Vector2 = _require_local_position(handholds[0])
    for handhold_index in range(1, handholds.size()):
        var candidate_position: Vector2 = _require_local_position(handholds[handhold_index])
        if candidate_position.y < target_position.y:
            target_index = handhold_index
            target_position = candidate_position

    return target_index

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
