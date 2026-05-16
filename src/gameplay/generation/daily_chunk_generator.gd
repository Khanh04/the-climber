class_name DailyChunkGenerator
extends RefCounted

const GeneratedHazardKindScript = preload("res://src/gameplay/generation/generated_hazard_kind.gd")
const HandholdLifecycleRuleScript = preload("res://resources/config/handhold_lifecycle_rule.gd")
const HandholdMovementRuleScript = preload("res://resources/config/handhold_movement_rule.gd")
const HandholdSurfaceProfileScript = preload("res://resources/config/handhold_surface_profile.gd")
const RouteProfileTuningScript = preload("res://resources/config/route_profile_tuning.gd")
const RouteValidationTuningScript = preload("res://resources/config/route_validation_tuning.gd")
const HandholdTypeScript = preload("res://src/gameplay/generation/handhold_type.gd")
const HandholdTypeDefinitionScript = preload("res://resources/config/handhold_type_definition.gd")
const RouteRoleScript = preload("res://src/gameplay/generation/route_role.gd")
const RoutePathValidatorScript: GDScript = preload("res://src/gameplay/generation/route_path_validator.gd")

var _tuning: GenerationTuning
var _route_path_validator: RefCounted
var _route_entry_anchor_positions: Array[Vector2]
var _route_slot_cache: Dictionary
var _chunk_layout_cache: Dictionary
var _chunk_seam_cache: Dictionary

func _init(tuning_value: GenerationTuning) -> void:
	Validation.require_condition(tuning_value != null, "DailyChunkGenerator requires generation tuning.")
	_tuning = tuning_value
	_tuning.assert_valid()
	var route_validation_tuning: RouteValidationTuningScript = _get_route_validation_tuning()
	_route_path_validator = _build_route_path_validator(
		route_validation_tuning.max_move_distance_meters,
		route_validation_tuning.max_downward_move_meters
	)
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
	var cache_key: String = _get_chunk_cache_key(seed_key, chunk_index)
	if _chunk_layout_cache.has(cache_key):
		var cached_layout_variant: Variant = _chunk_layout_cache[cache_key]
		Validation.require_condition(cached_layout_variant is GeneratedChunkLayout, "DailyChunkGenerator chunk cache must store GeneratedChunkLayout values.")
		var cached_layout: GeneratedChunkLayout = cached_layout_variant
		return cached_layout

	var best_valid_layout: GeneratedChunkLayout = null
	var best_fallback_layout: GeneratedChunkLayout = null
	for candidate_attempt_index in range(_tuning.route_validation_candidate_attempt_count):
		var candidate_layout: GeneratedChunkLayout = _build_chunk_candidate(seed_key, chunk_index, candidate_attempt_index)
		if _is_better_candidate(candidate_layout, best_fallback_layout, false):
			best_fallback_layout = candidate_layout

		var route_validation_result: RefCounted = candidate_layout.route_validation_result
		if route_validation_result != null and _route_validation_result_is_valid(route_validation_result):
			if _is_better_candidate(candidate_layout, best_valid_layout, true):
				best_valid_layout = candidate_layout

	var selected_layout: GeneratedChunkLayout = best_valid_layout
	if selected_layout == null:
		selected_layout = best_fallback_layout

	Validation.require_condition(selected_layout != null, "DailyChunkGenerator must produce at least one chunk candidate.")
	_chunk_layout_cache[cache_key] = selected_layout
	return selected_layout

func _build_chunk_candidate(seed_key: String, chunk_index: int, candidate_attempt_index: int) -> GeneratedChunkLayout:
	Validation.require_condition(candidate_attempt_index >= 0, "DailyChunkGenerator candidate attempt index cannot be negative.")

	var start_height_meters: float = float(chunk_index) * _tuning.segment_height_meters
	var difficulty_band: int = get_difficulty_band_for_height(start_height_meters)
	var route_slot: int = _get_route_slot_for_chunk_seeded(seed_key, chunk_index, difficulty_band)
	var chunk_rng: RandomNumberGenerator = _build_chunk_rng(seed_key, chunk_index, candidate_attempt_index)
	var chunk_type: int = _select_chunk_type(route_slot, difficulty_band, chunk_rng)
	var risky_lane_side_sign: float = _get_risky_lane_side_sign(seed_key, chunk_index, chunk_type)
	var provisional_handholds: Array[GeneratedHandholdSocket] = _build_handholds(
		chunk_index,
		chunk_type,
		route_slot,
		difficulty_band,
		risky_lane_side_sign,
		chunk_rng
	)
	var route_entry_hold_ids: PackedStringArray = _build_route_port_hold_ids(provisional_handholds, true)
	var route_exit_hold_ids: PackedStringArray = _build_route_port_hold_ids(provisional_handholds, false)
	var handholds: Array[GeneratedHandholdSocket] = _assign_route_roles(
		chunk_type,
		route_slot,
		difficulty_band,
		risky_lane_side_sign,
		provisional_handholds,
		route_entry_hold_ids,
		route_exit_hold_ids
	)
	var pickup_sockets: Array[GeneratedPickupSocket] = _build_pickup_sockets(
		chunk_index,
		chunk_type,
		route_slot,
		risky_lane_side_sign,
		handholds,
		chunk_rng
	)
	var hazard_sockets: Array[GeneratedHazardSocket] = _build_hazard_sockets(
		chunk_index,
		chunk_type,
		route_slot,
		difficulty_band,
		risky_lane_side_sign,
		handholds,
		chunk_rng
	)

	var preliminary_layout: GeneratedChunkLayout = GeneratedChunkLayout.new(
		seed_key,
		_tuning.generator_version,
		chunk_index,
		chunk_type,
		route_slot,
		difficulty_band,
		start_height_meters,
		handholds,
		pickup_sockets,
		hazard_sockets,
		route_entry_hold_ids,
		route_exit_hold_ids
	)
	var route_validation_result: RefCounted = _validate_generated_layout(preliminary_layout)
	var candidate_score: float = _score_candidate_layout(preliminary_layout, route_validation_result, candidate_attempt_index)

	return GeneratedChunkLayout.new(
		seed_key,
		_tuning.generator_version,
		chunk_index,
		chunk_type,
		route_slot,
		difficulty_band,
		start_height_meters,
		handholds,
		pickup_sockets,
		hazard_sockets,
		route_entry_hold_ids,
		route_exit_hold_ids,
		route_validation_result,
		candidate_attempt_index,
		candidate_score
	)

func _is_better_candidate(candidate_layout: GeneratedChunkLayout, incumbent_layout: GeneratedChunkLayout, require_valid: bool) -> bool:
	Validation.require_condition(candidate_layout != null, "DailyChunkGenerator candidate comparison requires a candidate layout.")
	if incumbent_layout == null:
		return true

	if require_valid:
		Validation.require_condition(candidate_layout.route_validation_result != null, "DailyChunkGenerator valid-candidate comparison requires route validation metadata.")
		Validation.require_condition(incumbent_layout.route_validation_result != null, "DailyChunkGenerator valid-candidate comparison requires incumbent route validation metadata.")

	if candidate_layout.candidate_score > incumbent_layout.candidate_score:
		return true
	if candidate_layout.candidate_score < incumbent_layout.candidate_score:
		return false

	return candidate_layout.selected_candidate_attempt_index < incumbent_layout.selected_candidate_attempt_index

func _score_candidate_layout(
	layout: GeneratedChunkLayout,
	route_validation_result: RefCounted,
	candidate_attempt_index: int
) -> float:
	Validation.require_condition(layout != null, "DailyChunkGenerator candidate scoring requires a layout.")
	Validation.require_condition(route_validation_result != null, "DailyChunkGenerator candidate scoring requires a route validation result.")
	Validation.require_condition(candidate_attempt_index >= 0, "DailyChunkGenerator candidate scoring requires a non-negative attempt index.")

	var score: float = 0.0
	if _route_validation_result_is_valid(route_validation_result):
		score += 1000.0

	score += float(_get_route_validation_path_length(route_validation_result)) * 25.0
	score += _score_route_role_coverage(layout.handholds, layout.route_slot)
	score += _score_route_slot_bonus(layout.handholds, layout.route_slot)
	score += _score_pickup_intent_alignment(layout.pickup_sockets, layout.handholds, layout.route_slot)
	score += _score_hazard_intent_alignment(layout.hazard_sockets, layout.handholds, layout.route_slot)
	score += _score_hazard_fairness(layout.hazard_sockets, layout.route_slot, layout.difficulty_band)
	score -= float(candidate_attempt_index) * 0.01
	return score

func _get_route_validation_path_length(route_validation_result: RefCounted) -> int:
	var raw_path_hold_ids: Variant = route_validation_result.get("path_hold_ids")
	Validation.require_condition(raw_path_hold_ids is PackedStringArray, "DailyChunkGenerator route validation results must expose PackedStringArray path_hold_ids.")
	var path_hold_ids: PackedStringArray = raw_path_hold_ids
	return path_hold_ids.size()

