class_name RewardedAdPlacement
extends RefCounted

enum Value {
    CONTINUE,
    POST_RUN_COIN_DOUBLER,
    PRE_RUN_VENDING_MACHINE
}

static func is_valid(value: int) -> bool:
    match value:
        Value.CONTINUE:
            return true
        Value.POST_RUN_COIN_DOUBLER:
            return true
        Value.PRE_RUN_VENDING_MACHINE:
            return true
        _:
            return false

static func assert_valid(value: int) -> void:
    Validation.require_condition(is_valid(value), "Unsupported rewarded ad placement.")