class_name GenerationTuning
extends Resource

const BandFieldProfileScript = preload("res://resources/config/band_field_profile.gd")
const ChunkDifficultyBandScript = preload("res://src/gameplay/generation/chunk_difficulty_band.gd")
const HandholdTypeDefinitionCatalogScript = preload("res://resources/config/handhold_type_definition_catalog.gd")
const HandholdTypeDefinitionScript = preload("res://resources/config/handhold_type_definition.gd")
const RouteValidationTuningScript = preload("res://resources/config/route_validation_tuning.gd")
const HandholdTypeScript = preload("res://src/gameplay/generation/handhold_type.gd")
const DefaultHandholdTypeDefinitionCatalogResource = preload("res://resources/config/handhold_type_definition_catalog.tres")
const DefaultRouteValidationTuningResource = preload("res://resources/config/route_validation_tuning.tres")
const DefaultEasyFieldProfileResource = preload("res://resources/config/band_field_profile_easy.tres")
const DefaultBaselineFieldProfileResource = preload("res://resources/config/band_field_profile_baseline.tres")
const DefaultChallengeFieldProfileResource = preload("res://resources/config/band_field_profile_challenge.tres")

## Generator version prefix embedded into seed keys and chunk metadata.
@export var generator_version: String = DailySeedKey.GENERATOR_VERSION
## Vertical meters covered by one generated chunk before the next chunk begins.
@export var segment_height_meters: float = 12.0
## Full width of the climbing wall. Wider than the visible screen; the camera pans.
@export var chunk_width_meters: float = 14.0
## Holds keep at least this far from either wall edge.
@export var wall_side_margin_meters: float = 0.5
## Height of the two fixed starter holds above the reset anchor in chunk 0.
@export var opener_first_row_height_meters: float = 0.72
## Two routes only count as different choices when they stay at least this far apart
## horizontally at matching heights.
@export var route_separation_meters: float = 1.75
## Top slice of a chunk the next chunk builds on: those holds seed the next field and
## are its route sources, so a seam is just more wall.
@export var seam_band_height_meters: float = 2.4
## Height ceiling for the easy difficulty band.
@export var easy_band_max_height_meters: float = 50.0
## Height ceiling for the baseline difficulty band before challenge-band rules begin.
@export var baseline_band_max_height_meters: float = 100.0
## Number of chunks kept spawned ahead of the current camera anchor.
@export var chunk_spawn_ahead_count: int = 3
## Number of chunks retained behind the current camera anchor.
@export var chunk_keep_behind_count: int = 1
## Player reach envelope, entry anchors, and candidate budget.
@export var route_validation_tuning: Resource = _duplicate_default(DefaultRouteValidationTuningResource, RouteValidationTuningScript)
## Hold-field knobs per difficulty band.
@export var easy_field_profile: Resource = _duplicate_default(DefaultEasyFieldProfileResource, BandFieldProfileScript)
@export var baseline_field_profile: Resource = _duplicate_default(DefaultBaselineFieldProfileResource, BandFieldProfileScript)
@export var challenge_field_profile: Resource = _duplicate_default(DefaultChallengeFieldProfileResource, BandFieldProfileScript)
## Typed handhold definitions keyed by HandholdType for generation and runtime setup.
@export var handhold_definitions: Array[Resource] = _duplicate_default_handhold_definitions()

var route_validation_candidate_attempt_count: int:
	get:
		return get_route_validation_tuning().candidate_attempt_count
	set(value):
		get_route_validation_tuning().candidate_attempt_count = value

func get_half_usable_width_meters() -> float:
	return chunk_width_meters * 0.5 - wall_side_margin_meters