func _score_route_role_coverage(handholds: Array[GeneratedHandholdSocket], route_slot: int) -> float:
	ChunkRouteSlot.assert_valid(route_slot)
	var has_entry: bool = false
	var has_setup: bool = false
	var has_crux: bool = false
	var has_recovery: bool = false
	var has_top_out: bool = false
	var has_optional_branch_role: bool = false

	for handhold in handholds:
		match handhold.route_role:
			RouteRoleScript.Value.ENTRY:
				has_entry = true
			RouteRoleScript.Value.SETUP:
				has_setup = true
			RouteRoleScript.Value.CRUX:
				has_crux = true
			RouteRoleScript.Value.RECOVERY:
				has_recovery = true
			RouteRoleScript.Value.TOP_OUT:
				has_top_out = true
			RouteRoleScript.Value.OPTIONAL_BETA, RouteRoleScript.Value.REWARD, RouteRoleScript.Value.HAZARD_DENIAL:
				has_optional_branch_role = true
			_:
				pass

	var score: float = 0.0
	if has_entry:
		score += 20.0
	if has_setup:
		score += 10.0
	if has_crux:
		score += 20.0
	if has_recovery:
		score += 15.0
	if has_top_out:
		score += 20.0
	if has_optional_branch_role:
		score += 8.0
	return score

func _score_route_slot_bonus(handholds: Array[GeneratedHandholdSocket], route_slot: int) -> float:
	ChunkRouteSlot.assert_valid(route_slot)
	var optional_role_count: int = 0
	for handhold in handholds:
		if handhold.route_role == RouteRoleScript.Value.OPTIONAL_BETA \
			or handhold.route_role == RouteRoleScript.Value.REWARD \
			or handhold.route_role == RouteRoleScript.Value.HAZARD_DENIAL:
			optional_role_count += 1

	match route_slot:
		ChunkRouteSlot.Value.RECOVERY:
			return float(optional_role_count) * 2.0
		ChunkRouteSlot.Value.SKILL, ChunkRouteSlot.Value.BASELINE:
			return float(optional_role_count) * 3.0
		ChunkRouteSlot.Value.RISK, ChunkRouteSlot.Value.PRESSURE:
			return float(optional_role_count) * 4.0
		_:
			return 0.0

func _score_hazard_fairness(
	hazard_sockets: Array[GeneratedHazardSocket],
	route_slot: int,
	difficulty_band: int
) -> float:
	ChunkRouteSlot.assert_valid(route_slot)
	ChunkDifficultyBand.assert_valid(difficulty_band)
	if hazard_sockets.is_empty():
		return 0.0

	var expected_hazard_kind: int = _select_hazard_kind(0, 0, route_slot, difficulty_band)
	var score: float = 0.0
	for hazard_socket in hazard_sockets:
		if hazard_socket.hazard_kind == expected_hazard_kind:
			score += 5.0
	return score

func _score_pickup_intent_alignment(
	pickup_sockets: Array[GeneratedPickupSocket],
	handholds: Array[GeneratedHandholdSocket],
	route_slot: int
) -> float:
	ChunkRouteSlot.assert_valid(route_slot)
	if pickup_sockets.is_empty() or handholds.is_empty():
		return 0.0

	var pickup_anchor_pool: Array[GeneratedHandholdSocket] = _get_pickup_intent_anchor_pool(route_slot, handholds)
	if pickup_anchor_pool.is_empty():
		return 0.0

	return _score_socket_alignment_to_handholds(pickup_sockets, pickup_anchor_pool, 18.0)

func _score_hazard_intent_alignment(
	hazard_sockets: Array[GeneratedHazardSocket],
	handholds: Array[GeneratedHandholdSocket],
	route_slot: int
) -> float:
	ChunkRouteSlot.assert_valid(route_slot)
	if hazard_sockets.is_empty() or handholds.is_empty():
		return 0.0

	var hazard_anchor_pool: Array[GeneratedHandholdSocket] = _get_hazard_intent_anchor_pool(route_slot, handholds)
	if hazard_anchor_pool.is_empty():
		return 0.0

	return _score_socket_alignment_to_handholds(hazard_sockets, hazard_anchor_pool, 14.0)

func _score_socket_alignment_to_handholds(
	sockets: Array,
	handholds: Array[GeneratedHandholdSocket],
	weight: float
) -> float:
	Validation.require_condition(handholds.size() > 0, "DailyChunkGenerator socket alignment scoring requires handholds.")
	Validation.require_condition(weight > 0.0, "DailyChunkGenerator socket alignment scoring weight must be positive.")
	if sockets.is_empty():
		return 0.0

	var score: float = 0.0
	for socket_value in sockets:
		Validation.require_condition(socket_value is Object, "DailyChunkGenerator socket alignment scoring requires Object-derived sockets.")
		var socket_object: Object = socket_value
		var raw_local_position: Variant = socket_object.get("local_position")
		Validation.require_condition(raw_local_position is Vector2, "DailyChunkGenerator socket alignment scoring requires Vector2 local positions.")
		var socket_position: Vector2 = raw_local_position
		var nearest_distance: float = socket_position.distance_to(handholds[0].local_position)
		for handhold in handholds:
			nearest_distance = minf(nearest_distance, socket_position.distance_to(handhold.local_position))

		score += weight / (0.35 + nearest_distance)

	return score

func _route_validation_result_is_valid(route_validation_result: RefCounted) -> bool:
	var raw_is_valid: Variant = route_validation_result.get("is_valid")
	Validation.require_condition(raw_is_valid is bool, "DailyChunkGenerator route validation result must expose a bool is_valid property.")
	var is_valid: bool = raw_is_valid
	return is_valid

func _build_route_port_hold_ids(handholds: Array[GeneratedHandholdSocket], select_entry_ports: bool) -> PackedStringArray:
	Validation.require_condition(handholds.size() > 0, "DailyChunkGenerator route ports require at least one handhold.")
	var target_row_y: float = handholds[0].local_position.y
	for handhold in handholds:
		if select_entry_ports:
			target_row_y = maxf(target_row_y, handhold.local_position.y)
		else:
			target_row_y = minf(target_row_y, handhold.local_position.y)

	var route_port_hold_ids: PackedStringArray = PackedStringArray()
	for handhold in handholds:
		if absf(handhold.local_position.y - target_row_y) <= _tuning.route_port_row_tolerance_meters:
			var _append_route_port_result: bool = route_port_hold_ids.append(String(handhold.hold_id))

	Validation.require_condition(route_port_hold_ids.size() > 0, "DailyChunkGenerator route ports cannot be empty.")
	return route_port_hold_ids

func _assign_route_roles(
	chunk_type: int,
	route_slot: int,
	difficulty_band: int,
	risky_lane_side_sign: float,
	handholds: Array[GeneratedHandholdSocket],
	route_entry_hold_ids: PackedStringArray,
	route_exit_hold_ids: PackedStringArray
) -> Array[GeneratedHandholdSocket]:
	ChunkType.assert_valid(chunk_type)
	ChunkRouteSlot.assert_valid(route_slot)
	ChunkDifficultyBand.assert_valid(difficulty_band)
	Validation.require_condition(
		risky_lane_side_sign == -1.0 or risky_lane_side_sign == 0.0 or risky_lane_side_sign == 1.0,
		"DailyChunkGenerator route-role assignment requires a valid route branch side sign."
	)
	Validation.require_condition(handholds.size() > 0, "DailyChunkGenerator route-role assignment requires handholds.")
	Validation.require_condition(route_entry_hold_ids.size() > 0, "DailyChunkGenerator route-role assignment requires entry ports.")
	Validation.require_condition(route_exit_hold_ids.size() > 0, "DailyChunkGenerator route-role assignment requires exit ports.")

	var role_assigned_handholds: Array[GeneratedHandholdSocket] = []
	for handhold in handholds:
		var route_role: int = _select_route_role(
			chunk_type,
			route_slot,
			difficulty_band,
			risky_lane_side_sign,
			handhold,
			handholds,
			route_entry_hold_ids,
			route_exit_hold_ids
		)
		role_assigned_handholds.append(_copy_handhold_with_route_role(handhold, route_role))

	return role_assigned_handholds

