class_name ClimbPrototypeTuning
extends Resource

@export var handhold_detection_radius_pixels: float = 96.0
@export var climb_impulse_pixels_per_second: float = 680.0
@export var upward_impulse_bias: float = 0.65
@export var max_player_speed_pixels_per_second: float = 900.0
@export var pixels_per_meter: float = 100.0
@export var handhold_group_name: StringName = &"handhold"

func is_valid() -> bool:
    return handhold_detection_radius_pixels > 0.0 \
        and climb_impulse_pixels_per_second > 0.0 \
        and upward_impulse_bias >= 0.0 \
        and upward_impulse_bias <= 1.0 \
        and max_player_speed_pixels_per_second > 0.0 \
        and pixels_per_meter > 0.0 \
        and not String(handhold_group_name).is_empty()

func validate() -> void:
    assert_valid()

func assert_valid() -> void:
    Validation.require_condition(handhold_detection_radius_pixels > 0.0, "Handhold detection radius must be positive.")
    Validation.require_condition(climb_impulse_pixels_per_second > 0.0, "Climb impulse must be positive.")
    Validation.require_condition(upward_impulse_bias >= 0.0 and upward_impulse_bias <= 1.0, "Upward impulse bias must be between 0 and 1.")
    Validation.require_condition(max_player_speed_pixels_per_second > 0.0, "Max player speed must be positive.")
    Validation.require_condition(pixels_per_meter > 0.0, "Pixels-per-meter conversion must be positive.")
    Validation.require_condition(not String(handhold_group_name).is_empty(), "Handhold group name cannot be empty.")
