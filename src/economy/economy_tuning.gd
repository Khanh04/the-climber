class_name EconomyTuning
extends Resource

@export var supporter_daily_coin_reward: int = 100
@export var special_stack_active_coin_body_cap: int = 24

func is_valid() -> bool:
    return supporter_daily_coin_reward > 0 and special_stack_active_coin_body_cap > 0

func validate() -> void:
    assert_valid()

func assert_valid() -> void:
    Validation.require_condition(supporter_daily_coin_reward > 0, "Supporter daily coin reward must be positive.")
    Validation.require_condition(special_stack_active_coin_body_cap > 0, "Special coin stack body cap must be positive.")