func _select_route_role(
	chunk_type: int,
	route_slot: int,
	difficulty_band: int,
	risky_lane_side_sign: float,
	handhold: GeneratedHandholdSocket,
	handholds: Array[GeneratedHandholdSocket],
	route_entry_hold_ids: PackedStringArray,
	route_exit_hold_ids: PackedStringArray
) -> int:
	ChunkType.assert_valid(chunk_type)
	ChunkRouteSlot.assert_valid(route_slot)
	ChunkDifficultyBand.assert_valid(difficulty_band)
	Validation.require_condition(
		risky_lane_side_sign == -1.0 or risky_lane_side_sign == 0.0 or risky_lane_side_sign == 1.0,
		"DailyChunkGenerator route-role selection requires a valid route branch side sign."
	)
	Validation.require_condition(handhold != null, "DailyChunkGenerator route-role selection requires a handhold.")
	Validation.require_condition(handholds.size() > 0, "DailyChunkGenerator route-role selection requires handholds.")

	if route_entry_hold_ids.has(String(handhold.hold_id)):
		return RouteRoleScript.Value.ENTRY

	if route_exit_hold_ids.has(String(handhold.hold_id)):
		return RouteRoleScript.Value.TOP_OUT

	var route_validation_tuning: RouteValidationTuningScript = _get_route_validation_tuning()
	var route_progress: float = _get_route_progress_ratio(handhold, handholds)
	var crux_target_ratio: float = (route_validation_tuning.setup_zone_upper_ratio + route_validation_tuning.crux_zone_upper_ratio) * 0.5
	var base_role: int = RouteRoleScript.Value.SETUP

	if route_progress >= route_validation_tuning.crux_zone_upper_ratio:
		base_role = RouteRoleScript.Value.RECOVERY
	elif absf(route_progress - crux_target_ratio) <= 0.16 or (
		route_slot == ChunkRouteSlot.Value.PRESSURE and route_progress >= crux_target_ratio
	):
		base_role = RouteRoleScript.Value.CRUX

	if _is_branch_route_role_candidate(chunk_type, route_slot, handhold.local_position, risky_lane_side_sign):
		match route_slot:
			ChunkRouteSlot.Value.RECOVERY:
				if base_role == RouteRoleScript.Value.RECOVERY:
					return RouteRoleScript.Value.REWARD
			ChunkRouteSlot.Value.RISK:
				if base_role == RouteRoleScript.Value.CRUX or base_role == RouteRoleScript.Value.RECOVERY:
					return RouteRoleScript.Value.HAZARD_DENIAL
			ChunkRouteSlot.Value.PRESSURE:
				if base_role == RouteRoleScript.Value.CRUX or base_role == RouteRoleScript.Value.RECOVERY:
					return RouteRoleScript.Value.HAZARD_DENIAL
			ChunkRouteSlot.Value.SKILL:
				if base_role == RouteRoleScript.Value.CRUX or base_role == RouteRoleScript.Value.RECOVERY:
					return RouteRoleScript.Value.OPTIONAL_BETA
			ChunkRouteSlot.Value.BASELINE:
				if base_role == RouteRoleScript.Value.CRUX or base_role == RouteRoleScript.Value.RECOVERY:
					return RouteRoleScript.Value.OPTIONAL_BETA
			_:
				pass

	return base_role

func _get_route_progress_ratio(handhold: GeneratedHandholdSocket, handholds: Array[GeneratedHandholdSocket]) -> float:
	Validation.require_condition(handhold != null, "DailyChunkGenerator route progress requires a handhold.")
	Validation.require_condition(handholds.size() > 0, "DailyChunkGenerator route progress requires handholds.")

	var minimum_height_meters: float = -handholds[0].local_position.y
	var maximum_height_meters: float = minimum_height_meters
	for candidate_handhold in handholds:
		var candidate_height_meters: float = -candidate_handhold.local_position.y
		minimum_height_meters = minf(minimum_height_meters, candidate_height_meters)
		maximum_height_meters = maxf(maximum_height_meters, candidate_height_meters)

	if is_equal_approx(minimum_height_meters, maximum_height_meters):
		return 0.0

	var handhold_height_meters: float = -handhold.local_position.y
	return clampf(
		(handhold_height_meters - minimum_height_meters) / (maximum_height_meters - minimum_height_meters),
		0.0,
		1.0
	)

func _is_branch_route_role_candidate(
	chunk_type: int,
	route_slot: int,
	local_position: Vector2,
	risky_lane_side_sign: float
) -> bool:
	ChunkType.assert_valid(chunk_type)
	ChunkRouteSlot.assert_valid(route_slot)
	Validation.require_condition(
		risky_lane_side_sign == -1.0 or risky_lane_side_sign == 0.0 or risky_lane_side_sign == 1.0,
		"DailyChunkGenerator branch route-role candidate checks require a valid route branch side sign."
	)
	if not _supports_lane_choice(chunk_type):
		return false

	if absf(local_position.x) < _get_branch_role_alignment_threshold():
		return false

	if (route_slot == ChunkRouteSlot.Value.RISK or route_slot == ChunkRouteSlot.Value.PRESSURE) and risky_lane_side_sign != 0.0:
		return is_equal_approx(signf(local_position.x), risky_lane_side_sign)

	return true

func _get_branch_role_alignment_threshold() -> float:
	var half_width: float = _tuning.chunk_width_meters * 0.5
	var inner_lane_alignment: float = half_width * _tuning.inner_lane_position_ratio
	var outer_lane_alignment: float = half_width * _tuning.outer_lane_position_ratio
	return (inner_lane_alignment + outer_lane_alignment) * 0.5

func _copy_handhold_with_route_role(handhold: GeneratedHandholdSocket, route_role: int) -> GeneratedHandholdSocket:
	Validation.require_condition(handhold != null, "DailyChunkGenerator handhold route-role copy requires a handhold.")
	RouteRoleScript.assert_valid(route_role)
	return GeneratedHandholdSocket.new(
		handhold.hold_id,
		handhold.definition_id,
		handhold.local_position,
		handhold.handhold_type,
		handhold.stamina_drain_multiplier,
		handhold.physical_size_meters,
		handhold.visual_color,
		handhold.break_after_attach_seconds,
		handhold.breaks_on_release,
		handhold.release_impulse_vector_pixels,
		route_role
	)

func _build_route_path_validator(max_move_distance_meters: float, max_downward_move_meters: float) -> RefCounted:
	var validator_variant: Variant = RoutePathValidatorScript.new(max_move_distance_meters, max_downward_move_meters)
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

func get_route_slot_for_chunk(chunk_index: int, difficulty_band: int) -> int:
	Validation.require_condition(chunk_index >= 0, "DailyChunkGenerator chunk index cannot be negative when calculating a route slot.")
	ChunkDifficultyBand.assert_valid(difficulty_band)
	var preview_seed_key: String = "%s:route_profile_preview" % _tuning.generator_version
	return _get_route_slot_for_chunk_seeded(preview_seed_key, chunk_index, difficulty_band)

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
		ChunkDifficultyBand.Value.BASELINE:
			_append_route_profile_candidate(candidate_slots, candidate_weights, ChunkRouteSlot.Value.BASELINE, route_profile_tuning.baseline_baseline_weight)
			_append_route_profile_candidate(candidate_slots, candidate_weights, ChunkRouteSlot.Value.SKILL, route_profile_tuning.baseline_skill_weight)
			_append_route_profile_candidate(candidate_slots, candidate_weights, ChunkRouteSlot.Value.RECOVERY, route_profile_tuning.baseline_recovery_weight)
			_append_route_profile_candidate(candidate_slots, candidate_weights, ChunkRouteSlot.Value.RISK, route_profile_tuning.baseline_risk_weight)
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
	var route_slot_seed_hash: int = route_slot_seed_key.hash()
	if route_slot_seed_hash < 0:
		route_slot_seed_hash = -route_slot_seed_hash
	route_slot_rng.seed = route_slot_seed_hash
	return route_slot_rng

func _get_route_slot_cache_key(seed_key: String, chunk_index: int) -> String:
	return "%s|%d" % [seed_key, chunk_index]

func _build_chunk_rng(seed_key: String, chunk_index: int, candidate_attempt_index: int = 0) -> RandomNumberGenerator:
	var chunk_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	Validation.require_condition(candidate_attempt_index >= 0, "DailyChunkGenerator candidate attempt index cannot be negative when building an RNG.")
	var chunk_seed_key: String = "%s:chunk:%d" % [seed_key, chunk_index]
	if candidate_attempt_index > 0:
		chunk_seed_key = "%s:candidate:%d" % [chunk_seed_key, candidate_attempt_index]
	var chunk_seed_hash: int = chunk_seed_key.hash()

	if chunk_seed_hash < 0:
		chunk_seed_hash = -chunk_seed_hash

	chunk_rng.seed = chunk_seed_hash
	return chunk_rng

