class_name DailyChunkGenerator
extends RefCounted

const ChunkRouteGenerationPipelineScript = preload("res://src/gameplay/generation/chunk_route_generation_pipeline.gd")
const RouteProfileTuningScript = preload("res://resources/config/route_profile_tuning.gd")
const RouteValidationTuningScript = preload("res://resources/config/route_validation_tuning.gd")
const RoutePathValidatorScript: GDScript = preload("res://src/gameplay/generation/route_path_validator.gd")

var _tuning: GenerationTuning
var _route_path_validator: RefCounted
var _route_generation_pipeline: ChunkRouteGenerationPipelineScript
var _route_entry_anchor_positions: Array[Vector2]
var _route_slot_cache: Dictionary
var _chunk_layout_cache: Dictionary
var _chunk_seam_cache: Dictionary

func _init(tuning_value: GenerationTuning, static_reach_distance_meters: float = -1.0) -> void:
	Validation.require_condition(tuning_value != null, "DailyChunkGenerator requires generation tuning.")
	_tuning = tuning_value
	_tuning.assert_valid()
	var route_validation_tuning: RouteValidationTuningScript = _get_route_validation_tuning()
	var effective_static_reach_distance_meters: float = route_validation_tuning.static_reach_distance_meters
	if static_reach_distance_meters > 0.0:
		effective_static_reach_distance_meters = static_reach_distance_meters
	Validation.require_condition(effective_static_reach_distance_meters <= route_validation_tuning.max_move_distance_meters, "DailyChunkGenerator runtime static reach cannot exceed the swing move envelope.")
	_route_path_validator = _build_route_path_validator(
		route_validation_tuning.max_move_distance_meters,
		route_validation_tuning.max_downward_move_meters,
		effective_static_reach_distance_meters
	)
	_route_generation_pipeline = ChunkRouteGenerationPipelineScript.new(_tuning)
	_route_entry_anchor_positions = route_validation_tuning.duplicate_entry_anchor_positions()
	_route_slot_cache = {}
	_chunk_layout_cache = {}
	_chunk_seam_cache = {}

func build_chunk(seed_key: String, chunk_index: int) -> GeneratedChunkLayout:
	Validation.require_condition(chunk_index >= 0, "DailyChunkGenerator chunk index cannot be negative.")
	Validation.require_condition(
		seed_key.begins_with(_tuning.generator_version + ":"),
        "DailyChunkGenerator seed key must match the configured generator version."
	)
	for pending_chunk_index in range(_get_first_uncached_predecessor_index(seed_key, chunk_index), chunk_index + 1):
		var pending_cache_key: String = _get_chunk_cache_key(seed_key, pending_chunk_index)
		if _chunk_layout_cache.has(pending_cache_key):
			continue
		if not _build_and_cache_chunk(seed_key, pending_chunk_index, pending_cache_key):
			return null

	_evict_chunk_caches_before(seed_key, chunk_index - _retained_chunk_history_count())
	return _get_cached_chunk_layout(seed_key, chunk_index)

## Walks back from chunk_index only as far as the nearest cached chunk. Predecessors
## are required for the incoming-seam check and the route-slot history walk; anything
## further back was already retired by _evict_chunk_caches_before on an earlier call.
func _get_first_uncached_predecessor_index(seed_key: String, chunk_index: int) -> int:
	var earliest_required_index: int = chunk_index
	while earliest_required_index > 0 and not _chunk_layout_cache.has(_get_chunk_cache_key(seed_key, earliest_required_index - 1)):
		earliest_required_index -= 1
	return earliest_required_index

## Chunks kept behind the highest built index. Covers the coordinator's keep-behind
## window plus its spawn-ahead reach so a steady climb never rebuilds a retired chunk.
func _retained_chunk_history_count() -> int:
	return _tuning.chunk_keep_behind_count + _tuning.chunk_spawn_ahead_count + 1

func _evict_chunk_caches_before(seed_key: String, min_retained_chunk_index: int) -> void:
	if min_retained_chunk_index <= 0:
		return
	_evict_indexed_cache_before(_chunk_layout_cache, seed_key, min_retained_chunk_index, 1)
	_evict_indexed_cache_before(_route_slot_cache, seed_key, min_retained_chunk_index, 1)
	_evict_indexed_cache_before(_chunk_seam_cache, seed_key, min_retained_chunk_index, 2)

