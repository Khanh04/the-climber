extends GutTest

const CoinTransactionLedgerScript = preload("res://src/economy/coin_transaction_ledger.gd")
const CoinTransactionScript = preload("res://src/economy/coin_transaction.gd")
const TransactionSourceScript = preload("res://src/economy/transaction_source.gd")

func test_transaction_source_supports_phase_8_transaction_kinds() -> void:
	assert_true(TransactionSourceScript.is_valid(TransactionSourceScript.Value.PICKUP))
	assert_true(TransactionSourceScript.is_valid(TransactionSourceScript.Value.AD_REWARD))
	assert_true(TransactionSourceScript.is_valid(TransactionSourceScript.Value.PURCHASE))
	assert_true(TransactionSourceScript.is_valid(TransactionSourceScript.Value.GRANT))
	assert_true(TransactionSourceScript.is_valid(TransactionSourceScript.Value.DEBUG_DEV))

func test_coin_transaction_tracks_grants_and_spends() -> void:
	var grant_transaction: CoinTransactionScript = CoinTransactionScript.new(
		"pickup:chunk_00_pickup_00",
		TransactionSourceScript.Value.PICKUP,
		3
	)
	var spend_transaction: CoinTransactionScript = CoinTransactionScript.new(
		"purchase:hot_coffee",
		TransactionSourceScript.Value.PURCHASE,
		-5
	)

	assert_eq(grant_transaction.transaction_id, "pickup:chunk_00_pickup_00")
	assert_eq(grant_transaction.source, TransactionSourceScript.Value.PICKUP)
	assert_eq(grant_transaction.coin_delta, 3)
	assert_true(grant_transaction.is_grant())
	assert_false(grant_transaction.is_spend())
	assert_true(spend_transaction.is_spend())
	assert_false(spend_transaction.is_grant())

func test_coin_transaction_becomes_invalid_after_empty_id_mutation() -> void:
	var transaction: CoinTransactionScript = CoinTransactionScript.new(
		"debug:grant_01",
		TransactionSourceScript.Value.DEBUG_DEV,
		9
	)

	transaction.transaction_id = ""

	assert_false(transaction.is_valid())

func test_coin_transaction_becomes_invalid_after_zero_delta_mutation() -> void:
	var transaction: CoinTransactionScript = CoinTransactionScript.new(
		"grant:starter_bonus",
		TransactionSourceScript.Value.GRANT,
		12
	)

	transaction.coin_delta = 0

	assert_false(transaction.is_valid())

func test_coin_transaction_ledger_records_each_transaction_id_once() -> void:
	var ledger: CoinTransactionLedgerScript = CoinTransactionLedgerScript.new()

	assert_false(ledger.has_transaction_id("pickup:chunk_01_pickup_02"))
	assert_true(ledger.record_transaction_id("pickup:chunk_01_pickup_02"))
	assert_true(ledger.has_transaction_id("pickup:chunk_01_pickup_02"))
	assert_false(ledger.record_transaction_id("pickup:chunk_01_pickup_02"))
	assert_eq(ledger.get_transaction_ids(), PackedStringArray(["pickup:chunk_01_pickup_02"]))