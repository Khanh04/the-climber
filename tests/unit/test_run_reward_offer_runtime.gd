extends GutTest

const CoinTransactionLedgerScript = preload("res://src/economy/coin_transaction_ledger.gd")
const PostRunCoinDoublerGrantServiceScript = preload("res://src/economy/post_run_coin_doubler_grant_service.gd")
const RewardedAdOutcomeScript = preload("res://src/platform/ads/rewarded_ad_outcome.gd")
const RewardedAdPlacementScript = preload("res://src/platform/ads/rewarded_ad_placement.gd")
const RewardedAdResultScript = preload("res://src/platform/ads/rewarded_ad_result.gd")
const RewardedAdsAdapterScript = preload("res://src/platform/ads/rewarded_ads_adapter.gd")
const RunEndReasonScript = preload("res://src/core/run_end_reason.gd")
const RunRewardOfferRuntimeScript = preload("res://src/gameplay/run/run_reward_offer_runtime.gd")
const RunSessionScript = preload("res://src/gameplay/run/run_session.gd")

class StubRewardedAdsAdapter extends RewardedAdsAdapterScript:
	var _can_show_continue: bool
	var _can_show_post_run_coin_doubler: bool

	func _init(can_show_continue: bool = false, can_show_post_run_coin_doubler: bool = false) -> void:
		_can_show_continue = can_show_continue
		_can_show_post_run_coin_doubler = can_show_post_run_coin_doubler

	func can_show(placement_value: int) -> bool:
		RewardedAdPlacementScript.assert_valid(placement_value)
		match placement_value:
			RewardedAdPlacementScript.Value.CONTINUE:
				return _can_show_continue
			RewardedAdPlacementScript.Value.POST_RUN_COIN_DOUBLER:
				return _can_show_post_run_coin_doubler
			_:
				return false

	func show(placement_value: int) -> RefCounted:
		RewardedAdPlacementScript.assert_valid(placement_value)
		return RewardedAdResultScript.new(placement_value, RewardedAdOutcomeScript.Value.UNAVAILABLE, false)

func test_can_offer_post_run_coin_doubler_returns_false_before_run_end_without_building_reward_id() -> void:
	var runtime: RunRewardOfferRuntimeScript = RunRewardOfferRuntimeScript.new()
	var run_session: RunSessionScript = _build_rescue_offered_run_session()
	var rewarded_ads_adapter: StubRewardedAdsAdapter = StubRewardedAdsAdapter.new(true, true)
	var persistent_transaction_ledger: CoinTransactionLedgerScript = CoinTransactionLedgerScript.new()
	var grant_service: PostRunCoinDoublerGrantServiceScript = PostRunCoinDoublerGrantServiceScript.new()

	assert_false(runtime.can_offer_post_run_coin_doubler(
		run_session,
		rewarded_ads_adapter,
		persistent_transaction_ledger,
		grant_service,
		""
	))

func test_can_offer_post_run_coin_doubler_derives_stable_reward_id_after_run_end() -> void:
	var runtime: RunRewardOfferRuntimeScript = RunRewardOfferRuntimeScript.new()
	var run_session: RunSessionScript = RunSessionScript.new()
	var rewarded_ads_adapter: StubRewardedAdsAdapter = StubRewardedAdsAdapter.new(false, true)
	var persistent_transaction_ledger: CoinTransactionLedgerScript = CoinTransactionLedgerScript.new()
	var grant_service: PostRunCoinDoublerGrantServiceScript = PostRunCoinDoublerGrantServiceScript.new()

	run_session.start_run()
	run_session.add_run_earned_coins(9)
	run_session.end_run(RunEndReasonScript.Value.CHASER_CONTACT)

	assert_true(runtime.can_offer_post_run_coin_doubler(
		run_session,
		rewarded_ads_adapter,
		persistent_transaction_ledger,
		grant_service,
		""
	))

	var generated_reward_id: String = runtime.get_or_create_post_run_coin_doubler_reward_id(run_session, "")
	assert_eq(generated_reward_id, "run_summary_%s" % str(run_session.get_instance_id()))
	var _recorded_transaction: bool = persistent_transaction_ledger.record_transaction_id(
		grant_service.build_transaction_id(generated_reward_id)
	)

	assert_false(runtime.can_offer_post_run_coin_doubler(
		run_session,
		rewarded_ads_adapter,
		persistent_transaction_ledger,
		grant_service,
		""
	))

func _build_rescue_offered_run_session() -> RunSessionScript:
	var run_session: RunSessionScript = RunSessionScript.new()
	run_session.start_run()
	run_session.begin_fall()
	run_session.resolve_fall(RunEndReasonScript.Value.BOTTOM_SCREEN_FALL)
	assert_eq(run_session.get_state(), 3)
	return run_session