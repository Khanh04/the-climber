class_name ChaserPacingModel
extends RefCounted

enum PaceState {
    CAMPING,
    NEUTRAL,
    RAPID_CLIMB
}

const SAMPLE_WINDOW_SECONDS: float = 5.0
const CAMPING_PROGRESS_METERS: float = 2.0
const RAPID_PROGRESS_METERS: float = 8.0

static func classify_progress(vertical_progress_meters: float, sample_window_seconds: float) -> PaceState:
    Validation.require_condition(sample_window_seconds > 0.0, "Chaser sample window must be positive.")

    var time_scale: float = sample_window_seconds / SAMPLE_WINDOW_SECONDS
    var camping_threshold: float = CAMPING_PROGRESS_METERS * time_scale
    var rapid_threshold: float = RAPID_PROGRESS_METERS * time_scale

    if vertical_progress_meters < camping_threshold:
        return PaceState.CAMPING

    if vertical_progress_meters > rapid_threshold:
        return PaceState.RAPID_CLIMB

    return PaceState.NEUTRAL