## Drops cache entries for a different run or below the retained window. Layout and
## route-slot keys are "<seed>|<index>"; seam keys are "<seed>|<current>|<next>".
func _evict_indexed_cache_before(cache: Dictionary, seed_key: String, min_retained_chunk_index: int, index_field_count: int) -> void:
	for cache_key in cache.keys():
		var key_parts: PackedStringArray = str(cache_key).rsplit("|", true, index_field_count)
		var is_stale: bool = key_parts.size() != index_field_count + 1 or key_parts[0] != seed_key or key_parts[1].to_int() < min_retained_chunk_index
		if is_stale:
			var _erased: bool = cache.erase(cache_key)

func _build_and_cache_chunk(seed_key: String, chunk_index: int, cache_key: String) -> bool:
	var previous_layout: GeneratedChunkLayout = null
	if chunk_index > 0:
		previous_layout = _get_cached_chunk_layout(seed_key, chunk_index - 1)

	var selected_layout: GeneratedChunkLayout = null
	var selected_score: float = -INF
	var candidate_failure_reasons: PackedStringArray = PackedStringArray()
	for candidate_attempt_index in range(_tuning.route_validation_candidate_attempt_count):
		var candidate_layout: GeneratedChunkLayout = _build_chunk_candidate(seed_key, chunk_index, candidate_attempt_index)
		var route_validation_result: RefCounted = candidate_layout.route_validation_result
		if route_validation_result == null or not _route_validation_result_is_valid(route_validation_result):
			var _append_route_failure_result: bool = candidate_failure_reasons.append("attempt %d route: %s" % [candidate_attempt_index, _require_validation_failure_reason(route_validation_result)])
			continue
		if previous_layout != null:
			var seam_result: RefCounted = validate_chunk_seam(previous_layout, candidate_layout)
			if not _seam_validation_result_is_valid(seam_result):
				var _append_seam_failure_result: bool = candidate_failure_reasons.append("attempt %d seam: %s" % [candidate_attempt_index, _require_validation_failure_reason(seam_result)])
				continue
		if selected_layout == null or candidate_layout.candidate_score > selected_score:
			selected_layout = candidate_layout
			selected_score = candidate_layout.candidate_score

	if selected_layout == null:
		push_error("DailyChunkGenerator exhausted %d candidate attempts without a valid route and incoming seam for chunk %d: %s" % [_tuning.route_validation_candidate_attempt_count, chunk_index, "; ".join(candidate_failure_reasons)])
		return false

	_chunk_layout_cache[cache_key] = selected_layout
	return true

func _get_cached_chunk_layout(seed_key: String, chunk_index: int) -> GeneratedChunkLayout:
	var cache_key: String = _get_chunk_cache_key(seed_key, chunk_index)
	Validation.require_condition(_chunk_layout_cache.has(cache_key), "DailyChunkGenerator requires predecessor chunks to be cached before access.")
	var cached_layout_variant: Variant = _chunk_layout_cache[cache_key]
	Validation.require_condition(cached_layout_variant is GeneratedChunkLayout, "DailyChunkGenerator chunk cache must store GeneratedChunkLayout values.")
	var cached_layout: GeneratedChunkLayout = cached_layout_variant
	return cached_layout

func _build_chunk_candidate(seed_key: String, chunk_index: int, candidate_attempt_index: int) -> GeneratedChunkLayout:
	Validation.require_condition(candidate_attempt_index >= 0, "DailyChunkGenerator candidate attempt index cannot be negative.")
	Validation.require_condition(_route_generation_pipeline != null, "DailyChunkGenerator requires a route generation pipeline.")

	var start_height_meters: float = float(chunk_index) * _tuning.segment_height_meters
	var difficulty_band: int = get_difficulty_band_for_height(start_height_meters)
	var route_slot: int = _get_route_slot_for_chunk_seeded(seed_key, chunk_index, difficulty_band)
	var candidate_selection_seed: String = _build_candidate_selection_seed(seed_key, chunk_index, candidate_attempt_index)
	var preliminary_layout: GeneratedChunkLayout = _route_generation_pipeline.build_layout(
		seed_key,
		chunk_index,
		route_slot,
		difficulty_band,
		null,
		candidate_attempt_index,
		0.0,
		candidate_selection_seed
	)
	var route_validation_result: RefCounted = _validate_generated_layout(preliminary_layout)
	var candidate_score: float = _build_candidate_score(preliminary_layout, route_validation_result)
	return _route_generation_pipeline.build_layout(
		seed_key,
		chunk_index,
		route_slot,
		difficulty_band,
		route_validation_result,
		candidate_attempt_index,
		candidate_score,
		candidate_selection_seed
	)

