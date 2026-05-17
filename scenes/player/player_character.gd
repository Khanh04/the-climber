class_name PlayerCharacter
extends Node2D

const ClimbPrototypeFrameResultScript = preload("res://src/gameplay/player/climb_prototype_frame_result.gd")
const ClimbPrototypeTuningScript = preload("res://resources/config/climb_prototype_tuning.gd")
const HandVisualFollowControllerScript = preload("res://src/gameplay/player/hand_visual_follow_controller.gd")
const HandAttachmentStateScript = preload("res://src/gameplay/player/hand_attachment_state.gd")
const HandSideScript = preload("res://src/gameplay/player/hand_side.gd")
const PlayerMotionControllerScript = preload("res://src/gameplay/player/player_motion_controller.gd")
const PlayerPhysicsModeScript = preload("res://src/gameplay/player/player_physics_mode.gd")
const PlayerPhysicsModeTransitionsScript = preload("res://src/gameplay/player/player_physics_mode_transitions.gd")

const CONTROLLED_COLLISION_MASK: int = 1
const FALLING_COLLISION_MASK: int = 3

@export var climb_tuning: ClimbPrototypeTuningScript

var _base_skeleton: Skeleton2D
var _torso_bone: Bone2D
var _player_body: RigidBody2D
var _body_collision_shape: CollisionShape2D
var _left_shoulder_socket: Marker2D
var _right_shoulder_socket: Marker2D
var _left_hand_anchor: Marker2D
var _right_hand_anchor: Marker2D
var _left_hand_visual_anchor: Marker2D
var _right_hand_visual_anchor: Marker2D
var _left_hand_cosmetic_root: Node2D
var _right_hand_cosmetic_root: Node2D
var _left_grip_joint_anchor: Marker2D
var _right_grip_joint_anchor: Marker2D
var _left_runtime_grip_joint: PinJoint2D = null
var _right_runtime_grip_joint: PinJoint2D = null
var _left_runtime_grip_link: Line2D = null
var _right_runtime_grip_link: Line2D = null
var _debug_anchors: Node2D
var _visual_root: Node2D
var _cosmetic_visual_root: Node2D
var _hand_visual_follow_controller: HandVisualFollowControllerScript
var _motion_controller: PlayerMotionControllerScript
var _left_hand_visual_offset_from_reach: Vector2 = Vector2.ZERO
var _right_hand_visual_offset_from_reach: Vector2 = Vector2.ZERO
var _physics_mode: int = 0
var _reset_body_rotation: float = 0.0

func _ready() -> void:
	_validate_required_state()
	set_physics_process(true)
	_reset_body_rotation = _player_body.rotation
	_hand_visual_follow_controller = HandVisualFollowControllerScript.new(climb_tuning)
	_motion_controller = PlayerMotionControllerScript.new(climb_tuning)
	_capture_hand_visual_offsets()
	_reset_hand_visual_anchors()
	_physics_mode = PlayerPhysicsModeScript.controlled_climb()
	_sync_body_collision_mask_for_mode()

func _physics_process(delta: float) -> void:
	Validation.require_condition(_hand_visual_follow_controller != null, "PlayerCharacter requires a hand visual follow controller.")
	_sync_hand_visual_anchors(delta)

func set_climb_tuning(tuning: Resource) -> void:
	Validation.require_condition(tuning != null, "PlayerCharacter requires climb tuning.")
	Validation.require_condition(tuning is ClimbPrototypeTuningScript, "PlayerCharacter requires climb prototype tuning implementation.")

	climb_tuning = tuning
	climb_tuning.assert_valid()
	_hand_visual_follow_controller = HandVisualFollowControllerScript.new(climb_tuning)
	_motion_controller = PlayerMotionControllerScript.new(climb_tuning)
	if is_node_ready():
		_reset_hand_visual_anchors()

