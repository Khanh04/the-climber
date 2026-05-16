class_name RouteValidationTuning
extends Resource

## Conservative maximum move distance allowed for the safe-path validator.
@export var max_move_distance_meters: float = 1.2
## Maximum downward-only move allowed before a path is considered too lossy to be safe.
@export var max_downward_move_meters: float = 0.12
## Entry anchors used when validating the opener and any chunk-local starting position.
@export var entry_anchor_positions: PackedVector2Array = PackedVector2Array([
	Vector2(-0.42, -0.24),
	Vector2(0.42, -0.24),
])
## Vertical grouping tolerance for route entry and exit ports derived from generated handholds.
@export var route_port_row_tolerance_meters: float = 0.3
## Bounded deterministic retry count before the generator accepts the best available invalid candidate.
@export var candidate_attempt_count: int = 1
## Relative weight for vertical movement cost when the route graph starts scoring moves.
@export var vertical_move_cost_weight: float = 1.0
## Relative weight for lateral movement cost when the route graph starts scoring moves.
@export var lateral_move_cost_weight: float = 1.0
## Relative weight for hand alternation or cross-through penalties.
@export var hand_switch_cost_weight: float = 0.25
## Relative weight for hold-type-specific punishment on candidate scoring.
@export var hold_type_cost_weight: float = 1.0
## Relative weight for stamina pressure when scoring safe and optional paths.
@export var stamina_cost_weight: float = 1.0
## Relative weight for hazard pressure when comparing otherwise valid candidates.
@export var hazard_pressure_cost_weight: float = 1.0
## Upper chunk-height ratio for the setup zone.
@export var setup_zone_upper_ratio: float = 0.34
## Upper chunk-height ratio for the crux zone before top-out space begins.
@export var crux_zone_upper_ratio: float = 0.76
## Lower chunk-height ratio where top-out roles can begin.
@export var top_out_zone_lower_ratio: float = 0.76

func is_valid() -> bool:
	return max_move_distance_meters > 0.0 \
		and max_downward_move_meters >= 0.0 \
		and entry_anchor_positions.size() > 0 \
		and route_port_row_tolerance_meters >= 0.0 \
		and candidate_attempt_count >= 1 \
		and vertical_move_cost_weight >= 0.0 \
		and lateral_move_cost_weight >= 0.0 \
		and hand_switch_cost_weight >= 0.0 \
		and hold_type_cost_weight >= 0.0 \
		and stamina_cost_weight >= 0.0 \
		and hazard_pressure_cost_weight >= 0.0 \
		and setup_zone_upper_ratio > 0.0 \
		and setup_zone_upper_ratio < crux_zone_upper_ratio \
		and crux_zone_upper_ratio <= top_out_zone_lower_ratio \
		and top_out_zone_lower_ratio < 1.0 \
		and _entry_anchor_positions_are_valid()

func validate() -> void:
	assert_valid()

func assert_valid() -> void:
	Validation.require_condition(max_move_distance_meters > 0.0, "Route validation max move distance must be positive.")
	Validation.require_condition(max_downward_move_meters >= 0.0, "Route validation max downward move cannot be negative.")
	Validation.require_condition(entry_anchor_positions.size() > 0, "Route validation requires at least one entry anchor position.")
	Validation.require_condition(route_port_row_tolerance_meters >= 0.0, "Route validation route-port row tolerance cannot be negative.")
	Validation.require_condition(candidate_attempt_count >= 1, "Route validation candidate attempt count must be at least one.")
	Validation.require_condition(vertical_move_cost_weight >= 0.0, "Route validation vertical move cost weight cannot be negative.")
	Validation.require_condition(lateral_move_cost_weight >= 0.0, "Route validation lateral move cost weight cannot be negative.")
	Validation.require_condition(hand_switch_cost_weight >= 0.0, "Route validation hand-switch cost weight cannot be negative.")
	Validation.require_condition(hold_type_cost_weight >= 0.0, "Route validation hold-type cost weight cannot be negative.")
	Validation.require_condition(stamina_cost_weight >= 0.0, "Route validation stamina cost weight cannot be negative.")
	Validation.require_condition(hazard_pressure_cost_weight >= 0.0, "Route validation hazard-pressure cost weight cannot be negative.")
	Validation.require_condition(setup_zone_upper_ratio > 0.0, "Route validation setup-zone upper ratio must be positive.")
	Validation.require_condition(
		setup_zone_upper_ratio < crux_zone_upper_ratio,
		"Route validation setup-zone ratio must be lower than the crux-zone ratio."
	)
	Validation.require_condition(
		crux_zone_upper_ratio <= top_out_zone_lower_ratio,
		"Route validation crux-zone ratio must not exceed the top-out lower ratio."
	)
	Validation.require_condition(top_out_zone_lower_ratio < 1.0, "Route validation top-out lower ratio must stay below 1.0.")
	_assert_valid_entry_anchor_positions()

func duplicate_entry_anchor_positions() -> Array[Vector2]:
	assert_valid()
	var duplicated_positions: Array[Vector2] = []
	for anchor_position in entry_anchor_positions:
		duplicated_positions.append(anchor_position)
	return duplicated_positions

func _entry_anchor_positions_are_valid() -> bool:
	for anchor_position in entry_anchor_positions:
		if not anchor_position is Vector2:
			return false

	return true

func _assert_valid_entry_anchor_positions() -> void:
	for anchor_index in range(entry_anchor_positions.size()):
		var anchor_position: Vector2 = entry_anchor_positions[anchor_index]
		Validation.require_condition(
			anchor_position is Vector2,
			"Route validation entry anchor positions must contain Vector2 values."
		)