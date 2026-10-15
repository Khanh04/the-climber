extends GutTest

const AimInputIntentScript = preload("res://src/gameplay/player/aim_input_intent.gd")
const ClimbPrototypeControllerScript = preload("res://src/gameplay/player/climb_prototype_controller.gd")
const ClimbPrototypeTuningScript = preload("res://resources/config/climb_prototype_tuning.gd")
const GripInputIntentScript = preload("res://src/gameplay/player/grip_input_intent.gd")
const HandholdTypeScript = preload("res://src/gameplay/generation/handhold_type.gd")
const HandSideScript = preload("res://src/gameplay/player/hand_side.gd")
const HandholdTargetScript = preload("res://src/gameplay/player/handhold_target.gd")
const PlayerInputFrameScript = preload("res://src/gameplay/player/player_input_frame.gd")
const ReleaseInputIntentScript = preload("res://src/gameplay/player/release_input_intent.gd")
const StaminaRuntimeScript = preload("res://src/gameplay/player/stamina_runtime.gd")
const StaminaTuningScript = preload("res://resources/config/stamina_tuning.gd")

func test_hand_attachment_state_tracks_independent_hands() -> void:
    var state := HandAttachmentState.new()

    state.attach(HandSideScript.Value.LEFT, &"hold_left", Vector2(10.0, 20.0), NodePath("left_hold"))
    state.attach(HandSideScript.Value.RIGHT, &"hold_right", Vector2(30.0, 40.0), NodePath("right_hold"))

    assert_true(state.is_attached(HandSideScript.Value.LEFT))
    assert_true(state.is_attached(HandSideScript.Value.RIGHT))
    assert_eq(state.get_attached_hand_count(), 2)
    assert_eq(state.get_hold_id(HandSideScript.Value.LEFT), &"hold_left")
    assert_eq(state.get_hold_path(HandSideScript.Value.LEFT), NodePath("left_hold"))
    assert_eq(state.get_attach_position(HandSideScript.Value.RIGHT), Vector2(30.0, 40.0))

    state.release(HandSideScript.Value.LEFT)

    assert_false(state.is_attached(HandSideScript.Value.LEFT))
    assert_true(state.is_attached(HandSideScript.Value.RIGHT))
    assert_eq(state.get_attached_hand_count(), 1)

func test_handhold_target_requires_id_and_positive_drain_multiplier() -> void:
    var target := HandholdTargetScript.new(&"hold", Vector2(1.0, 2.0), NodePath("hold"), 2.0, HandholdTypeScript.Value.BURN)

    assert_true(target.is_valid())

    target.stamina_drain_multiplier = 0.0

    assert_false(target.is_valid())

func test_controller_uses_attached_target_drain_multiplier_for_stamina() -> void:
    var tuning := ClimbPrototypeTuningScript.new()
    var stamina_tuning := StaminaTuningScript.new()
    stamina_tuning.one_hand_seconds = 0.1
    var stamina := StaminaRuntimeScript.new(stamina_tuning)
    var controller := ClimbPrototypeControllerScript.new(tuning, stamina)
    var left_target := HandholdTargetScript.new(
        &"left_hold",
        Vector2(100.0, 200.0),
        NodePath("left_hold"),
        2.0,
        HandholdTypeScript.Value.BURN
    )
    var grip_frame := PlayerInputFrameScript.new([GripInputIntentScript.new(HandSideScript.Value.LEFT)])

    var result := controller.apply_input_frame(grip_frame, left_target, null, 0.05)

    assert_true(result.stamina_depleted_now)
    assert_eq(result.attached_hand_count, 0)
    assert_false(controller.get_attachment_state().is_attached(HandSideScript.Value.LEFT))

