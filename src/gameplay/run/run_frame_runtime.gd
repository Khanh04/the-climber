class_name RunFrameRuntime
extends RefCounted

const BottomScreenFallServiceScript = preload("res://src/gameplay/run/bottom_screen_fall_service.gd")
const ChaserFeedbackSnapshotScript = preload("res://src/gameplay/chaser/chaser_feedback_snapshot.gd")
const ChaserPacingModelScript = preload("res://src/gameplay/chaser/chaser_pacing_model.gd")
const ClimbPrototypeControllerScript = preload("res://src/gameplay/player/climb_prototype_controller.gd")
const HandSideScript = preload("res://src/gameplay/player/hand_side.gd")
const RunGameplayNodeRefsScript = preload("res://src/gameplay/run/run_gameplay_node_refs.gd")
const RunLoopCoordinatorScript = preload("res://src/gameplay/run/run_loop_coordinator.gd")
const RunSessionScript = preload("res://src/gameplay/run/run_session.gd")
const RunStateScript = preload("res://src/gameplay/run/run_state.gd")

func calculate_current_height_meters(gameplay_nodes: RefCounted, start_y: float, pixels_per_meter: float) -> float:
	var typed_gameplay_nodes: RunGameplayNodeRefsScript = _require_gameplay_nodes(gameplay_nodes)
	Validation.require_condition(pixels_per_meter > 0.0, "RunFrameRuntime pixels-per-meter must be positive.")
	var player_position: Vector2 = typed_gameplay_nodes.player.get_body_global_position()
	Validation.require_condition(player_position.is_finite(), "RunFrameRuntime player position must be finite while calculating height.")
	var height_pixels: float = maxf(0.0, start_y - player_position.y)
	return height_pixels / pixels_per_meter

func update_camera_follow(
	gameplay_nodes: RefCounted,
	run_loop_coordinator: RefCounted,
	run_session: RefCounted,
	camera_player_lower_screen_offset_pixels: float,
	camera_vertical_dead_zone_pixels: float,
	camera_horizontal_dead_zone_pixels: float,
	camera_center_x: float,
	camera_horizontal_travel_limit_pixels: float,
	camera_shake_offset_pixels: Vector2 = Vector2.ZERO
) -> void:
	var typed_gameplay_nodes: RunGameplayNodeRefsScript = _require_gameplay_nodes(gameplay_nodes)
	var typed_run_loop_coordinator: RunLoopCoordinatorScript = _require_run_loop_coordinator(run_loop_coordinator)
	var typed_run_session: RunSessionScript = _require_run_session(run_session)
	Validation.require_condition(camera_horizontal_travel_limit_pixels >= 0.0, "RunFrameRuntime camera horizontal travel limit cannot be negative.")
	var player_position: Vector2 = typed_gameplay_nodes.player.get_body_global_position()
	if not player_position.is_finite():
		Validation.require_condition(
			typed_run_session.get_state() == RunStateScript.Value.ENDED or typed_run_session.get_state() == RunStateScript.Value.RESCUE_OFFERED,
			"RunFrameRuntime player position must be finite while the run is active."
		)
		return
	var target_x: float = typed_run_loop_coordinator.calculate_camera_target_x(
		typed_gameplay_nodes.camera.global_position.x,
		player_position.x,
		camera_horizontal_dead_zone_pixels,
		camera_center_x - camera_horizontal_travel_limit_pixels,
		camera_center_x + camera_horizontal_travel_limit_pixels
	)
	var target_y: float = typed_run_loop_coordinator.calculate_camera_target_y(
		typed_gameplay_nodes.camera.global_position.y,
		player_position.y,
		camera_player_lower_screen_offset_pixels,
		camera_vertical_dead_zone_pixels,
		typed_run_session.get_state()
	)
	# Shake is layered on top of the clean follow target, applied last. The
	# small transient offset does feed back into next frame's dead-zone read,
	# but at this amplitude/duration (see StartleHazardContactService) it
	# stays well inside the dead zone and self-corrects; not worth tracking a
	# separate "clean" camera position just to avoid it.
	typed_gameplay_nodes.camera.global_position = Vector2(target_x, target_y) + camera_shake_offset_pixels

