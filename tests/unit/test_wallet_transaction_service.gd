extends GutTest

const CoinTransactionLedgerScript = preload("res://src/economy/coin_transaction_ledger.gd")
const CoinTransactionScript = preload("res://src/economy/coin_transaction.gd")
const TransactionSourceScript = preload("res://src/economy/transaction_source.gd")
const WalletScript = preload("res://src/economy/wallet.gd")
const WalletTransactionServiceScript = preload("res://src/economy/wallet_transaction_service.gd")

func test_wallet_transaction_service_applies_grants_once() -> void:
	var wallet: WalletScript = WalletScript.new()
	var ledger: CoinTransactionLedgerScript = CoinTransactionLedgerScript.new()
	var service: WalletTransactionServiceScript = WalletTransactionServiceScript.new()
	var transaction: CoinTransactionScript = CoinTransactionScript.new(
		"pickup:chunk_02_pickup_01",
		TransactionSourceScript.Value.PICKUP,
		4
	)

	assert_true(service.apply_transaction(wallet, ledger, transaction))
	assert_eq(wallet.get_coins(), 4)
	assert_true(ledger.has_transaction_id("pickup:chunk_02_pickup_01"))
	assert_false(service.apply_transaction(wallet, ledger, transaction))
	assert_eq(wallet.get_coins(), 4)

func test_wallet_transaction_service_applies_spends_once() -> void:
	var wallet: WalletScript = WalletScript.new(10)
	var ledger: CoinTransactionLedgerScript = CoinTransactionLedgerScript.new()
	var service: WalletTransactionServiceScript = WalletTransactionServiceScript.new()
	var transaction: CoinTransactionScript = CoinTransactionScript.new(
		"purchase:hot_coffee",
		TransactionSourceScript.Value.PURCHASE,
		-3
	)

	assert_true(service.apply_transaction(wallet, ledger, transaction))
	assert_eq(wallet.get_coins(), 7)
	assert_true(ledger.has_transaction_id("purchase:hot_coffee"))