class_name ChaserTuning
extends Resource

## Seconds of recent climbing used to judge whether the player is camping or racing.
@export var sample_window_seconds: float = 5.0
## Climbing less than this within the sample window counts as camping and speeds the chaser up.
@export var camping_progress_meters: float = 2.0
## Climbing more than this within the sample window counts as racing and slows the chaser down.
@export var rapid_progress_meters: float = 8.0
## Chaser rise speed when the player is neither camping nor racing.
@export var base_rise_speed_meters_per_second: float = 0.5
## Extra rise speed while camping. Fades out as the altitude gain takes over.
@export var camping_speed_bonus_meters_per_second: float = 0.5
## Rise speed removed while the player is racing ahead.
@export var rapid_climb_slowdown_meters_per_second: float = 1.0
## Rise speed added per 100 m climbed above the onset height, so the chaser becomes
## a real escalating threat instead of flatlining at 1.0 m/s.
@export var altitude_rise_speed_gain_per_100m: float = 0.35
## Height below which altitude does not scale the chaser (the tutorial/early zone).
@export var altitude_rise_speed_onset_meters: float = 50.0
## Final rise speed is clamped to at least this.
@export var min_rise_speed_meters_per_second: float = 0.5
## Final rise speed is clamped to at most this.
@export var max_rise_speed_meters_per_second: float = 5.0
## How far below the player the chaser starts each run.
@export var initial_spawn_offset_meters: float = 8.0
## At or beyond this distance from the player, chaser visuals and audio sit at their calmest.
@export var far_distance_for_min_intensity_meters: float = 12.0
## At or inside this distance from the player, chaser visuals and audio are at full intensity.
@export var near_distance_for_max_intensity_meters: float = 4.0
## Chaser fill opacity at minimum intensity (0-1).
@export var min_visual_alpha: float = 0.72
## Chaser fill opacity at maximum intensity (0-1).
@export var max_visual_alpha: float = 0.96
## Chaser loop volume at minimum intensity, in decibels.
@export var min_audio_volume_db: float = -20.0
## Chaser loop volume at maximum intensity, in decibels.
@export var max_audio_volume_db: float = -7.0
## Chaser loop pitch at minimum intensity (1.0 is unchanged).
@export var min_audio_pitch_scale: float = 0.98
## Chaser loop pitch at maximum intensity (1.0 is unchanged).
@export var max_audio_pitch_scale: float = 1.04

func is_valid() -> bool:
    return sample_window_seconds > 0.0 \
        and camping_progress_meters >= 0.0 \
        and rapid_progress_meters > camping_progress_meters \
        and base_rise_speed_meters_per_second >= min_rise_speed_meters_per_second \
        and base_rise_speed_meters_per_second <= max_rise_speed_meters_per_second \
        and camping_speed_bonus_meters_per_second >= 0.0 \
        and rapid_climb_slowdown_meters_per_second >= 0.0 \
        and altitude_rise_speed_gain_per_100m >= 0.0 \
        and altitude_rise_speed_onset_meters >= 0.0 \
        and min_rise_speed_meters_per_second > 0.0 \
        and max_rise_speed_meters_per_second >= min_rise_speed_meters_per_second \
        and initial_spawn_offset_meters > 0.0 \
        and far_distance_for_min_intensity_meters > near_distance_for_max_intensity_meters \
        and near_distance_for_max_intensity_meters >= 0.0 \
        and min_visual_alpha >= 0.0 \
        and min_visual_alpha <= 1.0 \
        and max_visual_alpha >= min_visual_alpha \
        and max_visual_alpha <= 1.0 \
        and max_audio_volume_db >= min_audio_volume_db \
        and min_audio_pitch_scale > 0.0 \
        and max_audio_pitch_scale >= min_audio_pitch_scale

func validate() -> void:
    assert_valid()

func assert_valid() -> void:
    Validation.require_condition(sample_window_seconds > 0.0, "Chaser sample window must be positive.")
    Validation.require_condition(camping_progress_meters >= 0.0, "Chaser camping threshold cannot be negative.")
    Validation.require_condition(rapid_progress_meters > camping_progress_meters, "Chaser rapid-climb threshold must exceed the camping threshold.")
    Validation.require_condition(min_rise_speed_meters_per_second > 0.0, "Chaser minimum rise speed must be positive.")
    Validation.require_condition(max_rise_speed_meters_per_second >= min_rise_speed_meters_per_second, "Chaser maximum rise speed must be at least the minimum rise speed.")
    Validation.require_condition(base_rise_speed_meters_per_second >= min_rise_speed_meters_per_second, "Chaser base rise speed must be at least the minimum rise speed.")
    Validation.require_condition(base_rise_speed_meters_per_second <= max_rise_speed_meters_per_second, "Chaser base rise speed must not exceed the maximum rise speed.")
    Validation.require_condition(camping_speed_bonus_meters_per_second >= 0.0, "Chaser camping speed bonus cannot be negative.")
    Validation.require_condition(rapid_climb_slowdown_meters_per_second >= 0.0, "Chaser rapid-climb slowdown cannot be negative.")
    Validation.require_condition(altitude_rise_speed_gain_per_100m >= 0.0, "Chaser altitude rise-speed gain cannot be negative.")
    Validation.require_condition(altitude_rise_speed_onset_meters >= 0.0, "Chaser altitude rise-speed onset cannot be negative.")
    Validation.require_condition(initial_spawn_offset_meters > 0.0, "Chaser initial spawn offset must be positive.")
    Validation.require_condition(far_distance_for_min_intensity_meters > near_distance_for_max_intensity_meters, "Chaser far intensity distance must exceed the near intensity distance.")
    Validation.require_condition(near_distance_for_max_intensity_meters >= 0.0, "Chaser near intensity distance cannot be negative.")
    Validation.require_condition(min_visual_alpha >= 0.0 and min_visual_alpha <= 1.0, "Chaser minimum visual alpha must be between 0.0 and 1.0.")
    Validation.require_condition(max_visual_alpha >= min_visual_alpha and max_visual_alpha <= 1.0, "Chaser maximum visual alpha must be between the minimum visual alpha and 1.0.")
    Validation.require_condition(max_audio_volume_db >= min_audio_volume_db, "Chaser maximum audio volume must be at least the minimum audio volume.")
    Validation.require_condition(min_audio_pitch_scale > 0.0, "Chaser minimum audio pitch must be positive.")
    Validation.require_condition(max_audio_pitch_scale >= min_audio_pitch_scale, "Chaser maximum audio pitch must be at least the minimum audio pitch.")