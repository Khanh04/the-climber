class_name RunState
extends RefCounted

enum Value {
    READY,
    CLIMBING,
    FALLING,
    RESCUE_OFFERED,
    ENDED
}

static func is_valid(value: int) -> bool:
    match value:
        Value.READY:
            return true
        Value.CLIMBING:
            return true
        Value.FALLING:
            return true
        Value.RESCUE_OFFERED:
            return true
        Value.ENDED:
            return true
        _:
            return false

static func assert_valid(value: int) -> void:
    Validation.require_condition(is_valid(value), "Unsupported run state.")