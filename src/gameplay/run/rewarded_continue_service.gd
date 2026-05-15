class_name RewardedContinueService
extends RefCounted

const RewardedAdOutcomeScript = preload("res://src/platform/ads/rewarded_ad_outcome.gd")
const RewardedAdPlacementScript = preload("res://src/platform/ads/rewarded_ad_placement.gd")
const RewardedAdResultScript = preload("res://src/platform/ads/rewarded_ad_result.gd")
const RunSessionScript = preload("res://src/gameplay/run/run_session.gd")

func apply_reward(run_session: RefCounted, rewarded_ad_result: RefCounted) -> bool:
	Validation.require_condition(run_session != null, "RewardedContinueService requires a run session.")
	Validation.require_condition(run_session is RunSessionScript, "RewardedContinueService requires a RunSession implementation.")
	Validation.require_condition(rewarded_ad_result != null, "RewardedContinueService requires a rewarded ad result.")
	Validation.require_condition(rewarded_ad_result is RewardedAdResultScript, "RewardedContinueService requires a RewardedAdResult implementation.")

	var typed_run_session: RunSessionScript = run_session as RunSessionScript
	var typed_rewarded_ad_result: RewardedAdResultScript = rewarded_ad_result as RewardedAdResultScript
	typed_rewarded_ad_result.assert_valid()
	Validation.require_condition(
		typed_rewarded_ad_result.placement == RewardedAdPlacementScript.Value.CONTINUE,
		"RewardedContinueService requires the Continue placement."
	)
	if typed_rewarded_ad_result.outcome != RewardedAdOutcomeScript.Value.COMPLETED:
		return false

	typed_run_session.consume_rescue()
	return true