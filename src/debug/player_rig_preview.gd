@tool
class_name PlayerRigPreview
extends Node2D

const PlayerAppearanceCatalogScript = preload("res://resources/config/player_appearance_catalog.gd")
const PlayerAppearanceScript = preload("res://resources/config/player_appearance.gd")

const AUTHORED_REST_RIG_NODE_NAME: StringName = &"AuthoredRestRig"
const RUNTIME_DRIVEN_RIG_NODE_NAME: StringName = &"RuntimeDrivenRig"

@export var appearance_catalog: PlayerAppearanceCatalogScript
@export var appearance_id: StringName = &"human":
	set(value):
		appearance_id = value
		if is_inside_tree():
			_queue_rebuild_preview()
@export_range(80.0, 640.0, 1.0, "or_greater") var preview_spacing: float = 240.0:
	set(value):
		preview_spacing = value
		if is_inside_tree():
			_sync_anchor_positions()
@export_group("Driven Pose Delta")
@export_range(-180.0, 180.0, 0.1, "degrees") var lower_body_delta_degrees: float = 0.0:
	set(value):
		lower_body_delta_degrees = value
		if is_inside_tree():
			_apply_runtime_pose_delta()
@export_range(-180.0, 180.0, 0.1, "degrees") var left_upper_arm_delta_degrees: float = 0.0:
	set(value):
		left_upper_arm_delta_degrees = value
		if is_inside_tree():
			_apply_runtime_pose_delta()
@export_range(-180.0, 180.0, 0.1, "degrees") var left_forearm_delta_degrees: float = 0.0:
	set(value):
		left_forearm_delta_degrees = value
		if is_inside_tree():
			_apply_runtime_pose_delta()
@export_range(-180.0, 180.0, 0.1, "degrees") var left_hand_delta_degrees: float = 0.0:
	set(value):
		left_hand_delta_degrees = value
		if is_inside_tree():
			_apply_runtime_pose_delta()
@export_range(-180.0, 180.0, 0.1, "degrees") var right_upper_arm_delta_degrees: float = 0.0:
	set(value):
		right_upper_arm_delta_degrees = value
		if is_inside_tree():
			_apply_runtime_pose_delta()
@export_range(-180.0, 180.0, 0.1, "degrees") var right_forearm_delta_degrees: float = 0.0:
	set(value):
		right_forearm_delta_degrees = value
		if is_inside_tree():
			_apply_runtime_pose_delta()
@export_range(-180.0, 180.0, 0.1, "degrees") var right_hand_delta_degrees: float = 0.0:
	set(value):
		right_hand_delta_degrees = value
		if is_inside_tree():
			_apply_runtime_pose_delta()

var _authored_rest_pose_anchor: Marker2D
var _runtime_driven_pose_anchor: Marker2D
var _authored_rest_rig: Node2D = null
var _runtime_driven_rig: Node2D = null
var _authored_lower_body_bone: Bone2D = null
var _runtime_lower_body_bone: Bone2D = null
var _runtime_left_upper_arm_bone: Bone2D = null
var _runtime_left_forearm_bone: Bone2D = null
var _runtime_left_hand_bone: Bone2D = null
var _runtime_right_upper_arm_bone: Bone2D = null
var _runtime_right_forearm_bone: Bone2D = null
var _runtime_right_hand_bone: Bone2D = null
var _runtime_lower_body_rest_rotation: float = 0.0
var _runtime_left_upper_arm_rest_rotation: float = 0.0
var _runtime_left_forearm_rest_rotation: float = 0.0
var _runtime_left_hand_rest_rotation: float = 0.0
var _runtime_right_upper_arm_rest_rotation: float = 0.0
var _runtime_right_forearm_rest_rotation: float = 0.0
var _runtime_right_hand_rest_rotation: float = 0.0
var _rebuild_preview_queued: bool = false

func _ready() -> void:
	_validate_required_state()
	_sync_anchor_positions()
	_rebuild_preview()

func _notification(what: int) -> void:
	if not Engine.is_editor_hint():
		return
	if what == NOTIFICATION_EDITOR_PRE_SAVE:
		_clear_preview_rigs(true)
	elif what == NOTIFICATION_EDITOR_POST_SAVE:
		_queue_rebuild_preview()

