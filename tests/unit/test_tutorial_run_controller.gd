extends GutTest

const TutorialRunControllerScript = preload("res://src/gameplay/run/tutorial_run_controller.gd")
const TutorialRunObservationScript = preload("res://src/gameplay/run/tutorial_run_observation.gd")
const TutorialRunProgressScript = preload("res://src/gameplay/run/tutorial_run_progress.gd")

func test_tutorial_run_controller_starts_with_first_prompt() -> void:
	var controller: TutorialRunControllerScript = TutorialRunControllerScript.new()

	assert_eq(controller.get_current_step(), TutorialRunProgressScript.Step.LEFT_GRIP)
	assert_eq(controller.get_current_prompt_text(), "Hold left side to grip with your left hand")
	assert_false(controller.is_complete())

func test_tutorial_run_controller_hides_prompt_when_complete() -> void:
	var controller: TutorialRunControllerScript = TutorialRunControllerScript.new()

	controller.observe_observation(TutorialRunObservationScript.new(false, false, true, false, 1, Vector2.ZERO))
	controller.observe_observation(TutorialRunObservationScript.new(true, false, true, false, 1, Vector2.RIGHT))
	controller.observe_observation(TutorialRunObservationScript.new(true, false, true, true, 2, Vector2.ZERO))
	controller.observe_observation(TutorialRunObservationScript.new(true, true, false, true, 1, Vector2.ZERO))

	assert_true(controller.is_complete())
	assert_eq(controller.get_current_prompt_text(), "")