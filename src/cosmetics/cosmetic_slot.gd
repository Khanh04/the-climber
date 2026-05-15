class_name CosmeticSlot
extends RefCounted

enum Value {
	BODY,
	LEFT_HAND,
	RIGHT_HAND,
	CHASER_THEME
}

static func is_valid(value: int) -> bool:
	match value:
		Value.BODY:
			return true
		Value.LEFT_HAND:
			return true
		Value.RIGHT_HAND:
			return true
		Value.CHASER_THEME:
			return true
		_:
			return false

static func assert_valid(value: int) -> void:
	Validation.require_condition(is_valid(value), "Unsupported cosmetic slot.")

static func to_label(value: int) -> String:
	assert_valid(value)

	match value:
		Value.BODY:
			return "Body"
		Value.LEFT_HAND:
			return "Left Hand"
		Value.RIGHT_HAND:
			return "Right Hand"
		Value.CHASER_THEME:
			return "Chaser Theme"
		_:
			Validation.require_condition(false, "Unsupported cosmetic slot.")
			return ""