class_name UnavailableHapticsAdapter
extends "res://src/platform/haptics/haptics_adapter.gd"

func supports_feedback(feedback_type: int) -> bool:
    HapticFeedbackTypeScript.assert_valid(feedback_type)
    return false

func trigger_feedback(feedback_type: int) -> void:
    HapticFeedbackTypeScript.assert_valid(feedback_type)
    Validation.require_condition(false, "UnavailableHapticsAdapter cannot trigger haptic feedback on this runtime.")