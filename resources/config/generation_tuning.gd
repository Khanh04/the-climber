class_name GenerationTuning
extends Resource

const HandholdTypeDefinitionCatalogScript = preload("res://resources/config/handhold_type_definition_catalog.gd")
const HandholdTypeDefinitionScript = preload("res://resources/config/handhold_type_definition.gd")
const RouteProfileTuningScript = preload("res://resources/config/route_profile_tuning.gd")
const RouteValidationTuningScript = preload("res://resources/config/route_validation_tuning.gd")
const HandholdTypeScript = preload("res://src/gameplay/generation/handhold_type.gd")
const DefaultHandholdTypeDefinitionCatalogResource = preload("res://resources/config/handhold_type_definition_catalog.tres")
const DefaultRouteValidationTuningResource = preload("res://resources/config/route_validation_tuning.tres")
const DefaultRouteProfileTuningResource = preload("res://resources/config/route_profile_tuning.tres")

## Generator version prefix embedded into daily seed keys and chunk metadata.
@export var generator_version: String = DailySeedKey.GENERATOR_VERSION
## Vertical meters covered by one generated chunk before the next chunk begins.
@export var segment_height_meters: float = 12.0
## Horizontal meters available for generated lanes inside a chunk.
@export var chunk_width_meters: float = 8.0
## Ratio of half-width used for the inner left and inner right lane anchors.
@export var inner_lane_position_ratio: float = 0.425
## Ratio of half-width used for the outer left and outer right lane anchors.
@export var outer_lane_position_ratio: float = 0.85
## Height of the opener's first reachable row above the reset anchor.
@export var opener_first_row_height_meters: float = 0.72
## Clearance kept between the top of the opener route and the chunk ceiling.
@export var opener_top_padding_meters: float = 1.5
## Maximum lateral meters applied to generated handholds after lane placement; noise is sampled from -1.0 to 1.0 and scaled by this value.
@export var handhold_horizontal_jitter_meters: float = 0.08
## Maximum vertical meters applied to each generated handhold after row placement; noise is sampled from -1.0 to 1.0 and scaled by this value.
@export var handhold_vertical_jitter_meters: float = 0.2
## Height ceiling for the easy difficulty band.
@export var easy_band_max_height_meters: float = 50.0
## Height ceiling for the baseline difficulty band before challenge-band rules begin.
@export var baseline_band_max_height_meters: float = 100.0
## Number of chunks kept spawned ahead of the current camera anchor.
@export var chunk_spawn_ahead_count: int = 3
## Number of chunks retained behind the current camera anchor.
@export var chunk_keep_behind_count: int = 1
## Conservative route validation envelope, role-zone boundaries, and retry budget.
@export var route_validation_tuning: Resource = _duplicate_default_route_validation_tuning()
## Weighted profile scheduling knobs for future bouldering-aware chunk selection.
@export var route_profile_tuning: Resource = _duplicate_default_route_profile_tuning()
## Typed handhold definitions keyed by HandholdType for generation and runtime setup.
@export var handhold_definitions: Array[Resource] = _duplicate_default_handhold_definitions()

var route_validation_candidate_attempt_count: int:
	get:
		return _get_required_route_validation_tuning().candidate_attempt_count
	set(value):
		_get_required_route_validation_tuning().candidate_attempt_count = value

func is_valid() -> bool:
	_ensure_required_default_backing_resources()
	return generator_version != "" \
		and segment_height_meters > 0.0 \
		and chunk_width_meters > 0.0 \
		and inner_lane_position_ratio > 0.0 \
		and outer_lane_position_ratio > inner_lane_position_ratio \
		and outer_lane_position_ratio < 1.0 \
		and opener_first_row_height_meters > 0.0 \
		and opener_top_padding_meters >= 0.0 \
		and opener_first_row_height_meters + opener_top_padding_meters < segment_height_meters \
		and handhold_horizontal_jitter_meters >= 0.0 \
		and handhold_horizontal_jitter_meters < chunk_width_meters * 0.25 \
		and handhold_vertical_jitter_meters >= 0.0 \
		and handhold_vertical_jitter_meters < opener_first_row_height_meters * 0.5 \
		and easy_band_max_height_meters > 0.0 \
		and baseline_band_max_height_meters > easy_band_max_height_meters \
		and chunk_spawn_ahead_count >= 1 \
		and chunk_keep_behind_count >= 0 \
		and _route_validation_tuning_is_valid() \
		and _route_profile_tuning_is_valid() \
		and _handhold_definitions_are_valid()

