@tool
class_name PlayerAppearance
extends Resource

const CharacterSkillProfileScript = preload("res://resources/config/character_skill_profile.gd")

@export var appearance_id: StringName = &"human"
@export var display_name: String = "Human"
@export var hide_overlay_cosmetics: bool = true
@export_file("*.png") var face_texture_path: String = ""
@export var face_offset: Vector2 = Vector2.ZERO
@export var face_scale: Vector2 = Vector2.ONE
@export_file("*.png") var left_upper_arm_texture_path: String = ""
@export var left_upper_arm_offset: Vector2 = Vector2.ZERO
@export var left_upper_arm_scale: Vector2 = Vector2.ONE
## Turns the arm art so its shoulder->hand line matches the rig's bone (see PlayerCharacter).
@export var left_upper_arm_rotation_degrees: float = 0.0
@export_file("*.png") var right_upper_arm_texture_path: String = ""
@export var right_upper_arm_offset: Vector2 = Vector2.ZERO
@export var right_upper_arm_scale: Vector2 = Vector2.ONE
@export var right_upper_arm_rotation_degrees: float = 0.0
## Gameplay sidegrade this character carries (ADR 0013).
@export var skill_profile: CharacterSkillProfileScript

func is_valid() -> bool:
	return not appearance_id.is_empty() \
		and not display_name.is_empty() \
		and _is_asset_path_valid(face_texture_path) \
		and _is_asset_path_valid(left_upper_arm_texture_path) \
		and _is_asset_path_valid(right_upper_arm_texture_path) \
		and skill_profile != null \
		and skill_profile.is_valid()

func validate() -> void:
	assert_valid()

func assert_valid() -> void:
	Validation.require_condition(not appearance_id.is_empty(), "Player appearance id cannot be empty.")
	Validation.require_condition(not display_name.is_empty(), "Player appearance display name cannot be empty.")
	_assert_asset_path(face_texture_path, "Player appearance requires a face texture path.")
	_assert_asset_path(left_upper_arm_texture_path, "Player appearance requires a left arm texture path.")
	_assert_asset_path(right_upper_arm_texture_path, "Player appearance requires a right arm texture path.")
	Validation.require_condition(skill_profile != null, "Player appearance requires a character skill profile.")
	skill_profile.assert_valid()

func _assert_asset_path(asset_path: String, missing_message: String) -> void:
	Validation.require_condition(not asset_path.is_empty(), missing_message)
	Validation.require_condition(ResourceLoader.exists(asset_path), "%s Missing asset at %s." % [missing_message, asset_path])

func _is_asset_path_valid(asset_path: String) -> bool:
	return not asset_path.is_empty() and ResourceLoader.exists(asset_path)
