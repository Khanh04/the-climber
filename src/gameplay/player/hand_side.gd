class_name HandSide
extends RefCounted

enum Value {
    LEFT,
    RIGHT
}

static func is_valid(value: int) -> bool:
    match value:
        Value.LEFT:
            return true
        Value.RIGHT:
            return true
        _:
            return false

static func assert_valid(value: int) -> void:
    Validation.require_condition(is_valid(value), "Unsupported hand side.")