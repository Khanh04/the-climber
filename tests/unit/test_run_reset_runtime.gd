extends GutTest

const ChaserKillZoneScript = preload("res://scenes/chaser/chaser_kill_zone.gd")
const ChaserPacingModelScript = preload("res://src/gameplay/chaser/chaser_pacing_model.gd")
const ChaserTuningScript = preload("res://resources/config/chaser_tuning.gd")
const ClimbPrototypeControllerScript = preload("res://src/gameplay/player/climb_prototype_controller.gd")
const ClimbPrototypeTuningScript = preload("res://resources/config/climb_prototype_tuning.gd")
const GeneratedChunkCoordinatorScript = preload("res://src/gameplay/generation/generated_chunk_coordinator.gd")
const HandSideScript = preload("res://src/gameplay/player/hand_side.gd")
const PlayerCharacterScript = preload("res://scenes/player/player_character.gd")
const RunGameplayNodeRefsScript = preload("res://src/gameplay/run/run_gameplay_node_refs.gd")
const RunResetRuntimeScript = preload("res://src/gameplay/run/run_reset_runtime.gd")
const RunStateScript = preload("res://src/gameplay/run/run_state.gd")
const StaminaRuntimeScript = preload("res://src/gameplay/player/stamina_runtime.gd")
const StaminaTuningScript = preload("res://resources/config/stamina_tuning.gd")

func test_create_started_run_session_returns_fresh_active_session() -> void:
	var runtime: RunResetRuntimeScript = RunResetRuntimeScript.new()

	var run_session = runtime.create_started_run_session()

	assert_eq(run_session.get_state(), RunStateScript.Value.CLIMBING)
	assert_eq(run_session.get_height_meters(), 0.0)
	assert_eq(run_session.get_run_earned_coins(), 0)
	assert_false(run_session.has_used_rescue())
	assert_false(run_session.has_end_reason())

func test_reset_gameplay_state_resets_controller_player_camera_and_pacing_model() -> void:
	var runtime: RunResetRuntimeScript = RunResetRuntimeScript.new()
	var fixture: Node2D = await _build_runtime_fixture()
	var player: PlayerCharacterScript = fixture.get_node("Player") as PlayerCharacterScript
	var chaser: ChaserKillZoneScript = fixture.get_node("Chaser") as ChaserKillZoneScript
	var camera: Camera2D = fixture.get_node("Camera") as Camera2D
	var reset_anchor: Marker2D = fixture.get_node("ResetAnchor") as Marker2D
	var generated_chunk_coordinator: GeneratedChunkCoordinatorScript = fixture.get_node("GeneratedChunkCoordinator") as GeneratedChunkCoordinatorScript
	var starter_handholds_root: Node2D = fixture.get_node("Handholds") as Node2D
	var controller: ClimbPrototypeControllerScript = ClimbPrototypeControllerScript.new(
		ClimbPrototypeTuningScript.new(),
		StaminaRuntimeScript.new(StaminaTuningScript.new())
	)
	var chaser_pacing_model: ChaserPacingModelScript = ChaserPacingModelScript.new(ChaserTuningScript.new())
	var gameplay_nodes: RunGameplayNodeRefsScript = RunGameplayNodeRefsScript.new(
		player,
		chaser,
		generated_chunk_coordinator,
		reset_anchor,
		camera,
		starter_handholds_root
	)

	controller.get_attachment_state().attach(HandSideScript.Value.LEFT, &"left_hold", Vector2(40.0, 32.0), NodePath("left_hold"))
	chaser_pacing_model.record_height(6.0, 1.5)
	player.reset_physics(Vector2(120.0, 180.0))
	var player_body: RigidBody2D = player.get_player_body()
	player_body.global_rotation = 0.4
	player_body.linear_velocity = Vector2(30.0, -14.0)
	player_body.angular_velocity = 2.5
	camera.global_position = Vector2(320.0, 512.0)

	runtime.reset_gameplay_state(gameplay_nodes, controller, chaser_pacing_model, false, 160.0)

	assert_eq(controller.get_attachment_state().get_attached_hand_count(), 0)
	assert_eq(player_body.global_position, reset_anchor.global_position)
	assert_eq(player_body.global_rotation, 0.0)
	assert_eq(player_body.linear_velocity, Vector2.ZERO)
	assert_eq(player_body.angular_velocity, 0.0)
	assert_eq(camera.global_position, Vector2(reset_anchor.global_position.x, reset_anchor.global_position.y - 160.0))
	assert_eq(chaser_pacing_model.get_recent_vertical_progress_meters(), 0.0)

func _build_runtime_fixture() -> Node2D:
	var root: Node2D = Node2D.new()
	root.name = &"RuntimeFixture"
	add_child_autofree(root)

	var player_scene: PackedScene = load("res://scenes/player/player_character.tscn")
	var chaser_scene: PackedScene = load("res://scenes/chaser/chaser_kill_zone.tscn")
	var player_node: Node = player_scene.instantiate()
	var chaser_node: Node = chaser_scene.instantiate()
	assert_true(player_node is PlayerCharacterScript)
	assert_true(chaser_node is ChaserKillZoneScript)
	var player: PlayerCharacterScript = player_node as PlayerCharacterScript
	var chaser: ChaserKillZoneScript = chaser_node as ChaserKillZoneScript
	player.name = &"Player"
	chaser.name = &"Chaser"
	root.add_child(player)
	root.add_child(chaser)

	var generated_chunk_coordinator: GeneratedChunkCoordinatorScript = GeneratedChunkCoordinatorScript.new()
	generated_chunk_coordinator.name = &"GeneratedChunkCoordinator"
	root.add_child(generated_chunk_coordinator)

	var reset_anchor: Marker2D = Marker2D.new()
	reset_anchor.name = &"ResetAnchor"
	reset_anchor.global_position = Vector2(220.0, 360.0)
	root.add_child(reset_anchor)

	var camera: Camera2D = Camera2D.new()
	camera.name = &"Camera"
	root.add_child(camera)

	var starter_handholds_root: Node2D = Node2D.new()
	starter_handholds_root.name = &"Handholds"
	root.add_child(starter_handholds_root)

	await get_tree().process_frame
	return root