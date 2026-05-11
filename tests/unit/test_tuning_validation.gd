extends GutTest

const RewardedAdsTuningScript = preload("res://resources/config/rewarded_ads_tuning.gd")
const GenerationTuningScript = preload("res://resources/config/generation_tuning.gd")
const ChaserTuningScript = preload("res://resources/config/chaser_tuning.gd")
const CosmeticsTuningScript = preload("res://resources/config/cosmetics_tuning.gd")

func test_default_economy_tuning_is_valid() -> void:
    var tuning: EconomyTuning = EconomyTuning.new()

    assert_true(tuning.is_valid())

func test_economy_tuning_validate_alias_keeps_contract_consistent() -> void:
    var tuning: EconomyTuning = EconomyTuning.new()

    tuning.validate()
    assert_true(tuning.is_valid())

func test_invalid_economy_tuning_is_detected() -> void:
    var tuning: EconomyTuning = EconomyTuning.new()
    tuning.supporter_daily_coin_reward = 0

    assert_false(tuning.is_valid())

func test_default_stamina_tuning_is_valid() -> void:
    var tuning: StaminaTuning = StaminaTuning.new()

    assert_true(tuning.is_valid())

func test_stamina_tuning_validate_alias_keeps_contract_consistent() -> void:
    var tuning: StaminaTuning = StaminaTuning.new()

    tuning.validate()
    assert_true(tuning.is_valid())

func test_default_rewarded_ads_tuning_is_valid() -> void:
    var tuning = RewardedAdsTuningScript.new()

    assert_true(tuning.is_valid())

func test_invalid_rewarded_ads_tuning_is_detected() -> void:
    var tuning = RewardedAdsTuningScript.new()
    tuning.rewarded_continue_max_per_run = 2

    assert_false(tuning.is_valid())

func test_default_generation_tuning_is_valid() -> void:
    var tuning = GenerationTuningScript.new()

    assert_true(tuning.is_valid())

func test_invalid_generation_tuning_is_detected() -> void:
    var tuning = GenerationTuningScript.new()
    tuning.generator_version = ""

    assert_false(tuning.is_valid())

func test_default_chaser_tuning_is_valid() -> void:
    var tuning = ChaserTuningScript.new()

    assert_true(tuning.is_valid())

func test_invalid_chaser_tuning_is_detected() -> void:
    var tuning = ChaserTuningScript.new()
    tuning.rapid_progress_meters = tuning.camping_progress_meters

    assert_false(tuning.is_valid())

func test_default_cosmetics_tuning_is_valid() -> void:
    var tuning = CosmeticsTuningScript.new()

    assert_true(tuning.is_valid())

func test_invalid_cosmetics_tuning_is_detected() -> void:
    var tuning = CosmeticsTuningScript.new()
    tuning.loadout_slot_count = 0

    assert_false(tuning.is_valid())