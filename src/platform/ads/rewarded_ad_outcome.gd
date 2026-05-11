class_name RewardedAdOutcome
extends RefCounted

enum Value {
    COMPLETED,
    CANCELLED,
    UNAVAILABLE,
    FAILED
}

static func is_valid(value: int) -> bool:
    match value:
        Value.COMPLETED:
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
    Validation.require_condition(is_valid(value), "Unsupported rewarded ad outcome.")