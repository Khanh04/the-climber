extends GutTest

const ChunkDifficultyBandScript = preload("res://src/gameplay/generation/chunk_difficulty_band.gd")
const ChunkRouteSlotScript = preload("res://src/gameplay/generation/chunk_route_slot.gd")
const ChunkTypeScript = preload("res://src/gameplay/generation/chunk_type.gd")
const DailyChunkGeneratorScript = preload("res://src/gameplay/generation/daily_chunk_generator.gd")
const GeneratedChunkLayoutScript = preload("res://src/gameplay/generation/generated_chunk_layout.gd")
const GeneratedHazardKindScript = preload("res://src/gameplay/generation/generated_hazard_kind.gd")
const GeneratedRouteValidationResultScript: GDScript = preload("res://src/gameplay/generation/generated_route_validation_result.gd")
const HandholdAssignmentRuleScript = preload("res://resources/config/handhold_assignment_rule.gd")
const HandholdSurfaceProfileScript = preload("res://resources/config/handhold_surface_profile.gd")
const HandholdTypeScript = preload("res://src/gameplay/generation/handhold_type.gd")
const HandholdTypeDefinitionScript = preload("res://resources/config/handhold_type_definition.gd")
const HandholdRowZoneScript = preload("res://src/gameplay/generation/handhold_row_zone.gd")
const RouteRoleScript = preload("res://src/gameplay/generation/route_role.gd")
const GenerationTuningScript = preload("res://resources/config/generation_tuning.gd")

func test_build_chunk_is_stable_for_same_seed_and_index() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(tuning)
    var seed_key: String = DailySeedKey.from_utc_date(2026, 5, 14)

    var first_layout: RefCounted = generator.build_chunk(seed_key, 4)
    var second_layout: RefCounted = generator.build_chunk(seed_key, 4)

    assert_eq(_layout_signature(first_layout), _layout_signature(second_layout))

func test_build_chunk_reuses_cached_layout_for_same_seed_and_index() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(tuning)
    var seed_key: String = DailySeedKey.from_utc_date(2026, 5, 14)

    var first_layout: RefCounted = generator.build_chunk(seed_key, 4)
    var second_layout: RefCounted = generator.build_chunk(seed_key, 4)

    assert_eq(first_layout.get_instance_id(), second_layout.get_instance_id())

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
    var pressure_chunk_index: int = _find_first_chunk_index_with_route_slot_and_band(
        generator,
        seed_key,
        ChunkRouteSlotScript.Value.PRESSURE,
        ChunkDifficultyBandScript.Value.CHALLENGE
    )

    var layout: RefCounted = generator.build_chunk(seed_key, pressure_chunk_index)
    var typed_layout: GeneratedChunkLayoutScript = _require_chunk_layout(layout)

    assert_eq(typed_layout.difficulty_band, ChunkDifficultyBandScript.Value.CHALLENGE)
    assert_eq(typed_layout.route_slot, ChunkRouteSlotScript.Value.PRESSURE)
    assert_true(
        typed_layout.chunk_type == ChunkTypeScript.Value.SPARSE_REACH
            or typed_layout.chunk_type == ChunkTypeScript.Value.SWING_GAP
            or typed_layout.chunk_type == ChunkTypeScript.Value.RISK_LANE
    )

func test_weighted_profile_scheduler_keeps_easy_band_free_of_pressure_slots() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(tuning)
    var seed_key: String = DailySeedKey.from_utc_date(2026, 5, 14)

    for chunk_index in range(1, 5):
        var layout: GeneratedChunkLayoutScript = _require_chunk_layout(generator.build_chunk(seed_key, chunk_index))
        assert_ne(layout.route_slot, ChunkRouteSlotScript.Value.PRESSURE)

func test_weighted_profile_scheduler_keeps_baseline_band_free_of_pressure_slots() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(tuning)
    var seed_keys: PackedStringArray = PackedStringArray([
        DailySeedKey.from_utc_date(2026, 5, 14),
        DailySeedKey.from_utc_date(2026, 5, 15),
        DailySeedKey.from_utc_date(2026, 5, 16),
    ])

    for seed_key in seed_keys:
        for chunk_index in range(5, 10):
            var layout: GeneratedChunkLayoutScript = _require_chunk_layout(generator.build_chunk(seed_key, chunk_index))
            if layout.difficulty_band == ChunkDifficultyBandScript.Value.BASELINE:
                assert_ne(layout.route_slot, ChunkRouteSlotScript.Value.PRESSURE)

func test_weighted_profile_scheduler_inserts_recovery_after_pressure() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(tuning)
    var seed_key: String = DailySeedKey.from_utc_date(2026, 5, 14)
    var pressure_chunk_index: int = _find_first_chunk_index_with_route_slot_and_band(
        generator,
        seed_key,
        ChunkRouteSlotScript.Value.PRESSURE,
        ChunkDifficultyBandScript.Value.CHALLENGE
    )

    var next_layout: GeneratedChunkLayoutScript = _require_chunk_layout(generator.build_chunk(seed_key, pressure_chunk_index + 1))

    assert_eq(next_layout.route_slot, ChunkRouteSlotScript.Value.RECOVERY)

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