func _select_chunk_type(route_slot: int, difficulty_band: int, chunk_rng: RandomNumberGenerator) -> int:
	ChunkRouteSlot.assert_valid(route_slot)
	ChunkDifficultyBand.assert_valid(difficulty_band)
	Validation.require_condition(chunk_rng != null, "DailyChunkGenerator requires an RNG when selecting a chunk type.")

	var allowed_chunk_types: Array[int] = _get_allowed_chunk_types(route_slot, difficulty_band)
	Validation.require_condition(allowed_chunk_types.size() > 0, "DailyChunkGenerator requires at least one allowed chunk type.")
	if allowed_chunk_types.size() == 1:
		var only_chunk_type: int = allowed_chunk_types[0]
		ChunkType.assert_valid(only_chunk_type)
		return only_chunk_type

	var chunk_type_weights: Array[float] = []
	for chunk_type in allowed_chunk_types:
		chunk_type_weights.append(_get_chunk_type_selection_weight(route_slot, difficulty_band, chunk_type))

	var selected_chunk_type: int = _select_weighted_chunk_type(allowed_chunk_types, chunk_type_weights, chunk_rng)
	ChunkType.assert_valid(selected_chunk_type)
	return selected_chunk_type

func _get_chunk_type_selection_weight(route_slot: int, difficulty_band: int, chunk_type: int) -> float:
	ChunkRouteSlot.assert_valid(route_slot)
	ChunkDifficultyBand.assert_valid(difficulty_band)
	ChunkType.assert_valid(chunk_type)

	var hold_rows: Array[PackedInt32Array] = _get_hold_rows(chunk_type)
	Validation.require_condition(hold_rows.size() > 0, "DailyChunkGenerator chunk-type weighting requires authored hold rows.")
	var total_hold_count: int = _count_total_holds_in_rows(hold_rows)
	var center_row_count: int = _count_center_rows(hold_rows)
	var dual_side_row_count: int = _count_dual_side_rows(hold_rows)
	var outer_lane_row_count: int = _count_outer_lane_rows(hold_rows)
	var single_hold_row_count: int = _count_single_hold_rows(hold_rows)

	var weight: float = _get_chunk_type_route_slot_base_weight(route_slot, difficulty_band, chunk_type)
	match route_slot:
		ChunkRouteSlot.Value.OPENER:
			weight += float(center_row_count) * 0.35
			weight += float(total_hold_count) * 0.02
		ChunkRouteSlot.Value.BASELINE:
			weight += float(center_row_count) * 0.25
			weight += float(dual_side_row_count) * 0.18
			weight += float(total_hold_count) * 0.03
		ChunkRouteSlot.Value.SKILL:
			weight += float(dual_side_row_count) * 0.4
			weight += float(outer_lane_row_count) * 0.14
			weight -= float(single_hold_row_count) * 0.08
		ChunkRouteSlot.Value.RECOVERY:
			weight += float(total_hold_count) * 0.05
			weight += float(center_row_count) * 0.28
			weight -= float(single_hold_row_count) * 0.12
			weight -= float(outer_lane_row_count) * 0.06
		ChunkRouteSlot.Value.RISK:
			weight += float(dual_side_row_count) * 0.34
			weight += float(outer_lane_row_count) * 0.28
			weight -= float(center_row_count) * 0.05
		ChunkRouteSlot.Value.PRESSURE:
			weight += float(single_hold_row_count) * 0.42
			weight += float(outer_lane_row_count) * 0.24
			weight -= float(total_hold_count) * 0.04
			weight -= float(center_row_count) * 0.08
		_:
			Validation.require_condition(false, "DailyChunkGenerator chunk-type weighting requires a supported route slot.")

	return maxf(weight, 0.1)

func _get_chunk_type_route_slot_base_weight(route_slot: int, difficulty_band: int, chunk_type: int) -> float:
	ChunkRouteSlot.assert_valid(route_slot)
	ChunkDifficultyBand.assert_valid(difficulty_band)
	ChunkType.assert_valid(chunk_type)
	match route_slot:
		ChunkRouteSlot.Value.OPENER:
			match chunk_type:
				ChunkType.Value.LADDER:
					return 4.4
				ChunkType.Value.ZIGZAG:
					return 3.9
				_:
					return 1.0
		ChunkRouteSlot.Value.BASELINE:
			match chunk_type:
				ChunkType.Value.ZIGZAG:
					return 4.2
				ChunkType.Value.LADDER:
					return 3.8
				ChunkType.Value.WIDE_TRAVERSE:
					return 3.7
				ChunkType.Value.DENSE_RECOVERY:
					return 3.5
				ChunkType.Value.FORK:
					return 3.6 if difficulty_band == ChunkDifficultyBand.Value.CHALLENGE else 2.8
				_:
					return 1.0
		ChunkRouteSlot.Value.SKILL:
			match chunk_type:
				ChunkType.Value.ZIGZAG:
					return 4.2
				ChunkType.Value.WIDE_TRAVERSE:
					return 4.0
				ChunkType.Value.FORK:
					return 4.3
				ChunkType.Value.SWING_GAP:
					return 4.1
				_:
					return 1.0
		ChunkRouteSlot.Value.RECOVERY:
			match chunk_type:
				ChunkType.Value.DENSE_RECOVERY:
					return 4.6
				ChunkType.Value.LADDER:
					return 4.0
				ChunkType.Value.ZIGZAG:
					return 3.5
				_:
					return 1.0
		ChunkRouteSlot.Value.RISK:
			match chunk_type:
				ChunkType.Value.RISK_LANE:
					return 4.6
				ChunkType.Value.FORK:
					return 4.2
				ChunkType.Value.WIDE_TRAVERSE:
					return 3.8
				ChunkType.Value.SPARSE_REACH:
					return 3.9
				ChunkType.Value.ZIGZAG:
					return 3.3
				_:
					return 1.0
		ChunkRouteSlot.Value.PRESSURE:
			match chunk_type:
				ChunkType.Value.SWING_GAP:
					return 4.7
				ChunkType.Value.SPARSE_REACH:
					return 4.3
				ChunkType.Value.RISK_LANE:
					return 4.0
				_:
					return 1.0
		_:
			Validation.require_condition(false, "DailyChunkGenerator chunk-type base weighting requires a supported route slot.")
			return 1.0

func _select_weighted_chunk_type(
	chunk_types: Array[int],
	chunk_type_weights: Array[float],
	chunk_rng: RandomNumberGenerator
) -> int:
	Validation.require_condition(chunk_types.size() > 0, "DailyChunkGenerator weighted chunk-type selection requires candidates.")
	Validation.require_condition(chunk_types.size() == chunk_type_weights.size(), "DailyChunkGenerator weighted chunk-type candidates must align with weights.")
	Validation.require_condition(chunk_rng != null, "DailyChunkGenerator weighted chunk-type selection requires an RNG.")

	var total_weight: float = 0.0
	for weight in chunk_type_weights:
		Validation.require_condition(weight > 0.0, "DailyChunkGenerator weighted chunk-type selection requires positive weights.")
		total_weight += weight

	Validation.require_condition(total_weight > 0.0, "DailyChunkGenerator weighted chunk-type selection requires positive total weight.")
	var selection_value: float = chunk_rng.randf_range(0.0, total_weight)
	var accumulated_weight: float = 0.0
	for chunk_type_index in range(chunk_types.size()):
		accumulated_weight += chunk_type_weights[chunk_type_index]
		if selection_value <= accumulated_weight:
			return chunk_types[chunk_type_index]

	return chunk_types[chunk_types.size() - 1]

func _count_total_holds_in_rows(hold_rows: Array[PackedInt32Array]) -> int:
	Validation.require_condition(hold_rows.size() > 0, "DailyChunkGenerator row hold counting requires authored hold rows.")
	var total_holds: int = 0
	for row_lane_indices in hold_rows:
		total_holds += row_lane_indices.size()
	return total_holds

func _count_center_rows(hold_rows: Array[PackedInt32Array]) -> int:
	Validation.require_condition(hold_rows.size() > 0, "DailyChunkGenerator center-row counting requires authored hold rows.")
	var center_row_count: int = 0
	for row_lane_indices in hold_rows:
		if row_lane_indices.has(1) and row_lane_indices.has(2):
			center_row_count += 1
	return center_row_count

func _count_dual_side_rows(hold_rows: Array[PackedInt32Array]) -> int:
	Validation.require_condition(hold_rows.size() > 0, "DailyChunkGenerator dual-side row counting requires authored hold rows.")
	var dual_side_row_count: int = 0
	for row_lane_indices in hold_rows:
		var has_left_lane: bool = false
		var has_right_lane: bool = false
		for lane_index in row_lane_indices:
			if lane_index <= 1:
				has_left_lane = true
			if lane_index >= 2:
				has_right_lane = true
		if has_left_lane and has_right_lane:
			dual_side_row_count += 1
	return dual_side_row_count

func _count_outer_lane_rows(hold_rows: Array[PackedInt32Array]) -> int:
	Validation.require_condition(hold_rows.size() > 0, "DailyChunkGenerator outer-lane row counting requires authored hold rows.")
	var outer_lane_row_count: int = 0
	for row_lane_indices in hold_rows:
		if row_lane_indices.has(0) or row_lane_indices.has(3):
			outer_lane_row_count += 1
	return outer_lane_row_count