func _build_candidate_score(layout: GeneratedChunkLayout, route_validation_result: RefCounted) -> float:
	Validation.require_condition(layout != null, "DailyChunkGenerator candidate scoring requires a layout.")
	Validation.require_condition(route_validation_result != null, "DailyChunkGenerator candidate scoring requires a validation result.")
	if not _route_validation_result_is_valid(route_validation_result):
		return 0.0
	var path_hold_ids: PackedStringArray = _require_validation_path_hold_ids(route_validation_result)
	var maximum_move_distance: float = 0.0
	for path_index in range(1, path_hold_ids.size()):
		var from_position: Vector2 = _get_required_handhold_position(layout, path_hold_ids[path_index - 1])
		var to_position: Vector2 = _get_required_handhold_position(layout, path_hold_ids[path_index])
		maximum_move_distance = maxf(maximum_move_distance, from_position.distance_to(to_position))
	var route_validation_tuning: RouteValidationTuningScript = _get_route_validation_tuning()
	return maxf(0.0, route_validation_tuning.max_move_distance_meters - maximum_move_distance)

func _route_validation_result_is_valid(route_validation_result: RefCounted) -> bool:
	var raw_is_valid: Variant = route_validation_result.get("is_valid")
	Validation.require_condition(raw_is_valid is bool, "DailyChunkGenerator route validation result must expose a bool is_valid property.")
	var is_valid: bool = raw_is_valid
	return is_valid

func _seam_validation_result_is_valid(seam_validation_result: RefCounted) -> bool:
	Validation.require_condition(seam_validation_result != null, "DailyChunkGenerator seam validation requires a result.")
	var raw_is_valid: Variant = seam_validation_result.get("is_valid")
	Validation.require_condition(raw_is_valid is bool, "DailyChunkGenerator seam validation result must expose a bool is_valid property.")
	var is_valid: bool = raw_is_valid
	return is_valid

func _build_route_path_validator(max_move_distance_meters: float, max_downward_move_meters: float, static_reach_distance_meters: float) -> RefCounted:
	var validator_variant: Variant = RoutePathValidatorScript.new(max_move_distance_meters, max_downward_move_meters, static_reach_distance_meters)
	Validation.require_condition(validator_variant is RefCounted, "DailyChunkGenerator route path validator must be RefCounted.")
	var validator: RefCounted = validator_variant
	return validator

func _validate_generated_layout(layout: GeneratedChunkLayout) -> RefCounted:
	Validation.require_condition(_route_path_validator != null, "DailyChunkGenerator route path validator must be initialized.")
	var validation_result_variant: Variant = _route_path_validator.call("validate_layout", layout, _route_entry_anchor_positions)
	Validation.require_condition(
		validation_result_variant is RefCounted,
		"DailyChunkGenerator route validation must return a RefCounted result."
	)
	var validation_result: RefCounted = validation_result_variant
	return validation_result

func validate_chunk_seam(current_layout: GeneratedChunkLayout, next_layout: GeneratedChunkLayout) -> RefCounted:
	Validation.require_condition(current_layout != null, "DailyChunkGenerator current seam layout cannot be null.")
	Validation.require_condition(next_layout != null, "DailyChunkGenerator next seam layout cannot be null.")
	Validation.require_condition(_route_path_validator != null, "DailyChunkGenerator route path validator must be initialized.")
	current_layout.assert_valid()
	next_layout.assert_valid()
	var seam_cache_key: String = _get_chunk_seam_cache_key(current_layout, next_layout)
	if _chunk_seam_cache.has(seam_cache_key):
		var cached_seam_result_variant: Variant = _chunk_seam_cache[seam_cache_key]
		Validation.require_condition(cached_seam_result_variant is RefCounted, "DailyChunkGenerator seam cache must store RefCounted values.")
		var cached_seam_result: RefCounted = cached_seam_result_variant
		return cached_seam_result
	var seam_result_variant: Variant = _route_path_validator.call("validate_chunk_seam", current_layout, next_layout)
	Validation.require_condition(
		seam_result_variant is RefCounted,
		"DailyChunkGenerator seam validation must return a RefCounted result."
	)
	var seam_result: RefCounted = seam_result_variant
	_chunk_seam_cache[seam_cache_key] = seam_result
	return seam_result

