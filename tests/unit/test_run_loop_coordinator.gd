extends GutTest

const RunEndReasonScript = preload("res://src/core/run_end_reason.gd")
const RunLoopCoordinatorScript = preload("res://src/gameplay/run/run_loop_coordinator.gd")
const RunSessionScript = preload("res://src/gameplay/run/run_session.gd")
const RunStateScript = preload("res://src/gameplay/run/run_state.gd")

func test_bottom_fall_threshold_uses_camera_viewport_and_margin() -> void:
	var coordinator = RunLoopCoordinatorScript.new()
	var typed_coordinator: Object = coordinator

	var threshold_y: float = typed_coordinator.call("calculate_bottom_fall_threshold_y", 800.0, 600.0, 160.0)

	assert_eq(threshold_y, 1260.0)

func test_bottom_fall_resolution_requires_active_climb_and_crossing_threshold() -> void:
	var coordinator = RunLoopCoordinatorScript.new()
	var typed_coordinator: Object = coordinator
	var should_resolve_ready: bool = typed_coordinator.call("should_resolve_bottom_screen_fall", RunStateScript.Value.READY, 1300.0, 800.0, 600.0, 160.0)
	var should_resolve_falling: bool = typed_coordinator.call("should_resolve_bottom_screen_fall", RunStateScript.Value.FALLING, 1300.0, 800.0, 600.0, 160.0)
	var should_resolve_at_threshold: bool = typed_coordinator.call("should_resolve_bottom_screen_fall", RunStateScript.Value.CLIMBING, 1260.0, 800.0, 600.0, 160.0)
	var should_resolve_below_screen: bool = typed_coordinator.call("should_resolve_bottom_screen_fall", RunStateScript.Value.CLIMBING, 1261.0, 800.0, 600.0, 160.0)

	assert_false(should_resolve_ready)
	assert_false(should_resolve_falling)
	assert_false(should_resolve_at_threshold)
	assert_true(should_resolve_below_screen)

func test_camera_target_moves_upward_during_climb() -> void:
	var coordinator = RunLoopCoordinatorScript.new()

	var target_y: float = coordinator.calculate_camera_target_y(1000.0, 700.0, 160.0, 72.0, RunStateScript.Value.CLIMBING)

	assert_eq(target_y, 612.0)

func test_camera_target_holds_position_within_climb_dead_zone() -> void:
	var coordinator = RunLoopCoordinatorScript.new()

	var target_y: float = coordinator.calculate_camera_target_y(1000.0, 1090.0, 160.0, 72.0, RunStateScript.Value.CLIMBING)

	assert_eq(target_y, 1000.0)

func test_camera_target_holds_position_when_player_descends_while_climbing() -> void:
	var coordinator = RunLoopCoordinatorScript.new()

	var target_y: float = coordinator.calculate_camera_target_y(540.0, 900.0, 160.0, 72.0, RunStateScript.Value.CLIMBING)

	assert_eq(target_y, 540.0)

func test_camera_target_follows_downward_during_fall_and_run_end_states() -> void:
	var coordinator = RunLoopCoordinatorScript.new()

	assert_eq(coordinator.calculate_camera_target_y(540.0, 900.0, 160.0, 72.0, RunStateScript.Value.FALLING), 740.0)
	assert_eq(coordinator.calculate_camera_target_y(540.0, 900.0, 160.0, 72.0, RunStateScript.Value.RESCUE_OFFERED), 740.0)
	assert_eq(coordinator.calculate_camera_target_y(540.0, 900.0, 160.0, 72.0, RunStateScript.Value.ENDED), 740.0)

func test_camera_target_moves_horizontally_when_player_leaves_dead_zone() -> void:
	var coordinator = RunLoopCoordinatorScript.new()

	var target_x: float = coordinator.calculate_camera_target_x(1000.0, 1180.0, 72.0)

	assert_eq(target_x, 1108.0)

func test_camera_target_holds_horizontal_position_within_dead_zone() -> void:
	var coordinator = RunLoopCoordinatorScript.new()

	var target_x: float = coordinator.calculate_camera_target_x(1000.0, 1050.0, 72.0)

	assert_eq(target_x, 1000.0)


func test_visibility_flags_follow_run_state_contract() -> void:
	var coordinator = RunLoopCoordinatorScript.new()

	assert_false(coordinator.should_show_run_end_screen(RunStateScript.Value.READY))
	assert_false(coordinator.should_show_run_end_screen(RunStateScript.Value.CLIMBING))
	assert_true(coordinator.should_show_run_end_screen(RunStateScript.Value.RESCUE_OFFERED))
	assert_true(coordinator.should_show_run_end_screen(RunStateScript.Value.ENDED))
	assert_false(coordinator.is_rescue_offered(RunStateScript.Value.ENDED))
	assert_true(coordinator.is_rescue_offered(RunStateScript.Value.RESCUE_OFFERED))