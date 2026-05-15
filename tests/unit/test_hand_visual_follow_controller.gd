extends GutTest

const ClimbPrototypeTuningScript = preload("res://resources/config/climb_prototype_tuning.gd")
const HandVisualFollowControllerScript = preload("res://src/gameplay/player/hand_visual_follow_controller.gd")

func test_follow_controller_calculates_velocity_trailed_target_local_position() -> void:
    var tuning := ClimbPrototypeTuningScript.new()
    tuning.hand_visual_velocity_lag_seconds = 0.05
    tuning.hand_visual_max_lag_pixels = 10.0
    var controller := HandVisualFollowControllerScript.new(tuning)

    var target_local_position: Vector2 = controller.calculate_target_local_position(
        Vector2(-24.0, 10.0),
        Vector2(-8.0, 4.0),
        Vector2(400.0, 0.0)
    )

    assert_eq(target_local_position, Vector2(-42.0, 14.0))

func test_follow_controller_moves_visual_anchor_toward_trailed_target() -> void:
    var tuning := ClimbPrototypeTuningScript.new()
    tuning.hand_visual_follow_speed_pixels_per_second = 20.0
    tuning.hand_visual_velocity_lag_seconds = 0.05
    tuning.hand_visual_max_lag_pixels = 10.0
    var controller := HandVisualFollowControllerScript.new(tuning)

    var next_local_position: Vector2 = controller.calculate_next_local_position(
        Vector2(-32.0, 14.0),
        Vector2(-24.0, 10.0),
        Vector2(-8.0, 4.0),
        Vector2(400.0, 0.0),
        0.25
    )

    assert_eq(next_local_position, Vector2(-37.0, 14.0))