func _get_chunk_cache_key(seed_key: String, chunk_index: int) -> String:
	return "%s|%d" % [seed_key, chunk_index]

func _get_chunk_seam_cache_key(current_layout: GeneratedChunkLayout, next_layout: GeneratedChunkLayout) -> String:
	return "%s|%d|%d" % [current_layout.seed_key, current_layout.chunk_index, next_layout.chunk_index]

func _build_candidate_selection_seed(seed_key: String, chunk_index: int, candidate_attempt_index: int) -> String:
	return "%s:candidate:%d:%d" % [seed_key, chunk_index, candidate_attempt_index]

func _require_validation_path_hold_ids(route_validation_result: RefCounted) -> PackedStringArray:
	var raw_path_hold_ids: Variant = route_validation_result.get("path_hold_ids")
	Validation.require_condition(raw_path_hold_ids is PackedStringArray, "DailyChunkGenerator validation path must be a PackedStringArray.")
	var path_hold_ids: PackedStringArray = raw_path_hold_ids
	Validation.require_condition(not path_hold_ids.is_empty(), "DailyChunkGenerator valid candidate path cannot be empty.")
	return path_hold_ids

func _require_validation_failure_reason(validation_result: RefCounted) -> String:
	if validation_result == null:
		return "missing validation result"
	var raw_failure_reason: Variant = validation_result.get("failure_reason")
	Validation.require_condition(raw_failure_reason is String, "DailyChunkGenerator validation failure reason must be a String.")
	var failure_reason: String = raw_failure_reason
	return failure_reason

func _get_required_handhold_position(layout: GeneratedChunkLayout, hold_id: String) -> Vector2:
	for handhold in layout.handholds:
		if String(handhold.hold_id) == hold_id:
			return handhold.local_position
	Validation.require_condition(false, "DailyChunkGenerator candidate path references an unknown handhold.")
	return Vector2.ZERO

func _get_route_validation_tuning() -> RouteValidationTuningScript:
	Validation.require_condition(_tuning.route_validation_tuning != null, "DailyChunkGenerator requires route validation tuning.")
	Validation.require_condition(
		_tuning.route_validation_tuning is RouteValidationTuningScript,
		"DailyChunkGenerator route validation tuning must use RouteValidationTuning resources."
	)
	var typed_tuning: RouteValidationTuningScript = _tuning.route_validation_tuning as RouteValidationTuningScript
	return typed_tuning

func _get_route_profile_tuning() -> RouteProfileTuningScript:
	Validation.require_condition(_tuning.route_profile_tuning != null, "DailyChunkGenerator requires route profile tuning.")
	Validation.require_condition(
		_tuning.route_profile_tuning is RouteProfileTuningScript,
		"DailyChunkGenerator route profile tuning must use RouteProfileTuning resources."
	)
	var typed_tuning: RouteProfileTuningScript = _tuning.route_profile_tuning as RouteProfileTuningScript
	return typed_tuning

func get_difficulty_band_for_chunk(chunk_index: int) -> int:
	Validation.require_condition(chunk_index >= 0, "DailyChunkGenerator chunk index cannot be negative when calculating a difficulty band.")
	return get_difficulty_band_for_height(float(chunk_index) * _tuning.segment_height_meters)

func get_difficulty_band_for_height(height_meters: float) -> int:
	Validation.require_condition(height_meters >= 0.0, "DailyChunkGenerator height cannot be negative when calculating a difficulty band.")

	if height_meters < _tuning.easy_band_max_height_meters:
		return ChunkDifficultyBand.Value.EASY

	if height_meters < _tuning.baseline_band_max_height_meters:
		return ChunkDifficultyBand.Value.BASELINE

	return ChunkDifficultyBand.Value.CHALLENGE

