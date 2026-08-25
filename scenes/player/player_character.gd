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
# ponytail: measured from the CHR2 arm sprites' pixel content (opaque-pixel centroid of the
# shoulder half vs. the hand half of each cropped frame) rather than an exact art-authored
# value -- re-measure if the equipped arm art changes. The two are mirror images of each
# other (measured ~141.4 deg / ~38.6 deg), hence right = PI - left.
const LEFT_ARM_BONE_FORWARD_ANGLE_OFFSET_RADIANS: float = 2.4674
const RIGHT_ARM_BONE_FORWARD_ANGLE_OFFSET_RADIANS: float = PI - LEFT_ARM_BONE_FORWARD_ANGLE_OFFSET_RADIANS
const MIN_ARM_TARGET_DISTANCE_PIXELS: float = 4.0

# Head/LeftArm/RightArm all live on this layer and mask out everything except world
# geometry, so limbs never collide with each other. They cannot be kept off Torso by layer bits
# alone (Torso must stay on layer 1 so ChaserKillZone/hazard/pickup detection keeps working) --
# that exclusion is handled entirely by disable_collision=true on the 3 scene-authored PinJoint2D
# joints in player_character.tscn. Do not "simplify" this into a layer-only scheme.
const LIMB_COLLISION_LAYER: int = 32

# ponytail: per-limb mass values (scene-authored in player_character.tscn) are placeholder
# guesses with no prior precedent -- tune after playtesting how the ragdoll flops.

@export var climb_tuning: ClimbPrototypeTuningScript

var _torso: RigidBody2D
var _torso_collision_shape: CollisionShape2D
var _head_collision_shape: CollisionShape2D
var _left_arm_collision_shape: CollisionShape2D
var _right_arm_collision_shape: CollisionShape2D
var _torso_fitted_collision_polygons: Array[CollisionPolygon2D] = []
var _head_fitted_collision_polygons: Array[CollisionPolygon2D] = []
var _left_arm_fitted_collision_polygons: Array[CollisionPolygon2D] = []
var _right_arm_fitted_collision_polygons: Array[CollisionPolygon2D] = []
var _left_shoulder_socket: Marker2D
var _right_shoulder_socket: Marker2D
var _left_hand_anchor: Marker2D
var _right_hand_anchor: Marker2D
var _left_hand_visual_anchor: Marker2D
var _right_hand_visual_anchor: Marker2D
var _neck_socket: Marker2D
var _torso_head_joint: PinJoint2D
var _torso_left_arm_joint: PinJoint2D
var _torso_right_arm_joint: PinJoint2D
var _visual_root: Node2D
var _cosmetic_visual_root: Node2D
var _player_visual: Polygon2D
var _body_visual_sprite: Sprite2D

var _head: RigidBody2D
var _head_visual_root: Node2D
var _face_overlay: Sprite2D

var _left_arm: RigidBody2D
var _left_arm_visual_root: Node2D
var _left_arm_visual: Sprite2D
var _left_hand_cosmetic_root: Node2D

var _right_arm: RigidBody2D
var _right_arm_visual_root: Node2D
var _right_arm_visual: Sprite2D
var _right_hand_cosmetic_root: Node2D

var _left_grip_joint_anchor: Marker2D
var _right_grip_joint_anchor: Marker2D
var _left_runtime_grip_joint: PinJoint2D = null
var _right_runtime_grip_joint: PinJoint2D = null
var _left_runtime_grip_link: Line2D = null
var _right_runtime_grip_link: Line2D = null
var _debug_anchors: Node2D

var _hand_visual_follow_controller: HandVisualFollowControllerScript
var _motion_controller: PlayerMotionControllerScript
var _left_hand_visual_offset_from_reach: Vector2 = Vector2.ZERO
var _right_hand_visual_offset_from_reach: Vector2 = Vector2.ZERO
var _physics_mode: int = 0
var _reset_body_rotation: float = 0.0

