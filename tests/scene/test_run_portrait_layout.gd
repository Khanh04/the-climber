extends GutTest

func test_environment_and_hud_stay_aligned_on_phone_aspect_ratios() -> void:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(1080, 1920)
	add_child_autofree(viewport)
	var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
	var run: Node2D = scene.instantiate() as Node2D
	run.process_mode = Node.PROCESS_MODE_DISABLED
	viewport.add_child(run)
	var camera: Camera2D = run.get_node("DevCamera") as Camera2D
	var cloud: AnimatedSprite2D = camera.get_node("cloud") as AnimatedSprite2D
	var mountains: Sprite2D = camera.get_node("Sprite2D") as Sprite2D
	var trees: Sprite2D = camera.get_node("Tree") as Sprite2D
	var panel: Control = run.get_node("UiLayer/RunHud/Panel") as Control
	var pause_button: Control = panel.get_node("ContentMargin/Metrics/Wrapper_BtnPause/PauseButton") as Control
	var heights: Array[int] = [1920, 2400, 2340, 1920]
	for height: int in heights:
		viewport.size = Vector2i(1080, height)
		await get_tree().process_frame
		await get_tree().process_frame
		assert_eq(cloud.position, Vector2.ZERO, "Cloud must share the environment center.")
		assert_eq(mountains.position, Vector2.ZERO)
		assert_eq(trees.position, Vector2.ZERO)
		assert_almost_eq(cloud.scale.x, cloud.scale.y, 0.001, "Cloud must not stretch unevenly.")
		assert_almost_eq(cloud.scale.x, trees.scale.x, 0.001)
		assert_almost_eq(mountains.scale.x, trees.scale.x, 0.001)
		var artwork_width: float = trees.texture.get_width() * trees.scale.x * camera.zoom.x
		assert_almost_eq(artwork_width, 1080.0, 0.01, "Decorations must retain the main menu's full-width artwork frame.")
		var viewport_rect: Rect2 = Rect2(Vector2.ZERO, Vector2(viewport.size))
		var panel_rect: Rect2 = panel.get_global_transform() * Rect2(Vector2.ZERO, panel.size)
		var pause_rect: Rect2 = pause_button.get_global_transform() * Rect2(Vector2.ZERO, pause_button.size)
		assert_true(viewport_rect.encloses(panel_rect), "HUD must fit the portrait viewport.")
		assert_true(panel_rect.encloses(pause_rect), "Pause button must remain inside the HUD.")
