class_name ChaserTuning
extends Resource

@export var sample_window_seconds: float = 5.0
@export var camping_progress_meters: float = 2.0
@export var rapid_progress_meters: float = 8.0
@export var min_rise_speed_meters_per_second: float = 1.5
@export var max_rise_speed_meters_per_second: float = 5.0

func is_valid() -> bool:
    return sample_window_seconds > 0.0 \
        and camping_progress_meters >= 0.0 \
        and rapid_progress_meters > camping_progress_meters \
        and min_rise_speed_meters_per_second > 0.0 \
        and max_rise_speed_meters_per_second >= min_rise_speed_meters_per_second

func validate() -> void:
    assert_valid()

func assert_valid() -> void:
    Validation.require_condition(sample_window_seconds > 0.0, "Chaser sample window must be positive.")
    Validation.require_condition(camping_progress_meters >= 0.0, "Chaser camping threshold cannot be negative.")
    Validation.require_condition(rapid_progress_meters > camping_progress_meters, "Chaser rapid-climb threshold must exceed the camping threshold.")
    Validation.require_condition(min_rise_speed_meters_per_second > 0.0, "Chaser minimum rise speed must be positive.")
    Validation.require_condition(max_rise_speed_meters_per_second >= min_rise_speed_meters_per_second, "Chaser maximum rise speed must be at least the minimum rise speed.")