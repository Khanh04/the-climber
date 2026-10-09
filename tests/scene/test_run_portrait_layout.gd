extends GutTest

func test_run_environment_matches_main_menu_on_portrait_screens() -> void:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(1080, 1920)
	add_child_autofree(viewport)
	var run: RunScene = preload("res://scenes/main/run_scene.tscn").instantiate() as RunScene
	run.set_local_storage_adapter(InMemoryLocalStorageAdapter.new())
	run.process_mode = Node.PROCESS_MODE_DISABLED
	viewport.add_child(run)
	var menu: Control = preload("res://scenes/ui/main_menu.tscn").instantiate() as Control
	viewport.add_child(menu)
	menu.hide()
	var camera: Camera2D = run.get_node("DevCamera") as Camera2D
	var sizes: Array[Vector2i] = [Vector2i(1080, 1920), Vector2i(1080, 2400), Vector2i(1080, 2340), Vector2i(1080, 1920)]
	for viewport_size: Vector2i in sizes:
		viewport.size = viewport_size
		await get_tree().process_frame
		await get_tree().process_frame
		_assert_layer_matches(camera.get_node("background") as Sprite2D, menu.get_node("decor_preview/background_preview") as TextureRect, camera, viewport_size)
		_assert_layer_matches(camera.get_node("Moutain") as Sprite2D, menu.get_node("decor_preview/Mountaint") as TextureRect, camera, viewport_size)
		_assert_layer_matches(camera.get_node("Tree") as Sprite2D, menu.get_node("decor_preview/Tree_preview") as TextureRect, camera, viewport_size)
		var cloud: AnimatedSprite2D = camera.get_node("cloud") as AnimatedSprite2D
		var menu_cloud: AnimatedSprite2D = menu.get_node("decor_preview/cloud/cloud_animated") as AnimatedSprite2D
		assert_almost_eq(cloud.scale.x * camera.zoom.x, menu_cloud.scale.x, 0.01)
		assert_almost_eq(cloud.scale.x, cloud.scale.y, 0.001)
		var tree_reference: TextureRect = menu.get_node("decor_preview/Tree_preview") as TextureRect
		var tree_fit: float = minf(tree_reference.size.x / tree_reference.texture.get_width(), tree_reference.size.y / tree_reference.texture.get_height())
		var frame_height: float = tree_reference.texture.get_height() * tree_fit
		var frame_top: float = (float(viewport_size.y) - frame_height) * 0.5
		var top: ColorRect = run.get_node("UiLayer/EnvironmentMatteTop") as ColorRect
		var bottom: ColorRect = run.get_node("UiLayer/EnvironmentMatteBottom") as ColorRect
		assert_almost_eq(top.get_global_rect().end.y, frame_top, 0.01)
		assert_almost_eq(bottom.position.y, frame_top + frame_height, 0.01)
		assert_almost_eq(bottom.get_global_rect().end.y, float(viewport_size.y), 0.01)
		assert_eq(top.mouse_filter, Control.MOUSE_FILTER_IGNORE)

func _assert_layer_matches(layer: Sprite2D, reference: TextureRect, camera: Camera2D, viewport_size: Vector2i) -> void:
	var reference_scale: float = minf(reference.size.x / reference.texture.get_width(), reference.size.y / reference.texture.get_height())
	var expected_size: Vector2 = reference.texture.get_size() * reference_scale
	var expected_center: Vector2 = reference.get_global_rect().get_center()
	var actual_size: Vector2 = layer.texture.get_size() * layer.scale * camera.zoom
	var actual_center: Vector2 = Vector2(viewport_size) * 0.5 + layer.position * camera.zoom
	assert_almost_eq(actual_size.x, expected_size.x, 1.01)
	assert_almost_eq(actual_size.y, expected_size.y, 1.01)
	assert_almost_eq(actual_center.x, expected_center.x, 1.01)
	assert_almost_eq(actual_center.y, expected_center.y, 1.01)
	assert_almost_eq(layer.scale.x, layer.scale.y, 0.001, "Keep the original image proportions.")
