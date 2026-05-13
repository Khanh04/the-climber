class_name ChaserFeedbackSnapshot
extends RefCounted

const ChaserPacingModelScript = preload("res://src/gameplay/chaser/chaser_pacing_model.gd")

var pace_state: int
var recent_vertical_progress_meters: float
var rise_speed_meters_per_second: float
var speed_intensity_ratio: float

func _init(
	pace_state_value: int,
	recent_vertical_progress_meters_value: float,
	rise_speed_meters_per_second_value: float,
	speed_intensity_ratio_value: float
) -> void:
	pace_state = pace_state_value
	recent_vertical_progress_meters = recent_vertical_progress_meters_value
	rise_speed_meters_per_second = rise_speed_meters_per_second_value
	speed_intensity_ratio = speed_intensity_ratio_value

func assert_valid() -> void:
	Validation.require_condition(
		pace_state == ChaserPacingModelScript.PaceState.CAMPING \
			or pace_state == ChaserPacingModelScript.PaceState.NEUTRAL \
			or pace_state == ChaserPacingModelScript.PaceState.RAPID_CLIMB,
		"ChaserFeedbackSnapshot requires a supported pace state."
	)
	Validation.require_condition(recent_vertical_progress_meters >= 0.0, "ChaserFeedbackSnapshot progress cannot be negative.")
	Validation.require_condition(rise_speed_meters_per_second >= 0.0, "ChaserFeedbackSnapshot rise speed cannot be negative.")
	Validation.require_condition(speed_intensity_ratio >= 0.0 and speed_intensity_ratio <= 1.0, "ChaserFeedbackSnapshot speed intensity ratio must be between 0.0 and 1.0.")