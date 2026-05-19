class_name RunRewardOfferRuntime
extends RefCounted

const CoinTransactionLedgerScript = preload("res://src/economy/coin_transaction_ledger.gd")
const PostRunCoinDoublerGrantServiceScript = preload("res://src/economy/post_run_coin_doubler_grant_service.gd")
const RewardedAdsAdapterScript = preload("res://src/platform/ads/rewarded_ads_adapter.gd")
const RewardedAdPlacementScript = preload("res://src/platform/ads/rewarded_ad_placement.gd")
const RunSessionScript = preload("res://src/gameplay/run/run_session.gd")
const RunStateScript = preload("res://src/gameplay/run/run_state.gd")

func can_offer_rewarded_continue(run_session: RefCounted, rewarded_ads_adapter: RefCounted) -> bool:
	var typed_run_session: RunSessionScript = _require_run_session(run_session)
	var typed_rewarded_ads_adapter: RewardedAdsAdapterScript = _require_rewarded_ads_adapter(rewarded_ads_adapter)
	if typed_run_session.get_state() != RunStateScript.Value.RESCUE_OFFERED:
		return false

	return typed_rewarded_ads_adapter.can_show(RewardedAdPlacementScript.Value.CONTINUE)

func can_offer_post_run_coin_doubler(
	run_session: RefCounted,
	rewarded_ads_adapter: RefCounted,
	persistent_transaction_ledger: RefCounted,
	post_run_coin_doubler_grant_service: RefCounted,
	current_reward_id: String
) -> bool:
	var typed_run_session: RunSessionScript = _require_run_session(run_session)
	var typed_rewarded_ads_adapter: RewardedAdsAdapterScript = _require_rewarded_ads_adapter(rewarded_ads_adapter)
	var typed_persistent_transaction_ledger: CoinTransactionLedgerScript = _require_persistent_transaction_ledger(persistent_transaction_ledger)
	var typed_post_run_coin_doubler_grant_service: PostRunCoinDoublerGrantServiceScript = _require_post_run_coin_doubler_grant_service(post_run_coin_doubler_grant_service)

	if typed_run_session.get_state() != RunStateScript.Value.ENDED:
		return false

	if typed_run_session.get_run_earned_coins() <= 0:
		return false

	if not typed_rewarded_ads_adapter.can_show(RewardedAdPlacementScript.Value.POST_RUN_COIN_DOUBLER):
		return false

	var reward_id: String = get_or_create_post_run_coin_doubler_reward_id(typed_run_session, current_reward_id)
	var transaction_id: String = typed_post_run_coin_doubler_grant_service.build_transaction_id(reward_id)
	return not typed_persistent_transaction_ledger.has_transaction_id(transaction_id)

func get_or_create_post_run_coin_doubler_reward_id(run_session: RefCounted, current_reward_id: String) -> String:
	var typed_run_session: RunSessionScript = _require_run_session(run_session)
	Validation.require_condition(
		typed_run_session.get_state() == RunStateScript.Value.ENDED,
		"RunRewardOfferRuntime can only build a post-run coin doubler reward id after the run has ended."
	)
	if not current_reward_id.is_empty():
		return current_reward_id

	return "run_summary_%s" % str(typed_run_session.get_instance_id())

func bind_post_run_coin_doubler_reward_id(current_reward_id: String, reward_id: String) -> String:
	Validation.require_condition(not reward_id.is_empty(), "RunRewardOfferRuntime post-run coin doubler reward id cannot be empty.")
	if current_reward_id.is_empty():
		return reward_id

	Validation.require_condition(
		current_reward_id == reward_id,
		"RunRewardOfferRuntime post-run coin doubler reward id must remain stable for the current run summary."
	)
	return current_reward_id

func _require_run_session(run_session: RefCounted) -> RunSessionScript:
	Validation.require_condition(run_session != null, "RunRewardOfferRuntime requires a run session.")
	Validation.require_condition(run_session is RunSessionScript, "RunRewardOfferRuntime requires RunSession.")
	return run_session as RunSessionScript

func _require_rewarded_ads_adapter(rewarded_ads_adapter: RefCounted) -> RewardedAdsAdapterScript:
	Validation.require_condition(rewarded_ads_adapter != null, "RunRewardOfferRuntime requires a rewarded ads adapter.")
	Validation.require_condition(rewarded_ads_adapter is RewardedAdsAdapterScript, "RunRewardOfferRuntime requires RewardedAdsAdapter.")
	return rewarded_ads_adapter as RewardedAdsAdapterScript

func _require_persistent_transaction_ledger(persistent_transaction_ledger: RefCounted) -> CoinTransactionLedgerScript:
	Validation.require_condition(persistent_transaction_ledger != null, "RunRewardOfferRuntime requires a persistent transaction ledger.")
	Validation.require_condition(persistent_transaction_ledger is CoinTransactionLedgerScript, "RunRewardOfferRuntime requires CoinTransactionLedger.")
	return persistent_transaction_ledger as CoinTransactionLedgerScript

func _require_post_run_coin_doubler_grant_service(post_run_coin_doubler_grant_service: RefCounted) -> PostRunCoinDoublerGrantServiceScript:
	Validation.require_condition(post_run_coin_doubler_grant_service != null, "RunRewardOfferRuntime requires a post-run coin doubler grant service.")
	Validation.require_condition(
		post_run_coin_doubler_grant_service is PostRunCoinDoublerGrantServiceScript,
		"RunRewardOfferRuntime requires PostRunCoinDoublerGrantService."
	)
	return post_run_coin_doubler_grant_service as PostRunCoinDoublerGrantServiceScript