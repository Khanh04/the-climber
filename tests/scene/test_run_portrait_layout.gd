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
	var cloud: AnimatedSprite2D = camera.get_node("cloud") as AnimatedSprite2D
	var menu_cloud: AnimatedSprite2D = menu.get_node("decor_preview/cloud/cloud_animated") as AnimatedSprite2D
	var tree_left: Sprite2D = camera.get_node("TreeLeft") as Sprite2D
	var tree_right: Sprite2D = camera.get_node("TreeRight") as Sprite2D
	var generation_tuning: GenerationTuning = run.get("generation_tuning")
	var climb_tuning: ClimbPrototypeTuning = run.get("climb_tuning")
	var route_border: float = generation_tuning.get_half_usable_width_meters() * climb_tuning.pixels_per_meter
	var panel: Control = run.get_node("UiLayer/RunHud/Panel") as Control
	var pause_button: Control = panel.get_node("ContentMargin/Metrics/Wrapper_BtnPause/PauseButton") as Control
	var sizes: Array[Vector2i] = [Vector2i(1080, 1920), Vector2i(1080, 2400), Vector2i(1080, 2340), Vector2i(1080, 1920)]
	for viewport_size: Vector2i in sizes:
		viewport.size = viewport_size
		await get_tree().process_frame
		await get_tree().process_frame
		_assert_layer_matches(camera.get_node("background") as Sprite2D, menu.get_node("decor_preview/background_preview") as TextureRect, camera, viewport_size)
		_assert_layer_matches(camera.get_node("Moutain") as Sprite2D, menu.get_node("decor_preview/Mountaint") as TextureRect, camera, viewport_size)
		assert_almost_eq(cloud.scale.x * camera.zoom.x, menu_cloud.scale.x, 0.01)
		assert_almost_eq(cloud.scale.x, cloud.scale.y, 0.001, "Cloud must not stretch unevenly.")
		assert_eq(tree_left.scale, tree_right.scale, "Side vines must share one pixel scale.")
		var route_origin: Vector2 = run.call("_route_origin")
		var route_x: float = route_origin.x
		var left_inner_edge: float = tree_left.global_position.x + tree_left.region_rect.size.x * tree_left.scale.x
		assert_almost_eq(left_inner_edge, route_x - route_border, 0.01, "Left vine must line the route's left border.")
		assert_almost_eq(tree_right.global_position.x, route_x + route_border, 0.01, "Right vine must line the route's right border.")
		var frame_reference: TextureRect = menu.get_node("decor_preview/Tree_preview") as TextureRect
		var frame_fit: float = minf(frame_reference.size.x / frame_reference.texture.get_width(), frame_reference.size.y / frame_reference.texture.get_height())
		var frame_height: float = frame_reference.texture.get_height() * frame_fit
		var frame_top: float = (float(viewport_size.y) - frame_height) * 0.5
		var top: ColorRect = run.get_node("UiLayer/EnvironmentMatteTop") as ColorRect
		var bottom: ColorRect = run.get_node("UiLayer/EnvironmentMatteBottom") as ColorRect
		assert_almost_eq(top.get_global_rect().end.y, frame_top, 0.01)
		assert_almost_eq(bottom.position.y, frame_top + frame_height, 0.01)
		assert_almost_eq(bottom.get_global_rect().end.y, float(viewport_size.y), 0.01)
		assert_eq(top.mouse_filter, Control.MOUSE_FILTER_IGNORE)
		var viewport_rect: Rect2 = Rect2(Vector2.ZERO, Vector2(viewport.size))
		var panel_rect: Rect2 = panel.get_global_transform() * Rect2(Vector2.ZERO, panel.size)
		var pause_rect: Rect2 = pause_button.get_global_transform() * Rect2(Vector2.ZERO, pause_button.size)
		assert_true(viewport_rect.encloses(panel_rect), "HUD must fit the portrait viewport.")
		assert_true(panel_rect.encloses(pause_rect), "Pause button must remain inside the HUD.")

