class_name DailySeedKey
extends RefCounted

const GENERATOR_VERSION: String = "generator_v5"

## Deterministic seed-string factory (also used directly by tests as a stable, arbitrary
## seed key -- callers do not need this to mean "today").
static func from_utc_date(year: int, month: int, day: int) -> String:
    Validation.require_condition(year >= 2000, "Daily seed year must be explicit and modern.")
    Validation.require_condition(month >= 1 and month <= 12, "Daily seed month must be between 1 and 12.")
    Validation.require_condition(day >= 1 and day <= 31, "Daily seed day must be between 1 and 31.")

    return "%s:%04d-%02d-%02d" % [GENERATOR_VERSION, year, month, day]

## A fresh seed for one run, independent of the calendar day or any other run. Each call
## returns a different key so two runs (even started back to back) generate different routes.
static func current_run() -> String:
    return "%s:run:%d-%d" % [GENERATOR_VERSION, Time.get_ticks_usec(), randi()]

static func to_rng_seed(seed_key: String) -> int:
    Validation.require_condition(seed_key.begins_with(GENERATOR_VERSION + ":"), "Daily seed key has an unsupported generator version.")

    var raw_hash: int = seed_key.hash()
    if raw_hash < 0:
        return -raw_hash

    return raw_hash
