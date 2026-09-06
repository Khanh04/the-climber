extends GutTest

const ChunkDifficultyBandScript = preload("res://src/gameplay/generation/chunk_difficulty_band.gd")
const ChunkRoutePlanBuilderScript = preload("res://src/gameplay/generation/chunk_route_plan_builder.gd")
const ChunkRoutePlanScript = preload("res://src/gameplay/generation/chunk_route_plan.gd")
const ChunkRouteSlotScript = preload("res://src/gameplay/generation/chunk_route_slot.gd")
const GeneratedHazardIntentScript = preload("res://src/gameplay/generation/generated_hazard_intent.gd")
const HandholdTypeScript = preload("res://src/gameplay/generation/handhold_type.gd")
const RouteBranchSideScript = preload("res://src/gameplay/generation/route_branch_side.gd")
const RouteLaneScript = preload("res://src/gameplay/generation/route_lane.gd")
const RouteMovementStyleScript = preload("res://src/gameplay/generation/route_movement_style.gd")
const RouteRowRoleScript = preload("res://src/gameplay/generation/route_row_role.gd")

func test_route_lane_model_uses_five_lanes_with_center_and_outer_flags() -> void:
    var lanes: Array[int] = RouteLaneScript.get_all_values()

    assert_eq(lanes.size(), 5)
    assert_eq(RouteLaneScript.to_offset(RouteLaneScript.Value.OUTER_LEFT), -2)
    assert_eq(RouteLaneScript.to_offset(RouteLaneScript.Value.CENTER), 0)
    assert_eq(RouteLaneScript.to_offset(RouteLaneScript.Value.OUTER_RIGHT), 2)
    assert_true(RouteLaneScript.is_outer(RouteLaneScript.Value.OUTER_LEFT))
    assert_true(RouteLaneScript.is_outer(RouteLaneScript.Value.OUTER_RIGHT))
    assert_false(RouteLaneScript.is_outer(RouteLaneScript.Value.CENTER))

func test_opener_plan_is_onboarding_safe_and_non_branching() -> void:
    var plan: ChunkRoutePlanScript = _build_plan(0, ChunkRouteSlotScript.Value.OPENER, ChunkDifficultyBandScript.Value.EASY)

    assert_false(plan.optional_route_required)
    assert_eq(plan.route_branch_side, RouteBranchSideScript.Value.NONE)
    assert_eq(plan.movement_style, RouteMovementStyleScript.Value.LADDER)
    assert_gte(plan.get_row_count(), 10)
    assert_gte(plan.count_row_role(RouteRowRoleScript.Value.SUPPORT), 2)
    assert_eq(plan.max_sparse_row_streak, 1)
    assert_true(plan.safe_path_allows_handhold_type(HandholdTypeScript.Value.NORMAL))
    assert_true(plan.safe_path_allows_handhold_type(HandholdTypeScript.Value.REST))
    assert_false(plan.safe_path_allows_handhold_type(HandholdTypeScript.Value.BURN))
    assert_true(plan.has_hazard_intent(GeneratedHazardIntentScript.Value.RECOVERY_LIFT))

func test_easy_skill_plan_requires_readable_short_branch_and_beginner_safe_path() -> void:
    var plan: ChunkRoutePlanScript = _build_plan(2, ChunkRouteSlotScript.Value.SKILL, ChunkDifficultyBandScript.Value.EASY)

    assert_true(plan.optional_route_required)
    assert_ne(plan.route_branch_side, RouteBranchSideScript.Value.NONE)
    assert_eq(plan.minimum_branch_separation_rows, 2)
    assert_eq(plan.minimum_outer_lane_rows, 1)
    assert_eq(plan.max_sparse_row_streak, 1)
    assert_eq(plan.split_row_index, 2)
    assert_gt(plan.merge_row_index, plan.split_row_index)
    assert_gte(plan.get_row_count(), 10)
    assert_gte(plan.count_row_role(RouteRowRoleScript.Value.SUPPORT), 2)
    assert_gte(plan.count_row_role(RouteRowRoleScript.Value.CATCH), 1)
    assert_false(plan.safe_path_allows_handhold_type(HandholdTypeScript.Value.BURN))
    assert_true(plan.optional_path_allows_handhold_type(HandholdTypeScript.Value.BURN))
    assert_true(plan.has_hazard_intent(GeneratedHazardIntentScript.Value.TRAVERSE_FORCE))

