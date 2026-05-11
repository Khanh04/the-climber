class_name GenerationTuning
extends Resource

@export var generator_version: String = DailySeedKey.GENERATOR_VERSION
@export var segment_height_meters: float = 24.0
@export var chunk_spawn_ahead_count: int = 3
@export var chunk_keep_behind_count: int = 1
@export var socket_count_per_chunk: int = 12

func is_valid() -> bool:
    return generator_version != "" \
        and segment_height_meters > 0.0 \
        and chunk_spawn_ahead_count >= 1 \
        and chunk_keep_behind_count >= 0 \
        and socket_count_per_chunk > 0

func validate() -> void:
    assert_valid()

func assert_valid() -> void:
    Validation.require_condition(generator_version != "", "Generation config requires a generator version.")
    Validation.require_condition(segment_height_meters > 0.0, "Generation segment height must be positive.")
    Validation.require_condition(chunk_spawn_ahead_count >= 1, "Generation config must keep at least one chunk ahead of the camera.")
    Validation.require_condition(chunk_keep_behind_count >= 0, "Generation config cannot keep a negative number of chunks behind the camera.")
    Validation.require_condition(socket_count_per_chunk > 0, "Generation config must provide at least one socket per chunk.")