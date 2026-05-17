class_name HandholdType
extends RefCounted

enum Value {
	NORMAL,
	REST,
	BURN,
	BREAK,
	BOOST,
	GHOST,
	ROCKET,
}

static func is_valid(value: int) -> bool:
	match value:
		Value.NORMAL:
			return true
		Value.REST:
			return true
		Value.BURN:
			return true
		Value.BREAK:
			return true
		Value.BOOST:
			return true
		Value.GHOST:
			return true
		Value.ROCKET:
			return true
		_:
			return false

static func assert_valid(value: int) -> void:
	Validation.require_condition(is_valid(value), "Unsupported handhold type.")

static func to_label(value: int) -> String:
	assert_valid(value)
	match value:
		Value.NORMAL:
			return "NORMAL"
		Value.REST:
			return "REST"
		Value.BURN:
			return "BURN"
		Value.BREAK:
			return "BREAK"
		Value.BOOST:
			return "BOOST"
		Value.GHOST:
			return "GHOST"
		Value.ROCKET:
			return "ROCKET"
		_:
			Validation.require_condition(false, "HandholdType.to_label requires a supported handhold type.")
			return ""

static func from_label(label: String) -> int:
	match label:
		"NORMAL":
			return Value.NORMAL
		"REST":
			return Value.REST
		"BURN":
			return Value.BURN
		"BREAK":
			return Value.BREAK
		"BOOST":
			return Value.BOOST
		"GHOST":
			return Value.GHOST
		"ROCKET":
			return Value.ROCKET
		_:
			Validation.require_condition(false, "HandholdType.from_label requires a supported handhold label.")
			return -1

static func get_all_values() -> Array[int]:
	return [
		Value.NORMAL,
		Value.REST,
		Value.BURN,
		Value.BREAK,
		Value.BOOST,
		Value.GHOST,
		Value.ROCKET,
	]