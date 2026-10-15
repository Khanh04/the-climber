class_name EconomyTuning
extends Resource

## Coins granted each day to Supporter subscribers. Amount still open (docs/04). Not yet read at runtime.
@export var supporter_daily_coin_reward: int = 100
## Most special-stack coin physics bodies alive at once. Not yet read at runtime.
@export var special_stack_active_coin_body_cap: int = 24

func is_valid() -> bool:
    return supporter_daily_coin_reward > 0 and special_stack_active_coin_body_cap > 0

func validate() -> void:
    assert_valid()

func assert_valid() -> void:
    Validation.require_condition(supporter_daily_coin_reward > 0, "Supporter daily coin reward must be positive.")
    Validation.require_condition(special_stack_active_coin_body_cap > 0, "Special coin stack body cap must be positive.")