func apply_frame_motion(frame_result: RefCounted, attachment_state: RefCounted) -> void:
	Validation.require_condition(frame_result != null, "PlayerCharacter requires a frame result.")
	Validation.require_condition(frame_result is ClimbPrototypeFrameResultScript, "PlayerCharacter requires a ClimbPrototypeFrameResult.")
	Validation.require_condition(attachment_state != null, "PlayerCharacter requires hand attachment state.")
	Validation.require_condition(attachment_state is HandAttachmentStateScript, "PlayerCharacter requires HandAttachmentState.")
	Validation.require_condition(_motion_controller != null, "PlayerCharacter requires a motion controller.")

	var typed_attachment_state: HandAttachmentStateScript = attachment_state

	_physics_mode = PlayerPhysicsModeTransitionsScript.mode_after_frame(_physics_mode, frame_result)
	_sync_body_collision_mask_for_mode()
	if _physics_mode != PlayerPhysicsModeScript.controlled_climb():
		clear_runtime_grip_joints()
		clear_runtime_grip_links()
		return

	sync_runtime_grip_joints(typed_attachment_state)
	sync_runtime_grip_links(typed_attachment_state)
	_motion_controller.apply_frame_motion(_player_body, typed_attachment_state, frame_result)

func sync_runtime_grip_joints(attachment_state: RefCounted) -> void:
	Validation.require_condition(attachment_state != null, "PlayerCharacter requires hand attachment state to sync runtime grip joints.")
	Validation.require_condition(attachment_state is HandAttachmentStateScript, "PlayerCharacter requires HandAttachmentState to sync runtime grip joints.")

	var typed_attachment_state: HandAttachmentStateScript = attachment_state
	_left_runtime_grip_joint = _sync_runtime_grip_joint(
		HandSideScript.Value.LEFT,
		_left_runtime_grip_joint,
		_left_grip_joint_anchor,
		typed_attachment_state,
		&"LeftRuntimeGripJoint"
	)
	_right_runtime_grip_joint = _sync_runtime_grip_joint(
		HandSideScript.Value.RIGHT,
		_right_runtime_grip_joint,
		_right_grip_joint_anchor,
		typed_attachment_state,
		&"RightRuntimeGripJoint"
	)

func clear_runtime_grip_joints() -> void:
	_left_runtime_grip_joint = _clear_runtime_grip_joint(_left_runtime_grip_joint)
	_right_runtime_grip_joint = _clear_runtime_grip_joint(_right_runtime_grip_joint)

func sync_runtime_grip_links(attachment_state: RefCounted) -> void:
	Validation.require_condition(attachment_state != null, "PlayerCharacter requires hand attachment state to sync runtime grip links.")
	Validation.require_condition(attachment_state is HandAttachmentStateScript, "PlayerCharacter requires HandAttachmentState to sync runtime grip links.")

	var typed_attachment_state: HandAttachmentStateScript = attachment_state
	_left_runtime_grip_link = _sync_runtime_grip_link(
		HandSideScript.Value.LEFT,
		_left_runtime_grip_link,
		_left_hand_anchor,
		typed_attachment_state,
		&"LeftGripLink"
	)
	_right_runtime_grip_link = _sync_runtime_grip_link(
		HandSideScript.Value.RIGHT,
		_right_runtime_grip_link,
		_right_hand_anchor,
		typed_attachment_state,
		&"RightGripLink"
	)

func clear_runtime_grip_links() -> void:
	_left_runtime_grip_link = _clear_runtime_grip_link(_left_runtime_grip_link)
	_right_runtime_grip_link = _clear_runtime_grip_link(_right_runtime_grip_link)

func enter_falling(reason: int) -> void:
	PlayerPhysicsModeTransitionsScript.assert_transition_allowed(_physics_mode, PlayerPhysicsModeScript.falling_ragdoll(), reason)
	_physics_mode = PlayerPhysicsModeScript.falling_ragdoll()
	_sync_body_collision_mask_for_mode()
	clear_runtime_grip_joints()
	clear_runtime_grip_links()

func reset_physics(global_position_value: Vector2) -> void:
	_physics_mode = PlayerPhysicsModeTransitionsScript.reset_mode(_physics_mode)
	_sync_body_collision_mask_for_mode()
	clear_runtime_grip_joints()
	clear_runtime_grip_links()
	_player_body.global_position = global_position_value
	_player_body.rotation = _reset_body_rotation
	_player_body.linear_velocity = Vector2.ZERO
	_player_body.angular_velocity = 0.0
	_reset_hand_visual_anchors()

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

func get_left_shoulder_socket() -> Marker2D:
	return _left_shoulder_socket

func get_right_shoulder_socket() -> Marker2D:
	return _right_shoulder_socket

func get_left_hand_visual_anchor() -> Marker2D:
	return _left_hand_visual_anchor

