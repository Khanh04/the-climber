class_name ShareResult
extends RefCounted

enum Value {
    SHARED,
    CANCELLED,
    UNAVAILABLE,
    FAILED
}

static func is_valid(value: int) -> bool:
    match value:
        Value.SHARED:
            return true
        Value.CANCELLED:
            return true
        Value.UNAVAILABLE:
            return true
        Value.FAILED:
            return true
        _:
            return false

static func assert_valid(value: int) -> void:
    Validation.require_condition(is_valid(value), "Unsupported share result.")