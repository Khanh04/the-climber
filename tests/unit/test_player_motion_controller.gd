extends GutTest

const ClimbPrototypeTuningScript = preload("res://resources/config/climb_prototype_tuning.gd")
const HandAttachmentStateScript = preload("res://src/gameplay/player/hand_attachment_state.gd")
const HandSideScript = preload("res://src/gameplay/player/hand_side.gd")
const PlayerMotionControllerScript = preload("res://src/gameplay/player/player_motion_controller.gd")

func test_motion_controller_calculates_one_hand_grip_target() -> void:
    var tuning := ClimbPrototypeTuningScript.new()
    var controller := PlayerMotionControllerScript.new(tuning)
    var attachment_state := HandAttachmentStateScript.new()

    attachment_state.attach(HandSideScript.Value.LEFT, &"left_hold", Vector2(100.0, 200.0), NodePath("left_hold"))

    assert_eq(controller.calculate_grip_target_position(attachment_state, Vector2.ZERO), Vector2(100.0, 200.0 + tuning.grip_hang_offset_pixels))

func test_motion_controller_averages_two_hand_target_and_applies_aim_offset() -> void:
    var tuning := ClimbPrototypeTuningScript.new()
    tuning.grip_hang_offset_pixels = 80.0
    tuning.grip_aim_target_offset_pixels = 20.0
    var controller := PlayerMotionControllerScript.new(tuning)
    var attachment_state := HandAttachmentStateScript.new()

    attachment_state.attach(HandSideScript.Value.LEFT, &"left_hold", Vector2(80.0, 100.0), NodePath("left_hold"))
    attachment_state.attach(HandSideScript.Value.RIGHT, &"right_hold", Vector2(120.0, 100.0), NodePath("right_hold"))

    assert_eq(controller.calculate_grip_target_position(attachment_state, Vector2.RIGHT), Vector2(120.0, 180.0))

func test_motion_controller_clamps_velocity_to_tuning_speed() -> void:
    var tuning := ClimbPrototypeTuningScript.new()
    tuning.max_player_speed_pixels_per_second = 100.0
    var controller := PlayerMotionControllerScript.new(tuning)

    var clamped_velocity: Vector2 = controller.calculate_clamped_velocity(Vector2(300.0, 400.0))

    assert_eq(clamped_velocity.length(), 100.0)

func test_motion_controller_only_applies_two_hand_damping_for_two_attachments() -> void:
    var tuning := ClimbPrototypeTuningScript.new()
    tuning.two_hand_velocity_damping = 0.5
    var controller := PlayerMotionControllerScript.new(tuning)

    assert_eq(controller.calculate_damped_velocity(Vector2(10.0, 0.0), 0), Vector2(10.0, 0.0))
    assert_eq(controller.calculate_damped_velocity(Vector2(10.0, 0.0), 1), Vector2(10.0, 0.0))
    assert_eq(controller.calculate_damped_velocity(Vector2(10.0, 0.0), 2), Vector2(5.0, 0.0))