func test_vine_collision_traces_the_vines_on_their_own_layer() -> void:
	var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
	var run: Node2D = scene.instantiate() as Node2D
	run.process_mode = Node.PROCESS_MODE_DISABLED
	add_child_autofree(run)
	await get_tree().process_frame
	var player_body: RigidBody2D = run.get_node("PlayerCharacter/Head") as RigidBody2D
	for vine_path: String in ["DevCamera/TreeLeft", "DevCamera/TreeRight"]:
		var vine: Sprite2D = run.get_node(vine_path) as Sprite2D
		var body: StaticBody2D = vine.get_node("Collision") as StaticBody2D
		assert_eq(body.collision_layer, 64, "Vine collision needs its own layer so coin/hazard/chaser areas ignore it.")
		assert_eq(body.collision_mask, 0)
		assert_true(player_body.collision_mask & body.collision_layer != 0, "Player must collide with %s." % vine_path)
		var art_rect: Rect2 = Rect2(Vector2.ZERO, vine.region_rect.size)
		var image: Image = vine.texture.get_image()
		var shape_count: int = 0
		for child: Node in body.get_children():
			var shape: CollisionPolygon2D = child as CollisionPolygon2D
			assert_not_null(shape)
			shape_count += 1
			for point: Vector2 in shape.polygon:
				assert_true(art_rect.grow(0.01).has_point(point), "%s collision must stay inside the vine art." % vine_path)
		assert_gt(shape_count, 0)
		# Every tile blocks at the vine trunk (opaque); the open sky past the leaf tips does not.
		var trunk_column: int = 2 if vine_path.ends_with("Left") else image.get_width() - 3
		var sky_column: int = image.get_width() - 1 if vine_path.ends_with("Left") else 0
		assert_gt(image.get_pixel(trunk_column, 180).a, 0.0)
		assert_eq(image.get_pixel(sky_column, 180).a, 0.0)
		var tile_count: int = int(vine.region_rect.size.y) / image.get_height()
		for tile: int in tile_count:
			var tile_y: float = 180.0 + image.get_height() * tile
			assert_true(_body_contains(body, Vector2(trunk_column, tile_y)), "%s tile %d trunk must collide." % [vine_path, tile])
			assert_false(_body_contains(body, Vector2(sky_column, tile_y)), "Open sky past the leaf tips must not collide.")

func test_side_vines_cover_the_view_at_any_height_and_stay_fixed_to_the_wall() -> void:
	var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
	var run: Node2D = scene.instantiate() as Node2D
	run.process_mode = Node.PROCESS_MODE_DISABLED
	add_child_autofree(run)
	await get_tree().process_frame
	var camera: Camera2D = run.get_node("DevCamera") as Camera2D
	var route_origin: Vector2 = run.call("_route_origin")
	var anchor_y: float = route_origin.y
	var half_view_height: float = run.get_viewport_rect().size.y / camera.zoom.y * 0.5
	var start_y: float = camera.global_position.y
	for climb: float in [0.0, 37.0, 1000.0, 123456.0, 2500000.0]:
		camera.global_position.y = start_y - climb
		run.call("_pin_side_vines")
		for vine_path: String in ["DevCamera/TreeLeft", "DevCamera/TreeRight"]:
			var vine: Sprite2D = run.get_node(vine_path) as Sprite2D
			var tile_height: float = vine.texture.get_height() * vine.scale.y
			var top: float = vine.global_position.y
			var bottom: float = top + vine.region_rect.size.y * vine.scale.y
			assert_true(top <= camera.global_position.y - half_view_height, "%s must reach above the view after climbing %s px." % [vine_path, climb])
			assert_true(bottom >= camera.global_position.y + half_view_height, "%s must reach below the view after climbing %s px." % [vine_path, climb])
			var grid_offset: float = fposmod(top - anchor_y, tile_height)
			assert_true(minf(grid_offset, tile_height - grid_offset) < 0.5, "%s tiles must stay on the world grid, not slide with the camera." % vine_path)

func _body_contains(body: StaticBody2D, point: Vector2) -> bool:
	for child: Node in body.get_children():
		if Geometry2D.is_point_in_polygon(point, (child as CollisionPolygon2D).polygon):
			return true
	return false

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