func test_controller_attaches_from_typed_grip_intents_and_releases_from_typed_release_intents() -> void:
    var controller := _create_controller()
    var left_target := HandholdTargetScript.new(&"left_hold", Vector2(100.0, 200.0), NodePath("left_hold"))
    var grip_frame := PlayerInputFrameScript.new([GripInputIntentScript.new(HandSideScript.Value.LEFT)])
    var release_frame := PlayerInputFrameScript.new([], [ReleaseInputIntentScript.new(HandSideScript.Value.LEFT)])

    var grip_result := controller.apply_input_frame(grip_frame, left_target, null, 0.0)

    assert_eq(grip_result.attached_hand_count, 1)
    assert_true(controller.get_attachment_state().is_attached(HandSideScript.Value.LEFT))
    assert_eq(controller.get_attachment_state().get_hold_id(HandSideScript.Value.LEFT), &"left_hold")
    assert_eq(controller.get_attachment_state().get_hold_path(HandSideScript.Value.LEFT), NodePath("left_hold"))

    var release_result := controller.apply_input_frame(release_frame, null, null, 0.0)

    assert_eq(release_result.attached_hand_count, 0)
    assert_false(controller.get_attachment_state().is_attached(HandSideScript.Value.LEFT))

func test_controller_does_not_attach_both_hands_to_the_same_hold() -> void:
    var controller := _create_controller()
    var shared_target := HandholdTargetScript.new(&"shared_hold", Vector2(100.0, 200.0), NodePath("shared_hold"))
    var dual_grip_frame := PlayerInputFrameScript.new([
        GripInputIntentScript.new(HandSideScript.Value.LEFT),
        GripInputIntentScript.new(HandSideScript.Value.RIGHT),
    ])

    var result := controller.apply_input_frame(dual_grip_frame, shared_target, shared_target, 0.0)

    assert_eq(result.attached_hand_count, 1)
    assert_true(controller.get_attachment_state().is_attached(HandSideScript.Value.LEFT))
    assert_false(controller.get_attachment_state().is_attached(HandSideScript.Value.RIGHT))

func test_controller_generates_control_force_when_aiming_while_attached() -> void:
    var controller := _create_controller()
    var right_target := HandholdTargetScript.new(&"right_hold", Vector2(100.0, 200.0), NodePath("right_hold"))
    var grip_frame := PlayerInputFrameScript.new([GripInputIntentScript.new(HandSideScript.Value.RIGHT)])
    var aim_frame := PlayerInputFrameScript.new([], [], AimInputIntentScript.new(Vector2.RIGHT))

    var _grip_result := controller.apply_input_frame(grip_frame, null, right_target, 0.0)
    var aim_result := controller.apply_input_frame(aim_frame, null, null, 0.0)

    assert_gt(aim_result.control_force.x, 0.0)
    assert_eq(aim_result.control_force.y, 0.0)

func test_controller_does_not_generate_control_force_after_releasing_last_hand() -> void:
    var controller := _create_controller()
    var left_target := HandholdTargetScript.new(&"left_hold", Vector2(100.0, 200.0), NodePath("left_hold"))
    var grip_frame := PlayerInputFrameScript.new([GripInputIntentScript.new(HandSideScript.Value.LEFT)])
    var release_aim_frame := PlayerInputFrameScript.new(
        [],
        [ReleaseInputIntentScript.new(HandSideScript.Value.LEFT)],
        AimInputIntentScript.new(Vector2.UP)
    )

    var _grip_result := controller.apply_input_frame(grip_frame, left_target, null, 0.0)
    var release_aim_result := controller.apply_input_frame(release_aim_frame, null, null, 0.0)

    assert_eq(release_aim_result.control_force, Vector2.ZERO)
    assert_eq(release_aim_result.attached_hand_count, 0)

func test_controller_reports_stamina_depletion_and_breaks_attachment() -> void:
    var tuning := ClimbPrototypeTuningScript.new()
    var stamina_tuning := StaminaTuningScript.new()
    stamina_tuning.one_hand_seconds = 0.1
    var stamina := StaminaRuntimeScript.new(stamina_tuning)
    var controller := ClimbPrototypeControllerScript.new(tuning, stamina)
    var left_target := HandholdTargetScript.new(&"left_hold", Vector2(100.0, 200.0), NodePath("left_hold"))
    var grip_frame := PlayerInputFrameScript.new([GripInputIntentScript.new(HandSideScript.Value.LEFT)])

    var result := controller.apply_input_frame(grip_frame, left_target, null, 0.1)

    assert_true(result.stamina_depleted_now)
    assert_eq(result.attached_hand_count, 0)
    assert_false(controller.get_attachment_state().is_attached(HandSideScript.Value.LEFT))

