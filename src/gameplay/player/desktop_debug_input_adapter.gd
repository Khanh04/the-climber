class_name DesktopDebugInputAdapter
extends RefCounted

const AimInputIntentScript = preload("res://src/gameplay/player/aim_input_intent.gd")
const DebugResetInputIntentScript = preload("res://src/gameplay/player/debug_reset_input_intent.gd")
const GripInputIntentScript = preload("res://src/gameplay/player/grip_input_intent.gd")
const HandSideScript = preload("res://src/gameplay/player/hand_side.gd")
const PlayerInputFrameScript = preload("res://src/gameplay/player/player_input_frame.gd")
const ReleaseInputIntentScript = preload("res://src/gameplay/player/release_input_intent.gd")

var _left_grip_pressed: bool = false
var _right_grip_pressed: bool = false
var _debug_reset_pressed: bool = false

func create_input_frame(
    left_grip_pressed_now: bool,
    right_grip_pressed_now: bool,
    aim_vector: Vector2 = Vector2.ZERO,
    debug_reset_pressed_now: bool = false
) -> PlayerInputFrameScript:
    var grip_intents: Array = []
    var release_intents: Array = []
    var aim_intent: RefCounted = null
    var debug_reset_intent: RefCounted = null

    if left_grip_pressed_now and not _left_grip_pressed:
        grip_intents.append(GripInputIntentScript.new(HandSideScript.Value.LEFT))
    elif _left_grip_pressed and not left_grip_pressed_now:
        release_intents.append(ReleaseInputIntentScript.new(HandSideScript.Value.LEFT))

    if right_grip_pressed_now and not _right_grip_pressed:
        grip_intents.append(GripInputIntentScript.new(HandSideScript.Value.RIGHT))
    elif _right_grip_pressed and not right_grip_pressed_now:
        release_intents.append(ReleaseInputIntentScript.new(HandSideScript.Value.RIGHT))

    if aim_vector != Vector2.ZERO:
        aim_intent = AimInputIntentScript.new(aim_vector)

    if debug_reset_pressed_now and not _debug_reset_pressed:
        debug_reset_intent = DebugResetInputIntentScript.new()

    _left_grip_pressed = left_grip_pressed_now
    _right_grip_pressed = right_grip_pressed_now
    _debug_reset_pressed = debug_reset_pressed_now

    return PlayerInputFrameScript.new(grip_intents, release_intents, aim_intent, debug_reset_intent)

func reset() -> void:
    _left_grip_pressed = false
    _right_grip_pressed = false
    _debug_reset_pressed = false