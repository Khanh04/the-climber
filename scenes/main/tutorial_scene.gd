class_name TutorialScene
extends Node2D

const RunLaunchIntentScript = preload("res://src/core/run_launch_intent.gd")
const RunLaunchModeScript = preload("res://src/core/run_launch_mode.gd")
const TutorialRunControllerScript = preload("res://src/gameplay/run/tutorial_run_controller.gd")
const RunSceneScript = preload("res://scenes/main/run_scene.gd")
const RunScenePackedScene = preload("res://scenes/main/run_scene.tscn")
const TutorialOverlayScript = preload("res://scenes/ui/tutorial_overlay.gd")
const TutorialOverlayPresenterScript = preload("res://src/ui/tutorial_overlay_presenter.gd")

@onready var _tutorial_overlay: TutorialOverlayScript = %TutorialOverlay

var _run_scene: RunSceneScript = null
var _tutorial_overlay_presenter: TutorialOverlayPresenterScript = TutorialOverlayPresenterScript.new()
var _tutorial_run_controller: TutorialRunControllerScript = TutorialRunControllerScript.new()

func _ready() -> void:
	_validate_required_nodes()
	_stage_tutorial_launch_mode()
	_instantiate_run_scene()
	_refresh_overlay()

func get_run_scene_for_test() -> RunSceneScript:
	return _run_scene

func get_tutorial_overlay_for_test() -> TutorialOverlayScript:
	return _tutorial_overlay

func get_tutorial_prompt_text_for_test() -> String:
	return _tutorial_run_controller.get_current_prompt_text()

func _stage_tutorial_launch_mode() -> void:
	var run_launch_intent: RunLaunchIntentScript = _get_run_launch_intent()
	run_launch_intent.set_next_mode(RunLaunchModeScript.Value.TUTORIAL)

func _instantiate_run_scene() -> void:
	Validation.require_condition(_run_scene == null, "TutorialScene cannot instantiate RunScene more than once.")
	var run_scene_node: Node = RunScenePackedScene.instantiate()
	Validation.require_condition(run_scene_node != null, "TutorialScene RunScene must instantiate a node.")
	Validation.require_condition(run_scene_node is RunSceneScript, "TutorialScene must instantiate RunScene.")
	_run_scene = run_scene_node as RunSceneScript
	var _tutorial_observation_connect_result: int = _run_scene.connect(&"tutorial_observation_recorded", Callable(self, "_on_run_scene_tutorial_observation_recorded"))
	add_child(_run_scene)

func _refresh_overlay() -> void:
	Validation.require_condition(_tutorial_overlay != null, "TutorialScene requires TutorialOverlay before refreshing prompts.")
	var prompt_text: String = _tutorial_run_controller.get_current_prompt_text()
	_tutorial_overlay.apply_state(_tutorial_overlay_presenter.build_state(prompt_text))

func _on_run_scene_tutorial_observation_recorded(observation: RefCounted) -> void:
	_tutorial_run_controller.observe_observation(observation)
	_refresh_overlay()

func _validate_required_nodes() -> void:
	Validation.require_condition(_tutorial_overlay != null, "TutorialScene requires TutorialOverlay.")

func _get_run_launch_intent() -> RunLaunchIntentScript:
	Validation.require_condition(has_node("/root/RunLaunchIntent"), "TutorialScene requires the RunLaunchIntent autoload.")
	var run_launch_intent_node: Node = get_node("/root/RunLaunchIntent")
	Validation.require_condition(run_launch_intent_node is RunLaunchIntentScript, "TutorialScene requires a RunLaunchIntent implementation.")
	return run_launch_intent_node as RunLaunchIntentScript