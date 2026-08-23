@tool
class_name PlayerAppearanceCatalog
extends Resource

const PlayerAppearanceScript = preload("res://resources/config/player_appearance.gd")

@export var appearances: Array[Resource] = []

func is_valid() -> bool:
	if appearances.is_empty():
		return false

	var seen_appearance_ids: Dictionary[StringName, bool] = {}
	for appearance in appearances:
		if appearance == null or not appearance is PlayerAppearanceScript:
			return false

		var typed_appearance: PlayerAppearanceScript = appearance as PlayerAppearanceScript
		if not typed_appearance.is_valid() or seen_appearance_ids.has(typed_appearance.appearance_id):
			return false

		seen_appearance_ids[typed_appearance.appearance_id] = true

	return true

func validate() -> void:
	assert_valid()

func assert_valid() -> void:
	Validation.require_condition(not appearances.is_empty(), "Player appearance catalog requires at least one appearance.")

	var seen_appearance_ids: Dictionary[StringName, bool] = {}
	for appearance in appearances:
		Validation.require_condition(appearance != null, "Player appearance catalog cannot contain null appearances.")
		Validation.require_condition(appearance is PlayerAppearanceScript, "Player appearance catalog requires PlayerAppearance resources.")
		var typed_appearance: PlayerAppearanceScript = appearance as PlayerAppearanceScript
		typed_appearance.assert_valid()
		Validation.require_condition(
			not seen_appearance_ids.has(typed_appearance.appearance_id),
			"Player appearance catalog appearance ids must be unique."
		)
		seen_appearance_ids[typed_appearance.appearance_id] = true

func get_all_appearances() -> Array[PlayerAppearanceScript]:
	assert_valid()
	var typed_appearances: Array[PlayerAppearanceScript] = []
	for appearance in appearances:
		typed_appearances.append(appearance as PlayerAppearanceScript)
	return typed_appearances

func get_required_appearance_by_id(appearance_id: StringName) -> PlayerAppearanceScript:
	Validation.require_condition(not appearance_id.is_empty(), "Player appearance catalog lookup requires an appearance id.")
	assert_valid()

	for appearance in appearances:
		var typed_appearance: PlayerAppearanceScript = appearance as PlayerAppearanceScript
		if typed_appearance.appearance_id == appearance_id:
			return typed_appearance

	Validation.require_condition(false, "Player appearance catalog is missing appearance id %s." % String(appearance_id))
	return null