func _get_route_slot_for_chunk_seeded(seed_key: String, chunk_index: int, difficulty_band: int) -> int:
	Validation.require_condition(chunk_index >= 0, "DailyChunkGenerator chunk index cannot be negative when calculating a seeded route slot.")
	ChunkDifficultyBand.assert_valid(difficulty_band)

	if chunk_index == 0:
		return ChunkRouteSlot.Value.OPENER

	var cache_key: String = _get_route_slot_cache_key(seed_key, chunk_index)
	var bootstrap_route_slot: int = _get_bootstrap_route_slot(chunk_index)
	if bootstrap_route_slot != -1:
		_route_slot_cache[cache_key] = bootstrap_route_slot
		return bootstrap_route_slot

	if _route_slot_cache.has(cache_key):
		var cached_route_slot_variant: Variant = _route_slot_cache[cache_key]
		Validation.require_condition(cached_route_slot_variant is int, "DailyChunkGenerator route-slot cache must store ints.")
		var cached_route_slot: int = cached_route_slot_variant
		ChunkRouteSlot.assert_valid(cached_route_slot)
		return cached_route_slot

	var route_profile_tuning: RouteProfileTuningScript = _get_route_profile_tuning()
	var previous_route_slot: int = ChunkRouteSlot.Value.OPENER
	if chunk_index > 1:
		var previous_difficulty_band: int = get_difficulty_band_for_chunk(chunk_index - 1)
		previous_route_slot = _get_route_slot_for_chunk_seeded(seed_key, chunk_index - 1, previous_difficulty_band)

	if previous_route_slot == ChunkRouteSlot.Value.PRESSURE:
		_route_slot_cache[cache_key] = ChunkRouteSlot.Value.RECOVERY
		return ChunkRouteSlot.Value.RECOVERY

	var candidate_slots: Array[int] = []
	var candidate_weights: Array[float] = []
	_append_route_profile_candidates(route_profile_tuning, difficulty_band, candidate_slots, candidate_weights)
	_apply_route_profile_history_biases(seed_key, chunk_index, candidate_slots, candidate_weights)
	var route_slot_rng: RandomNumberGenerator = _build_route_slot_rng(seed_key, chunk_index)
	var selected_route_slot: int = _select_weighted_route_slot(candidate_slots, candidate_weights, route_slot_rng)
	_route_slot_cache[cache_key] = selected_route_slot
	return selected_route_slot

func _get_bootstrap_route_slot(chunk_index: int) -> int:
	Validation.require_condition(chunk_index > 0, "DailyChunkGenerator bootstrap route slots apply only after the opener.")
	match chunk_index:
		1:
			return ChunkRouteSlot.Value.BASELINE
		2:
			return ChunkRouteSlot.Value.SKILL
		3:
			return ChunkRouteSlot.Value.RECOVERY
		_:
			return -1

func _append_route_profile_candidates(
	route_profile_tuning: RouteProfileTuningScript,
	difficulty_band: int,
	candidate_slots: Array[int],
	candidate_weights: Array[float]
) -> void:
	Validation.require_condition(route_profile_tuning != null, "DailyChunkGenerator route-profile candidates require tuning.")
	ChunkDifficultyBand.assert_valid(difficulty_band)

	match difficulty_band:
		ChunkDifficultyBand.Value.EASY:
			_append_route_profile_candidate(candidate_slots, candidate_weights, ChunkRouteSlot.Value.BASELINE, route_profile_tuning.easy_baseline_weight)
			_append_route_profile_candidate(candidate_slots, candidate_weights, ChunkRouteSlot.Value.SKILL, route_profile_tuning.easy_skill_weight)
			_append_route_profile_candidate(candidate_slots, candidate_weights, ChunkRouteSlot.Value.RECOVERY, route_profile_tuning.easy_recovery_weight)
			_append_route_profile_candidate(candidate_slots, candidate_weights, ChunkRouteSlot.Value.RISK, route_profile_tuning.easy_risk_weight)
			_append_route_profile_candidate(candidate_slots, candidate_weights, ChunkRouteSlot.Value.PRESSURE, route_profile_tuning.easy_pressure_weight)
		ChunkDifficultyBand.Value.BASELINE:
			_append_route_profile_candidate(candidate_slots, candidate_weights, ChunkRouteSlot.Value.BASELINE, route_profile_tuning.baseline_baseline_weight)
			_append_route_profile_candidate(candidate_slots, candidate_weights, ChunkRouteSlot.Value.SKILL, route_profile_tuning.baseline_skill_weight)
			_append_route_profile_candidate(candidate_slots, candidate_weights, ChunkRouteSlot.Value.RECOVERY, route_profile_tuning.baseline_recovery_weight)
			_append_route_profile_candidate(candidate_slots, candidate_weights, ChunkRouteSlot.Value.RISK, route_profile_tuning.baseline_risk_weight)
			_append_route_profile_candidate(candidate_slots, candidate_weights, ChunkRouteSlot.Value.PRESSURE, route_profile_tuning.baseline_pressure_weight)
		ChunkDifficultyBand.Value.CHALLENGE:
			_append_route_profile_candidate(candidate_slots, candidate_weights, ChunkRouteSlot.Value.BASELINE, route_profile_tuning.challenge_baseline_weight)
			_append_route_profile_candidate(candidate_slots, candidate_weights, ChunkRouteSlot.Value.SKILL, route_profile_tuning.challenge_skill_weight)
			_append_route_profile_candidate(candidate_slots, candidate_weights, ChunkRouteSlot.Value.RECOVERY, route_profile_tuning.challenge_recovery_weight)
			_append_route_profile_candidate(candidate_slots, candidate_weights, ChunkRouteSlot.Value.RISK, route_profile_tuning.challenge_risk_weight)
			_append_route_profile_candidate(candidate_slots, candidate_weights, ChunkRouteSlot.Value.PRESSURE, route_profile_tuning.challenge_pressure_weight)
		_:
			Validation.require_condition(false, "DailyChunkGenerator route-profile candidates require a supported difficulty band.")

	Validation.require_condition(candidate_slots.size() > 0, "DailyChunkGenerator route-profile candidates cannot be empty.")

