class_name PlayerInputFrame
extends RefCounted

const AimInputIntentScript = preload("res://src/gameplay/player/aim_input_intent.gd")
const DebugResetInputIntentScript = preload("res://src/gameplay/player/debug_reset_input_intent.gd")
const GripInputIntentScript = preload("res://src/gameplay/player/grip_input_intent.gd")
const ReleaseInputIntentScript = preload("res://src/gameplay/player/release_input_intent.gd")

var grip_intents: Array = []
var release_intents: Array = []
var aim_intent: RefCounted = null
var debug_reset_intent: RefCounted = null

func _init(
    grip_intents_value: Array = [],
    release_intents_value: Array = [],
    aim_intent_value: RefCounted = null,
    debug_reset_intent_value: RefCounted = null
) -> void:
    grip_intents = grip_intents_value.duplicate()
    release_intents = release_intents_value.duplicate()
    aim_intent = aim_intent_value
    debug_reset_intent = debug_reset_intent_value
    assert_valid()

func has_aim_intent() -> bool:
    return aim_intent != null

func has_debug_reset_intent() -> bool:
    return debug_reset_intent != null

func is_valid() -> bool:
    if not _all_grip_intents_valid():
        return false

    if not _all_release_intents_valid():
        return false

    if aim_intent != null:
        if not aim_intent is AimInputIntentScript:
            return false

        if not aim_intent.call("is_valid"):
            return false

    if debug_reset_intent != null:
        if not debug_reset_intent is DebugResetInputIntentScript:
            return false

        if not debug_reset_intent.call("is_valid"):
            return false

    return true

func assert_valid() -> void:
    Validation.require_condition(_all_grip_intents_valid(), "PlayerInputFrame requires grip intents to contain only valid GripInputIntent values.")
    Validation.require_condition(_all_release_intents_valid(), "PlayerInputFrame requires release intents to contain only valid ReleaseInputIntent values.")

    if aim_intent != null:
        Validation.require_condition(aim_intent is AimInputIntentScript, "PlayerInputFrame requires a valid AimInputIntent instance.")
        aim_intent.call("assert_valid")

    if debug_reset_intent != null:
        Validation.require_condition(debug_reset_intent is DebugResetInputIntentScript, "PlayerInputFrame requires a valid DebugResetInputIntent instance.")
        debug_reset_intent.call("assert_valid")

func _all_grip_intents_valid() -> bool:
    for intent in grip_intents:
        var typed_intent: Object = intent

        if not typed_intent is GripInputIntentScript:
            return false

        if not typed_intent.call("is_valid"):
            return false

    return true

func _all_release_intents_valid() -> bool:
    for intent in release_intents:
        var typed_intent: Object = intent

        if not typed_intent is ReleaseInputIntentScript:
            return false

        if not typed_intent.call("is_valid"):
            return false

    return true