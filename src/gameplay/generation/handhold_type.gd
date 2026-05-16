class_name HandholdType
extends RefCounted

enum Value {
	NORMAL,
	REST,
	BURN,
	BREAK,
	BOOST,
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
		_:
			Validation.require_condition(false, "HandholdType.from_label requires a supported handhold label.")
			return -1

static func get_default_definition_id(value: int) -> StringName:
	return StringName(to_label(value))

static func get_default_stamina_drain_multiplier(value: int) -> float:
	assert_valid(value)
	match value:
		Value.NORMAL:
			return 1.0
		Value.REST:
			return 0.75
		Value.BURN:
			return 1.35
		Value.BREAK:
			return 1.0
		Value.BOOST:
			return 1.0
		_:
			Validation.require_condition(false, "HandholdType default drain multiplier requires a supported handhold type.")
			return 0.0

static func get_default_physical_size_meters(value: int) -> Vector2:
	assert_valid(value)
	match value:
		Value.NORMAL:
			return Vector2(1.12, 0.30)
		Value.REST:
			return Vector2(1.24, 0.30)
		Value.BURN:
			return Vector2(0.96, 0.30)
		Value.BREAK:
			return Vector2(0.88, 0.28)
		Value.BOOST:
			return Vector2(1.04, 0.30)
		_:
			Validation.require_condition(false, "HandholdType default physical size requires a supported handhold type.")
			return Vector2.ZERO

static func get_default_color(value: int) -> Color:
	assert_valid(value)
	match value:
		Value.NORMAL:
			return Color(0.92, 0.72, 0.23, 1.0)
		Value.REST:
			return Color(0.41, 0.82, 0.47, 1.0)
		Value.BURN:
			return Color(0.92, 0.39, 0.27, 1.0)
		Value.BREAK:
			return Color(0.95, 0.64, 0.21, 1.0)
		Value.BOOST:
			return Color(0.32, 0.72, 0.96, 1.0)
		_:
			Validation.require_condition(false, "HandholdType default color requires a supported handhold type.")
			return Color.WHITE