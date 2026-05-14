extends GutTest

const CoinTransactionLedgerScript = preload("res://src/economy/coin_transaction_ledger.gd")
const PersistentCoinTransactionServiceScript = preload("res://src/economy/persistent_coin_transaction_service.gd")
const TransactionSourceScript = preload("res://src/economy/transaction_source.gd")
const WalletScript = preload("res://src/economy/wallet.gd")
const WalletTransactionServiceScript = preload("res://src/economy/wallet_transaction_service.gd")

func test_persistent_coin_transaction_service_applies_non_pickup_transactions_once() -> void:
	var wallet: WalletScript = WalletScript.new()
	var persistent_ledger: CoinTransactionLedgerScript = CoinTransactionLedgerScript.new()
	var wallet_transaction_service: WalletTransactionServiceScript = WalletTransactionServiceScript.new()
	var service: PersistentCoinTransactionServiceScript = PersistentCoinTransactionServiceScript.new()

	assert_true(service.apply_persistent_transaction(
		wallet,
		persistent_ledger,
		wallet_transaction_service,
		"ad_reward:daily_reward_2026-05-14",
		TransactionSourceScript.Value.AD_REWARD,
		12
	))
	assert_eq(wallet.get_coins(), 12)
	assert_true(persistent_ledger.has_transaction_id("ad_reward:daily_reward_2026-05-14"))
	assert_false(service.apply_persistent_transaction(
		wallet,
		persistent_ledger,
		wallet_transaction_service,
		"ad_reward:daily_reward_2026-05-14",
		TransactionSourceScript.Value.AD_REWARD,
		12
	))
	assert_eq(wallet.get_coins(), 12)

func test_persistent_coin_transaction_service_supports_coin_spends() -> void:
	var wallet: WalletScript = WalletScript.new(15)
	var persistent_ledger: CoinTransactionLedgerScript = CoinTransactionLedgerScript.new()
	var wallet_transaction_service: WalletTransactionServiceScript = WalletTransactionServiceScript.new()
	var service: PersistentCoinTransactionServiceScript = PersistentCoinTransactionServiceScript.new()

	assert_true(service.apply_persistent_transaction(
		wallet,
		persistent_ledger,
		wallet_transaction_service,
		"grant:refund_reversal_01",
		TransactionSourceScript.Value.GRANT,
		-4
	))
	assert_eq(wallet.get_coins(), 11)

func test_persistent_coin_transaction_service_supports_debug_dev_grants() -> void:
	var wallet: WalletScript = WalletScript.new()
	var persistent_ledger: CoinTransactionLedgerScript = CoinTransactionLedgerScript.new()
	var wallet_transaction_service: WalletTransactionServiceScript = WalletTransactionServiceScript.new()
	var service: PersistentCoinTransactionServiceScript = PersistentCoinTransactionServiceScript.new()

	assert_true(service.apply_persistent_transaction(
		wallet,
		persistent_ledger,
		wallet_transaction_service,
		"debug_dev:grant_01",
		TransactionSourceScript.Value.DEBUG_DEV,
		5
	))
	assert_eq(wallet.get_coins(), 5)
	assert_true(persistent_ledger.has_transaction_id("debug_dev:grant_01"))