func is_valid() -> bool:
	return generator_version != "" \
		and segment_height_meters > 0.0 \
		and chunk_width_meters > 0.0 \
		and wall_side_margin_meters >= 0.0 \
		and wall_side_margin_meters < chunk_width_meters * 0.25 \
		and opener_first_row_height_meters > 0.0 \
		and opener_first_row_height_meters < segment_height_meters \
		and route_separation_meters > 0.0 \
		and route_separation_meters < chunk_width_meters \
		and seam_band_height_meters > 0.0 \
		and seam_band_height_meters < segment_height_meters * 0.5 \
		and easy_band_max_height_meters > 0.0 \
		and baseline_band_max_height_meters > easy_band_max_height_meters \
		and chunk_spawn_ahead_count >= 1 \
		and chunk_keep_behind_count >= 0 \
		and _typed_resource_is_valid(route_validation_tuning, RouteValidationTuningScript) \
		and _typed_resource_is_valid(easy_field_profile, BandFieldProfileScript) \
		and _typed_resource_is_valid(baseline_field_profile, BandFieldProfileScript) \
		and _typed_resource_is_valid(challenge_field_profile, BandFieldProfileScript) \
		and _handhold_definitions_are_valid()

func validate() -> void:
	assert_valid()

func assert_valid() -> void:
	Validation.require_condition(generator_version != "", "Generation config requires a generator version.")
	Validation.require_condition(segment_height_meters > 0.0, "Generation segment height must be positive.")
	Validation.require_condition(chunk_width_meters > 0.0, "Generation chunk width must be positive.")
	Validation.require_condition(wall_side_margin_meters >= 0.0, "Generation wall side margin cannot be negative.")
	Validation.require_condition(wall_side_margin_meters < chunk_width_meters * 0.25, "Generation wall side margin must leave most of the wall usable.")
	Validation.require_condition(opener_first_row_height_meters > 0.0, "Generation opener first-row height must be positive.")
	Validation.require_condition(opener_first_row_height_meters < segment_height_meters, "Generation opener first row must sit inside the first chunk.")
	Validation.require_condition(route_separation_meters > 0.0, "Generation route separation must be positive.")
	Validation.require_condition(route_separation_meters < chunk_width_meters, "Generation route separation must fit inside the wall.")
	Validation.require_condition(seam_band_height_meters > 0.0, "Generation seam band height must be positive.")
	Validation.require_condition(seam_band_height_meters < segment_height_meters * 0.5, "Generation seam band must stay below half the chunk height.")
	Validation.require_condition(easy_band_max_height_meters > 0.0, "Generation easy-band max height must be positive.")
	Validation.require_condition(
		baseline_band_max_height_meters > easy_band_max_height_meters,
		"Generation baseline-band max height must be greater than the easy-band max height."
	)
	Validation.require_condition(chunk_spawn_ahead_count >= 1, "Generation config must keep at least one chunk ahead of the camera.")
	Validation.require_condition(chunk_keep_behind_count >= 0, "Generation config cannot keep a negative number of chunks behind the camera.")
	get_route_validation_tuning().assert_valid()
	get_field_profile(ChunkDifficultyBandScript.Value.EASY).assert_valid()
	get_field_profile(ChunkDifficultyBandScript.Value.BASELINE).assert_valid()
	get_field_profile(ChunkDifficultyBandScript.Value.CHALLENGE).assert_valid()
	_assert_valid_handhold_definitions()

func get_route_validation_tuning() -> RouteValidationTuningScript:
	Validation.require_condition(route_validation_tuning is RouteValidationTuningScript, "Generation config requires RouteValidationTuning.")
	return route_validation_tuning as RouteValidationTuningScript

func get_field_profile(difficulty_band: int) -> BandFieldProfileScript:
	ChunkDifficultyBandScript.assert_valid(difficulty_band)
	var profile: Resource = easy_field_profile
	match difficulty_band:
		ChunkDifficultyBandScript.Value.BASELINE:
			profile = baseline_field_profile
		ChunkDifficultyBandScript.Value.CHALLENGE:
			profile = challenge_field_profile
	Validation.require_condition(profile is BandFieldProfileScript, "Generation config requires a BandFieldProfile for %s." % ChunkDifficultyBandScript.to_label(difficulty_band))
	return profile as BandFieldProfileScript

