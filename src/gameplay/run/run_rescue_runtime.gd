class_name RunRescueRuntime
extends RefCounted

const ClimbPrototypeControllerScript = preload("res://src/gameplay/player/climb_prototype_controller.gd")
const HandAttachmentStateScript = preload("res://src/gameplay/player/hand_attachment_state.gd")
const HandSideScript = preload("res://src/gameplay/player/hand_side.gd")
const HandholdTargetScript = preload("res://src/gameplay/player/handhold_target.gd")
const RewardedContinueRescuePlanScript = preload("res://src/gameplay/run/rewarded_continue_rescue_plan.gd")
const RunGameplayNodeRefsScript = preload("res://src/gameplay/run/run_gameplay_node_refs.gd")

func build_rewarded_continue_rescue_plan(
	handholds: Array[StaticBody2D],
	camera_position: Vector2,
	camera_player_lower_screen_offset_pixels: float,
	grip_hang_offset_pixels: float,
	target_anchor_spacing: float,
	require_handhold_drain_multiplier: Callable,
	require_handhold_type: Callable
) -> RewardedContinueRescuePlanScript:
	var rescue_hold_targets: Array[HandholdTargetScript] = find_rewarded_continue_hold_targets(
		handholds,
		camera_position,
		camera_player_lower_screen_offset_pixels,
		grip_hang_offset_pixels,
		target_anchor_spacing,
		require_handhold_drain_multiplier,
		require_handhold_type
	)
	Validation.require_condition(rescue_hold_targets.size() == 2, "RunRescueRuntime rewarded continue requires exactly two rescue hold targets.")
	var left_hold_target: HandholdTargetScript = rescue_hold_targets[0]
	var right_hold_target: HandholdTargetScript = rescue_hold_targets[1]
	var rescue_body_position: Vector2 = calculate_rewarded_continue_body_position(
		left_hold_target,
		right_hold_target,
		grip_hang_offset_pixels
	)
	var rescue_plan: RewardedContinueRescuePlanScript = RewardedContinueRescuePlanScript.new(
		left_hold_target,
		right_hold_target,
		rescue_body_position
	)
	rescue_plan.assert_valid()
	return rescue_plan

func find_rewarded_continue_hold_targets(
	handholds: Array[StaticBody2D],
	camera_position: Vector2,
	camera_player_lower_screen_offset_pixels: float,
	grip_hang_offset_pixels: float,
	target_anchor_spacing: float,
	require_handhold_drain_multiplier: Callable,
	require_handhold_type: Callable
) -> Array[HandholdTargetScript]:
	Validation.require_condition(handholds.size() >= 2, "RunRescueRuntime rewarded continue requires at least two handholds.")
	Validation.require_condition(camera_player_lower_screen_offset_pixels > 0.0, "RunRescueRuntime camera offset must be positive.")
	Validation.require_condition(grip_hang_offset_pixels > 0.0, "RunRescueRuntime grip hang offset must be positive.")
	Validation.require_condition(target_anchor_spacing > 0.0, "RunRescueRuntime target anchor spacing must be positive.")
	Validation.require_condition(require_handhold_drain_multiplier.is_valid(), "RunRescueRuntime requires a handhold drain multiplier resolver.")
	Validation.require_condition(require_handhold_type.is_valid(), "RunRescueRuntime requires a handhold type resolver.")

	var target_body_y: float = camera_position.y + camera_player_lower_screen_offset_pixels
	var target_hold_average_y: float = target_body_y - grip_hang_offset_pixels
	var target_center_x: float = camera_position.x
	var best_score: float = INF
	var best_left_hold: StaticBody2D = null
	var best_right_hold: StaticBody2D = null

	for first_index in range(handholds.size() - 1):
		for second_index in range(first_index + 1, handholds.size()):
			var first_hold: StaticBody2D = handholds[first_index]
			var second_hold: StaticBody2D = handholds[second_index]
			var ordered_holds: Array[StaticBody2D] = _sort_holds_left_to_right(first_hold, second_hold)
			var left_hold: StaticBody2D = ordered_holds[0]
			var right_hold: StaticBody2D = ordered_holds[1]

			var score: float = _score_rewarded_continue_pair(
				left_hold,
				right_hold,
				target_hold_average_y,
				target_center_x,
				target_anchor_spacing
			)
			if score < best_score:
				best_score = score
				best_left_hold = left_hold
				best_right_hold = right_hold

	Validation.require_condition(best_left_hold != null, "RunRescueRuntime rewarded continue requires a left rescue handhold.")
	Validation.require_condition(best_right_hold != null, "RunRescueRuntime rewarded continue requires a right rescue handhold.")
	return [
		_build_handhold_target(best_left_hold, require_handhold_drain_multiplier, require_handhold_type),
		_build_handhold_target(best_right_hold, require_handhold_drain_multiplier, require_handhold_type),
	]