func test_first_chunk_only_uses_beginner_safe_handhold_types() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(tuning)
    var seed_key: String = DailySeedKey.from_utc_date(2026, 5, 14)

    var layout: GeneratedChunkLayoutScript = _require_chunk_layout(generator.build_chunk(seed_key, 0))

    for handhold in layout.handholds:
        assert_true(
            handhold.handhold_type == HandholdTypeScript.Value.NORMAL
                or handhold.handhold_type == HandholdTypeScript.Value.REST
        )

func test_first_chunk_uses_configured_opener_first_row_height_for_route_start() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    tuning.opener_first_row_height_meters = 0.64
    var generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(tuning)
    var seed_key: String = DailySeedKey.from_utc_date(2026, 5, 14)

    var layout: GeneratedChunkLayoutScript = _require_chunk_layout(generator.build_chunk(seed_key, 0))
    var row_heights: Array[float] = _get_sorted_unique_row_heights(layout.handholds)

    assert_gte(row_heights.size(), 10)
    assert_true(is_equal_approx(row_heights[0], tuning.opener_first_row_height_meters))
    assert_gte(row_heights[row_heights.size() - 1], tuning.segment_height_meters - 1.0)
    assert_lte(_get_max_row_height_gap(row_heights), 1.2)

func test_first_chunk_spreads_holds_without_flat_bars_on_every_row() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(tuning)
    var seed_key: String = DailySeedKey.from_utc_date(2026, 5, 14)

    var layout: GeneratedChunkLayoutScript = _require_chunk_layout(generator.build_chunk(seed_key, 0))
    var row_heights: Array[float] = _get_sorted_unique_row_heights(layout.handholds)

    assert_true(_has_handhold_on_side(layout.handholds, -1))
    assert_true(_has_handhold_on_side(layout.handholds, 1))
    assert_lt(_count_rows_with_minimum_handholds(layout.handholds, row_heights, 3), row_heights.size())

func test_generated_handholds_resolve_type_specific_drain_and_size() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(tuning)
    var seed_key: String = DailySeedKey.from_utc_date(2026, 5, 14)

    var layout: GeneratedChunkLayoutScript = _require_chunk_layout(generator.build_chunk(seed_key, 4))

    for handhold in layout.handholds:
        var definition: HandholdTypeDefinitionScript = tuning.get_required_handhold_definition(handhold.handhold_type)
        var surface_profile: HandholdSurfaceProfileScript = definition.surface_profile as HandholdSurfaceProfileScript
        assert_eq(handhold.definition_id, definition.definition_id)
        assert_eq(
            handhold.stamina_drain_multiplier,
            surface_profile.stamina_drain_multiplier
        )
        assert_true(
            handhold.physical_size_meters.is_equal_approx(
                definition.physical_size_meters
            )
        )

func test_first_chunk_respects_tuned_segment_height_and_avoids_legacy_span() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(tuning)
    var seed_key: String = DailySeedKey.from_utc_date(2026, 5, 14)

    var layout: GeneratedChunkLayoutScript = _require_chunk_layout(generator.build_chunk(seed_key, 0))
    var furthest_upward_hold_height_meters: float = 0.0

    for handhold in layout.handholds:
        furthest_upward_hold_height_meters = maxf(furthest_upward_hold_height_meters, -handhold.local_position.y)

    assert_lte(furthest_upward_hold_height_meters, tuning.segment_height_meters)
    assert_lt(furthest_upward_hold_height_meters, 12.0)

func test_generated_chunks_include_route_validation_metadata() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(tuning)
    var seed_key: String = DailySeedKey.from_utc_date(2026, 5, 14)

    var opener_layout: GeneratedChunkLayoutScript = _require_chunk_layout(generator.build_chunk(seed_key, 0))
    var validation_result: Object = _require_route_validation_result(opener_layout)

    assert_true(_require_route_validation_bool(validation_result, &"is_valid"))
    assert_eq(_require_route_validation_string(validation_result, &"failure_reason"), "")
    assert_true(opener_layout.route_exit_hold_ids.has(String(_require_route_validation_string_name(validation_result, &"target_hold_id"))))
    assert_gt(_require_route_validation_path(validation_result).size(), 0)

func test_generated_adjacent_chunks_include_seam_validation_result() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(tuning)
    var seed_key: String = DailySeedKey.from_utc_date(2026, 5, 14)
    var current_layout: GeneratedChunkLayoutScript = _require_chunk_layout(generator.build_chunk(seed_key, 0))
    var next_layout: GeneratedChunkLayoutScript = _require_chunk_layout(generator.build_chunk(seed_key, 1))

    var seam_result: Object = _require_seam_validation_result(generator.validate_chunk_seam(current_layout, next_layout))

    assert_true(_require_route_validation_bool(seam_result, &"is_valid"))
    assert_eq(_require_route_validation_int(seam_result, &"next_chunk_index"), 1)
    assert_eq(_require_route_validation_string(seam_result, &"failure_reason"), "")
    assert_true(current_layout.route_exit_hold_ids.has(String(_require_route_validation_string_name(seam_result, &"from_hold_id"))))
    assert_true(next_layout.route_entry_hold_ids.has(String(_require_route_validation_string_name(seam_result, &"to_hold_id"))))

