class_name TutorialRunProgress
extends RefCounted

const TutorialRunObservationScript = preload("res://src/gameplay/run/tutorial_run_observation.gd")

enum Step {
	LEFT_GRIP,
	DRAG,
	RIGHT_GRIP,
	RELEASE,
	COMPLETE
}

var _current_step: int = Step.LEFT_GRIP

func get_current_step() -> int:
	return _current_step

func is_complete() -> bool:
	return _current_step == Step.COMPLETE

func get_current_prompt_text() -> String:
	match _current_step:
		Step.LEFT_GRIP:
			return "Hold left side to grip with your left hand"
		Step.DRAG:
			return "Drag while holding to move your free hand"
		Step.RIGHT_GRIP:
			return "Hold right side to grip with your right hand"
		Step.RELEASE:
			return "Release a hand to let go"
		Step.COMPLETE:
			return ""
		_:
			Validation.require_condition(false, "TutorialRunProgress requires a supported step.")
			return ""

func observe_observation(observation: RefCounted) -> void:
	Validation.require_condition(observation != null, "TutorialRunProgress requires an observation.")
	Validation.require_condition(observation is TutorialRunObservationScript, "TutorialRunProgress requires a TutorialRunObservation implementation.")
	var typed_observation: TutorialRunObservationScript = observation as TutorialRunObservationScript
	typed_observation.assert_valid()

	match _current_step:
		Step.LEFT_GRIP:
			if not typed_observation.left_was_attached and typed_observation.left_is_attached:
				_current_step = Step.DRAG
		Step.DRAG:
			if typed_observation.attached_hand_count == 1 and typed_observation.control_force != Vector2.ZERO:
				_current_step = Step.RIGHT_GRIP
		Step.RIGHT_GRIP:
			if not typed_observation.right_was_attached and typed_observation.right_is_attached:
				_current_step = Step.RELEASE
		Step.RELEASE:
			var left_released_now: bool = typed_observation.left_was_attached and not typed_observation.left_is_attached
			var right_released_now: bool = typed_observation.right_was_attached and not typed_observation.right_is_attached
			if left_released_now or right_released_now:
				_current_step = Step.COMPLETE
		Step.COMPLETE:
			pass
		_:
			Validation.require_condition(false, "TutorialRunProgress requires a supported step.")