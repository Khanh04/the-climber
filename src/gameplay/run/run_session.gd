class_name RunSession
extends RefCounted

const RescueEligibilityScript = preload("res://src/gameplay/run/rescue_eligibility.gd")
const RunEndReasonScript = preload("res://src/core/run_end_reason.gd")
const RunStateScript = preload("res://src/gameplay/run/run_state.gd")
const RunStateTransitionsScript = preload("res://src/gameplay/run/run_state_transitions.gd")

var _state: int = RunStateScript.Value.READY
var _height_meters: float = 0.0
var _run_earned_coins: int = 0
var _rescue_used: bool = false
var _has_end_reason: bool = false
var _end_reason: int = -1

func get_state() -> int:
    return _state

func get_height_meters() -> float:
    return _height_meters

func get_run_earned_coins() -> int:
    return _run_earned_coins

func has_used_rescue() -> bool:
    return _rescue_used

func has_end_reason() -> bool:
    return _has_end_reason

func get_end_reason() -> int:
    Validation.require_condition(_has_end_reason, "Run session does not have an end reason.")
    return _end_reason

func start_run() -> void:
    _transition_to(RunStateScript.Value.CLIMBING)
    _height_meters = 0.0
    _run_earned_coins = 0
    _rescue_used = false
    _clear_end_reason()

func record_height(height_meters: float) -> void:
    Validation.require_condition(height_meters >= 0.0, "Run session height cannot be negative.")
    Validation.require_condition(_is_run_active(), "Run session height can only update during an active run.")
    if height_meters > _height_meters:
        _height_meters = height_meters

func add_run_earned_coins(amount: int) -> void:
    Validation.require_condition(amount > 0, "Run session coin gains must be positive.")
    Validation.require_condition(_is_run_active(), "Run session coins can only update during an active run.")
    _run_earned_coins += amount

func begin_stamina_fall() -> void:
    Validation.require_condition(_state == RunStateScript.Value.CLIMBING, "Run session can only begin a stamina fall while climbing.")
    begin_fall()

func begin_fall() -> void:
    _transition_to(RunStateScript.Value.FALLING)

func resolve_stamina_fall() -> void:
    resolve_fall(RunEndReasonScript.Value.STAMINA_FALL)

func resolve_fall(reason: int) -> void:
    Validation.require_condition(_state == RunStateScript.Value.FALLING, "Run session can only resolve a fall while falling.")
    Validation.require_condition(RunEndReasonScript.is_fall_reason(reason), "Run session can only resolve fall end reasons while falling.")
    _set_end_reason(reason)

    if RescueEligibilityScript.is_rescue_eligible(reason, _rescue_used):
        _transition_to(RunStateScript.Value.RESCUE_OFFERED)
        return

    _transition_to(RunStateScript.Value.ENDED)

func end_run(reason: int) -> void:
    RunEndReasonScript.assert_valid(reason)
    Validation.require_condition(
        _state == RunStateScript.Value.CLIMBING or _state == RunStateScript.Value.FALLING or _state == RunStateScript.Value.RESCUE_OFFERED,
        "Run session can only end from an active or rescue-offered state."
    )
    _set_end_reason(reason)
    _transition_to(RunStateScript.Value.ENDED)

func consume_rescue() -> void:
    Validation.require_condition(_state == RunStateScript.Value.RESCUE_OFFERED, "Run session can only consume a rescue from the rescue-offered state.")
    Validation.require_condition(not _rescue_used, "Run session rescue has already been used.")
    _rescue_used = true
    _clear_end_reason()
    _transition_to(RunStateScript.Value.CLIMBING)

func decline_rescue() -> void:
    Validation.require_condition(_state == RunStateScript.Value.RESCUE_OFFERED, "Run session can only decline a rescue from the rescue-offered state.")
    Validation.require_condition(_has_end_reason, "Run session rescue decline requires an end reason.")
    _transition_to(RunStateScript.Value.ENDED)

func reset() -> void:
    _transition_to(RunStateScript.Value.READY)
    _height_meters = 0.0
    _run_earned_coins = 0
    _rescue_used = false
    _clear_end_reason()

func _transition_to(next_state: int) -> void:
    RunStateTransitionsScript.assert_transition_allowed(_state, next_state)
    _state = next_state

func _set_end_reason(reason: int) -> void:
    RunEndReasonScript.assert_valid(reason)
    _end_reason = reason
    _has_end_reason = true

func _clear_end_reason() -> void:
    _end_reason = -1
    _has_end_reason = false

func _is_run_active() -> bool:
    return _state == RunStateScript.Value.CLIMBING or _state == RunStateScript.Value.FALLING or _state == RunStateScript.Value.RESCUE_OFFERED