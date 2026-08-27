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
const PlayerPhysicsModeTransitionsScript = preload("res://src/gameplay/player/player_physics_mode_transitions.gd")
const PlayerCosmeticApplicatorScript = preload("res://src/cosmetics/player_cosmetic_applicator.gd")

func test_player_character_scene_wires_required_nodes() -> void:
    var player: PlayerCharacterScript = await _instantiate_player()

    assert_not_null(player.get_player_body())
    assert_not_null(player.get_torso_collision_shape())
    assert_not_null(player.get_head_collision_shape())
    assert_not_null(player.get_left_arm_collision_shape())
    assert_not_null(player.get_right_arm_collision_shape())
    assert_not_null(player.get_head_body())
    assert_not_null(player.get_left_arm_body())
    assert_not_null(player.get_right_arm_body())
    assert_not_null(player.get_node_or_null("Torso/NeckSocket"))
    assert_not_null(player.get_node_or_null("Torso/NeckSocket/TorsoHeadJoint"))
    assert_not_null(player.get_node_or_null("Torso/LeftShoulderSocket/TorsoLeftArmJoint"))
    assert_not_null(player.get_node_or_null("Torso/RightShoulderSocket/TorsoRightArmJoint"))
    assert_not_null(player.get_body_visual_sprite())
    assert_not_null(player.get_face_overlay())
    assert_not_null(player.get_left_arm_visual())
    assert_not_null(player.get_right_arm_visual())
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

func test_player_character_each_limb_owns_its_own_collision_shape() -> void:
    var player: PlayerCharacterScript = await _instantiate_player()

    var torso: RigidBody2D = player.get_player_body()
    var torso_shape: CollisionShape2D = player.get_torso_collision_shape()
    assert_eq(torso_shape.get_parent(), torso)
    assert_true(torso_shape.shape is CapsuleShape2D)

    var head: RigidBody2D = player.get_head_body()
    var head_shape: CollisionShape2D = head.get_node("HeadCollisionShape")
    assert_eq(head_shape.get_parent(), head)
    assert_true(head_shape.shape is CircleShape2D)

    var left_arm: RigidBody2D = player.get_left_arm_body()
    var left_arm_shape: CollisionShape2D = left_arm.get_node("LeftArmCollisionShape")
    assert_eq(left_arm_shape.get_parent(), left_arm)
    assert_true(left_arm_shape.shape is CapsuleShape2D)

    var right_arm: RigidBody2D = player.get_right_arm_body()
    var right_arm_shape: CollisionShape2D = right_arm.get_node("RightArmCollisionShape")
    assert_eq(right_arm_shape.get_parent(), right_arm)
    assert_true(right_arm_shape.shape is CapsuleShape2D)

func test_player_character_limb_collision_layer_excludes_self_and_torso() -> void:
    var player: PlayerCharacterScript = await _instantiate_player()

    for limb_body in _limb_bodies(player):
        assert_eq(limb_body.collision_layer, PlayerCharacterScript.LIMB_COLLISION_LAYER)
        assert_eq(limb_body.collision_mask, 1)

    assert_true((player.get_node("Torso/NeckSocket/TorsoHeadJoint") as PinJoint2D).disable_collision)
    assert_true((player.get_node("Torso/LeftShoulderSocket/TorsoLeftArmJoint") as PinJoint2D).disable_collision)
    assert_true((player.get_node("Torso/RightShoulderSocket/TorsoRightArmJoint") as PinJoint2D).disable_collision)

func test_player_character_limbs_start_frozen_kinematic_while_climbing() -> void:
    var player: PlayerCharacterScript = await _instantiate_player()

    assert_eq(player.get_physics_mode(), PlayerPhysicsModeScript.controlled_climb())
    for limb_body in _limb_bodies(player):
        assert_true(limb_body.freeze)
        assert_eq(limb_body.freeze_mode, RigidBody2D.FREEZE_MODE_KINEMATIC)

func test_player_character_enters_falling_unfreezes_limbs_and_seeds_velocity_from_torso() -> void:
    var player: PlayerCharacterScript = await _instantiate_player()
    var torso: RigidBody2D = player.get_player_body()
    torso.linear_velocity = Vector2(120.0, -40.0)
    torso.angular_velocity = 1.5

    player.enter_falling(PlayerPhysicsModeTransitionsScript.Reason.FALL_DETECTED)
    await get_tree().process_frame

    for limb_body in _limb_bodies(player):
        assert_false(limb_body.freeze)
        assert_eq(limb_body.linear_velocity, Vector2(120.0, -40.0))
        assert_eq(limb_body.angular_velocity, 1.5)

