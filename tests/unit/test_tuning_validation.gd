extends GutTest

func test_default_economy_tuning_is_valid() -> void:
    var tuning: EconomyTuning = EconomyTuning.new()

    assert_true(tuning.is_valid())

func test_invalid_economy_tuning_is_detected() -> void:
    var tuning: EconomyTuning = EconomyTuning.new()
    tuning.supporter_daily_coin_reward = 0

    assert_false(tuning.is_valid())

func test_default_stamina_tuning_is_valid() -> void:
    var tuning: StaminaTuning = StaminaTuning.new()

    assert_true(tuning.is_valid())