func calculate_rewarded_continue_body_position(
	left_hold_target: HandholdTargetScript,
	right_hold_target: HandholdTargetScript,
	grip_hang_offset_pixels: float
) -> Vector2:
	left_hold_target.assert_valid()
	right_hold_target.assert_valid()
	Validation.require_condition(grip_hang_offset_pixels > 0.0, "RunRescueRuntime grip hang offset must be positive.")
	var average_hold_position: Vector2 = (left_hold_target.attach_position + right_hold_target.attach_position) * 0.5
	return average_hold_position + Vector2.DOWN * grip_hang_offset_pixels

func restore_rewarded_continue(
	gameplay_nodes: RefCounted,
	controller: RefCounted,
	left_hold_target: HandholdTargetScript,
	right_hold_target: HandholdTargetScript,
	rescue_body_position: Vector2,
	camera_player_lower_screen_offset_pixels: float
) -> HandAttachmentStateScript:
	var typed_gameplay_nodes: RunGameplayNodeRefsScript = _require_gameplay_nodes(gameplay_nodes)
	var typed_controller: ClimbPrototypeControllerScript = _require_controller(controller)
	left_hold_target.assert_valid()
	right_hold_target.assert_valid()
	Validation.require_condition(camera_player_lower_screen_offset_pixels > 0.0, "RunRescueRuntime camera offset must be positive.")

	typed_controller.reset()
	typed_gameplay_nodes.player.reset_physics(rescue_body_position)
	var attachment_state: HandAttachmentStateScript = typed_controller.get_attachment_state()
	attachment_state.attach(HandSideScript.Value.LEFT, left_hold_target.hold_id, left_hold_target.attach_position, left_hold_target.hold_path)
	attachment_state.attach(HandSideScript.Value.RIGHT, right_hold_target.hold_id, right_hold_target.attach_position, right_hold_target.hold_path)
	typed_gameplay_nodes.player.sync_runtime_grip_joints(attachment_state)
	typed_gameplay_nodes.player.sync_runtime_grip_links(attachment_state)
	typed_gameplay_nodes.camera.global_position = Vector2(
		typed_gameplay_nodes.camera.global_position.x,
		rescue_body_position.y - camera_player_lower_screen_offset_pixels
	)
	return attachment_state

func restore_rewarded_continue_from_plan(
	gameplay_nodes: RefCounted,
	controller: RefCounted,
	rescue_plan: RefCounted,
	camera_player_lower_screen_offset_pixels: float
) -> HandAttachmentStateScript:
	Validation.require_condition(rescue_plan != null, "RunRescueRuntime requires a rescue plan.")
	Validation.require_condition(rescue_plan is RewardedContinueRescuePlanScript, "RunRescueRuntime requires RewardedContinueRescuePlan.")
	var typed_rescue_plan: RewardedContinueRescuePlanScript = rescue_plan as RewardedContinueRescuePlanScript
	typed_rescue_plan.assert_valid()
	return restore_rewarded_continue(
		gameplay_nodes,
		controller,
		typed_rescue_plan.left_hold_target,
		typed_rescue_plan.right_hold_target,
		typed_rescue_plan.rescue_body_position,
		camera_player_lower_screen_offset_pixels
	)

