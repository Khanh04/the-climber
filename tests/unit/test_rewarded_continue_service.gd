extends GutTest

const RewardedContinueServiceScript = preload("res://src/gameplay/run/rewarded_continue_service.gd")
const RewardedAdOutcomeScript = preload("res://src/platform/ads/rewarded_ad_outcome.gd")
const RewardedAdPlacementScript = preload("res://src/platform/ads/rewarded_ad_placement.gd")
const RewardedAdResultScript = preload("res://src/platform/ads/rewarded_ad_result.gd")
const RunEndReasonScript = preload("res://src/core/run_end_reason.gd")
const RunSessionScript = preload("res://src/gameplay/run/run_session.gd")
const RunStateScript = preload("res://src/gameplay/run/run_state.gd")

func test_rewarded_continue_service_consumes_rescue_for_completed_continue_results() -> void:
	var service: RewardedContinueServiceScript = RewardedContinueServiceScript.new()
	var run_session: RunSessionScript = _build_rescue_offered_run_session()
	var rewarded_ad_result: RewardedAdResultScript = RewardedAdResultScript.new(
		RewardedAdPlacementScript.Value.CONTINUE,
		RewardedAdOutcomeScript.Value.COMPLETED,
		true
	)

	assert_true(service.apply_reward(run_session, rewarded_ad_result))
	assert_eq(run_session.get_state(), RunStateScript.Value.CLIMBING)
	assert_true(run_session.has_used_rescue())
	assert_false(run_session.has_end_reason())

func test_rewarded_continue_service_ignores_non_completed_continue_results() -> void:
	var outcomes: Array[int] = [
		RewardedAdOutcomeScript.Value.CANCELLED,
		RewardedAdOutcomeScript.Value.FAILED,
		RewardedAdOutcomeScript.Value.UNAVAILABLE,
	]

	for outcome: int in outcomes:
		var service: RewardedContinueServiceScript = RewardedContinueServiceScript.new()
		var run_session: RunSessionScript = _build_rescue_offered_run_session()
		var rewarded_ad_result: RewardedAdResultScript = RewardedAdResultScript.new(
			RewardedAdPlacementScript.Value.CONTINUE,
			outcome,
			false
		)

		assert_false(service.apply_reward(run_session, rewarded_ad_result))
		assert_eq(run_session.get_state(), RunStateScript.Value.RESCUE_OFFERED)
		assert_false(run_session.has_used_rescue())
		assert_true(run_session.has_end_reason())
		assert_eq(run_session.get_end_reason(), RunEndReasonScript.Value.BOTTOM_SCREEN_FALL)

func _build_rescue_offered_run_session() -> RunSessionScript:
	var run_session: RunSessionScript = RunSessionScript.new()
	run_session.start_run()
	run_session.begin_fall()
	run_session.resolve_fall(RunEndReasonScript.Value.BOTTOM_SCREEN_FALL)
	assert_eq(run_session.get_state(), RunStateScript.Value.RESCUE_OFFERED)
	return run_session