class_name DailyChunkGenerator
extends RefCounted

const GeneratedHazardKindScript = preload("res://src/gameplay/generation/generated_hazard_kind.gd")
const HandholdLifecycleRuleScript = preload("res://resources/config/handhold_lifecycle_rule.gd")
const HandholdMovementRuleScript = preload("res://resources/config/handhold_movement_rule.gd")
const HandholdSurfaceProfileScript = preload("res://resources/config/handhold_surface_profile.gd")
const HandholdTypeScript = preload("res://src/gameplay/generation/handhold_type.gd")
const HandholdTypeDefinitionScript = preload("res://resources/config/handhold_type_definition.gd")
const RoutePathValidatorScript: GDScript = preload("res://src/gameplay/generation/route_path_validator.gd")

const ROUTE_VALIDATION_MAX_MOVE_DISTANCE_METERS: float = 1.2

var _tuning: GenerationTuning
var _route_path_validator: RefCounted
var _route_entry_anchor_positions: Array[Vector2]

func _init(tuning_value: GenerationTuning) -> void:
	Validation.require_condition(tuning_value != null, "DailyChunkGenerator requires generation tuning.")
	_tuning = tuning_value
	_tuning.assert_valid()
	_route_path_validator = _build_route_path_validator(ROUTE_VALIDATION_MAX_MOVE_DISTANCE_METERS)
	_route_entry_anchor_positions = [Vector2(-0.42, -0.24), Vector2(0.42, -0.24)]

func build_chunk(seed_key: String, chunk_index: int) -> GeneratedChunkLayout:
	Validation.require_condition(chunk_index >= 0, "DailyChunkGenerator chunk index cannot be negative.")
	Validation.require_condition(
		seed_key.begins_with(_tuning.generator_version + ":"),
        "DailyChunkGenerator seed key must match the configured generator version."
	)

	var start_height_meters: float = float(chunk_index) * _tuning.segment_height_meters
	var difficulty_band: int = get_difficulty_band_for_height(start_height_meters)
	var route_slot: int = get_route_slot_for_chunk(chunk_index, difficulty_band)
	var chunk_rng: RandomNumberGenerator = _build_chunk_rng(seed_key, chunk_index)
	var chunk_type: int = _select_chunk_type(route_slot, difficulty_band, chunk_rng)
	var risky_lane_side_sign: float = _get_risky_lane_side_sign(seed_key, chunk_index, chunk_type)
	var handholds: Array[GeneratedHandholdSocket] = _build_handholds(chunk_index, chunk_type, route_slot, difficulty_band, chunk_rng)
	var pickup_sockets: Array[GeneratedPickupSocket] = _build_pickup_sockets(
		chunk_index,
		chunk_type,
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
		hazard_sockets
	)
	var route_validation_result: RefCounted = _validate_generated_layout(preliminary_layout)

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
		route_validation_result
	)

func _build_route_path_validator(max_move_distance_meters: float) -> RefCounted:
	var validator_variant: Variant = RoutePathValidatorScript.new(max_move_distance_meters)
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
	var seam_result_variant: Variant = _route_path_validator.call("validate_chunk_seam", current_layout, next_layout)
	Validation.require_condition(
		seam_result_variant is RefCounted,
		"DailyChunkGenerator seam validation must return a RefCounted result."
	)
	var seam_result: RefCounted = seam_result_variant
	return seam_result

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

	if chunk_index == 0:
		return ChunkRouteSlot.Value.OPENER

	var structured_index: int = (chunk_index - 1) % 5
	match structured_index:
		0:
			return ChunkRouteSlot.Value.BASELINE
		1:
			return ChunkRouteSlot.Value.SKILL
		2:
			return ChunkRouteSlot.Value.RECOVERY
		3:
			return ChunkRouteSlot.Value.RISK
		4:
			if difficulty_band == ChunkDifficultyBand.Value.CHALLENGE:
				return ChunkRouteSlot.Value.PRESSURE
			return ChunkRouteSlot.Value.BASELINE
		_:
			Validation.require_condition(false, "DailyChunkGenerator route slot sequencing produced an unsupported index.")
			return ChunkRouteSlot.Value.BASELINE

