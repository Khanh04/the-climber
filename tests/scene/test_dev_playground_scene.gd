extends GutTest

const RunEndReasonScript = preload("res://src/core/run_end_reason.gd")
const RunStateScript = preload("res://src/gameplay/run/run_state.gd")

func test_dev_playground_scene_wires_required_nodes_and_starts_run() -> void:
    var scene: PackedScene = load("res://scenes/main/dev_playground.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: DevPlayground = playground_node as DevPlayground

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    assert_not_null(playground.get_node_or_null("PlayerBody"))
    assert_not_null(playground.get_node_or_null("PlayerBody/LeftHandAnchor"))
    assert_not_null(playground.get_node_or_null("PlayerBody/RightHandAnchor"))
    assert_not_null(playground.get_node_or_null("ResetAnchor"))
    assert_not_null(playground.get_node_or_null("DevCamera"))
    assert_not_null(playground.get_node_or_null("DebugHud/DebugLabel"))
    assert_eq(playground.get_run_session_for_test().get_state(), RunStateScript.Value.CLIMBING)

func test_dev_playground_uses_extended_starting_stamina_for_playtesting() -> void:
    var scene: PackedScene = load("res://scenes/main/dev_playground.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: DevPlayground = playground_node as DevPlayground

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    assert_eq(playground.stamina_tuning.one_hand_seconds, 20.0)


func test_dev_playground_handholds_have_required_group() -> void:
    var scene: PackedScene = load("res://scenes/main/dev_playground.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: DevPlayground = playground_node as DevPlayground

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    var handholds: Array = playground.get_tree().get_nodes_in_group(&"handhold")

    assert_gt(handholds.size(), 0)
    for handhold in handholds:
        assert_true(handhold is StaticBody2D)

func test_dev_playground_starter_holds_are_in_initial_grip_range() -> void:
    var scene: PackedScene = load("res://scenes/main/dev_playground.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: DevPlayground = playground_node as DevPlayground

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    var left_anchor: Marker2D = playground.get_node("PlayerBody/LeftHandAnchor") as Marker2D
    var right_anchor: Marker2D = playground.get_node("PlayerBody/RightHandAnchor") as Marker2D
    var left_hold: StaticBody2D = playground.get_node("Handholds/HoldStartLeft") as StaticBody2D
    var right_hold: StaticBody2D = playground.get_node("Handholds/HoldStartRight") as StaticBody2D

    assert_not_null(left_anchor)
    assert_not_null(right_anchor)
    assert_not_null(left_hold)
    assert_not_null(right_hold)
    assert_lte(left_anchor.global_position.distance_to(left_hold.global_position), playground.climb_tuning.handhold_detection_radius_pixels)
    assert_lte(right_anchor.global_position.distance_to(right_hold.global_position), playground.climb_tuning.handhold_detection_radius_pixels)

func test_dev_playground_climb_holds_do_not_block_player_body() -> void:
    var scene: PackedScene = load("res://scenes/main/dev_playground.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: DevPlayground = playground_node as DevPlayground

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    var player_body: RigidBody2D = playground.get_node("PlayerBody") as RigidBody2D
    var left_hold: StaticBody2D = playground.get_node("Handholds/HoldStartLeft") as StaticBody2D
    var right_hold: StaticBody2D = playground.get_node("Handholds/HoldStartRight") as StaticBody2D
    var safe_platform: StaticBody2D = playground.get_node("Handholds/HoldSafePlatform") as StaticBody2D

    assert_not_null(player_body)
    assert_not_null(left_hold)
    assert_not_null(right_hold)
    assert_not_null(safe_platform)
    assert_false((player_body.collision_mask & left_hold.collision_layer) != 0)
    assert_false((player_body.collision_mask & right_hold.collision_layer) != 0)
    assert_true((player_body.collision_mask & safe_platform.collision_layer) != 0)

func test_dev_playground_has_tall_non_blocking_test_route() -> void:
    var scene: PackedScene = load("res://scenes/main/dev_playground.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: DevPlayground = playground_node as DevPlayground

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    var player_body: RigidBody2D = playground.get_node("PlayerBody") as RigidBody2D
    var non_blocking_hold_count: int = 0
    var highest_hold_y: float = INF
    var lowest_hold_y: float = -INF

    assert_not_null(player_body)
    for handhold in playground.get_tree().get_nodes_in_group(&"handhold"):
        assert_true(handhold is StaticBody2D)
        var handhold_body: StaticBody2D = handhold
        if (player_body.collision_mask & handhold_body.collision_layer) == 0:
            non_blocking_hold_count += 1
            highest_hold_y = minf(highest_hold_y, handhold_body.global_position.y)
            lowest_hold_y = maxf(lowest_hold_y, handhold_body.global_position.y)

    assert_gte(non_blocking_hold_count, 8)
    assert_gt(lowest_hold_y - highest_hold_y, 1200.0)

func test_dev_playground_camera_follows_player_upward() -> void:
    var scene: PackedScene = load("res://scenes/main/dev_playground.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: DevPlayground = playground_node as DevPlayground

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    var player_body: RigidBody2D = playground.get_node("PlayerBody") as RigidBody2D
    var camera: Camera2D = playground.get_node("DevCamera") as Camera2D

    assert_not_null(player_body)
    assert_not_null(camera)

    var starting_camera_y: float = camera.global_position.y
    player_body.global_position = Vector2(player_body.global_position.x, player_body.global_position.y - 500.0)
    playground._physics_process(0.0)

    assert_lt(camera.global_position.y, starting_camera_y)
    assert_eq(camera.global_position.y, player_body.global_position.y - playground.get_camera_player_lower_screen_offset_for_test())

func test_dev_playground_bottom_screen_fall_routes_through_run_session() -> void:
    var scene: PackedScene = load("res://scenes/main/dev_playground.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: DevPlayground = playground_node as DevPlayground

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    var player_body: RigidBody2D = playground.get_node("PlayerBody") as RigidBody2D
    var camera: Camera2D = playground.get_node("DevCamera") as Camera2D

    assert_not_null(player_body)
    assert_not_null(camera)

    var viewport_size: Vector2 = playground.get_viewport_rect().size
    player_body.global_position = Vector2(
        player_body.global_position.x,
        camera.global_position.y + (viewport_size.y * 0.5) + playground.get_bottom_fall_margin_for_test() + 24.0
    )
    playground._physics_process(0.0)

    assert_eq(playground.get_run_session_for_test().get_state(), RunStateScript.Value.RESCUE_OFFERED)
    assert_true(playground.get_run_session_for_test().has_end_reason())
    assert_eq(playground.get_run_session_for_test().get_end_reason(), RunEndReasonScript.Value.BOTTOM_SCREEN_FALL)

func test_dev_playground_has_safe_start_block_below_spawn() -> void:
    var scene: PackedScene = load("res://scenes/main/dev_playground.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: DevPlayground = playground_node as DevPlayground

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    var reset_anchor: Marker2D = playground.get_node("ResetAnchor") as Marker2D
    var safe_platform: StaticBody2D = playground.get_node("Handholds/HoldSafePlatform") as StaticBody2D

    assert_not_null(reset_anchor)
    assert_not_null(safe_platform)
    assert_true(safe_platform.is_in_group(&"handhold"))
    assert_gt(safe_platform.global_position.y, reset_anchor.global_position.y)
    assert_lte(safe_platform.global_position.y - reset_anchor.global_position.y, 80.0)

func test_dev_playground_left_grip_creates_and_releases_runtime_link() -> void:
    var scene: PackedScene = load("res://scenes/main/dev_playground.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: DevPlayground = playground_node as DevPlayground

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    playground.get_controller_for_test().get_attachment_state().attach(
        HandSide.Value.LEFT,
        &"HoldStartLeft",
        Vector2(450.0, 1424.0),
        NodePath("Handholds/HoldStartLeft")
    )
    playground.sync_grip_links_for_test()

    var left_link: Line2D = playground.get_node_or_null("LeftGripLink") as Line2D
    assert_not_null(left_link)
    assert_eq(left_link.get_point_count(), 2)

    playground.get_controller_for_test().get_attachment_state().release(HandSide.Value.LEFT)
    playground.sync_grip_links_for_test()
    await get_tree().process_frame

    assert_null(playground.get_node_or_null("LeftGripLink"))

func test_dev_playground_reset_clears_runtime_attachments_and_restarts_run() -> void:
    var scene: PackedScene = load("res://scenes/main/dev_playground.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: DevPlayground = playground_node as DevPlayground

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    playground.get_controller_for_test().get_attachment_state().attach(HandSide.Value.LEFT, &"test_hold", Vector2.ZERO, NodePath("Handholds/HoldStartLeft"))
    playground.reset_for_test()

    assert_eq(playground.get_controller_for_test().get_attachment_state().get_attached_hand_count(), 0)
    assert_eq(playground.get_run_session_for_test().get_state(), RunStateScript.Value.CLIMBING)

func test_dev_playground_debug_reset_action_works_while_falling() -> void:
    var scene: PackedScene = load("res://scenes/main/dev_playground.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: DevPlayground = playground_node as DevPlayground

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    var player_body: RigidBody2D = playground.get_node("PlayerBody") as RigidBody2D
    var reset_anchor: Marker2D = playground.get_node("ResetAnchor") as Marker2D

    assert_not_null(player_body)
    assert_not_null(reset_anchor)

    playground.get_run_session_for_test().begin_fall()
    player_body.global_position = Vector2(100.0, 100.0)
    player_body.linear_velocity = Vector2(200.0, 500.0)

    var reset_event := InputEventAction.new()
    reset_event.action = &"debug_reset_run"
    reset_event.pressed = true
    playground._input(reset_event)

    assert_eq(playground.get_run_session_for_test().get_state(), RunStateScript.Value.CLIMBING)
    assert_eq(player_body.global_position, reset_anchor.global_position)
    assert_eq(player_body.linear_velocity, Vector2.ZERO)