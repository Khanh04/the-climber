class_name StaminaTuning
extends Resource

@export var one_hand_seconds: float = 8.0
@export var greasy_ledge_drain_multiplier: float = 3.0

func is_valid() -> bool:
    return one_hand_seconds > 0.0 and greasy_ledge_drain_multiplier >= 1.0

func assert_valid() -> void:
    Validation.require_condition(one_hand_seconds > 0.0, "One-hand stamina duration must be positive.")
    Validation.require_condition(greasy_ledge_drain_multiplier >= 1.0, "Greasy ledge drain multiplier must be at least 1.0.")