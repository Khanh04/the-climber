class_name DailyChunkGenerator
extends RefCounted

var _tuning: GenerationTuning

func _init(tuning_value: GenerationTuning) -> void:
    Validation.require_condition(tuning_value != null, "DailyChunkGenerator requires generation tuning.")
    _tuning = tuning_value
    _tuning.assert_valid()

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
    var handholds: Array[GeneratedHandholdSocket] = _build_handholds(chunk_index, chunk_type, difficulty_band, chunk_rng)
    var pickup_sockets: Array[GeneratedPickupSocket] = _build_pickup_sockets(chunk_index, handholds, chunk_rng)
    var hazard_sockets: Array[GeneratedHazardSocket] = _build_hazard_sockets(chunk_index, handholds, chunk_rng)

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
        hazard_sockets
    )

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
    difficulty_band: int,
    chunk_rng: RandomNumberGenerator
) -> Array[GeneratedHandholdSocket]:
    ChunkType.assert_valid(chunk_type)
    ChunkDifficultyBand.assert_valid(difficulty_band)

    var lane_positions: Array[float] = _get_lane_positions(chunk_rng)
    var lane_pattern: Array[int] = _get_lane_pattern(chunk_type)
    var handholds: Array[GeneratedHandholdSocket] = []
    var vertical_span_meters: float = _tuning.segment_height_meters - 3.0
    var step_height_meters: float = vertical_span_meters / float(lane_pattern.size() + 1)
    var jitter_scale: float = _get_vertical_jitter_scale(difficulty_band)

    for handhold_index in range(lane_pattern.size()):
        var lane_index: int = lane_pattern[handhold_index]
        Validation.require_condition(lane_index >= 0 and lane_index < lane_positions.size(), "DailyChunkGenerator lane pattern index is out of bounds.")

        var height_meters: float = 1.5 + (step_height_meters * float(handhold_index + 1))
        var height_jitter: float = chunk_rng.randf_range(-jitter_scale, jitter_scale)
        var local_position: Vector2 = Vector2(
            lane_positions[lane_index] + chunk_rng.randf_range(-0.18, 0.18),
            -(height_meters + height_jitter)
        )
        var handhold_id: StringName = StringName("chunk_%02d_hold_%02d" % [chunk_index, handhold_index])
        handholds.append(GeneratedHandholdSocket.new(handhold_id, local_position, 1.0))

    return handholds

func _build_pickup_sockets(
    chunk_index: int,
    handholds: Array[GeneratedHandholdSocket],
    chunk_rng: RandomNumberGenerator
) -> Array[GeneratedPickupSocket]:
    Validation.require_condition(handholds.size() > 0, "DailyChunkGenerator requires handholds before generating pickup sockets.")

    var pickup_socket_count: int = ceili(float(_tuning.socket_count_per_chunk) * 0.6)
    var pickup_sockets: Array[GeneratedPickupSocket] = []

    for socket_index in range(pickup_socket_count):
        var anchor_index: int = (socket_index * 2) % handholds.size()
        var anchor_socket: GeneratedHandholdSocket = handholds[anchor_index]
        var local_position: Vector2 = Vector2(
            _clamp_local_x(anchor_socket.local_position.x + chunk_rng.randf_range(-0.45, 0.45)),
            anchor_socket.local_position.y - 0.65
        )
        var socket_id: StringName = StringName("chunk_%02d_pickup_%02d" % [chunk_index, socket_index])
        pickup_sockets.append(GeneratedPickupSocket.new(socket_id, local_position))

    return pickup_sockets

func _build_hazard_sockets(
    chunk_index: int,
    handholds: Array[GeneratedHandholdSocket],
    chunk_rng: RandomNumberGenerator
) -> Array[GeneratedHazardSocket]:
    Validation.require_condition(handholds.size() > 0, "DailyChunkGenerator requires handholds before generating hazard sockets.")

    var pickup_socket_count: int = ceili(float(_tuning.socket_count_per_chunk) * 0.6)
    var hazard_socket_count: int = maxi(0, _tuning.socket_count_per_chunk - pickup_socket_count)
    var hazard_sockets: Array[GeneratedHazardSocket] = []

    for socket_index in range(hazard_socket_count):
        var lower_handhold_index: int = (socket_index * 2) % handholds.size()
        var upper_handhold_index: int = mini(lower_handhold_index + 1, handholds.size() - 1)
        var lower_handhold: GeneratedHandholdSocket = handholds[lower_handhold_index]
        var upper_handhold: GeneratedHandholdSocket = handholds[upper_handhold_index]
        var midpoint: Vector2 = (lower_handhold.local_position + upper_handhold.local_position) * 0.5
        var local_position: Vector2 = Vector2(
            _clamp_local_x(midpoint.x + chunk_rng.randf_range(-0.35, 0.35)),
            midpoint.y + 0.4
        )
        var socket_id: StringName = StringName("chunk_%02d_hazard_%02d" % [chunk_index, socket_index])
        hazard_sockets.append(GeneratedHazardSocket.new(socket_id, local_position))

    return hazard_sockets

func _get_lane_positions(chunk_rng: RandomNumberGenerator) -> Array[float]:
    var half_width: float = _tuning.chunk_width_meters * 0.5
    var lane_positions: Array[float] = [
        -(half_width * 0.78),
        -(half_width * 0.26),
        half_width * 0.26,
        half_width * 0.78,
    ]

    if chunk_rng.randi_range(0, 1) == 1:
        lane_positions.reverse()

    return lane_positions

func _get_lane_pattern(chunk_type: int) -> Array[int]:
    ChunkType.assert_valid(chunk_type)

    match chunk_type:
        ChunkType.Value.LADDER:
            return [1, 2, 1, 2, 1, 2, 1, 2]
        ChunkType.Value.ZIGZAG:
            return [0, 3, 0, 3, 1, 2, 1, 2]
        ChunkType.Value.WIDE_TRAVERSE:
            return [0, 1, 2, 3, 2, 1, 2, 3]
        ChunkType.Value.SPARSE_REACH:
            return [0, 3, 1, 2, 0, 3]
        ChunkType.Value.DENSE_RECOVERY:
            return [1, 0, 2, 1, 3, 2, 1, 0, 2, 1]
        ChunkType.Value.FORK:
            return [1, 0, 2, 1, 3, 2, 1, 0]
        ChunkType.Value.RISK_LANE:
            return [1, 1, 0, 2, 3, 2, 1, 3]
        ChunkType.Value.SWING_GAP:
            return [0, 0, 3, 3, 1, 2, 0]
        _:
            Validation.require_condition(false, "DailyChunkGenerator requires a supported chunk type for lane pattern generation.")
            return []

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

func _clamp_local_x(local_x: float) -> float:
    var half_width: float = _tuning.chunk_width_meters * 0.5
    return clampf(local_x, -half_width, half_width)