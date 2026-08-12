extends GutTest

const ClimbPrototypeFrameResultScript = preload("res://src/gameplay/player/climb_prototype_frame_result.gd")
const HandAttachmentStateScript = preload("res://src/gameplay/player/hand_attachment_state.gd")
const HandSideScript = preload("res://src/gameplay/player/hand_side.gd")
const CosmeticItemCatalogScript = preload("res://resources/config/cosmetic_item_catalog.gd")
const CosmeticLoadoutScript = preload("res://resources/config/cosmetic_loadout.gd")
const PlayerAppearanceScript = preload("res://resources/config/player_appearance.gd")
const PlayerAppearanceCatalogScript = preload("res://resources/config/player_appearance_catalog.gd")
const PlayerAppearanceApplicatorScript = preload("res://src/cosmetics/player_appearance_applicator.gd")
const PlayerCharacterScript = preload("res://scenes/player/player_character.gd")
const PlayerPhysicsModeScript = preload("res://src/gameplay/player/player_physics_mode.gd")
const PlayerCosmeticApplicatorScript = preload("res://src/cosmetics/player_cosmetic_applicator.gd")

func test_player_character_scene_wires_required_nodes() -> void:
    var player: PlayerCharacterScript = await _instantiate_player()

    assert_not_null(player.get_node_or_null("BaseSkeleton"))
    assert_not_null(player.get_node_or_null("BaseSkeleton/TorsoBone"))
    assert_not_null(player.get_visual_skeleton())
    assert_not_null(player.get_node_or_null("BaseSkeleton/PlayerBody/VisualRoot/BodyVisualSprite"))
    assert_not_null(player.get_node_or_null("BaseSkeleton/PlayerBody/VisualRoot/FaceOverlay"))
    assert_not_null(player.get_node_or_null("BaseSkeleton/PlayerBody/VisualRoot/VisualSkeleton/LeftUpperArmBone"))
    assert_not_null(player.get_node_or_null("BaseSkeleton/PlayerBody/VisualRoot/VisualSkeleton/LeftUpperArmBone/LeftForearmBone"))
    assert_not_null(player.get_left_hand_bone())
    assert_not_null(player.get_node_or_null("BaseSkeleton/PlayerBody/VisualRoot/VisualSkeleton/RightUpperArmBone"))
    assert_not_null(player.get_node_or_null("BaseSkeleton/PlayerBody/VisualRoot/VisualSkeleton/RightUpperArmBone/RightForearmBone"))
    assert_not_null(player.get_right_hand_bone())
    assert_not_null(player.get_node_or_null("BaseSkeleton/PlayerBody/VisualRoot/VisualSkeleton/LowerBodyBone"))
    assert_not_null(player.get_node_or_null("BaseSkeleton/PlayerBody/VisualRoot/VisualSkeleton/LowerBodyBone/LowerBodyVisual"))
    assert_not_null(player.get_player_body())
    assert_not_null(player.get_body_collision_shape())
    assert_not_null(player.get_left_shoulder_socket())
    assert_not_null(player.get_right_shoulder_socket())
    assert_not_null(player.get_left_hand_anchor())
    assert_not_null(player.get_right_hand_anchor())
    assert_not_null(player.get_left_hand_visual_anchor())
    assert_not_null(player.get_right_hand_visual_anchor())
    assert_not_null(player.get_left_hand_cosmetic_root())
    assert_not_null(player.get_right_hand_cosmetic_root())
    assert_not_null(player.get_left_grip_joint_anchor())
    assert_not_null(player.get_right_grip_joint_anchor())
    assert_not_null(player.get_node_or_null("DebugAnchors"))
    assert_not_null(player.get_visual_root())
    assert_not_null(player.get_cosmetic_visual_root())

