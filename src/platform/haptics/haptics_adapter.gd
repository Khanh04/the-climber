class_name HapticsAdapter
extends RefCounted

const HapticFeedbackTypeScript = preload("res://src/platform/haptics/haptic_feedback_type.gd")

func supports_feedback(feedback_type: int) -> bool:
    HapticFeedbackTypeScript.assert_valid(feedback_type)
    Validation.require_condition(false, "HapticsAdapter.supports_feedback must be implemented.")
    return false

func trigger_feedback(feedback_type: int) -> void:
    HapticFeedbackTypeScript.assert_valid(feedback_type)
    Validation.require_condition(false, "HapticsAdapter.trigger_feedback must be implemented.")