extends GutTest

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
    assert_eq(playground.get_run_session_for_test().get_state(), RunStateScript.Value.CLIMBING)


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

func test_dev_playground_reset_clears_runtime_attachments_and_restarts_run() -> void:
    var scene: PackedScene = load("res://scenes/main/dev_playground.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: DevPlayground = playground_node as DevPlayground

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    playground.get_controller_for_test().get_attachment_state().attach(HandSide.Value.LEFT, &"test_hold", Vector2.ZERO)
    playground.reset_for_test()

    assert_eq(playground.get_controller_for_test().get_attachment_state().get_attached_hand_count(), 0)
    assert_eq(playground.get_run_session_for_test().get_state(), RunStateScript.Value.CLIMBING)