class_name RunStateTransitions
extends RefCounted

const RunStateScript = preload("res://src/gameplay/run/run_state.gd")

static func is_transition_allowed(from_state: int, to_state: int) -> bool:
    if not RunStateScript.is_valid(from_state):
        return false

    if not RunStateScript.is_valid(to_state):
        return false

    match from_state:
        RunStateScript.Value.READY:
            return to_state == RunStateScript.Value.CLIMBING
        RunStateScript.Value.CLIMBING:
            return to_state == RunStateScript.Value.FALLING or to_state == RunStateScript.Value.ENDED
        RunStateScript.Value.FALLING:
            return to_state == RunStateScript.Value.RESCUE_OFFERED or to_state == RunStateScript.Value.ENDED
        RunStateScript.Value.RESCUE_OFFERED:
            return to_state == RunStateScript.Value.CLIMBING or to_state == RunStateScript.Value.ENDED
        RunStateScript.Value.ENDED:
            return to_state == RunStateScript.Value.READY
        _:
            return false

static func assert_transition_allowed(from_state: int, to_state: int) -> void:
    RunStateScript.assert_valid(from_state)
    RunStateScript.assert_valid(to_state)
    Validation.require_condition(
        is_transition_allowed(from_state, to_state),
        "Unsupported run state transition."
    )