func _append_route_profile_candidate(
	candidate_slots: Array[int],
	candidate_weights: Array[float],
	route_slot: int,
	weight: float
) -> void:
	ChunkRouteSlot.assert_valid(route_slot)
	Validation.require_condition(weight >= 0.0, "DailyChunkGenerator route-profile candidate weights cannot be negative.")
	if is_zero_approx(weight):
		return

	candidate_slots.append(route_slot)
	candidate_weights.append(weight)

func _apply_route_profile_history_biases(
	seed_key: String,
	chunk_index: int,
	candidate_slots: Array[int],
	candidate_weights: Array[float]
) -> void:
	Validation.require_condition(chunk_index > 0, "DailyChunkGenerator route-profile history biases require a non-opener chunk.")
	Validation.require_condition(candidate_slots.size() == candidate_weights.size(), "DailyChunkGenerator route-profile candidates must align with weights.")
	var route_profile_tuning: RouteProfileTuningScript = _get_route_profile_tuning()
	var recent_history_count: int = maxi(route_profile_tuning.max_repeat_profile_count, route_profile_tuning.recovery_debt_threshold)
	var recent_slots: Array[int] = _get_recent_route_slots(seed_key, chunk_index, recent_history_count)
	var risk_pressure_count: int = 0

	for recent_slot in recent_slots:
		if recent_slot == ChunkRouteSlot.Value.RISK or recent_slot == ChunkRouteSlot.Value.PRESSURE:
			risk_pressure_count += 1

	if _recent_slots_are_repeating(recent_slots, route_profile_tuning.max_repeat_profile_count):
		_set_route_slot_weight(candidate_slots, candidate_weights, recent_slots[0], 0.0)

	if risk_pressure_count >= route_profile_tuning.recovery_debt_threshold:
		_add_route_slot_weight(candidate_slots, candidate_weights, ChunkRouteSlot.Value.RECOVERY, route_profile_tuning.novelty_bonus_weight + 1.0)
		_add_route_slot_weight(candidate_slots, candidate_weights, ChunkRouteSlot.Value.BASELINE, 0.5)
		_scale_route_slot_weight(candidate_slots, candidate_weights, ChunkRouteSlot.Value.PRESSURE, 0.25)
		_scale_route_slot_weight(candidate_slots, candidate_weights, ChunkRouteSlot.Value.RISK, 0.5)

	for route_slot in candidate_slots:
		if not recent_slots.has(route_slot):
			_add_route_slot_weight(candidate_slots, candidate_weights, route_slot, route_profile_tuning.novelty_bonus_weight)

	_add_route_slot_weight(candidate_slots, candidate_weights, ChunkRouteSlot.Value.RISK, route_profile_tuning.optional_beta_bias_weight)