func get_authored_rest_rig_for_test() -> Node2D:
	return _authored_rest_rig

func get_runtime_driven_rig_for_test() -> Node2D:
	return _runtime_driven_rig

func get_authored_lower_body_bone_for_test() -> Bone2D:
	return _authored_lower_body_bone

func get_runtime_lower_body_bone_for_test() -> Bone2D:
	return _runtime_lower_body_bone

func _queue_rebuild_preview() -> void:
	if _rebuild_preview_queued:
		return
	_rebuild_preview_queued = true
	call_deferred("_rebuild_preview")

func _rebuild_preview() -> void:
	_rebuild_preview_queued = false
	_validate_required_state()
	_sync_anchor_positions()
	_clear_preview_rigs()
	var appearance: PlayerAppearanceScript = _get_selected_appearance()
	var rig_scene_resource: Resource = load(appearance.rig_scene_path)
	Validation.require_condition(rig_scene_resource != null, "PlayerRigPreview failed to load rig scene at %s." % appearance.rig_scene_path)
	Validation.require_condition(rig_scene_resource is PackedScene, "PlayerRigPreview rig scene must be a PackedScene.")
	var rig_scene: PackedScene = rig_scene_resource as PackedScene
	_authored_rest_rig = _instantiate_preview_rig(rig_scene, AUTHORED_REST_RIG_NODE_NAME, _authored_rest_pose_anchor)
	_runtime_driven_rig = _instantiate_preview_rig(rig_scene, RUNTIME_DRIVEN_RIG_NODE_NAME, _runtime_driven_pose_anchor)
	_authored_lower_body_bone = _require_bone_from_root(_authored_rest_rig, appearance.rig_lower_body_bone_path, "PlayerRigPreview requires an authored lower body bone.")
	_runtime_lower_body_bone = _require_bone_from_root(_runtime_driven_rig, appearance.rig_lower_body_bone_path, "PlayerRigPreview requires a runtime lower body bone.")
	_runtime_left_upper_arm_bone = _require_bone_from_root(_runtime_driven_rig, appearance.rig_left_upper_arm_bone_path, "PlayerRigPreview requires a runtime left upper arm bone.")
	_runtime_left_forearm_bone = _require_bone_from_root(_runtime_driven_rig, appearance.rig_left_forearm_bone_path, "PlayerRigPreview requires a runtime left forearm bone.")
	_runtime_left_hand_bone = _require_bone_from_root(_runtime_driven_rig, appearance.rig_left_hand_bone_path, "PlayerRigPreview requires a runtime left hand bone.")
	_runtime_right_upper_arm_bone = _require_bone_from_root(_runtime_driven_rig, appearance.rig_right_upper_arm_bone_path, "PlayerRigPreview requires a runtime right upper arm bone.")
	_runtime_right_forearm_bone = _require_bone_from_root(_runtime_driven_rig, appearance.rig_right_forearm_bone_path, "PlayerRigPreview requires a runtime right forearm bone.")
	_runtime_right_hand_bone = _require_bone_from_root(_runtime_driven_rig, appearance.rig_right_hand_bone_path, "PlayerRigPreview requires a runtime right hand bone.")
	_runtime_lower_body_rest_rotation = _runtime_lower_body_bone.rotation
	_runtime_left_upper_arm_rest_rotation = _runtime_left_upper_arm_bone.rotation
	_runtime_left_forearm_rest_rotation = _runtime_left_forearm_bone.rotation
	_runtime_left_hand_rest_rotation = _runtime_left_hand_bone.rotation
	_runtime_right_upper_arm_rest_rotation = _runtime_right_upper_arm_bone.rotation
	_runtime_right_forearm_rest_rotation = _runtime_right_forearm_bone.rotation
	_runtime_right_hand_rest_rotation = _runtime_right_hand_bone.rotation
	_apply_runtime_pose_delta()