func validate() -> void:
	assert_valid()

func assert_valid() -> void:
	_ensure_required_default_backing_resources()
	Validation.require_condition(generator_version != "", "Generation config requires a generator version.")
	Validation.require_condition(segment_height_meters > 0.0, "Generation segment height must be positive.")
	Validation.require_condition(chunk_width_meters > 0.0, "Generation chunk width must be positive.")
	Validation.require_condition(inner_lane_position_ratio > 0.0, "Generation inner lane position ratio must be positive.")
	Validation.require_condition(
		outer_lane_position_ratio > inner_lane_position_ratio,
        "Generation outer lane position ratio must be greater than the inner lane position ratio."
	)
	Validation.require_condition(outer_lane_position_ratio < 1.0, "Generation outer lane position ratio must stay inside the chunk width.")
	Validation.require_condition(opener_first_row_height_meters > 0.0, "Generation opener first-row height must be positive.")
	Validation.require_condition(opener_top_padding_meters >= 0.0, "Generation opener top padding cannot be negative.")
	Validation.require_condition(
		opener_first_row_height_meters + opener_top_padding_meters < segment_height_meters,
        "Generation opener spacing must leave vertical room inside the chunk."
	)
	Validation.require_condition(handhold_horizontal_jitter_meters >= 0.0, "Generation handhold horizontal jitter cannot be negative.")
	Validation.require_condition(
		handhold_horizontal_jitter_meters < chunk_width_meters * 0.25,
        "Generation handhold horizontal jitter must stay below center-to-inner lane spacing."
	)
	Validation.require_condition(handhold_vertical_jitter_meters >= 0.0, "Generation handhold vertical jitter cannot be negative.")
	Validation.require_condition(
		handhold_vertical_jitter_meters < opener_first_row_height_meters * 0.5,
        "Generation handhold vertical jitter must stay below half the first-row height."
	)
	Validation.require_condition(easy_band_max_height_meters > 0.0, "Generation easy-band max height must be positive.")
	Validation.require_condition(
		baseline_band_max_height_meters > easy_band_max_height_meters,
        "Generation baseline-band max height must be greater than the easy-band max height."
	)
	Validation.require_condition(chunk_spawn_ahead_count >= 1, "Generation config must keep at least one chunk ahead of the camera.")
	Validation.require_condition(chunk_keep_behind_count >= 0, "Generation config cannot keep a negative number of chunks behind the camera.")
	_assert_valid_route_validation_tuning()
	_assert_valid_route_profile_tuning()
	_assert_valid_handhold_definitions()

func get_required_handhold_definition(handhold_type: int) -> HandholdTypeDefinitionScript:
	HandholdTypeScript.assert_valid(handhold_type)
	assert_valid()

	for definition_resource in handhold_definitions:
		var typed_definition: HandholdTypeDefinitionScript = definition_resource as HandholdTypeDefinitionScript
		if typed_definition.handhold_type == handhold_type:
			return typed_definition

	Validation.require_condition(false, "Generation config requires a handhold definition for %s." % HandholdTypeScript.to_label(handhold_type))
	return null

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

		if seen_definition_ids.has(typed_definition.definition_id):
			return false

		if seen_handhold_types.has(typed_definition.handhold_type):
			return false

		seen_definition_ids[typed_definition.definition_id] = true
		seen_handhold_types[typed_definition.handhold_type] = true

	for handhold_type in HandholdTypeScript.get_all_values():
		if not seen_handhold_types.has(handhold_type):
			return false

	return true

func _route_validation_tuning_is_valid() -> bool:
	if route_validation_tuning == null or not route_validation_tuning is RouteValidationTuningScript:
		return false

	var typed_tuning: RouteValidationTuningScript = route_validation_tuning as RouteValidationTuningScript
	return typed_tuning.is_valid()

