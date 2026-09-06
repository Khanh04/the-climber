class_name RouteValidationTuning
extends Resource

## Conservative maximum move distance allowed for the safe-path validator.
@export var max_move_distance_meters: float = 2.2
## Runtime hand-anchor acquisition radius used to distinguish static grabs from swing-assisted moves.
@export var static_reach_distance_meters: float = 0.96
## Maximum downward-only move allowed before a path is considered too lossy to be safe.
@export var max_downward_move_meters: float = 0.12
## Minimum lateral clearance a swing move must keep, so the player's body has room to swing
## between two holds instead of squeezing past the wall. Sourced from the player's collision
## footprint (scenes/player/player_character.tscn HeadCollisionShape: 48px wide at
## climb_prototype_tuning.gd's pixels_per_meter = 100.0 -> 0.48m) -- keep the two in agreement.
@export var player_body_width_meters: float = 0.48
## Entry anchors used when validating the opener and any chunk-local starting position.
@export var entry_anchor_positions: PackedVector2Array = PackedVector2Array([
	Vector2(-0.42, -0.24),
	Vector2(0.42, -0.24),
])
## Bounded deterministic candidate count used to select the strongest valid route.
@export var candidate_attempt_count: int = 3

func is_valid() -> bool:
	return max_move_distance_meters > 0.0 \
		and static_reach_distance_meters > 0.0 \
		and static_reach_distance_meters <= max_move_distance_meters \
		and max_downward_move_meters >= 0.0 \
		and player_body_width_meters > 0.0 \
		and player_body_width_meters < max_move_distance_meters \
		and entry_anchor_positions.size() > 0 \
		and candidate_attempt_count >= 1 \
		and _entry_anchor_positions_are_valid()

func validate() -> void:
	assert_valid()

func assert_valid() -> void:
	Validation.require_condition(max_move_distance_meters > 0.0, "Route validation max move distance must be positive.")
	Validation.require_condition(static_reach_distance_meters > 0.0, "Route validation static reach distance must be positive.")
	Validation.require_condition(static_reach_distance_meters <= max_move_distance_meters, "Route validation static reach cannot exceed the swing move envelope.")
	Validation.require_condition(max_downward_move_meters >= 0.0, "Route validation max downward move cannot be negative.")
	Validation.require_condition(player_body_width_meters > 0.0, "Route validation player body width must be positive.")
	Validation.require_condition(player_body_width_meters < max_move_distance_meters, "Route validation player body width cannot exceed the swing move envelope.")
	Validation.require_condition(entry_anchor_positions.size() > 0, "Route validation requires at least one entry anchor position.")
	Validation.require_condition(candidate_attempt_count >= 1, "Route validation candidate attempt count must be at least one.")
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
