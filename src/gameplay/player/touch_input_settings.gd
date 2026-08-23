class_name TouchInputSettings
extends RefCounted

const MIN_SPLIT_RATIO: float = 0.35
const MAX_SPLIT_RATIO: float = 0.65
const MIN_CENTER_DEAD_ZONE_RATIO: float = 0.0
const MAX_CENTER_DEAD_ZONE_RATIO: float = 0.20

var split_ratio: float
var center_dead_zone_ratio: float

func _init(split_ratio_value: float = 0.5, center_dead_zone_ratio_value: float = 0.0) -> void:
	split_ratio = split_ratio_value
	center_dead_zone_ratio = center_dead_zone_ratio_value
	assert_valid()

func is_valid() -> bool:
	return are_values_valid(split_ratio, center_dead_zone_ratio)

static func are_values_valid(split_ratio_value: float, center_dead_zone_ratio_value: float) -> bool:
	return split_ratio_value >= MIN_SPLIT_RATIO \
		and split_ratio_value <= MAX_SPLIT_RATIO \
		and center_dead_zone_ratio_value >= MIN_CENTER_DEAD_ZONE_RATIO \
		and center_dead_zone_ratio_value <= MAX_CENTER_DEAD_ZONE_RATIO

func assert_valid() -> void:
	Validation.require_condition(split_ratio >= MIN_SPLIT_RATIO and split_ratio <= MAX_SPLIT_RATIO, "Touch split ratio must stay within the supported mobile control range.")
	Validation.require_condition(center_dead_zone_ratio >= MIN_CENTER_DEAD_ZONE_RATIO and center_dead_zone_ratio <= MAX_CENTER_DEAD_ZONE_RATIO, "Touch center dead-zone ratio must stay within the supported mobile control range.")
