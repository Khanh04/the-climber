extends GutTest

const EconomyTuningScript = preload("res://resources/config/economy_tuning.gd")
const StaminaTuningScript = preload("res://resources/config/stamina_tuning.gd")
const RewardedAdsTuningScript = preload("res://resources/config/rewarded_ads_tuning.gd")
const ChaserThemeCatalogScript = preload("res://resources/config/chaser_theme_catalog.gd")
const HandholdAssignmentRuleCatalogScript = preload("res://resources/config/handhold_assignment_rule_catalog.gd")
const HandholdAssignmentRuleScript = preload("res://resources/config/handhold_assignment_rule.gd")
const GenerationTuningScript = preload("res://resources/config/generation_tuning.gd")
const HandholdTypeDefinitionCatalogScript = preload("res://resources/config/handhold_type_definition_catalog.gd")
const HandholdTypeDefinitionScript = preload("res://resources/config/handhold_type_definition.gd")
const RouteProfileTuningScript = preload("res://resources/config/route_profile_tuning.gd")
const RouteValidationTuningScript = preload("res://resources/config/route_validation_tuning.gd")
const ChaserThemeScript = preload("res://resources/config/chaser_theme.gd")
const ChaserTuningScript = preload("res://resources/config/chaser_tuning.gd")
const CosmeticItemCatalogScript = preload("res://resources/config/cosmetic_item_catalog.gd")
const CosmeticLoadoutScript = preload("res://resources/config/cosmetic_loadout.gd")
const CosmeticsTuningScript = preload("res://resources/config/cosmetics_tuning.gd")
const ClimbPrototypeTuningScript = preload("res://resources/config/climb_prototype_tuning.gd")
const ChunkDifficultyBandScript = preload("res://src/gameplay/generation/chunk_difficulty_band.gd")
const ChunkRouteSlotScript = preload("res://src/gameplay/generation/chunk_route_slot.gd")
const HandholdRowZoneScript = preload("res://src/gameplay/generation/handhold_row_zone.gd")
const HandholdTypeScript = preload("res://src/gameplay/generation/handhold_type.gd")

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

func test_default_route_validation_tuning_is_valid() -> void:
    var tuning: RouteValidationTuningScript = load("res://resources/config/route_validation_tuning.tres") as RouteValidationTuningScript

    assert_not_null(tuning)
    assert_true(tuning.is_valid())

func test_default_route_profile_tuning_is_valid() -> void:
    var tuning: RouteProfileTuningScript = load("res://resources/config/route_profile_tuning.tres") as RouteProfileTuningScript

    assert_not_null(tuning)
    assert_true(tuning.is_valid())

func test_default_handhold_type_definition_catalog_is_valid() -> void:
    var catalog: HandholdTypeDefinitionCatalogScript = load("res://resources/config/handhold_type_definition_catalog.tres") as HandholdTypeDefinitionCatalogScript

    assert_not_null(catalog)
    assert_true(catalog.is_valid())

func test_default_handhold_assignment_rule_catalog_is_valid() -> void:
    var catalog: HandholdAssignmentRuleCatalogScript = load("res://resources/config/handhold_assignment_rule_catalog.tres") as HandholdAssignmentRuleCatalogScript

    assert_not_null(catalog)
    assert_true(catalog.is_valid())

func test_generation_tuning_duplicates_authored_default_handhold_resources() -> void:
    var first_tuning: GenerationTuningScript = GenerationTuningScript.new()
    var second_tuning: GenerationTuningScript = GenerationTuningScript.new()
    var first_definition: HandholdTypeDefinitionScript = first_tuning.handhold_definitions[0] as HandholdTypeDefinitionScript
    var second_definition: HandholdTypeDefinitionScript = second_tuning.handhold_definitions[0] as HandholdTypeDefinitionScript
    var first_rule: HandholdAssignmentRuleScript = first_tuning.handhold_assignment_rules[0] as HandholdAssignmentRuleScript
    var second_rule: HandholdAssignmentRuleScript = second_tuning.handhold_assignment_rules[0] as HandholdAssignmentRuleScript
    var first_route_validation_tuning: RouteValidationTuningScript = first_tuning.route_validation_tuning as RouteValidationTuningScript
    var second_route_validation_tuning: RouteValidationTuningScript = second_tuning.route_validation_tuning as RouteValidationTuningScript
    var first_route_profile_tuning: RouteProfileTuningScript = first_tuning.route_profile_tuning as RouteProfileTuningScript
    var second_route_profile_tuning: RouteProfileTuningScript = second_tuning.route_profile_tuning as RouteProfileTuningScript

    assert_not_null(first_definition)
    assert_not_null(second_definition)
    assert_not_null(first_rule)
    assert_not_null(second_rule)
    assert_not_null(first_route_validation_tuning)
    assert_not_null(second_route_validation_tuning)
    assert_not_null(first_route_profile_tuning)
    assert_not_null(second_route_profile_tuning)
    assert_ne(first_definition, second_definition)
    assert_ne(first_definition.surface_profile, second_definition.surface_profile)
    assert_ne(first_definition.lifecycle_rule, second_definition.lifecycle_rule)
    assert_ne(first_definition.movement_rule, second_definition.movement_rule)
    assert_ne(first_rule, second_rule)
    assert_ne(first_route_validation_tuning, second_route_validation_tuning)
    assert_ne(first_route_profile_tuning, second_route_profile_tuning)

func test_invalid_generation_tuning_is_detected() -> void:
    var tuning = GenerationTuningScript.new()
    tuning.generator_version = ""

    assert_false(tuning.is_valid())

