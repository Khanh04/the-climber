extends GutTest

const RunLaunchModeScript = preload("res://src/core/run_launch_mode.gd")
const TutorialRunObservationScript = preload("res://src/gameplay/run/tutorial_run_observation.gd")
const RunSceneScript = preload("res://scenes/main/run_scene.gd")
const TutorialSceneScript = preload("res://scenes/main/tutorial_scene.gd")

var _requested_scene_path: String = ""

func test_tutorial_scene_instantiates_run_scene_in_tutorial_mode() -> void:
	var scene: PackedScene = load("res://scenes/main/tutorial_scene.tscn")
	var tutorial_scene_node: Node = scene.instantiate()

	assert_not_null(tutorial_scene_node)
	assert_true(tutorial_scene_node is TutorialSceneScript)
	var tutorial_scene: TutorialSceneScript = tutorial_scene_node as TutorialSceneScript
	assert_not_null(tutorial_scene)
	add_child_autofree(tutorial_scene)
	await get_tree().process_frame

	var run_scene: RunSceneScript = tutorial_scene.get_run_scene_for_test()

	assert_not_null(run_scene)
	assert_not_null(tutorial_scene.get_node_or_null("RunScene"))
	assert_not_null(tutorial_scene.get_node_or_null("TutorialOverlay"))
	assert_eq(run_scene.get_launch_mode_for_test(), RunLaunchModeScript.Value.TUTORIAL)
	assert_eq(tutorial_scene.get_tutorial_prompt_text_for_test(), "Hold left side to grip with your left hand")
	var tutorial_overlay: Control = tutorial_scene.get_tutorial_overlay_for_test()
	assert_not_null(tutorial_overlay)
	var overlay_prompt_label: Label = tutorial_scene.get_node("TutorialOverlay/Panel/PromptLabel") as Label
	assert_not_null(overlay_prompt_label)
	assert_true(tutorial_overlay.visible)
	assert_eq(overlay_prompt_label.text, "Hold left side to grip with your left hand")

func test_tutorial_scene_returns_to_main_menu_when_tutorial_completes() -> void:
	var scene: PackedScene = load("res://scenes/main/tutorial_scene.tscn")
	var tutorial_scene_node: Node = scene.instantiate()

	assert_not_null(tutorial_scene_node)
	assert_true(tutorial_scene_node is TutorialSceneScript)
	var tutorial_scene: TutorialSceneScript = tutorial_scene_node as TutorialSceneScript
	assert_not_null(tutorial_scene)
	_requested_scene_path = ""
	tutorial_scene.set_scene_change_callable_for_test(Callable(self, "_record_requested_scene_path"))
	add_child_autofree(tutorial_scene)
	await get_tree().process_frame

	var run_scene: RunSceneScript = tutorial_scene.get_run_scene_for_test()

	assert_not_null(run_scene)
	var _left_grip_emit_result: int = run_scene.emit_signal("tutorial_observation_recorded", TutorialRunObservationScript.new(false, false, true, false, 1, Vector2.ZERO))
	var _drag_emit_result: int = run_scene.emit_signal("tutorial_observation_recorded", TutorialRunObservationScript.new(true, false, true, false, 1, Vector2.RIGHT))
	var _right_grip_emit_result: int = run_scene.emit_signal("tutorial_observation_recorded", TutorialRunObservationScript.new(true, false, true, true, 2, Vector2.ZERO))
	var _release_emit_result: int = run_scene.emit_signal("tutorial_observation_recorded", TutorialRunObservationScript.new(true, true, false, true, 1, Vector2.ZERO))

	assert_eq(_requested_scene_path, "res://scenes/main/main_menu_scene.tscn")
	assert_eq(tutorial_scene.get_tutorial_prompt_text_for_test(), "")
	assert_false(tutorial_scene.get_tutorial_overlay_for_test().visible)

func _record_requested_scene_path(scene_path: String) -> void:
	_requested_scene_path = scene_path