func get_right_hand_visual_anchor() -> Marker2D:
	return _right_hand_visual_anchor

func get_left_hand_anchor_global_position() -> Vector2:
	return _left_hand_anchor.global_position

func get_right_hand_anchor_global_position() -> Vector2:
	return _right_hand_anchor.global_position

func get_left_hand_cosmetic_root() -> Node2D:
	return _left_hand_cosmetic_root

func get_right_hand_cosmetic_root() -> Node2D:
	return _right_hand_cosmetic_root

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

func get_left_runtime_grip_joint() -> PinJoint2D:
	return _left_runtime_grip_joint

func get_right_runtime_grip_joint() -> PinJoint2D:
	return _right_runtime_grip_joint

func get_left_runtime_grip_link() -> Line2D:
	return _left_runtime_grip_link

func get_right_runtime_grip_link() -> Line2D:
	return _right_runtime_grip_link

func assert_visual_roots_physics_neutral() -> void:
	_assert_node_tree_has_no_physics_nodes(_visual_root)
	_assert_node_tree_has_no_physics_nodes(_cosmetic_visual_root)
	_assert_node_tree_has_no_physics_nodes(_left_hand_cosmetic_root)
	_assert_node_tree_has_no_physics_nodes(_right_hand_cosmetic_root)

func _sync_body_collision_mask_for_mode() -> void:
	Validation.require_condition(_player_body != null, "PlayerCharacter requires PlayerBody before syncing collision masks.")
	if _physics_mode == PlayerPhysicsModeScript.falling_ragdoll():
		_player_body.collision_mask = FALLING_COLLISION_MASK
		return

	_player_body.collision_mask = CONTROLLED_COLLISION_MASK