func test_player_character_owns_gameplay_collision_under_base_skeleton_body() -> void:
    var player: PlayerCharacterScript = await _instantiate_player()
    var body: RigidBody2D = player.get_player_body()
    var collision_shape: CollisionShape2D = player.get_body_collision_shape()

    assert_true(body.get_parent() is Skeleton2D)
    assert_eq(collision_shape.get_parent(), body)
    assert_not_null(collision_shape.shape)
    assert_true(collision_shape.shape is CapsuleShape2D)

func test_player_character_visual_roots_are_physics_neutral() -> void:
    var player: PlayerCharacterScript = await _instantiate_player()
    var body: RigidBody2D = player.get_player_body()
    var starting_mass: float = body.mass
    var starting_collision_layer: int = body.collision_layer
    var starting_collision_mask: int = body.collision_mask
    var starting_collision_shape: Shape2D = player.get_body_collision_shape().shape

    var extra_visual := Polygon2D.new()
    extra_visual.name = &"TestCosmeticVisual"
    extra_visual.polygon = PackedVector2Array([Vector2.ZERO, Vector2.RIGHT, Vector2.DOWN])
    player.get_cosmetic_visual_root().add_child(extra_visual)

    player.assert_visual_roots_physics_neutral()

    assert_eq(body.mass, starting_mass)
    assert_eq(body.collision_layer, starting_collision_layer)
    assert_eq(body.collision_mask, starting_collision_mask)
    assert_eq(player.get_body_collision_shape().shape, starting_collision_shape)

func test_player_character_hand_geometry_separates_reach_and_visual_anchors() -> void:
    var player: PlayerCharacterScript = await _instantiate_player()
    var left_placeholder: Node2D = player.get_node("BaseSkeleton/PlayerBody/VisualRoot/VisualSkeleton/LeftUpperArmBone/LeftForearmBone/LeftHandBone/LeftHandCosmeticRoot/LeftHandVisual") as Node2D
    var right_placeholder: Node2D = player.get_node("BaseSkeleton/PlayerBody/VisualRoot/VisualSkeleton/RightUpperArmBone/RightForearmBone/RightHandBone/RightHandCosmeticRoot/RightHandVisual") as Node2D

    assert_eq(player.get_left_hand_anchor().get_parent(), player.get_left_shoulder_socket())
    assert_eq(player.get_right_hand_anchor().get_parent(), player.get_right_shoulder_socket())
    assert_eq(player.get_left_hand_visual_anchor().get_parent(), player.get_left_shoulder_socket())
    assert_eq(player.get_right_hand_visual_anchor().get_parent(), player.get_right_shoulder_socket())
    assert_eq(player.get_left_hand_cosmetic_root().get_parent(), player.get_left_hand_bone())
    assert_eq(player.get_right_hand_cosmetic_root().get_parent(), player.get_right_hand_bone())
    assert_not_null(left_placeholder)
    assert_not_null(right_placeholder)
    assert_eq(left_placeholder.get_parent(), player.get_left_hand_cosmetic_root())
    assert_eq(right_placeholder.get_parent(), player.get_right_hand_cosmetic_root())
    assert_ne(player.get_left_hand_anchor().position, player.get_left_hand_visual_anchor().position)
    assert_ne(player.get_right_hand_anchor().position, player.get_right_hand_visual_anchor().position)

    var left_visual := Polygon2D.new()
    left_visual.name = &"LeftHandCosmeticTest"
    left_visual.polygon = PackedVector2Array([Vector2.ZERO, Vector2.RIGHT, Vector2.DOWN])
    player.get_left_hand_cosmetic_root().add_child(left_visual)

    var right_visual := Polygon2D.new()
    right_visual.name = &"RightHandCosmeticTest"
    right_visual.polygon = PackedVector2Array([Vector2.ZERO, Vector2.LEFT, Vector2.DOWN])
    player.get_right_hand_cosmetic_root().add_child(right_visual)

    player.assert_visual_roots_physics_neutral()

