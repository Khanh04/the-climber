class_name RouteAnchorGraph
extends RefCounted

const RouteAnchorCandidateScript = preload("res://src/gameplay/generation/route_anchor_candidate.gd")
const RouteLaneScript = preload("res://src/gameplay/generation/route_lane.gd")

var row_count: int
var anchors: Array[RouteAnchorCandidateScript]

func _init(row_count_value: int, anchors_value: Array[RouteAnchorCandidateScript]) -> void:
	row_count = row_count_value
	anchors = _duplicate_anchors(anchors_value)
	assert_valid()

func assert_valid() -> void:
	Validation.require_condition(row_count >= 2, "RouteAnchorGraph requires at least two rows.")
	Validation.require_condition(not anchors.is_empty(), "RouteAnchorGraph requires anchor candidates.")

	for anchor in anchors:
		Validation.require_condition(anchor != null, "RouteAnchorGraph anchors cannot contain null entries.")
		anchor.assert_valid()
		Validation.require_condition(anchor.row_index < row_count, "RouteAnchorGraph anchor row index must be inside the graph.")

		var duplicate_count: int = 0
		for candidate_anchor in anchors:
			if candidate_anchor.row_index == anchor.row_index and candidate_anchor.lane == anchor.lane:
				duplicate_count += 1

		Validation.require_condition(duplicate_count == 1, "RouteAnchorGraph cannot contain duplicate row/lane anchors.")

	for row_index in range(row_count):
		Validation.require_condition(_row_has_anchor(row_index), "RouteAnchorGraph requires at least one anchor in every row.")

func get_anchor_count() -> int:
	return anchors.size()

func get_anchor_for_row_and_lane(row_index: int, lane: int) -> RouteAnchorCandidateScript:
	Validation.require_condition(row_index >= 0 and row_index < row_count, "RouteAnchorGraph anchor lookup row is out of bounds.")
	RouteLaneScript.assert_valid(lane)

	for anchor in anchors:
		if anchor.row_index == row_index and anchor.lane == lane:
			return anchor

	return null

func has_anchor_for_row_and_lane(row_index: int, lane: int) -> bool:
	return get_anchor_for_row_and_lane(row_index, lane) != null

func get_anchors_for_row(row_index: int) -> Array[RouteAnchorCandidateScript]:
	Validation.require_condition(row_index >= 0 and row_index < row_count, "RouteAnchorGraph row anchor lookup row is out of bounds.")
	var row_anchors: Array[RouteAnchorCandidateScript] = []
	for anchor in anchors:
		if anchor.row_index == row_index:
			row_anchors.append(anchor)
	return row_anchors

func _row_has_anchor(row_index: int) -> bool:
	for anchor in anchors:
		if anchor.row_index == row_index:
			return true
	return false

static func _duplicate_anchors(source: Array[RouteAnchorCandidateScript]) -> Array[RouteAnchorCandidateScript]:
	var duplicated_anchors: Array[RouteAnchorCandidateScript] = []
	for anchor in source:
		duplicated_anchors.append(anchor)
	return duplicated_anchors
