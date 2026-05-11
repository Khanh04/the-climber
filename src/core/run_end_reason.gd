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

static func is_fall_reason(reason: Value) -> bool:
    match reason:
        Value.BOTTOM_SCREEN_FALL:
            return true
        Value.STAMINA_FALL:
            return true
        Value.MISSED_GRIP_FALL:
            return true
        _:
            return false