func test_player_character_visual_hand_anchors_lag_behind_body_velocity() -> void:
    var player: PlayerCharacterScript = await _instantiate_player()
    var left_visual_anchor: Marker2D = player.get_left_hand_visual_anchor()
    var starting_position: Vector2 = left_visual_anchor.position

    player.set_body_linear_velocity(Vector2(300.0, 0.0))
    player._physics_process(1.0 / 60.0)

    var lagged_position: Vector2 = left_visual_anchor.position

    assert_lt(lagged_position.x, starting_position.x)
    assert_eq(lagged_position.y, starting_position.y)

    player.set_body_linear_velocity(Vector2.ZERO)
    player._physics_process(1.0 / 60.0)

    assert_gt(left_visual_anchor.position.x, lagged_position.x)

func test_player_character_attached_visual_hand_biases_toward_hold() -> void:
    var player: PlayerCharacterScript = await _instantiate_player()
    var hold: StaticBody2D = _create_hold(&"LeftHold", Vector2(180.0, 260.0))
    var attachment_state := HandAttachmentStateScript.new()
    var left_visual_anchor: Marker2D = player.get_left_hand_visual_anchor()
    var starting_distance_to_hold: float = left_visual_anchor.global_position.distance_to(hold.global_position)

    attachment_state.attach(HandSideScript.Value.LEFT, &"left_hold", hold.global_position, hold.get_path())
    player.apply_frame_motion(ClimbPrototypeFrameResultScript.new(Vector2.ZERO, false, 1), attachment_state)
    player._physics_process(1.0 / 60.0)

    assert_lt(left_visual_anchor.global_position.distance_to(hold.global_position), starting_distance_to_hold)

func test_player_character_visual_arm_bones_follow_hand_targets() -> void:
    var player: PlayerCharacterScript = await _instantiate_player()
    var left_hand_bone: Bone2D = player.get_left_hand_bone()
    var starting_position: Vector2 = left_hand_bone.global_position

    player.set_body_linear_velocity(Vector2(300.0, 0.0))
    player._physics_process(1.0 / 60.0)

    assert_eq(left_hand_bone.global_position, starting_position)

func test_player_character_unattached_motion_keeps_rest_pose() -> void:
    var player: PlayerCharacterScript = await _instantiate_player()
    var left_upper_arm_bone: Bone2D = player.get_node("BaseSkeleton/PlayerBody/VisualRoot/VisualSkeleton/LeftUpperArmBone") as Bone2D
    var left_forearm_bone: Bone2D = player.get_node("BaseSkeleton/PlayerBody/VisualRoot/VisualSkeleton/LeftUpperArmBone/LeftForearmBone") as Bone2D
    var lower_body_bone: Bone2D = player.get_node("BaseSkeleton/PlayerBody/VisualRoot/VisualSkeleton/LowerBodyBone") as Bone2D
    var starting_left_upper_arm_rotation: float = left_upper_arm_bone.rotation
    var starting_left_forearm_rotation: float = left_forearm_bone.rotation
    var starting_lower_body_rotation: float = lower_body_bone.rotation

    player.set_body_linear_velocity(Vector2(600.0, 0.0))
    player._physics_process(1.0 / 60.0)

    assert_almost_eq(left_upper_arm_bone.rotation, starting_left_upper_arm_rotation, 0.001)
    assert_almost_eq(left_forearm_bone.rotation, starting_left_forearm_rotation, 0.001)
    assert_almost_eq(lower_body_bone.rotation, starting_lower_body_rotation, 0.001)

