class_name GeneratedHazardKind
extends RefCounted

enum Value {
	SPIKE_CLUSTER,
	WIND_GUST,
	DOWNDRAFT,
	UPDRAFT,
}

static func is_valid(value: int) -> bool:
	match value:
		Value.SPIKE_CLUSTER:
			return true
		Value.WIND_GUST:
			return true
		Value.DOWNDRAFT:
			return true
		Value.UPDRAFT:
			return true
		_:
			return false

static func assert_valid(value: int) -> void:
	Validation.require_condition(is_valid(value), "Unsupported generated hazard kind.")

static func to_label(value: int) -> String:
	assert_valid(value)
	match value:
		Value.SPIKE_CLUSTER:
			return "SPIKE_CLUSTER"
		Value.WIND_GUST:
			return "WIND_GUST"
		Value.DOWNDRAFT:
			return "DOWNDRAFT"
		Value.UPDRAFT:
			return "UPDRAFT"
		_:
			Validation.require_condition(false, "Unsupported generated hazard kind label.")
			return ""