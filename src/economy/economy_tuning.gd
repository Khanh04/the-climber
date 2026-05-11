class_name EconomyTuning
extends Resource

@export var supporter_daily_coin_reward: int = 100
@export var rewarded_continue_max_per_run: int = 1
@export var post_run_coin_doubler_max_per_summary: int = 1
@export var pre_run_vending_max_per_run: int = 1
@export var special_stack_active_coin_body_cap: int = 24

func is_valid() -> bool:
    return supporter_daily_coin_reward > 0 \
        and rewarded_continue_max_per_run == 1 \
        and post_run_coin_doubler_max_per_summary == 1 \
        and pre_run_vending_max_per_run == 1 \
        and special_stack_active_coin_body_cap > 0

func assert_valid() -> void:
    Validation.require_condition(supporter_daily_coin_reward > 0, "Supporter daily coin reward must be positive.")
    Validation.require_condition(rewarded_continue_max_per_run == 1, "Rewarded Continue must be capped at once per run for MVP.")
    Validation.require_condition(post_run_coin_doubler_max_per_summary == 1, "Post-run Coin Doubler must be capped at once per summary.")
    Validation.require_condition(pre_run_vending_max_per_run == 1, "Pre-run Vending Machine must be capped at once per run.")
    Validation.require_condition(special_stack_active_coin_body_cap > 0, "Special coin stack body cap must be positive.")