func test_generated_chunks_include_explicit_route_ports() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(tuning)
    var seed_key: String = DailySeedKey.from_utc_date(2026, 5, 14)

    var opener_layout: GeneratedChunkLayoutScript = _require_chunk_layout(generator.build_chunk(seed_key, 0))

    assert_gt(opener_layout.route_entry_hold_ids.size(), 0)
    assert_gt(opener_layout.route_exit_hold_ids.size(), 0)
    assert_true(opener_layout.route_entry_hold_ids.has(String(opener_layout.handholds[0].hold_id)) or opener_layout.route_entry_hold_ids.size() > 0)

func test_generated_chunks_assign_entry_and_top_out_route_roles() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(tuning)
    var seed_key: String = DailySeedKey.from_utc_date(2026, 5, 14)

    var opener_layout: GeneratedChunkLayoutScript = _require_chunk_layout(generator.build_chunk(seed_key, 0))
    var entry_role_count: int = 0
    var top_out_role_count: int = 0

    for handhold in opener_layout.handholds:
        if opener_layout.route_entry_hold_ids.has(String(handhold.hold_id)):
            assert_eq(handhold.route_role, RouteRoleScript.Value.ENTRY)
            entry_role_count += 1

        if opener_layout.route_exit_hold_ids.has(String(handhold.hold_id)):
            assert_eq(handhold.route_role, RouteRoleScript.Value.TOP_OUT)
            top_out_role_count += 1

    assert_gt(entry_role_count, 0)
    assert_gt(top_out_role_count, 0)

func test_risk_lane_chunks_assign_branch_route_roles() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(tuning)
    var seed_keys: PackedStringArray = PackedStringArray([
        DailySeedKey.from_utc_date(2026, 5, 14),
        DailySeedKey.from_utc_date(2026, 5, 15),
    ])

    var risk_layout: GeneratedChunkLayoutScript = _find_layout_by_chunk_type(generator, seed_keys, ChunkTypeScript.Value.RISK_LANE)
    var has_branch_role: bool = false

    for handhold in risk_layout.handholds:
        if handhold.route_role == RouteRoleScript.Value.HAZARD_DENIAL \
            or handhold.route_role == RouteRoleScript.Value.OPTIONAL_BETA:
            has_branch_role = true
            break

    assert_true(has_branch_role)

func test_risk_lane_chunks_align_hazard_denial_holds_to_one_outer_side() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(tuning)
    var seed_keys: PackedStringArray = PackedStringArray([
        DailySeedKey.from_utc_date(2026, 5, 14),
        DailySeedKey.from_utc_date(2026, 5, 15),
    ])
    var lane_choice_threshold: float = _get_lane_choice_threshold(tuning)

    var risk_layout: GeneratedChunkLayoutScript = _find_layout_by_chunk_type(generator, seed_keys, ChunkTypeScript.Value.RISK_LANE)
    var hazard_denial_side_score: int = _route_role_side_score(
        risk_layout.handholds,
        RouteRoleScript.Value.HAZARD_DENIAL,
        lane_choice_threshold
    )
    var hazard_denial_average_abs_x: float = _average_abs_x_for_route_role(
        risk_layout.handholds,
        RouteRoleScript.Value.HAZARD_DENIAL
    )
    var setup_average_abs_x: float = _average_abs_x_for_route_role(
        risk_layout.handholds,
        RouteRoleScript.Value.SETUP
    )

    assert_true(hazard_denial_side_score != 0)
    assert_eq(absi(hazard_denial_side_score), _count_handholds_with_route_role(risk_layout.handholds, RouteRoleScript.Value.HAZARD_DENIAL))
    assert_gt(hazard_denial_average_abs_x, setup_average_abs_x)

func test_custom_route_validation_candidate_attempt_count_stays_deterministic() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    tuning.route_validation_candidate_attempt_count = 3
    var generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(tuning)
    var seed_key: String = DailySeedKey.from_utc_date(2026, 5, 14)

    var first_layout: RefCounted = generator.build_chunk(seed_key, 4)
    var second_layout: RefCounted = generator.build_chunk(seed_key, 4)

    assert_eq(_layout_signature(first_layout), _layout_signature(second_layout))

func test_generated_chunks_include_candidate_selection_metadata() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    tuning.route_validation_candidate_attempt_count = 3
    var generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(tuning)
    var seed_key: String = DailySeedKey.from_utc_date(2026, 5, 14)

    var layout: GeneratedChunkLayoutScript = _require_chunk_layout(generator.build_chunk(seed_key, 4))

    assert_gte(layout.selected_candidate_attempt_index, 0)
    assert_lt(layout.selected_candidate_attempt_index, tuning.route_validation_candidate_attempt_count)
    assert_false(is_nan(layout.candidate_score))

