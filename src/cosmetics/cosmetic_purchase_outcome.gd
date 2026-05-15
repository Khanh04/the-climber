class_name CosmeticPurchaseOutcome
extends RefCounted

enum Value {
	PURCHASED,
	ALREADY_OWNED,
	INSUFFICIENT_FUNDS
}

static func is_valid(value: int) -> bool:
	match value:
		Value.PURCHASED:
			return true
		Value.ALREADY_OWNED:
			return true
		Value.INSUFFICIENT_FUNDS:
			return true
		_:
			return false

static func assert_valid(value: int) -> void:
	Validation.require_condition(is_valid(value), "Unsupported cosmetic purchase outcome.")