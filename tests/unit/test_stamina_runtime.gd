extends GutTest

const StaminaRuntimeScript = preload("res://src/gameplay/player/stamina_runtime.gd")
const StaminaTuningScript = preload("res://resources/config/stamina_tuning.gd")
const RunSessionScript = preload("res://src/gameplay/run/run_session.gd")
const RunStateScript = preload("res://src/gameplay/run/run_state.gd")
const RunEndReasonScript = preload("res://src/core/run_end_reason.gd")

func test_stamina_only_drains_with_exactly_one_hand_attached() -> void:
    var tuning: StaminaTuningScript = StaminaTuningScript.new()
    var stamina: StaminaRuntimeScript = StaminaRuntimeScript.new(tuning)
    var partially_drained_stamina: float = tuning.one_hand_seconds - 1.5

    assert_false(stamina.advance(2, 1.5))
    assert_eq(stamina.get_current_stamina_seconds(), tuning.one_hand_seconds)

    assert_false(stamina.advance(0, 1.5))
    assert_eq(stamina.get_current_stamina_seconds(), tuning.one_hand_seconds)

    assert_false(stamina.advance(1, 1.5))
    assert_eq(stamina.get_current_stamina_seconds(), partially_drained_stamina)

func test_stamina_respects_drain_multipliers_and_reports_new_depletion_once() -> void:
    var tuning: StaminaTuningScript = StaminaTuningScript.new()
    var stamina: StaminaRuntimeScript = StaminaRuntimeScript.new(tuning)
    var greasy_stamina_remaining: float = tuning.one_hand_seconds - tuning.greasy_ledge_drain_multiplier

    assert_false(stamina.advance(1, 1.0, tuning.greasy_ledge_drain_multiplier))
    assert_eq(stamina.get_current_stamina_seconds(), greasy_stamina_remaining)

    assert_true(stamina.advance(1, tuning.one_hand_seconds))
    assert_true(stamina.is_depleted())
    assert_eq(stamina.get_current_stamina_seconds(), 0.0)
    assert_false(stamina.advance(1, 0.1))

func test_restore_full_refills_depleted_stamina() -> void:
    var tuning: StaminaTuningScript = StaminaTuningScript.new()
    var stamina: StaminaRuntimeScript = StaminaRuntimeScript.new(tuning)

    assert_true(stamina.advance(1, tuning.one_hand_seconds))
    stamina.restore_full()

    assert_false(stamina.is_depleted())
    assert_eq(stamina.get_current_stamina_seconds(), tuning.one_hand_seconds)

func test_stamina_depletion_can_enter_session_level_fall_flow() -> void:
    var tuning: StaminaTuningScript = StaminaTuningScript.new()
    var stamina: StaminaRuntimeScript = StaminaRuntimeScript.new(tuning)
    var session: RunSessionScript = RunSessionScript.new()

    session.start_run()

    assert_true(stamina.advance(1, tuning.one_hand_seconds))

    session.begin_stamina_fall()
    session.resolve_stamina_fall()

    assert_eq(session.get_state(), RunStateScript.Value.RESCUE_OFFERED)
    assert_true(session.has_end_reason())
    assert_eq(session.get_end_reason(), RunEndReasonScript.Value.STAMINA_FALL)