func test_recovery_route_maps_to_dense_recovery_metadata_and_reward_socket() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(tuning)
    var seed_key: String = DailySeedKey.from_utc_date(2026, 5, 14)

    var layout: GeneratedChunkLayoutScript = _require_chunk_layout(generator.build_chunk(seed_key, 3))

    assert_eq(layout.route_slot, ChunkRouteSlotScript.Value.RECOVERY)
    assert_eq(layout.chunk_type, ChunkTypeScript.Value.DENSE_RECOVERY)
    assert_gt(layout.pickup_sockets.size(), 0)

func test_pressure_route_maps_to_swing_gap_metadata_and_pressure_hazards() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(tuning)
    var seed_key: String = DailySeedKey.from_utc_date(2026, 5, 14)
    var pressure_chunk_index: int = _find_first_chunk_index_with_route_slot_and_band(
        generator,
        seed_key,
        ChunkRouteSlotScript.Value.PRESSURE,
        ChunkDifficultyBandScript.Value.CHALLENGE
    )

    var layout: GeneratedChunkLayoutScript = _require_chunk_layout(generator.build_chunk(seed_key, pressure_chunk_index))

    assert_eq(layout.route_slot, ChunkRouteSlotScript.Value.PRESSURE)
    assert_eq(layout.chunk_type, ChunkTypeScript.Value.SWING_GAP)
    assert_true(_has_hazard_kind(layout.hazard_sockets, GeneratedHazardKindScript.Value.DOWNDRAFT))
    assert_true(_has_hazard_kind(layout.hazard_sockets, GeneratedHazardKindScript.Value.SPIKE_CLUSTER))

func test_sampled_daily_generation_distribution_preserves_route_first_shape() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(tuning)
    var seed_keys: PackedStringArray = PackedStringArray([
        DailySeedKey.from_utc_date(2026, 5, 14),
        DailySeedKey.from_utc_date(2026, 5, 15),
        DailySeedKey.from_utc_date(2026, 5, 16),
        DailySeedKey.from_utc_date(2026, 5, 17),
        DailySeedKey.from_utc_date(2026, 5, 18),
        DailySeedKey.from_utc_date(2026, 5, 19),
    ])
    var baseline_count: int = 0
    var skill_count: int = 0
    var recovery_count: int = 0
    var risk_count: int = 0
    var pressure_count: int = 0
    var recovery_dense_count: int = 0
    var pressure_swing_gap_count: int = 0

    for seed_key in seed_keys:
        for chunk_index in range(4, 37):
            var layout: GeneratedChunkLayoutScript = _require_chunk_layout(generator.build_chunk(seed_key, chunk_index))
            match layout.route_slot:
                ChunkRouteSlotScript.Value.BASELINE:
                    baseline_count += 1
                ChunkRouteSlotScript.Value.SKILL:
                    skill_count += 1
                ChunkRouteSlotScript.Value.RECOVERY:
                    recovery_count += 1
                    if layout.chunk_type == ChunkTypeScript.Value.DENSE_RECOVERY:
                        recovery_dense_count += 1
                ChunkRouteSlotScript.Value.RISK:
                    risk_count += 1
                ChunkRouteSlotScript.Value.PRESSURE:
                    pressure_count += 1
                    if layout.chunk_type == ChunkTypeScript.Value.SWING_GAP:
                        pressure_swing_gap_count += 1
                _:
                    fail_test("Unexpected route slot in sampled distribution test.")

    assert_gt(baseline_count, 0)
    assert_gt(skill_count, 0)
    assert_gt(recovery_count, 0)
    assert_gt(risk_count, 0)
    assert_gt(pressure_count, 0)
    assert_gt(recovery_count, pressure_count)
    assert_eq(recovery_dense_count, recovery_count)
    assert_eq(pressure_swing_gap_count, pressure_count)

func test_generated_chunk_sockets_follow_route_intents() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(tuning)
    var seed_key: String = DailySeedKey.from_utc_date(2026, 5, 14)

    var layout: GeneratedChunkLayoutScript = _require_chunk_layout(generator.build_chunk(seed_key, 3))

    assert_eq(layout.route_slot, ChunkRouteSlotScript.Value.RECOVERY)
    assert_eq(layout.pickup_sockets.size(), 1)
    assert_eq(layout.hazard_sockets.size(), 2)
    assert_gt(layout.handholds.size(), 0)