func _build_handhold_target(
	handhold: StaticBody2D,
	require_handhold_drain_multiplier: Callable,
	require_handhold_type: Callable
) -> HandholdTargetScript:
	Validation.require_condition(handhold != null, "RunRescueRuntime handhold target requires a handhold node.")
	var stamina_drain_multiplier_variant: Variant = require_handhold_drain_multiplier.call(handhold)
	var handhold_type_variant: Variant = require_handhold_type.call(handhold)
	Validation.require_condition(stamina_drain_multiplier_variant is float, "RunRescueRuntime handhold drain multiplier must be a float.")
	Validation.require_condition(handhold_type_variant is int, "RunRescueRuntime handhold type must be an int.")
	var stamina_drain_multiplier: float = stamina_drain_multiplier_variant
	var handhold_type: int = handhold_type_variant
	return HandholdTargetScript.new(
		handhold.name,
		handhold.global_position,
		handhold.get_path(),
		stamina_drain_multiplier,
		handhold_type
	)

func _sort_holds_left_to_right(first_hold: StaticBody2D, second_hold: StaticBody2D) -> Array[StaticBody2D]:
	Validation.require_condition(first_hold != null, "RunRescueRuntime requires a first handhold to sort.")
	Validation.require_condition(second_hold != null, "RunRescueRuntime requires a second handhold to sort.")
	if first_hold.global_position.x <= second_hold.global_position.x:
		return [first_hold, second_hold]

	return [second_hold, first_hold]

func _score_rewarded_continue_pair(
	left_hold: StaticBody2D,
	right_hold: StaticBody2D,
	target_hold_average_y: float,
	target_center_x: float,
	target_anchor_spacing: float
) -> float:
	Validation.require_condition(left_hold != null, "RunRescueRuntime requires a left handhold to score.")
	Validation.require_condition(right_hold != null, "RunRescueRuntime requires a right handhold to score.")
	var average_position: Vector2 = (left_hold.global_position + right_hold.global_position) * 0.5
	var spacing_x: float = absf(right_hold.global_position.x - left_hold.global_position.x)
	var vertical_target_penalty: float = absf(average_position.y - target_hold_average_y)
	var horizontal_target_penalty: float = absf(average_position.x - target_center_x)
	var spacing_penalty: float = absf(spacing_x - target_anchor_spacing)
	var vertical_alignment_penalty: float = absf(left_hold.global_position.y - right_hold.global_position.y)
	var collapse_penalty: float = 0.0
	if spacing_x < 48.0:
		collapse_penalty = 1000.0

	return vertical_target_penalty \
		+ (horizontal_target_penalty * 0.35) \
		+ (spacing_penalty * 0.5) \
		+ (vertical_alignment_penalty * 0.75) \
		+ collapse_penalty

func _require_gameplay_nodes(gameplay_nodes: RefCounted) -> RunGameplayNodeRefsScript:
	Validation.require_condition(gameplay_nodes != null, "RunRescueRuntime requires gameplay nodes.")
	Validation.require_condition(gameplay_nodes is RunGameplayNodeRefsScript, "RunRescueRuntime requires RunGameplayNodeRefs.")
	var typed_gameplay_nodes: RunGameplayNodeRefsScript = gameplay_nodes as RunGameplayNodeRefsScript
	typed_gameplay_nodes.assert_valid()
	return typed_gameplay_nodes

func _require_controller(controller: RefCounted) -> ClimbPrototypeControllerScript:
	Validation.require_condition(controller != null, "RunRescueRuntime requires a climb controller.")
	Validation.require_condition(controller is ClimbPrototypeControllerScript, "RunRescueRuntime requires ClimbPrototypeController.")
	return controller as ClimbPrototypeControllerScript