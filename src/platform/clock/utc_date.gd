class_name UtcDate
extends RefCounted

const SELF_SCRIPT: GDScript = preload("res://src/platform/clock/utc_date.gd")

var year: int
var month: int
var day: int

func _init(year_value: int, month_value: int, day_value: int) -> void:
    year = year_value
    month = month_value
    day = day_value
    assert_valid()

static func from_iso_date(date_text: String) -> RefCounted:
    var date_parts: PackedStringArray = date_text.split("-")
    Validation.require_condition(date_parts.size() == 3, "UTC date string must use YYYY-MM-DD format.")

    return SELF_SCRIPT.new(date_parts[0].to_int(), date_parts[1].to_int(), date_parts[2].to_int())

func is_valid() -> bool:
    return year >= 2000 and month >= 1 and month <= 12 and day >= 1 and day <= 31

func assert_valid() -> void:
    Validation.require_condition(year >= 2000, "UTC date year must be explicit and modern.")
    Validation.require_condition(month >= 1 and month <= 12, "UTC date month must be between 1 and 12.")
    Validation.require_condition(day >= 1 and day <= 31, "UTC date day must be between 1 and 31.")