func sync_generated_chunks(
	gameplay_nodes: RefCounted,
	controller: RefCounted,
	run_session: RefCounted,
	current_height_meters: float,
	uses_generated_chunks: bool
) -> void:
	if not uses_generated_chunks:
		return

	var typed_run_session: RunSessionScript = _require_run_session(run_session)
	if typed_run_session.get_state() != RunStateScript.Value.CLIMBING:
		return
	var typed_gameplay_nodes: RunGameplayNodeRefsScript = _require_gameplay_nodes(gameplay_nodes)
	var typed_controller: ClimbPrototypeControllerScript = _require_controller(controller)
	Validation.require_condition(not is_nan(current_height_meters) and not is_inf(current_height_meters), "RunFrameRuntime generated chunk height must be finite.")
	typed_gameplay_nodes.generated_chunk_coordinator.sync_chunks_for_height(
		current_height_meters,
		_collect_attached_hold_paths(typed_controller)
	)

func update_chaser(
	gameplay_nodes: RefCounted,
	run_session: RefCounted,
	chaser_pacing_model: RefCounted,
	pixels_per_meter: float,
	current_height_meters: float,
	delta_seconds: float
) -> void:
	var typed_gameplay_nodes: RunGameplayNodeRefsScript = _require_gameplay_nodes(gameplay_nodes)
	var typed_run_session: RunSessionScript = _require_run_session(run_session)
	var typed_chaser_pacing_model: ChaserPacingModelScript = _require_chaser_pacing_model(chaser_pacing_model)
	Validation.require_condition(pixels_per_meter > 0.0, "RunFrameRuntime pixels-per-meter must be positive for chaser updates.")
	Validation.require_condition(delta_seconds >= 0.0, "RunFrameRuntime chaser update delta cannot be negative.")
	var run_state: int = typed_run_session.get_state()
	if run_state == RunStateScript.Value.READY or run_state == RunStateScript.Value.ENDED:
		return

	typed_chaser_pacing_model.record_height(current_height_meters, delta_seconds)
	var feedback_snapshot: ChaserFeedbackSnapshotScript = typed_chaser_pacing_model.get_current_feedback_snapshot()
	typed_gameplay_nodes.chaser_kill_zone.sync_feedback(
		feedback_snapshot,
		typed_gameplay_nodes.player.get_body_global_position().y,
		pixels_per_meter
	)
	typed_gameplay_nodes.chaser_kill_zone.advance_rise(
		feedback_snapshot.rise_speed_meters_per_second,
		pixels_per_meter,
		delta_seconds
	)

func resolve_bottom_screen_fall_if_needed(
	gameplay_nodes: RefCounted,
	run_loop_coordinator: RefCounted,
	bottom_screen_fall_service: RefCounted,
	controller: RefCounted,
	run_session: RefCounted,
	viewport_height: float,
	bottom_fall_margin_pixels: float
) -> bool:
	var typed_gameplay_nodes: RunGameplayNodeRefsScript = _require_gameplay_nodes(gameplay_nodes)
	var typed_run_loop_coordinator: RunLoopCoordinatorScript = _require_run_loop_coordinator(run_loop_coordinator)
	var typed_bottom_screen_fall_service: BottomScreenFallServiceScript = _require_bottom_screen_fall_service(bottom_screen_fall_service)
	var typed_controller: ClimbPrototypeControllerScript = _require_controller(controller)
	var typed_run_session: RunSessionScript = _require_run_session(run_session)
	var should_resolve_bottom_fall: bool = typed_run_loop_coordinator.should_resolve_bottom_screen_fall(
		typed_run_session.get_state(),
		typed_gameplay_nodes.player.get_body_global_position().y,
		typed_gameplay_nodes.camera.global_position.y,
		viewport_height,
		bottom_fall_margin_pixels,
		typed_gameplay_nodes.camera.zoom.y
	)
	if not should_resolve_bottom_fall:
		return false

	typed_bottom_screen_fall_service.resolve(typed_controller, typed_gameplay_nodes.player, typed_run_session)
	return true

