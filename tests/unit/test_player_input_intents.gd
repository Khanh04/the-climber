extends GutTest

const AimInputIntentScript = preload("res://src/gameplay/player/aim_input_intent.gd")
const DebugResetInputIntentScript = preload("res://src/gameplay/player/debug_reset_input_intent.gd")
const GripInputIntentScript = preload("res://src/gameplay/player/grip_input_intent.gd")
const HandSideScript = preload("res://src/gameplay/player/hand_side.gd")
const PlayerInputFrameScript = preload("res://src/gameplay/player/player_input_frame.gd")
const ReleaseInputIntentScript = preload("res://src/gameplay/player/release_input_intent.gd")

func test_hand_side_validation_covers_supported_values() -> void:
    assert_true(HandSideScript.is_valid(HandSideScript.Value.LEFT))
    assert_true(HandSideScript.is_valid(HandSideScript.Value.RIGHT))
    assert_false(HandSideScript.is_valid(-1))

func test_grip_and_release_intents_require_a_supported_hand_side() -> void:
    var grip_intent := GripInputIntentScript.new(HandSideScript.Value.LEFT)
    var release_intent := ReleaseInputIntentScript.new(HandSideScript.Value.RIGHT)

    assert_true(grip_intent.is_valid())
    assert_true(release_intent.is_valid())

    grip_intent.hand_side = 99
    release_intent.hand_side = -1

    assert_false(grip_intent.is_valid())
    assert_false(release_intent.is_valid())

func test_aim_intent_requires_a_non_zero_vector() -> void:
    var aim_intent := AimInputIntentScript.new(Vector2.UP)

    assert_true(aim_intent.is_valid())

    aim_intent.aim_vector = Vector2.ZERO

    assert_false(aim_intent.is_valid())

func test_player_input_frame_groups_typed_intents() -> void:
    var grip_intent := GripInputIntentScript.new(HandSideScript.Value.LEFT)
    var release_intent := ReleaseInputIntentScript.new(HandSideScript.Value.RIGHT)
    var aim_intent := AimInputIntentScript.new(Vector2.RIGHT)
    var debug_reset_intent := DebugResetInputIntentScript.new()
    var input_frame := PlayerInputFrameScript.new(
        [grip_intent],
        [release_intent],
        aim_intent,
        debug_reset_intent
    )

    assert_true(input_frame.is_valid())
    assert_eq(input_frame.grip_intents.size(), 1)
    assert_eq(input_frame.release_intents.size(), 1)
    assert_true(input_frame.has_aim_intent())
    assert_true(input_frame.has_debug_reset_intent())

func test_player_input_frame_rejects_wrong_intent_types() -> void:
    var grip_intent := GripInputIntentScript.new(HandSideScript.Value.LEFT)
    var input_frame := PlayerInputFrameScript.new([grip_intent])

    input_frame.release_intents = [grip_intent]

    assert_false(input_frame.is_valid())