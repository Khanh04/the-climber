class_name GenerationTuning
extends Resource

const HandholdAssignmentRuleCatalogScript = preload("res://resources/config/handhold_assignment_rule_catalog.gd")
const HandholdAssignmentRuleScript = preload("res://resources/config/handhold_assignment_rule.gd")
const HandholdTypeDefinitionCatalogScript = preload("res://resources/config/handhold_type_definition_catalog.gd")
const HandholdTypeDefinitionScript = preload("res://resources/config/handhold_type_definition.gd")
const RouteProfileTuningScript = preload("res://resources/config/route_profile_tuning.gd")
const RouteValidationTuningScript = preload("res://resources/config/route_validation_tuning.gd")
const HandholdTypeScript = preload("res://src/gameplay/generation/handhold_type.gd")
const DefaultHandholdTypeDefinitionCatalogResource = preload("res://resources/config/handhold_type_definition_catalog.tres")
const DefaultHandholdAssignmentRuleCatalogResource = preload("res://resources/config/handhold_assignment_rule_catalog.tres")
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
## Vertical offset applied before non-opener chunk rows begin climbing away from the chunk base.
@export var non_opener_row_base_height_meters: float = 1.5
## Portion of each chunk's placeholder sockets reserved for pickups before hazards take the remainder.
@export var pickup_socket_ratio: float = 0.6
## Maximum lateral meters a generated pickup can drift from its anchor handhold.
@export var pickup_lateral_offset_meters: float = 0.28
## Minimum side alignment a handhold must satisfy before pickup placement treats it as part of the risky branch.
@export var pickup_branch_side_alignment_meters: float = 0.25
## Minimum side alignment a handhold must satisfy before hazard placement treats it as part of the risky branch.
@export var hazard_branch_side_alignment_meters: float = 0.25
## Height ceiling for the easy difficulty band.
@export var easy_band_max_height_meters: float = 50.0
## Height ceiling for the baseline difficulty band before challenge-band rules begin.
@export var baseline_band_max_height_meters: float = 100.0
## Number of chunks kept spawned ahead of the current camera anchor.
@export var chunk_spawn_ahead_count: int = 3
## Number of chunks retained behind the current camera anchor.
@export var chunk_keep_behind_count: int = 1
## Total placeholder sockets per chunk before pickup and hazard splits are applied.
@export var socket_count_per_chunk: int = 12
## Conservative route validation envelope, role-zone boundaries, and retry budget.
@export var route_validation_tuning: Resource = _duplicate_default_route_validation_tuning()
## Weighted profile scheduling knobs for future bouldering-aware chunk selection.
@export var route_profile_tuning: Resource = _duplicate_default_route_profile_tuning()
## Typed handhold definitions keyed by HandholdType for generation and runtime setup.
@export var handhold_definitions: Array[Resource] = _duplicate_default_handhold_definitions()
## Ordered handhold assignment rules matched by route slot, difficulty band, and row zone.
@export var handhold_assignment_rules: Array[Resource] = _duplicate_default_handhold_assignment_rules()
## Vertical spacing between LADDER template rows.
@export var ladder_row_step_height_meters: float = 1.0
## Vertical spacing between ZIGZAG template rows.
@export var zigzag_row_step_height_meters: float = 1.05
## Vertical spacing between WIDE_TRAVERSE template rows.
@export var wide_traverse_row_step_height_meters: float = 1.08
## Vertical spacing between SPARSE_REACH template rows.
@export var sparse_reach_row_step_height_meters: float = 1.16
## Vertical spacing between DENSE_RECOVERY template rows.
@export var dense_recovery_row_step_height_meters: float = 0.96
## Vertical spacing between FORK template rows.
@export var fork_row_step_height_meters: float = 1.08
## Vertical spacing between RISK_LANE template rows.
@export var risk_lane_row_step_height_meters: float = 1.1
## Vertical spacing between SWING_GAP template rows.
@export var swing_gap_row_step_height_meters: float = 1.2
## Vertical spacing between opener LADDER template rows.
@export var opener_ladder_row_step_height_meters: float = 1.88
## Vertical spacing between opener ZIGZAG template rows.
@export var opener_zigzag_row_step_height_meters: float = 1.92
## Handhold rows for LADDER chunks; each row lists the lane indices spawned at one vertical step.
@export var ladder_hold_rows: Array[PackedInt32Array] = [
	PackedInt32Array([1, 2]),
	PackedInt32Array([1]),
	PackedInt32Array([2]),
	PackedInt32Array([1, 2]),
	PackedInt32Array([1]),
	PackedInt32Array([2]),
	PackedInt32Array([1, 2]),
]
## Handhold rows for ZIGZAG chunks; rows alternate lane groups before converging.
@export var zigzag_hold_rows: Array[PackedInt32Array] = [
	PackedInt32Array([0, 1]),
	PackedInt32Array([2, 3]),
	PackedInt32Array([0, 1]),
	PackedInt32Array([2, 3]),
	PackedInt32Array([1, 2]),
	PackedInt32Array([0, 3]),
]
## Handhold rows for WIDE_TRAVERSE chunks; rows encourage side-to-side movement across the full width.
@export var wide_traverse_hold_rows: Array[PackedInt32Array] = [
	PackedInt32Array([0, 1]),
	PackedInt32Array([1, 2]),
	PackedInt32Array([2, 3]),
	PackedInt32Array([1, 2]),
	PackedInt32Array([0, 1]),
	PackedInt32Array([2, 3]),
	PackedInt32Array([1, 2]),
]
## Handhold rows for SPARSE_REACH chunks; rows intentionally reduce intermediate options.
@export var sparse_reach_hold_rows: Array[PackedInt32Array] = [
	PackedInt32Array([0]),
	PackedInt32Array([3]),
	PackedInt32Array([1, 2]),
	PackedInt32Array([0]),
	PackedInt32Array([3]),
	PackedInt32Array([1, 2]),
]
## Handhold rows for DENSE_RECOVERY chunks; rows bias toward generous central catches and recoveries.
@export var dense_recovery_hold_rows: Array[PackedInt32Array] = [
	PackedInt32Array([1, 2]),
	PackedInt32Array([0, 1]),
	PackedInt32Array([1, 2]),
	PackedInt32Array([2, 3]),
	PackedInt32Array([1, 2]),
	PackedInt32Array([0, 1]),
	PackedInt32Array([1, 2]),
]
## Handhold rows for FORK chunks; rows keep left and right lines alive for several vertical steps.
@export var fork_hold_rows: Array[PackedInt32Array] = [
	PackedInt32Array([1, 2]),
	PackedInt32Array([0, 3]),
	PackedInt32Array([0, 3]),
	PackedInt32Array([1, 2]),
	PackedInt32Array([0, 3]),
	PackedInt32Array([0, 3]),
	PackedInt32Array([1, 2]),
]
## Handhold rows for RISK_LANE chunks; rows preserve a safer center option beside a wider risky branch.
@export var risk_lane_hold_rows: Array[PackedInt32Array] = [
	PackedInt32Array([1, 2]),
	PackedInt32Array([0, 2]),
	PackedInt32Array([1, 3]),
	PackedInt32Array([0, 2]),
	PackedInt32Array([1, 3]),
	PackedInt32Array([0, 2]),
	PackedInt32Array([1, 2]),
]
## Handhold rows for SWING_GAP chunks; rows create wider commitments with fewer recovery holds.
@export var swing_gap_hold_rows: Array[PackedInt32Array] = [
	PackedInt32Array([0]),
	PackedInt32Array([0, 2]),
	PackedInt32Array([3]),
	PackedInt32Array([1, 3]),
	PackedInt32Array([0]),
	PackedInt32Array([2]),
]
## Handhold rows for LADDER opener chunks. Paired rows use INNER_LEFT + INNER_RIGHT (not the
## adjacent INNER_LEFT + CENTER) so the now-solid holds leave a clear centre corridor the
## player body can swing up through.
@export var opener_ladder_hold_rows: Array[PackedInt32Array] = [
	PackedInt32Array([1, 3]),
	PackedInt32Array([1]),
	PackedInt32Array([2]),
	PackedInt32Array([0]),
	PackedInt32Array([3]),
	PackedInt32Array([1, 3]),
]
## Handhold rows for ZIGZAG opener chunks; rows keep the start readable while widening later choices.
@export var opener_zigzag_hold_rows: Array[PackedInt32Array] = [
	PackedInt32Array([1, 3]),
	PackedInt32Array([0]),
	PackedInt32Array([3]),
	PackedInt32Array([1]),
	PackedInt32Array([2]),
	PackedInt32Array([0, 3]),
]

