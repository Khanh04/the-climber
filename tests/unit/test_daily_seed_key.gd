extends GutTest

const SystemUtcDateProviderScript = preload("res://src/platform/clock/system_utc_date_provider.gd")
const UtcDateScript = preload("res://src/platform/clock/utc_date.gd")

func test_from_utc_date_uses_generator_version_and_full_date() -> void:
    assert_eq(DailySeedKey.from_utc_date(2026, 5, 11), "generator_v2:2026-05-11")

func test_current_utc_uses_date_provider_boundary() -> void:
    var date_provider: RefCounted = SystemUtcDateProviderScript.new()
    var seed_key: String = DailySeedKey.current_utc(date_provider)

    assert_true(seed_key.begins_with(DailySeedKey.GENERATOR_VERSION + ":"))

func test_utc_date_parses_iso_date() -> void:
    var utc_date = UtcDateScript.from_iso_date("2026-05-11")
    var year: int = utc_date.year
    var month: int = utc_date.month
    var day: int = utc_date.day

    assert_eq(year, 2026)
    assert_eq(month, 5)
    assert_eq(day, 11)

func test_to_rng_seed_is_stable_for_same_key() -> void:
    var seed_key: String = DailySeedKey.from_utc_date(2026, 5, 11)

    assert_eq(DailySeedKey.to_rng_seed(seed_key), DailySeedKey.to_rng_seed(seed_key))