func _ready() -> void:
	_validate_required_state()
	set_physics_process(true)
	_reset_body_rotation = _torso.rotation
	_hand_visual_follow_controller = HandVisualFollowControllerScript.new(climb_tuning)
	_motion_controller = PlayerMotionControllerScript.new(climb_tuning)
	_capture_hand_visual_offsets()
	_reset_hand_visual_anchors()
	_physics_mode = PlayerPhysicsModeScript.controlled_climb()
	_sync_torso_collision_mask_for_mode()
	_sync_limb_freeze_for_mode()
	_sync_kinematic_limb_pose()

func _physics_process(delta: float) -> void:
	Validation.require_condition(_hand_visual_follow_controller != null, "PlayerCharacter requires a hand visual follow controller.")
	_sync_hand_visual_anchors(delta)
	if _physics_mode == PlayerPhysicsModeScript.controlled_climb():
		_sync_kinematic_limb_pose()

func set_climb_tuning(tuning: Resource) -> void:
	Validation.require_condition(tuning != null, "PlayerCharacter requires climb tuning.")
	Validation.require_condition(tuning is ClimbPrototypeTuningScript, "PlayerCharacter requires climb prototype tuning implementation.")

	climb_tuning = tuning
	climb_tuning.assert_valid()
	_hand_visual_follow_controller = HandVisualFollowControllerScript.new(climb_tuning)
	_motion_controller = PlayerMotionControllerScript.new(climb_tuning)
	if is_node_ready():
		_reset_hand_visual_anchors()
		if _physics_mode == PlayerPhysicsModeScript.controlled_climb():
			_sync_kinematic_limb_pose()

func apply_frame_motion(frame_result: RefCounted, attachment_state: RefCounted) -> void:
	Validation.require_condition(frame_result != null, "PlayerCharacter requires a frame result.")
	Validation.require_condition(frame_result is ClimbPrototypeFrameResultScript, "PlayerCharacter requires a ClimbPrototypeFrameResult.")
	Validation.require_condition(attachment_state != null, "PlayerCharacter requires hand attachment state.")
	Validation.require_condition(attachment_state is HandAttachmentStateScript, "PlayerCharacter requires HandAttachmentState.")
	Validation.require_condition(_motion_controller != null, "PlayerCharacter requires a motion controller.")

	var typed_attachment_state: HandAttachmentStateScript = attachment_state

	_physics_mode = PlayerPhysicsModeTransitionsScript.mode_after_frame(_physics_mode, frame_result)
	_sync_torso_collision_mask_for_mode()
	_sync_limb_freeze_for_mode()
	if _physics_mode != PlayerPhysicsModeScript.controlled_climb():
		clear_runtime_grip_joints()
		clear_runtime_grip_links()
		return

	sync_runtime_grip_joints(typed_attachment_state)
	sync_runtime_grip_links(typed_attachment_state)
	_motion_controller.apply_frame_motion(_torso, typed_attachment_state, frame_result)
	_sync_kinematic_limb_pose()

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
	_sync_torso_collision_mask_for_mode()
	_sync_limb_freeze_for_mode()
	clear_runtime_grip_joints()
	clear_runtime_grip_links()

func reset_physics(global_position_value: Vector2) -> void:
	_physics_mode = PlayerPhysicsModeTransitionsScript.reset_mode(_physics_mode)
	clear_runtime_grip_joints()
	clear_runtime_grip_links()
	_torso.global_position = global_position_value
	_torso.rotation = _reset_body_rotation
	_torso.linear_velocity = Vector2.ZERO
	_torso.angular_velocity = 0.0
	_sync_torso_collision_mask_for_mode()
	_sync_limb_freeze_for_mode()
	_sync_kinematic_limb_pose()
	_reset_hand_visual_anchors()

func get_physics_mode() -> int:
	return _physics_mode

func get_player_body() -> RigidBody2D:
	return _torso

func get_head_body() -> RigidBody2D:
	return _head

func get_left_arm_body() -> RigidBody2D:
	return _left_arm

func get_right_arm_body() -> RigidBody2D:
	return _right_arm

