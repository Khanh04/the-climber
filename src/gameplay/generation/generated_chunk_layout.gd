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
    hazard_sockets_value: Array[GeneratedHazardSocket]
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