extends GutTest

const RunStateScript = preload("res://src/gameplay/run/run_state.gd")
const RunStateTransitionsScript = preload("res://src/gameplay/run/run_state_transitions.gd")

func test_run_state_values_are_validated() -> void:
    assert_true(RunStateScript.is_valid(RunStateScript.Value.READY))
    assert_true(RunStateScript.is_valid(RunStateScript.Value.CLIMBING))
    assert_true(RunStateScript.is_valid(RunStateScript.Value.FALLING))
    assert_true(RunStateScript.is_valid(RunStateScript.Value.RESCUE_OFFERED))
    assert_true(RunStateScript.is_valid(RunStateScript.Value.ENDED))
    assert_false(RunStateScript.is_valid(-1))
    assert_false(RunStateScript.is_valid(99))

func test_transition_matrix_allows_documented_run_flow() -> void:
    assert_true(RunStateTransitionsScript.is_transition_allowed(RunStateScript.Value.READY, RunStateScript.Value.CLIMBING))
    assert_true(RunStateTransitionsScript.is_transition_allowed(RunStateScript.Value.CLIMBING, RunStateScript.Value.FALLING))
    assert_true(RunStateTransitionsScript.is_transition_allowed(RunStateScript.Value.CLIMBING, RunStateScript.Value.ENDED))
    assert_true(RunStateTransitionsScript.is_transition_allowed(RunStateScript.Value.FALLING, RunStateScript.Value.RESCUE_OFFERED))
    assert_true(RunStateTransitionsScript.is_transition_allowed(RunStateScript.Value.FALLING, RunStateScript.Value.ENDED))
    assert_true(RunStateTransitionsScript.is_transition_allowed(RunStateScript.Value.RESCUE_OFFERED, RunStateScript.Value.CLIMBING))
    assert_true(RunStateTransitionsScript.is_transition_allowed(RunStateScript.Value.RESCUE_OFFERED, RunStateScript.Value.ENDED))
    assert_true(RunStateTransitionsScript.is_transition_allowed(RunStateScript.Value.ENDED, RunStateScript.Value.READY))

func test_transition_matrix_rejects_invalid_state_changes() -> void:
    assert_false(RunStateTransitionsScript.is_transition_allowed(RunStateScript.Value.READY, RunStateScript.Value.FALLING))
    assert_false(RunStateTransitionsScript.is_transition_allowed(RunStateScript.Value.CLIMBING, RunStateScript.Value.RESCUE_OFFERED))
    assert_false(RunStateTransitionsScript.is_transition_allowed(RunStateScript.Value.FALLING, RunStateScript.Value.READY))
    assert_false(RunStateTransitionsScript.is_transition_allowed(RunStateScript.Value.ENDED, RunStateScript.Value.CLIMBING))

func test_transition_matrix_rejects_unsupported_state_values() -> void:
    assert_false(RunStateTransitionsScript.is_transition_allowed(-1, RunStateScript.Value.READY))
    assert_false(RunStateTransitionsScript.is_transition_allowed(RunStateScript.Value.READY, 77))