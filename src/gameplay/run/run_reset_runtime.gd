class_name RunResetRuntime
extends RefCounted

const ChaserPacingModelScript = preload("res://src/gameplay/chaser/chaser_pacing_model.gd")
const ClimbPrototypeControllerScript = preload("res://src/gameplay/player/climb_prototype_controller.gd")
const RunGameplayNodeRefsScript = preload("res://src/gameplay/run/run_gameplay_node_refs.gd")
const RunSessionScript = preload("res://src/gameplay/run/run_session.gd")

func create_started_run_session() -> RunSessionScript:
	var run_session: RunSessionScript = RunSessionScript.new()
	run_session.start_run()
	return run_session

func reset_gameplay_state(
	gameplay_nodes: RefCounted,
	controller: RefCounted,
	chaser_pacing_model: RefCounted,
	uses_generated_chunks: bool,
	camera_player_lower_screen_offset_pixels: float
) -> void:
	var typed_gameplay_nodes: RunGameplayNodeRefsScript = _require_gameplay_nodes(gameplay_nodes)
	var typed_controller: ClimbPrototypeControllerScript = _require_controller(controller)
	Validation.require_condition(
		camera_player_lower_screen_offset_pixels > 0.0,
		"RunResetRuntime camera offset must be positive."
	)

	typed_controller.reset()
	if chaser_pacing_model != null:
		_require_chaser_pacing_model(chaser_pacing_model).reset()
	if uses_generated_chunks:
		typed_gameplay_nodes.generated_chunk_coordinator.reset_chunks()
	typed_gameplay_nodes.player.reset_physics(typed_gameplay_nodes.reset_anchor.global_position)
	typed_gameplay_nodes.camera.global_position = Vector2(
		typed_gameplay_nodes.reset_anchor.global_position.x,
		typed_gameplay_nodes.reset_anchor.global_position.y - camera_player_lower_screen_offset_pixels
	)

func reset_chaser_to_player_position(
	gameplay_nodes: RefCounted,
	pixels_per_meter: float,
	viewport_width: float
) -> void:
	var typed_gameplay_nodes: RunGameplayNodeRefsScript = _require_gameplay_nodes(gameplay_nodes)
	Validation.require_condition(pixels_per_meter > 0.0, "RunResetRuntime pixels-per-meter must be positive.")
	Validation.require_condition(viewport_width > 0.0, "RunResetRuntime viewport width must be positive.")
	typed_gameplay_nodes.chaser_kill_zone.reset_to_player_position(
		typed_gameplay_nodes.player.get_body_global_position().y,
		pixels_per_meter,
		typed_gameplay_nodes.camera.global_position.x,
		viewport_width / typed_gameplay_nodes.camera.zoom.x
	)

func _require_gameplay_nodes(gameplay_nodes: RefCounted) -> RunGameplayNodeRefsScript:
	Validation.require_condition(gameplay_nodes != null, "RunResetRuntime requires gameplay nodes.")
	Validation.require_condition(gameplay_nodes is RunGameplayNodeRefsScript, "RunResetRuntime requires RunGameplayNodeRefs.")
	var typed_gameplay_nodes: RunGameplayNodeRefsScript = gameplay_nodes as RunGameplayNodeRefsScript
	typed_gameplay_nodes.assert_valid()
	return typed_gameplay_nodes

func _require_controller(controller: RefCounted) -> ClimbPrototypeControllerScript:
	Validation.require_condition(controller != null, "RunResetRuntime requires a climb controller.")
	Validation.require_condition(controller is ClimbPrototypeControllerScript, "RunResetRuntime requires ClimbPrototypeController.")
	return controller as ClimbPrototypeControllerScript

func _require_chaser_pacing_model(chaser_pacing_model: RefCounted) -> ChaserPacingModelScript:
	Validation.require_condition(chaser_pacing_model is ChaserPacingModelScript, "RunResetRuntime requires ChaserPacingModel.")
	return chaser_pacing_model as ChaserPacingModelScript
