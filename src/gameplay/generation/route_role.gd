class_name RouteRole
extends RefCounted

enum Value {
	ENTRY,
	SETUP,
	CRUX,
	RECOVERY,
	TOP_OUT,
	OPTIONAL_BETA,
	REWARD,
	HAZARD_DENIAL,
}

static func is_valid(value: int) -> bool:
	match value:
		Value.ENTRY:
			return true
		Value.SETUP:
			return true
		Value.CRUX:
			return true
		Value.RECOVERY:
			return true
		Value.TOP_OUT:
			return true
		Value.OPTIONAL_BETA:
			return true
		Value.REWARD:
			return true
		Value.HAZARD_DENIAL:
			return true
		_:
			return false

static func assert_valid(value: int) -> void:
	Validation.require_condition(is_valid(value), "Unsupported route role.")

static func to_label(value: int) -> String:
	match value:
		Value.ENTRY:
			return "ENTRY"
		Value.SETUP:
			return "SETUP"
		Value.CRUX:
			return "CRUX"
		Value.RECOVERY:
			return "RECOVERY"
		Value.TOP_OUT:
			return "TOP_OUT"
		Value.OPTIONAL_BETA:
			return "OPTIONAL_BETA"
		Value.REWARD:
			return "REWARD"
		Value.HAZARD_DENIAL:
			return "HAZARD_DENIAL"
		_:
			Validation.require_condition(false, "RouteRole.to_label requires a supported route role.")
			return ""