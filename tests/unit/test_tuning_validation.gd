extends GutTest

const EconomyTuningScript = preload("res://resources/config/economy_tuning.gd")
const StaminaTuningScript = preload("res://resources/config/stamina_tuning.gd")
const RewardedAdsTuningScript = preload("res://resources/config/rewarded_ads_tuning.gd")
const ChaserThemeCatalogScript = preload("res://resources/config/chaser_theme_catalog.gd")
const GenerationTuningScript = preload("res://resources/config/generation_tuning.gd")
const HandholdTypeDefinitionCatalogScript = preload("res://resources/config/handhold_type_definition_catalog.gd")
const HandholdTypeDefinitionScript = preload("res://resources/config/handhold_type_definition.gd")
const BandFieldProfileScript = preload("res://resources/config/band_field_profile.gd")
const RouteValidationTuningScript = preload("res://resources/config/route_validation_tuning.gd")
const ChaserThemeScript = preload("res://resources/config/chaser_theme.gd")
const ChaserTuningScript = preload("res://resources/config/chaser_tuning.gd")
const CosmeticItemCatalogScript = preload("res://resources/config/cosmetic_item_catalog.gd")
const CosmeticLoadoutScript = preload("res://resources/config/cosmetic_loadout.gd")
const CosmeticsTuningScript = preload("res://resources/config/cosmetics_tuning.gd")
const ClimbPrototypeTuningScript = preload("res://resources/config/climb_prototype_tuning.gd")
const PlayerCharacterScript = preload("res://scenes/player/player_character.gd")
const ChunkTypeScript = preload("res://src/gameplay/generation/chunk_type.gd")
const ChunkDifficultyBandScript = preload("res://src/gameplay/generation/chunk_difficulty_band.gd")
const ChunkRouteSlotScript = preload("res://src/gameplay/generation/chunk_route_slot.gd")
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

func test_route_validation_player_body_width_matches_player_collision_footprint() -> void:
    var tuning: RouteValidationTuningScript = load("res://resources/config/route_validation_tuning.tres") as RouteValidationTuningScript
    var player_scene: PackedScene = load("res://scenes/player/player_character.tscn")
    var player: PlayerCharacterScript = player_scene.instantiate() as PlayerCharacterScript
    add_child_autofree(player)
    var climb_tuning: ClimbPrototypeTuningScript = player.climb_tuning
    var head_collision_shape: CollisionShape2D = player.get_node("Head/HeadCollisionShape") as CollisionShape2D
    var head_shape: RectangleShape2D = head_collision_shape.shape as RectangleShape2D

    var expected_body_width_meters: float = head_shape.size.x / climb_tuning.pixels_per_meter

    assert_almost_eq(tuning.player_body_width_meters, expected_body_width_meters, 0.01)

func test_default_band_field_profiles_are_valid() -> void:
    for path: String in [
        "res://resources/config/band_field_profile_easy.tres",
        "res://resources/config/band_field_profile_baseline.tres",
        "res://resources/config/band_field_profile_challenge.tres",
    ]:
        var profile: BandFieldProfileScript = load(path) as BandFieldProfileScript
        assert_not_null(profile, path)
        assert_true(profile.is_valid(), path)

func test_band_field_profiles_get_harder_with_altitude() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var easy: BandFieldProfileScript = tuning.get_field_profile(ChunkDifficultyBandScript.Value.EASY)
    var baseline: BandFieldProfileScript = tuning.get_field_profile(ChunkDifficultyBandScript.Value.BASELINE)
    var challenge: BandFieldProfileScript = tuning.get_field_profile(ChunkDifficultyBandScript.Value.CHALLENGE)

    assert_lt(easy.max_route_move_meters, baseline.max_route_move_meters)
    assert_lt(baseline.max_route_move_meters, challenge.max_route_move_meters)
    assert_lt(easy.corridor_hold_spacing_meters, challenge.corridor_hold_spacing_meters)

func test_default_handhold_type_definition_catalog_is_valid() -> void:
    var catalog: HandholdTypeDefinitionCatalogScript = load("res://resources/config/handhold_type_definition_catalog.tres") as HandholdTypeDefinitionCatalogScript

    assert_not_null(catalog)
    assert_true(catalog.is_valid())

func test_default_handhold_widths_leave_a_visual_gap_at_the_tightest_hold_spacing() -> void:
    var catalog: HandholdTypeDefinitionCatalogScript = load("res://resources/config/handhold_type_definition_catalog.tres") as HandholdTypeDefinitionCatalogScript
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var tightest_spacing_meters: float = tuning.get_field_profile(ChunkDifficultyBandScript.Value.EASY).corridor_hold_spacing_meters
    var minimum_visual_gap_meters: float = 0.02

    assert_not_null(catalog)
    for definition_resource in catalog.definitions:
        assert_true(definition_resource is HandholdTypeDefinitionScript)
        var definition: HandholdTypeDefinitionScript = definition_resource as HandholdTypeDefinitionScript
        assert_lte(definition.physical_size_meters.x, tightest_spacing_meters - minimum_visual_gap_meters)

