class_name HandholdAssignmentRule
extends Resource

const ChunkDifficultyBandScript = preload("res://src/gameplay/generation/chunk_difficulty_band.gd")
const ChunkRouteSlotScript = preload("res://src/gameplay/generation/chunk_route_slot.gd")
const HandholdRowZoneScript = preload("res://src/gameplay/generation/handhold_row_zone.gd")
const HandholdTypeScript = preload("res://src/gameplay/generation/handhold_type.gd")

@export var route_slot: int = ChunkRouteSlotScript.Value.OPENER
@export var applies_to_all_difficulty_bands: bool = false
@export var difficulty_band: int = ChunkDifficultyBandScript.Value.EASY
@export var row_zone: int = HandholdRowZoneScript.Value.ANY
@export var allowed_handhold_types: Array[int] = [HandholdTypeScript.Value.NORMAL]

func is_valid() -> bool:
	if not ChunkRouteSlotScript.is_valid(route_slot):
		return false

	if not applies_to_all_difficulty_bands and not ChunkDifficultyBandScript.is_valid(difficulty_band):
		return false

	if not HandholdRowZoneScript.is_valid(row_zone):
		return false

	if allowed_handhold_types.is_empty():
		return false

	for handhold_type in allowed_handhold_types:
		if not HandholdTypeScript.is_valid(handhold_type):
			return false

	return true

func validate() -> void:
	assert_valid()

func assert_valid() -> void:
	ChunkRouteSlotScript.assert_valid(route_slot)
	if not applies_to_all_difficulty_bands:
		ChunkDifficultyBandScript.assert_valid(difficulty_band)
	HandholdRowZoneScript.assert_valid(row_zone)
	Validation.require_condition(
		not allowed_handhold_types.is_empty(),
		"Handhold assignment rules require at least one allowed handhold type."
	)

	for handhold_type in allowed_handhold_types:
		HandholdTypeScript.assert_valid(handhold_type)

func matches(route_slot_value: int, difficulty_band_value: int, row_index: int, row_count: int) -> bool:
	ChunkRouteSlotScript.assert_valid(route_slot_value)
	ChunkDifficultyBandScript.assert_valid(difficulty_band_value)
	Validation.require_condition(row_count > 0, "Handhold assignment rule matching requires at least one row.")
	Validation.require_condition(row_index >= 0 and row_index < row_count, "Handhold assignment rule row index is out of bounds.")

	if route_slot_value != route_slot:
		return false

	if not applies_to_all_difficulty_bands and difficulty_band_value != difficulty_band:
		return false

	return HandholdRowZoneScript.matches_row(row_zone, row_index, row_count)

func get_allowed_handhold_types_copy() -> Array[int]:
	var handhold_types_copy: Array[int] = []
	for handhold_type in allowed_handhold_types:
		handhold_types_copy.append(handhold_type)
	return handhold_types_copy