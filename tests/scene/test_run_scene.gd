extends GutTest

const AimInputIntentScript = preload("res://src/gameplay/player/aim_input_intent.gd")
const ChaserFeedbackSnapshotScript = preload("res://src/gameplay/chaser/chaser_feedback_snapshot.gd")
const ChaserPacingModelScript = preload("res://src/gameplay/chaser/chaser_pacing_model.gd")
const ChaserKillZoneScript = preload("res://scenes/chaser/chaser_kill_zone.gd")
const CosmeticLoadoutScript = preload("res://resources/config/cosmetic_loadout.gd")
const PlayerInputFrameScript = preload("res://src/gameplay/player/player_input_frame.gd")
const PlayerPhysicsModeScript = preload("res://src/gameplay/player/player_physics_mode.gd")
const RunEndReasonScript = preload("res://src/core/run_end_reason.gd")
const RunSceneScript = preload("res://scenes/main/run_scene.gd")
const SaveSchemaScript = preload("res://src/platform/storage/save_schema.gd")
const SaveSnapshotScript = preload("res://src/platform/storage/save_snapshot.gd")
const StaminaFallServiceScript = preload("res://src/gameplay/run/stamina_fall_service.gd")
const RunStateScript = preload("res://src/gameplay/run/run_state.gd")

func test_run_scene_wires_required_nodes_and_starts_run() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    assert_not_null(playground.get_node_or_null("PlayerCharacter"))
    assert_not_null(playground.get_node_or_null("ChaserKillZone"))
    assert_not_null(playground.get_player_body_for_test())
    assert_not_null(playground.get_left_hand_anchor_for_test())
    assert_not_null(playground.get_right_hand_anchor_for_test())
    assert_not_null(playground.get_node_or_null("ResetAnchor"))
    assert_not_null(playground.get_node_or_null("DevCamera"))
    assert_not_null(playground.get_node_or_null("UiLayer/RunHud"))
    assert_not_null(playground.get_node_or_null("UiLayer/RunEndScreen"))
    assert_eq(playground.get_run_session_for_test().get_state(), RunStateScript.Value.CLIMBING)

func test_run_scene_uses_extended_starting_stamina_for_playtesting() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    assert_eq(playground.stamina_tuning.one_hand_seconds, 20.0)

func test_run_scene_applies_equipped_chaser_theme_from_cosmetic_loadout() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript
    var cosmetic_loadout := CosmeticLoadoutScript.new()

    assert_not_null(playground)
    cosmetic_loadout.chaser_theme_id = &"glitch"
    playground.cosmetic_loadout = cosmetic_loadout
    add_child_autofree(playground)
    await get_tree().process_frame

    assert_eq(playground.get_chaser_for_test().chaser_theme.theme_id, &"glitch")

    playground.reset_for_test()
    assert_eq(playground.get_chaser_for_test().chaser_theme.theme_id, &"glitch")

func test_run_scene_save_snapshot_overrides_default_chaser_theme_selection() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript
    var save_snapshot: SaveSnapshotScript = SaveSnapshotScript.new(12, SaveSchemaScript.VERSION, &"hot_coffee")

    assert_not_null(playground)
    playground.set_save_snapshot(save_snapshot)
    add_child_autofree(playground)
    await get_tree().process_frame

    assert_eq(playground.get_chaser_for_test().chaser_theme.theme_id, &"hot_coffee")

    playground.reset_for_test()
    assert_eq(playground.get_chaser_for_test().chaser_theme.theme_id, &"hot_coffee")

func test_run_scene_handholds_have_required_group() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    var handholds: Array = playground.get_tree().get_nodes_in_group(&"handhold")

    assert_gt(handholds.size(), 0)
    for handhold in handholds:
        assert_true(handhold is StaticBody2D)

