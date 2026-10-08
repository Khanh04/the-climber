extends GutTest

const BandFieldProfileScript = preload("res://resources/config/band_field_profile.gd")
const ChunkDifficultyBandScript = preload("res://src/gameplay/generation/chunk_difficulty_band.gd")
const ChunkRouteSlotScript = preload("res://src/gameplay/generation/chunk_route_slot.gd")
const DailyChunkGeneratorScript = preload("res://src/gameplay/generation/daily_chunk_generator.gd")
const FieldChunkDecoratorScript = preload("res://src/gameplay/generation/field_chunk_decorator.gd")
const GeneratedChunkLayoutScript = preload("res://src/gameplay/generation/generated_chunk_layout.gd")
const GeneratedHazardKindScript = preload("res://src/gameplay/generation/generated_hazard_kind.gd")
const GenerationTuningScript = preload("res://resources/config/generation_tuning.gd")
const HandholdTypeScript = preload("res://src/gameplay/generation/handhold_type.gd")
const FieldChunkPipelineScript = preload("res://src/gameplay/generation/field_chunk_pipeline.gd")
const HoldFieldSamplerScript = preload("res://src/gameplay/generation/hold_field_sampler.gd")
const HoldReachGraphScript = preload("res://src/gameplay/generation/hold_reach_graph.gd")
const RouteValidationTuningScript = preload("res://resources/config/route_validation_tuning.gd")

const SAMPLE_SEEDS: Array[String] = ["generator_v6:run:11-1", "generator_v6:run:22-2", "generator_v6:run:33-3"]
const SAMPLE_CHUNK_COUNT: int = 13

func test_build_chunk_is_stable_for_same_seed_and_index() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var first: GeneratedChunkLayoutScript = DailyChunkGeneratorScript.new(tuning).build_chunk(SAMPLE_SEEDS[0], 6)
    var second: GeneratedChunkLayoutScript = DailyChunkGeneratorScript.new(tuning).build_chunk(SAMPLE_SEEDS[0], 6)

    assert_eq(_fingerprint(first), _fingerprint(second))

func test_chunk_generation_is_independent_of_call_order() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var stepwise_generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(tuning)
    for chunk_index in range(9):
        var _layout: GeneratedChunkLayoutScript = stepwise_generator.build_chunk(SAMPLE_SEEDS[1], chunk_index)
    var stepwise: GeneratedChunkLayoutScript = stepwise_generator.build_chunk(SAMPLE_SEEDS[1], 8)
    var direct: GeneratedChunkLayoutScript = DailyChunkGeneratorScript.new(tuning).build_chunk(SAMPLE_SEEDS[1], 8)

    assert_eq(_fingerprint(stepwise), _fingerprint(direct))

func test_rebuilding_an_evicted_chunk_gives_the_same_layout() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(tuning)
    var original: String = _fingerprint(generator.build_chunk(SAMPLE_SEEDS[0], 2))
    var _far: GeneratedChunkLayoutScript = generator.build_chunk(SAMPLE_SEEDS[0], 14)

    assert_eq(_fingerprint(generator.build_chunk(SAMPLE_SEEDS[0], 2)), original)

func test_build_chunk_varies_for_different_seeds() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var first: GeneratedChunkLayoutScript = DailyChunkGeneratorScript.new(tuning).build_chunk(SAMPLE_SEEDS[0], 3)
    var second: GeneratedChunkLayoutScript = DailyChunkGeneratorScript.new(tuning).build_chunk(SAMPLE_SEEDS[1], 3)

    assert_ne(_fingerprint(first), _fingerprint(second))

func test_first_chunk_is_reachable_from_the_player_start_anchors() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var validation_tuning: RouteValidationTuningScript = tuning.get_route_validation_tuning()
    for seed_key in SAMPLE_SEEDS:
        var opener: GeneratedChunkLayoutScript = DailyChunkGeneratorScript.new(tuning).build_chunk(seed_key, 0)
        var entry: Vector2 = _position_of(opener, opener.route_entry_hold_ids[0])
        var nearest: float = INF
        for anchor in validation_tuning.entry_anchor_positions:
            nearest = minf(nearest, anchor.distance_to(entry))

        assert_eq(opener.route_slot, ChunkRouteSlotScript.Value.OPENER)
        assert_lte(nearest, validation_tuning.static_reach_distance_meters, "Opener entry must be inside the start grab reach for %s." % seed_key)

