class_name DesktopPreviewRewardedAdsAdapter
extends "res://src/platform/ads/rewarded_ads_adapter.gd"

func can_show(placement_value: int) -> bool:
    RewardedAdPlacementScript.assert_valid(placement_value)
    return true

func show(placement_value: int) -> RefCounted:
    RewardedAdPlacementScript.assert_valid(placement_value)
    return RewardedAdResultScript.new(placement_value, RewardedAdOutcomeScript.Value.COMPLETED, true)