func test_baseline_risk_plan_requires_sustained_outer_branch_and_risk_hazards() -> void:
    var plan: ChunkRoutePlanScript = _build_plan(7, ChunkRouteSlotScript.Value.RISK, ChunkDifficultyBandScript.Value.BASELINE)

    assert_true(plan.optional_route_required)
    assert_eq(plan.movement_style, RouteMovementStyleScript.Value.RISK_LANE)
    assert_eq(plan.minimum_branch_separation_rows, 3)
    assert_eq(plan.minimum_outer_lane_rows, 2)
    assert_gte(plan.target_difficulty_score, 0.6)
    assert_true(plan.safe_path_allows_handhold_type(HandholdTypeScript.Value.BURN))
    assert_false(plan.safe_path_allows_handhold_type(HandholdTypeScript.Value.BREAK))
    assert_true(plan.optional_path_allows_handhold_type(HandholdTypeScript.Value.BOOST))
    assert_true(plan.optional_path_allows_handhold_type(HandholdTypeScript.Value.ROCKET))
    assert_true(plan.has_hazard_intent(GeneratedHazardIntentScript.Value.OPTIONAL_BRANCH_DENIAL))
    assert_true(plan.has_hazard_intent(GeneratedHazardIntentScript.Value.REWARD_GREED_PRESSURE))

func test_challenge_pressure_plan_allows_advanced_pressure_and_longer_branch() -> void:
    var plan: ChunkRoutePlanScript = _build_plan(12, ChunkRouteSlotScript.Value.PRESSURE, ChunkDifficultyBandScript.Value.CHALLENGE)

    assert_true(plan.optional_route_required)
    assert_eq(plan.movement_style, RouteMovementStyleScript.Value.PRESSURE)
    assert_eq(plan.minimum_branch_separation_rows, 4)
    assert_eq(plan.minimum_outer_lane_rows, 3)
    assert_eq(plan.max_sparse_row_streak, 3)
    assert_gt(plan.target_difficulty_score, plan.target_support_score)
    assert_true(plan.safe_path_allows_handhold_type(HandholdTypeScript.Value.BREAK))
    assert_true(plan.safe_path_allows_handhold_type(HandholdTypeScript.Value.BOOST))
    assert_true(plan.optional_path_allows_handhold_type(HandholdTypeScript.Value.BREAK))
    assert_true(plan.optional_path_allows_handhold_type(HandholdTypeScript.Value.GHOST))
    assert_true(plan.optional_path_allows_handhold_type(HandholdTypeScript.Value.ROCKET))
    assert_true(plan.has_hazard_intent(GeneratedHazardIntentScript.Value.CRUX_PRESSURE))
    assert_true(plan.has_hazard_intent(GeneratedHazardIntentScript.Value.OPTIONAL_BRANCH_DENIAL))

func test_route_plan_validation_rejects_branch_without_outer_lane_requirement() -> void:
    var plan: ChunkRoutePlanScript = _build_plan(8, ChunkRouteSlotScript.Value.RISK, ChunkDifficultyBandScript.Value.BASELINE)

    plan.minimum_outer_lane_rows = 0

    assert_false(plan.is_valid())

func test_seeded_template_variant_yields_distinct_structures_but_stable_role_multiset() -> void:
    var builder: ChunkRoutePlanBuilderScript = ChunkRoutePlanBuilderScript.new()
    var base_plan: ChunkRoutePlanScript = builder.build_plan(
        DailySeedKey.from_utc_date(2026, 5, 1), 6, ChunkRouteSlotScript.Value.BASELINE, ChunkDifficultyBandScript.Value.BASELINE
    )
    var base_role_multiset: Dictionary[int, int] = _count_roles(base_plan.row_roles)
    var distinct_sequences: Dictionary[String, bool] = {}

    for day in range(1, 21):
        var plan: ChunkRoutePlanScript = builder.build_plan(
            DailySeedKey.from_utc_date(2026, 5, day), 6, ChunkRouteSlotScript.Value.BASELINE, ChunkDifficultyBandScript.Value.BASELINE
        )
        assert_eq(plan.get_row_count(), base_plan.get_row_count())
        assert_eq(plan.row_roles[0], base_plan.row_roles[0])
        assert_eq(plan.row_roles[plan.get_row_count() - 1], RouteRowRoleScript.Value.TOP_OUT)
        assert_eq(_count_roles(plan.row_roles), base_role_multiset)
        distinct_sequences[",".join(_ints_to_strings(plan.row_roles))] = true

    assert_gt(distinct_sequences.size(), 1, "Seeded template variant produced only one structure across seeds.")

func _count_roles(row_roles: Array[int]) -> Dictionary[int, int]:
    var counts: Dictionary[int, int] = {}
    for row_role in row_roles:
        counts[row_role] = counts.get(row_role, 0) + 1
    return counts

func _ints_to_strings(values: Array[int]) -> PackedStringArray:
    var text_values: PackedStringArray = PackedStringArray()
    for value in values:
        var _appended: bool = text_values.append(str(value))
    return text_values

func _build_plan(chunk_index: int, route_slot: int, difficulty_band: int) -> ChunkRoutePlanScript:
    var builder: ChunkRoutePlanBuilderScript = ChunkRoutePlanBuilderScript.new()
    return builder.build_plan(DailySeedKey.from_utc_date(2026, 5, 16), chunk_index, route_slot, difficulty_band)