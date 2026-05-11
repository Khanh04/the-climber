class_name HapticFeedbackType
extends RefCounted

enum Value {
    LIGHT_IMPACT,
    MEDIUM_IMPACT,
    HEAVY_IMPACT,
    SUCCESS,
    WARNING,
    ERROR
}

static func is_valid(value: int) -> bool:
    match value:
        Value.LIGHT_IMPACT:
            return true
        Value.MEDIUM_IMPACT:
            return true
        Value.HEAVY_IMPACT:
            return true
        Value.SUCCESS:
            return true
        Value.WARNING:
            return true
        Value.ERROR:
            return true
        _:
            return false

static func assert_valid(value: int) -> void:
    Validation.require_condition(is_valid(value), "Unsupported haptic feedback type.")