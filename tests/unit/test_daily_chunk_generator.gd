extends GutTest

const ChunkDifficultyBandScript = preload("res://src/gameplay/generation/chunk_difficulty_band.gd")
const ChunkRouteSlotScript = preload("res://src/gameplay/generation/chunk_route_slot.gd")
const ChunkTypeScript = preload("res://src/gameplay/generation/chunk_type.gd")
const DailyChunkGeneratorScript = preload("res://src/gameplay/generation/daily_chunk_generator.gd")
const GeneratedChunkLayoutScript = preload("res://src/gameplay/generation/generated_chunk_layout.gd")
const GeneratedHazardKindScript = preload("res://src/gameplay/generation/generated_hazard_kind.gd")
const GenerationTuningScript = preload("res://resources/config/generation_tuning.gd")

func test_build_chunk_is_stable_for_same_seed_and_index() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(tuning)
    var seed_key: String = DailySeedKey.from_utc_date(2026, 5, 14)

    var first_layout: RefCounted = generator.build_chunk(seed_key, 4)
    var second_layout: RefCounted = generator.build_chunk(seed_key, 4)

    assert_eq(_layout_signature(first_layout), _layout_signature(second_layout))

func test_build_chunk_varies_for_different_dates() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(tuning)
    var first_seed_key: String = DailySeedKey.from_utc_date(2026, 5, 14)
    var second_seed_key: String = DailySeedKey.from_utc_date(2026, 5, 15)

    var first_layout: RefCounted = generator.build_chunk(first_seed_key, 4)
    var second_layout: RefCounted = generator.build_chunk(second_seed_key, 4)

    assert_ne(_layout_signature(first_layout), _layout_signature(second_layout))

func test_first_chunk_uses_opener_slot_in_easy_band() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(tuning)
    var seed_key: String = DailySeedKey.from_utc_date(2026, 5, 14)

    var layout: RefCounted = generator.build_chunk(seed_key, 0)
    var typed_layout: GeneratedChunkLayoutScript = _require_chunk_layout(layout)

    assert_eq(typed_layout.route_slot, ChunkRouteSlotScript.Value.OPENER)
    assert_eq(typed_layout.difficulty_band, ChunkDifficultyBandScript.Value.EASY)
    assert_true(
        typed_layout.chunk_type == ChunkTypeScript.Value.LADDER or typed_layout.chunk_type == ChunkTypeScript.Value.ZIGZAG
    )

func test_challenge_band_chunks_can_schedule_pressure_slots() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(tuning)
    var seed_key: String = DailySeedKey.from_utc_date(2026, 5, 14)

    var layout: RefCounted = generator.build_chunk(seed_key, 10)
    var typed_layout: GeneratedChunkLayoutScript = _require_chunk_layout(layout)

    assert_eq(typed_layout.difficulty_band, ChunkDifficultyBandScript.Value.CHALLENGE)
    assert_eq(typed_layout.route_slot, ChunkRouteSlotScript.Value.PRESSURE)
    assert_true(
        typed_layout.chunk_type == ChunkTypeScript.Value.SPARSE_REACH
            or typed_layout.chunk_type == ChunkTypeScript.Value.SWING_GAP
            or typed_layout.chunk_type == ChunkTypeScript.Value.RISK_LANE
    )

func test_chunk_generation_is_independent_of_call_order() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(tuning)
    var seed_key: String = DailySeedKey.from_utc_date(2026, 5, 14)

    var first_layout: RefCounted = generator.build_chunk(seed_key, 7)
    var _earlier_layout: RefCounted = generator.build_chunk(seed_key, 1)
    var second_layout: RefCounted = generator.build_chunk(seed_key, 7)

    assert_eq(_layout_signature(first_layout), _layout_signature(second_layout))

func test_first_chunk_provides_reachable_generated_starter_holds() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(tuning)
    var seed_key: String = DailySeedKey.from_utc_date(2026, 5, 14)
    var grip_range_meters: float = 0.96
    var left_anchor_local_position: Vector2 = Vector2(-0.42, -0.24)
    var right_anchor_local_position: Vector2 = Vector2(0.42, -0.24)

    var layout: GeneratedChunkLayoutScript = _require_chunk_layout(generator.build_chunk(seed_key, 0))

    assert_true(_has_handhold_within_distance(layout.handholds, left_anchor_local_position, grip_range_meters))
    assert_true(_has_handhold_within_distance(layout.handholds, right_anchor_local_position, grip_range_meters))

func test_generated_chunk_respects_total_placeholder_socket_budget() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(tuning)
    var seed_key: String = DailySeedKey.from_utc_date(2026, 5, 14)

    var layout: RefCounted = generator.build_chunk(seed_key, 3)
    var typed_layout: GeneratedChunkLayoutScript = _require_chunk_layout(layout)
    var total_socket_count: int = typed_layout.pickup_sockets.size() + typed_layout.hazard_sockets.size()

    assert_eq(total_socket_count, tuning.socket_count_per_chunk)
    assert_gt(typed_layout.handholds.size(), 0)

