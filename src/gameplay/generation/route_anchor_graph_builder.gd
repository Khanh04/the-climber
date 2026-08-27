class_name RouteAnchorGraphBuilder
extends RefCounted

const ChunkRoutePlanScript = preload("res://src/gameplay/generation/chunk_route_plan.gd")
const RouteAnchorCandidateScript = preload("res://src/gameplay/generation/route_anchor_candidate.gd")
const RouteAnchorGraphScript = preload("res://src/gameplay/generation/route_anchor_graph.gd")
const RouteLaneScript = preload("res://src/gameplay/generation/route_lane.gd")

const DEFAULT_INNER_LANE_POSITION_RATIO: float = 0.28
const DEFAULT_OUTER_LANE_POSITION_RATIO: float = 0.82
const STARTING_INNER_LANE_OFFSET_METERS: float = 0.42
const STARTING_OUTER_LANE_OFFSET_METERS: float = 1.23
const LANE_FAN_OUT_ROW_COUNT: int = 3

var chunk_width_meters: float
var row_step_height_meters: float
var first_row_height_meters: float
var horizontal_jitter_meters: float
var vertical_jitter_meters: float
var seed_key: String
var inner_lane_position_ratio: float
var outer_lane_position_ratio: float

func _init(
	chunk_width_meters_value: float,
	row_step_height_meters_value: float,
	first_row_height_meters_value: float = -1.0,
	horizontal_jitter_meters_value: float = 0.0,
	vertical_jitter_meters_value: float = 0.0,
	seed_key_value: String = "",
	inner_lane_position_ratio_value: float = DEFAULT_INNER_LANE_POSITION_RATIO,
	outer_lane_position_ratio_value: float = DEFAULT_OUTER_LANE_POSITION_RATIO
) -> void:
	chunk_width_meters = chunk_width_meters_value
	row_step_height_meters = row_step_height_meters_value
	first_row_height_meters = first_row_height_meters_value
	horizontal_jitter_meters = horizontal_jitter_meters_value
	vertical_jitter_meters = vertical_jitter_meters_value
	seed_key = seed_key_value
	inner_lane_position_ratio = inner_lane_position_ratio_value
	outer_lane_position_ratio = outer_lane_position_ratio_value
	if first_row_height_meters < 0.0:
		first_row_height_meters = row_step_height_meters
	assert_valid()

func assert_valid() -> void:
	Validation.require_condition(chunk_width_meters > 0.0, "RouteAnchorGraphBuilder chunk width must be positive.")
	Validation.require_condition(row_step_height_meters > 0.0, "RouteAnchorGraphBuilder row step height must be positive.")
	Validation.require_condition(first_row_height_meters > 0.0, "RouteAnchorGraphBuilder first row height must be positive.")
	Validation.require_condition(horizontal_jitter_meters >= 0.0, "RouteAnchorGraphBuilder horizontal jitter cannot be negative.")
	Validation.require_condition(vertical_jitter_meters >= 0.0, "RouteAnchorGraphBuilder vertical jitter cannot be negative.")
	Validation.require_condition(inner_lane_position_ratio > 0.0, "RouteAnchorGraphBuilder inner lane ratio must be positive.")
	Validation.require_condition(outer_lane_position_ratio > inner_lane_position_ratio, "RouteAnchorGraphBuilder outer lane ratio must exceed the inner lane ratio.")
	Validation.require_condition(outer_lane_position_ratio < 1.0, "RouteAnchorGraphBuilder outer lane ratio must stay inside the chunk width.")

func set_lane_position_ratios(inner_lane_position_ratio_value: float, outer_lane_position_ratio_value: float) -> void:
	inner_lane_position_ratio = inner_lane_position_ratio_value
	outer_lane_position_ratio = outer_lane_position_ratio_value
	assert_valid()

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
	var row_height_meters: float = first_row_height_meters + (row_step_height_meters * float(row_index))
	var base_position: Vector2 = Vector2(_get_lane_position_meters(lane, row_index, half_width_meters), -row_height_meters)
	var jittered_x: float = clampf(
		base_position.x + _build_horizontal_jitter(row_index, lane),
		-half_width_meters,
		half_width_meters
	)
	return Vector2(jittered_x, base_position.y + _build_vertical_jitter(row_index, lane, row_count))

func _get_lane_position_meters(lane: int, row_index: int, half_width_meters: float) -> float:
	var inner_position_meters: float = _get_fanned_lane_position(
		STARTING_INNER_LANE_OFFSET_METERS,
		half_width_meters * inner_lane_position_ratio,
		row_index
	)
	var outer_position_meters: float = _get_fanned_lane_position(
		STARTING_OUTER_LANE_OFFSET_METERS,
		half_width_meters * outer_lane_position_ratio,
		row_index
	)
	match lane:
		RouteLaneScript.Value.OUTER_LEFT:
			return -outer_position_meters
		RouteLaneScript.Value.INNER_LEFT:
			return -inner_position_meters
		RouteLaneScript.Value.CENTER:
			return 0.0
		RouteLaneScript.Value.INNER_RIGHT:
			return inner_position_meters
		RouteLaneScript.Value.OUTER_RIGHT:
			return outer_position_meters
		_:
			Validation.require_condition(false, "RouteAnchorGraphBuilder lane positions require a supported lane.")
			return 0.0

func _get_fanned_lane_position(starting_position_meters: float, target_position_meters: float, row_index: int) -> float:
	var fan_progress: float = clampf(float(row_index) / float(LANE_FAN_OUT_ROW_COUNT), 0.0, 1.0)
	return lerpf(starting_position_meters, target_position_meters, fan_progress)

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
