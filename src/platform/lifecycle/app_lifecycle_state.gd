class_name AppLifecycleState
extends RefCounted

enum Value {
    ACTIVE,
    PAUSED,
    BACKGROUND
}

static func is_valid(value: int) -> bool:
    match value:
        Value.ACTIVE:
            return true
        Value.PAUSED:
            return true
        Value.BACKGROUND:
            return true
        _:
            return false

static func assert_valid(value: int) -> void:
    Validation.require_condition(is_valid(value), "Unsupported app lifecycle state.")