func test_generation_tuning_duplicates_authored_default_handhold_resources() -> void:
    var first_tuning: GenerationTuningScript = GenerationTuningScript.new()
    var second_tuning: GenerationTuningScript = GenerationTuningScript.new()
    var first_definition: HandholdTypeDefinitionScript = first_tuning.handhold_definitions[0] as HandholdTypeDefinitionScript
    var second_definition: HandholdTypeDefinitionScript = second_tuning.handhold_definitions[0] as HandholdTypeDefinitionScript
    var first_route_validation_tuning: RouteValidationTuningScript = first_tuning.route_validation_tuning as RouteValidationTuningScript
    var second_route_validation_tuning: RouteValidationTuningScript = second_tuning.route_validation_tuning as RouteValidationTuningScript
    var first_easy_profile: BandFieldProfileScript = first_tuning.easy_field_profile as BandFieldProfileScript
    var second_easy_profile: BandFieldProfileScript = second_tuning.easy_field_profile as BandFieldProfileScript

    assert_not_null(first_definition)
    assert_not_null(second_definition)
    assert_not_null(first_route_validation_tuning)
    assert_not_null(second_route_validation_tuning)
    assert_not_null(first_easy_profile)
    assert_not_null(second_easy_profile)
    assert_ne(first_definition, second_definition)
    assert_ne(first_definition.surface_profile, second_definition.surface_profile)
    assert_ne(first_definition.lifecycle_rule, second_definition.lifecycle_rule)
    assert_ne(first_definition.movement_rule, second_definition.movement_rule)
    assert_ne(first_route_validation_tuning, second_route_validation_tuning)
    assert_ne(first_easy_profile, second_easy_profile)

func test_invalid_generation_tuning_is_detected() -> void:
    var tuning = GenerationTuningScript.new()
    tuning.generator_version = ""

    assert_false(tuning.is_valid())

func test_generation_tuning_rejects_non_positive_chunk_width() -> void:
    var tuning = GenerationTuningScript.new()
    tuning.chunk_width_meters = 0.0

    assert_false(tuning.is_valid())

func test_generation_tuning_rejects_non_increasing_difficulty_band_heights() -> void:
    var tuning = GenerationTuningScript.new()
    tuning.baseline_band_max_height_meters = tuning.easy_band_max_height_meters

    assert_false(tuning.is_valid())

func test_generation_tuning_rejects_a_band_profile_needing_more_routes_than_corridors() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var profile: BandFieldProfileScript = tuning.get_field_profile(ChunkDifficultyBandScript.Value.BASELINE)
    profile.required_route_count = profile.corridor_count + 1

    assert_false(tuning.is_valid())

func test_generation_tuning_rejects_opener_row_outside_the_first_chunk() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    tuning.opener_first_row_height_meters = tuning.segment_height_meters

    assert_false(tuning.is_valid())

func test_band_field_profile_rejects_route_moves_shorter_than_hold_spacing() -> void:
    var profile: BandFieldProfileScript = BandFieldProfileScript.new()
    profile.max_route_move_meters = profile.corridor_hold_spacing_meters

    assert_false(profile.is_valid())

func test_band_field_profile_rejects_a_keep_ratio_outside_zero_to_one() -> void:
    var profile: BandFieldProfileScript = BandFieldProfileScript.new()
    profile.extra_hold_keep_ratio = 1.1

    assert_false(profile.is_valid())

func test_band_field_profile_rejects_a_move_floor_above_its_ceiling() -> void:
    var profile: BandFieldProfileScript = BandFieldProfileScript.new()
    profile.min_easiest_route_move_meters = profile.max_route_move_meters

    assert_false(profile.is_valid())

func test_generation_tuning_rejects_invalid_route_validation_tuning() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var route_validation_tuning: RouteValidationTuningScript = tuning.route_validation_tuning as RouteValidationTuningScript

    assert_not_null(route_validation_tuning)
    route_validation_tuning.candidate_attempt_count = 0

    assert_false(tuning.is_valid())

func test_generation_tuning_rejects_static_reach_above_swing_envelope() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var route_validation_tuning: RouteValidationTuningScript = tuning.route_validation_tuning as RouteValidationTuningScript
    route_validation_tuning.static_reach_distance_meters = route_validation_tuning.max_move_distance_meters + 0.01

    assert_false(tuning.is_valid())

func test_generation_tuning_rejects_missing_route_validation_tuning() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    tuning.route_validation_tuning = null

    assert_false(tuning.is_valid())

func test_generation_tuning_rejects_missing_band_field_profile() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    tuning.challenge_field_profile = null

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
    theme.chaser_sprite_frames = load("res://resources/config/chaser_run_animation.tres") as SpriteFrames
    theme.pulse_max_frequency_hz = 0.25
    theme.pulse_min_frequency_hz = 0.5

    assert_false(theme.is_valid())

func test_chaser_theme_rejects_non_positive_audio_curve_exponents() -> void:
    var theme := ChaserThemeScript.new()
    theme.audio_loop_stream = load("res://assets/audio/chaser_pressure_loop.tres") as AudioStream
    theme.chaser_sprite_frames = load("res://resources/config/chaser_run_animation.tres") as SpriteFrames
    theme.audio_pitch_curve_exponent = 0.0

    assert_false(theme.is_valid())

func test_chaser_theme_requires_sprite_frames() -> void:
    var theme := ChaserThemeScript.new()
    theme.audio_loop_stream = load("res://assets/audio/chaser_pressure_loop.tres") as AudioStream

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
    assert_not_null(rising_void_theme.chaser_sprite_frames)
    assert_not_null(hot_coffee_theme.chaser_sprite_frames)
    assert_not_null(glitch_theme.chaser_sprite_frames)
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
