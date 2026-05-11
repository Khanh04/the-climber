class_name UtcDateProvider
extends RefCounted

const UtcDateScript = preload("res://src/platform/clock/utc_date.gd")

func get_current_utc_date() -> UtcDateScript:
    Validation.require_condition(false, "UtcDateProvider.get_current_utc_date must be implemented.")
    return UtcDateScript.new(2000, 1, 1)