extends GutTest

const EconomyTuningScript = preload("res://resources/config/economy_tuning.gd")
const StaminaTuningScript = preload("res://resources/config/stamina_tuning.gd")
const RewardedAdsTuningScript = preload("res://resources/config/rewarded_ads_tuning.gd")
const ChaserThemeCatalogScript = preload("res://resources/config/chaser_theme_catalog.gd")
const GenerationTuningScript = preload("res://resources/config/generation_tuning.gd")
const ChaserThemeScript = preload("res://resources/config/chaser_theme.gd")
const ChaserTuningScript = preload("res://resources/config/chaser_tuning.gd")
const CosmeticLoadoutScript = preload("res://resources/config/cosmetic_loadout.gd")
const CosmeticsTuningScript = preload("res://resources/config/cosmetics_tuning.gd")
const ClimbPrototypeTuningScript = preload("res://resources/config/climb_prototype_tuning.gd")

func test_default_economy_tuning_is_valid() -> void:
    var tuning = EconomyTuningScript.new()

    assert_true(tuning.is_valid())

func test_economy_tuning_validate_alias_keeps_contract_consistent() -> void:
    var tuning = EconomyTuningScript.new()

    tuning.validate()
    assert_true(tuning.is_valid())

func test_invalid_economy_tuning_is_detected() -> void:
    var tuning = EconomyTuningScript.new()
    tuning.supporter_daily_coin_reward = 0

    assert_false(tuning.is_valid())


func test_default_stamina_tuning_is_valid() -> void:
    var tuning = StaminaTuningScript.new()

    assert_true(tuning.is_valid())

func test_stamina_tuning_validate_alias_keeps_contract_consistent() -> void:
    var tuning = StaminaTuningScript.new()

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

func test_generation_tuning_rejects_non_positive_chunk_width() -> void:
    var tuning = GenerationTuningScript.new()
    tuning.chunk_width_meters = 0.0

    assert_false(tuning.is_valid())

func test_generation_tuning_rejects_non_positive_starter_chunk_gap() -> void:
    var tuning = GenerationTuningScript.new()
    tuning.starter_chunk_gap_meters = 0.0

    assert_false(tuning.is_valid())

func test_generation_tuning_rejects_non_increasing_difficulty_band_heights() -> void:
    var tuning = GenerationTuningScript.new()
    tuning.baseline_band_max_height_meters = tuning.easy_band_max_height_meters

    assert_false(tuning.is_valid())

func test_default_chaser_tuning_is_valid() -> void:
    var tuning = ChaserTuningScript.new()

    assert_true(tuning.is_valid())

func test_invalid_chaser_tuning_is_detected() -> void:
    var tuning = ChaserTuningScript.new()
    tuning.rapid_progress_meters = tuning.camping_progress_meters

    assert_false(tuning.is_valid())

func test_chaser_tuning_rejects_non_positive_spawn_offset() -> void:
    var tuning = ChaserTuningScript.new()
    tuning.initial_spawn_offset_meters = 0.0

    assert_false(tuning.is_valid())

func test_chaser_tuning_rejects_invalid_feedback_ranges() -> void:
    var tuning = ChaserTuningScript.new()
    tuning.far_distance_for_min_intensity_meters = tuning.near_distance_for_max_intensity_meters

    assert_false(tuning.is_valid())

func test_default_chaser_theme_is_valid() -> void:
    var theme: ChaserThemeScript = load("res://resources/config/chaser_theme_rising_void.tres") as ChaserThemeScript

    assert_not_null(theme)
    assert_true(theme.is_valid())

func test_invalid_chaser_theme_is_detected() -> void:
    var theme := ChaserThemeScript.new()
    theme.audio_loop_stream = load("res://assets/audio/chaser_pressure_loop.tres") as AudioStream
    theme.pulse_max_frequency_hz = 0.25
    theme.pulse_min_frequency_hz = 0.5

    assert_false(theme.is_valid())