func _route_profile_tuning_is_valid() -> bool:
	if route_profile_tuning == null or not route_profile_tuning is RouteProfileTuningScript:
		return false

	var typed_tuning: RouteProfileTuningScript = route_profile_tuning as RouteProfileTuningScript
	return typed_tuning.is_valid()

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
		Validation.require_condition(
			not seen_definition_ids.has(typed_definition.definition_id),
            "Generation config handhold definition ids must be unique."
		)
		Validation.require_condition(
			not seen_handhold_types.has(typed_definition.handhold_type),
            "Generation config handhold types must be unique."
		)
		seen_definition_ids[typed_definition.definition_id] = true
		seen_handhold_types[typed_definition.handhold_type] = true

	for handhold_type in HandholdTypeScript.get_all_values():
		Validation.require_condition(
			seen_handhold_types.has(handhold_type),
			"Generation config requires a handhold definition for %s." % HandholdTypeScript.to_label(handhold_type)
		)

func _assert_valid_route_validation_tuning() -> void:
	Validation.require_condition(route_validation_tuning != null, "Generation config requires route validation tuning.")
	Validation.require_condition(
		route_validation_tuning is RouteValidationTuningScript,
        "Generation config route validation tuning must use RouteValidationTuning resources."
	)
	var typed_tuning: RouteValidationTuningScript = route_validation_tuning as RouteValidationTuningScript
	typed_tuning.assert_valid()

func _assert_valid_route_profile_tuning() -> void:
	Validation.require_condition(route_profile_tuning != null, "Generation config requires route profile tuning.")
	Validation.require_condition(
		route_profile_tuning is RouteProfileTuningScript,
        "Generation config route profile tuning must use RouteProfileTuning resources."
	)
	var typed_tuning: RouteProfileTuningScript = route_profile_tuning as RouteProfileTuningScript
	typed_tuning.assert_valid()

func _ensure_required_default_backing_resources() -> void:
	if route_validation_tuning == null:
		route_validation_tuning = _duplicate_default_route_validation_tuning()

	if route_profile_tuning == null:
		route_profile_tuning = _duplicate_default_route_profile_tuning()

static func _duplicate_default_handhold_definitions() -> Array[Resource]:
	Validation.require_condition(
		DefaultHandholdTypeDefinitionCatalogResource != null,
        "Generation config requires an authored default handhold type definition catalog resource."
	)
	Validation.require_condition(
		DefaultHandholdTypeDefinitionCatalogResource is HandholdTypeDefinitionCatalogScript,
        "Generation config default handhold type definitions must use HandholdTypeDefinitionCatalog resources."
	)

	var typed_catalog: HandholdTypeDefinitionCatalogScript = DefaultHandholdTypeDefinitionCatalogResource as HandholdTypeDefinitionCatalogScript
	typed_catalog.assert_valid()
	return typed_catalog.duplicate_definitions()


static func _duplicate_default_route_validation_tuning() -> Resource:
	Validation.require_condition(
		DefaultRouteValidationTuningResource != null,
        "Generation config requires an authored default route validation tuning resource."
	)
	Validation.require_condition(
		DefaultRouteValidationTuningResource is RouteValidationTuningScript,
        "Generation config default route validation tuning must use RouteValidationTuning resources."
	)

	var duplicated_resource: Resource = DefaultRouteValidationTuningResource.duplicate(true)
	Validation.require_condition(
		duplicated_resource is RouteValidationTuningScript,
        "Generation config duplicated route validation tuning must remain a RouteValidationTuning resource."
	)
	return duplicated_resource

static func _duplicate_default_route_profile_tuning() -> Resource:
	Validation.require_condition(
		DefaultRouteProfileTuningResource != null,
        "Generation config requires an authored default route profile tuning resource."
	)
	Validation.require_condition(
		DefaultRouteProfileTuningResource is RouteProfileTuningScript,
        "Generation config default route profile tuning must use RouteProfileTuning resources."
	)

	var duplicated_resource: Resource = DefaultRouteProfileTuningResource.duplicate(true)
	Validation.require_condition(
		duplicated_resource is RouteProfileTuningScript,
        "Generation config duplicated route profile tuning must remain a RouteProfileTuning resource."
	)
	return duplicated_resource

func _get_required_route_validation_tuning() -> RouteValidationTuningScript:
	_ensure_required_default_backing_resources()
	Validation.require_condition(route_validation_tuning != null, "Generation config requires route validation tuning before access.")
	Validation.require_condition(
		route_validation_tuning is RouteValidationTuningScript,
        "Generation config route validation tuning must use RouteValidationTuning resources before access."
	)
	var typed_tuning: RouteValidationTuningScript = route_validation_tuning as RouteValidationTuningScript
	return typed_tuning
