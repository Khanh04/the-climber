class_name RewardedAdsTuning
extends Resource

## Rewarded Continue offers allowed per run. Not yet read at runtime.
@export var rewarded_continue_max_per_run: int = 1
## Coin Doubler offers allowed per run-end summary. Not yet read at runtime.
@export var post_run_coin_doubler_max_per_summary: int = 1
## Pre-run Vending Machine uses allowed before each run. Not yet read at runtime.
@export var pre_run_vending_max_per_run: int = 1
## Seconds to hide ad offers after the player watches an ad, to avoid ad fatigue. Not yet read at runtime.
@export var fatigue_suppression_seconds: float = 90.0

func is_valid() -> bool:
    return rewarded_continue_max_per_run == 1 \
        and post_run_coin_doubler_max_per_summary == 1 \
        and pre_run_vending_max_per_run == 1 \
        and fatigue_suppression_seconds >= 0.0

func validate() -> void:
    assert_valid()

func assert_valid() -> void:
    Validation.require_condition(rewarded_continue_max_per_run == 1, "Rewarded Continue must be capped at once per run for MVP.")
    Validation.require_condition(post_run_coin_doubler_max_per_summary == 1, "Post-run Coin Doubler must be capped at once per summary.")
    Validation.require_condition(pre_run_vending_max_per_run == 1, "Pre-run Vending Machine must be capped at once per run.")
    Validation.require_condition(fatigue_suppression_seconds >= 0.0, "Rewarded ad fatigue suppression seconds cannot be negative.")