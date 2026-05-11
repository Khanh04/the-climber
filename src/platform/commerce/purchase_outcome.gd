class_name PurchaseOutcome
extends RefCounted

enum Value {
    PURCHASED,
    CANCELLED,
    FAILED,
    RESTORED,
    UNAVAILABLE
}

static func is_valid(value: int) -> bool:
    match value:
        Value.PURCHASED:
            return true
        Value.CANCELLED:
            return true
        Value.FAILED:
            return true
        Value.RESTORED:
            return true
        Value.UNAVAILABLE:
            return true
        _:
            return false

static func assert_valid(value: int) -> void:
    Validation.require_condition(is_valid(value), "Unsupported purchase outcome.")