func test_player_character_left_grip_pose_uses_static_attached_rotations() -> void:
    var player: PlayerCharacterScript = await _instantiate_player()
    var hold: StaticBody2D = _create_hold(&"LeftHold", Vector2(180.0, 260.0))
    var attachment_state := HandAttachmentStateScript.new()
    var left_upper_arm_bone: Bone2D = player.get_node("BaseSkeleton/PlayerBody/VisualRoot/VisualSkeleton/LeftUpperArmBone") as Bone2D
    var left_hand_bone: Bone2D = player.get_left_hand_bone()
    var left_forearm_bone: Bone2D = player.get_node("BaseSkeleton/PlayerBody/VisualRoot/VisualSkeleton/LeftUpperArmBone/LeftForearmBone") as Bone2D
    var starting_left_upper_arm_rotation: float = left_upper_arm_bone.rotation
    var starting_left_forearm_rotation: float = left_forearm_bone.rotation
    var starting_left_hand_rotation: float = left_hand_bone.rotation

    attachment_state.attach(HandSideScript.Value.LEFT, &"left_hold", hold.global_position, hold.get_path())
    player.apply_frame_motion(ClimbPrototypeFrameResultScript.new(Vector2.ZERO, false, 1), attachment_state)

    assert_almost_eq(left_upper_arm_bone.rotation - starting_left_upper_arm_rotation, 0.45, 0.001)
    assert_almost_eq(left_forearm_bone.rotation - starting_left_forearm_rotation, 1.2, 0.001)
    assert_almost_eq(left_hand_bone.rotation - starting_left_hand_rotation, 0.9, 0.001)

func test_player_character_right_grip_pose_uses_static_attached_rotations() -> void:
    var player: PlayerCharacterScript = await _instantiate_player()
    var hold: StaticBody2D = _create_hold(&"RightHold", Vector2(60.0, 260.0))
    var attachment_state := HandAttachmentStateScript.new()
    var right_upper_arm_bone: Bone2D = player.get_node("BaseSkeleton/PlayerBody/VisualRoot/VisualSkeleton/RightUpperArmBone") as Bone2D
    var right_hand_bone: Bone2D = player.get_right_hand_bone()
    var right_forearm_bone: Bone2D = player.get_node("BaseSkeleton/PlayerBody/VisualRoot/VisualSkeleton/RightUpperArmBone/RightForearmBone") as Bone2D
    var starting_right_upper_arm_rotation: float = right_upper_arm_bone.rotation
    var starting_right_forearm_rotation: float = right_forearm_bone.rotation
    var starting_right_hand_rotation: float = right_hand_bone.rotation

    attachment_state.attach(HandSideScript.Value.RIGHT, &"right_hold", hold.global_position, hold.get_path())
    player.apply_frame_motion(ClimbPrototypeFrameResultScript.new(Vector2.ZERO, false, 1), attachment_state)

    assert_almost_eq(right_upper_arm_bone.rotation - starting_right_upper_arm_rotation, -0.45, 0.001)
    assert_almost_eq(right_forearm_bone.rotation - starting_right_forearm_rotation, -1.2, 0.001)
    assert_almost_eq(right_hand_bone.rotation - starting_right_hand_rotation, -0.9, 0.001)

func test_player_character_grab_pose_disables_free_side_and_lower_body_animation() -> void:
    var player: PlayerCharacterScript = await _instantiate_player()
    var hold: StaticBody2D = _create_hold(&"LeftHold", Vector2(180.0, 260.0))
    var attachment_state := HandAttachmentStateScript.new()
    var right_upper_arm_bone: Bone2D = player.get_node("BaseSkeleton/PlayerBody/VisualRoot/VisualSkeleton/RightUpperArmBone") as Bone2D
    var right_forearm_bone: Bone2D = player.get_node("BaseSkeleton/PlayerBody/VisualRoot/VisualSkeleton/RightUpperArmBone/RightForearmBone") as Bone2D
    var right_hand_bone: Bone2D = player.get_right_hand_bone()
    var lower_body_bone: Bone2D = player.get_node("BaseSkeleton/PlayerBody/VisualRoot/VisualSkeleton/LowerBodyBone") as Bone2D
    var starting_right_upper_arm_rotation: float = right_upper_arm_bone.rotation
    var starting_right_forearm_rotation: float = right_forearm_bone.rotation
    var starting_right_hand_rotation: float = right_hand_bone.rotation
    var starting_lower_body_rotation: float = lower_body_bone.rotation

    player.set_body_linear_velocity(Vector2(600.0, 0.0))
    attachment_state.attach(HandSideScript.Value.LEFT, &"left_hold", hold.global_position, hold.get_path())
    player.apply_frame_motion(ClimbPrototypeFrameResultScript.new(Vector2.ZERO, false, 1), attachment_state)
    player._physics_process(1.0 / 60.0)

    assert_almost_eq(right_upper_arm_bone.rotation, starting_right_upper_arm_rotation, 0.001)
    assert_almost_eq(right_forearm_bone.rotation, starting_right_forearm_rotation, 0.001)
    assert_almost_eq(right_hand_bone.rotation, starting_right_hand_rotation, 0.001)
    assert_almost_eq(lower_body_bone.rotation, starting_lower_body_rotation, 0.001)