func _count_single_hold_rows(hold_rows: Array[PackedInt32Array]) -> int:
	Validation.require_condition(hold_rows.size() > 0, "DailyChunkGenerator single-hold row counting requires authored hold rows.")
	var single_hold_row_count: int = 0
	for row_lane_indices in hold_rows:
		if row_lane_indices.size() == 1:
			single_hold_row_count += 1
	return single_hold_row_count

func _get_allowed_chunk_types(route_slot: int, difficulty_band: int) -> Array[int]:
	ChunkRouteSlot.assert_valid(route_slot)
	ChunkDifficultyBand.assert_valid(difficulty_band)

	match route_slot:
		ChunkRouteSlot.Value.OPENER:
			return [ChunkType.Value.LADDER, ChunkType.Value.ZIGZAG]
		ChunkRouteSlot.Value.BASELINE:
			if difficulty_band == ChunkDifficultyBand.Value.EASY:
				return [ChunkType.Value.LADDER, ChunkType.Value.ZIGZAG, ChunkType.Value.DENSE_RECOVERY]
			if difficulty_band == ChunkDifficultyBand.Value.BASELINE:
				return [ChunkType.Value.LADDER, ChunkType.Value.ZIGZAG, ChunkType.Value.WIDE_TRAVERSE, ChunkType.Value.DENSE_RECOVERY]
			return [ChunkType.Value.ZIGZAG, ChunkType.Value.WIDE_TRAVERSE, ChunkType.Value.FORK, ChunkType.Value.DENSE_RECOVERY]
		ChunkRouteSlot.Value.SKILL:
			if difficulty_band == ChunkDifficultyBand.Value.EASY:
				return [ChunkType.Value.ZIGZAG, ChunkType.Value.WIDE_TRAVERSE]
			if difficulty_band == ChunkDifficultyBand.Value.BASELINE:
				return [ChunkType.Value.ZIGZAG, ChunkType.Value.WIDE_TRAVERSE, ChunkType.Value.FORK]
			return [ChunkType.Value.WIDE_TRAVERSE, ChunkType.Value.FORK, ChunkType.Value.SWING_GAP]
		ChunkRouteSlot.Value.RECOVERY:
			if difficulty_band == ChunkDifficultyBand.Value.CHALLENGE:
				return [ChunkType.Value.DENSE_RECOVERY, ChunkType.Value.LADDER, ChunkType.Value.ZIGZAG]
			return [ChunkType.Value.LADDER, ChunkType.Value.DENSE_RECOVERY]
		ChunkRouteSlot.Value.RISK:
			if difficulty_band == ChunkDifficultyBand.Value.EASY:
				return [ChunkType.Value.WIDE_TRAVERSE, ChunkType.Value.ZIGZAG]
			if difficulty_band == ChunkDifficultyBand.Value.BASELINE:
				return [ChunkType.Value.WIDE_TRAVERSE, ChunkType.Value.FORK, ChunkType.Value.RISK_LANE]
			return [ChunkType.Value.FORK, ChunkType.Value.RISK_LANE, ChunkType.Value.SPARSE_REACH]
		ChunkRouteSlot.Value.PRESSURE:
			Validation.require_condition(
				difficulty_band == ChunkDifficultyBand.Value.CHALLENGE,
                "DailyChunkGenerator pressure slots require the challenge difficulty band."
			)
			return [ChunkType.Value.SPARSE_REACH, ChunkType.Value.SWING_GAP, ChunkType.Value.RISK_LANE]
		_:
			Validation.require_condition(false, "DailyChunkGenerator requires a supported route slot.")
			return []

func _build_handholds(
	chunk_index: int,
	chunk_type: int,
	route_slot: int,
	difficulty_band: int,
	risky_lane_side_sign: float,
	chunk_rng: RandomNumberGenerator
) -> Array[GeneratedHandholdSocket]:
	ChunkType.assert_valid(chunk_type)
	ChunkRouteSlot.assert_valid(route_slot)
	ChunkDifficultyBand.assert_valid(difficulty_band)
	Validation.require_condition(
		risky_lane_side_sign == -1.0 or risky_lane_side_sign == 0.0 or risky_lane_side_sign == 1.0,
		"DailyChunkGenerator handhold placement requires a valid route branch side sign."
	)
	Validation.require_condition(chunk_rng != null, "DailyChunkGenerator requires an RNG when building handholds.")

	if chunk_index == 0:
		return _build_opener_handholds(chunk_type, difficulty_band, chunk_rng)

	var lane_positions: Array[float] = _get_lane_positions(chunk_rng)
	var hold_rows: Array[PackedInt32Array] = _get_hold_rows(chunk_type)
	var handholds: Array[GeneratedHandholdSocket] = []
	Validation.require_condition(hold_rows.size() > 0, "DailyChunkGenerator requires at least one handhold row.")
	var step_height_meters: float = _tuning.get_chunk_row_step_height_meters(chunk_type)
	var jitter_scale: float = _get_vertical_jitter_scale(difficulty_band)
	var handhold_sequence_index: int = 0

	for row_index in range(hold_rows.size()):
		var row_lane_indices: PackedInt32Array = hold_rows[row_index]
		Validation.require_condition(row_lane_indices.size() > 0, "DailyChunkGenerator handhold rows cannot be empty.")
		var row_template_role: int = _get_route_row_template_role(row_index, hold_rows.size())

		var row_height_meters: float = _tuning.non_opener_row_base_height_meters + (step_height_meters * float(row_index + 1))
		var row_height_jitter: float = chunk_rng.randf_range(-(jitter_scale * 0.65), jitter_scale * 0.65)
		var horizontal_jitter_scale: float = _get_horizontal_jitter_scale(difficulty_band, row_lane_indices.size())

		for lane_entry_index in range(row_lane_indices.size()):
			var lane_index: int = row_lane_indices[lane_entry_index]
			Validation.require_condition(lane_index >= 0 and lane_index < lane_positions.size(), "DailyChunkGenerator lane pattern index is out of bounds.")

			var hold_height_jitter: float = 0.0
			if row_lane_indices.size() > 1:
				hold_height_jitter = chunk_rng.randf_range(-0.08, 0.08)

			var base_local_position: Vector2 = Vector2(
				_clamp_local_x(lane_positions[lane_index] + chunk_rng.randf_range(-horizontal_jitter_scale, horizontal_jitter_scale)),
				-(row_height_meters + row_height_jitter + hold_height_jitter)
			)
			var local_position: Vector2 = Vector2(
				_clamp_local_x(
					base_local_position.x + _get_route_row_horizontal_offset(
						chunk_type,
						route_slot,
						row_template_role,
						base_local_position.x,
						risky_lane_side_sign
					)
				),
				base_local_position.y
			)
			var handhold_id: StringName = StringName("chunk_%02d_hold_%02d" % [chunk_index, handhold_sequence_index])
			var handhold_type: int = _select_handhold_type(
				chunk_index,
				chunk_type,
				route_slot,
				difficulty_band,
				row_index,
				hold_rows.size(),
				lane_entry_index,
				row_lane_indices.size(),
				base_local_position
			)
			handholds.append(_build_handhold_socket(handhold_id, local_position, handhold_type))
			handhold_sequence_index += 1

	return handholds

func _get_route_row_template_role(row_index: int, row_count: int) -> int:
	Validation.require_condition(row_count > 0, "DailyChunkGenerator route row templates require at least one row.")
	Validation.require_condition(row_index >= 0 and row_index < row_count, "DailyChunkGenerator route row template index is out of bounds.")
	if row_index == 0:
		return RouteRoleScript.Value.ENTRY
	if row_index == row_count - 1:
		return RouteRoleScript.Value.TOP_OUT
	if row_count == 1:
		return RouteRoleScript.Value.ENTRY

	var route_validation_tuning: RouteValidationTuningScript = _get_route_validation_tuning()
	var row_progress_ratio: float = float(row_index) / float(row_count - 1)
	if row_progress_ratio <= route_validation_tuning.setup_zone_upper_ratio:
		return RouteRoleScript.Value.SETUP
	if row_progress_ratio <= route_validation_tuning.crux_zone_upper_ratio:
		return RouteRoleScript.Value.CRUX
	return RouteRoleScript.Value.RECOVERY

