class_name TutorialScene
extends Node2D

const RunLaunchModeScript = preload("res://src/core/run_launch_mode.gd")
const TutorialRunControllerScript = preload("res://src/gameplay/run/tutorial_run_controller.gd")
const RunSceneScript = preload("res://scenes/main/run_scene.gd")
const RunScenePackedScene = preload("res://scenes/main/run_scene.tscn")
const TutorialOverlayScript = preload("res://scenes/ui/tutorial_overlay.gd")
const TutorialOverlayPresenterScript = preload("res://src/ui/tutorial_overlay_presenter.gd")
const MAIN_MENU_SCENE_PATH: String = "res://scenes/main/main_menu_scene.tscn"

@onready var _tutorial_overlay: TutorialOverlayScript = %TutorialOverlay

var _run_scene: RunSceneScript = null
var _tutorial_overlay_presenter: TutorialOverlayPresenterScript = TutorialOverlayPresenterScript.new()
var _tutorial_run_controller: TutorialRunControllerScript = TutorialRunControllerScript.new()
var _scene_change_callable: Callable = Callable()

func _ready() -> void:
	_validate_required_nodes()
	_instantiate_run_scene()
	_refresh_overlay()

func get_run_scene_for_test() -> RunSceneScript:
	return _run_scene

func get_tutorial_overlay_for_test() -> TutorialOverlayScript:
	return _tutorial_overlay

func get_tutorial_prompt_text_for_test() -> String:
	return _tutorial_run_controller.get_current_prompt_text()

func set_scene_change_callable_for_test(scene_change_callable: Callable) -> void:
	Validation.require_condition(scene_change_callable.is_valid(), "TutorialScene test scene-change callable must be valid.")
	_scene_change_callable = scene_change_callable

func _instantiate_run_scene() -> void:
	Validation.require_condition(_run_scene == null, "TutorialScene cannot instantiate RunScene more than once.")
	var run_scene_node: Node = RunScenePackedScene.instantiate()
	Validation.require_condition(run_scene_node != null, "TutorialScene RunScene must instantiate a node.")
	Validation.require_condition(run_scene_node is RunSceneScript, "TutorialScene must instantiate RunScene.")
	_apply_tutorial_launch_mode_override(run_scene_node)
	_run_scene = run_scene_node as RunSceneScript
	var _tutorial_observation_connect_result: int = _run_scene.connect(&"tutorial_observation_recorded", Callable(self, "_on_run_scene_tutorial_observation_recorded"))
	add_child(_run_scene)

func _apply_tutorial_launch_mode_override(run_scene_node: Node) -> void:
	Validation.require_condition(
		run_scene_node.has_method(&"set_launch_mode_override"),
		"TutorialScene requires RunScene launch mode override support."
	)
	var _set_launch_mode_override_result: Variant = run_scene_node.call(&"set_launch_mode_override", RunLaunchModeScript.Value.TUTORIAL)

func _refresh_overlay() -> void:
	Validation.require_condition(_tutorial_overlay != null, "TutorialScene requires TutorialOverlay before refreshing prompts.")
	var prompt_text: String = _tutorial_run_controller.get_current_prompt_text()
	_tutorial_overlay.apply_state(_tutorial_overlay_presenter.build_state(prompt_text))

func _on_run_scene_tutorial_observation_recorded(observation: RefCounted) -> void:
	_tutorial_run_controller.observe_observation(observation)
	_refresh_overlay()
	if _tutorial_run_controller.is_complete():
		_return_to_main_menu()

func _validate_required_nodes() -> void:
	Validation.require_condition(_tutorial_overlay != null, "TutorialScene requires TutorialOverlay.")

func _return_to_main_menu() -> void:
	if _scene_change_callable.is_valid():
		_scene_change_callable.call(MAIN_MENU_SCENE_PATH)
		return

	var change_result: Error = get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)
	Validation.require_condition(change_result == OK, "TutorialScene could not load MainMenuScene.")