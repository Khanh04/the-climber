class_name PlayerCharacter
extends Node2D

const ClimbPrototypeFrameResultScript = preload("res://src/gameplay/player/climb_prototype_frame_result.gd")
const ClimbPrototypeTuningScript = preload("res://resources/config/climb_prototype_tuning.gd")
const HandAttachmentStateScript = preload("res://src/gameplay/player/hand_attachment_state.gd")
const PlayerMotionControllerScript = preload("res://src/gameplay/player/player_motion_controller.gd")
const PlayerPhysicsModeScript = preload("res://src/gameplay/player/player_physics_mode.gd")
const PlayerPhysicsModeTransitionsScript = preload("res://src/gameplay/player/player_physics_mode_transitions.gd")

@export var climb_tuning: ClimbPrototypeTuningScript

var _base_skeleton: Skeleton2D
var _torso_bone: Bone2D
var _player_body: RigidBody2D
var _body_collision_shape: CollisionShape2D
var _left_hand_anchor: Marker2D
var _right_hand_anchor: Marker2D
var _left_grip_joint_anchor: Marker2D
var _right_grip_joint_anchor: Marker2D
var _debug_anchors: Node2D
var _visual_root: Node2D
var _cosmetic_visual_root: Node2D
var _motion_controller: PlayerMotionControllerScript
var _physics_mode: int = 0

func _ready() -> void:
	_validate_required_state()
	_motion_controller = PlayerMotionControllerScript.new(climb_tuning)
	_physics_mode = PlayerPhysicsModeScript.controlled_climb()

func set_climb_tuning(tuning: Resource) -> void:
	Validation.require_condition(tuning != null, "PlayerCharacter requires climb tuning.")
	Validation.require_condition(tuning is ClimbPrototypeTuningScript, "PlayerCharacter requires climb prototype tuning implementation.")

	climb_tuning = tuning
	climb_tuning.assert_valid()
	_motion_controller = PlayerMotionControllerScript.new(climb_tuning)

func apply_frame_motion(frame_result: RefCounted, attachment_state: RefCounted) -> void:
	Validation.require_condition(frame_result != null, "PlayerCharacter requires a frame result.")
	Validation.require_condition(frame_result is ClimbPrototypeFrameResultScript, "PlayerCharacter requires a ClimbPrototypeFrameResult.")
	Validation.require_condition(attachment_state != null, "PlayerCharacter requires hand attachment state.")
	Validation.require_condition(attachment_state is HandAttachmentStateScript, "PlayerCharacter requires HandAttachmentState.")
	Validation.require_condition(_motion_controller != null, "PlayerCharacter requires a motion controller.")

	_physics_mode = PlayerPhysicsModeTransitionsScript.mode_after_frame(_physics_mode, frame_result)
	if _physics_mode != PlayerPhysicsModeScript.controlled_climb():
		return

	_motion_controller.apply_frame_motion(_player_body, attachment_state, frame_result)

func enter_falling(reason: int) -> void:
	PlayerPhysicsModeTransitionsScript.assert_transition_allowed(_physics_mode, PlayerPhysicsModeScript.falling_ragdoll(), reason)
	_physics_mode = PlayerPhysicsModeScript.falling_ragdoll()

func reset_physics(global_position_value: Vector2) -> void:
	_physics_mode = PlayerPhysicsModeTransitionsScript.reset_mode(_physics_mode)
	_player_body.global_position = global_position_value
	_player_body.linear_velocity = Vector2.ZERO
	_player_body.angular_velocity = 0.0

func get_physics_mode() -> int:
	return _physics_mode

func get_player_body() -> RigidBody2D:
	return _player_body

func get_body_global_position() -> Vector2:
	return _player_body.global_position

func set_body_global_position(global_position_value: Vector2) -> void:
	_player_body.global_position = global_position_value

func get_body_linear_velocity() -> Vector2:
	return _player_body.linear_velocity

func set_body_linear_velocity(linear_velocity_value: Vector2) -> void:
	_player_body.linear_velocity = linear_velocity_value

func get_left_hand_anchor() -> Marker2D:
	return _left_hand_anchor

func get_right_hand_anchor() -> Marker2D:
	return _right_hand_anchor

func get_left_hand_anchor_global_position() -> Vector2:
	return _left_hand_anchor.global_position

func get_right_hand_anchor_global_position() -> Vector2:
	return _right_hand_anchor.global_position

func get_visual_root() -> Node2D:
	return _visual_root

func get_cosmetic_visual_root() -> Node2D:
	return _cosmetic_visual_root

func get_body_collision_shape() -> CollisionShape2D:
	return _body_collision_shape

func get_left_grip_joint_anchor() -> Marker2D:
	return _left_grip_joint_anchor

func get_right_grip_joint_anchor() -> Marker2D:
	return _right_grip_joint_anchor

func assert_visual_roots_physics_neutral() -> void:
	_assert_node_tree_has_no_physics_nodes(_visual_root)
	_assert_node_tree_has_no_physics_nodes(_cosmetic_visual_root)