func _get_route_row_horizontal_offset(
	chunk_type: int,
	route_slot: int,
	row_template_role: int,
	base_local_x: float,
	risky_lane_side_sign: float
) -> float:
	ChunkType.assert_valid(chunk_type)
	ChunkRouteSlot.assert_valid(route_slot)
	RouteRoleScript.assert_valid(row_template_role)
	Validation.require_condition(
		risky_lane_side_sign == -1.0 or risky_lane_side_sign == 0.0 or risky_lane_side_sign == 1.0,
		"DailyChunkGenerator route row offsets require a valid branch side sign."
	)
	if is_zero_approx(base_local_x):
		return 0.0

	var lane_side_sign: float = signf(base_local_x)
	var offset_meters: float = -lane_side_sign * _get_route_row_center_pull_meters(route_slot, row_template_role)
	if not _supports_lane_choice(chunk_type) or risky_lane_side_sign == 0.0:
		return offset_meters
	if absf(base_local_x) < _get_branch_role_alignment_threshold():
		return offset_meters

	var branch_push_meters: float = _get_route_row_branch_push_meters(route_slot, row_template_role)
	if is_zero_approx(branch_push_meters):
		return offset_meters

	if is_equal_approx(lane_side_sign, risky_lane_side_sign):
		return offset_meters + (lane_side_sign * branch_push_meters)

	return offset_meters - (lane_side_sign * (branch_push_meters * 0.55))

func _get_route_row_center_pull_meters(route_slot: int, row_template_role: int) -> float:
	ChunkRouteSlot.assert_valid(route_slot)
	RouteRoleScript.assert_valid(row_template_role)
	match row_template_role:
		RouteRoleScript.Value.ENTRY:
			return 0.04
		RouteRoleScript.Value.SETUP:
			return 0.02
		RouteRoleScript.Value.TOP_OUT:
			return 0.03
		RouteRoleScript.Value.RECOVERY:
			if route_slot == ChunkRouteSlot.Value.RECOVERY:
				return 0.02
			return 0.0
		_:
			return 0.0

func _get_route_row_branch_push_meters(route_slot: int, row_template_role: int) -> float:
	ChunkRouteSlot.assert_valid(route_slot)
	RouteRoleScript.assert_valid(row_template_role)
	if row_template_role != RouteRoleScript.Value.CRUX and row_template_role != RouteRoleScript.Value.RECOVERY:
		return 0.0

	match route_slot:
		ChunkRouteSlot.Value.BASELINE, ChunkRouteSlot.Value.SKILL:
			return 0.14
		ChunkRouteSlot.Value.RECOVERY:
			return 0.12
		ChunkRouteSlot.Value.RISK, ChunkRouteSlot.Value.PRESSURE:
			return 0.18
		_:
			return 0.0

func _build_opener_handholds(chunk_type: int, difficulty_band: int, chunk_rng: RandomNumberGenerator) -> Array[GeneratedHandholdSocket]:
	ChunkType.assert_valid(chunk_type)
	ChunkDifficultyBand.assert_valid(difficulty_band)
	Validation.require_condition(chunk_rng != null, "DailyChunkGenerator requires an RNG when building opener handholds.")

	var hold_rows: Array[PackedInt32Array] = _tuning.get_opener_hold_rows(chunk_type)
	var lane_positions: Array[float] = _get_opener_lane_positions()
	var handholds: Array[GeneratedHandholdSocket] = []
	Validation.require_condition(hold_rows.size() > 0, "DailyChunkGenerator opener generation requires at least one handhold row.")
	var row_step_height_meters: float = _tuning.get_opener_row_step_height_meters(chunk_type)

	var handhold_sequence_index: int = 0

	for row_index in range(hold_rows.size()):
		var row_lane_indices: PackedInt32Array = hold_rows[row_index]
		Validation.require_condition(row_lane_indices.size() > 0, "DailyChunkGenerator opener handhold rows cannot be empty.")
		var row_height_meters: float = _tuning.opener_first_row_height_meters + (row_step_height_meters * float(row_index))

		for lane_entry_index in range(row_lane_indices.size()):
			var lane_index: int = row_lane_indices[lane_entry_index]
			Validation.require_condition(lane_index >= 0 and lane_index < lane_positions.size(), "DailyChunkGenerator opener lane pattern index is out of bounds.")
			var local_position: Vector2 = Vector2(
				_clamp_local_x(lane_positions[lane_index] + chunk_rng.randf_range(-_tuning.opener_horizontal_jitter_meters, _tuning.opener_horizontal_jitter_meters)),
				-(row_height_meters + chunk_rng.randf_range(-_tuning.opener_vertical_jitter_meters, _tuning.opener_vertical_jitter_meters))
			)
			var handhold_id: StringName = StringName("chunk_00_hold_%02d" % handhold_sequence_index)
			var handhold_type: int = _select_handhold_type(
				0,
				chunk_type,
				ChunkRouteSlot.Value.OPENER,
				difficulty_band,
				row_index,
				hold_rows.size(),
				lane_entry_index,
				row_lane_indices.size(),
				local_position
			)
			handholds.append(_build_handhold_socket(handhold_id, local_position, handhold_type))
			handhold_sequence_index += 1

	return handholds

func _get_opener_lane_positions() -> Array[float]:
	var half_width: float = _tuning.chunk_width_meters * 0.5
	return [
		-(half_width * _tuning.outer_lane_position_ratio),
		-(half_width * _tuning.inner_lane_position_ratio),
		half_width * _tuning.inner_lane_position_ratio,
		half_width * _tuning.outer_lane_position_ratio,
	]

func _build_pickup_sockets(
	chunk_index: int,
	chunk_type: int,
	route_slot: int,
	risky_lane_side_sign: float,
	handholds: Array[GeneratedHandholdSocket],
	chunk_rng: RandomNumberGenerator
) -> Array[GeneratedPickupSocket]:
	Validation.require_condition(handholds.size() > 0, "DailyChunkGenerator requires handholds before generating pickup sockets.")
	ChunkType.assert_valid(chunk_type)
	ChunkRouteSlot.assert_valid(route_slot)
	Validation.require_condition(chunk_rng != null, "DailyChunkGenerator requires an RNG when generating pickup sockets.")

	var pickup_socket_count: int = _tuning.get_pickup_socket_count()
	var pickup_sockets: Array[GeneratedPickupSocket] = []
	var pickup_anchor_pool: Array[GeneratedHandholdSocket] = _get_pickup_anchor_pool(route_slot, chunk_type, risky_lane_side_sign, handholds)

	for socket_index in range(pickup_socket_count):
		var anchor_index: int = socket_index % pickup_anchor_pool.size()
		var anchor_socket: GeneratedHandholdSocket = pickup_anchor_pool[anchor_index]
		var lateral_offset: float = chunk_rng.randf_range(-_tuning.pickup_lateral_offset_meters, _tuning.pickup_lateral_offset_meters)
		var local_position: Vector2 = Vector2(
			_clamp_local_x(anchor_socket.local_position.x + lateral_offset),
			anchor_socket.local_position.y - 0.65
		)
		var socket_id: StringName = StringName("chunk_%02d_pickup_%02d" % [chunk_index, socket_index])
		pickup_sockets.append(GeneratedPickupSocket.new(socket_id, local_position))

	return pickup_sockets

func _build_hazard_sockets(
	chunk_index: int,
	chunk_type: int,
	route_slot: int,
	difficulty_band: int,
	risky_lane_side_sign: float,
	handholds: Array[GeneratedHandholdSocket],
	chunk_rng: RandomNumberGenerator
) -> Array[GeneratedHazardSocket]:
	Validation.require_condition(handholds.size() > 0, "DailyChunkGenerator requires handholds before generating hazard sockets.")
	ChunkType.assert_valid(chunk_type)
	ChunkRouteSlot.assert_valid(route_slot)
	ChunkDifficultyBand.assert_valid(difficulty_band)
	Validation.require_condition(chunk_rng != null, "DailyChunkGenerator requires an RNG when generating hazard sockets.")

	var hazard_socket_count: int = _tuning.get_hazard_socket_count()
	var hazard_sockets: Array[GeneratedHazardSocket] = []
	var hazard_anchor_pool: Array[GeneratedHandholdSocket] = _get_hazard_anchor_pool(route_slot, chunk_type, risky_lane_side_sign, handholds)
	var hazard_anchor_offset: int = 0

	if chunk_index == 0 and hazard_anchor_pool.size() > 3:
		hazard_anchor_offset = 2

	for socket_index in range(hazard_socket_count):
		var lower_handhold_index: int = mini(hazard_anchor_offset + socket_index, hazard_anchor_pool.size() - 1)
		var upper_handhold_index: int = mini(lower_handhold_index + 1, hazard_anchor_pool.size() - 1)
		var lower_handhold: GeneratedHandholdSocket = hazard_anchor_pool[lower_handhold_index]
		var upper_handhold: GeneratedHandholdSocket = hazard_anchor_pool[upper_handhold_index]
		var midpoint: Vector2 = (lower_handhold.local_position + upper_handhold.local_position) * 0.5
		var hazard_kind: int = _select_hazard_kind(chunk_index, socket_index, route_slot, difficulty_band)
		var local_position: Vector2 = _build_hazard_local_position(hazard_kind, midpoint, chunk_rng)
		var socket_id: StringName = StringName("chunk_%02d_hazard_%02d" % [chunk_index, socket_index])
		hazard_sockets.append(GeneratedHazardSocket.new(socket_id, hazard_kind, local_position))

	return hazard_sockets

