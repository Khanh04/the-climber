class_name RouteMovementStyle
extends RefCounted

enum Value {
	LADDER,
	ZIGZAG,
	RECOVERY,
	FORK,
	TRAVERSE_BRANCH,
	RISK_LANE,
	PRESSURE,
}

static func is_valid(value: int) -> bool:
	match value:
		Value.LADDER:
			return true
		Value.ZIGZAG:
			return true
		Value.RECOVERY:
			return true
		Value.FORK:
			return true
		Value.TRAVERSE_BRANCH:
			return true
		Value.RISK_LANE:
			return true
		Value.PRESSURE:
			return true
		_:
			return false

static func assert_valid(value: int) -> void:
	Validation.require_condition(is_valid(value), "Unsupported route movement style.")

static func to_label(value: int) -> String:
	match value:
		Value.LADDER:
			return "LADDER"
		Value.ZIGZAG:
			return "ZIGZAG"
		Value.RECOVERY:
			return "RECOVERY"
		Value.FORK:
			return "FORK"
		Value.TRAVERSE_BRANCH:
			return "TRAVERSE_BRANCH"
		Value.RISK_LANE:
			return "RISK_LANE"
		Value.PRESSURE:
			return "PRESSURE"
		_:
			Validation.require_condition(false, "RouteMovementStyle.to_label requires a supported movement style.")
			return ""