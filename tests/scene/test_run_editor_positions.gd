extends GutTest

func test_authored_positions_survive_ready_and_restart() -> void:
	var run: RunScene = preload("res://scenes/main/run_scene.tscn").instantiate() as RunScene
	run.set_local_storage_adapter(InMemoryLocalStorageAdapter.new())
	run.process_mode = Node.PROCESS_MODE_DISABLED
	var paths: Array[String] = ["PlayerCharacter", "ChaserKillZone", "ResetAnchor", "GeneratedChunks", "Handholds", "Handholds/HoldSafePlatform", "Floor", "DevCamera"]
	var expected: Dictionary[String, Vector2] = {}
	for path: String in paths:
		var node: Node2D = run.get_node(path) as Node2D
		expected[path] = node.position
	var player_root: Node2D = run.get_node("PlayerCharacter") as Node2D
	var head: Node2D = run.get_node("PlayerCharacter/Head") as Node2D
	var expected_body_position: Vector2 = run.transform * player_root.transform * head.position
	add_child_autofree(run)
	_check_positions(run, expected)
	var player: PlayerCharacter = run.get_node("PlayerCharacter") as PlayerCharacter
	assert_eq(player.get_body_global_position(), expected_body_position)
	player.set_body_global_position(Vector2(800.0, -1000.0))
	(run.get_node("ChaserKillZone") as Node2D).position += Vector2(20, -500)
	(run.get_node("DevCamera") as Node2D).position += Vector2(20, -200)
	var _reset_result: Variant = run.call("_reset_playground")
	_check_positions(run, expected)
	assert_eq(player.get_body_global_position(), expected_body_position)
	var chunks: GeneratedChunkCoordinator = run.get_node("GeneratedChunks") as GeneratedChunkCoordinator
	assert_eq(chunks.get_chunk_node(0).global_position, expected_body_position)
	var start_y: float = run.get("_start_y")
	assert_eq(start_y, expected_body_position.y)

func test_legacy_reset_anchor_mode_is_available() -> void:
	var run: RunScene = preload("res://scenes/main/run_scene.tscn").instantiate() as RunScene
	run.set_local_storage_adapter(InMemoryLocalStorageAdapter.new())
	run.use_editor_start_positions = false
	run.process_mode = Node.PROCESS_MODE_DISABLED
	add_child_autofree(run)
	var player: PlayerCharacter = run.get_node("PlayerCharacter") as PlayerCharacter
	var anchor: Node2D = run.get_node("ResetAnchor") as Node2D
	assert_eq(player.get_body_global_position(), anchor.global_position)
	assert_eq((run.get_node("GeneratedChunks") as Node2D).global_position, anchor.global_position)

func test_authored_environment_and_camera_framing_survive_resize() -> void:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(1080, 1920)
	add_child_autofree(viewport)
	var run: RunScene = preload("res://scenes/main/run_scene.tscn").instantiate() as RunScene
	run.set_local_storage_adapter(InMemoryLocalStorageAdapter.new())
	run.process_mode = Node.PROCESS_MODE_DISABLED
	var camera: Camera2D = run.get_node("DevCamera") as Camera2D
	var authored_zoom: Vector2 = camera.zoom
	var authored_camera_position: Vector2 = camera.position
	var authored_camera_global_position: Vector2 = run.transform * camera.position
	var expected: Dictionary[String, Transform2D] = {}
	for path: String in ["DevCamera/background", "DevCamera/Moutain", "DevCamera/cloud", "Handholds", "Handholds/HoldSafePlatform/Visual", "Floor", "Floor/Visual", "ResetAnchor"]:
		expected[path] = (run.get_node(path) as Node2D).transform
	viewport.add_child(run)
	var sizes: Array[Vector2i] = [Vector2i(1080, 1920), Vector2i(1080, 2400), Vector2i(360, 800), Vector2i(1080, 1920)]
	for viewport_size: Vector2i in sizes:
		viewport.size = viewport_size
		await get_tree().process_frame
		await get_tree().process_frame
		for path: String in expected:
			assert_eq((run.get_node(path) as Node2D).transform, expected[path], path + " preserves position, scale and rotation.")
		assert_eq(camera.position, authored_camera_position)
		var ui_design_scale: float = minf(float(viewport_size.x) / 1080.0, float(viewport_size.y) / 1920.0)
		assert_almost_eq(camera.zoom.x, authored_zoom.x * ui_design_scale, 0.001)
		assert_almost_eq(camera.zoom.y, authored_zoom.y * ui_design_scale, 0.001)
		var floor_node: Node2D = run.get_node("Floor") as Node2D
		var projected_floor: Vector2 = Vector2(viewport_size) * 0.5 + (floor_node.global_position - camera.global_position) * camera.zoom
		var design_floor: Vector2 = (projected_floor - Vector2(viewport_size) * 0.5) / ui_design_scale
		assert_almost_eq(design_floor.x, (floor_node.global_position.x - authored_camera_global_position.x) * authored_zoom.x, 0.01)
		assert_almost_eq(design_floor.y, (floor_node.global_position.y - authored_camera_global_position.y) * authored_zoom.y, 0.01)

func _check_positions(run: RunScene, expected: Dictionary[String, Vector2]) -> void:
	for path: String in expected:
		assert_eq((run.get_node(path) as Node2D).position, expected[path], path + " keeps its saved scene position.")