func _create_controller() -> ClimbPrototypeControllerScript:
    var tuning := ClimbPrototypeTuningScript.new()
    var stamina := StaminaRuntimeScript.new(StaminaTuningScript.new())

    return ClimbPrototypeControllerScript.new(tuning, stamina)

func test_auto_catch_grips_targets_without_grip_input_when_no_hand_is_attached() -> void:
    var stamina := StaminaRuntimeScript.new(StaminaTuningScript.new())
    var controller := ClimbPrototypeControllerScript.new(ClimbPrototypeTuningScript.new(), stamina)
    controller.configure_character_passives(false, true)
    var left_target := HandholdTargetScript.new(&"left_hold", Vector2(100.0, 200.0), NodePath("left_hold"))
    var empty_frame := PlayerInputFrameScript.new()

    var _result: RefCounted = controller.apply_input_frame(empty_frame, left_target, null, 0.016)

    assert_true(controller.get_attachment_state().is_attached(HandSideScript.Value.LEFT))
    assert_false(controller.get_attachment_state().is_attached(HandSideScript.Value.RIGHT))

func test_auto_catch_does_not_grab_while_a_hand_is_already_attached() -> void:
    var stamina := StaminaRuntimeScript.new(StaminaTuningScript.new())
    var controller := ClimbPrototypeControllerScript.new(ClimbPrototypeTuningScript.new(), stamina)
    controller.configure_character_passives(false, true)
    var left_target := HandholdTargetScript.new(&"left_hold", Vector2(100.0, 200.0), NodePath("left_hold"))
    var right_target := HandholdTargetScript.new(&"right_hold", Vector2(150.0, 200.0), NodePath("right_hold"))
    var _first: RefCounted = controller.apply_input_frame(PlayerInputFrameScript.new([GripInputIntentScript.new(HandSideScript.Value.LEFT)]), left_target, null, 0.016)

    var _second: RefCounted = controller.apply_input_frame(PlayerInputFrameScript.new(), left_target, right_target, 0.016)

    assert_false(controller.get_attachment_state().is_attached(HandSideScript.Value.RIGHT))

func test_without_auto_catch_targets_need_grip_input() -> void:
    var stamina := StaminaRuntimeScript.new(StaminaTuningScript.new())
    var controller := ClimbPrototypeControllerScript.new(ClimbPrototypeTuningScript.new(), stamina)
    var left_target := HandholdTargetScript.new(&"left_hold", Vector2(100.0, 200.0), NodePath("left_hold"))

    var _result: RefCounted = controller.apply_input_frame(PlayerInputFrameScript.new(), left_target, null, 0.016)
    assert_eq(controller.get_attachment_state().get_attached_hand_count(), 0)

    controller.set_forced_catch(true)
    var _forced: RefCounted = controller.apply_input_frame(PlayerInputFrameScript.new(), left_target, null, 0.016)
    assert_true(controller.get_attachment_state().is_attached(HandSideScript.Value.LEFT))

func test_caps_hold_drain_limits_slippery_hold_drain_to_normal() -> void:
    var stamina_tuning := StaminaTuningScript.new()
    var stamina := StaminaRuntimeScript.new(stamina_tuning)
    var controller := ClimbPrototypeControllerScript.new(ClimbPrototypeTuningScript.new(), stamina)
    controller.configure_character_passives(true, false)
    var greasy_target := HandholdTargetScript.new(&"greasy", Vector2(100.0, 200.0), NodePath("greasy"), 3.0)

    var _result: RefCounted = controller.apply_input_frame(PlayerInputFrameScript.new([GripInputIntentScript.new(HandSideScript.Value.LEFT)]), greasy_target, null, 1.0)

    assert_almost_eq(stamina.get_current_stamina_seconds(), stamina_tuning.one_hand_seconds - 1.0, 0.001)

func test_swing_force_multiplier_scales_swing_control() -> void:
    var tuning := ClimbPrototypeTuningScript.new()
    var controller := ClimbPrototypeControllerScript.new(tuning, StaminaRuntimeScript.new(StaminaTuningScript.new()))
    controller.configure_character_passives(false, false, 0.8)

    assert_almost_eq(controller.get_swing_control_force(Vector2.UP).length(), tuning.swing_control_force * 0.8, 0.01)
