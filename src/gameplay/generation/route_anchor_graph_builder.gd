class_name RouteAnchorGraphBuilder
extends RefCounted

const ChunkRoutePlanScript = preload("res://src/gameplay/generation/chunk_route_plan.gd")
const RouteAnchorCandidateScript = preload("res://src/gameplay/generation/route_anchor_candidate.gd")
const RouteAnchorGraphScript = preload("res://src/gameplay/generation/route_anchor_graph.gd")
const RouteLaneScript = preload("res://src/gameplay/generation/route_lane.gd")

var chunk_width_meters: float
var row_step_height_meters: float
var first_row_height_meters: float

func _init(
	chunk_width_meters_value: float,
	row_step_height_meters_value: float,
	first_row_height_meters_value: float = -1.0
) -> void:
	chunk_width_meters = chunk_width_meters_value
	row_step_height_meters = row_step_height_meters_value
	first_row_height_meters = first_row_height_meters_value
	if first_row_height_meters < 0.0:
		first_row_height_meters = row_step_height_meters
	assert_valid()

func assert_valid() -> void:
	Validation.require_condition(chunk_width_meters > 0.0, "RouteAnchorGraphBuilder chunk width must be positive.")
	Validation.require_condition(row_step_height_meters > 0.0, "RouteAnchorGraphBuilder row step height must be positive.")
	Validation.require_condition(first_row_height_meters > 0.0, "RouteAnchorGraphBuilder first row height must be positive.")

func build_graph(plan: ChunkRoutePlanScript) -> RouteAnchorGraphScript:
	Validation.require_condition(plan != null, "RouteAnchorGraphBuilder requires a route plan.")
	plan.assert_valid()
	assert_valid()

	var anchors: Array[RouteAnchorCandidateScript] = []
	for row_index in range(plan.get_row_count()):
		var row_role: int = plan.row_roles[row_index]
		for lane in RouteLaneScript.get_all_values():
			anchors.append(RouteAnchorCandidateScript.new(
				_build_anchor_id(plan.chunk_index, row_index, lane),
				row_index,
				lane,
				_build_local_position(row_index, lane),
				row_role
			))

	return RouteAnchorGraphScript.new(plan.get_row_count(), anchors)

func _build_anchor_id(chunk_index: int, row_index: int, lane: int) -> StringName:
	return StringName("chunk_%02d_row_%02d_%s" % [
		chunk_index,
		row_index,
		RouteLaneScript.to_label(lane).to_lower(),
	])

func _build_local_position(row_index: int, lane: int) -> Vector2:
	var half_width_meters: float = chunk_width_meters * 0.5
	var lane_offset: float = float(RouteLaneScript.to_offset(lane)) * 0.5
	var row_height_meters: float = first_row_height_meters + (row_step_height_meters * float(row_index))
	return Vector2(half_width_meters * lane_offset, -row_height_meters)
