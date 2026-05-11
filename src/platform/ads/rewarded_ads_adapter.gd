class_name RewardedAdsAdapter
extends RefCounted

const RewardedAdOutcomeScript = preload("res://src/platform/ads/rewarded_ad_outcome.gd")
const RewardedAdPlacementScript = preload("res://src/platform/ads/rewarded_ad_placement.gd")
const RewardedAdResultScript = preload("res://src/platform/ads/rewarded_ad_result.gd")

func can_show(placement_value: int) -> bool:
    RewardedAdPlacementScript.assert_valid(placement_value)
    Validation.require_condition(false, "RewardedAdsAdapter.can_show must be implemented.")
    return false

func show(placement_value: int) -> RefCounted:
    RewardedAdPlacementScript.assert_valid(placement_value)
    Validation.require_condition(false, "RewardedAdsAdapter.show must be implemented.")
    return RewardedAdResultScript.new(placement_value, RewardedAdOutcomeScript.Value.UNAVAILABLE, false)