func _validate_required_state() -> void:
	Validation.require_condition(climb_tuning != null, "PlayerCharacter requires climb tuning.")
	climb_tuning.assert_valid()

	_base_skeleton = _require_skeleton_2d("BaseSkeleton", "PlayerCharacter requires BaseSkeleton.")
	_torso_bone = _require_bone_2d("BaseSkeleton/TorsoBone", "PlayerCharacter requires TorsoBone.")
	_player_body = _require_rigid_body_2d("BaseSkeleton/PlayerBody", "PlayerCharacter requires PlayerBody.")
	_body_collision_shape = _require_collision_shape_2d("BaseSkeleton/PlayerBody/BodyCollisionShape", "PlayerCharacter requires BodyCollisionShape.")
	_left_hand_anchor = _require_marker_2d("BaseSkeleton/PlayerBody/LeftHandAnchor", "PlayerCharacter requires LeftHandAnchor.")
	_right_hand_anchor = _require_marker_2d("BaseSkeleton/PlayerBody/RightHandAnchor", "PlayerCharacter requires RightHandAnchor.")
	_left_grip_joint_anchor = _require_marker_2d("GripJoints/LeftGripJointAnchor", "PlayerCharacter requires LeftGripJointAnchor.")
	_right_grip_joint_anchor = _require_marker_2d("GripJoints/RightGripJointAnchor", "PlayerCharacter requires RightGripJointAnchor.")
	_debug_anchors = _require_node_2d("DebugAnchors", "PlayerCharacter requires DebugAnchors.")
	_visual_root = _require_node_2d("BaseSkeleton/PlayerBody/VisualRoot", "PlayerCharacter requires VisualRoot.")
	_cosmetic_visual_root = _require_node_2d("BaseSkeleton/PlayerBody/VisualRoot/CosmeticVisualRoot", "PlayerCharacter requires CosmeticVisualRoot.")

	Validation.require_condition(_body_collision_shape.shape != null, "PlayerCharacter BodyCollisionShape requires a shape.")
	Validation.require_condition(_body_collision_shape.get_parent() == _player_body, "PlayerCharacter gameplay collision must belong to PlayerBody.")
	Validation.require_condition(_player_body.get_parent() == _base_skeleton, "PlayerCharacter PlayerBody must belong to BaseSkeleton.")
	Validation.require_condition(_torso_bone.get_parent() == _base_skeleton, "PlayerCharacter TorsoBone must belong to BaseSkeleton.")
	assert_visual_roots_physics_neutral()

func _require_skeleton_2d(node_path: NodePath, message: String) -> Skeleton2D:
	var node: Node = get_node_or_null(node_path)
	Validation.require_condition(node != null, message)
	Validation.require_condition(node is Skeleton2D, "%s Expected Skeleton2D." % message)
	return node as Skeleton2D

func _require_bone_2d(node_path: NodePath, message: String) -> Bone2D:
	var node: Node = get_node_or_null(node_path)
	Validation.require_condition(node != null, message)
	Validation.require_condition(node is Bone2D, "%s Expected Bone2D." % message)
	return node as Bone2D

func _require_rigid_body_2d(node_path: NodePath, message: String) -> RigidBody2D:
	var node: Node = get_node_or_null(node_path)
	Validation.require_condition(node != null, message)
	Validation.require_condition(node is RigidBody2D, "%s Expected RigidBody2D." % message)
	return node as RigidBody2D

func _require_collision_shape_2d(node_path: NodePath, message: String) -> CollisionShape2D:
	var node: Node = get_node_or_null(node_path)
	Validation.require_condition(node != null, message)
	Validation.require_condition(node is CollisionShape2D, "%s Expected CollisionShape2D." % message)
	return node as CollisionShape2D

func _require_marker_2d(node_path: NodePath, message: String) -> Marker2D:
	var node: Node = get_node_or_null(node_path)
	Validation.require_condition(node != null, message)
	Validation.require_condition(node is Marker2D, "%s Expected Marker2D." % message)
	return node as Marker2D

func _require_node_2d(node_path: NodePath, message: String) -> Node2D:
	var node: Node = get_node_or_null(node_path)
	Validation.require_condition(node != null, message)
	Validation.require_condition(node is Node2D, "%s Expected Node2D." % message)
	return node as Node2D

func _assert_node_tree_has_no_physics_nodes(root: Node) -> void:
	Validation.require_condition(root != null, "Physics-neutral visual validation requires a root node.")
	Validation.require_condition(not root is CollisionObject2D, "Player visual roots cannot contain CollisionObject2D nodes.")
	Validation.require_condition(not root is CollisionShape2D, "Player visual roots cannot contain CollisionShape2D nodes.")

	for child in root.get_children():
		Validation.require_condition(child is Node, "Player visual root child must be a Node.")
		var child_node: Node = child
		_assert_node_tree_has_no_physics_nodes(child_node)