func record_height(run_session: RefCounted, current_height_meters: float) -> void:
	var typed_run_session: RunSessionScript = _require_run_session(run_session)
	Validation.require_condition(current_height_meters >= 0.0, "RunFrameRuntime recorded height cannot be negative.")
	typed_run_session.record_height(current_height_meters)

func _collect_attached_hold_paths(controller: ClimbPrototypeControllerScript) -> Array[NodePath]:
	var hold_paths: Array[NodePath] = []
	var attachment_state: HandAttachmentState = controller.get_attachment_state()
	if attachment_state.is_attached(HandSideScript.Value.LEFT):
		hold_paths.append(attachment_state.get_hold_path(HandSideScript.Value.LEFT))

	if attachment_state.is_attached(HandSideScript.Value.RIGHT):
		hold_paths.append(attachment_state.get_hold_path(HandSideScript.Value.RIGHT))

	return hold_paths

func _require_gameplay_nodes(gameplay_nodes: RefCounted) -> RunGameplayNodeRefsScript:
	Validation.require_condition(gameplay_nodes != null, "RunFrameRuntime requires gameplay nodes.")
	Validation.require_condition(gameplay_nodes is RunGameplayNodeRefsScript, "RunFrameRuntime requires RunGameplayNodeRefs.")
	var typed_gameplay_nodes: RunGameplayNodeRefsScript = gameplay_nodes as RunGameplayNodeRefsScript
	typed_gameplay_nodes.assert_valid()
	return typed_gameplay_nodes

func _require_run_loop_coordinator(run_loop_coordinator: RefCounted) -> RunLoopCoordinatorScript:
	Validation.require_condition(run_loop_coordinator != null, "RunFrameRuntime requires a run loop coordinator.")
	Validation.require_condition(run_loop_coordinator is RunLoopCoordinatorScript, "RunFrameRuntime requires RunLoopCoordinator.")
	return run_loop_coordinator as RunLoopCoordinatorScript

func _require_bottom_screen_fall_service(bottom_screen_fall_service: RefCounted) -> BottomScreenFallServiceScript:
	Validation.require_condition(bottom_screen_fall_service != null, "RunFrameRuntime requires a bottom-screen fall service.")
	Validation.require_condition(bottom_screen_fall_service is BottomScreenFallServiceScript, "RunFrameRuntime requires BottomScreenFallService.")
	return bottom_screen_fall_service as BottomScreenFallServiceScript

func _require_controller(controller: RefCounted) -> ClimbPrototypeControllerScript:
	Validation.require_condition(controller != null, "RunFrameRuntime requires a climb controller.")
	Validation.require_condition(controller is ClimbPrototypeControllerScript, "RunFrameRuntime requires ClimbPrototypeController.")
	return controller as ClimbPrototypeControllerScript

func _require_run_session(run_session: RefCounted) -> RunSessionScript:
	Validation.require_condition(run_session != null, "RunFrameRuntime requires a run session.")
	Validation.require_condition(run_session is RunSessionScript, "RunFrameRuntime requires RunSession.")
	return run_session as RunSessionScript

func _require_chaser_pacing_model(chaser_pacing_model: RefCounted) -> ChaserPacingModelScript:
	Validation.require_condition(chaser_pacing_model != null, "RunFrameRuntime requires a chaser pacing model.")
	Validation.require_condition(chaser_pacing_model is ChaserPacingModelScript, "RunFrameRuntime requires ChaserPacingModel.")
	return chaser_pacing_model as ChaserPacingModelScript