func test_first_chunk_only_uses_beginner_hold_types_and_no_hazards() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    for seed_key in SAMPLE_SEEDS:
        var opener: GeneratedChunkLayoutScript = DailyChunkGeneratorScript.new(tuning).build_chunk(seed_key, 0)
        for handhold in opener.handholds:
            assert_true(
                handhold.handhold_type == HandholdTypeScript.Value.NORMAL or handhold.handhold_type == HandholdTypeScript.Value.REST,
                "Opener hold %s must be NORMAL or REST." % handhold.hold_id
            )
        assert_eq(opener.hazard_sockets.size(), 0)

func test_every_chunk_offers_the_band_route_count() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var validation_tuning: RouteValidationTuningScript = tuning.get_route_validation_tuning()
    for seed_key in SAMPLE_SEEDS:
        var generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(tuning)
        var previous: GeneratedChunkLayoutScript = null
        for chunk_index in range(SAMPLE_CHUNK_COUNT):
            var layout: GeneratedChunkLayoutScript = generator.build_chunk(seed_key, chunk_index)
            var profile: BandFieldProfileScript = tuning.get_field_profile(layout.difficulty_band)
            var route_count: int = _count_distinct_routes(tuning, validation_tuning, previous, layout, profile)
            assert_gte(route_count, profile.required_route_count, "%s chunk %d offers %d routes." % [seed_key, chunk_index, route_count])
            previous = layout

func test_adjacent_chunks_have_reachable_seams() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    for seed_key in SAMPLE_SEEDS:
        var generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(tuning)
        for chunk_index in range(1, SAMPLE_CHUNK_COUNT):
            var seam: GeneratedChunkSeamValidationResult = generator.validate_chunk_seam(generator.build_chunk(seed_key, chunk_index - 1), generator.build_chunk(seed_key, chunk_index))
            assert_true(seam.is_valid, "%s seam into chunk %d: %s" % [seed_key, chunk_index, seam.failure_reason])

func test_each_candidate_gets_its_own_seam_check() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(tuning)
    var seed_key: String = SAMPLE_SEEDS[0]
    var previous: GeneratedChunkLayoutScript = generator.build_chunk(seed_key, 0)
    var band: int = generator.get_difficulty_band_for_chunk(1)
    var reachable: GeneratedChunkLayoutScript = generator._build_chunk_candidate(seed_key, 1, 0, previous, band, false)
    var unreachable: GeneratedChunkLayoutScript = generator._build_chunk_candidate(seed_key, 1, 1, previous, band, false)
    assert_not_null(reachable)
    assert_not_null(unreachable)
    # Lift the whole candidate out of reach of the previous chunk's seam band.
    for handhold in unreachable.handholds:
        handhold.local_position = Vector2(handhold.local_position.x, -11.5)

    assert_true(generator.validate_chunk_seam(previous, reachable).is_valid)
    assert_false(generator.validate_chunk_seam(previous, unreachable).is_valid, "A later candidate must not reuse an earlier candidate's seam result.")

func test_holds_stay_on_the_wall_and_use_most_of_its_width() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var half_width: float = tuning.get_half_usable_width_meters()
    var spans: Array = []
    for seed_key in SAMPLE_SEEDS:
        var generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(tuning)
        for chunk_index in range(SAMPLE_CHUNK_COUNT):
            var layout: GeneratedChunkLayoutScript = generator.build_chunk(seed_key, chunk_index)
            var lowest_x: float = INF
            var highest_x: float = -INF
            for handhold in layout.handholds:
                assert_lte(absf(handhold.local_position.x), half_width + 0.001)
                # Repair holds may sit in the previous chunk's seam band, just below this chunk's floor.
                assert_true(handhold.local_position.y <= tuning.seam_band_height_meters and handhold.local_position.y >= -tuning.segment_height_meters)
                lowest_x = minf(lowest_x, handhold.local_position.x)
                highest_x = maxf(highest_x, handhold.local_position.x)
            assert_gte(highest_x - lowest_x, 8.0, "%s chunk %d spans only %.1f m." % [seed_key, chunk_index, highest_x - lowest_x])
            spans.append(highest_x - lowest_x)
    # Pruning drops edge holds no route uses, so single chunks can be narrower; typical
    # chunks still cover most of the 14 m wall (the old generator used 3.4 m of 8 m).
    assert_gte(_median(spans), 11.0)