func _validate_required_state() -> void:
	Validation.require_condition(climb_tuning != null, "PlayerCharacter requires climb tuning.")
	climb_tuning.assert_valid()

	_base_skeleton = _require_skeleton_2d("BaseSkeleton", "PlayerCharacter requires BaseSkeleton.")
	_torso_bone = _require_bone_2d("BaseSkeleton/TorsoBone", "PlayerCharacter requires TorsoBone.")
	_player_body = _require_rigid_body_2d("BaseSkeleton/PlayerBody", "PlayerCharacter requires PlayerBody.")
	_body_collision_shape = _require_collision_shape_2d("BaseSkeleton/PlayerBody/BodyCollisionShape", "PlayerCharacter requires BodyCollisionShape.")
	_left_shoulder_socket = _require_marker_2d("BaseSkeleton/PlayerBody/LeftShoulderSocket", "PlayerCharacter requires LeftShoulderSocket.")
	_right_shoulder_socket = _require_marker_2d("BaseSkeleton/PlayerBody/RightShoulderSocket", "PlayerCharacter requires RightShoulderSocket.")
	_left_hand_anchor = _require_marker_2d("BaseSkeleton/PlayerBody/LeftShoulderSocket/LeftHandAnchor", "PlayerCharacter requires LeftHandAnchor.")
	_right_hand_anchor = _require_marker_2d("BaseSkeleton/PlayerBody/RightShoulderSocket/RightHandAnchor", "PlayerCharacter requires RightHandAnchor.")
	_left_hand_visual_anchor = _require_marker_2d("BaseSkeleton/PlayerBody/LeftShoulderSocket/LeftHandVisualAnchor", "PlayerCharacter requires LeftHandVisualAnchor.")
	_right_hand_visual_anchor = _require_marker_2d("BaseSkeleton/PlayerBody/RightShoulderSocket/RightHandVisualAnchor", "PlayerCharacter requires RightHandVisualAnchor.")
	_left_hand_cosmetic_root = _require_node_2d("BaseSkeleton/PlayerBody/LeftShoulderSocket/LeftHandVisualAnchor/LeftHandCosmeticRoot", "PlayerCharacter requires LeftHandCosmeticRoot.")
	_right_hand_cosmetic_root = _require_node_2d("BaseSkeleton/PlayerBody/RightShoulderSocket/RightHandVisualAnchor/RightHandCosmeticRoot", "PlayerCharacter requires RightHandCosmeticRoot.")
	_left_grip_joint_anchor = _require_marker_2d("GripJoints/LeftGripJointAnchor", "PlayerCharacter requires LeftGripJointAnchor.")
	_right_grip_joint_anchor = _require_marker_2d("GripJoints/RightGripJointAnchor", "PlayerCharacter requires RightGripJointAnchor.")
	_debug_anchors = _require_node_2d("DebugAnchors", "PlayerCharacter requires DebugAnchors.")
	_visual_root = _require_node_2d("BaseSkeleton/PlayerBody/VisualRoot", "PlayerCharacter requires VisualRoot.")
	_cosmetic_visual_root = _require_node_2d("BaseSkeleton/PlayerBody/VisualRoot/CosmeticVisualRoot", "PlayerCharacter requires CosmeticVisualRoot.")

	Validation.require_condition(_body_collision_shape.shape != null, "PlayerCharacter BodyCollisionShape requires a shape.")
	Validation.require_condition(_body_collision_shape.get_parent() == _player_body, "PlayerCharacter gameplay collision must belong to PlayerBody.")
	Validation.require_condition(_player_body.get_parent() == _base_skeleton, "PlayerCharacter PlayerBody must belong to BaseSkeleton.")
	Validation.require_condition(_torso_bone.get_parent() == _base_skeleton, "PlayerCharacter TorsoBone must belong to BaseSkeleton.")
	Validation.require_condition(_left_shoulder_socket.get_parent() == _player_body, "PlayerCharacter LeftShoulderSocket must belong to PlayerBody.")
	Validation.require_condition(_right_shoulder_socket.get_parent() == _player_body, "PlayerCharacter RightShoulderSocket must belong to PlayerBody.")
	Validation.require_condition(_left_hand_anchor.get_parent() == _left_shoulder_socket, "PlayerCharacter LeftHandAnchor must belong to LeftShoulderSocket.")
	Validation.require_condition(_right_hand_anchor.get_parent() == _right_shoulder_socket, "PlayerCharacter RightHandAnchor must belong to RightShoulderSocket.")
	Validation.require_condition(_left_hand_visual_anchor.get_parent() == _left_shoulder_socket, "PlayerCharacter LeftHandVisualAnchor must belong to LeftShoulderSocket.")
	Validation.require_condition(_right_hand_visual_anchor.get_parent() == _right_shoulder_socket, "PlayerCharacter RightHandVisualAnchor must belong to RightShoulderSocket.")
	Validation.require_condition(_left_hand_cosmetic_root.get_parent() == _left_hand_visual_anchor, "PlayerCharacter LeftHandCosmeticRoot must belong to LeftHandVisualAnchor.")
	Validation.require_condition(_right_hand_cosmetic_root.get_parent() == _right_hand_visual_anchor, "PlayerCharacter RightHandCosmeticRoot must belong to RightHandVisualAnchor.")
	assert_visual_roots_physics_neutral()

func _capture_hand_visual_offsets() -> void:
	_left_hand_visual_offset_from_reach = _left_hand_visual_anchor.position - _left_hand_anchor.position
	_right_hand_visual_offset_from_reach = _right_hand_visual_anchor.position - _right_hand_anchor.position

func _reset_hand_visual_anchors() -> void:
	_left_hand_visual_anchor.position = _left_hand_anchor.position + _left_hand_visual_offset_from_reach
	_right_hand_visual_anchor.position = _right_hand_anchor.position + _right_hand_visual_offset_from_reach

func _sync_hand_visual_anchors(delta: float) -> void:
	var body_local_velocity: Vector2 = _player_body.to_local(_player_body.global_position + _player_body.linear_velocity)
	var left_attached_to_hold: bool = _left_runtime_grip_joint != null
	var right_attached_to_hold: bool = _right_runtime_grip_joint != null
	var left_attached_hold_local_position: Vector2 = Vector2.ZERO
	var right_attached_hold_local_position: Vector2 = Vector2.ZERO
	if left_attached_to_hold:
		left_attached_hold_local_position = _left_shoulder_socket.to_local(_left_runtime_grip_joint.global_position)
	if right_attached_to_hold:
		right_attached_hold_local_position = _right_shoulder_socket.to_local(_right_runtime_grip_joint.global_position)

	_left_hand_visual_anchor.position = _hand_visual_follow_controller.calculate_next_local_position(
		_left_hand_visual_anchor.position,
		_left_hand_anchor.position,
		_left_hand_visual_offset_from_reach,
		body_local_velocity,
		delta,
		left_attached_hold_local_position,
		left_attached_to_hold
	)
	_right_hand_visual_anchor.position = _hand_visual_follow_controller.calculate_next_local_position(
		_right_hand_visual_anchor.position,
		_right_hand_anchor.position,
		_right_hand_visual_offset_from_reach,
		body_local_velocity,
		delta,
		right_attached_hold_local_position,
		right_attached_to_hold
	)

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

