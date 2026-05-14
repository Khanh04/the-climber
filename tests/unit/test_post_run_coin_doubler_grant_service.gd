extends GutTest

const CoinTransactionLedgerScript = preload("res://src/economy/coin_transaction_ledger.gd")
const PersistentCoinTransactionServiceScript = preload("res://src/economy/persistent_coin_transaction_service.gd")
const PostRunCoinDoublerGrantServiceScript = preload("res://src/economy/post_run_coin_doubler_grant_service.gd")
const RewardedAdOutcomeScript = preload("res://src/platform/ads/rewarded_ad_outcome.gd")
const RewardedAdPlacementScript = preload("res://src/platform/ads/rewarded_ad_placement.gd")
const RewardedAdResultScript = preload("res://src/platform/ads/rewarded_ad_result.gd")
const WalletScript = preload("res://src/economy/wallet.gd")
const WalletTransactionServiceScript = preload("res://src/economy/wallet_transaction_service.gd")

func test_post_run_coin_doubler_grant_service_applies_completed_reward_once() -> void:
	var wallet: WalletScript = WalletScript.new(3)
	var persistent_ledger: CoinTransactionLedgerScript = CoinTransactionLedgerScript.new()
	var wallet_transaction_service: WalletTransactionServiceScript = WalletTransactionServiceScript.new()
	var persistent_coin_transaction_service: PersistentCoinTransactionServiceScript = PersistentCoinTransactionServiceScript.new()
	var service: PostRunCoinDoublerGrantServiceScript = PostRunCoinDoublerGrantServiceScript.new()
	var rewarded_ad_result: RewardedAdResultScript = RewardedAdResultScript.new(
		RewardedAdPlacementScript.Value.POST_RUN_COIN_DOUBLER,
		RewardedAdOutcomeScript.Value.COMPLETED,
		true
	)

	assert_true(service.apply_reward(
		wallet,
		persistent_ledger,
		wallet_transaction_service,
		persistent_coin_transaction_service,
		rewarded_ad_result,
		"summary_01",
		6
	))
	assert_eq(wallet.get_coins(), 9)
	assert_true(persistent_ledger.has_transaction_id("ad_reward:post_run_coin_doubler:summary_01"))
	assert_false(service.apply_reward(
		wallet,
		persistent_ledger,
		wallet_transaction_service,
		persistent_coin_transaction_service,
		rewarded_ad_result,
		"summary_01",
		6
	))
	assert_eq(wallet.get_coins(), 9)

func test_post_run_coin_doubler_grant_service_ignores_cancelled_results() -> void:
	var wallet: WalletScript = WalletScript.new(4)
	var persistent_ledger: CoinTransactionLedgerScript = CoinTransactionLedgerScript.new()
	var wallet_transaction_service: WalletTransactionServiceScript = WalletTransactionServiceScript.new()
	var persistent_coin_transaction_service: PersistentCoinTransactionServiceScript = PersistentCoinTransactionServiceScript.new()
	var service: PostRunCoinDoublerGrantServiceScript = PostRunCoinDoublerGrantServiceScript.new()
	var rewarded_ad_result: RewardedAdResultScript = RewardedAdResultScript.new(
		RewardedAdPlacementScript.Value.POST_RUN_COIN_DOUBLER,
		RewardedAdOutcomeScript.Value.CANCELLED,
		false
	)

	assert_false(service.apply_reward(
		wallet,
		persistent_ledger,
		wallet_transaction_service,
		persistent_coin_transaction_service,
		rewarded_ad_result,
		"summary_02",
		5
	))
	assert_eq(wallet.get_coins(), 4)
	assert_eq(persistent_ledger.get_transaction_ids(), PackedStringArray())