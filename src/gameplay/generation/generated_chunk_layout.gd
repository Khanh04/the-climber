class_name GeneratedChunkLayout
extends RefCounted

var seed_key: String
var generator_version: String
var chunk_index: int
var chunk_type: int
var route_slot: int
var difficulty_band: int
var start_height_meters: float
var handholds: Array[GeneratedHandholdSocket]
var pickup_sockets: Array[GeneratedPickupSocket]
var hazard_sockets: Array[GeneratedHazardSocket]
var route_entry_hold_ids: PackedStringArray
var route_exit_hold_ids: PackedStringArray
var safe_path_hold_ids: PackedStringArray
var route_validation_result: RefCounted
var selected_candidate_attempt_index: int
var candidate_score: float

func _init(
    seed_key_value: String,
    generator_version_value: String,
    chunk_index_value: int,
    chunk_type_value: int,
    route_slot_value: int,
    difficulty_band_value: int,
    start_height_meters_value: float,
    handholds_value: Array[GeneratedHandholdSocket],
    pickup_sockets_value: Array[GeneratedPickupSocket],
    hazard_sockets_value: Array[GeneratedHazardSocket],
    route_entry_hold_ids_value: PackedStringArray,
    route_exit_hold_ids_value: PackedStringArray,
    route_validation_result_value: RefCounted = null,
    selected_candidate_attempt_index_value: int = 0,
    candidate_score_value: float = 0.0,
    safe_path_hold_ids_value: PackedStringArray = PackedStringArray()
) -> void:
    seed_key = seed_key_value
    generator_version = generator_version_value
    chunk_index = chunk_index_value
    chunk_type = chunk_type_value
    route_slot = route_slot_value
    difficulty_band = difficulty_band_value
    start_height_meters = start_height_meters_value
    handholds = handholds_value
    pickup_sockets = pickup_sockets_value
    hazard_sockets = hazard_sockets_value
    route_entry_hold_ids = route_entry_hold_ids_value
    route_exit_hold_ids = route_exit_hold_ids_value
    safe_path_hold_ids = PackedStringArray(safe_path_hold_ids_value)
    if safe_path_hold_ids.is_empty():
        for handhold in handholds:
            var _append_safe_hold_id_result: bool = safe_path_hold_ids.append(String(handhold.hold_id))
    route_validation_result = route_validation_result_value
    selected_candidate_attempt_index = selected_candidate_attempt_index_value
    candidate_score = candidate_score_value
    assert_valid()

func assert_valid() -> void:
    Validation.require_condition(seed_key != "", "GeneratedChunkLayout requires a seed key.")
    Validation.require_condition(generator_version != "", "GeneratedChunkLayout requires a generator version.")
    Validation.require_condition(chunk_index >= 0, "GeneratedChunkLayout chunk index cannot be negative.")
    ChunkType.assert_valid(chunk_type)
    ChunkRouteSlot.assert_valid(route_slot)
    ChunkDifficultyBand.assert_valid(difficulty_band)
    Validation.require_condition(start_height_meters >= 0.0, "GeneratedChunkLayout start height cannot be negative.")
    Validation.require_condition(handholds.size() > 0, "GeneratedChunkLayout requires at least one handhold.")

    for handhold in handholds:
        Validation.require_condition(handhold != null, "GeneratedChunkLayout handholds cannot contain null entries.")
        handhold.assert_valid()

    for pickup_socket in pickup_sockets:
        Validation.require_condition(pickup_socket != null, "GeneratedChunkLayout pickup sockets cannot contain null entries.")
        pickup_socket.assert_valid()

    for hazard_socket in hazard_sockets:
        Validation.require_condition(hazard_socket != null, "GeneratedChunkLayout hazard sockets cannot contain null entries.")
        hazard_socket.assert_valid()

    Validation.require_condition(route_entry_hold_ids.size() > 0, "GeneratedChunkLayout requires at least one route entry hold id.")
    Validation.require_condition(route_exit_hold_ids.size() > 0, "GeneratedChunkLayout requires at least one route exit hold id.")
    Validation.require_condition(safe_path_hold_ids.size() > 0, "GeneratedChunkLayout requires safe-path hold ids.")
    Validation.require_condition(selected_candidate_attempt_index >= 0, "GeneratedChunkLayout candidate attempt index cannot be negative.")
    Validation.require_condition(not is_nan(candidate_score), "GeneratedChunkLayout candidate score cannot be NaN.")

    for hold_id in route_entry_hold_ids:
        Validation.require_condition(hold_id != "", "GeneratedChunkLayout route entry hold ids cannot contain empty values.")

    for hold_id in route_exit_hold_ids:
        Validation.require_condition(hold_id != "", "GeneratedChunkLayout route exit hold ids cannot contain empty values.")

    for hold_id in safe_path_hold_ids:
        Validation.require_condition(hold_id != "", "GeneratedChunkLayout safe-path hold ids cannot contain empty values.")
        Validation.require_condition(_count_handholds_with_id(hold_id) == 1, "GeneratedChunkLayout safe-path hold ids must reference exactly one handhold.")

    for hold_id in route_entry_hold_ids:
        Validation.require_condition(safe_path_hold_ids.has(hold_id), "GeneratedChunkLayout route entries must belong to the safe path.")

    for hold_id in route_exit_hold_ids:
        Validation.require_condition(safe_path_hold_ids.has(hold_id), "GeneratedChunkLayout route exits must belong to the safe path.")

    if route_validation_result != null:
        Validation.require_condition(
            route_validation_result.has_method("assert_valid"),
            "GeneratedChunkLayout route validation result must expose assert_valid()."
        )
        route_validation_result.call("assert_valid")

func _count_handholds_with_id(hold_id: String) -> int:
    var count: int = 0
    for handhold in handholds:
        if String(handhold.hold_id) == hold_id:
            count += 1
    return count