func test_player_cosmetic_applicator_adds_visuals_without_changing_physics() -> void:
    var player: PlayerCharacterScript = await _instantiate_player()
    var catalog: CosmeticItemCatalogScript = load("res://resources/config/cosmetic_item_catalog.tres") as CosmeticItemCatalogScript
    var loadout := CosmeticLoadoutScript.new()
    var applicator := PlayerCosmeticApplicatorScript.new()
    var body: RigidBody2D = player.get_player_body()
    var starting_mass: float = body.mass
    var starting_collision_layer: int = body.collision_layer
    var starting_collision_mask: int = body.collision_mask
    var starting_collision_shape: Shape2D = player.get_body_collision_shape().shape

    assert_not_null(catalog)
    loadout.body_cosmetic_id = &"body_sunrise_jacket"
    loadout.left_hand_cosmetic_id = &"left_hand_gold_grip"
    loadout.right_hand_cosmetic_id = &"right_hand_gold_grip"
    applicator.apply_loadout(player, loadout, catalog)

    assert_not_null(player.get_cosmetic_visual_root().get_node_or_null("AppliedBodyCosmetic"))
    assert_not_null(player.get_left_hand_cosmetic_root().get_node_or_null("AppliedLeftHandCosmetic"))
    assert_not_null(player.get_right_hand_cosmetic_root().get_node_or_null("AppliedRightHandCosmetic"))
    player.assert_visual_roots_physics_neutral()
    assert_eq(body.mass, starting_mass)
    assert_eq(body.collision_layer, starting_collision_layer)
    assert_eq(body.collision_mask, starting_collision_mask)
    assert_eq(player.get_body_collision_shape().shape, starting_collision_shape)

