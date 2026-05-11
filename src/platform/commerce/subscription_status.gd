class_name SubscriptionStatus
extends RefCounted

enum Value {
    INACTIVE,
    ACTIVE,
    GRACE_PERIOD,
    EXPIRED
}

static func is_valid(value: int) -> bool:
    match value:
        Value.INACTIVE:
            return true
        Value.ACTIVE:
            return true
        Value.GRACE_PERIOD:
            return true
        Value.EXPIRED:
            return true
        _:
            return false

static func assert_valid(value: int) -> void:
    Validation.require_condition(is_valid(value), "Unsupported subscription status.")