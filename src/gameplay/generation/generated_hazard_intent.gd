class_name GeneratedHazardIntent
extends RefCounted

enum Value {
	SAFE_ROUTE_RELIEF,
	OPTIONAL_BRANCH_DENIAL,
	CRUX_PRESSURE,
	TRAVERSE_FORCE,
	RECOVERY_LIFT,
	REWARD_GREED_PRESSURE,
}

static func is_valid(value: int) -> bool:
	match value:
		Value.SAFE_ROUTE_RELIEF:
			return true
		Value.OPTIONAL_BRANCH_DENIAL:
			return true
		Value.CRUX_PRESSURE:
			return true
		Value.TRAVERSE_FORCE:
			return true
		Value.RECOVERY_LIFT:
			return true
		Value.REWARD_GREED_PRESSURE:
			return true
		_:
			return false

static func assert_valid(value: int) -> void:
	Validation.require_condition(is_valid(value), "Unsupported generated hazard intent.")

static func to_label(value: int) -> String:
	match value:
		Value.SAFE_ROUTE_RELIEF:
			return "SAFE_ROUTE_RELIEF"
		Value.OPTIONAL_BRANCH_DENIAL:
			return "OPTIONAL_BRANCH_DENIAL"
		Value.CRUX_PRESSURE:
			return "CRUX_PRESSURE"
		Value.TRAVERSE_FORCE:
			return "TRAVERSE_FORCE"
		Value.RECOVERY_LIFT:
			return "RECOVERY_LIFT"
		Value.REWARD_GREED_PRESSURE:
			return "REWARD_GREED_PRESSURE"
		_:
			Validation.require_condition(false, "GeneratedHazardIntent.to_label requires a supported hazard intent.")
			return ""