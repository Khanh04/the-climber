class_name RunEndReason
extends RefCounted

enum Value {
    BOTTOM_SCREEN_FALL,
    STAMINA_FALL,
    MISSED_GRIP_FALL,
    CHASER_CONTACT,
    LETHAL_HAZARD,
    ALREADY_RESCUED
}

static func is_valid(reason: int) -> bool:
    match reason:
        Value.BOTTOM_SCREEN_FALL:
            return true
        Value.STAMINA_FALL:
            return true
        Value.MISSED_GRIP_FALL:
            return true
        Value.CHASER_CONTACT:
            return true
        Value.LETHAL_HAZARD:
            return true
        Value.ALREADY_RESCUED:
            return true
        _:
            return false

static func assert_valid(reason: int) -> void:
    Validation.require_condition(is_valid(reason), "Unsupported run end reason.")

static func is_fall_reason(reason: int) -> bool:
    match reason:
        Value.BOTTOM_SCREEN_FALL:
            return true
        Value.STAMINA_FALL:
            return true
        Value.MISSED_GRIP_FALL:
            return true
        _:
            return false