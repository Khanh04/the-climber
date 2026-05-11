class_name RescueEligibility
extends RefCounted

static func is_rescue_eligible(reason: RunEndReason.Value, already_rescued: bool) -> bool:
    if already_rescued:
        return false

    match reason:
        RunEndReason.Value.BOTTOM_SCREEN_FALL:
            return true
        RunEndReason.Value.STAMINA_FALL:
            return true
        RunEndReason.Value.MISSED_GRIP_FALL:
            return true
        RunEndReason.Value.CHASER_CONTACT:
            return false
        RunEndReason.Value.LETHAL_HAZARD:
            return false
        RunEndReason.Value.ALREADY_RESCUED:
            return false
        _:
            Validation.require_condition(false, "Unsupported run end reason for rescue eligibility.")
            return false