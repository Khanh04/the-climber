class_name StaminaTuning
extends Resource

## Seconds a player can hang from one hand before stamina runs out and they fall.
## A character's max-stamina multiplier scales this. Higher is more forgiving.
@export var one_hand_seconds: float = 8.0
## Drain multiplier for greasy ledges. Must be at least 1.0.
## Per-hold drain now comes from handhold_type_definition_catalog.tres; this is only validated.
@export var greasy_ledge_drain_multiplier: float = 3.0
## Stamina seconds regained per second while both hands are attached.
@export var two_hand_regen_seconds_per_second: float = 0.0

func is_valid() -> bool:
    return one_hand_seconds > 0.0 and greasy_ledge_drain_multiplier >= 1.0 and two_hand_regen_seconds_per_second >= 0.0

func validate() -> void:
    assert_valid()

func assert_valid() -> void:
    Validation.require_condition(one_hand_seconds > 0.0, "One-hand stamina duration must be positive.")
    Validation.require_condition(greasy_ledge_drain_multiplier >= 1.0, "Greasy ledge drain multiplier must be at least 1.0.")
    Validation.require_condition(two_hand_regen_seconds_per_second >= 0.0, "Two-hand stamina regen cannot be negative.")
