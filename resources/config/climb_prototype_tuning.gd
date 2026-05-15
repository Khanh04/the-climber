class_name ClimbPrototypeTuning
extends Resource

# Max distance from a hand anchor to a hold before grip input can attach.
# Higher values make grabbing more forgiving; lower values require cleaner aim.
@export var handhold_detection_radius_pixels: float = 96.0
# Debug-only directional force applied while the player is attached and aiming.
# Higher values make pull and swing input feel stronger and more immediate.
@export var swing_control_force: float = 2400.0
# Default vertical gap between the held grip point and the player's body center.
# Higher values make the body hang lower under holds; lower values tuck it closer.
@export var grip_hang_offset_pixels: float = 92.0
# Debug-only distance the grip target shifts toward the aim direction while attached.
# Higher values make aiming reshape the body position more aggressively.
@export var grip_aim_target_offset_pixels: float = 72.0
# Strength of the spring-like pull that moves the body toward the grip target.
# Higher values feel snappier and more controlled; lower values feel looser.
@export var grip_pull_stiffness: float = 42.0
# Per-frame velocity retention while attached.
# Higher values preserve momentum; lower values bleed speed faster.
@export var grip_velocity_damping: float = 0.96
# Upward force that offsets gravity while attached.
# Higher values reduce sag and falling; lower values make hanging heavier.
@export var attached_gravity_compensation_force: float = 980.0
# Speed at which hand visuals catch up to their visual target positions.
# Higher values reduce visible lag; lower values make hands feel sloppier.
@export var hand_visual_follow_speed_pixels_per_second: float = 240.0
# Seconds of body velocity used to trail hand visuals behind the gameplay reach anchors.
# Higher values exaggerate visual drag opposite the body's motion.
@export var hand_visual_velocity_lag_seconds: float = 0.03
# Maximum distance that body-velocity drag can pull a hand visual away from its visual rest offset.
# Higher values allow more exaggerated trailing before the follow catches up.
@export var hand_visual_max_lag_pixels: float = 18.0
# Extra per-frame damping applied when both hands are attached.
# Lower values lock the player down more; higher values keep two-hand movement livelier.
@export var two_hand_velocity_damping: float = 0.90
# Hard speed cap applied after movement forces each frame.
# Higher values allow faster swings and launches before clamping.
@export var max_player_speed_pixels_per_second: float = 900.0
# Vertical offset used to keep the player below the camera center while climbing upward.
# Higher values show more space above the player; lower values center them more.
@export var camera_player_lower_screen_offset_pixels: float = 160.0
# Extra distance below the visible bottom edge before a fall is resolved.
# Higher values are more forgiving; lower values end the run sooner when dropping.
@export var bottom_fall_margin_pixels: float = 160.0
# Conversion factor for recording climb height into run-session meters.
# Higher values mean more pixels are required to count as one meter of progress.
@export var pixels_per_meter: float = 100.0
# Scene group name used to find valid handhold nodes at runtime.
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
        and hand_visual_follow_speed_pixels_per_second > 0.0 \
        and hand_visual_velocity_lag_seconds >= 0.0 \
        and hand_visual_max_lag_pixels >= 0.0 \
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
    Validation.require_condition(hand_visual_follow_speed_pixels_per_second > 0.0, "Hand visual follow speed must be positive.")
    Validation.require_condition(hand_visual_velocity_lag_seconds >= 0.0, "Hand visual velocity lag seconds cannot be negative.")
    Validation.require_condition(hand_visual_max_lag_pixels >= 0.0, "Hand visual max lag pixels cannot be negative.")
    Validation.require_condition(two_hand_velocity_damping >= 0.0 and two_hand_velocity_damping <= 1.0, "Two-hand velocity damping must be between 0 and 1.")
    Validation.require_condition(max_player_speed_pixels_per_second > 0.0, "Max player speed must be positive.")
    Validation.require_condition(camera_player_lower_screen_offset_pixels >= 0.0, "Camera player lower-screen offset cannot be negative.")
    Validation.require_condition(bottom_fall_margin_pixels >= 0.0, "Bottom fall margin cannot be negative.")
    Validation.require_condition(pixels_per_meter > 0.0, "Pixels-per-meter conversion must be positive.")
    Validation.require_condition(not String(handhold_group_name).is_empty(), "Handhold group name cannot be empty.")