func _validate_required_state() -> void:
	_authored_rest_pose_anchor = _require_marker_2d("AuthoredRestPoseAnchor", "PlayerRigPreview requires AuthoredRestPoseAnchor.")
	_runtime_driven_pose_anchor = _require_marker_2d("RuntimeDrivenPoseAnchor", "PlayerRigPreview requires RuntimeDrivenPoseAnchor.")
	_resolve_required_appearance_catalog().assert_valid()
	Validation.require_condition(preview_spacing > 0.0, "PlayerRigPreview preview spacing must be positive.")

func _sync_anchor_positions() -> void:
	Validation.require_condition(_authored_rest_pose_anchor != null, "PlayerRigPreview requires AuthoredRestPoseAnchor before syncing preview spacing.")
	Validation.require_condition(_runtime_driven_pose_anchor != null, "PlayerRigPreview requires RuntimeDrivenPoseAnchor before syncing preview spacing.")
	_authored_rest_pose_anchor.position = Vector2(-preview_spacing / 2.0, 0.0)
	_runtime_driven_pose_anchor.position = Vector2(preview_spacing / 2.0, 0.0)

func _get_selected_appearance() -> PlayerAppearanceScript:
	var resolved_catalog: PlayerAppearanceCatalogScript = _resolve_required_appearance_catalog()
	Validation.require_condition(not appearance_id.is_empty(), "PlayerRigPreview requires a non-empty appearance id.")
	var appearance: PlayerAppearanceScript = resolved_catalog.get_required_appearance_by_id(appearance_id)
	appearance.assert_valid()
	Validation.require_condition(not appearance.rig_scene_path.is_empty(), "PlayerRigPreview requires the selected appearance to define a rig scene path.")
	return appearance

func _resolve_required_appearance_catalog() -> PlayerAppearanceCatalogScript:
	Validation.require_condition(appearance_catalog != null, "PlayerRigPreview requires an appearance catalog.")
	if appearance_catalog is PlayerAppearanceCatalogScript:
		return appearance_catalog as PlayerAppearanceCatalogScript

	var catalog_resource_path: String = appearance_catalog.resource_path
	Validation.require_condition(
		not catalog_resource_path.is_empty(),
		"PlayerRigPreview requires the appearance catalog placeholder resource to define a resource path."
	)
	var loaded_resource: Resource = load(catalog_resource_path)
	Validation.require_condition(loaded_resource != null, "PlayerRigPreview failed to load appearance catalog at %s." % catalog_resource_path)
	Validation.require_condition(
		loaded_resource is PlayerAppearanceCatalogScript,
		"PlayerRigPreview appearance catalog at %s must implement PlayerAppearanceCatalog." % catalog_resource_path
	)
	var typed_catalog: PlayerAppearanceCatalogScript = loaded_resource as PlayerAppearanceCatalogScript
	appearance_catalog = typed_catalog
	return typed_catalog

func _instantiate_preview_rig(rig_scene: PackedScene, node_name: StringName, anchor: Marker2D) -> Node2D:
	Validation.require_condition(rig_scene != null, "PlayerRigPreview requires a rig scene to instantiate a preview rig.")
	Validation.require_condition(anchor != null, "PlayerRigPreview requires a preview anchor to instantiate a preview rig.")
	var instantiated_node: Node = rig_scene.instantiate()
	Validation.require_condition(instantiated_node is Node2D, "PlayerRigPreview rig preview root must be a Node2D.")
	var typed_node: Node2D = instantiated_node as Node2D
	typed_node.name = node_name
	typed_node.position = Vector2.ZERO
	typed_node.rotation = 0.0
	typed_node.scale = Vector2.ONE
	anchor.add_child(typed_node)
	_adopt_preview_rig_for_editor(typed_node)
	return typed_node

func _adopt_preview_rig_for_editor(preview_rig: Node2D) -> void:
	if not Engine.is_editor_hint():
		return
	Validation.require_condition(preview_rig != null, "PlayerRigPreview cannot adopt a null preview rig for editor display.")
	preview_rig.owner = self

