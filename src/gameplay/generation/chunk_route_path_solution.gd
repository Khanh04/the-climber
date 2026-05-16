class_name ChunkRoutePathSolution
extends RefCounted

const RoutePlannedPathScript = preload("res://src/gameplay/generation/route_planned_path.gd")

var is_valid: bool
var failure_reason: String
var safe_path: RoutePlannedPathScript
var optional_path: RoutePlannedPathScript
var branch_separation_rows: int
var optional_outer_lane_rows: int

func _init(
	is_valid_value: bool,
	failure_reason_value: String,
	safe_path_value: RoutePlannedPathScript,
	optional_path_value: RoutePlannedPathScript,
	branch_separation_rows_value: int,
	optional_outer_lane_rows_value: int
) -> void:
	is_valid = is_valid_value
	failure_reason = failure_reason_value
	safe_path = safe_path_value
	optional_path = optional_path_value
	branch_separation_rows = branch_separation_rows_value
	optional_outer_lane_rows = optional_outer_lane_rows_value
	assert_valid()

func assert_valid() -> void:
	Validation.require_condition(branch_separation_rows >= 0, "ChunkRoutePathSolution branch separation rows cannot be negative.")
	Validation.require_condition(optional_outer_lane_rows >= 0, "ChunkRoutePathSolution optional outer lane rows cannot be negative.")

	if is_valid:
		Validation.require_condition(failure_reason == "", "ChunkRoutePathSolution cannot include a failure reason when valid.")
		Validation.require_condition(safe_path != null, "ChunkRoutePathSolution requires a safe path when valid.")
		safe_path.assert_valid()
		if optional_path != null:
			optional_path.assert_valid()
		return

	Validation.require_condition(failure_reason != "", "ChunkRoutePathSolution requires a failure reason when invalid.")
	if safe_path != null:
		safe_path.assert_valid()
	if optional_path != null:
		optional_path.assert_valid()
