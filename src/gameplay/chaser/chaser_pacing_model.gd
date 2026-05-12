class_name ChaserPacingModel
extends RefCounted

const ChaserTuningScript = preload("res://resources/config/chaser_tuning.gd")

enum PaceState {
    CAMPING,
    NEUTRAL,
    RAPID_CLIMB
}

class ProgressSample:
    extends RefCounted

    var elapsed_seconds: float
    var height_meters: float

    func _init(elapsed_seconds_value: float, height_meters_value: float) -> void:
        elapsed_seconds = elapsed_seconds_value
        height_meters = height_meters_value

var _tuning: ChaserTuningScript
var _elapsed_seconds: float = 0.0
var _samples: Array[ProgressSample] = []

func _init(tuning: Resource) -> void:
    _tuning = _require_tuning(tuning)
    reset()

static func classify_progress(vertical_progress_meters: float, tuning: Resource) -> int:
    var typed_tuning: ChaserTuningScript = _require_tuning(tuning)

    if vertical_progress_meters < typed_tuning.camping_progress_meters:
        return PaceState.CAMPING

    if vertical_progress_meters > typed_tuning.rapid_progress_meters:
        return PaceState.RAPID_CLIMB

    return PaceState.NEUTRAL

static func calculate_rise_speed_meters_per_second(vertical_progress_meters: float, tuning: Resource) -> float:
    var typed_tuning: ChaserTuningScript = _require_tuning(tuning)
    var rise_speed_meters_per_second: float = typed_tuning.base_rise_speed_meters_per_second

    match classify_progress(vertical_progress_meters, typed_tuning):
        PaceState.CAMPING:
            rise_speed_meters_per_second += typed_tuning.camping_speed_bonus_meters_per_second
        PaceState.RAPID_CLIMB:
            rise_speed_meters_per_second -= typed_tuning.rapid_climb_slowdown_meters_per_second
        _:
            pass

    return clampf(
        rise_speed_meters_per_second,
        typed_tuning.min_rise_speed_meters_per_second,
        typed_tuning.max_rise_speed_meters_per_second
    )

func reset(starting_height_meters: float = 0.0) -> void:
    Validation.require_condition(starting_height_meters >= 0.0, "ChaserPacingModel starting height cannot be negative.")
    _elapsed_seconds = 0.0
    _samples.clear()
    _append_sample(starting_height_meters)

func record_height(height_meters: float, delta_seconds: float) -> void:
    Validation.require_condition(height_meters >= 0.0, "ChaserPacingModel height cannot be negative.")
    Validation.require_condition(delta_seconds >= 0.0, "ChaserPacingModel delta cannot be negative.")

    _elapsed_seconds += delta_seconds
    _append_sample(height_meters)
    _prune_samples_outside_window()

func get_recent_vertical_progress_meters() -> float:
    Validation.require_condition(_samples.size() > 0, "ChaserPacingModel requires at least one progress sample.")
    return _samples[_samples.size() - 1].height_meters - _samples[0].height_meters

func get_current_pace_state() -> int:
    return classify_progress(get_recent_vertical_progress_meters(), _tuning)

func get_current_rise_speed_meters_per_second() -> float:
    return calculate_rise_speed_meters_per_second(get_recent_vertical_progress_meters(), _tuning)

static func _require_tuning(tuning: Resource) -> ChaserTuningScript:
    Validation.require_condition(tuning != null, "ChaserPacingModel requires chaser tuning.")
    Validation.require_condition(tuning is ChaserTuningScript, "ChaserPacingModel requires a ChaserTuning implementation.")

    var typed_tuning: ChaserTuningScript = tuning as ChaserTuningScript
    typed_tuning.assert_valid()
    return typed_tuning

func _append_sample(height_meters: float) -> void:
    _samples.append(ProgressSample.new(_elapsed_seconds, height_meters))

func _prune_samples_outside_window() -> void:
    var window_start_seconds: float = _elapsed_seconds - _tuning.sample_window_seconds

    while _samples.size() > 1 and _samples[0].elapsed_seconds < window_start_seconds:
        _samples.remove_at(0)