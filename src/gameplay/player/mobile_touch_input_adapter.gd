class_name MobileTouchInputAdapter
extends RefCounted

const GripInputIntentScript = preload("res://src/gameplay/player/grip_input_intent.gd")
const HandSideScript = preload("res://src/gameplay/player/hand_side.gd")
const PlayerInputFrameScript = preload("res://src/gameplay/player/player_input_frame.gd")
const ReleaseInputIntentScript = preload("res://src/gameplay/player/release_input_intent.gd")

var _left_grip_pressed: bool = false
var _right_grip_pressed: bool = false

func create_input_frame(
    viewport_size: Vector2,
    active_touch_positions: PackedVector2Array
) -> PlayerInputFrameScript:
    Validation.require_condition(viewport_size.x > 0.0, "MobileTouchInputAdapter requires a positive viewport width.")
    Validation.require_condition(viewport_size.y > 0.0, "MobileTouchInputAdapter requires a positive viewport height.")

    var left_grip_pressed_now: bool = _has_touch_in_left_half(viewport_size, active_touch_positions)
    var right_grip_pressed_now: bool = _has_touch_in_right_half(viewport_size, active_touch_positions)
    var grip_intents: Array = []
    var release_intents: Array = []

    if left_grip_pressed_now and not _left_grip_pressed:
        grip_intents.append(GripInputIntentScript.new(HandSideScript.Value.LEFT))
    elif _left_grip_pressed and not left_grip_pressed_now:
        release_intents.append(ReleaseInputIntentScript.new(HandSideScript.Value.LEFT))

    if right_grip_pressed_now and not _right_grip_pressed:
        grip_intents.append(GripInputIntentScript.new(HandSideScript.Value.RIGHT))
    elif _right_grip_pressed and not right_grip_pressed_now:
        release_intents.append(ReleaseInputIntentScript.new(HandSideScript.Value.RIGHT))

    _left_grip_pressed = left_grip_pressed_now
    _right_grip_pressed = right_grip_pressed_now

    return PlayerInputFrameScript.new(grip_intents, release_intents)

func reset() -> void:
    _left_grip_pressed = false
    _right_grip_pressed = false

func _has_touch_in_left_half(viewport_size: Vector2, active_touch_positions: PackedVector2Array) -> bool:
    var midpoint_x: float = viewport_size.x * 0.5

    for touch_position in active_touch_positions:
        var typed_touch_position: Vector2 = touch_position
        if typed_touch_position.x < midpoint_x:
            return true

    return false

func _has_touch_in_right_half(viewport_size: Vector2, active_touch_positions: PackedVector2Array) -> bool:
    var midpoint_x: float = viewport_size.x * 0.5

    for touch_position in active_touch_positions:
        var typed_touch_position: Vector2 = touch_position
        if typed_touch_position.x >= midpoint_x:
            return true

    return false