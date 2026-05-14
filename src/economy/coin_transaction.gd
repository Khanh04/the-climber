class_name CoinTransaction
extends RefCounted

const TransactionSourceScript = preload("res://src/economy/transaction_source.gd")

var transaction_id: String
var source: int
var coin_delta: int

func _init(transaction_id_value: String, source_value: int, coin_delta_value: int) -> void:
	transaction_id = transaction_id_value
	source = source_value
	coin_delta = coin_delta_value
	assert_valid()

func is_valid() -> bool:
	if transaction_id.is_empty():
		return false

	if not TransactionSourceScript.is_valid(source):
		return false

	return coin_delta != 0

func assert_valid() -> void:
	Validation.require_condition(not transaction_id.is_empty(), "Coin transaction id cannot be empty.")
	TransactionSourceScript.assert_valid(source)
	Validation.require_condition(coin_delta != 0, "Coin transaction delta cannot be zero.")

func is_grant() -> bool:
	return coin_delta > 0

func is_spend() -> bool:
	return coin_delta < 0