func test_generation_tuning_rejects_empty_handhold_assignment_rules() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    tuning.handhold_assignment_rules = []

    assert_false(tuning.is_valid())

func test_generation_tuning_matches_ordered_row_zone_assignment_rules() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    tuning.handhold_assignment_rules = [
        _build_assignment_rule(
            ChunkRouteSlotScript.Value.OPENER,
            true,
            ChunkDifficultyBandScript.Value.EASY,
            HandholdRowZoneScript.Value.LOWER,
            [HandholdTypeScript.Value.REST]
        ),
        _build_assignment_rule(
            ChunkRouteSlotScript.Value.OPENER,
            true,
            ChunkDifficultyBandScript.Value.EASY,
            HandholdRowZoneScript.Value.ANY,
            [HandholdTypeScript.Value.NORMAL]
        ),
    ]

    var lower_row_types: Array[int] = tuning.get_allowed_handhold_types(
        ChunkRouteSlotScript.Value.OPENER,
        ChunkDifficultyBandScript.Value.EASY,
        0,
        1
    )
    var upper_row_types: Array[int] = tuning.get_allowed_handhold_types(
        ChunkRouteSlotScript.Value.OPENER,
        ChunkDifficultyBandScript.Value.EASY,
        3,
        5
    )

    assert_eq(lower_row_types.size(), 1)
    assert_eq(lower_row_types[0], HandholdTypeScript.Value.REST)
    assert_eq(upper_row_types.size(), 1)
    assert_eq(upper_row_types[0], HandholdTypeScript.Value.NORMAL)

func test_generation_tuning_rejects_non_positive_chunk_width() -> void:
    var tuning = GenerationTuningScript.new()
    tuning.chunk_width_meters = 0.0

    assert_false(tuning.is_valid())

func test_generation_tuning_rejects_non_increasing_difficulty_band_heights() -> void:
    var tuning = GenerationTuningScript.new()
    tuning.baseline_band_max_height_meters = tuning.easy_band_max_height_meters

    assert_false(tuning.is_valid())

func test_generation_tuning_rejects_invalid_lane_position_ratios() -> void:
    var tuning = GenerationTuningScript.new()
    tuning.inner_lane_position_ratio = tuning.outer_lane_position_ratio

    assert_false(tuning.is_valid())

func test_generation_tuning_rejects_opener_spacing_that_exceeds_chunk_height() -> void:
    var tuning = GenerationTuningScript.new()
    tuning.opener_first_row_height_meters = tuning.segment_height_meters * 0.8
    tuning.opener_top_padding_meters = tuning.segment_height_meters * 0.25

    assert_false(tuning.is_valid())

func test_generation_tuning_rejects_invalid_pickup_socket_ratio() -> void:
    var tuning = GenerationTuningScript.new()
    tuning.pickup_socket_ratio = 1.0

    assert_false(tuning.is_valid())

func test_generation_tuning_rejects_invalid_route_validation_tuning() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var route_validation_tuning: RouteValidationTuningScript = tuning.route_validation_tuning as RouteValidationTuningScript

    assert_not_null(route_validation_tuning)
    route_validation_tuning.candidate_attempt_count = 0

    assert_false(tuning.is_valid())

func test_generation_tuning_rejects_invalid_route_profile_tuning() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var route_profile_tuning: RouteProfileTuningScript = tuning.route_profile_tuning as RouteProfileTuningScript

    assert_not_null(route_profile_tuning)
    route_profile_tuning.easy_baseline_weight = 0.0
    route_profile_tuning.easy_skill_weight = 0.0
    route_profile_tuning.easy_recovery_weight = 0.0
    route_profile_tuning.easy_risk_weight = 0.0
    route_profile_tuning.easy_pressure_weight = 0.0

    assert_false(tuning.is_valid())

func test_generation_tuning_rejects_invalid_branch_side_alignment() -> void:
    var tuning = GenerationTuningScript.new()
    tuning.pickup_branch_side_alignment_meters = 2.0

    assert_false(tuning.is_valid())

func test_generation_tuning_rejects_out_of_range_hold_rows() -> void:
    var tuning = GenerationTuningScript.new()
    var invalid_fork_hold_rows: Array[PackedInt32Array] = [PackedInt32Array([4])]
    tuning.fork_hold_rows = invalid_fork_hold_rows

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

func test_cosmetic_loadout_rejects_empty_player_cosmetic_ids() -> void:
    var loadout := CosmeticLoadoutScript.new()
    loadout.body_cosmetic_id = StringName()

    assert_false(loadout.is_valid())

func test_default_cosmetic_item_catalog_is_valid() -> void:
    var catalog: CosmeticItemCatalogScript = load("res://resources/config/cosmetic_item_catalog.tres") as CosmeticItemCatalogScript

    assert_not_null(catalog)
    assert_true(catalog.is_valid())
    assert_eq(catalog.get_required_item_by_id(&"body_default").item_id, &"body_default")

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

func _build_assignment_rule(
    route_slot: int,
    applies_to_all_difficulty_bands: bool,
    difficulty_band: int,
    row_zone: int,
    allowed_handhold_types: Array[int]
) -> HandholdAssignmentRuleScript:
    var assignment_rule: HandholdAssignmentRuleScript = HandholdAssignmentRuleScript.new()
    assignment_rule.route_slot = route_slot
    assignment_rule.applies_to_all_difficulty_bands = applies_to_all_difficulty_bands
    assignment_rule.difficulty_band = difficulty_band
    assignment_rule.row_zone = row_zone
    assignment_rule.allowed_handhold_types = allowed_handhold_types
    return assignment_rule