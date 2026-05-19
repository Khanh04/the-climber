extends GutTest

const HandholdTargetScript = preload("res://src/gameplay/player/handhold_target.gd")
const HandholdTypeScript = preload("res://src/gameplay/generation/handhold_type.gd")
const RunRescueRuntimeScript = preload("res://src/gameplay/run/run_rescue_runtime.gd")

func test_find_rewarded_continue_hold_targets_prefers_best_pair_for_camera_and_anchor_spacing() -> void:
	var root: Node2D = Node2D.new()
	add_child_autofree(root)

	var off_center_left: StaticBody2D = _add_handhold(root, "OffCenterLeft", Vector2(96.0, 340.0), 1.1, HandholdTypeScript.Value.NORMAL)
	var off_center_right: StaticBody2D = _add_handhold(root, "OffCenterRight", Vector2(176.0, 340.0), 1.2, HandholdTypeScript.Value.BREAK)
	var ideal_left: StaticBody2D = _add_handhold(root, "IdealLeft", Vector2(160.0, 340.0), 1.3, HandholdTypeScript.Value.BOOST)
	var ideal_right: StaticBody2D = _add_handhold(root, "IdealRight", Vector2(240.0, 340.0), 1.4, HandholdTypeScript.Value.NORMAL)
	var collapsed_center: StaticBody2D = _add_handhold(root, "CollapsedCenter", Vector2(208.0, 340.0), 2.0, HandholdTypeScript.Value.NORMAL)
	var collapsed_right: StaticBody2D = _add_handhold(root, "CollapsedRight", Vector2(232.0, 340.0), 2.1, HandholdTypeScript.Value.NORMAL)
	var runtime: RunRescueRuntimeScript = RunRescueRuntimeScript.new()

	var targets: Array[HandholdTargetScript] = runtime.find_rewarded_continue_hold_targets(
		[
			off_center_left,
			off_center_right,
			ideal_left,
			ideal_right,
			collapsed_center,
			collapsed_right,
		],
		Vector2(200.0, 300.0),
		160.0,
		120.0,
		80.0,
		Callable(self, "_require_handhold_drain_multiplier"),
		Callable(self, "_require_handhold_type")
	)

	assert_eq(targets.size(), 2)
	assert_eq(targets[0].hold_id, &"IdealLeft")
	assert_eq(targets[1].hold_id, &"IdealRight")
	assert_eq(targets[0].hold_path, ideal_left.get_path())
	assert_eq(targets[1].hold_path, ideal_right.get_path())
	assert_eq(targets[0].stamina_drain_multiplier, 1.3)
	assert_eq(targets[1].stamina_drain_multiplier, 1.4)
	assert_eq(targets[0].handhold_type, HandholdTypeScript.Value.BOOST)
	assert_eq(targets[1].handhold_type, HandholdTypeScript.Value.NORMAL)

func test_calculate_rewarded_continue_body_position_uses_average_hold_position_and_hang_offset() -> void:
	var runtime: RunRescueRuntimeScript = RunRescueRuntimeScript.new()
	var left_target: HandholdTargetScript = HandholdTargetScript.new(
		&"LeftHold",
		Vector2(140.0, 320.0),
		NodePath("/root/TestRoot/LeftHold"),
		1.0,
		HandholdTypeScript.Value.NORMAL
	)
	var right_target: HandholdTargetScript = HandholdTargetScript.new(
		&"RightHold",
		Vector2(260.0, 360.0),
		NodePath("/root/TestRoot/RightHold"),
		1.0,
		HandholdTypeScript.Value.NORMAL
	)

	var rescue_body_position: Vector2 = runtime.calculate_rewarded_continue_body_position(
		left_target,
		right_target,
		96.0
	)

	assert_eq(rescue_body_position, Vector2(200.0, 436.0))

func _add_handhold(
	parent: Node,
	handhold_name: String,
	global_position_value: Vector2,
	stamina_drain_multiplier: float,
	handhold_type: int
) -> StaticBody2D:
	var handhold: StaticBody2D = StaticBody2D.new()
	handhold.name = handhold_name
	handhold.global_position = global_position_value
	handhold.set_meta(&"stamina_drain_multiplier", stamina_drain_multiplier)
	handhold.set_meta(&"handhold_type", handhold_type)
	parent.add_child(handhold)
	return handhold

func _require_handhold_drain_multiplier(handhold: StaticBody2D) -> float:
	var drain_multiplier: Variant = handhold.get_meta(&"stamina_drain_multiplier")
	assert_true(drain_multiplier is float)
	return drain_multiplier

func _require_handhold_type(handhold: StaticBody2D) -> int:
	var handhold_type: Variant = handhold.get_meta(&"handhold_type")
	assert_true(handhold_type is int)
	return handhold_type