func test_player_appearance_applicator_applies_human_rig_without_changing_physics() -> void:
    var player: PlayerCharacterScript = await _instantiate_player()
    var catalog: PlayerAppearanceCatalogScript = load("res://resources/config/player_appearance_catalog.tres") as PlayerAppearanceCatalogScript
    var applicator := PlayerAppearanceApplicatorScript.new()
    var body: RigidBody2D = player.get_player_body()
    var starting_mass: float = body.mass
    var starting_collision_layer: int = body.collision_layer
    var starting_collision_mask: int = body.collision_mask
    var starting_collision_shape: Shape2D = player.get_body_collision_shape().shape
    var starting_capsule: CapsuleShape2D = starting_collision_shape as CapsuleShape2D
    var starting_collision_position: Vector2 = player.get_body_collision_shape().position

    assert_not_null(catalog)
    assert_not_null(starting_capsule)
    var human_appearance: PlayerAppearanceScript = catalog.get_required_appearance_by_id(&"human")
    applicator.apply_appearance(player, human_appearance)

    var fitted_collision_shape: Shape2D = player.get_body_collision_shape().shape
    var fitted_capsule: CapsuleShape2D = fitted_collision_shape as CapsuleShape2D
    var runtime_rig: Node2D = player.get_runtime_appearance_rig()
    var runtime_left_upper_arm: Bone2D = runtime_rig.get_node_or_null(human_appearance.rig_left_upper_arm_bone_path) as Bone2D if runtime_rig != null else null
    var runtime_right_forearm: Bone2D = runtime_rig.get_node_or_null(human_appearance.rig_right_forearm_bone_path) as Bone2D if runtime_rig != null else null
    var runtime_lower_body: Bone2D = runtime_rig.get_node_or_null(human_appearance.rig_lower_body_bone_path) as Bone2D if runtime_rig != null else null
    var gameplay_left_upper_arm: Bone2D = player.get_node("BaseSkeleton/PlayerBody/VisualRoot/VisualSkeleton/LeftUpperArmBone") as Bone2D
    var gameplay_right_forearm: Bone2D = player.get_node("BaseSkeleton/PlayerBody/VisualRoot/VisualSkeleton/RightUpperArmBone/RightForearmBone") as Bone2D
    var gameplay_lower_body: Bone2D = player.get_node("BaseSkeleton/PlayerBody/VisualRoot/VisualSkeleton/LowerBodyBone") as Bone2D

    assert_false(player.get_player_visual().visible)
    assert_null(player.get_body_visual_sprite().texture)
    assert_null(player.get_face_overlay().texture)
    assert_null(player.get_left_upper_arm_visual().texture)
    assert_null(player.get_left_forearm_visual().texture)
    assert_null(player.get_left_hand_visual().texture)
    assert_null(player.get_right_upper_arm_visual().texture)
    assert_null(player.get_right_forearm_visual().texture)
    assert_null(player.get_right_hand_visual().texture)
    assert_null(player.get_lower_body_visual().texture)
    assert_null(player.get_body_visual_sprite().get_node_or_null("AppearanceCutout"))
    assert_null(player.get_face_overlay().get_node_or_null("AppearanceCutout"))
    assert_null(player.get_left_upper_arm_visual().get_node_or_null("AppearanceCutout"))
    assert_null(player.get_left_forearm_visual().get_node_or_null("AppearanceCutout"))
    assert_null(player.get_left_hand_visual().get_node_or_null("AppearanceCutout"))
    assert_null(player.get_right_upper_arm_visual().get_node_or_null("AppearanceCutout"))
    assert_null(player.get_right_forearm_visual().get_node_or_null("AppearanceCutout"))
    assert_null(player.get_right_hand_visual().get_node_or_null("AppearanceCutout"))
    assert_null(player.get_lower_body_visual().get_node_or_null("AppearanceCutout"))
    assert_not_null(runtime_rig)
    assert_eq(runtime_rig.get_parent(), player.get_visual_root())
    assert_not_null(runtime_left_upper_arm)
    assert_not_null(runtime_right_forearm)
    assert_not_null(runtime_lower_body)
    var left_upper_arm_rotation_offset: float = wrapf(runtime_left_upper_arm.rotation - gameplay_left_upper_arm.rotation, -PI, PI)
    var right_forearm_rotation_offset: float = wrapf(runtime_right_forearm.rotation - gameplay_right_forearm.rotation, -PI, PI)
    var lower_body_rotation_offset: float = wrapf(runtime_lower_body.rotation - gameplay_lower_body.rotation, -PI, PI)
    player.set_body_linear_velocity(Vector2(300.0, 0.0))
    player._physics_process(1.0 / 60.0)
    assert_almost_eq(wrapf((runtime_left_upper_arm.rotation - gameplay_left_upper_arm.rotation) - left_upper_arm_rotation_offset, -PI, PI), 0.0, 0.001)
    assert_almost_eq(wrapf((runtime_right_forearm.rotation - gameplay_right_forearm.rotation) - right_forearm_rotation_offset, -PI, PI), 0.0, 0.001)
    assert_almost_eq(wrapf((runtime_lower_body.rotation - gameplay_lower_body.rotation) - lower_body_rotation_offset, -PI, PI), 0.0, 0.001)
    assert_not_null(fitted_capsule)
    assert_true(fitted_collision_shape is CapsuleShape2D)
    assert_ne(fitted_collision_shape, starting_collision_shape)
    assert_lt(fitted_capsule.radius, starting_capsule.radius)
    assert_gt(fitted_capsule.height, starting_capsule.height)
    assert_gt(player.get_body_collision_shape().position.y, starting_collision_position.y)
    player.assert_visual_roots_physics_neutral()
    assert_eq(body.mass, starting_mass)
    assert_eq(body.collision_layer, starting_collision_layer)
    assert_eq(body.collision_mask, starting_collision_mask)