func test_run_scene_starter_holds_are_in_initial_grip_range() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    var left_anchor: Marker2D = playground.get_left_hand_anchor_for_test()
    var right_anchor: Marker2D = playground.get_right_hand_anchor_for_test()
    var left_hold: StaticBody2D = playground.get_node("Handholds/HoldStartLeft") as StaticBody2D
    var right_hold: StaticBody2D = playground.get_node("Handholds/HoldStartRight") as StaticBody2D

    assert_not_null(left_anchor)
    assert_not_null(right_anchor)
    assert_not_null(left_hold)
    assert_not_null(right_hold)
    assert_lte(left_anchor.global_position.distance_to(left_hold.global_position), playground.climb_tuning.handhold_detection_radius_pixels)
    assert_lte(right_anchor.global_position.distance_to(right_hold.global_position), playground.climb_tuning.handhold_detection_radius_pixels)

func test_run_scene_climb_holds_do_not_block_player_body() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    var player_body: RigidBody2D = playground.get_player_body_for_test()
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

func test_run_scene_has_tall_non_blocking_test_route() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    var player_body: RigidBody2D = playground.get_player_body_for_test()
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

    assert_gte(non_blocking_hold_count, 18)
    assert_gt(lowest_hold_y - highest_hold_y, 1200.0)

func test_run_scene_camera_follows_player_upward() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    var player_body: RigidBody2D = playground.get_player_body_for_test()
    var camera: Camera2D = playground.get_node("DevCamera") as Camera2D

    assert_not_null(player_body)
    assert_not_null(camera)

    var starting_camera_y: float = camera.global_position.y
    player_body.global_position = Vector2(player_body.global_position.x, player_body.global_position.y - 500.0)
    playground._physics_process(0.0)

    assert_lt(camera.global_position.y, starting_camera_y)
    assert_eq(camera.global_position.y, player_body.global_position.y - playground.get_camera_player_lower_screen_offset_for_test())

func test_run_scene_bottom_screen_fall_routes_through_run_session() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    var player_body: RigidBody2D = playground.get_player_body_for_test()
    var camera: Camera2D = playground.get_node("DevCamera") as Camera2D

    assert_not_null(player_body)
    assert_not_null(camera)

    playground.get_controller_for_test().get_attachment_state().attach(
        HandSide.Value.LEFT,
        &"HoldStartLeft",
        Vector2(450.0, 1424.0),
        NodePath("Handholds/HoldStartLeft")
    )
    playground.get_controller_for_test().get_attachment_state().attach(
        HandSide.Value.RIGHT,
        &"HoldStartRight",
        Vector2(630.0, 1424.0),
        NodePath("Handholds/HoldStartRight")
    )

    var viewport_size: Vector2 = playground.get_viewport_rect().size
    player_body.global_position = Vector2(
        player_body.global_position.x,
        camera.global_position.y + (viewport_size.y * 0.5) + playground.get_bottom_fall_margin_for_test() + 24.0
    )
    playground._physics_process(0.0)

    assert_eq(playground.get_run_session_for_test().get_state(), RunStateScript.Value.RESCUE_OFFERED)
    assert_true(playground.get_run_session_for_test().has_end_reason())
    assert_eq(playground.get_run_session_for_test().get_end_reason(), RunEndReasonScript.Value.BOTTOM_SCREEN_FALL)
    assert_eq(playground.get_controller_for_test().get_attachment_state().get_attached_hand_count(), 0)
    assert_eq(playground.get_player_for_test().get_physics_mode(), PlayerPhysicsModeScript.falling_ragdoll())

