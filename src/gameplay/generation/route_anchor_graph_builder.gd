class_name RouteAnchorGraphBuilder
extends RefCounted

const ChunkRoutePlanScript = preload("res://src/gameplay/generation/chunk_route_plan.gd")
const RouteAnchorCandidateScript = preload("res://src/gameplay/generation/route_anchor_candidate.gd")
const RouteAnchorGraphScript = preload("res://src/gameplay/generation/route_anchor_graph.gd")
const RouteLaneScript = preload("res://src/gameplay/generation/route_lane.gd")

var chunk_width_meters: float
var row_step_height_meters: float
var first_row_height_meters: float
var horizontal_jitter_meters: float
var vertical_jitter_meters: float
var seed_key: String

func _init(
	chunk_width_meters_value: float,
	row_step_height_meters_value: float,
	first_row_height_meters_value: float = -1.0,
	horizontal_jitter_meters_value: float = 0.0,
	vertical_jitter_meters_value: float = 0.0,
	seed_key_value: String = ""
) -> void:
	chunk_width_meters = chunk_width_meters_value
	row_step_height_meters = row_step_height_meters_value
	first_row_height_meters = first_row_height_meters_value
	horizontal_jitter_meters = horizontal_jitter_meters_value
	vertical_jitter_meters = vertical_jitter_meters_value
	seed_key = seed_key_value
	if first_row_height_meters < 0.0:
		first_row_height_meters = row_step_height_meters
	assert_valid()

func assert_valid() -> void:
	Validation.require_condition(chunk_width_meters > 0.0, "RouteAnchorGraphBuilder chunk width must be positive.")
	Validation.require_condition(row_step_height_meters > 0.0, "RouteAnchorGraphBuilder row step height must be positive.")
	Validation.require_condition(first_row_height_meters > 0.0, "RouteAnchorGraphBuilder first row height must be positive.")
	Validation.require_condition(horizontal_jitter_meters >= 0.0, "RouteAnchorGraphBuilder horizontal jitter cannot be negative.")
	Validation.require_condition(vertical_jitter_meters >= 0.0, "RouteAnchorGraphBuilder vertical jitter cannot be negative.")

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
				_build_local_position(row_index, lane, plan.get_row_count()),
				row_role
			))

	return RouteAnchorGraphScript.new(plan.get_row_count(), anchors)

func _build_anchor_id(chunk_index: int, row_index: int, lane: int) -> StringName:
	return StringName("chunk_%02d_row_%02d_%s" % [
		chunk_index,
		row_index,
		RouteLaneScript.to_label(lane).to_lower(),
	])

func _build_local_position(row_index: int, lane: int, row_count: int) -> Vector2:
	Validation.require_condition(row_count > 0, "RouteAnchorGraphBuilder local positions require a positive row count.")
	var half_width_meters: float = chunk_width_meters * 0.5
	var lane_offset: float = float(RouteLaneScript.to_offset(lane)) * 0.5
	var row_height_meters: float = first_row_height_meters + (row_step_height_meters * float(row_index))
	var base_position: Vector2 = Vector2(half_width_meters * lane_offset, -row_height_meters)
	var jittered_x: float = clampf(
		base_position.x + _build_horizontal_jitter(row_index, lane),
		-half_width_meters,
		half_width_meters
	)
	return Vector2(jittered_x, base_position.y + _build_vertical_jitter(row_index, lane, row_count))

func _build_horizontal_jitter(row_index: int, lane: int) -> float:
	if horizontal_jitter_meters == 0.0 or seed_key == "":
		return 0.0

	return _build_signed_jitter("x:%d:%d" % [row_index, lane], horizontal_jitter_meters)

func _build_vertical_jitter(row_index: int, lane: int, row_count: int) -> float:
	if vertical_jitter_meters == 0.0 or seed_key == "":
		return 0.0

	if row_index == 0 or row_index == row_count - 1:
		return 0.0

	return _build_signed_jitter("y:%d:%d" % [row_index, lane], vertical_jitter_meters)

func _build_signed_jitter(jitter_key: String, maximum_abs_jitter_meters: float) -> float:
	Validation.require_condition(maximum_abs_jitter_meters >= 0.0, "RouteAnchorGraphBuilder jitter amount cannot be negative.")
	var jitter_hash: int = _hash_int("%s:%s" % [seed_key, jitter_key])
	var normalized_jitter: float = (float(jitter_hash % 20001) / 10000.0) - 1.0
	return normalized_jitter * maximum_abs_jitter_meters

func _hash_int(seed_text: String) -> int:
	var hash_value: int = 2166136261
	for character_index in range(seed_text.length()):
		hash_value = hash_value ^ seed_text.unicode_at(character_index)
		hash_value = (hash_value * 16777619) & 0x7fffffff

	return hash_value
