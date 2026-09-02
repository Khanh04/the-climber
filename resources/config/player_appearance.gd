@tool
class_name PlayerAppearance
extends Resource

@export var appearance_id: StringName = &"human"
@export var display_name: String = "Human"
@export var hide_overlay_cosmetics: bool = true
@export_file("*.png") var atlas_texture_path: String = ""
@export_file("*.png") var face_texture_path: String = ""
@export var face_offset: Vector2 = Vector2.ZERO
@export var face_scale: Vector2 = Vector2.ONE
@export_file("*.png") var left_upper_arm_texture_path: String = ""
@export var left_upper_arm_offset: Vector2 = Vector2.ZERO
@export var left_upper_arm_scale: Vector2 = Vector2.ONE
@export_file("*.png") var right_upper_arm_texture_path: String = ""
@export var right_upper_arm_offset: Vector2 = Vector2.ZERO
@export var right_upper_arm_scale: Vector2 = Vector2.ONE

func is_valid() -> bool:
	return not appearance_id.is_empty() \
		and not display_name.is_empty() \
		and (atlas_texture_path.is_empty() or _is_asset_path_valid(atlas_texture_path)) \
		and _is_asset_path_valid(face_texture_path) \
		and _is_asset_path_valid(left_upper_arm_texture_path) \
		and _is_asset_path_valid(right_upper_arm_texture_path)

func validate() -> void:
	assert_valid()

func assert_valid() -> void:
	Validation.require_condition(not appearance_id.is_empty(), "Player appearance id cannot be empty.")
	Validation.require_condition(not display_name.is_empty(), "Player appearance display name cannot be empty.")
	if not atlas_texture_path.is_empty():
		_assert_asset_path(atlas_texture_path, "Player appearance atlas texture path is invalid.")
	_assert_asset_path(face_texture_path, "Player appearance requires a face texture path.")
	_assert_asset_path(left_upper_arm_texture_path, "Player appearance requires a left arm texture path.")
	_assert_asset_path(right_upper_arm_texture_path, "Player appearance requires a right arm texture path.")

func _assert_asset_path(asset_path: String, missing_message: String) -> void:
	Validation.require_condition(not asset_path.is_empty(), missing_message)
	Validation.require_condition(FileAccess.file_exists(asset_path), "%s Missing asset at %s." % [missing_message, asset_path])

func _is_asset_path_valid(asset_path: String) -> bool:
	return not asset_path.is_empty() and FileAccess.file_exists(asset_path)