func test_player_character_reset_physics_refreezes_limbs_and_snaps_pose() -> void:
    var player: PlayerCharacterScript = await _instantiate_player()
    player.enter_falling(PlayerPhysicsModeTransitionsScript.Reason.FALL_DETECTED)

    player.reset_physics(Vector2(40.0, 90.0))

    assert_eq(player.get_physics_mode(), PlayerPhysicsModeScript.controlled_climb())
    for limb_body in _limb_bodies(player):
        assert_true(limb_body.freeze)
        assert_eq(limb_body.linear_velocity, Vector2.ZERO)
        assert_eq(limb_body.angular_velocity, 0.0)

    assert_eq(player.get_head_body().global_position, (player.get_node("Torso/NeckSocket") as Node2D).global_position)
    assert_eq(player.get_left_arm_body().global_position, player.get_left_shoulder_socket().global_position)
    assert_eq(player.get_right_arm_body().global_position, player.get_right_shoulder_socket().global_position)

func test_player_character_visual_roots_are_physics_neutral() -> void:
    var player: PlayerCharacterScript = await _instantiate_player()
    var bodies: Array[RigidBody2D] = [player.get_player_body(), player.get_head_body(), player.get_left_arm_body(), player.get_right_arm_body()]
    var starting_masses: Array[float] = []
    var starting_layers: Array[int] = []
    var starting_masks: Array[int] = []
    for body in bodies:
        starting_masses.append(body.mass)
        starting_layers.append(body.collision_layer)
        starting_masks.append(body.collision_mask)
    var starting_torso_shape: Shape2D = player.get_torso_collision_shape().shape

    var extra_visual := Polygon2D.new()
    extra_visual.name = &"TestCosmeticVisual"
    extra_visual.polygon = PackedVector2Array([Vector2.ZERO, Vector2.RIGHT, Vector2.DOWN])
    player.get_cosmetic_visual_root().add_child(extra_visual)

    player.assert_visual_roots_physics_neutral()

    for index in bodies.size():
        assert_eq(bodies[index].mass, starting_masses[index])
        assert_eq(bodies[index].collision_layer, starting_layers[index])
        assert_eq(bodies[index].collision_mask, starting_masks[index])
    assert_eq(player.get_torso_collision_shape().shape, starting_torso_shape)

func test_player_character_hand_geometry_separates_reach_and_visual_anchors() -> void:
    var player: PlayerCharacterScript = await _instantiate_player()

    assert_eq(player.get_left_hand_anchor().get_parent(), player.get_left_shoulder_socket())
    assert_eq(player.get_right_hand_anchor().get_parent(), player.get_right_shoulder_socket())
    assert_eq(player.get_left_hand_visual_anchor().get_parent(), player.get_left_shoulder_socket())
    assert_eq(player.get_right_hand_visual_anchor().get_parent(), player.get_right_shoulder_socket())
    assert_eq(player.get_left_hand_cosmetic_root().get_parent(), player.get_left_arm_body())
    assert_eq(player.get_right_hand_cosmetic_root().get_parent(), player.get_right_arm_body())
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

func test_player_character_unattached_arm_tracks_shoulder_socket() -> void:
    var player: PlayerCharacterScript = await _instantiate_player()
    var left_arm: RigidBody2D = player.get_left_arm_body()

    player.set_body_linear_velocity(Vector2(300.0, 0.0))
    player._physics_process(1.0 / 60.0)

    assert_eq(left_arm.global_position, player.get_left_shoulder_socket().global_position)

func test_player_character_unattached_motion_keeps_arm_rest_rotation() -> void:
    var player: PlayerCharacterScript = await _instantiate_player()
    var left_arm: RigidBody2D = player.get_left_arm_body()
    var starting_left_arm_rotation: float = left_arm.global_rotation

    player.set_body_linear_velocity(Vector2(600.0, 0.0))
    player._physics_process(1.0 / 60.0)

    assert_almost_eq(left_arm.global_rotation, starting_left_arm_rotation, 0.001)

func test_player_character_left_arm_pose_points_toward_hold() -> void:
    var player: PlayerCharacterScript = await _instantiate_player()
    var hold: StaticBody2D = _create_hold(&"LeftHold", Vector2(180.0, 260.0))
    var attachment_state := HandAttachmentStateScript.new()
    var left_arm: RigidBody2D = player.get_left_arm_body()
    var left_shoulder_socket: Marker2D = player.get_left_shoulder_socket()

    attachment_state.attach(HandSideScript.Value.LEFT, &"left_hold", hold.global_position, hold.get_path())
    player.apply_frame_motion(ClimbPrototypeFrameResultScript.new(Vector2.ZERO, false, 1), attachment_state)

    var expected_direction: Vector2 = (hold.global_position - left_shoulder_socket.global_position).normalized()
    var actual_direction: Vector2 = Vector2.RIGHT.rotated(left_arm.global_rotation + PlayerCharacterScript.LEFT_ARM_BONE_FORWARD_ANGLE_OFFSET_RADIANS)
    assert_almost_eq(actual_direction.angle_to(expected_direction), 0.0, 0.01)
    assert_eq(left_arm.global_position, left_shoulder_socket.global_position)