func test_generator_assigns_specific_hazard_kinds_by_route_pressure() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(tuning)
    var seed_key: String = DailySeedKey.from_utc_date(2026, 5, 14)
    var easy_skill_chunk_index: int = _find_first_chunk_index_with_route_slot_and_band(
        generator,
        seed_key,
        ChunkRouteSlotScript.Value.SKILL,
        ChunkDifficultyBandScript.Value.EASY
    )
    var challenge_skill_chunk_index: int = _find_first_chunk_index_with_route_slot_and_band(
        generator,
        seed_key,
        ChunkRouteSlotScript.Value.SKILL,
        ChunkDifficultyBandScript.Value.CHALLENGE
    )
    var pressure_chunk_index: int = _find_first_chunk_index_with_route_slot_and_band(
        generator,
        seed_key,
        ChunkRouteSlotScript.Value.PRESSURE,
        ChunkDifficultyBandScript.Value.CHALLENGE
    )

    var opener_layout: GeneratedChunkLayoutScript = _require_chunk_layout(generator.build_chunk(seed_key, 0))
    var easy_skill_layout: GeneratedChunkLayoutScript = _require_chunk_layout(generator.build_chunk(seed_key, easy_skill_chunk_index))
    var challenge_skill_layout: GeneratedChunkLayoutScript = _require_chunk_layout(generator.build_chunk(seed_key, challenge_skill_chunk_index))
    var pressure_layout: GeneratedChunkLayoutScript = _require_chunk_layout(generator.build_chunk(seed_key, pressure_chunk_index))

    assert_gt(opener_layout.hazard_sockets.size(), 0)
    assert_gt(easy_skill_layout.hazard_sockets.size(), 0)
    assert_gt(challenge_skill_layout.hazard_sockets.size(), 0)
    assert_gt(pressure_layout.hazard_sockets.size(), 0)
    assert_eq(opener_layout.hazard_sockets[0].hazard_kind, GeneratedHazardKindScript.Value.UPDRAFT)
    assert_eq(easy_skill_layout.route_slot, ChunkRouteSlotScript.Value.SKILL)
    assert_eq(easy_skill_layout.hazard_sockets[0].hazard_kind, GeneratedHazardKindScript.Value.WIND_GUST)
    assert_eq(challenge_skill_layout.route_slot, ChunkRouteSlotScript.Value.SKILL)
    assert_eq(challenge_skill_layout.difficulty_band, ChunkDifficultyBandScript.Value.CHALLENGE)
    assert_eq(challenge_skill_layout.hazard_sockets[0].hazard_kind, GeneratedHazardKindScript.Value.WIND_GUST)
    assert_eq(challenge_skill_layout.hazard_sockets[1].hazard_kind, GeneratedHazardKindScript.Value.DOWNDRAFT)
    assert_eq(pressure_layout.hazard_sockets[0].hazard_kind, GeneratedHazardKindScript.Value.DOWNDRAFT)
    assert_eq(pressure_layout.hazard_sockets[1].hazard_kind, GeneratedHazardKindScript.Value.SPIKE_CLUSTER)

func test_recovery_chunks_offer_more_support_than_pressure_chunks() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(tuning)
    var seed_key: String = DailySeedKey.from_utc_date(2026, 5, 14)
    var pressure_chunk_index: int = _find_first_chunk_index_with_route_slot_and_band(
        generator,
        seed_key,
        ChunkRouteSlotScript.Value.PRESSURE,
        ChunkDifficultyBandScript.Value.CHALLENGE
    )

    var recovery_layout: GeneratedChunkLayoutScript = _require_chunk_layout(generator.build_chunk(seed_key, 3))
    var pressure_layout: GeneratedChunkLayoutScript = _require_chunk_layout(generator.build_chunk(seed_key, pressure_chunk_index))

    assert_eq(recovery_layout.route_slot, ChunkRouteSlotScript.Value.RECOVERY)
    assert_eq(pressure_layout.route_slot, ChunkRouteSlotScript.Value.PRESSURE)
    assert_gt(recovery_layout.handholds.size(), pressure_layout.handholds.size())

func test_skill_chunks_preserve_horizontal_branch_options_across_rows() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(tuning)
    var seed_key: String = DailySeedKey.from_utc_date(2026, 5, 14)
    var lane_choice_threshold: float = _get_lane_choice_threshold(tuning)
    var skill_chunk_index: int = _find_first_chunk_index_with_route_slot_and_band(
        generator,
        seed_key,
        ChunkRouteSlotScript.Value.SKILL,
        ChunkDifficultyBandScript.Value.EASY
    )

    var skill_layout: GeneratedChunkLayoutScript = _require_chunk_layout(generator.build_chunk(seed_key, skill_chunk_index))

    assert_gte(_count_rows_with_dual_side_options(skill_layout.handholds, lane_choice_threshold), 3)

func test_risk_lane_chunks_bias_hazards_and_pickups_to_shared_risky_side() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(tuning)
    var seed_keys: PackedStringArray = PackedStringArray([
        DailySeedKey.from_utc_date(2026, 5, 14),
        DailySeedKey.from_utc_date(2026, 5, 15),
    ])
    var lane_choice_threshold: float = _get_lane_choice_threshold(tuning)

    var risk_layout: GeneratedChunkLayoutScript = _find_layout_by_chunk_type(generator, seed_keys, ChunkTypeScript.Value.RISK_LANE)
    var pickup_side_score: int = _pickup_side_score(risk_layout.pickup_sockets, lane_choice_threshold)
    var hazard_side_score: int = _hazard_side_score(risk_layout.hazard_sockets, lane_choice_threshold)

    assert_gt(_count_handholds_with_route_role(risk_layout.handholds, RouteRoleScript.Value.HAZARD_DENIAL), 0)
    assert_true(pickup_side_score != 0)
    assert_true(hazard_side_score != 0)
    assert_gt(pickup_side_score * hazard_side_score, 0)
    assert_gte(absi(pickup_side_score), 1)
    assert_gte(absi(hazard_side_score), 1)