var route_port_row_tolerance_meters: float:
	get:
		return _get_required_route_validation_tuning().route_port_row_tolerance_meters
	set(value):
		_get_required_route_validation_tuning().route_port_row_tolerance_meters = value

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
		and non_opener_row_base_height_meters > 0.0 \
		and pickup_socket_ratio > 0.0 \
		and pickup_socket_ratio < 1.0 \
		and pickup_lateral_offset_meters >= 0.0 \
		and pickup_branch_side_alignment_meters >= 0.0 \
		and pickup_branch_side_alignment_meters < _max_lane_alignment_meters() \
		and hazard_branch_side_alignment_meters >= 0.0 \
		and hazard_branch_side_alignment_meters < _max_lane_alignment_meters() \
		and easy_band_max_height_meters > 0.0 \
		and baseline_band_max_height_meters > easy_band_max_height_meters \
		and chunk_spawn_ahead_count >= 1 \
		and chunk_keep_behind_count >= 0 \
		and _route_validation_tuning_is_valid() \
		and _route_profile_tuning_is_valid() \
		and _handhold_definitions_are_valid() \
		and _handhold_assignment_rules_are_valid() \
		and socket_count_per_chunk > 0 \
		and _hold_rows_are_valid(ladder_hold_rows) \
		and _hold_rows_are_valid(zigzag_hold_rows) \
		and _hold_rows_are_valid(opener_ladder_hold_rows) \
		and _hold_rows_are_valid(opener_zigzag_hold_rows) \
		and _hold_rows_are_valid(wide_traverse_hold_rows) \
		and _hold_rows_are_valid(sparse_reach_hold_rows) \
		and _hold_rows_are_valid(dense_recovery_hold_rows) \
		and _hold_rows_are_valid(fork_hold_rows) \
		and _hold_rows_are_valid(risk_lane_hold_rows) \
		and _hold_rows_are_valid(swing_gap_hold_rows) \
		and _chunk_row_steps_are_valid() \
		and _opener_row_steps_are_valid()

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
	Validation.require_condition(non_opener_row_base_height_meters > 0.0, "Generation non-opener row base height must be positive.")
	Validation.require_condition(pickup_socket_ratio > 0.0, "Generation pickup socket ratio must be positive.")
	Validation.require_condition(pickup_socket_ratio < 1.0, "Generation pickup socket ratio must leave room for hazards.")
	Validation.require_condition(pickup_lateral_offset_meters >= 0.0, "Generation pickup lateral offset cannot be negative.")
	Validation.require_condition(
		pickup_branch_side_alignment_meters >= 0.0,
        "Generation pickup branch-side alignment cannot be negative."
	)
	Validation.require_condition(
		pickup_branch_side_alignment_meters < _max_lane_alignment_meters(),
        "Generation pickup branch-side alignment must stay inside the outer lane width."
	)
	Validation.require_condition(
		hazard_branch_side_alignment_meters >= 0.0,
        "Generation hazard branch-side alignment cannot be negative."
	)
	Validation.require_condition(
		hazard_branch_side_alignment_meters < _max_lane_alignment_meters(),
        "Generation hazard branch-side alignment must stay inside the outer lane width."
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
	_assert_valid_handhold_assignment_rules()
	Validation.require_condition(socket_count_per_chunk > 0, "Generation config must provide at least one socket per chunk.")
	_assert_valid_hold_rows("LADDER", ladder_hold_rows)
	_assert_valid_hold_rows("ZIGZAG", zigzag_hold_rows)
	_assert_valid_hold_rows("OPENER_LADDER", opener_ladder_hold_rows)
	_assert_valid_hold_rows("OPENER_ZIGZAG", opener_zigzag_hold_rows)
	_assert_valid_hold_rows("WIDE_TRAVERSE", wide_traverse_hold_rows)
	_assert_valid_hold_rows("SPARSE_REACH", sparse_reach_hold_rows)
	_assert_valid_hold_rows("DENSE_RECOVERY", dense_recovery_hold_rows)
	_assert_valid_hold_rows("FORK", fork_hold_rows)
	_assert_valid_hold_rows("RISK_LANE", risk_lane_hold_rows)
	_assert_valid_hold_rows("SWING_GAP", swing_gap_hold_rows)
	_assert_valid_chunk_row_steps()
	_assert_valid_opener_row_steps()

func get_pickup_socket_count() -> int:
	return ceili(float(socket_count_per_chunk) * pickup_socket_ratio)

func get_hazard_socket_count() -> int:
	return maxi(0, socket_count_per_chunk - get_pickup_socket_count())

func get_required_handhold_definition(handhold_type: int) -> HandholdTypeDefinitionScript:
	HandholdTypeScript.assert_valid(handhold_type)
	assert_valid()

	for definition_resource in handhold_definitions:
		var typed_definition: HandholdTypeDefinitionScript = definition_resource as HandholdTypeDefinitionScript
		if typed_definition.handhold_type == handhold_type:
			return typed_definition

	Validation.require_condition(false, "Generation config requires a handhold definition for %s." % HandholdTypeScript.to_label(handhold_type))
	return null

func get_allowed_handhold_types(route_slot: int, difficulty_band: int, row_index: int, row_count: int) -> Array[int]:
	ChunkRouteSlot.assert_valid(route_slot)
	ChunkDifficultyBand.assert_valid(difficulty_band)
	Validation.require_condition(row_count > 0, "Generation config handhold assignment requires at least one row.")
	Validation.require_condition(row_index >= 0 and row_index < row_count, "Generation config handhold assignment row index is out of bounds.")
	assert_valid()

	for assignment_rule_resource in handhold_assignment_rules:
		var typed_rule: HandholdAssignmentRuleScript = assignment_rule_resource as HandholdAssignmentRuleScript
		if typed_rule.matches(route_slot, difficulty_band, row_index, row_count):
			return typed_rule.get_allowed_handhold_types_copy()

	Validation.require_condition(
		false,
		"Generation config requires a handhold assignment rule for %s / %s at row %d of %d." % [
			ChunkRouteSlot.to_label(route_slot),
			ChunkDifficultyBand.to_label(difficulty_band),
			row_index,
			row_count,
		]
	)
	return []

func get_hold_rows(chunk_type: int) -> Array[PackedInt32Array]:
	ChunkType.assert_valid(chunk_type)

	match chunk_type:
		ChunkType.Value.LADDER:
			return ladder_hold_rows
		ChunkType.Value.ZIGZAG:
			return zigzag_hold_rows
		ChunkType.Value.WIDE_TRAVERSE:
			return wide_traverse_hold_rows
		ChunkType.Value.SPARSE_REACH:
			return sparse_reach_hold_rows
		ChunkType.Value.DENSE_RECOVERY:
			return dense_recovery_hold_rows
		ChunkType.Value.FORK:
			return fork_hold_rows
		ChunkType.Value.RISK_LANE:
			return risk_lane_hold_rows
		ChunkType.Value.SWING_GAP:
			return swing_gap_hold_rows
		_:
			Validation.require_condition(false, "Generation config requires a supported chunk type when fetching hold rows.")
			return []

func get_chunk_row_step_height_meters(chunk_type: int) -> float:
	ChunkType.assert_valid(chunk_type)

	match chunk_type:
		ChunkType.Value.LADDER:
			return ladder_row_step_height_meters
		ChunkType.Value.ZIGZAG:
			return zigzag_row_step_height_meters
		ChunkType.Value.WIDE_TRAVERSE:
			return wide_traverse_row_step_height_meters
		ChunkType.Value.SPARSE_REACH:
			return sparse_reach_row_step_height_meters
		ChunkType.Value.DENSE_RECOVERY:
			return dense_recovery_row_step_height_meters
		ChunkType.Value.FORK:
			return fork_row_step_height_meters
		ChunkType.Value.RISK_LANE:
			return risk_lane_row_step_height_meters
		ChunkType.Value.SWING_GAP:
			return swing_gap_row_step_height_meters
		_:
			Validation.require_condition(false, "Generation config requires a supported chunk type when fetching row-step height.")
			return 0.0

func get_opener_hold_rows(chunk_type: int) -> Array[PackedInt32Array]:
	ChunkType.assert_valid(chunk_type)

	match chunk_type:
		ChunkType.Value.LADDER:
			return opener_ladder_hold_rows
		ChunkType.Value.ZIGZAG:
			return opener_zigzag_hold_rows
		_:
			Validation.require_condition(false, "Generation config requires a supported opener chunk type when fetching hold rows.")
			return []

func get_opener_row_step_height_meters(chunk_type: int) -> float:
	ChunkType.assert_valid(chunk_type)

	match chunk_type:
		ChunkType.Value.LADDER:
			return opener_ladder_row_step_height_meters
		ChunkType.Value.ZIGZAG:
			return opener_zigzag_row_step_height_meters
		_:
			Validation.require_condition(false, "Generation config requires a supported opener chunk type when fetching row-step height.")
			return 0.0

func _hold_rows_are_valid(hold_rows: Array[PackedInt32Array]) -> bool:
	if hold_rows.size() == 0:
		return false

	for row_index in range(hold_rows.size()):
		var hold_row: PackedInt32Array = hold_rows[row_index]
		if hold_row.size() == 0:
			return false

		for lane_entry_index in range(hold_row.size()):
			var lane_index: int = hold_row[lane_entry_index]
			if lane_index < 0 or lane_index > 3:
				return false

	return true

func _chunk_row_steps_are_valid() -> bool:
	var chunk_types: Array[int] = [
		ChunkType.Value.LADDER,
		ChunkType.Value.ZIGZAG,
		ChunkType.Value.WIDE_TRAVERSE,
		ChunkType.Value.SPARSE_REACH,
		ChunkType.Value.DENSE_RECOVERY,
		ChunkType.Value.FORK,
		ChunkType.Value.RISK_LANE,
		ChunkType.Value.SWING_GAP,
	]

	for chunk_type in chunk_types:
		var row_step_height_meters: float = get_chunk_row_step_height_meters(chunk_type)
		if row_step_height_meters <= 0.0:
			return false

		var hold_rows: Array[PackedInt32Array] = get_hold_rows(chunk_type)
		if hold_rows.size() == 0:
			return false

		var last_row_height_meters: float = non_opener_row_base_height_meters + (row_step_height_meters * float(hold_rows.size()))
		if last_row_height_meters >= segment_height_meters:
			return false

	return true

func _opener_row_steps_are_valid() -> bool:
	var opener_chunk_types: Array[int] = [ChunkType.Value.LADDER, ChunkType.Value.ZIGZAG]
	var opener_ceiling_height_meters: float = segment_height_meters - opener_top_padding_meters

	for chunk_type in opener_chunk_types:
		var row_step_height_meters: float = get_opener_row_step_height_meters(chunk_type)
		if row_step_height_meters <= 0.0:
			return false

		var hold_rows: Array[PackedInt32Array] = get_opener_hold_rows(chunk_type)
		if hold_rows.size() == 0:
			return false

		var last_row_height_meters: float = opener_first_row_height_meters + (row_step_height_meters * float(maxi(0, hold_rows.size() - 1)))
		if last_row_height_meters > opener_ceiling_height_meters:
			return false

	return true

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

func _handhold_assignment_rules_are_valid() -> bool:
	if handhold_assignment_rules.is_empty():
		return false

	for assignment_rule_resource in handhold_assignment_rules:
		if assignment_rule_resource == null or not assignment_rule_resource is HandholdAssignmentRuleScript:
			return false

		var typed_rule: HandholdAssignmentRuleScript = assignment_rule_resource as HandholdAssignmentRuleScript
		if not typed_rule.is_valid():
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

func _assert_valid_handhold_assignment_rules() -> void:
	Validation.require_condition(
		not handhold_assignment_rules.is_empty(),
        "Generation config requires at least one handhold assignment rule."
	)

	for assignment_rule_resource in handhold_assignment_rules:
		Validation.require_condition(
			assignment_rule_resource != null,
            "Generation config handhold assignment rules cannot contain null entries."
		)
		Validation.require_condition(
			assignment_rule_resource is HandholdAssignmentRuleScript,
            "Generation config handhold assignment rules must use HandholdAssignmentRule resources."
		)
		var typed_rule: HandholdAssignmentRuleScript = assignment_rule_resource as HandholdAssignmentRuleScript
		typed_rule.assert_valid()

func _assert_valid_hold_rows(label: String, hold_rows: Array[PackedInt32Array]) -> void:
	Validation.require_condition(hold_rows.size() > 0, "Generation %s hold rows must not be empty." % label)

	for row_index in range(hold_rows.size()):
		var hold_row: PackedInt32Array = hold_rows[row_index]
		Validation.require_condition(hold_row.size() > 0, "Generation %s hold row %d must not be empty." % [label, row_index])

		for lane_entry_index in range(hold_row.size()):
			var lane_index: int = hold_row[lane_entry_index]
			Validation.require_condition(
				lane_index >= 0 and lane_index <= 3,
				"Generation %s hold row %d contains an out-of-range lane index." % [label, row_index]
			)

func _assert_valid_chunk_row_steps() -> void:
	var chunk_types: Array[int] = [
		ChunkType.Value.LADDER,
		ChunkType.Value.ZIGZAG,
		ChunkType.Value.WIDE_TRAVERSE,
		ChunkType.Value.SPARSE_REACH,
		ChunkType.Value.DENSE_RECOVERY,
		ChunkType.Value.FORK,
		ChunkType.Value.RISK_LANE,
		ChunkType.Value.SWING_GAP,
	]

	for chunk_type in chunk_types:
		var row_step_height_meters: float = get_chunk_row_step_height_meters(chunk_type)
		Validation.require_condition(
			row_step_height_meters > 0.0,
			"Generation %s row-step height must be positive." % ChunkType.to_label(chunk_type)
		)

		var hold_rows: Array[PackedInt32Array] = get_hold_rows(chunk_type)
		var last_row_height_meters: float = non_opener_row_base_height_meters + (row_step_height_meters * float(hold_rows.size()))
		Validation.require_condition(
			last_row_height_meters < segment_height_meters,
			"Generation %s row-step height must keep the last row inside the chunk height." % ChunkType.to_label(chunk_type)
		)

func _assert_valid_opener_row_steps() -> void:
	var opener_chunk_types: Array[int] = [ChunkType.Value.LADDER, ChunkType.Value.ZIGZAG]
	var opener_ceiling_height_meters: float = segment_height_meters - opener_top_padding_meters

	for chunk_type in opener_chunk_types:
		var row_step_height_meters: float = get_opener_row_step_height_meters(chunk_type)
		Validation.require_condition(
			row_step_height_meters > 0.0,
			"Generation opener %s row-step height must be positive." % ChunkType.to_label(chunk_type)
		)

		var hold_rows: Array[PackedInt32Array] = get_opener_hold_rows(chunk_type)
		var last_row_height_meters: float = opener_first_row_height_meters + (row_step_height_meters * float(maxi(0, hold_rows.size() - 1)))
		Validation.require_condition(
			last_row_height_meters <= opener_ceiling_height_meters,
			"Generation opener %s row-step height must leave the configured top padding inside the chunk." % ChunkType.to_label(chunk_type)
		)

func _max_lane_alignment_meters() -> float:
	return (chunk_width_meters * 0.5) * outer_lane_position_ratio

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

static func _duplicate_default_handhold_assignment_rules() -> Array[Resource]:
	Validation.require_condition(
		DefaultHandholdAssignmentRuleCatalogResource != null,
        "Generation config requires an authored default handhold assignment rule catalog resource."
	)
	Validation.require_condition(
		DefaultHandholdAssignmentRuleCatalogResource is HandholdAssignmentRuleCatalogScript,
        "Generation config default handhold assignment rules must use HandholdAssignmentRuleCatalog resources."
	)

	var typed_catalog: HandholdAssignmentRuleCatalogScript = DefaultHandholdAssignmentRuleCatalogResource as HandholdAssignmentRuleCatalogScript
	typed_catalog.assert_valid()
	return typed_catalog.duplicate_rules()

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
