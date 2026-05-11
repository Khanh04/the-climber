class_name StaminaRuntime
extends RefCounted

const StaminaTuningScript = preload("res://resources/config/stamina_tuning.gd")

var _tuning: StaminaTuningScript
var _current_stamina_seconds: float = 0.0

func _init(tuning: RefCounted) -> void:
    Validation.require_condition(tuning != null, "StaminaRuntime requires a stamina tuning resource.")
    Validation.require_condition(tuning is StaminaTuningScript, "StaminaRuntime requires a stamina tuning resource implementation.")

    _tuning = tuning
    _tuning.assert_valid()
    restore_full()

func get_current_stamina_seconds() -> float:
    return _current_stamina_seconds

func get_max_stamina_seconds() -> float:
    return _tuning.one_hand_seconds

func is_depleted() -> bool:
    return _current_stamina_seconds <= 0.0

func restore_full() -> void:
    _current_stamina_seconds = _tuning.one_hand_seconds

func advance(attached_hand_count: int, delta_seconds: float, drain_multiplier: float = 1.0) -> bool:
    Validation.require_condition(attached_hand_count >= 0 and attached_hand_count <= 2, "StaminaRuntime attached hand count must be between 0 and 2.")
    Validation.require_condition(delta_seconds >= 0.0, "StaminaRuntime delta seconds cannot be negative.")
    Validation.require_condition(drain_multiplier > 0.0, "StaminaRuntime drain multiplier must be positive.")

    if attached_hand_count != 1:
        return false

    if is_depleted():
        return false

    var next_stamina_seconds: float = _current_stamina_seconds - (delta_seconds * drain_multiplier)
    var depleted_now: bool = next_stamina_seconds <= 0.0

    if depleted_now:
        _current_stamina_seconds = 0.0
        return true

    _current_stamina_seconds = next_stamina_seconds
    return false