func _sync_runtime_grip_joint(
	hand_side: int,
	current_joint: PinJoint2D,
	joint_anchor: Marker2D,
	attachment_state: HandAttachmentStateScript,
	joint_name: StringName
) -> PinJoint2D:
	if not attachment_state.is_attached(hand_side):
		return _clear_runtime_grip_joint(current_joint)

	var hold_node: Node = _resolve_attached_hold_node(attachment_state.get_hold_path(hand_side))
	Validation.require_condition(hold_node != null, "PlayerCharacter runtime grip joint requires an attached handhold node.")
	Validation.require_condition(hold_node is PhysicsBody2D, "PlayerCharacter runtime grip joint requires a PhysicsBody2D handhold.")

	var typed_hold_node: PhysicsBody2D = hold_node
	var active_joint: PinJoint2D = current_joint
	if active_joint != null:
		var expected_node_b: NodePath = active_joint.get_path_to(typed_hold_node)
		if active_joint.node_b != expected_node_b:
			active_joint = _clear_runtime_grip_joint(active_joint)

	if active_joint == null:
		active_joint = PinJoint2D.new()
		active_joint.name = joint_name
		active_joint.disable_collision = true
		joint_anchor.add_child(active_joint)

	active_joint.global_position = attachment_state.get_attach_position(hand_side)
	active_joint.node_a = active_joint.get_path_to(_player_body)
	active_joint.node_b = active_joint.get_path_to(typed_hold_node)
	return active_joint

func _clear_runtime_grip_joint(runtime_grip_joint: PinJoint2D) -> PinJoint2D:
	if runtime_grip_joint != null:
		runtime_grip_joint.queue_free()

	return null

func _sync_runtime_grip_link(
	hand_side: int,
	current_link: Line2D,
	hand_anchor: Marker2D,
	attachment_state: HandAttachmentStateScript,
	link_name: StringName
) -> Line2D:
	if not attachment_state.is_attached(hand_side):
		return _clear_runtime_grip_link(current_link)

	var hold_node: Node = _resolve_attached_hold_node(attachment_state.get_hold_path(hand_side))
	Validation.require_condition(hold_node != null, "PlayerCharacter runtime grip link requires an attached handhold node.")
	Validation.require_condition(hold_node is Node2D, "PlayerCharacter runtime grip link requires a Node2D handhold.")

	var active_link: Line2D = current_link
	if active_link == null:
		active_link = Line2D.new()
		active_link.name = link_name
		active_link.width = 4.0
		active_link.default_color = Color(0.72, 0.9, 1.0, 0.8)
		add_child(active_link)

	active_link.points = PackedVector2Array([
		to_local(attachment_state.get_attach_position(hand_side)),
		to_local(hand_anchor.global_position)
	])
	return active_link

func _clear_runtime_grip_link(runtime_grip_link: Line2D) -> Line2D:
	if runtime_grip_link != null:
		runtime_grip_link.queue_free()

	return null

func _resolve_attached_hold_node(hold_path: NodePath) -> Node:
	Validation.require_condition(not hold_path.is_empty(), "PlayerCharacter attached hold path cannot be empty.")

	var hold_node: Node = get_node_or_null(hold_path)
	if hold_node != null:
		return hold_node

	if get_parent() != null:
		return get_parent().get_node_or_null(hold_path)

	return null

func _assert_node_tree_has_no_physics_nodes(root: Node) -> void:
	Validation.require_condition(root != null, "Physics-neutral visual validation requires a root node.")
	Validation.require_condition(not root is CollisionObject2D, "Player visual roots cannot contain CollisionObject2D nodes.")
	Validation.require_condition(not root is CollisionShape2D, "Player visual roots cannot contain CollisionShape2D nodes.")

	for child in root.get_children():
		Validation.require_condition(child is Node, "Player visual root child must be a Node.")
		var child_node: Node = child
		_assert_node_tree_has_no_physics_nodes(child_node)