func get_body_global_position() -> Vector2:
	return _torso.global_position

func set_body_global_position(global_position_value: Vector2) -> void:
	_torso.global_position = global_position_value

func get_body_linear_velocity() -> Vector2:
	return _torso.linear_velocity

func set_body_linear_velocity(linear_velocity_value: Vector2) -> void:
	_torso.linear_velocity = linear_velocity_value

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

func get_player_visual() -> Polygon2D:
	return _player_visual

func get_body_visual_sprite() -> Sprite2D:
	return _body_visual_sprite

func get_face_overlay() -> Sprite2D:
	return _face_overlay

func get_left_arm_visual() -> Sprite2D:
	return _left_arm_visual

func get_right_arm_visual() -> Sprite2D:
	return _right_arm_visual

func get_torso_collision_shape() -> CollisionShape2D:
	return _torso_collision_shape

func get_head_collision_shape() -> CollisionShape2D:
	return _head_collision_shape

func get_left_arm_collision_shape() -> CollisionShape2D:
	return _left_arm_collision_shape

func get_right_arm_collision_shape() -> CollisionShape2D:
	return _right_arm_collision_shape

func get_torso_fitted_collision_polygons() -> Array[CollisionPolygon2D]:
	return _torso_fitted_collision_polygons

func get_head_fitted_collision_polygons() -> Array[CollisionPolygon2D]:
	return _head_fitted_collision_polygons

func get_left_arm_fitted_collision_polygons() -> Array[CollisionPolygon2D]:
	return _left_arm_fitted_collision_polygons

func get_right_arm_fitted_collision_polygons() -> Array[CollisionPolygon2D]:
	return _right_arm_fitted_collision_polygons

func configure_torso_collision_capsule(radius: float, height: float, collision_offset: Vector2) -> void:
	_configure_capsule_shape(_torso_collision_shape, "Torso", radius, height, collision_offset)

func configure_arm_collision_capsule(hand_side: int, radius: float, height: float, collision_offset: Vector2) -> void:
	if hand_side == HandSideScript.Value.LEFT:
		_configure_capsule_shape(_left_arm_collision_shape, "LeftArm", radius, height, collision_offset)
		return
	_configure_capsule_shape(_right_arm_collision_shape, "RightArm", radius, height, collision_offset)

func configure_head_collision_circle(radius: float, collision_offset: Vector2) -> void:
	Validation.require_condition(radius > 0.0, "PlayerCharacter head collision circle radius must be positive.")
	Validation.require_condition(_head_collision_shape != null, "PlayerCharacter requires HeadCollisionShape before configuring the circle.")
	Validation.require_condition(_head_collision_shape.shape != null, "PlayerCharacter requires HeadCollisionShape to have a shape before configuring the circle.")
	Validation.require_condition(_head_collision_shape.shape is CircleShape2D, "PlayerCharacter head collision shape must remain a CircleShape2D.")

	var duplicated_shape: Resource = _head_collision_shape.shape.duplicate()
	Validation.require_condition(duplicated_shape is CircleShape2D, "PlayerCharacter failed to duplicate the head collision circle.")
	var circle_shape: CircleShape2D = duplicated_shape as CircleShape2D
	circle_shape.radius = radius
	_head_collision_shape.shape = circle_shape
	_head_collision_shape.position = collision_offset

# Pixel-silhouette collision: N convex CollisionPolygon2D children replace the fallback
# primitive shape (disabled, not removed -- it's the always-valid state before any appearance
# is applied, and stays the shape used by the cutout appearance path). Godot's dynamic
# RigidBody2D physics doesn't support a single concave shape correctly (no well-defined
# "inside"), so a traced silhouette must arrive pre-decomposed into convex pieces -- this
# only assembles what PlayerAppearanceApplicator hands it, it doesn't do the tracing itself.
func configure_torso_collision_polygons(local_polygons: Array[PackedVector2Array]) -> void:
	_torso_fitted_collision_polygons = _configure_collision_polygons(_torso, _torso_collision_shape, _torso_fitted_collision_polygons, "Torso", local_polygons)

