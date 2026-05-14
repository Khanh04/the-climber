class_name CoinTransactionLedger
extends RefCounted

var _transaction_ids: PackedStringArray = PackedStringArray()

func _init(initial_transaction_ids: PackedStringArray = PackedStringArray()) -> void:
	_transaction_ids = initial_transaction_ids.duplicate()
	assert_valid()

func has_transaction_id(transaction_id: String) -> bool:
	Validation.require_condition(not transaction_id.is_empty(), "CoinTransactionLedger transaction id cannot be empty.")
	return _transaction_ids.has(transaction_id)

func record_transaction_id(transaction_id: String) -> bool:
	Validation.require_condition(not transaction_id.is_empty(), "CoinTransactionLedger transaction id cannot be empty.")
	if _transaction_ids.has(transaction_id):
		return false

	var _append_result: bool = _transaction_ids.append(transaction_id)
	return true

func get_transaction_ids() -> PackedStringArray:
	return _transaction_ids.duplicate()

func is_valid() -> bool:
	var validated_transaction_ids: PackedStringArray = PackedStringArray()
	for transaction_id: String in _transaction_ids:
		if transaction_id.is_empty():
			return false

		if validated_transaction_ids.has(transaction_id):
			return false

		var _append_result: bool = validated_transaction_ids.append(transaction_id)

	return true

func assert_valid() -> void:
	Validation.require_condition(is_valid(), "CoinTransactionLedger requires non-empty unique transaction ids.")