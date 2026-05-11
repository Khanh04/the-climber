extends GutTest

const RunEndReasonScript = preload("res://src/core/run_end_reason.gd")
const RunSessionScript = preload("res://src/gameplay/run/run_session.gd")
const RunStateScript = preload("res://src/gameplay/run/run_state.gd")

func test_new_run_session_starts_ready_with_empty_progress() -> void:
    var session = RunSessionScript.new()

    assert_eq(session.get_state(), RunStateScript.Value.READY)
    assert_eq(session.get_height_meters(), 0.0)
    assert_eq(session.get_run_earned_coins(), 0)
    assert_false(session.has_used_rescue())
    assert_false(session.has_end_reason())

func test_start_run_and_progress_tracking_update_active_session() -> void:
    var session = RunSessionScript.new()

    session.start_run()
    session.record_height(12.5)
    session.record_height(9.0)
    session.add_run_earned_coins(6)

    assert_eq(session.get_state(), RunStateScript.Value.CLIMBING)
    assert_eq(session.get_height_meters(), 12.5)
    assert_eq(session.get_run_earned_coins(), 6)

func test_resolve_eligible_fall_offers_rescue_and_consuming_rescue_resumes_run() -> void:
    var session = RunSessionScript.new()

    session.start_run()
    session.begin_fall()
    session.resolve_fall(RunEndReasonScript.Value.BOTTOM_SCREEN_FALL)

    assert_eq(session.get_state(), RunStateScript.Value.RESCUE_OFFERED)
    assert_true(session.has_end_reason())
    assert_eq(session.get_end_reason(), RunEndReasonScript.Value.BOTTOM_SCREEN_FALL)

    session.consume_rescue()

    assert_eq(session.get_state(), RunStateScript.Value.CLIMBING)
    assert_true(session.has_used_rescue())
    assert_false(session.has_end_reason())

func test_second_rescue_eligible_fall_ends_run_after_rescue_is_used() -> void:
    var session = RunSessionScript.new()

    session.start_run()
    session.begin_fall()
    session.resolve_fall(RunEndReasonScript.Value.BOTTOM_SCREEN_FALL)
    session.consume_rescue()
    session.begin_fall()
    session.resolve_fall(RunEndReasonScript.Value.STAMINA_FALL)

    assert_eq(session.get_state(), RunStateScript.Value.ENDED)
    assert_true(session.has_used_rescue())
    assert_true(session.has_end_reason())
    assert_eq(session.get_end_reason(), RunEndReasonScript.Value.STAMINA_FALL)

func test_stamina_fall_helpers_route_through_shared_fall_flow() -> void:
    var session = RunSessionScript.new()

    session.start_run()
    session.begin_stamina_fall()

    assert_eq(session.get_state(), RunStateScript.Value.FALLING)

    session.resolve_stamina_fall()

    assert_eq(session.get_state(), RunStateScript.Value.RESCUE_OFFERED)
    assert_true(session.has_end_reason())
    assert_eq(session.get_end_reason(), RunEndReasonScript.Value.STAMINA_FALL)

func test_non_rescueable_end_reason_ends_run_immediately() -> void:
    var session = RunSessionScript.new()

    session.start_run()
    session.end_run(RunEndReasonScript.Value.CHASER_CONTACT)

    assert_eq(session.get_state(), RunStateScript.Value.ENDED)
    assert_true(session.has_end_reason())
    assert_eq(session.get_end_reason(), RunEndReasonScript.Value.CHASER_CONTACT)

func test_reset_returns_ended_run_to_ready_and_clears_session_data() -> void:
    var session = RunSessionScript.new()

    session.start_run()
    session.record_height(7.0)
    session.add_run_earned_coins(3)
    session.end_run(RunEndReasonScript.Value.LETHAL_HAZARD)
    session.reset()

    assert_eq(session.get_state(), RunStateScript.Value.READY)
    assert_eq(session.get_height_meters(), 0.0)
    assert_eq(session.get_run_earned_coins(), 0)
    assert_false(session.has_used_rescue())
    assert_false(session.has_end_reason())