func configure_head_collision_polygons(local_polygons: Array[PackedVector2Array]) -> void:
	_head_fitted_collision_polygons = _configure_collision_polygons(_head, _head_collision_shape, _head_fitted_collision_polygons, "Head", local_polygons)

func configure_arm_collision_polygons(hand_side: int, local_polygons: Array[PackedVector2Array]) -> void:
	if hand_side == HandSideScript.Value.LEFT:
		_left_arm_fitted_collision_polygons = _configure_collision_polygons(_left_arm, _left_arm_collision_shape, _left_arm_fitted_collision_polygons, "LeftArm", local_polygons)
		return
	_right_arm_fitted_collision_polygons = _configure_collision_polygons(_right_arm, _right_arm_collision_shape, _right_arm_fitted_collision_polygons, "RightArm", local_polygons)

func _configure_collision_polygons(body: RigidBody2D, fallback_shape: CollisionShape2D, existing_polygons: Array[CollisionPolygon2D], label: String, local_polygons: Array[PackedVector2Array]) -> Array[CollisionPolygon2D]:
	Validation.require_condition(body != null, "PlayerCharacter requires a %s body before configuring fitted collision polygons." % label)
	Validation.require_condition(fallback_shape != null, "PlayerCharacter requires a %s fallback collision shape before configuring fitted collision polygons." % label)
	Validation.require_condition(not local_polygons.is_empty(), "PlayerCharacter requires at least one %s collision polygon." % label)

	for existing_polygon in existing_polygons:
		existing_polygon.queue_free()

	var created_polygons: Array[CollisionPolygon2D] = []
	for polygon_points in local_polygons:
		Validation.require_condition(polygon_points.size() >= 3, "PlayerCharacter %s collision polygon requires at least 3 points." % label)
		var polygon_node := CollisionPolygon2D.new()
		polygon_node.name = "%sFittedCollisionPolygon%d" % [label, created_polygons.size()]
		polygon_node.polygon = polygon_points
		body.add_child(polygon_node)
		created_polygons.append(polygon_node)

	fallback_shape.disabled = true
	return created_polygons

func _configure_capsule_shape(shape_node: CollisionShape2D, label: String, radius: float, height: float, collision_offset: Vector2) -> void:
	Validation.require_condition(radius > 0.0, "PlayerCharacter %s collision capsule radius must be positive." % label)
	Validation.require_condition(height >= 0.0, "PlayerCharacter %s collision capsule height cannot be negative." % label)
	Validation.require_condition(shape_node != null, "PlayerCharacter requires %s collision shape before configuring the capsule." % label)
	Validation.require_condition(shape_node.shape != null, "PlayerCharacter requires %s collision shape to have a shape before configuring the capsule." % label)
	Validation.require_condition(shape_node.shape is CapsuleShape2D, "PlayerCharacter %s collision shape must remain a CapsuleShape2D." % label)

	var duplicated_shape: Resource = shape_node.shape.duplicate()
	Validation.require_condition(duplicated_shape is CapsuleShape2D, "PlayerCharacter failed to duplicate the %s collision capsule." % label)
	var capsule_shape: CapsuleShape2D = duplicated_shape as CapsuleShape2D
	capsule_shape.radius = radius
	capsule_shape.height = height
	shape_node.shape = capsule_shape
	shape_node.position = collision_offset

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
	_assert_node_tree_has_no_physics_nodes(_head_visual_root)
	_assert_node_tree_has_no_physics_nodes(_left_arm_visual_root)
	_assert_node_tree_has_no_physics_nodes(_left_hand_cosmetic_root)
	_assert_node_tree_has_no_physics_nodes(_right_arm_visual_root)
	_assert_node_tree_has_no_physics_nodes(_right_hand_cosmetic_root)

func _sync_torso_collision_mask_for_mode() -> void:
	Validation.require_condition(_torso != null, "PlayerCharacter requires Torso before syncing collision masks.")
	if _physics_mode == PlayerPhysicsModeScript.falling_ragdoll():
		_torso.collision_mask = FALLING_COLLISION_MASK
		return

	_torso.collision_mask = CONTROLLED_COLLISION_MASK