func test_run_scene_hud_displays_initial_run_snapshot() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    var height_value_label: Label = playground.get_node("UiLayer/RunHud/Panel/ContentMargin/Metrics/HeightMetric/HeightValueLabel") as Label
    var stamina_value_label: Label = playground.get_node("UiLayer/RunHud/Panel/ContentMargin/Metrics/StaminaMetric/StaminaValueLabel") as Label
    var coins_value_label: Label = playground.get_node("UiLayer/RunHud/Panel/ContentMargin/Metrics/CoinsMetric/CoinsValueLabel") as Label
    var run_end_screen: Control = playground.get_node("UiLayer/RunEndScreen") as Control

    assert_not_null(height_value_label)
    assert_not_null(stamina_value_label)
    assert_not_null(coins_value_label)
    assert_not_null(run_end_screen)
    assert_eq(height_value_label.text, "0.0 m")
    assert_eq(stamina_value_label.text, "20.0 / 20.0")
    assert_eq(coins_value_label.text, "0")
    assert_false(run_end_screen.visible)

func test_run_scene_bottom_screen_fall_shows_run_end_screen() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    var player_body: RigidBody2D = playground.get_player_body_for_test()
    var camera: Camera2D = playground.get_node("DevCamera") as Camera2D

    assert_not_null(player_body)
    assert_not_null(camera)

    var viewport_size: Vector2 = playground.get_viewport_rect().size
    player_body.global_position = Vector2(
        player_body.global_position.x,
        camera.global_position.y + (viewport_size.y * 0.5) + playground.get_bottom_fall_margin_for_test() + 24.0
    )
    playground._physics_process(0.0)

    var run_end_screen: Control = playground.get_node("UiLayer/RunEndScreen") as Control
    var title_label: Label = playground.get_node("UiLayer/RunEndScreen/CenterContainer/Panel/ContentMargin/Content/TitleLabel") as Label

    assert_not_null(run_end_screen)
    assert_not_null(title_label)
    assert_true(run_end_screen.visible)
    assert_eq(title_label.text, "Rescue Offered")

func test_run_scene_chaser_contact_ends_run_without_rescue_and_restart_resets_chaser() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    var chaser: ChaserKillZoneScript = playground.get_chaser_for_test()
    var reset_anchor: Marker2D = playground.get_node("ResetAnchor") as Marker2D
    var run_end_screen: Control = playground.get_node("UiLayer/RunEndScreen") as Control
    var title_label: Label = playground.get_node("UiLayer/RunEndScreen/CenterContainer/Panel/ContentMargin/Content/TitleLabel") as Label
    var reason_label: Label = playground.get_node("UiLayer/RunEndScreen/CenterContainer/Panel/ContentMargin/Content/ReasonLabel") as Label
    var restart_button: Button = playground.get_node("UiLayer/RunEndScreen/CenterContainer/Panel/ContentMargin/Content/RestartButton") as Button

    assert_not_null(chaser)
    assert_not_null(reset_anchor)
    assert_not_null(run_end_screen)
    assert_not_null(title_label)
    assert_not_null(reason_label)
    assert_not_null(restart_button)

    playground.get_controller_for_test().get_attachment_state().attach(
        HandSide.Value.LEFT,
        &"HoldStartLeft",
        Vector2(450.0, 1424.0),
        NodePath("Handholds/HoldStartLeft")
    )

    chaser.global_position.y = 100.0
    playground.resolve_chaser_contact_for_test()

    assert_eq(playground.get_run_session_for_test().get_state(), RunStateScript.Value.ENDED)
    assert_true(playground.get_run_session_for_test().has_end_reason())
    assert_eq(playground.get_run_session_for_test().get_end_reason(), RunEndReasonScript.Value.CHASER_CONTACT)
    assert_eq(playground.get_controller_for_test().get_attachment_state().get_attached_hand_count(), 0)
    assert_eq(playground.get_player_for_test().get_physics_mode(), PlayerPhysicsModeScript.falling_ragdoll())
    assert_true(run_end_screen.visible)
    assert_eq(title_label.text, "Run Ended")
    assert_eq(reason_label.text, "Reason: Chaser contact")

    var _emit_result: int = restart_button.emit_signal("pressed")

    var expected_reset_chaser_y: float = reset_anchor.global_position.y + (chaser.chaser_tuning.initial_spawn_offset_meters * playground.climb_tuning.pixels_per_meter) + (chaser.kill_zone_height_pixels * 0.5)

    assert_eq(playground.get_run_session_for_test().get_state(), RunStateScript.Value.CLIMBING)
    assert_false(run_end_screen.visible)
    assert_eq(chaser.global_position.y, expected_reset_chaser_y)

