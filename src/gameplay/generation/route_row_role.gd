class_name RouteRowRole
extends RefCounted

enum Value {
	SUPPORT,
	DECISION,
	TRAVERSE,
	CRUX,
	PRESSURE,
	CATCH,
	TOP_OUT,
}

static func is_valid(value: int) -> bool:
	match value:
		Value.SUPPORT:
			return true
		Value.DECISION:
			return true
		Value.TRAVERSE:
			return true
		Value.CRUX:
			return true
		Value.PRESSURE:
			return true
		Value.CATCH:
			return true
		Value.TOP_OUT:
			return true
		_:
			return false

static func assert_valid(value: int) -> void:
	Validation.require_condition(is_valid(value), "Unsupported route row role.")

static func is_sparse(value: int) -> bool:
	match value:
		Value.CRUX:
			return true
		Value.PRESSURE:
			return true
		_:
			assert_valid(value)
			return false

static func to_label(value: int) -> String:
	match value:
		Value.SUPPORT:
			return "SUPPORT"
		Value.DECISION:
			return "DECISION"
		Value.TRAVERSE:
			return "TRAVERSE"
		Value.CRUX:
			return "CRUX"
		Value.PRESSURE:
			return "PRESSURE"
		Value.CATCH:
			return "CATCH"
		Value.TOP_OUT:
			return "TOP_OUT"
		_:
			Validation.require_condition(false, "RouteRowRole.to_label requires a supported row role.")
			return ""