func _apply_runtime_pose_delta() -> void:
	if _runtime_driven_rig == null:
		return

	Validation.require_condition(_runtime_lower_body_bone != null, "PlayerRigPreview requires a runtime lower body bone before applying pose delta.")
	Validation.require_condition(_runtime_left_upper_arm_bone != null, "PlayerRigPreview requires a runtime left upper arm bone before applying pose delta.")
	Validation.require_condition(_runtime_left_forearm_bone != null, "PlayerRigPreview requires a runtime left forearm bone before applying pose delta.")
	Validation.require_condition(_runtime_left_hand_bone != null, "PlayerRigPreview requires a runtime left hand bone before applying pose delta.")
	Validation.require_condition(_runtime_right_upper_arm_bone != null, "PlayerRigPreview requires a runtime right upper arm bone before applying pose delta.")
	Validation.require_condition(_runtime_right_forearm_bone != null, "PlayerRigPreview requires a runtime right forearm bone before applying pose delta.")
	Validation.require_condition(_runtime_right_hand_bone != null, "PlayerRigPreview requires a runtime right hand bone before applying pose delta.")

	_runtime_lower_body_bone.rotation = _runtime_lower_body_rest_rotation + deg_to_rad(lower_body_delta_degrees)
	_runtime_left_upper_arm_bone.rotation = _runtime_left_upper_arm_rest_rotation + deg_to_rad(left_upper_arm_delta_degrees)
	_runtime_left_forearm_bone.rotation = _runtime_left_forearm_rest_rotation + deg_to_rad(left_forearm_delta_degrees)
	_runtime_left_hand_bone.rotation = _runtime_left_hand_rest_rotation + deg_to_rad(left_hand_delta_degrees)
	_runtime_right_upper_arm_bone.rotation = _runtime_right_upper_arm_rest_rotation + deg_to_rad(right_upper_arm_delta_degrees)
	_runtime_right_forearm_bone.rotation = _runtime_right_forearm_rest_rotation + deg_to_rad(right_forearm_delta_degrees)
	_runtime_right_hand_bone.rotation = _runtime_right_hand_rest_rotation + deg_to_rad(right_hand_delta_degrees)

func _clear_preview_rigs(immediate: bool = false) -> void:
	_runtime_lower_body_rest_rotation = 0.0
	_runtime_left_upper_arm_rest_rotation = 0.0
	_runtime_left_forearm_rest_rotation = 0.0
	_runtime_left_hand_rest_rotation = 0.0
	_runtime_right_upper_arm_rest_rotation = 0.0
	_runtime_right_forearm_rest_rotation = 0.0
	_runtime_right_hand_rest_rotation = 0.0
	_authored_lower_body_bone = null
	_runtime_lower_body_bone = null
	_runtime_left_upper_arm_bone = null
	_runtime_left_forearm_bone = null
	_runtime_left_hand_bone = null
	_runtime_right_upper_arm_bone = null
	_runtime_right_forearm_bone = null
	_runtime_right_hand_bone = null
	if _authored_rest_rig != null:
		_release_preview_rig(_authored_rest_rig, immediate)
		_authored_rest_rig = null
	if _runtime_driven_rig != null:
		_release_preview_rig(_runtime_driven_rig, immediate)
		_runtime_driven_rig = null

func _release_preview_rig(preview_rig: Node2D, immediate: bool) -> void:
	Validation.require_condition(preview_rig != null, "PlayerRigPreview cannot release a null preview rig.")
	if preview_rig.get_parent() != null:
		preview_rig.get_parent().remove_child(preview_rig)
	if immediate:
		preview_rig.free()
	else:
		preview_rig.queue_free()

func _require_marker_2d(node_path: NodePath, message: String) -> Marker2D:
	var node: Node = get_node_or_null(node_path)
	Validation.require_condition(node != null, message)
	Validation.require_condition(node is Marker2D, "%s Expected Marker2D." % message)
	return node as Marker2D

func _require_bone_from_root(root: Node2D, node_path: NodePath, message: String) -> Bone2D:
	Validation.require_condition(root != null, message)
	Validation.require_condition(not String(node_path).is_empty(), "%s NodePath cannot be empty." % message)
	var node: Node = root.get_node_or_null(node_path)
	Validation.require_condition(node != null, message)
	Validation.require_condition(node is Bone2D, "%s Expected Bone2D." % message)
	return node as Bone2D