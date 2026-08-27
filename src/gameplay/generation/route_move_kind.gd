class_name RouteMoveKind
extends RefCounted

enum Value {
	STATIC_REACH,
	SWING_REACH,
}

static func is_valid(value: int) -> bool:
	match value:
		Value.STATIC_REACH:
			return true
		Value.SWING_REACH:
			return true
		_:
			return false

static func assert_valid(value: int) -> void:
	Validation.require_condition(is_valid(value), "Unsupported route move kind.")

static func to_label(value: int) -> String:
	match value:
		Value.STATIC_REACH:
			return "STATIC_REACH"
		Value.SWING_REACH:
			return "SWING_REACH"
		_:
			Validation.require_condition(false, "RouteMoveKind.to_label requires a supported route move kind.")
			return ""
