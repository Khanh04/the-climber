extends GutTest

const RunLaunchModeScript = preload("res://src/core/run_launch_mode.gd")
const RunSceneScript = preload("res://scenes/main/run_scene.gd")
const TutorialSceneScript = preload("res://scenes/main/tutorial_scene.gd")

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