func test_player_character_grip_joints_target_player_body() -> void:
    var player: PlayerCharacterScript = await _instantiate_player()

    assert_not_null(player.get_left_grip_joint_anchor())
    assert_not_null(player.get_right_grip_joint_anchor())
    assert_eq(player.get_left_grip_joint_anchor().get_parent().name, "GripJoints")
    assert_eq(player.get_right_grip_joint_anchor().get_parent().name, "GripJoints")

func test_player_character_creates_runtime_grip_joint_for_attached_hand() -> void:
    var player: PlayerCharacterScript = await _instantiate_player()
    var hold: StaticBody2D = _create_hold(&"LeftHold", Vector2(180.0, 260.0))
    var attachment_state := HandAttachmentStateScript.new()

    attachment_state.attach(HandSideScript.Value.LEFT, &"left_hold", hold.global_position, hold.get_path())
    player.apply_frame_motion(ClimbPrototypeFrameResultScript.new(Vector2.ZERO, false, 1), attachment_state)

    var runtime_grip_joint: PinJoint2D = player.get_left_runtime_grip_joint()
    assert_not_null(runtime_grip_joint)
    assert_true(runtime_grip_joint.disable_collision)
    assert_eq(runtime_grip_joint.node_a, runtime_grip_joint.get_path_to(player.get_player_body()))
    assert_eq(runtime_grip_joint.node_b, runtime_grip_joint.get_path_to(hold))
    assert_eq(runtime_grip_joint.global_position, hold.global_position)
    assert_null(player.get_right_runtime_grip_joint())

func test_player_character_clears_runtime_grip_joint_when_attachment_is_removed() -> void:
    var player: PlayerCharacterScript = await _instantiate_player()
    var hold: StaticBody2D = _create_hold(&"LeftHold", Vector2(180.0, 260.0))
    var attachment_state := HandAttachmentStateScript.new()

    attachment_state.attach(HandSideScript.Value.LEFT, &"left_hold", hold.global_position, hold.get_path())
    player.apply_frame_motion(ClimbPrototypeFrameResultScript.new(Vector2.ZERO, false, 1), attachment_state)

    assert_not_null(player.get_left_runtime_grip_joint())

    attachment_state.release(HandSideScript.Value.LEFT)
    player.apply_frame_motion(ClimbPrototypeFrameResultScript.new(Vector2.ZERO, false, 0), attachment_state)

    assert_null(player.get_left_runtime_grip_joint())

func test_player_character_creates_runtime_grip_link_for_attached_hand() -> void:
    var player: PlayerCharacterScript = await _instantiate_player()
    var hold: StaticBody2D = _create_hold(&"LeftHold", Vector2(180.0, 260.0))
    var attachment_state := HandAttachmentStateScript.new()

    attachment_state.attach(HandSideScript.Value.LEFT, &"left_hold", hold.global_position, hold.get_path())
    player.sync_runtime_grip_links(attachment_state)

    var runtime_grip_link: Line2D = player.get_left_runtime_grip_link()
    assert_not_null(runtime_grip_link)
    assert_eq(runtime_grip_link.get_point_count(), 2)
    assert_eq(runtime_grip_link.points[0], player.to_local(hold.global_position))
    assert_eq(runtime_grip_link.points[1], player.to_local(player.get_left_hand_anchor_global_position()))
    assert_null(player.get_right_runtime_grip_link())