func test_easiest_route_moves_fit_the_band_limit_and_get_longer_with_altitude() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var longest_moves_by_band: Dictionary[int, Array] = {}
    for seed_key in SAMPLE_SEEDS:
        var generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(tuning)
        for chunk_index in range(SAMPLE_CHUNK_COUNT):
            var layout: GeneratedChunkLayoutScript = generator.build_chunk(seed_key, chunk_index)
            var longest: float = 0.0
            for index in range(1, layout.safe_path_hold_ids.size()):
                longest = maxf(longest, _position_of(layout, layout.safe_path_hold_ids[index - 1]).distance_to(_position_of(layout, layout.safe_path_hold_ids[index])))
            assert_lte(longest, tuning.get_field_profile(layout.difficulty_band).max_route_move_meters + 0.001)
            if not longest_moves_by_band.has(layout.difficulty_band):
                longest_moves_by_band[layout.difficulty_band] = []
            longest_moves_by_band[layout.difficulty_band].append(longest)

    var easy: float = _median(longest_moves_by_band[ChunkDifficultyBandScript.Value.EASY])
    var baseline: float = _median(longest_moves_by_band[ChunkDifficultyBandScript.Value.BASELINE])
    var challenge: float = _median(longest_moves_by_band[ChunkDifficultyBandScript.Value.CHALLENGE])
    assert_lt(easy, baseline, "EASY hardest move (%.2f) should be below BASELINE (%.2f)." % [easy, baseline])
    assert_lt(baseline, challenge, "BASELINE hardest move (%.2f) should be below CHALLENGE (%.2f)." % [baseline, challenge])

func test_pruning_keeps_hold_counts_well_below_the_unpruned_field() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var counts_by_band: Dictionary[int, Array] = {}
    for seed_key in SAMPLE_SEEDS:
        var generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(tuning)
        for chunk_index in range(SAMPLE_CHUNK_COUNT):
            var layout: GeneratedChunkLayoutScript = generator.build_chunk(seed_key, chunk_index)
            if not counts_by_band.has(layout.difficulty_band):
                counts_by_band[layout.difficulty_band] = []
            counts_by_band[layout.difficulty_band].append(float(layout.handholds.size()))

    # Unpruned medians were ~80 / 59 / 47.
    assert_lte(_median(counts_by_band[ChunkDifficultyBandScript.Value.EASY]), 58.0)
    assert_lte(_median(counts_by_band[ChunkDifficultyBandScript.Value.BASELINE]), 46.0)
    assert_lte(_median(counts_by_band[ChunkDifficultyBandScript.Value.CHALLENGE]), 36.0)

func test_challenge_chunks_use_special_hold_types() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(tuning)
    var seen: Dictionary[int, bool] = {}
    for chunk_index in range(9, SAMPLE_CHUNK_COUNT):
        for handhold in generator.build_chunk(SAMPLE_SEEDS[2], chunk_index).handholds:
            seen[handhold.handhold_type] = true

    assert_true(seen.has(HandholdTypeScript.Value.BREAK) or seen.has(HandholdTypeScript.Value.BOOST))
    assert_true(seen.has(HandholdTypeScript.Value.GHOST) or seen.has(HandholdTypeScript.Value.ROCKET))

func test_hazards_keep_apart_and_coins_stay_out_of_lethal_envelopes() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    for seed_key in SAMPLE_SEEDS:
        var generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(tuning)
        for chunk_index in range(SAMPLE_CHUNK_COUNT):
            var layout: GeneratedChunkLayoutScript = generator.build_chunk(seed_key, chunk_index)
            for index in range(layout.hazard_sockets.size()):
                var hazard: GeneratedHazardSocket = layout.hazard_sockets[index]
                for other_index in range(index + 1, layout.hazard_sockets.size()):
                    assert_gte(hazard.local_position.distance_to(layout.hazard_sockets[other_index].local_position), FieldChunkDecoratorScript.HAZARD_MIN_SPACING_METERS - 0.001)
                if _is_lethal(hazard.hazard_kind):
                    var envelope: Rect2 = FieldChunkDecoratorScript.lethal_envelope(hazard.hazard_kind)
                    envelope.position += hazard.local_position
                    for coin in layout.pickup_sockets:
                        assert_false(envelope.has_point(coin.local_position), "%s chunk %d coin %s sits in a lethal hazard." % [seed_key, chunk_index, coin.socket_id])

func test_coins_are_within_grab_reach_of_a_hold() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var reach: float = tuning.get_route_validation_tuning().static_reach_distance_meters
    var generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(tuning)
    var coin_count: int = 0
    for chunk_index in range(SAMPLE_CHUNK_COUNT):
        var layout: GeneratedChunkLayoutScript = generator.build_chunk(SAMPLE_SEEDS[0], chunk_index)
        for coin in layout.pickup_sockets:
            coin_count += 1
            var nearest: float = INF
            for handhold in layout.handholds:
                nearest = minf(nearest, handhold.local_position.distance_to(coin.local_position))
            assert_lte(nearest, reach)
    assert_gt(coin_count, 0)

