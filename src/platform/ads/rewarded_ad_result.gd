class_name RewardedAdResult
extends RefCounted

const RewardedAdOutcomeScript = preload("res://src/platform/ads/rewarded_ad_outcome.gd")
const RewardedAdPlacementScript = preload("res://src/platform/ads/rewarded_ad_placement.gd")

var placement: int
var outcome: int
var reward_granted: bool

func _init(placement_value: int, outcome_value: int, reward_granted_value: bool = false) -> void:
    placement = placement_value
    outcome = outcome_value
    reward_granted = reward_granted_value
    assert_valid()

func is_valid() -> bool:
    if not RewardedAdPlacementScript.is_valid(placement):
        return false

    if not RewardedAdOutcomeScript.is_valid(outcome):
        return false

    if outcome == RewardedAdOutcomeScript.Value.COMPLETED:
        return reward_granted

    return not reward_granted

func assert_valid() -> void:
    RewardedAdPlacementScript.assert_valid(placement)
    RewardedAdOutcomeScript.assert_valid(outcome)

    if outcome == RewardedAdOutcomeScript.Value.COMPLETED:
        Validation.require_condition(reward_granted, "Completed rewarded ads must grant a reward.")
        return

    Validation.require_condition(not reward_granted, "Non-completed rewarded ads cannot grant a reward.")