func test_player_character_clears_runtime_grip_link_when_attachment_is_removed() -> void:
    var player: PlayerCharacterScript = await _instantiate_player()
    var hold: StaticBody2D = _create_hold(&"LeftHold", Vector2(180.0, 260.0))
    var attachment_state := HandAttachmentStateScript.new()

    attachment_state.attach(HandSideScript.Value.LEFT, &"left_hold", hold.global_position, hold.get_path())
    player.sync_runtime_grip_links(attachment_state)

    assert_not_null(player.get_left_runtime_grip_link())

    attachment_state.release(HandSideScript.Value.LEFT)
    player.sync_runtime_grip_links(attachment_state)
    await get_tree().process_frame

    assert_null(player.get_left_runtime_grip_link())

func test_player_character_enters_falling_on_stamina_depletion_and_resets_controlled() -> void:
    var player: PlayerCharacterScript = await _instantiate_player()
    var frame_result := ClimbPrototypeFrameResultScript.new(Vector2.ZERO, true, 0)
    var attachment_state := HandAttachmentStateScript.new()
    var player_body: RigidBody2D = player.get_player_body()
    var starting_rotation: float = player_body.global_rotation
    var left_upper_arm_bone: Bone2D = player.get_node("BaseSkeleton/PlayerBody/VisualRoot/VisualSkeleton/LeftUpperArmBone") as Bone2D
    var left_forearm_bone: Bone2D = player.get_node("BaseSkeleton/PlayerBody/VisualRoot/VisualSkeleton/LeftUpperArmBone/LeftForearmBone") as Bone2D
    var lower_body_bone: Bone2D = player.get_node("BaseSkeleton/PlayerBody/VisualRoot/VisualSkeleton/LowerBodyBone") as Bone2D
    var starting_left_upper_arm_rotation: float = left_upper_arm_bone.rotation
    var starting_left_forearm_rotation: float = left_forearm_bone.rotation
    var starting_lower_body_rotation: float = lower_body_bone.rotation

    assert_eq(player_body.collision_mask, 1)

    player.apply_frame_motion(frame_result, attachment_state)

    assert_eq(player.get_physics_mode(), PlayerPhysicsModeScript.falling_ragdoll())
    assert_eq(player_body.collision_mask, 3)
    assert_almost_eq(left_upper_arm_bone.rotation, starting_left_upper_arm_rotation, 0.001)
    assert_almost_eq(left_forearm_bone.rotation, starting_left_forearm_rotation, 0.001)
    assert_almost_eq(lower_body_bone.rotation, starting_lower_body_rotation, 0.001)

    player_body.global_rotation = 0.65
    player_body.angular_velocity = 4.0

    player.reset_physics(Vector2(25.0, 50.0))

    assert_eq(player.get_physics_mode(), PlayerPhysicsModeScript.controlled_climb())
    assert_eq(player_body.collision_mask, 1)
    assert_eq(player.get_body_global_position(), Vector2(25.0, 50.0))
    assert_eq(player_body.global_rotation, starting_rotation)
    assert_eq(player.get_body_linear_velocity(), Vector2.ZERO)
    assert_eq(player_body.angular_velocity, 0.0)

func _instantiate_player() -> PlayerCharacterScript:
    var scene: PackedScene = load("res://scenes/player/player_character.tscn")
    var player_node: Node = scene.instantiate()
    var player: PlayerCharacterScript = player_node as PlayerCharacterScript

    assert_not_null(player)
    add_child_autofree(player)
    await get_tree().process_frame

    return player

func _create_hold(hold_name: StringName, global_position_value: Vector2) -> StaticBody2D:
    var hold := StaticBody2D.new()
    var collision_shape := CollisionShape2D.new()
    var shape := RectangleShape2D.new()

    hold.name = hold_name
    hold.global_position = global_position_value
    shape.size = Vector2(64.0, 24.0)
    collision_shape.shape = shape
    hold.add_child(collision_shape)
    add_child_autofree(hold)

    return hold