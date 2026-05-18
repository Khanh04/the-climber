class_name RunLoopCoordinator
extends RefCounted

const RunStateScript = preload("res://src/gameplay/run/run_state.gd")

func calculate_bottom_fall_threshold_y(camera_y: float, viewport_height: float, bottom_fall_margin_pixels: float) -> float:
	Validation.require_condition(viewport_height > 0.0, "RunLoopCoordinator viewport height must be positive.")
	Validation.require_condition(bottom_fall_margin_pixels >= 0.0, "RunLoopCoordinator bottom fall margin cannot be negative.")
	return camera_y + (viewport_height * 0.5) + bottom_fall_margin_pixels

func should_resolve_bottom_screen_fall(run_state: int, player_body_y: float, camera_y: float, viewport_height: float, bottom_fall_margin_pixels: float) -> bool:
	RunStateScript.assert_valid(run_state)
	if run_state != RunStateScript.Value.CLIMBING:
		return false

	var bottom_fall_threshold_y: float = calculate_bottom_fall_threshold_y(camera_y, viewport_height, bottom_fall_margin_pixels)
	return player_body_y > bottom_fall_threshold_y

func calculate_camera_target_y(
	current_camera_y: float,
	player_body_y: float,
	camera_player_lower_screen_offset_pixels: float,
	camera_vertical_dead_zone_pixels: float,
	run_state: int
) -> float:
	Validation.require_condition(camera_player_lower_screen_offset_pixels >= 0.0, "RunLoopCoordinator camera offset cannot be negative.")
	Validation.require_condition(camera_vertical_dead_zone_pixels >= 0.0, "RunLoopCoordinator camera dead-zone cannot be negative.")
	RunStateScript.assert_valid(run_state)

	var target_y: float = player_body_y - camera_player_lower_screen_offset_pixels
	if target_y < current_camera_y - camera_vertical_dead_zone_pixels:
		return target_y + camera_vertical_dead_zone_pixels

	if should_follow_descending_camera(run_state):
		return target_y

	return current_camera_y

func should_follow_descending_camera(run_state: int) -> bool:
	RunStateScript.assert_valid(run_state)
	return run_state == RunStateScript.Value.FALLING \
		or run_state == RunStateScript.Value.RESCUE_OFFERED \
		or run_state == RunStateScript.Value.ENDED

func should_show_run_end_screen(run_state: int) -> bool:
	RunStateScript.assert_valid(run_state)
	return run_state == RunStateScript.Value.RESCUE_OFFERED or run_state == RunStateScript.Value.ENDED

func is_rescue_offered(run_state: int) -> bool:
	RunStateScript.assert_valid(run_state)
	return run_state == RunStateScript.Value.RESCUE_OFFERED