func test_generator_assigns_specific_hazard_kinds_by_route_pressure() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(tuning)
    var seed_key: String = DailySeedKey.from_utc_date(2026, 5, 14)

    var opener_layout: GeneratedChunkLayoutScript = _require_chunk_layout(generator.build_chunk(seed_key, 0))
    var easy_skill_layout: GeneratedChunkLayoutScript = _require_chunk_layout(generator.build_chunk(seed_key, 2))
    var challenge_skill_layout: GeneratedChunkLayoutScript = _require_chunk_layout(generator.build_chunk(seed_key, 7))
    var pressure_layout: GeneratedChunkLayoutScript = _require_chunk_layout(generator.build_chunk(seed_key, 10))

    assert_gt(opener_layout.hazard_sockets.size(), 0)
    assert_gt(easy_skill_layout.hazard_sockets.size(), 0)
    assert_gt(challenge_skill_layout.hazard_sockets.size(), 0)
    assert_gt(pressure_layout.hazard_sockets.size(), 0)
    assert_eq(opener_layout.hazard_sockets[0].hazard_kind, GeneratedHazardKindScript.Value.UPDRAFT)
    assert_eq(easy_skill_layout.route_slot, ChunkRouteSlotScript.Value.SKILL)
    assert_eq(easy_skill_layout.hazard_sockets[0].hazard_kind, GeneratedHazardKindScript.Value.WIND_GUST)
    assert_eq(challenge_skill_layout.route_slot, ChunkRouteSlotScript.Value.SKILL)
    assert_eq(challenge_skill_layout.difficulty_band, ChunkDifficultyBandScript.Value.CHALLENGE)
    assert_eq(challenge_skill_layout.hazard_sockets[0].hazard_kind, GeneratedHazardKindScript.Value.DOWNDRAFT)
    assert_eq(pressure_layout.hazard_sockets[0].hazard_kind, GeneratedHazardKindScript.Value.SPIKE_CLUSTER)

func _layout_signature(layout: RefCounted) -> String:
    var typed_layout: GeneratedChunkLayoutScript = _require_chunk_layout(layout)
    var signature_parts: PackedStringArray = PackedStringArray([
        _chunk_type_name(typed_layout.chunk_type),
        _route_slot_name(typed_layout.route_slot),
        _difficulty_band_name(typed_layout.difficulty_band),
        str(typed_layout.start_height_meters),
    ])

    for handhold in typed_layout.handholds:
        var _append_handhold_result: bool = signature_parts.append(
            "%s@%.3f,%.3f" % [String(handhold.hold_id), handhold.local_position.x, handhold.local_position.y]
        )

    for pickup_socket in typed_layout.pickup_sockets:
        var _append_pickup_result: bool = signature_parts.append(
            "%s@%.3f,%.3f" % [String(pickup_socket.socket_id), pickup_socket.local_position.x, pickup_socket.local_position.y]
        )

    for hazard_socket in typed_layout.hazard_sockets:
        var _append_hazard_result: bool = signature_parts.append(
            "%s:%s@%.3f,%.3f" % [
                String(hazard_socket.socket_id),
                GeneratedHazardKindScript.to_label(hazard_socket.hazard_kind),
                hazard_socket.local_position.x,
                hazard_socket.local_position.y,
            ]
        )

    return "|".join(signature_parts)

func _require_chunk_layout(layout: RefCounted) -> GeneratedChunkLayoutScript:
    assert_true(layout is GeneratedChunkLayoutScript)
    return layout as GeneratedChunkLayoutScript

func _has_handhold_within_distance(
    handholds: Array[GeneratedHandholdSocket],
    anchor_local_position: Vector2,
    max_distance_meters: float
) -> bool:
    for handhold in handholds:
        if anchor_local_position.distance_to(handhold.local_position) <= max_distance_meters:
            return true

    return false

func _chunk_type_name(chunk_type: int) -> String:
    match chunk_type:
        ChunkTypeScript.Value.LADDER:
            return "LADDER"
        ChunkTypeScript.Value.ZIGZAG:
            return "ZIGZAG"
        ChunkTypeScript.Value.WIDE_TRAVERSE:
            return "WIDE_TRAVERSE"
        ChunkTypeScript.Value.SPARSE_REACH:
            return "SPARSE_REACH"
        ChunkTypeScript.Value.DENSE_RECOVERY:
            return "DENSE_RECOVERY"
        ChunkTypeScript.Value.FORK:
            return "FORK"
        ChunkTypeScript.Value.RISK_LANE:
            return "RISK_LANE"
        ChunkTypeScript.Value.SWING_GAP:
            return "SWING_GAP"
        _:
            fail_test("Unsupported chunk type in test signature helper.")
            return ""

func _route_slot_name(route_slot: int) -> String:
    match route_slot:
        ChunkRouteSlotScript.Value.OPENER:
            return "OPENER"
        ChunkRouteSlotScript.Value.BASELINE:
            return "BASELINE"
        ChunkRouteSlotScript.Value.SKILL:
            return "SKILL"
        ChunkRouteSlotScript.Value.RECOVERY:
            return "RECOVERY"
        ChunkRouteSlotScript.Value.RISK:
            return "RISK"
        ChunkRouteSlotScript.Value.PRESSURE:
            return "PRESSURE"
        _:
            fail_test("Unsupported route slot in test signature helper.")
            return ""

func _difficulty_band_name(difficulty_band: int) -> String:
    match difficulty_band:
        ChunkDifficultyBandScript.Value.EASY:
            return "EASY"
        ChunkDifficultyBandScript.Value.BASELINE:
            return "BASELINE"
        ChunkDifficultyBandScript.Value.CHALLENGE:
            return "CHALLENGE"
        _:
            fail_test("Unsupported difficulty band in test signature helper.")
            return ""