class_name SystemUtcDateProvider
extends "res://src/platform/clock/utc_date_provider.gd"

func get_current_utc_date() -> UtcDateScript:
    return UtcDateScript.from_iso_date(Time.get_date_string_from_system(true))