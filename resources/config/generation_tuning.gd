class_name GenerationTuning
extends Resource

@export var generator_version: String = DailySeedKey.GENERATOR_VERSION
@export var segment_height_meters: float = 24.0
@export var chunk_width_meters: float = 6.0
@export var starter_chunk_gap_meters: float = 2.0
@export var easy_band_max_height_meters: float = 50.0
@export var baseline_band_max_height_meters: float = 150.0
@export var chunk_spawn_ahead_count: int = 3
@export var chunk_keep_behind_count: int = 1
@export var socket_count_per_chunk: int = 12

func is_valid() -> bool:
    return generator_version != "" \
        and segment_height_meters > 0.0 \
        and chunk_width_meters > 0.0 \
        and starter_chunk_gap_meters > 0.0 \
        and easy_band_max_height_meters > 0.0 \
        and baseline_band_max_height_meters > easy_band_max_height_meters \
        and chunk_spawn_ahead_count >= 1 \
        and chunk_keep_behind_count >= 0 \
        and socket_count_per_chunk > 0

func validate() -> void:
    assert_valid()

func assert_valid() -> void:
    Validation.require_condition(generator_version != "", "Generation config requires a generator version.")
    Validation.require_condition(segment_height_meters > 0.0, "Generation segment height must be positive.")
    Validation.require_condition(chunk_width_meters > 0.0, "Generation chunk width must be positive.")
    Validation.require_condition(starter_chunk_gap_meters > 0.0, "Generation starter chunk gap must be positive.")
    Validation.require_condition(easy_band_max_height_meters > 0.0, "Generation easy-band max height must be positive.")
    Validation.require_condition(
        baseline_band_max_height_meters > easy_band_max_height_meters,
        "Generation baseline-band max height must be greater than the easy-band max height."
    )
    Validation.require_condition(chunk_spawn_ahead_count >= 1, "Generation config must keep at least one chunk ahead of the camera.")
    Validation.require_condition(chunk_keep_behind_count >= 0, "Generation config cannot keep a negative number of chunks behind the camera.")
    Validation.require_condition(socket_count_per_chunk > 0, "Generation config must provide at least one socket per chunk.")