func test_run_scene_exposes_chaser_feedback_hooks_for_playtesting() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    var chaser: ChaserKillZoneScript = playground.get_chaser_for_test()
    var player_body: RigidBody2D = playground.get_player_body_for_test()
    var pixels_per_meter: float = playground.climb_tuning.pixels_per_meter

    assert_not_null(chaser)
    assert_not_null(player_body)

    chaser.global_position.y = player_body.global_position.y + (chaser.kill_zone_height_pixels * 0.5) + (chaser.chaser_tuning.far_distance_for_min_intensity_meters * pixels_per_meter)
    playground._physics_process(0.0)
    var far_intensity: float = playground.get_chaser_feedback_intensity_ratio_for_test()

    chaser.global_position.y = player_body.global_position.y + (chaser.kill_zone_height_pixels * 0.5) + (chaser.chaser_tuning.near_distance_for_max_intensity_meters * pixels_per_meter)
    playground._physics_process(0.0)
    var near_intensity: float = playground.get_chaser_feedback_intensity_ratio_for_test()
    var feedback_snapshot: ChaserFeedbackSnapshotScript = playground.get_chaser_feedback_snapshot_for_test()

    assert_lt(far_intensity, near_intensity)
    assert_eq(feedback_snapshot.pace_state, ChaserPacingModelScript.PaceState.CAMPING)
    assert_gte(feedback_snapshot.speed_intensity_ratio, 0.0)
    assert_lte(feedback_snapshot.speed_intensity_ratio, 1.0)

func test_run_scene_camera_follows_player_downward_after_fall_resolution() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    var player_body: RigidBody2D = playground.get_player_body_for_test()
    var camera: Camera2D = playground.get_node("DevCamera") as Camera2D

    assert_not_null(player_body)
    assert_not_null(camera)

    var viewport_size: Vector2 = playground.get_viewport_rect().size
    player_body.global_position = Vector2(
        player_body.global_position.x,
        camera.global_position.y + (viewport_size.y * 0.5) + playground.get_bottom_fall_margin_for_test() + 24.0
    )
    playground._physics_process(0.0)

    var camera_after_fall_resolution: float = camera.global_position.y
    player_body.global_position = Vector2(player_body.global_position.x, player_body.global_position.y + 220.0)
    playground._physics_process(0.0)

    assert_gt(camera.global_position.y, camera_after_fall_resolution)
    assert_eq(camera.global_position.y, player_body.global_position.y - playground.get_camera_player_lower_screen_offset_for_test())

func test_run_scene_run_end_restart_button_resets_run() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    var player_body: RigidBody2D = playground.get_player_body_for_test()
    var camera: Camera2D = playground.get_node("DevCamera") as Camera2D
    var reset_anchor: Marker2D = playground.get_node("ResetAnchor") as Marker2D

    assert_not_null(player_body)
    assert_not_null(camera)
    assert_not_null(reset_anchor)

    var viewport_size: Vector2 = playground.get_viewport_rect().size
    player_body.global_position = Vector2(
        player_body.global_position.x,
        camera.global_position.y + (viewport_size.y * 0.5) + playground.get_bottom_fall_margin_for_test() + 24.0
    )
    playground._physics_process(0.0)

    var restart_button: Button = playground.get_node("UiLayer/RunEndScreen/CenterContainer/Panel/ContentMargin/Content/RestartButton") as Button
    var run_end_screen: Control = playground.get_node("UiLayer/RunEndScreen") as Control

    assert_not_null(restart_button)
    assert_not_null(run_end_screen)
    assert_true(run_end_screen.visible)

    var _emit_result: int = restart_button.emit_signal("pressed")

    assert_eq(playground.get_run_session_for_test().get_state(), RunStateScript.Value.CLIMBING)
    assert_eq(player_body.global_position, reset_anchor.global_position)
    assert_eq(player_body.linear_velocity, Vector2.ZERO)
    assert_eq(camera.global_position.y, reset_anchor.global_position.y - playground.get_camera_player_lower_screen_offset_for_test())
    assert_false(run_end_screen.visible)