func test_player_character_right_arm_pose_points_toward_hold() -> void:
    var player: PlayerCharacterScript = await _instantiate_player()
    var hold: StaticBody2D = _create_hold(&"RightHold", Vector2(60.0, 260.0))
    var attachment_state := HandAttachmentStateScript.new()
    var right_arm: RigidBody2D = player.get_right_arm_body()
    var right_shoulder_socket: Marker2D = player.get_right_shoulder_socket()

    attachment_state.attach(HandSideScript.Value.RIGHT, &"right_hold", hold.global_position, hold.get_path())
    player.apply_frame_motion(ClimbPrototypeFrameResultScript.new(Vector2.ZERO, false, 1), attachment_state)

    var expected_direction: Vector2 = (hold.global_position - right_shoulder_socket.global_position).normalized()
    var actual_direction: Vector2 = Vector2.RIGHT.rotated(right_arm.global_rotation + PlayerCharacterScript.RIGHT_ARM_BONE_FORWARD_ANGLE_OFFSET_RADIANS)
    assert_almost_eq(actual_direction.angle_to(expected_direction), 0.0, 0.01)

func test_player_character_grab_pose_keeps_free_side_at_rest_pose() -> void:
    var player: PlayerCharacterScript = await _instantiate_player()
    var hold: StaticBody2D = _create_hold(&"LeftHold", Vector2(180.0, 260.0))
    var attachment_state := HandAttachmentStateScript.new()
    var right_arm: RigidBody2D = player.get_right_arm_body()
    var torso: RigidBody2D = player.get_player_body()

    attachment_state.attach(HandSideScript.Value.LEFT, &"left_hold", hold.global_position, hold.get_path())
    player.apply_frame_motion(ClimbPrototypeFrameResultScript.new(Vector2.ZERO, false, 1), attachment_state)

    assert_almost_eq(right_arm.global_rotation, torso.global_rotation, 0.001)
    assert_eq(right_arm.global_position, player.get_right_shoulder_socket().global_position)

func test_player_cosmetic_applicator_adds_visuals_without_changing_physics() -> void:
    var player: PlayerCharacterScript = await _instantiate_player()
    var catalog: CosmeticItemCatalogScript = load("res://resources/config/cosmetic_item_catalog.tres") as CosmeticItemCatalogScript
    var loadout := CosmeticLoadoutScript.new()
    var applicator := PlayerCosmeticApplicatorScript.new()
    var body: RigidBody2D = player.get_player_body()
    var starting_mass: float = body.mass
    var starting_collision_layer: int = body.collision_layer
    var starting_collision_mask: int = body.collision_mask
    var starting_collision_shape: Shape2D = player.get_torso_collision_shape().shape

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
    assert_eq(player.get_torso_collision_shape().shape, starting_collision_shape)

