class_name TransactionSource
extends RefCounted

enum Value {
	PICKUP,
	AD_REWARD,
	PURCHASE,
	GRANT,
	DEBUG_DEV
}

static func is_valid(value: int) -> bool:
	match value:
		Value.PICKUP:
			return true
		Value.AD_REWARD:
			return true
		Value.PURCHASE:
			return true
		Value.GRANT:
			return true
		Value.DEBUG_DEV:
			return true
		_:
			return false

static func assert_valid(value: int) -> void:
	Validation.require_condition(is_valid(value), "Unsupported transaction source.")

static func to_label(value: int) -> String:
	assert_valid(value)

	match value:
		Value.PICKUP:
			return "pickup"
		Value.AD_REWARD:
			return "ad_reward"
		Value.PURCHASE:
			return "purchase"
		Value.GRANT:
			return "grant"
		Value.DEBUG_DEV:
			return "debug_dev"
		_:
			Validation.require_condition(false, "Unsupported transaction source.")
			return ""