class_name TutorialRunController
extends RefCounted

const TutorialRunObservationScript = preload("res://src/gameplay/run/tutorial_run_observation.gd")
const TutorialRunProgressScript = preload("res://src/gameplay/run/tutorial_run_progress.gd")

var _progress: TutorialRunProgressScript = TutorialRunProgressScript.new()

func observe_observation(observation: RefCounted) -> void:
	Validation.require_condition(observation != null, "TutorialRunController requires a tutorial observation.")
	Validation.require_condition(observation is TutorialRunObservationScript, "TutorialRunController requires a TutorialRunObservation implementation.")
	_progress.observe_observation(observation as TutorialRunObservationScript)

func get_current_prompt_text() -> String:
	return _progress.get_current_prompt_text()

func get_current_step() -> int:
	return _progress.get_current_step()

func is_complete() -> bool:
	return _progress.is_complete()