func test_player_appearance_applicator_applies_human_appearance_without_changing_physics() -> void:
    var player: PlayerCharacterScript = await _instantiate_player()
    var catalog: PlayerAppearanceCatalogScript = load("res://resources/config/player_appearance_catalog.tres") as PlayerAppearanceCatalogScript
    var applicator := PlayerAppearanceApplicatorScript.new()
    var body: RigidBody2D = player.get_player_body()
    var starting_mass: float = body.mass
    var starting_collision_layer: int = body.collision_layer
    var starting_collision_mask: int = body.collision_mask

    assert_not_null(catalog)
    assert_true(player.get_torso_collision_shape().shape is CapsuleShape2D)
    assert_false(player.get_torso_collision_shape().disabled)
    assert_true(player.get_torso_fitted_collision_polygons().is_empty())
    var human_appearance: PlayerAppearanceScript = catalog.get_required_appearance_by_id(&"human")
    applicator.apply_appearance(player, human_appearance)

    assert_false(player.get_player_visual().visible)
    assert_not_null(player.get_body_visual_sprite().texture)
    assert_not_null(player.get_face_overlay().texture)
    assert_not_null(player.get_left_arm_visual().texture)
    assert_not_null(player.get_right_arm_visual().texture)

    # The plain-texture path fits pixel-silhouette collision, which disables the fallback
    # primitive shape (still a valid CapsuleShape2D/CircleShape2D -- untouched, just inactive)
    # and replaces it with one or more convex CollisionPolygon2D children per limb.
    assert_true(player.get_torso_collision_shape().disabled)
    _assert_fitted_collision_polygons_are_valid(player.get_torso_fitted_collision_polygons())
    assert_true(player.get_head_collision_shape().disabled)
    _assert_fitted_collision_polygons_are_valid(player.get_head_fitted_collision_polygons())
    assert_true(player.get_left_arm_collision_shape().disabled)
    _assert_fitted_collision_polygons_are_valid(player.get_left_arm_fitted_collision_polygons())
    assert_true(player.get_right_arm_collision_shape().disabled)
    _assert_fitted_collision_polygons_are_valid(player.get_right_arm_fitted_collision_polygons())

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

    assert_eq(player_body.collision_mask, 1)

    player.apply_frame_motion(frame_result, attachment_state)
    await get_tree().process_frame

    assert_eq(player.get_physics_mode(), PlayerPhysicsModeScript.falling_ragdoll())
    assert_eq(player_body.collision_mask, 3)
    for limb_body in _limb_bodies(player):
        assert_false(limb_body.freeze)

    player_body.global_rotation = 0.65
    player_body.angular_velocity = 4.0

    player.reset_physics(Vector2(25.0, 50.0))

    assert_eq(player.get_physics_mode(), PlayerPhysicsModeScript.controlled_climb())
    assert_eq(player_body.collision_mask, 1)
    assert_eq(player.get_body_global_position(), Vector2(25.0, 50.0))
    assert_eq(player_body.global_rotation, starting_rotation)
    assert_eq(player.get_body_linear_velocity(), Vector2.ZERO)
    assert_eq(player_body.angular_velocity, 0.0)
    for limb_body in _limb_bodies(player):
        assert_true(limb_body.freeze)

func test_player_character_swings_with_one_hand_attached_over_time() -> void:
    var player: PlayerCharacterScript = await _instantiate_player()
    var hold: StaticBody2D = _create_hold(&"LeftHold", player.get_left_hand_anchor_global_position() + Vector2(0.0, -60.0))
    var attachment_state := HandAttachmentStateScript.new()
    attachment_state.attach(HandSideScript.Value.LEFT, &"left_hold", hold.global_position, hold.get_path())

    var start_position: Vector2 = player.get_body_global_position()
    for _frame_index in range(90):
        var frame_result := ClimbPrototypeFrameResultScript.new(Vector2(2400.0, 0.0), false, 1)
        player.apply_frame_motion(frame_result, attachment_state)
        await get_tree().physics_frame

    assert_ne(
        player.get_body_global_position(),
        start_position,
        "One-hand swing input held over time must move the player body, or swinging silently does nothing."
    )

func test_player_character_swings_when_aim_is_nearly_radial_to_an_overhead_hold() -> void:
    # Regression for a real reported bug: a hold almost directly overhead plus aim input almost
    # directly along that same radial line leaves only a tiny tangential force component each
    # frame -- too small to push velocity back above Godot's sleep threshold before the next
    # tick, so the body re-slept every frame and every frame's progress was discarded forever.
    var player: PlayerCharacterScript = await _instantiate_player()
    var hold: StaticBody2D = _create_hold(&"LeftHold", player.get_left_hand_anchor_global_position() + Vector2(-2.4, -62.65))
    var attachment_state := HandAttachmentStateScript.new()
    attachment_state.attach(HandSideScript.Value.LEFT, &"left_hold", hold.global_position, hold.get_path())

    var start_position: Vector2 = player.get_body_global_position()
    for _frame_index in range(120):
        var frame_result := ClimbPrototypeFrameResultScript.new(Vector2(0.0, -2400.0), false, 1)
        player.apply_frame_motion(frame_result, attachment_state)
        await get_tree().physics_frame

    assert_ne(
        player.get_body_global_position(),
        start_position,
        "A small but real tangential force held over many frames must still eventually move the player body."
    )

func _limb_bodies(player: PlayerCharacterScript) -> Array[RigidBody2D]:
    return [player.get_head_body(), player.get_left_arm_body(), player.get_right_arm_body()]

func _assert_fitted_collision_polygons_are_valid(polygons: Array[CollisionPolygon2D]) -> void:
    assert_gt(polygons.size(), 0)
    for polygon_node in polygons:
        assert_gt(polygon_node.polygon.size(), 2)
        assert_false(polygon_node.disabled)

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
