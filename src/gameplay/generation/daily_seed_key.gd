class_name DailySeedKey
extends RefCounted

const GENERATOR_VERSION: String = "generator_v1"

static func from_utc_date(year: int, month: int, day: int) -> String:
    Validation.require_condition(year >= 2000, "Daily seed year must be explicit and modern.")
    Validation.require_condition(month >= 1 and month <= 12, "Daily seed month must be between 1 and 12.")
    Validation.require_condition(day >= 1 and day <= 31, "Daily seed day must be between 1 and 31.")

    return "%s:%04d-%02d-%02d" % [GENERATOR_VERSION, year, month, day]

static func current_utc() -> String:
    var date_parts: PackedStringArray = Time.get_date_string_from_system(true).split("-")
    Validation.require_condition(date_parts.size() == 3, "UTC date string must use YYYY-MM-DD format.")

    var year: int = date_parts[0].to_int()
    var month: int = date_parts[1].to_int()
    var day: int = date_parts[2].to_int()

    return from_utc_date(year, month, day)

static func to_rng_seed(seed_key: String) -> int:
    Validation.require_condition(seed_key.begins_with(GENERATOR_VERSION + ":"), "Daily seed key has an unsupported generator version.")

    var raw_hash: int = seed_key.hash()
    if raw_hash < 0:
        return -raw_hash

    return raw_hash