func _sync_limb_freeze_for_mode() -> void:
	Validation.require_condition(_head != null and _left_arm != null and _right_arm != null, "PlayerCharacter requires all limb bodies before syncing freeze state.")

	if _physics_mode == PlayerPhysicsModeScript.controlled_climb():
		_head.freeze = true
		_left_arm.freeze = true
		_right_arm.freeze = true
		# The torso<->limb joints must stay disabled while limbs are kinematically posed:
		# a joint between dynamic Torso and a limb that mirrors Torso's own position every
		# frame constrains Torso to match a body that is, by construction, always wherever
		# Torso just was -- pinning Torso in place and cancelling any grip/swing force. The
		# joints only matter once limbs are real dynamic ragdoll bodies (falling).
		_set_limb_joints_enabled(false)
		return

	if _head.freeze:
		_unfreeze_limb_with_torso_velocity(_head)
		_unfreeze_limb_with_torso_velocity(_left_arm)
		_unfreeze_limb_with_torso_velocity(_right_arm)

	_set_limb_joints_enabled(true)

func _unfreeze_limb_with_torso_velocity(limb_body: RigidBody2D) -> void:
	# enter_falling() can run from an Area2D body_entered signal (chaser/hazard contact),
	# which fires mid physics-step while Godot is flushing collision queries. A direct
	# `.freeze = false` calls PhysicsServer2D.body_set_mode() synchronously and Godot
	# rejects that mid-flush, silently leaving the limb kinematic forever. Deferring is
	# the fix Godot's own error message points at.
	limb_body.set_deferred(&"freeze", false)
	limb_body.linear_velocity = _torso.linear_velocity
	limb_body.angular_velocity = _torso.angular_velocity

func _set_limb_joints_enabled(enabled: bool) -> void:
	_set_torso_limb_joint_enabled(_torso_head_joint, _head, enabled)
	_set_torso_limb_joint_enabled(_torso_left_arm_joint, _left_arm, enabled)
	_set_torso_limb_joint_enabled(_torso_right_arm_joint, _right_arm, enabled)

func _set_torso_limb_joint_enabled(joint: PinJoint2D, limb_body: RigidBody2D, enabled: bool) -> void:
	if not enabled:
		joint.node_a = NodePath()
		joint.node_b = NodePath()
		return

	joint.node_a = joint.get_path_to(_torso)
	joint.node_b = joint.get_path_to(limb_body)

