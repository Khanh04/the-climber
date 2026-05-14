class_name PostRunCoinDoublerGrantService
extends RefCounted

const PersistentCoinTransactionServiceScript = preload("res://src/economy/persistent_coin_transaction_service.gd")
const RewardedAdOutcomeScript = preload("res://src/platform/ads/rewarded_ad_outcome.gd")
const RewardedAdPlacementScript = preload("res://src/platform/ads/rewarded_ad_placement.gd")
const RewardedAdResultScript = preload("res://src/platform/ads/rewarded_ad_result.gd")
const TransactionSourceScript = preload("res://src/economy/transaction_source.gd")

func build_transaction_id(reward_id: String) -> String:
	Validation.require_condition(not reward_id.is_empty(), "PostRunCoinDoublerGrantService reward id cannot be empty.")
	return "%s:post_run_coin_doubler:%s" % [TransactionSourceScript.to_label(TransactionSourceScript.Value.AD_REWARD), reward_id]

func apply_reward(
	wallet: RefCounted,
	persistent_transaction_ledger: RefCounted,
	wallet_transaction_service: RefCounted,
	persistent_coin_transaction_service: RefCounted,
	rewarded_ad_result: RefCounted,
	reward_id: String,
	run_coin_amount: int
) -> bool:
	Validation.require_condition(persistent_coin_transaction_service != null, "PostRunCoinDoublerGrantService requires a persistent coin transaction service.")
	Validation.require_condition(persistent_coin_transaction_service is PersistentCoinTransactionServiceScript, "PostRunCoinDoublerGrantService requires a PersistentCoinTransactionService implementation.")
	Validation.require_condition(rewarded_ad_result != null, "PostRunCoinDoublerGrantService requires a rewarded ad result.")
	Validation.require_condition(rewarded_ad_result is RewardedAdResultScript, "PostRunCoinDoublerGrantService requires a RewardedAdResult implementation.")
	Validation.require_condition(run_coin_amount > 0, "PostRunCoinDoublerGrantService run coin amount must be positive.")

	var typed_rewarded_ad_result: RewardedAdResultScript = rewarded_ad_result as RewardedAdResultScript
	typed_rewarded_ad_result.assert_valid()
	Validation.require_condition(
		typed_rewarded_ad_result.placement == RewardedAdPlacementScript.Value.POST_RUN_COIN_DOUBLER,
		"PostRunCoinDoublerGrantService requires the Post-run Coin Doubler placement."
	)
	if typed_rewarded_ad_result.outcome != RewardedAdOutcomeScript.Value.COMPLETED:
		return false

	var typed_persistent_coin_transaction_service: PersistentCoinTransactionServiceScript = persistent_coin_transaction_service as PersistentCoinTransactionServiceScript
	var transaction_id: String = build_transaction_id(reward_id)
	return typed_persistent_coin_transaction_service.apply_persistent_transaction(
		wallet,
		persistent_transaction_ledger,
		wallet_transaction_service,
		transaction_id,
		TransactionSourceScript.Value.AD_REWARD,
		run_coin_amount
	)