func test_chaser_theme_rejects_non_positive_audio_curve_exponents() -> void:
    var theme := ChaserThemeScript.new()
    theme.audio_loop_stream = load("res://assets/audio/chaser_pressure_loop.tres") as AudioStream
    theme.audio_pitch_curve_exponent = 0.0

    assert_false(theme.is_valid())

func test_concrete_chaser_themes_swap_distinct_audio_and_pulse_profiles() -> void:
    var rising_void_theme: ChaserThemeScript = load("res://resources/config/chaser_theme_rising_void.tres") as ChaserThemeScript
    var hot_coffee_theme: ChaserThemeScript = load("res://resources/config/chaser_theme_hot_coffee.tres") as ChaserThemeScript
    var glitch_theme: ChaserThemeScript = load("res://resources/config/chaser_theme_glitch.tres") as ChaserThemeScript

    assert_not_null(rising_void_theme)
    assert_not_null(hot_coffee_theme)
    assert_not_null(glitch_theme)
    assert_ne(rising_void_theme.audio_loop_stream, hot_coffee_theme.audio_loop_stream)
    assert_ne(hot_coffee_theme.audio_loop_stream, glitch_theme.audio_loop_stream)
    assert_ne(rising_void_theme.pulse_max_frequency_hz, glitch_theme.pulse_max_frequency_hz)
    assert_ne(rising_void_theme.audio_volume_curve_exponent, hot_coffee_theme.audio_volume_curve_exponent)
    assert_ne(hot_coffee_theme.audio_pitch_curve_exponent, glitch_theme.audio_pitch_curve_exponent)
    assert_ne(hot_coffee_theme.base_fill_color, glitch_theme.base_fill_color)

func test_default_cosmetic_loadout_is_valid() -> void:
    var loadout: CosmeticLoadoutScript = load("res://resources/config/cosmetic_loadout_default.tres") as CosmeticLoadoutScript

    assert_not_null(loadout)
    assert_true(loadout.is_valid())

func test_invalid_cosmetic_loadout_is_detected() -> void:
    var loadout := CosmeticLoadoutScript.new()
    loadout.chaser_theme_id = StringName()

    assert_false(loadout.is_valid())

func test_default_chaser_theme_catalog_is_valid() -> void:
    var catalog: ChaserThemeCatalogScript = load("res://resources/config/chaser_theme_catalog.tres") as ChaserThemeCatalogScript

    assert_not_null(catalog)
    assert_true(catalog.is_valid())
    assert_eq(catalog.get_required_theme_by_id(&"hot_coffee").theme_id, &"hot_coffee")

func test_invalid_chaser_theme_catalog_is_detected() -> void:
    var theme: ChaserThemeScript = load("res://resources/config/chaser_theme_rising_void.tres") as ChaserThemeScript
    var catalog := ChaserThemeCatalogScript.new()
    catalog.themes = [theme, theme]

    assert_false(catalog.is_valid())

func test_default_cosmetics_tuning_is_valid() -> void:
    var tuning = CosmeticsTuningScript.new()

    assert_true(tuning.is_valid())

func test_invalid_cosmetics_tuning_is_detected() -> void:
    var tuning = CosmeticsTuningScript.new()
    tuning.loadout_slot_count = 0

    assert_false(tuning.is_valid())

func test_default_climb_prototype_tuning_is_valid() -> void:
    var tuning = ClimbPrototypeTuningScript.new()

    assert_true(tuning.is_valid())

func test_climb_prototype_tuning_validate_alias_keeps_contract_consistent() -> void:
    var tuning = ClimbPrototypeTuningScript.new()

    tuning.validate()
    assert_true(tuning.is_valid())

func test_invalid_climb_prototype_tuning_is_detected() -> void:
    var tuning = ClimbPrototypeTuningScript.new()
    tuning.grip_velocity_damping = 1.5

    assert_false(tuning.is_valid())