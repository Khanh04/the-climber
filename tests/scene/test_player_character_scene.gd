extends GutTest

const ClimbPrototypeFrameResultScript = preload("res://src/gameplay/player/climb_prototype_frame_result.gd")
const HandAttachmentStateScript = preload("res://src/gameplay/player/hand_attachment_state.gd")
const PlayerCharacterScript = preload("res://scenes/player/player_character.gd")
const PlayerPhysicsModeScript = preload("res://src/gameplay/player/player_physics_mode.gd")

func test_player_character_scene_wires_required_nodes() -> void:
    var player: PlayerCharacterScript = await _instantiate_player()

    assert_not_null(player.get_node_or_null("BaseSkeleton"))
    assert_not_null(player.get_node_or_null("BaseSkeleton/TorsoBone"))
    assert_not_null(player.get_player_body())
    assert_not_null(player.get_body_collision_shape())
    assert_not_null(player.get_left_hand_anchor())
    assert_not_null(player.get_right_hand_anchor())
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

func test_player_character_grip_joints_target_player_body() -> void:
    var player: PlayerCharacterScript = await _instantiate_player()

    assert_not_null(player.get_left_grip_joint_anchor())
    assert_not_null(player.get_right_grip_joint_anchor())
    assert_eq(player.get_left_grip_joint_anchor().get_parent().name, "GripJoints")
    assert_eq(player.get_right_grip_joint_anchor().get_parent().name, "GripJoints")

func test_player_character_enters_falling_on_stamina_depletion_and_resets_controlled() -> void:
    var player: PlayerCharacterScript = await _instantiate_player()
    var frame_result := ClimbPrototypeFrameResultScript.new(Vector2.ZERO, true, 0)
    var attachment_state := HandAttachmentStateScript.new()

    player.apply_frame_motion(frame_result, attachment_state)

    assert_eq(player.get_physics_mode(), PlayerPhysicsModeScript.falling_ragdoll())

    player.reset_physics(Vector2(25.0, 50.0))

    assert_eq(player.get_physics_mode(), PlayerPhysicsModeScript.controlled_climb())
    assert_eq(player.get_body_global_position(), Vector2(25.0, 50.0))
    assert_eq(player.get_body_linear_velocity(), Vector2.ZERO)

func _instantiate_player() -> PlayerCharacterScript:
    var scene: PackedScene = load("res://scenes/player/player_character.tscn")
    var player_node: Node = scene.instantiate()
    var player: PlayerCharacterScript = player_node as PlayerCharacterScript

    assert_not_null(player)
    add_child_autofree(player)
    await get_tree().process_frame

    return player