func _count_distinct_routes(
    tuning: GenerationTuningScript,
    validation_tuning: RouteValidationTuningScript,
    previous: GeneratedChunkLayoutScript,
    layout: GeneratedChunkLayoutScript,
    profile: BandFieldProfileScript
) -> int:
    var positions: PackedVector2Array = PackedVector2Array()
    var sizes: PackedVector2Array = PackedVector2Array()
    var sources: PackedInt32Array = PackedInt32Array()
    var seam_floor: float = -(tuning.segment_height_meters - tuning.seam_band_height_meters)
    if previous != null:
        for handhold in previous.handholds:
            if handhold.local_position.y <= seam_floor:
                var _s: bool = sources.append(positions.size())
                var _p: bool = positions.append(handhold.local_position + Vector2(0.0, tuning.segment_height_meters))
                var _z: bool = sizes.append(handhold.physical_size_meters)
    var first_new: int = positions.size()
    for handhold in layout.handholds:
        # The opener's two starter holds sit on its first row.
        if previous == null and is_equal_approx(handhold.local_position.y, -tuning.opener_first_row_height_meters):
            var _s: bool = sources.append(positions.size())
        var _p: bool = positions.append(handhold.local_position)
        var _z: bool = sizes.append(handhold.physical_size_meters)
    var graph: HoldReachGraphScript = HoldReachGraphScript.new(positions, sizes, validation_tuning.max_move_distance_meters, validation_tuning.max_downward_move_meters)
    var is_target: PackedByteArray = graph.empty_mask()
    var exempt: PackedByteArray = graph.empty_mask()
    for node in range(first_new, graph.node_count()):
        if positions[node].y <= seam_floor:
            is_target[node] = 1
        if previous == null and positions[node].y > -3.0:
            exempt[node] = 1
    for source in sources:
        exempt[source] = 1
    # Same corridor guides the generator searches with (FieldChunkPipeline._corridor_guides).
    var sampler: HoldFieldSamplerScript = HoldFieldSamplerScript.new(layout.seed_key, tuning.get_half_usable_width_meters())
    var guides: Array[PackedByteArray] = []
    for corridor_index in range(profile.corridor_count):
        var outside_band: PackedByteArray = graph.empty_mask()
        for node in range(graph.node_count()):
            var band_half_width: float = profile.corridor_half_width_meters + FieldChunkPipelineScript.CORRIDOR_BAND_SLACK_METERS
            if exempt[node] == 0 and absf(positions[node].x - sampler.corridor_x(corridor_index, layout.start_height_meters - positions[node].y)) > band_half_width:
                outside_band[node] = 1
        guides.append(outside_band)
    return graph.distinct_routes(sources, is_target, exempt, profile.max_route_move_meters, tuning.route_separation_meters, profile.required_route_count, PackedByteArray(), guides).size()

func _fingerprint(layout: GeneratedChunkLayoutScript) -> String:
    var parts: PackedStringArray = PackedStringArray()
    for handhold in layout.handholds:
        var _h: bool = parts.append("%s:%.4f,%.4f:%d" % [handhold.hold_id, handhold.local_position.x, handhold.local_position.y, handhold.handhold_type])
    for hazard in layout.hazard_sockets:
        var _z: bool = parts.append("%d:%.4f,%.4f" % [hazard.hazard_kind, hazard.local_position.x, hazard.local_position.y])
    for coin in layout.pickup_sockets:
        var _c: bool = parts.append("c:%.4f,%.4f" % [coin.local_position.x, coin.local_position.y])
    return "|".join(parts)

func _position_of(layout: GeneratedChunkLayoutScript, hold_id: String) -> Vector2:
    for handhold in layout.handholds:
        if String(handhold.hold_id) == hold_id:
            return handhold.local_position
    fail_test("Unknown hold %s." % hold_id)
    return Vector2.ZERO

func _median(values: Array) -> float:
    var sorted_values: Array = values.duplicate()
    sorted_values.sort()
    var middle: float = sorted_values[sorted_values.size() / 2]
    return middle

func _is_lethal(hazard_kind: int) -> bool:
    return hazard_kind == GeneratedHazardKindScript.Value.SPIKE_CLUSTER \
        or hazard_kind == GeneratedHazardKindScript.Value.FALLING_ROCK \
        or hazard_kind == GeneratedHazardKindScript.Value.PENDULUM_LOG
