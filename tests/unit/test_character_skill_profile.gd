extends GutTest

const CharacterSkillProfileScript = preload("res://resources/config/character_skill_profile.gd")
const PlayerAppearanceCatalogScript = preload("res://resources/config/player_appearance_catalog.gd")

func _valid_profile() -> CharacterSkillProfileScript:
	var profile: CharacterSkillProfileScript = CharacterSkillProfileScript.new()
	profile.passive_name = "Catch"
	profile.active_name = "Chalk Up"
	profile.description = "Test kit."
	return profile

func test_profile_with_names_and_positive_values_is_valid() -> void:
	assert_true(_valid_profile().is_valid())

func test_profile_rejects_non_positive_multipliers() -> void:
	var profile: CharacterSkillProfileScript = _valid_profile()
	profile.max_stamina_multiplier = 0.0
	assert_false(profile.is_valid())

	profile = _valid_profile()
	profile.hazard_impulse_multiplier = -1.0
	assert_false(profile.is_valid())

	profile = _valid_profile()
	profile.cooldown_seconds = 0.0
	assert_false(profile.is_valid())

func test_profile_magnitude_range_depends_on_active_kind() -> void:
	var profile: CharacterSkillProfileScript = _valid_profile()
	profile.magnitude = 1.5
	assert_false(profile.is_valid(), "Chalk Up cannot restore more than the full pool.")

	profile.active_kind = CharacterSkillProfileScript.ActiveKind.WEB_SWING
	assert_true(profile.is_valid())

	profile.magnitude = 1.0
	assert_false(profile.is_valid(), "Web Swing must reach beyond the normal grab radius.")

func test_every_catalog_character_carries_a_distinct_valid_kit() -> void:
	var catalog: PlayerAppearanceCatalogScript = load("res://resources/config/player_appearance_catalog.tres") as PlayerAppearanceCatalogScript
	var kinds: Dictionary[int, StringName] = {}

	for appearance in catalog.get_all_appearances():
		assert_not_null(appearance.skill_profile, "%s needs a skill profile." % appearance.appearance_id)
		assert_true(appearance.skill_profile.is_valid())
		kinds[appearance.skill_profile.active_kind] = appearance.appearance_id

	assert_eq(kinds.size(), catalog.get_all_appearances().size(), "Each character should have its own active skill.")

func test_catalog_kits_match_designed_characters() -> void:
	var catalog: PlayerAppearanceCatalogScript = load("res://resources/config/player_appearance_catalog.tres") as PlayerAppearanceCatalogScript

	var human: CharacterSkillProfileScript = catalog.get_required_appearance_by_id(&"human").skill_profile
	assert_true(human.auto_catch)
	assert_eq(human.active_kind, CharacterSkillProfileScript.ActiveKind.CHALK_UP)

	var spartan: CharacterSkillProfileScript = catalog.get_required_appearance_by_id(&"spartan").skill_profile
	assert_gt(spartan.max_stamina_multiplier, 1.0)
	assert_lt(spartan.swing_force_multiplier, 1.0)
	assert_eq(spartan.active_kind, CharacterSkillProfileScript.ActiveKind.SPARTAN_KICK)

	var webhead: CharacterSkillProfileScript = catalog.get_required_appearance_by_id(&"webhead").skill_profile
	assert_true(webhead.caps_hold_drain)
	assert_lt(webhead.max_stamina_multiplier, 1.0)
	assert_eq(webhead.active_kind, CharacterSkillProfileScript.ActiveKind.WEB_SWING)