func _validate_required_state() -> void:
	Validation.require_condition(climb_tuning != null, "PlayerCharacter requires climb tuning.")
	climb_tuning.assert_valid()

	_torso = _require_rigid_body_2d("Torso", "PlayerCharacter requires Torso.")
	_torso_collision_shape = _require_collision_shape_2d("Torso/TorsoCollisionShape", "PlayerCharacter requires TorsoCollisionShape.")
	_left_shoulder_socket = _require_marker_2d("Torso/LeftShoulderSocket", "PlayerCharacter requires LeftShoulderSocket.")
	_right_shoulder_socket = _require_marker_2d("Torso/RightShoulderSocket", "PlayerCharacter requires RightShoulderSocket.")
	_left_hand_anchor = _require_marker_2d("Torso/LeftShoulderSocket/LeftHandAnchor", "PlayerCharacter requires LeftHandAnchor.")
	_right_hand_anchor = _require_marker_2d("Torso/RightShoulderSocket/RightHandAnchor", "PlayerCharacter requires RightHandAnchor.")
	_left_hand_visual_anchor = _require_marker_2d("Torso/LeftShoulderSocket/LeftHandVisualAnchor", "PlayerCharacter requires LeftHandVisualAnchor.")
	_right_hand_visual_anchor = _require_marker_2d("Torso/RightShoulderSocket/RightHandVisualAnchor", "PlayerCharacter requires RightHandVisualAnchor.")
	_neck_socket = _require_marker_2d("Torso/NeckSocket", "PlayerCharacter requires NeckSocket.")
	_torso_head_joint = _require_pin_joint_2d("Torso/NeckSocket/TorsoHeadJoint", "PlayerCharacter requires TorsoHeadJoint.")
	_torso_left_arm_joint = _require_pin_joint_2d("Torso/LeftShoulderSocket/TorsoLeftArmJoint", "PlayerCharacter requires TorsoLeftArmJoint.")
	_torso_right_arm_joint = _require_pin_joint_2d("Torso/RightShoulderSocket/TorsoRightArmJoint", "PlayerCharacter requires TorsoRightArmJoint.")
	_visual_root = _require_node_2d("Torso/VisualRoot", "PlayerCharacter requires VisualRoot.")
	_cosmetic_visual_root = _require_node_2d("Torso/VisualRoot/CosmeticVisualRoot", "PlayerCharacter requires CosmeticVisualRoot.")
	_player_visual = _require_polygon_2d("Torso/VisualRoot/PlayerVisual", "PlayerCharacter requires PlayerVisual.")
	_body_visual_sprite = _require_sprite_2d("Torso/VisualRoot/BodyVisualSprite", "PlayerCharacter requires BodyVisualSprite.")

	_head = _require_rigid_body_2d("Head", "PlayerCharacter requires Head.")
	_head_collision_shape = _require_collision_shape_2d("Head/HeadCollisionShape", "PlayerCharacter requires HeadCollisionShape.")
	_head_visual_root = _require_node_2d("Head/HeadVisualRoot", "PlayerCharacter requires HeadVisualRoot.")
	_face_overlay = _require_sprite_2d("Head/HeadVisualRoot/FaceOverlay", "PlayerCharacter requires FaceOverlay.")

	_left_arm = _require_rigid_body_2d("LeftArm", "PlayerCharacter requires LeftArm.")
	_left_arm_collision_shape = _require_collision_shape_2d("LeftArm/LeftArmCollisionShape", "PlayerCharacter requires LeftArmCollisionShape.")
	_left_arm_visual_root = _require_node_2d("LeftArm/LeftArmVisualRoot", "PlayerCharacter requires LeftArmVisualRoot.")
	_left_arm_visual = _require_sprite_2d("LeftArm/LeftArmVisualRoot/LeftArmVisual", "PlayerCharacter requires LeftArmVisual.")
	_left_hand_cosmetic_root = _require_node_2d("LeftArm/LeftHandCosmeticRoot", "PlayerCharacter requires LeftHandCosmeticRoot.")

	_right_arm = _require_rigid_body_2d("RightArm", "PlayerCharacter requires RightArm.")
	_right_arm_collision_shape = _require_collision_shape_2d("RightArm/RightArmCollisionShape", "PlayerCharacter requires RightArmCollisionShape.")
	_right_arm_visual_root = _require_node_2d("RightArm/RightArmVisualRoot", "PlayerCharacter requires RightArmVisualRoot.")
	_right_arm_visual = _require_sprite_2d("RightArm/RightArmVisualRoot/RightArmVisual", "PlayerCharacter requires RightArmVisual.")
	_right_hand_cosmetic_root = _require_node_2d("RightArm/RightHandCosmeticRoot", "PlayerCharacter requires RightHandCosmeticRoot.")

	_left_grip_joint_anchor = _require_marker_2d("GripJoints/LeftGripJointAnchor", "PlayerCharacter requires LeftGripJointAnchor.")
	_right_grip_joint_anchor = _require_marker_2d("GripJoints/RightGripJointAnchor", "PlayerCharacter requires RightGripJointAnchor.")
	_debug_anchors = _require_node_2d("DebugAnchors", "PlayerCharacter requires DebugAnchors.")

	Validation.require_condition(_torso_collision_shape.shape != null, "PlayerCharacter TorsoCollisionShape requires a shape.")
	Validation.require_condition(_torso_collision_shape.get_parent() == _torso, "PlayerCharacter gameplay collision must belong to Torso.")
	Validation.require_condition(_left_shoulder_socket.get_parent() == _torso, "PlayerCharacter LeftShoulderSocket must belong to Torso.")
	Validation.require_condition(_right_shoulder_socket.get_parent() == _torso, "PlayerCharacter RightShoulderSocket must belong to Torso.")
	Validation.require_condition(_left_hand_anchor.get_parent() == _left_shoulder_socket, "PlayerCharacter LeftHandAnchor must belong to LeftShoulderSocket.")
	Validation.require_condition(_right_hand_anchor.get_parent() == _right_shoulder_socket, "PlayerCharacter RightHandAnchor must belong to RightShoulderSocket.")
	Validation.require_condition(_left_hand_visual_anchor.get_parent() == _left_shoulder_socket, "PlayerCharacter LeftHandVisualAnchor must belong to LeftShoulderSocket.")
	Validation.require_condition(_right_hand_visual_anchor.get_parent() == _right_shoulder_socket, "PlayerCharacter RightHandVisualAnchor must belong to RightShoulderSocket.")
	Validation.require_condition(_neck_socket.get_parent() == _torso, "PlayerCharacter NeckSocket must belong to Torso.")
	Validation.require_condition(_player_visual.get_parent() == _visual_root, "PlayerCharacter PlayerVisual must belong to VisualRoot.")
	Validation.require_condition(_body_visual_sprite.get_parent() == _visual_root, "PlayerCharacter BodyVisualSprite must belong to VisualRoot.")
	Validation.require_condition(_head_collision_shape.get_parent() == _head, "PlayerCharacter HeadCollisionShape must belong to Head.")
	Validation.require_condition(_face_overlay.get_parent() == _head_visual_root, "PlayerCharacter FaceOverlay must belong to HeadVisualRoot.")
	Validation.require_condition(_left_arm_collision_shape.get_parent() == _left_arm, "PlayerCharacter LeftArmCollisionShape must belong to LeftArm.")
	Validation.require_condition(_left_arm_visual.get_parent() == _left_arm_visual_root, "PlayerCharacter LeftArmVisual must belong to LeftArmVisualRoot.")
	Validation.require_condition(_left_hand_cosmetic_root.get_parent() == _left_arm, "PlayerCharacter LeftHandCosmeticRoot must belong to LeftArm.")
	Validation.require_condition(_right_arm_collision_shape.get_parent() == _right_arm, "PlayerCharacter RightArmCollisionShape must belong to RightArm.")
	Validation.require_condition(_right_arm_visual.get_parent() == _right_arm_visual_root, "PlayerCharacter RightArmVisual must belong to RightArmVisualRoot.")
	Validation.require_condition(_right_hand_cosmetic_root.get_parent() == _right_arm, "PlayerCharacter RightHandCosmeticRoot must belong to RightArm.")

	Validation.require_condition(_head.collision_layer == LIMB_COLLISION_LAYER, "PlayerCharacter Head must be on the ragdoll limb collision layer.")
	Validation.require_condition(_left_arm.collision_layer == LIMB_COLLISION_LAYER, "PlayerCharacter LeftArm must be on the ragdoll limb collision layer.")
	Validation.require_condition(_right_arm.collision_layer == LIMB_COLLISION_LAYER, "PlayerCharacter RightArm must be on the ragdoll limb collision layer.")
	Validation.require_condition(_head.freeze_mode == RigidBody2D.FREEZE_MODE_KINEMATIC, "PlayerCharacter Head must use kinematic freeze mode.")
	Validation.require_condition(_left_arm.freeze_mode == RigidBody2D.FREEZE_MODE_KINEMATIC, "PlayerCharacter LeftArm must use kinematic freeze mode.")
	Validation.require_condition(_right_arm.freeze_mode == RigidBody2D.FREEZE_MODE_KINEMATIC, "PlayerCharacter RightArm must use kinematic freeze mode.")

	assert_visual_roots_physics_neutral()

