class_name GodotHapticsAdapter
extends "res://src/platform/haptics/haptics_adapter.gd"

func supports_feedback(feedback_type: int) -> bool:
	HapticFeedbackTypeScript.assert_valid(feedback_type)
	return true

func trigger_feedback(feedback_type: int) -> void:
	HapticFeedbackTypeScript.assert_valid(feedback_type)
	Input.vibrate_handheld(_duration_for_feedback_type(feedback_type), _amplitude_for_feedback_type(feedback_type))

func _duration_for_feedback_type(feedback_type: int) -> int:
	HapticFeedbackTypeScript.assert_valid(feedback_type)
	match feedback_type:
		HapticFeedbackTypeScript.Value.LIGHT_IMPACT:
			return 18
		HapticFeedbackTypeScript.Value.MEDIUM_IMPACT:
			return 34
		HapticFeedbackTypeScript.Value.HEAVY_IMPACT:
			return 52
		HapticFeedbackTypeScript.Value.SUCCESS:
			return 42
		HapticFeedbackTypeScript.Value.WARNING:
			return 58
		HapticFeedbackTypeScript.Value.ERROR:
			return 72
		_:
			Validation.require_condition(false, "GodotHapticsAdapter requires a supported feedback type.")
			return 0

func _amplitude_for_feedback_type(feedback_type: int) -> float:
	HapticFeedbackTypeScript.assert_valid(feedback_type)
	match feedback_type:
		HapticFeedbackTypeScript.Value.LIGHT_IMPACT:
			return 0.25
		HapticFeedbackTypeScript.Value.MEDIUM_IMPACT:
			return 0.45
		HapticFeedbackTypeScript.Value.HEAVY_IMPACT:
			return 0.70
		HapticFeedbackTypeScript.Value.SUCCESS:
			return 0.50
		HapticFeedbackTypeScript.Value.WARNING:
			return 0.62
		HapticFeedbackTypeScript.Value.ERROR:
			return 0.85
		_:
			Validation.require_condition(false, "GodotHapticsAdapter requires a supported feedback type.")
			return 0.0
