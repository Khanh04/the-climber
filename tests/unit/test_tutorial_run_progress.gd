extends GutTest

const TutorialRunObservationScript = preload("res://src/gameplay/run/tutorial_run_observation.gd")
const TutorialRunProgressScript = preload("res://src/gameplay/run/tutorial_run_progress.gd")

func test_tutorial_progress_advances_through_expected_milestones() -> void:
	var progress: TutorialRunProgressScript = TutorialRunProgressScript.new()

	assert_eq(progress.get_current_prompt_text(), "Hold left side to grip with your left hand")

	progress.observe_observation(TutorialRunObservationScript.new(false, false, true, false, 1, Vector2.ZERO))

	assert_eq(progress.get_current_prompt_text(), "Drag while holding to move your free hand")

	progress.observe_observation(TutorialRunObservationScript.new(true, false, true, false, 1, Vector2.RIGHT))

	assert_eq(progress.get_current_prompt_text(), "Hold right side to grip with your right hand")

	progress.observe_observation(TutorialRunObservationScript.new(true, false, true, true, 2, Vector2.ZERO))

	assert_eq(progress.get_current_prompt_text(), "Reach an upper hold to finish the tutorial")

	progress.observe_observation(TutorialRunObservationScript.new(true, true, true, true, 2, Vector2.ZERO, true))

	assert_true(progress.is_complete())
	assert_eq(progress.get_current_prompt_text(), "")

func test_tutorial_progress_ignores_drag_until_exactly_one_hand_is_attached() -> void:
	var progress: TutorialRunProgressScript = TutorialRunProgressScript.new()

	progress.observe_observation(TutorialRunObservationScript.new(false, false, true, false, 1, Vector2.ZERO))
	progress.observe_observation(TutorialRunObservationScript.new(true, false, true, true, 2, Vector2.RIGHT))

	assert_eq(progress.get_current_step(), TutorialRunProgressScript.Step.DRAG)
	assert_eq(progress.get_current_prompt_text(), "Drag while holding to move your free hand")