func _capture_hand_visual_offsets() -> void:
	_left_hand_visual_offset_from_reach = _left_hand_visual_anchor.position - _left_hand_anchor.position
	_right_hand_visual_offset_from_reach = _right_hand_visual_anchor.position - _right_hand_anchor.position

func _reset_hand_visual_anchors() -> void:
	_left_hand_visual_anchor.position = _left_hand_anchor.position + _left_hand_visual_offset_from_reach
	_right_hand_visual_anchor.position = _right_hand_anchor.position + _right_hand_visual_offset_from_reach

func _sync_hand_visual_anchors(delta: float) -> void:
	var body_local_velocity: Vector2 = _torso.to_local(_torso.global_position + _torso.linear_velocity)
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

func _sync_kinematic_limb_pose() -> void:
	_sync_idle_rest_limb_pose()
	if _left_runtime_grip_joint != null:
		_sync_arm_kinematic_pose_toward_target(_left_arm, _left_shoulder_socket, _left_runtime_grip_joint.global_position, LEFT_ARM_BONE_FORWARD_ANGLE_OFFSET_RADIANS)
	if _right_runtime_grip_joint != null:
		_sync_arm_kinematic_pose_toward_target(_right_arm, _right_shoulder_socket, _right_runtime_grip_joint.global_position, RIGHT_ARM_BONE_FORWARD_ANGLE_OFFSET_RADIANS)
	_sync_head_kinematic_pose()