func test_challenge_pressure_chunks_assign_break_or_boost_handholds() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(tuning)
    var seed_key: String = DailySeedKey.from_utc_date(2026, 5, 14)
    var pressure_chunk_index: int = _find_first_chunk_index_with_route_slot_and_band(
        generator,
        seed_key,
        ChunkRouteSlotScript.Value.PRESSURE,
        ChunkDifficultyBandScript.Value.CHALLENGE
    )

    var layout: GeneratedChunkLayoutScript = _require_chunk_layout(generator.build_chunk(seed_key, pressure_chunk_index))
    var has_special_pressure_hold: bool = false

    for handhold in layout.handholds:
        if handhold.handhold_type == HandholdTypeScript.Value.BREAK \
            or handhold.handhold_type == HandholdTypeScript.Value.BOOST:
            has_special_pressure_hold = true
            break

    assert_true(has_special_pressure_hold)

func test_route_first_handhold_policy_ignores_legacy_assignment_rows() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    tuning.handhold_assignment_rules = [
        _build_assignment_rule(
            ChunkRouteSlotScript.Value.BASELINE,
            false,
            ChunkDifficultyBandScript.Value.EASY,
            HandholdRowZoneScript.Value.ANY,
            [HandholdTypeScript.Value.BOOST]
        ),
    ]
    var generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(tuning)
    var seed_key: String = DailySeedKey.from_utc_date(2026, 5, 14)

    var layout: GeneratedChunkLayoutScript = _require_chunk_layout(generator.build_chunk(seed_key, 1))

    for handhold in layout.handholds:
        assert_ne(handhold.handhold_type, HandholdTypeScript.Value.BOOST)

func test_route_first_generation_uses_intent_sockets_over_legacy_socket_split() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    tuning.pickup_socket_ratio = 0.75
    var generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(tuning)
    var seed_key: String = DailySeedKey.from_utc_date(2026, 5, 14)

    var recovery_layout: GeneratedChunkLayoutScript = _require_chunk_layout(generator.build_chunk(seed_key, 3))

    assert_eq(recovery_layout.route_slot, ChunkRouteSlotScript.Value.RECOVERY)
    assert_eq(recovery_layout.pickup_sockets.size(), 1)
    assert_eq(recovery_layout.hazard_sockets.size(), 2)

func test_custom_branch_alignment_threshold_pushes_biased_sockets_to_outer_lanes() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    tuning.pickup_branch_side_alignment_meters = 0.8
    tuning.hazard_branch_side_alignment_meters = 0.8
    var generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(tuning)
    var seed_keys: PackedStringArray = PackedStringArray([
        DailySeedKey.from_utc_date(2026, 5, 14),
        DailySeedKey.from_utc_date(2026, 5, 15),
    ])

    var risk_layout: GeneratedChunkLayoutScript = _find_layout_by_chunk_type(generator, seed_keys, ChunkTypeScript.Value.RISK_LANE)

    for pickup_socket in risk_layout.pickup_sockets:
        assert_gte(absf(pickup_socket.local_position.x), 0.5)

    for hazard_socket in risk_layout.hazard_sockets:
        assert_gte(absf(hazard_socket.local_position.x), 0.5)