func get_required_handhold_definition(handhold_type: int) -> HandholdTypeDefinitionScript:
	HandholdTypeScript.assert_valid(handhold_type)
	for definition_resource in handhold_definitions:
		var typed_definition: HandholdTypeDefinitionScript = definition_resource as HandholdTypeDefinitionScript
		if typed_definition != null and typed_definition.handhold_type == handhold_type:
			return typed_definition

	Validation.require_condition(false, "Generation config requires a handhold definition for %s." % HandholdTypeScript.to_label(handhold_type))
	return null

static func _has_script(resource: Resource, script: GDScript) -> bool:
	return is_same(resource.get_script(), script)

func _typed_resource_is_valid(resource: Resource, script: GDScript) -> bool:
	if resource == null or not _has_script(resource, script):
		return false
	var valid: Variant = resource.call("is_valid")
	return valid is bool and valid

func _handhold_definitions_are_valid() -> bool:
	if handhold_definitions.is_empty():
		return false

	var seen_definition_ids: Dictionary[StringName, bool] = {}
	var seen_handhold_types: Dictionary[int, bool] = {}
	for definition_resource in handhold_definitions:
		if definition_resource == null or not definition_resource is HandholdTypeDefinitionScript:
			return false
		var typed_definition: HandholdTypeDefinitionScript = definition_resource as HandholdTypeDefinitionScript
		if not typed_definition.is_valid():
			return false
		if seen_definition_ids.has(typed_definition.definition_id) or seen_handhold_types.has(typed_definition.handhold_type):
			return false
		seen_definition_ids[typed_definition.definition_id] = true
		seen_handhold_types[typed_definition.handhold_type] = true

	for handhold_type in HandholdTypeScript.get_all_values():
		if not seen_handhold_types.has(handhold_type):
			return false
	return true

func _assert_valid_handhold_definitions() -> void:
	Validation.require_condition(not handhold_definitions.is_empty(), "Generation config requires at least one handhold definition.")

	var seen_definition_ids: Dictionary[StringName, bool] = {}
	var seen_handhold_types: Dictionary[int, bool] = {}
	for definition_resource in handhold_definitions:
		Validation.require_condition(definition_resource != null, "Generation config handhold definitions cannot contain null entries.")
		Validation.require_condition(
			definition_resource is HandholdTypeDefinitionScript,
			"Generation config handhold definitions must use HandholdTypeDefinition resources."
		)
		var typed_definition: HandholdTypeDefinitionScript = definition_resource as HandholdTypeDefinitionScript
		typed_definition.assert_valid()
		Validation.require_condition(not seen_definition_ids.has(typed_definition.definition_id), "Generation config handhold definition ids must be unique.")
		Validation.require_condition(not seen_handhold_types.has(typed_definition.handhold_type), "Generation config handhold types must be unique.")
		seen_definition_ids[typed_definition.definition_id] = true
		seen_handhold_types[typed_definition.handhold_type] = true

	for handhold_type in HandholdTypeScript.get_all_values():
		Validation.require_condition(
			seen_handhold_types.has(handhold_type),
			"Generation config requires a handhold definition for %s." % HandholdTypeScript.to_label(handhold_type)
		)

static func _duplicate_default_handhold_definitions() -> Array[Resource]:
	Validation.require_condition(
		DefaultHandholdTypeDefinitionCatalogResource is HandholdTypeDefinitionCatalogScript,
		"Generation config default handhold type definitions must use HandholdTypeDefinitionCatalog resources."
	)
	var typed_catalog: HandholdTypeDefinitionCatalogScript = DefaultHandholdTypeDefinitionCatalogResource as HandholdTypeDefinitionCatalogScript
	typed_catalog.assert_valid()
	return typed_catalog.duplicate_definitions()

static func _duplicate_default(default_resource: Resource, script: GDScript) -> Resource:
	var has_script: bool = default_resource != null and _has_script(default_resource, script)
	Validation.require_condition(has_script, "Generation config requires an authored default %s resource." % script.resource_path)
	var duplicated_resource: Resource = default_resource.duplicate(true)
	Validation.require_condition(_has_script(duplicated_resource, script), "Generation config duplicated resource must keep its script.")
	return duplicated_resource