func _sync_idle_rest_limb_pose() -> void:
	if _left_runtime_grip_joint == null:
		_left_arm.global_position = _left_shoulder_socket.global_position
		_left_arm.global_rotation = _torso.global_rotation
	if _right_runtime_grip_joint == null:
		_right_arm.global_position = _right_shoulder_socket.global_position
		_right_arm.global_rotation = _torso.global_rotation

func _sync_arm_kinematic_pose_toward_target(arm_body: RigidBody2D, shoulder_socket: Marker2D, target_global_position: Vector2, bone_forward_angle_offset_radians: float) -> void:
	Validation.require_condition(arm_body != null, "PlayerCharacter requires an arm body to sync attached pose.")
	Validation.require_condition(shoulder_socket != null, "PlayerCharacter requires a shoulder socket to sync attached pose.")

	var target_vector: Vector2 = target_global_position - shoulder_socket.global_position
	var target_distance: float = target_vector.length()
	var target_direction: Vector2 = Vector2.DOWN if target_distance <= MIN_ARM_TARGET_DISTANCE_PIXELS else target_vector / target_distance
	var arm_global_angle: float = target_direction.angle() - bone_forward_angle_offset_radians

	arm_body.global_position = shoulder_socket.global_position
	arm_body.global_rotation = arm_global_angle

func _sync_head_kinematic_pose() -> void:
	_head.global_position = _neck_socket.global_position
	_head.global_rotation = _torso.global_rotation

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

func _require_sprite_2d(node_path: NodePath, message: String) -> Sprite2D:
	var node: Node = get_node_or_null(node_path)
	Validation.require_condition(node != null, message)
	Validation.require_condition(node is Sprite2D, "%s Expected Sprite2D." % message)
	return node as Sprite2D

func _require_polygon_2d(node_path: NodePath, message: String) -> Polygon2D:
	var node: Node = get_node_or_null(node_path)
	Validation.require_condition(node != null, message)
	Validation.require_condition(node is Polygon2D, "%s Expected Polygon2D." % message)
	return node as Polygon2D

func _require_pin_joint_2d(node_path: NodePath, message: String) -> PinJoint2D:
	var node: Node = get_node_or_null(node_path)
	Validation.require_condition(node != null, message)
	Validation.require_condition(node is PinJoint2D, "%s Expected PinJoint2D." % message)
	var joint: PinJoint2D = node as PinJoint2D
	Validation.require_condition(joint.disable_collision, "%s PinJoint2D must disable collision between Torso and its limb." % message)
	return joint

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
	active_joint.node_a = active_joint.get_path_to(_torso)
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