func _select_hazard_kind(chunk_index: int, socket_index: int, route_slot: int, difficulty_band: int) -> int:
	Validation.require_condition(chunk_index >= 0, "DailyChunkGenerator chunk index cannot be negative when selecting a hazard kind.")
	Validation.require_condition(socket_index >= 0, "DailyChunkGenerator socket index cannot be negative when selecting a hazard kind.")
	ChunkRouteSlot.assert_valid(route_slot)
	ChunkDifficultyBand.assert_valid(difficulty_band)

	if route_slot == ChunkRouteSlot.Value.OPENER:
		return GeneratedHazardKindScript.Value.UPDRAFT

	if route_slot == ChunkRouteSlot.Value.RECOVERY:
		return GeneratedHazardKindScript.Value.UPDRAFT

	if route_slot == ChunkRouteSlot.Value.RISK or route_slot == ChunkRouteSlot.Value.PRESSURE:
		return GeneratedHazardKindScript.Value.SPIKE_CLUSTER

	if route_slot == ChunkRouteSlot.Value.SKILL and difficulty_band == ChunkDifficultyBand.Value.CHALLENGE:
		return GeneratedHazardKindScript.Value.DOWNDRAFT

	if ((chunk_index + socket_index) % 2) == 0:
		return GeneratedHazardKindScript.Value.WIND_GUST

	return GeneratedHazardKindScript.Value.SPIKE_CLUSTER

func _build_hazard_local_position(hazard_kind: int, midpoint: Vector2, chunk_rng: RandomNumberGenerator) -> Vector2:
	GeneratedHazardKindScript.assert_valid(hazard_kind)
	Validation.require_condition(chunk_rng != null, "DailyChunkGenerator requires an RNG when building hazard positions.")

	match hazard_kind:
		GeneratedHazardKindScript.Value.SPIKE_CLUSTER:
			return Vector2(
				_clamp_local_x(midpoint.x + chunk_rng.randf_range(-0.35, 0.35)),
				midpoint.y + 0.4
			)
		GeneratedHazardKindScript.Value.WIND_GUST:
			return Vector2(
				_clamp_local_x(midpoint.x + chunk_rng.randf_range(-0.22, 0.22)),
				midpoint.y - 0.15
			)
		GeneratedHazardKindScript.Value.DOWNDRAFT:
			return Vector2(
				_clamp_local_x(midpoint.x + chunk_rng.randf_range(-0.12, 0.12)),
				midpoint.y - 0.55
			)
		GeneratedHazardKindScript.Value.UPDRAFT:
			return Vector2(
				_clamp_local_x(midpoint.x + chunk_rng.randf_range(-0.16, 0.16)),
				midpoint.y - 0.9
			)
		_:
			Validation.require_condition(false, "DailyChunkGenerator requires a supported hazard kind when building hazard positions.")
			return midpoint

func _get_lane_positions(chunk_rng: RandomNumberGenerator) -> Array[float]:
	var half_width: float = _tuning.chunk_width_meters * 0.5
	var lane_positions: Array[float] = [
		-(half_width * _tuning.outer_lane_position_ratio),
		-(half_width * _tuning.inner_lane_position_ratio),
		half_width * _tuning.inner_lane_position_ratio,
		half_width * _tuning.outer_lane_position_ratio,
	]

	if chunk_rng.randi_range(0, 1) == 1:
		lane_positions.reverse()

	return lane_positions

func _get_hold_rows(chunk_type: int) -> Array[PackedInt32Array]:
	ChunkType.assert_valid(chunk_type)
	return _tuning.get_hold_rows(chunk_type)

func _get_horizontal_jitter_scale(difficulty_band: int, hold_count_in_row: int) -> float:
	ChunkDifficultyBand.assert_valid(difficulty_band)
	Validation.require_condition(hold_count_in_row > 0, "DailyChunkGenerator handhold rows require at least one hold when calculating jitter.")

	var base_scale: float = 0.08
	if hold_count_in_row == 1:
		base_scale = 0.12

	match difficulty_band:
		ChunkDifficultyBand.Value.EASY:
			return base_scale
		ChunkDifficultyBand.Value.BASELINE:
			return base_scale + 0.02
		ChunkDifficultyBand.Value.CHALLENGE:
			return base_scale + 0.04
		_:
			Validation.require_condition(false, "DailyChunkGenerator requires a supported difficulty band for horizontal jitter scaling.")
			return 0.0

func _get_vertical_jitter_scale(difficulty_band: int) -> float:
	ChunkDifficultyBand.assert_valid(difficulty_band)

	match difficulty_band:
		ChunkDifficultyBand.Value.EASY:
			return 0.12
		ChunkDifficultyBand.Value.BASELINE:
			return 0.18
		ChunkDifficultyBand.Value.CHALLENGE:
			return 0.24
		_:
			Validation.require_condition(false, "DailyChunkGenerator requires a supported difficulty band for jitter scaling.")
			return 0.0

func _select_handhold_type(
	chunk_index: int,
	chunk_type: int,
	route_slot: int,
	difficulty_band: int,
	row_index: int,
	row_count: int,
	lane_entry_index: int,
	lane_entry_count: int,
	local_position: Vector2
) -> int:
	Validation.require_condition(chunk_index >= 0, "DailyChunkGenerator handhold type selection requires a non-negative chunk index.")
	ChunkType.assert_valid(chunk_type)
	ChunkRouteSlot.assert_valid(route_slot)
	ChunkDifficultyBand.assert_valid(difficulty_band)
	Validation.require_condition(row_count > 0, "DailyChunkGenerator handhold type selection requires at least one row.")
	Validation.require_condition(row_index >= 0 and row_index < row_count, "DailyChunkGenerator handhold type selection row index is out of bounds.")
	Validation.require_condition(lane_entry_count > 0, "DailyChunkGenerator handhold type selection requires at least one lane entry.")
	Validation.require_condition(
		lane_entry_index >= 0 and lane_entry_index < lane_entry_count,
        "DailyChunkGenerator handhold type selection lane entry index is out of bounds."
	)

	var allowed_handhold_types: Array[int] = _tuning.get_allowed_handhold_types(route_slot, difficulty_band, row_index, row_count)
	Validation.require_condition(
		allowed_handhold_types.size() > 0,
        "DailyChunkGenerator handhold type selection requires at least one allowed handhold type."
	)

	var selector_seed: int = chunk_index \
		+ (chunk_type * 17) \
		+ (route_slot * 23) \
		+ (difficulty_band * 31) \
		+ (row_index * 37) \
		+ (lane_entry_index * 41) \
		+ (lane_entry_count * 43) \
		+ roundi(absf(local_position.x) * 100.0) \
		+ roundi(absf(local_position.y) * 100.0)
	var selector_index: int = selector_seed % allowed_handhold_types.size()
	var handhold_type: int = allowed_handhold_types[selector_index]
	HandholdTypeScript.assert_valid(handhold_type)
	return handhold_type

func _build_handhold_socket(hold_id: StringName, local_position: Vector2, handhold_type: int) -> GeneratedHandholdSocket:
	Validation.require_condition(not String(hold_id).is_empty(), "DailyChunkGenerator handhold socket creation requires a hold id.")
	HandholdTypeScript.assert_valid(handhold_type)

	var definition: HandholdTypeDefinitionScript = _tuning.get_required_handhold_definition(handhold_type)
	var surface_profile: HandholdSurfaceProfileScript = definition.surface_profile as HandholdSurfaceProfileScript
	var lifecycle_rule: HandholdLifecycleRuleScript = definition.lifecycle_rule as HandholdLifecycleRuleScript
	var movement_rule: HandholdMovementRuleScript = definition.movement_rule as HandholdMovementRuleScript
	return GeneratedHandholdSocket.new(
		hold_id,
		definition.definition_id,
		local_position,
		handhold_type,
		surface_profile.stamina_drain_multiplier,
		definition.physical_size_meters,
		definition.visual_color,
		lifecycle_rule.break_after_attach_seconds,
		lifecycle_rule.breaks_on_release,
		movement_rule.release_impulse_vector,
		RouteRoleScript.Value.SETUP
	)

func _get_risky_lane_side_sign(seed_key: String, chunk_index: int, chunk_type: int) -> float:
	ChunkType.assert_valid(chunk_type)
	Validation.require_condition(chunk_index >= 0, "DailyChunkGenerator chunk index cannot be negative when selecting a risky lane side.")

	if not _supports_lane_choice(chunk_type):
		return 0.0

	var side_seed_key: String = "%s:chunk:%d:type:%d:risky_lane" % [seed_key, chunk_index, chunk_type]
	var side_hash: int = side_seed_key.hash()
	if side_hash < 0:
		side_hash = -side_hash

	if (side_hash % 2) == 0:
		return -1.0

	return 1.0