func _get_recent_route_slots(seed_key: String, chunk_index: int, max_count: int) -> Array[int]:
	Validation.require_condition(chunk_index > 0, "DailyChunkGenerator recent route-slot lookup requires a non-opener chunk.")
	Validation.require_condition(max_count >= 0, "DailyChunkGenerator recent route-slot count cannot be negative.")
	var recent_slots: Array[int] = []
	for previous_chunk_index in range(chunk_index - 1, maxi(0, chunk_index - max_count) - 1, -1):
		if previous_chunk_index == 0:
			recent_slots.append(ChunkRouteSlot.Value.OPENER)
			continue

		var previous_difficulty_band: int = get_difficulty_band_for_chunk(previous_chunk_index)
		recent_slots.append(_get_route_slot_for_chunk_seeded(seed_key, previous_chunk_index, previous_difficulty_band))

	return recent_slots

func _recent_slots_are_repeating(recent_slots: Array[int], required_repeat_count: int) -> bool:
	if required_repeat_count <= 1:
		return recent_slots.size() > 0
	if recent_slots.size() < required_repeat_count:
		return false

	var repeated_route_slot: int = recent_slots[0]
	for recent_index in range(required_repeat_count):
		if recent_slots[recent_index] != repeated_route_slot:
			return false

	return true

func _set_route_slot_weight(candidate_slots: Array[int], candidate_weights: Array[float], route_slot: int, weight: float) -> void:
	ChunkRouteSlot.assert_valid(route_slot)
	Validation.require_condition(weight >= 0.0, "DailyChunkGenerator route-slot weight cannot be negative.")
	for slot_index in range(candidate_slots.size()):
		if candidate_slots[slot_index] == route_slot:
			candidate_weights[slot_index] = weight
			return

func _add_route_slot_weight(candidate_slots: Array[int], candidate_weights: Array[float], route_slot: int, delta: float) -> void:
	ChunkRouteSlot.assert_valid(route_slot)
	Validation.require_condition(delta >= 0.0, "DailyChunkGenerator route-slot weight delta cannot be negative.")
	for slot_index in range(candidate_slots.size()):
		if candidate_slots[slot_index] == route_slot:
			candidate_weights[slot_index] += delta
			return

func _scale_route_slot_weight(candidate_slots: Array[int], candidate_weights: Array[float], route_slot: int, scale: float) -> void:
	ChunkRouteSlot.assert_valid(route_slot)
	Validation.require_condition(scale >= 0.0, "DailyChunkGenerator route-slot weight scale cannot be negative.")
	for slot_index in range(candidate_slots.size()):
		if candidate_slots[slot_index] == route_slot:
			candidate_weights[slot_index] *= scale
			return

func _select_weighted_route_slot(
	candidate_slots: Array[int],
	candidate_weights: Array[float],
	route_slot_rng: RandomNumberGenerator
) -> int:
	Validation.require_condition(candidate_slots.size() > 0, "DailyChunkGenerator weighted route-slot selection requires candidates.")
	Validation.require_condition(candidate_slots.size() == candidate_weights.size(), "DailyChunkGenerator weighted route-slot candidates must align with weights.")
	Validation.require_condition(route_slot_rng != null, "DailyChunkGenerator weighted route-slot selection requires an RNG.")

	var total_weight: float = 0.0
	for weight in candidate_weights:
		total_weight += weight

	Validation.require_condition(total_weight > 0.0, "DailyChunkGenerator weighted route-slot selection requires positive total weight.")
	var selection_value: float = route_slot_rng.randf_range(0.0, total_weight)
	var accumulated_weight: float = 0.0
	for slot_index in range(candidate_slots.size()):
		accumulated_weight += candidate_weights[slot_index]
		if selection_value <= accumulated_weight:
			return candidate_slots[slot_index]

	return candidate_slots[candidate_slots.size() - 1]

func _build_route_slot_rng(seed_key: String, chunk_index: int) -> RandomNumberGenerator:
	var route_slot_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	var route_slot_seed_key: String = "%s:route_profile:%d" % [seed_key, chunk_index]
	route_slot_rng.seed = DeterministicHash.of_string(route_slot_seed_key)
	return route_slot_rng

func _get_route_slot_cache_key(seed_key: String, chunk_index: int) -> String:
	return "%s|%d" % [seed_key, chunk_index]
