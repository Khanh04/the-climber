@tool
class_name PlayerAppearance
extends Resource

@export var appearance_id: StringName = &"human"
@export var display_name: String = "Human"
@export var hide_overlay_cosmetics: bool = true
@export_file("*.tscn") var rig_scene_path: String = ""
@export var rig_visual_offset: Vector2 = Vector2.ZERO
@export var rig_lower_body_bone_path: NodePath = NodePath("")
@export var rig_left_upper_arm_bone_path: NodePath = NodePath("")
@export var rig_left_forearm_bone_path: NodePath = NodePath("")
@export var rig_left_hand_bone_path: NodePath = NodePath("")
@export var rig_right_upper_arm_bone_path: NodePath = NodePath("")
@export var rig_right_forearm_bone_path: NodePath = NodePath("")
@export var rig_right_hand_bone_path: NodePath = NodePath("")
@export_file("*.png") var atlas_texture_path: String = ""
@export_file("*.png") var body_texture_path: String = ""
@export var body_offset: Vector2 = Vector2.ZERO
@export var body_scale: Vector2 = Vector2.ONE
@export_file("*.png") var face_texture_path: String = ""
@export var face_offset: Vector2 = Vector2.ZERO
@export var face_scale: Vector2 = Vector2.ONE
@export_file("*.png") var left_upper_arm_texture_path: String = ""
@export var left_upper_arm_offset: Vector2 = Vector2.ZERO
@export var left_upper_arm_scale: Vector2 = Vector2.ONE
@export_file("*.png") var left_forearm_texture_path: String = ""
@export var left_forearm_offset: Vector2 = Vector2.ZERO
@export var left_forearm_scale: Vector2 = Vector2.ONE
@export_file("*.png") var left_hand_texture_path: String = ""
@export var left_hand_offset: Vector2 = Vector2.ZERO
@export var left_hand_scale: Vector2 = Vector2.ONE
@export_file("*.png") var right_upper_arm_texture_path: String = ""
@export var right_upper_arm_offset: Vector2 = Vector2.ZERO
@export var right_upper_arm_scale: Vector2 = Vector2.ONE
@export_file("*.png") var right_forearm_texture_path: String = ""
@export var right_forearm_offset: Vector2 = Vector2.ZERO
@export var right_forearm_scale: Vector2 = Vector2.ONE
@export_file("*.png") var right_hand_texture_path: String = ""
@export var right_hand_offset: Vector2 = Vector2.ZERO
@export var right_hand_scale: Vector2 = Vector2.ONE
@export_file("*.png") var lower_body_texture_path: String = ""
@export var lower_body_offset: Vector2 = Vector2.ZERO
@export var lower_body_scale: Vector2 = Vector2.ONE

func is_valid() -> bool:
	return not appearance_id.is_empty() \
		and not display_name.is_empty() \
		and (rig_scene_path.is_empty() or _is_asset_path_valid(rig_scene_path)) \
		and (rig_scene_path.is_empty() or _are_rig_binding_paths_valid()) \
		and (atlas_texture_path.is_empty() or _is_asset_path_valid(atlas_texture_path)) \
		and _is_asset_path_valid(body_texture_path) \
		and _is_asset_path_valid(face_texture_path) \
		and _is_asset_path_valid(left_upper_arm_texture_path) \
		and _is_asset_path_valid(left_forearm_texture_path) \
		and _is_asset_path_valid(left_hand_texture_path) \
		and _is_asset_path_valid(right_upper_arm_texture_path) \
		and _is_asset_path_valid(right_forearm_texture_path) \
		and _is_asset_path_valid(right_hand_texture_path) \
		and _is_asset_path_valid(lower_body_texture_path)

func validate() -> void:
	assert_valid()

func assert_valid() -> void:
	Validation.require_condition(not appearance_id.is_empty(), "Player appearance id cannot be empty.")
	Validation.require_condition(not display_name.is_empty(), "Player appearance display name cannot be empty.")
	if not rig_scene_path.is_empty():
		_assert_asset_path(rig_scene_path, "Player appearance rig scene path is invalid.")
		_assert_node_path(rig_lower_body_bone_path, "Player appearance rig lower body bone path is invalid.")
		_assert_node_path(rig_left_upper_arm_bone_path, "Player appearance rig left upper arm bone path is invalid.")
		_assert_node_path(rig_left_forearm_bone_path, "Player appearance rig left forearm bone path is invalid.")
		_assert_node_path(rig_left_hand_bone_path, "Player appearance rig left hand bone path is invalid.")
		_assert_node_path(rig_right_upper_arm_bone_path, "Player appearance rig right upper arm bone path is invalid.")
		_assert_node_path(rig_right_forearm_bone_path, "Player appearance rig right forearm bone path is invalid.")
		_assert_node_path(rig_right_hand_bone_path, "Player appearance rig right hand bone path is invalid.")
	if not atlas_texture_path.is_empty():
		_assert_asset_path(atlas_texture_path, "Player appearance atlas texture path is invalid.")
	_assert_asset_path(body_texture_path, "Player appearance requires a body texture path.")
	_assert_asset_path(face_texture_path, "Player appearance requires a face texture path.")
	_assert_asset_path(left_upper_arm_texture_path, "Player appearance requires a left upper arm texture path.")
	_assert_asset_path(left_forearm_texture_path, "Player appearance requires a left forearm texture path.")
	_assert_asset_path(left_hand_texture_path, "Player appearance requires a left hand texture path.")
	_assert_asset_path(right_upper_arm_texture_path, "Player appearance requires a right upper arm texture path.")
	_assert_asset_path(right_forearm_texture_path, "Player appearance requires a right forearm texture path.")
	_assert_asset_path(right_hand_texture_path, "Player appearance requires a right hand texture path.")
	_assert_asset_path(lower_body_texture_path, "Player appearance requires a lower body texture path.")

func _assert_asset_path(asset_path: String, missing_message: String) -> void:
	Validation.require_condition(not asset_path.is_empty(), missing_message)
	Validation.require_condition(FileAccess.file_exists(asset_path), "%s Missing asset at %s." % [missing_message, asset_path])

func _assert_node_path(node_path: NodePath, missing_message: String) -> void:
	Validation.require_condition(not _is_node_path_empty(node_path), missing_message)

func _are_rig_binding_paths_valid() -> bool:
	return not _is_node_path_empty(rig_lower_body_bone_path) \
		and not _is_node_path_empty(rig_left_upper_arm_bone_path) \
		and not _is_node_path_empty(rig_left_forearm_bone_path) \
		and not _is_node_path_empty(rig_left_hand_bone_path) \
		and not _is_node_path_empty(rig_right_upper_arm_bone_path) \
		and not _is_node_path_empty(rig_right_forearm_bone_path) \
		and not _is_node_path_empty(rig_right_hand_bone_path)

func _is_node_path_empty(node_path: NodePath) -> bool:
	return String(node_path).is_empty()

func _is_asset_path_valid(asset_path: String) -> bool:
	return not asset_path.is_empty() and FileAccess.file_exists(asset_path)