func test_run_scene_has_safe_start_block_below_spawn() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript

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

func test_run_scene_left_grip_creates_and_releases_runtime_link() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript

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

    var left_link: Line2D = playground.get_player_for_test().get_left_runtime_grip_link()
    assert_not_null(left_link)
    assert_eq(left_link.get_point_count(), 2)

    playground.get_controller_for_test().get_attachment_state().release(HandSide.Value.LEFT)
    playground.sync_grip_links_for_test()
    await get_tree().process_frame

    assert_null(playground.get_player_for_test().get_left_runtime_grip_link())

func test_run_scene_aim_preview_shows_for_unattached_hands_when_aiming() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    var input_frame: PlayerInputFrameScript = PlayerInputFrameScript.new([], [], AimInputIntentScript.new(Vector2.UP))
    playground.sync_aim_preview_for_test(input_frame)

    var left_preview: Line2D = playground.get_node_or_null("LeftAimPreview") as Line2D
    var right_preview: Line2D = playground.get_node_or_null("RightAimPreview") as Line2D
    var aim_marker: Polygon2D = playground.get_node_or_null("AimTargetMarker") as Polygon2D

    assert_not_null(left_preview)
    assert_not_null(right_preview)
    assert_not_null(aim_marker)
    assert_eq(left_preview.get_point_count(), 2)
    assert_eq(right_preview.get_point_count(), 2)

func test_run_scene_aim_preview_hides_for_attached_hand() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    playground.get_controller_for_test().get_attachment_state().attach(
        HandSide.Value.LEFT,
        &"HoldStartLeft",
        Vector2(450.0, 1424.0),
        NodePath("Handholds/HoldStartLeft")
    )

    var input_frame: PlayerInputFrameScript = PlayerInputFrameScript.new([], [], AimInputIntentScript.new(Vector2.RIGHT))
    playground.sync_aim_preview_for_test(input_frame)

    assert_null(playground.get_node_or_null("LeftAimPreview"))
    assert_not_null(playground.get_node_or_null("RightAimPreview"))
    assert_not_null(playground.get_node_or_null("AimTargetMarker"))

func test_run_scene_reset_clears_runtime_attachments_and_restarts_run() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    playground.get_controller_for_test().get_attachment_state().attach(HandSide.Value.LEFT, &"test_hold", Vector2.ZERO, NodePath("Handholds/HoldStartLeft"))
    playground.reset_for_test()

    assert_eq(playground.get_controller_for_test().get_attachment_state().get_attached_hand_count(), 0)
    assert_eq(playground.get_run_session_for_test().get_state(), RunStateScript.Value.CLIMBING)

func test_run_scene_debug_reset_action_works_while_falling() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    var player_body: RigidBody2D = playground.get_player_body_for_test()
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

func test_run_scene_stamina_fall_routes_through_service_shape() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript
    var stamina_fall_service: Object = StaminaFallServiceScript.new()

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    var player: PlayerCharacter = playground.get_player_for_test()

    assert_not_null(player)
    stamina_fall_service.call("resolve", player, playground.get_run_session_for_test())

    assert_eq(player.get_physics_mode(), PlayerPhysicsModeScript.falling_ragdoll())
    assert_eq(playground.get_run_session_for_test().get_state(), RunStateScript.Value.RESCUE_OFFERED)
    assert_true(playground.get_run_session_for_test().has_end_reason())
    assert_eq(playground.get_run_session_for_test().get_end_reason(), RunEndReasonScript.Value.STAMINA_FALL)