func _supports_lane_choice(chunk_type: int) -> bool:
	ChunkType.assert_valid(chunk_type)

	match chunk_type:
		ChunkType.Value.ZIGZAG:
			return true
		ChunkType.Value.WIDE_TRAVERSE:
			return true
		ChunkType.Value.FORK:
			return true
		ChunkType.Value.RISK_LANE:
			return true
		_:
			return false

func _get_pickup_anchor_pool(
	route_slot: int,
	chunk_type: int,
	risky_lane_side_sign: float,
	handholds: Array[GeneratedHandholdSocket]
) -> Array[GeneratedHandholdSocket]:
	ChunkRouteSlot.assert_valid(route_slot)
	ChunkType.assert_valid(chunk_type)
	Validation.require_condition(handholds.size() > 0, "DailyChunkGenerator pickup anchor selection requires handholds.")

	var role_priority_pool: Array[GeneratedHandholdSocket] = _get_pickup_intent_anchor_pool(route_slot, handholds)
	var side_biased_role_pool: Array[GeneratedHandholdSocket] = _filter_handholds_to_side_or_empty(
		role_priority_pool,
		risky_lane_side_sign,
		_tuning.pickup_branch_side_alignment_meters
	)
	if side_biased_role_pool.size() > 0:
		return side_biased_role_pool
	if role_priority_pool.size() > 0:
		return role_priority_pool

	if not _supports_lane_choice(chunk_type) or risky_lane_side_sign == 0.0:
		return handholds

	return _filter_handholds_to_side(handholds, risky_lane_side_sign, _tuning.pickup_branch_side_alignment_meters)

func _get_hazard_anchor_pool(
	route_slot: int,
	chunk_type: int,
	risky_lane_side_sign: float,
	handholds: Array[GeneratedHandholdSocket]
) -> Array[GeneratedHandholdSocket]:
	ChunkRouteSlot.assert_valid(route_slot)
	ChunkType.assert_valid(chunk_type)
	Validation.require_condition(handholds.size() > 0, "DailyChunkGenerator hazard anchor selection requires handholds.")

	var role_priority_pool: Array[GeneratedHandholdSocket] = _get_hazard_intent_anchor_pool(route_slot, handholds)
	var side_biased_role_pool: Array[GeneratedHandholdSocket] = _filter_handholds_to_side_or_empty(
		role_priority_pool,
		risky_lane_side_sign,
		_tuning.hazard_branch_side_alignment_meters
	)
	if side_biased_role_pool.size() > 0:
		return side_biased_role_pool
	if role_priority_pool.size() > 0:
		return role_priority_pool

	if not _supports_lane_choice(chunk_type) or risky_lane_side_sign == 0.0:
		return handholds

	return _filter_handholds_to_side(handholds, risky_lane_side_sign, _tuning.hazard_branch_side_alignment_meters)

func _get_pickup_intent_anchor_pool(route_slot: int, handholds: Array[GeneratedHandholdSocket]) -> Array[GeneratedHandholdSocket]:
	ChunkRouteSlot.assert_valid(route_slot)
	Validation.require_condition(handholds.size() > 0, "DailyChunkGenerator pickup intent anchor selection requires handholds.")
	match route_slot:
		ChunkRouteSlot.Value.RECOVERY:
			return _get_handholds_with_route_role_priority(
				handholds,
				[RouteRoleScript.Value.REWARD, RouteRoleScript.Value.RECOVERY, RouteRoleScript.Value.TOP_OUT]
			)
		ChunkRouteSlot.Value.RISK, ChunkRouteSlot.Value.PRESSURE:
			return _get_handholds_with_route_role_priority(
				handholds,
				[RouteRoleScript.Value.HAZARD_DENIAL, RouteRoleScript.Value.CRUX, RouteRoleScript.Value.RECOVERY]
			)
		ChunkRouteSlot.Value.SKILL, ChunkRouteSlot.Value.BASELINE:
			return _get_handholds_with_route_role_priority(
				handholds,
				[RouteRoleScript.Value.OPTIONAL_BETA, RouteRoleScript.Value.CRUX, RouteRoleScript.Value.RECOVERY]
			)
		ChunkRouteSlot.Value.OPENER:
			return _get_handholds_with_route_role_priority(
				handholds,
				[RouteRoleScript.Value.ENTRY, RouteRoleScript.Value.SETUP]
			)
		_:
			Validation.require_condition(false, "DailyChunkGenerator pickup intent anchor selection requires a supported route slot.")
			return []

func _get_hazard_intent_anchor_pool(route_slot: int, handholds: Array[GeneratedHandholdSocket]) -> Array[GeneratedHandholdSocket]:
	ChunkRouteSlot.assert_valid(route_slot)
	Validation.require_condition(handholds.size() > 0, "DailyChunkGenerator hazard intent anchor selection requires handholds.")
	match route_slot:
		ChunkRouteSlot.Value.RECOVERY:
			return _get_handholds_with_route_role_priority(
				handholds,
				[RouteRoleScript.Value.RECOVERY, RouteRoleScript.Value.TOP_OUT, RouteRoleScript.Value.SETUP]
			)
		ChunkRouteSlot.Value.RISK, ChunkRouteSlot.Value.PRESSURE:
			return _get_handholds_with_route_role_priority(
				handholds,
				[RouteRoleScript.Value.HAZARD_DENIAL, RouteRoleScript.Value.CRUX, RouteRoleScript.Value.RECOVERY]
			)
		ChunkRouteSlot.Value.SKILL, ChunkRouteSlot.Value.BASELINE:
			return _get_handholds_with_route_role_priority(
				handholds,
				[RouteRoleScript.Value.OPTIONAL_BETA, RouteRoleScript.Value.CRUX, RouteRoleScript.Value.RECOVERY]
			)
		ChunkRouteSlot.Value.OPENER:
			return _get_handholds_with_route_role_priority(
				handholds,
				[RouteRoleScript.Value.SETUP, RouteRoleScript.Value.ENTRY]
			)
		_:
			Validation.require_condition(false, "DailyChunkGenerator hazard intent anchor selection requires a supported route slot.")
			return []

func _get_handholds_with_route_role_priority(
	handholds: Array[GeneratedHandholdSocket],
	role_priority: Array[int]
) -> Array[GeneratedHandholdSocket]:
	Validation.require_condition(handholds.size() > 0, "DailyChunkGenerator route-role priority selection requires handholds.")
	Validation.require_condition(role_priority.size() > 0, "DailyChunkGenerator route-role priority selection requires at least one route role.")
	var prioritized_handholds: Array[GeneratedHandholdSocket] = []
	for route_role in role_priority:
		RouteRoleScript.assert_valid(route_role)
		for handhold in handholds:
			if handhold.route_role == route_role:
				prioritized_handholds.append(handhold)
	return prioritized_handholds

func _filter_handholds_to_side_or_empty(
	handholds: Array[GeneratedHandholdSocket],
	side_sign: float,
	minimum_alignment: float
) -> Array[GeneratedHandholdSocket]:
	Validation.require_condition(minimum_alignment >= 0.0, "DailyChunkGenerator optional side filtering minimum alignment cannot be negative.")
	if handholds.is_empty():
		return []
	if side_sign == 0.0:
		return handholds

	Validation.require_condition(side_sign == -1.0 or side_sign == 1.0, "DailyChunkGenerator optional side filtering requires a valid side sign.")
	var filtered_handholds: Array[GeneratedHandholdSocket] = []
	for handhold in handholds:
		if handhold.local_position.x * side_sign >= minimum_alignment:
			filtered_handholds.append(handhold)
	return filtered_handholds

func _filter_handholds_to_side(
	handholds: Array[GeneratedHandholdSocket],
	side_sign: float,
	minimum_alignment: float
) -> Array[GeneratedHandholdSocket]:
	Validation.require_condition(handholds.size() > 0, "DailyChunkGenerator side filtering requires handholds.")
	Validation.require_condition(side_sign == -1.0 or side_sign == 1.0, "DailyChunkGenerator side filtering requires a valid side sign.")
	Validation.require_condition(minimum_alignment >= 0.0, "DailyChunkGenerator side filtering minimum alignment cannot be negative.")

	var filtered_handholds: Array[GeneratedHandholdSocket] = []
	for handhold in handholds:
		if handhold.local_position.x * side_sign >= minimum_alignment:
			filtered_handholds.append(handhold)

	Validation.require_condition(
		filtered_handholds.size() > 0,
        "DailyChunkGenerator branchable chunk types require aligned handholds for lane-biased placement."
	)
	return filtered_handholds

func _clamp_local_x(local_x: float) -> float:
	var half_width: float = _tuning.chunk_width_meters * 0.5
	return clampf(local_x, -half_width, half_width)