func _layout_signature(layout: RefCounted) -> String:
    var typed_layout: GeneratedChunkLayoutScript = _require_chunk_layout(layout)
    var signature_parts: PackedStringArray = PackedStringArray([
        _chunk_type_name(typed_layout.chunk_type),
        _route_slot_name(typed_layout.route_slot),
        _difficulty_band_name(typed_layout.difficulty_band),
        str(typed_layout.start_height_meters),
    ])

    if typed_layout.route_validation_result != null:
        var route_validation_result: Object = _require_route_validation_result(typed_layout)
        var _append_validation_result: bool = signature_parts.append(
            "validation:%s:%s:%s:%d" % [
                str(_require_route_validation_bool(route_validation_result, &"is_valid")),
                String(_require_route_validation_string_name(route_validation_result, &"target_hold_id")),
                _require_route_validation_string(route_validation_result, &"failure_reason"),
                _require_route_validation_path(route_validation_result).size(),
            ]
        )

    var _append_entry_ports_result: bool = signature_parts.append("entry_ports:%s" % ",".join(typed_layout.route_entry_hold_ids))
    var _append_exit_ports_result: bool = signature_parts.append("exit_ports:%s" % ",".join(typed_layout.route_exit_hold_ids))

    for handhold in typed_layout.handholds:
        var _append_handhold_result: bool = signature_parts.append(
            "%s:%s:%s@%.3f,%.3f" % [
                String(handhold.hold_id),
                HandholdTypeScript.to_label(handhold.handhold_type),
                RouteRoleScript.to_label(handhold.route_role),
                handhold.local_position.x,
                handhold.local_position.y,
            ]
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

func _require_route_validation_result(layout: GeneratedChunkLayoutScript) -> Object:
    var validation_result: RefCounted = layout.route_validation_result
    assert_not_null(validation_result)
    assert_true(validation_result is Object)
    var validation_object: Object = validation_result
    return validation_object

func _require_seam_validation_result(result: RefCounted) -> Object:
    assert_not_null(result)
    assert_true(result is Object)
    var seam_object: Object = result
    return seam_object

func _require_route_validation_bool(result_object: Object, property_name: StringName) -> bool:
    var raw_value: Variant = result_object.get(property_name)
    assert_true(raw_value is bool)
    var typed_value: bool = raw_value
    return typed_value

func _require_route_validation_string(result_object: Object, property_name: StringName) -> String:
    var raw_value: Variant = result_object.get(property_name)
    assert_true(raw_value is String)
    var typed_value: String = raw_value
    return typed_value

func _require_route_validation_string_name(result_object: Object, property_name: StringName) -> StringName:
    var raw_value: Variant = result_object.get(property_name)
    assert_true(raw_value is StringName)
    var typed_value: StringName = raw_value
    return typed_value

func _require_route_validation_int(result_object: Object, property_name: StringName) -> int:
    var raw_value: Variant = result_object.get(property_name)
    assert_true(raw_value is int)
    var typed_value: int = raw_value
    return typed_value

func _require_route_validation_path(result_object: Object) -> PackedStringArray:
    var raw_value: Variant = result_object.get(&"path_hold_ids")
    assert_true(raw_value is PackedStringArray)
    var typed_value: PackedStringArray = raw_value
    return typed_value

func _get_top_hold_id(layout: GeneratedChunkLayoutScript) -> String:
    var top_hold_id: String = String(layout.handholds[0].hold_id)
    var top_hold_y: float = layout.handholds[0].local_position.y

    for handhold in layout.handholds:
        if handhold.local_position.y < top_hold_y:
            top_hold_id = String(handhold.hold_id)
            top_hold_y = handhold.local_position.y

    return top_hold_id

func _find_layout_by_chunk_type(
    generator: DailyChunkGeneratorScript,
    seed_keys: PackedStringArray,
    chunk_type: int
) -> GeneratedChunkLayoutScript:
    ChunkTypeScript.assert_valid(chunk_type)

    for seed_key in seed_keys:
        for chunk_index in range(1, 41):
            var layout: GeneratedChunkLayoutScript = _require_chunk_layout(generator.build_chunk(seed_key, chunk_index))
            if layout.chunk_type == chunk_type:
                return layout

    fail_test("Expected to find chunk type %s in the scanned layouts." % _chunk_type_name(chunk_type))
    return _require_chunk_layout(generator.build_chunk(seed_keys[0], 1))

func _find_first_chunk_index_with_route_slot_and_band(
    generator: DailyChunkGeneratorScript,
    seed_key: String,
    route_slot: int,
    difficulty_band: int
) -> int:
    ChunkRouteSlotScript.assert_valid(route_slot)
    ChunkDifficultyBandScript.assert_valid(difficulty_band)

    for chunk_index in range(1, 81):
        var layout: GeneratedChunkLayoutScript = _require_chunk_layout(generator.build_chunk(seed_key, chunk_index))
        if layout.route_slot == route_slot and layout.difficulty_band == difficulty_band:
            return chunk_index

    fail_test(
        "Expected to find route slot %s in difficulty band %s within the scanned chunk range." % [
            _route_slot_name(route_slot),
            _difficulty_band_name(difficulty_band),
        ]
    )
    return 1

func _count_rows_with_dual_side_options(handholds: Array[GeneratedHandholdSocket], lane_choice_threshold: float) -> int:
    var row_keys: Array[int] = []
    var left_counts: Array[int] = []
    var right_counts: Array[int] = []

    for handhold in handholds:
        var row_key: int = roundi(handhold.local_position.y * 2.0)
        var row_index: int = row_keys.find(row_key)
        if row_index == -1:
            row_index = row_keys.size()
            row_keys.append(row_key)
            left_counts.append(0)
            right_counts.append(0)

        if handhold.local_position.x <= -lane_choice_threshold:
            left_counts[row_index] += 1
        elif handhold.local_position.x >= lane_choice_threshold:
            right_counts[row_index] += 1

    var dual_side_row_count: int = 0
    for row_index in range(row_keys.size()):
        if left_counts[row_index] > 0 and right_counts[row_index] > 0:
            dual_side_row_count += 1

    return dual_side_row_count

func _pickup_side_score(pickup_sockets: Array[GeneratedPickupSocket], lane_choice_threshold: float) -> int:
    var side_score: int = 0
    for pickup_socket in pickup_sockets:
        if pickup_socket.local_position.x <= -lane_choice_threshold:
            side_score -= 1
        elif pickup_socket.local_position.x >= lane_choice_threshold:
            side_score += 1

    return side_score

func _hazard_side_score(hazard_sockets: Array[GeneratedHazardSocket], lane_choice_threshold: float) -> int:
    var side_score: int = 0
    for hazard_socket in hazard_sockets:
        if hazard_socket.local_position.x <= -lane_choice_threshold:
            side_score -= 1
        elif hazard_socket.local_position.x >= lane_choice_threshold:
            side_score += 1

    return side_score

func _has_hazard_kind(hazard_sockets: Array[GeneratedHazardSocket], hazard_kind: int) -> bool:
    GeneratedHazardKindScript.assert_valid(hazard_kind)

    for hazard_socket in hazard_sockets:
        if hazard_socket.hazard_kind == hazard_kind:
            return true

    return false

func _route_role_side_score(
    handholds: Array[GeneratedHandholdSocket],
    route_role: int,
    lane_choice_threshold: float
) -> int:
    RouteRoleScript.assert_valid(route_role)
    var side_score: int = 0
    for handhold in handholds:
        if handhold.route_role != route_role:
            continue
        if handhold.local_position.x <= -lane_choice_threshold:
            side_score -= 1
        elif handhold.local_position.x >= lane_choice_threshold:
            side_score += 1

    return side_score

func _count_handholds_with_route_role(handholds: Array[GeneratedHandholdSocket], route_role: int) -> int:
    RouteRoleScript.assert_valid(route_role)
    var count: int = 0
    for handhold in handholds:
        if handhold.route_role == route_role:
            count += 1

    return count

func _average_abs_x_for_route_role(handholds: Array[GeneratedHandholdSocket], route_role: int) -> float:
    RouteRoleScript.assert_valid(route_role)
    var total_abs_x: float = 0.0
    var count: int = 0
    for handhold in handholds:
        if handhold.route_role != route_role:
            continue
        total_abs_x += absf(handhold.local_position.x)
        count += 1

    assert_gt(count, 0)
    return total_abs_x / float(count)

func _build_assignment_rule(
    route_slot: int,
    applies_to_all_difficulty_bands: bool,
    difficulty_band: int,
    row_zone: int,
    allowed_handhold_types: Array[int]
) -> HandholdAssignmentRuleScript:
    var assignment_rule: HandholdAssignmentRuleScript = HandholdAssignmentRuleScript.new()
    assignment_rule.route_slot = route_slot
    assignment_rule.applies_to_all_difficulty_bands = applies_to_all_difficulty_bands
    assignment_rule.difficulty_band = difficulty_band
    assignment_rule.row_zone = row_zone
    assignment_rule.allowed_handhold_types = allowed_handhold_types
    return assignment_rule

func _get_lane_choice_threshold(tuning: GenerationTuningScript) -> float:
    return (tuning.chunk_width_meters * 0.5 * tuning.inner_lane_position_ratio) * 0.5

func _get_sorted_unique_row_heights(handholds: Array[GeneratedHandholdSocket]) -> Array[float]:
    var row_heights: Array[float] = []

    for handhold in handholds:
        var row_height_meters: float = -handhold.local_position.y
        var has_matching_row: bool = false
        for existing_row_height in row_heights:
            if is_equal_approx(existing_row_height, row_height_meters):
                has_matching_row = true
                break

        if not has_matching_row:
            row_heights.append(row_height_meters)

    row_heights.sort()
    return row_heights

func _get_max_row_height_gap(row_heights: Array[float]) -> float:
    Validation.require_condition(row_heights.size() >= 2, "Test row gap helper requires at least two rows.")
    var max_gap: float = 0.0
    for row_index in range(1, row_heights.size()):
        max_gap = maxf(max_gap, row_heights[row_index] - row_heights[row_index - 1])

    return max_gap

func _has_handhold_on_side(handholds: Array[GeneratedHandholdSocket], side_sign: int) -> bool:
    Validation.require_condition(side_sign == -1 or side_sign == 1, "Test side helper requires a left or right sign.")
    for handhold in handholds:
        if side_sign < 0 and handhold.local_position.x < -0.01:
            return true

        if side_sign > 0 and handhold.local_position.x > 0.01:
            return true

    return false

func _count_rows_with_minimum_handholds(
    handholds: Array[GeneratedHandholdSocket],
    row_heights: Array[float],
    minimum_handhold_count: int
) -> int:
    Validation.require_condition(minimum_handhold_count > 0, "Test row count helper requires a positive minimum.")
    var matching_row_count: int = 0
    for row_height in row_heights:
        var handhold_count: int = 0
        for handhold in handholds:
            if is_equal_approx(-handhold.local_position.y, row_height):
                handhold_count += 1

        if handhold_count >= minimum_handhold_count:
            matching_row_count += 1

    return matching_row_count

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