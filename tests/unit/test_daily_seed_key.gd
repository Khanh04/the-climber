extends GutTest

func test_from_utc_date_uses_generator_version_and_full_date() -> void:
    assert_eq(DailySeedKey.from_utc_date(2026, 5, 11), "generator_v1:2026-05-11")

func test_to_rng_seed_is_stable_for_same_key() -> void:
    var seed_key: String = DailySeedKey.from_utc_date(2026, 5, 11)

    assert_eq(DailySeedKey.to_rng_seed(seed_key), DailySeedKey.to_rng_seed(seed_key))