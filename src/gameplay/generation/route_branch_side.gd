class_name RouteBranchSide
extends RefCounted

enum Value {
	NONE,
	LEFT,
	RIGHT,
}

static func is_valid(value: int) -> bool:
	match value:
		Value.NONE:
			return true
		Value.LEFT:
			return true
		Value.RIGHT:
			return true
		_:
			return false

static func assert_valid(value: int) -> void:
	Validation.require_condition(is_valid(value), "Unsupported route branch side.")

static func to_sign(value: int) -> int:
	match value:
		Value.NONE:
			return 0
		Value.LEFT:
			return -1
		Value.RIGHT:
			return 1
		_:
			Validation.require_condition(false, "RouteBranchSide.to_sign requires a supported branch side.")
			return 0

static func to_label(value: int) -> String:
	match value:
		Value.NONE:
			return "NONE"
		Value.LEFT:
			return "LEFT"
		Value.RIGHT:
			return "RIGHT"
		_:
			Validation.require_condition(false, "RouteBranchSide.to_label requires a supported branch side.")
			return ""