func _build_chunk_rng(seed_key: String, chunk_index: int) -> RandomNumberGenerator:
	var chunk_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	var chunk_seed_key: String = "%s:chunk:%d" % [seed_key, chunk_index]
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

	var selected_index: int = chunk_rng.randi_range(0, allowed_chunk_types.size() - 1)
	var selected_chunk_type: int = allowed_chunk_types[selected_index]
	ChunkType.assert_valid(selected_chunk_type)
	return selected_chunk_type

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
	chunk_rng: RandomNumberGenerator
) -> Array[GeneratedHandholdSocket]:
	ChunkType.assert_valid(chunk_type)
	ChunkRouteSlot.assert_valid(route_slot)
	ChunkDifficultyBand.assert_valid(difficulty_band)
	Validation.require_condition(chunk_rng != null, "DailyChunkGenerator requires an RNG when building handholds.")

	if chunk_index == 0:
		return _build_opener_handholds(chunk_type, difficulty_band, chunk_rng)

	var lane_positions: Array[float] = _get_lane_positions(chunk_rng)
	var hold_rows: Array[PackedInt32Array] = _get_hold_rows(chunk_type)
	var handholds: Array[GeneratedHandholdSocket] = []
	Validation.require_condition(hold_rows.size() > 0, "DailyChunkGenerator requires at least one handhold row.")
	var vertical_span_meters: float = _tuning.segment_height_meters - 3.0
	var step_height_meters: float = vertical_span_meters / float(hold_rows.size() + 1)
	var jitter_scale: float = _get_vertical_jitter_scale(difficulty_band)
	var handhold_sequence_index: int = 0

	for row_index in range(hold_rows.size()):
		var row_lane_indices: PackedInt32Array = hold_rows[row_index]
		Validation.require_condition(row_lane_indices.size() > 0, "DailyChunkGenerator handhold rows cannot be empty.")

		var row_height_meters: float = 1.5 + (step_height_meters * float(row_index + 1))
		var row_height_jitter: float = chunk_rng.randf_range(-(jitter_scale * 0.65), jitter_scale * 0.65)
		var horizontal_jitter_scale: float = _get_horizontal_jitter_scale(difficulty_band, row_lane_indices.size())

		for lane_entry_index in range(row_lane_indices.size()):
			var lane_index: int = row_lane_indices[lane_entry_index]
			Validation.require_condition(lane_index >= 0 and lane_index < lane_positions.size(), "DailyChunkGenerator lane pattern index is out of bounds.")

			var hold_height_jitter: float = 0.0
			if row_lane_indices.size() > 1:
				hold_height_jitter = chunk_rng.randf_range(-0.08, 0.08)

			var local_position: Vector2 = Vector2(
				_clamp_local_x(lane_positions[lane_index] + chunk_rng.randf_range(-horizontal_jitter_scale, horizontal_jitter_scale)),
				-(row_height_meters + row_height_jitter + hold_height_jitter)
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
				local_position
			)
			handholds.append(_build_handhold_socket(handhold_id, local_position, handhold_type))
			handhold_sequence_index += 1

	return handholds

func _build_opener_handholds(chunk_type: int, difficulty_band: int, chunk_rng: RandomNumberGenerator) -> Array[GeneratedHandholdSocket]:
	ChunkType.assert_valid(chunk_type)
	ChunkDifficultyBand.assert_valid(difficulty_band)
	Validation.require_condition(chunk_rng != null, "DailyChunkGenerator requires an RNG when building opener handholds.")

	var hold_rows: Array[PackedInt32Array] = _tuning.get_opener_hold_rows(chunk_type)
	var lane_positions: Array[float] = _get_opener_lane_positions()
	var handholds: Array[GeneratedHandholdSocket] = []
	Validation.require_condition(hold_rows.size() > 0, "DailyChunkGenerator opener generation requires at least one handhold row.")
	var last_row_height_meters: float = _tuning.segment_height_meters - _tuning.opener_top_padding_meters
	var row_step_height_meters: float = 0.0
	if hold_rows.size() > 1:
		row_step_height_meters = (last_row_height_meters - _tuning.opener_first_row_height_meters) / float(hold_rows.size() - 1)

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
	risky_lane_side_sign: float,
	handholds: Array[GeneratedHandholdSocket],
	chunk_rng: RandomNumberGenerator
) -> Array[GeneratedPickupSocket]:
	Validation.require_condition(handholds.size() > 0, "DailyChunkGenerator requires handholds before generating pickup sockets.")
	ChunkType.assert_valid(chunk_type)
	Validation.require_condition(chunk_rng != null, "DailyChunkGenerator requires an RNG when generating pickup sockets.")

	var pickup_socket_count: int = _tuning.get_pickup_socket_count()
	var pickup_sockets: Array[GeneratedPickupSocket] = []
	var pickup_anchor_pool: Array[GeneratedHandholdSocket] = _get_pickup_anchor_pool(chunk_type, risky_lane_side_sign, handholds)

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
	var hazard_anchor_pool: Array[GeneratedHandholdSocket] = _get_hazard_anchor_pool(chunk_type, risky_lane_side_sign, handholds)
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
		movement_rule.release_impulse_vector
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
	chunk_type: int,
	risky_lane_side_sign: float,
	handholds: Array[GeneratedHandholdSocket]
) -> Array[GeneratedHandholdSocket]:
	ChunkType.assert_valid(chunk_type)
	Validation.require_condition(handholds.size() > 0, "DailyChunkGenerator pickup anchor selection requires handholds.")

	if not _supports_lane_choice(chunk_type) or risky_lane_side_sign == 0.0:
		return handholds

	return _filter_handholds_to_side(handholds, risky_lane_side_sign, _tuning.pickup_branch_side_alignment_meters)

func _get_hazard_anchor_pool(
	chunk_type: int,
	risky_lane_side_sign: float,
	handholds: Array[GeneratedHandholdSocket]
) -> Array[GeneratedHandholdSocket]:
	ChunkType.assert_valid(chunk_type)
	Validation.require_condition(handholds.size() > 0, "DailyChunkGenerator hazard anchor selection requires handholds.")

	if not _supports_lane_choice(chunk_type) or risky_lane_side_sign == 0.0:
		return handholds

	return _filter_handholds_to_side(handholds, risky_lane_side_sign, _tuning.hazard_branch_side_alignment_meters)

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
