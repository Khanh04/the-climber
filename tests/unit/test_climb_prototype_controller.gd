extends GutTest

const AimInputIntentScript = preload("res://src/gameplay/player/aim_input_intent.gd")
const ClimbPrototypeControllerScript = preload("res://src/gameplay/player/climb_prototype_controller.gd")
const ClimbPrototypeTuningScript = preload("res://resources/config/climb_prototype_tuning.gd")
const GripInputIntentScript = preload("res://src/gameplay/player/grip_input_intent.gd")
const HandSideScript = preload("res://src/gameplay/player/hand_side.gd")
const HandholdTargetScript = preload("res://src/gameplay/player/handhold_target.gd")
const PlayerInputFrameScript = preload("res://src/gameplay/player/player_input_frame.gd")
const ReleaseInputIntentScript = preload("res://src/gameplay/player/release_input_intent.gd")
const StaminaRuntimeScript = preload("res://src/gameplay/player/stamina_runtime.gd")
const StaminaTuningScript = preload("res://resources/config/stamina_tuning.gd")

func test_hand_attachment_state_tracks_independent_hands() -> void:
    var state := HandAttachmentState.new()

    state.attach(HandSideScript.Value.LEFT, &"hold_left", Vector2(10.0, 20.0))
    state.attach(HandSideScript.Value.RIGHT, &"hold_right", Vector2(30.0, 40.0))

    assert_true(state.is_attached(HandSideScript.Value.LEFT))
    assert_true(state.is_attached(HandSideScript.Value.RIGHT))
    assert_eq(state.get_attached_hand_count(), 2)
    assert_eq(state.get_hold_id(HandSideScript.Value.LEFT), &"hold_left")
    assert_eq(state.get_attach_position(HandSideScript.Value.RIGHT), Vector2(30.0, 40.0))

    state.release(HandSideScript.Value.LEFT)

    assert_false(state.is_attached(HandSideScript.Value.LEFT))
    assert_true(state.is_attached(HandSideScript.Value.RIGHT))
    assert_eq(state.get_attached_hand_count(), 1)

func test_handhold_target_requires_id_and_positive_drain_multiplier() -> void:
    var target := HandholdTargetScript.new(&"hold", Vector2(1.0, 2.0), 2.0)

    assert_true(target.is_valid())

    target.stamina_drain_multiplier = 0.0

    assert_false(target.is_valid())

func test_controller_attaches_from_typed_grip_intents_and_releases_from_typed_release_intents() -> void:
    var controller := _create_controller()
    var left_target := HandholdTargetScript.new(&"left_hold", Vector2(100.0, 200.0))
    var grip_frame := PlayerInputFrameScript.new([GripInputIntentScript.new(HandSideScript.Value.LEFT)])
    var release_frame := PlayerInputFrameScript.new([], [ReleaseInputIntentScript.new(HandSideScript.Value.LEFT)])

    var grip_result := controller.apply_input_frame(grip_frame, left_target, null, 0.0)

    assert_eq(grip_result.attached_hand_count, 1)
    assert_true(controller.get_attachment_state().is_attached(HandSideScript.Value.LEFT))
    assert_eq(controller.get_attachment_state().get_hold_id(HandSideScript.Value.LEFT), &"left_hold")

    var release_result := controller.apply_input_frame(release_frame, null, null, 0.0)

    assert_eq(release_result.attached_hand_count, 0)
    assert_false(controller.get_attachment_state().is_attached(HandSideScript.Value.LEFT))

func test_controller_generates_upward_biased_impulse_when_aiming_while_attached() -> void:
    var controller := _create_controller()
    var right_target := HandholdTargetScript.new(&"right_hold", Vector2(100.0, 200.0))
    var grip_frame := PlayerInputFrameScript.new([GripInputIntentScript.new(HandSideScript.Value.RIGHT)])
    var aim_frame := PlayerInputFrameScript.new([], [], AimInputIntentScript.new(Vector2.RIGHT))

    var _grip_result := controller.apply_input_frame(grip_frame, null, right_target, 0.0)
    var aim_result := controller.apply_input_frame(aim_frame, null, null, 0.0)

    assert_gt(aim_result.impulse.x, 0.0)
    assert_lt(aim_result.impulse.y, 0.0)

func test_controller_generates_impulse_when_releasing_an_attached_hand_with_aim() -> void:
    var controller := _create_controller()
    var left_target := HandholdTargetScript.new(&"left_hold", Vector2(100.0, 200.0))
    var grip_frame := PlayerInputFrameScript.new([GripInputIntentScript.new(HandSideScript.Value.LEFT)])
    var release_aim_frame := PlayerInputFrameScript.new(
        [],
        [ReleaseInputIntentScript.new(HandSideScript.Value.LEFT)],
        AimInputIntentScript.new(Vector2.UP)
    )

    var _grip_result := controller.apply_input_frame(grip_frame, left_target, null, 0.0)
    var release_aim_result := controller.apply_input_frame(release_aim_frame, null, null, 0.0)

    assert_lt(release_aim_result.impulse.y, 0.0)
    assert_eq(release_aim_result.attached_hand_count, 0)

func test_controller_reports_stamina_depletion_and_breaks_attachment() -> void:
    var tuning := ClimbPrototypeTuningScript.new()
    var stamina_tuning := StaminaTuningScript.new()
    stamina_tuning.one_hand_seconds = 0.1
    var stamina := StaminaRuntimeScript.new(stamina_tuning)
    var controller := ClimbPrototypeControllerScript.new(tuning, stamina)
    var left_target := HandholdTargetScript.new(&"left_hold", Vector2(100.0, 200.0))
    var grip_frame := PlayerInputFrameScript.new([GripInputIntentScript.new(HandSideScript.Value.LEFT)])

    var result := controller.apply_input_frame(grip_frame, left_target, null, 0.1)

    assert_true(result.stamina_depleted_now)
    assert_eq(result.attached_hand_count, 0)
    assert_false(controller.get_attachment_state().is_attached(HandSideScript.Value.LEFT))

func _create_controller() -> ClimbPrototypeControllerScript:
    var tuning := ClimbPrototypeTuningScript.new()
    var stamina := StaminaRuntimeScript.new(StaminaTuningScript.new())

    return ClimbPrototypeControllerScript.new(tuning, stamina)
