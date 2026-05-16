class_name RoutePlannedPath
extends RefCounted

const RouteBranchSideScript = preload("res://src/gameplay/generation/route_branch_side.gd")
const RouteLaneScript = preload("res://src/gameplay/generation/route_lane.gd")

var path_id: StringName
var anchor_ids: PackedStringArray
var row_indices: PackedInt32Array
var lanes: Array[int]
var total_lateral_lane_steps: int

func _init(
	path_id_value: StringName,
	anchor_ids_value: PackedStringArray,
	row_indices_value: PackedInt32Array,
	lanes_value: Array[int]
) -> void:
	path_id = path_id_value
	anchor_ids = PackedStringArray(anchor_ids_value)
	row_indices = PackedInt32Array(row_indices_value)
	lanes = _duplicate_int_array(lanes_value)
	total_lateral_lane_steps = _calculate_total_lateral_lane_steps()
	assert_valid()

func assert_valid() -> void:
	Validation.require_condition(not String(path_id).is_empty(), "RoutePlannedPath requires a path id.")
	Validation.require_condition(anchor_ids.size() > 0, "RoutePlannedPath requires at least one anchor id.")
	Validation.require_condition(anchor_ids.size() == row_indices.size(), "RoutePlannedPath anchor ids and row indices must align.")
	Validation.require_condition(anchor_ids.size() == lanes.size(), "RoutePlannedPath anchor ids and lanes must align.")
	Validation.require_condition(total_lateral_lane_steps >= 0, "RoutePlannedPath lateral lane steps cannot be negative.")

	var previous_row_index: int = -1
	for path_index in range(anchor_ids.size()):
		Validation.require_condition(anchor_ids[path_index] != "", "RoutePlannedPath anchor ids cannot contain empty entries.")
		Validation.require_condition(row_indices[path_index] >= 0, "RoutePlannedPath row indices cannot be negative.")
		Validation.require_condition(row_indices[path_index] > previous_row_index, "RoutePlannedPath rows must be strictly increasing.")
		RouteLaneScript.assert_valid(lanes[path_index])
		previous_row_index = row_indices[path_index]

func get_row_count() -> int:
	return row_indices.size()

func get_lane_at_row(row_index: int) -> int:
	Validation.require_condition(row_index >= 0, "RoutePlannedPath lane lookup row cannot be negative.")
	for path_index in range(row_indices.size()):
		if row_indices[path_index] == row_index:
			return lanes[path_index]

	Validation.require_condition(false, "RoutePlannedPath does not contain the requested row.")
	return RouteLaneScript.Value.CENTER

func get_anchor_id_at_row(row_index: int) -> String:
	Validation.require_condition(row_index >= 0, "RoutePlannedPath anchor lookup row cannot be negative.")
	for path_index in range(row_indices.size()):
		if row_indices[path_index] == row_index:
			return anchor_ids[path_index]

	Validation.require_condition(false, "RoutePlannedPath does not contain the requested row.")
	return ""

func count_separated_rows(other_path: RoutePlannedPath, first_row_index: int, last_row_index: int) -> int:
	Validation.require_condition(other_path != null, "RoutePlannedPath separation requires another path.")
	Validation.require_condition(first_row_index >= 0, "RoutePlannedPath separation first row cannot be negative.")
	Validation.require_condition(last_row_index >= first_row_index, "RoutePlannedPath separation last row must be at or after the first row.")

	var separated_rows: int = 0
	for row_index in range(first_row_index, last_row_index + 1):
		if get_lane_at_row(row_index) != other_path.get_lane_at_row(row_index):
			separated_rows += 1
	return separated_rows

func count_outer_lane_rows_for_side(branch_side: int, first_row_index: int, last_row_index: int) -> int:
	RouteBranchSideScript.assert_valid(branch_side)
	Validation.require_condition(branch_side != RouteBranchSideScript.Value.NONE, "RoutePlannedPath outer lane count requires a branch side.")
	Validation.require_condition(first_row_index >= 0, "RoutePlannedPath outer lane first row cannot be negative.")
	Validation.require_condition(last_row_index >= first_row_index, "RoutePlannedPath outer lane last row must be at or after the first row.")

	var outer_lane_rows: int = 0
	for row_index in range(first_row_index, last_row_index + 1):
		var lane: int = get_lane_at_row(row_index)
		if RouteLaneScript.is_outer(lane) and RouteLaneScript.to_branch_side(lane) == branch_side:
			outer_lane_rows += 1
	return outer_lane_rows

func _calculate_total_lateral_lane_steps() -> int:
	var lateral_steps: int = 0
	for path_index in range(1, lanes.size()):
		var previous_lane_offset: int = RouteLaneScript.to_offset(lanes[path_index - 1])
		var lane_offset: int = RouteLaneScript.to_offset(lanes[path_index])
		lateral_steps += absi(lane_offset - previous_lane_offset)
	return lateral_steps

static func _duplicate_int_array(source: Array[int]) -> Array[int]:
	var duplicated_values: Array[int] = []
	for value in source:
		duplicated_values.append(value)
	return duplicated_values
