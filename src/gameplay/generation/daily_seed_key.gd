class_name DailySeedKey
extends RefCounted

const UtcDateScript = preload("res://src/platform/clock/utc_date.gd")
const UtcDateProviderScript = preload("res://src/platform/clock/utc_date_provider.gd")

const GENERATOR_VERSION: String = "generator_v5"

static func from_utc_date(year: int, month: int, day: int) -> String:
    Validation.require_condition(year >= 2000, "Daily seed year must be explicit and modern.")
    Validation.require_condition(month >= 1 and month <= 12, "Daily seed month must be between 1 and 12.")
    Validation.require_condition(day >= 1 and day <= 31, "Daily seed day must be between 1 and 31.")

    return "%s:%04d-%02d-%02d" % [GENERATOR_VERSION, year, month, day]

static func current_utc(date_provider: RefCounted) -> String:
    Validation.require_condition(date_provider != null, "Daily seed generation requires a UTC date provider.")
    Validation.require_condition(date_provider is UtcDateProviderScript, "Daily seed generation requires a UTC date provider implementation.")

    var typed_date_provider: UtcDateProviderScript = date_provider
    var utc_date: UtcDateScript = typed_date_provider.get_current_utc_date()
    return from_utc_date(utc_date.year, utc_date.month, utc_date.day)

static func to_rng_seed(seed_key: String) -> int:
    Validation.require_condition(seed_key.begins_with(GENERATOR_VERSION + ":"), "Daily seed key has an unsupported generator version.")

    var raw_hash: int = seed_key.hash()
    if raw_hash < 0:
        return -raw_hash

    return raw_hash
