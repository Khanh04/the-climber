class_name ClimbPrototypeTuning
extends Resource

@export var handhold_detection_radius_pixels: float = 96.0
@export var swing_control_force: float = 2400.0
@export var grip_hang_offset_pixels: float = 92.0
@export var grip_aim_target_offset_pixels: float = 72.0
@export var grip_pull_stiffness: float = 42.0
@export var grip_velocity_damping: float = 0.96
@export var attached_gravity_compensation_force: float = 980.0
@export var two_hand_velocity_damping: float = 0.90
@export var max_player_speed_pixels_per_second: float = 900.0
@export var camera_player_lower_screen_offset_pixels: float = 160.0
@export var bottom_fall_margin_pixels: float = 160.0
@export var pixels_per_meter: float = 100.0
@export var handhold_group_name: StringName = &"handhold"

func is_valid() -> bool:
    return handhold_detection_radius_pixels > 0.0 \
        and swing_control_force > 0.0 \
        and grip_hang_offset_pixels > 0.0 \
        and grip_aim_target_offset_pixels >= 0.0 \
        and grip_pull_stiffness > 0.0 \
        and grip_velocity_damping >= 0.0 \
        and grip_velocity_damping <= 1.0 \
        and attached_gravity_compensation_force >= 0.0 \
        and two_hand_velocity_damping >= 0.0 \
        and two_hand_velocity_damping <= 1.0 \
        and max_player_speed_pixels_per_second > 0.0 \
        and camera_player_lower_screen_offset_pixels >= 0.0 \
        and bottom_fall_margin_pixels >= 0.0 \
        and pixels_per_meter > 0.0 \
        and not String(handhold_group_name).is_empty()

func validate() -> void:
    assert_valid()

func get_camera_player_lower_screen_offset_pixels() -> float:
    return camera_player_lower_screen_offset_pixels

func get_bottom_fall_margin_pixels() -> float:
    return bottom_fall_margin_pixels

func assert_valid() -> void:
    Validation.require_condition(handhold_detection_radius_pixels > 0.0, "Handhold detection radius must be positive.")
    Validation.require_condition(swing_control_force > 0.0, "Swing control force must be positive.")
    Validation.require_condition(grip_hang_offset_pixels > 0.0, "Grip hang offset must be positive.")
    Validation.require_condition(grip_aim_target_offset_pixels >= 0.0, "Grip aim target offset cannot be negative.")
    Validation.require_condition(grip_pull_stiffness > 0.0, "Grip pull stiffness must be positive.")
    Validation.require_condition(grip_velocity_damping >= 0.0 and grip_velocity_damping <= 1.0, "Grip velocity damping must be between 0 and 1.")
    Validation.require_condition(attached_gravity_compensation_force >= 0.0, "Attached gravity compensation force cannot be negative.")
    Validation.require_condition(two_hand_velocity_damping >= 0.0 and two_hand_velocity_damping <= 1.0, "Two-hand velocity damping must be between 0 and 1.")
    Validation.require_condition(max_player_speed_pixels_per_second > 0.0, "Max player speed must be positive.")
    Validation.require_condition(camera_player_lower_screen_offset_pixels >= 0.0, "Camera player lower-screen offset cannot be negative.")
    Validation.require_condition(bottom_fall_margin_pixels >= 0.0, "Bottom fall margin cannot be negative.")
    Validation.require_condition(pixels_per_meter > 0.0, "Pixels-per-meter conversion must be positive.")
    Validation.require_condition(not String(handhold_group_name).is_empty(), "Handhold group name cannot be empty.")
