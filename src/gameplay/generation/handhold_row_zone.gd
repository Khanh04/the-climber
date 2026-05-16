class_name HandholdRowZone
extends RefCounted

enum Value {
	ANY,
	LOWER,
	MIDDLE,
	UPPER,
}

static func is_valid(value: int) -> bool:
	match value:
		Value.ANY:
			return true
		Value.LOWER:
			return true
		Value.MIDDLE:
			return true
		Value.UPPER:
			return true
		_:
			return false

static func assert_valid(value: int) -> void:
	Validation.require_condition(is_valid(value), "Unsupported handhold row zone.")

static func matches_row(value: int, row_index: int, row_count: int) -> bool:
	assert_valid(value)
	Validation.require_condition(row_count > 0, "HandholdRowZone row matching requires at least one row.")
	Validation.require_condition(row_index >= 0 and row_index < row_count, "HandholdRowZone row index is out of bounds.")

	match value:
		Value.ANY:
			return true
		Value.LOWER:
			return row_index <= 1
		Value.MIDDLE:
			return row_index > 1 and row_index < maxi(0, row_count - 2)
		Value.UPPER:
			return row_index >= maxi(0, row_count - 2)
		_:
			Validation.require_condition(false, "HandholdRowZone.matches_row requires a supported row zone.")
			return false