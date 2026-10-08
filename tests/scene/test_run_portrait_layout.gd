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
	var tree_left: Sprite2D = camera.get_node("TreeLeft") as Sprite2D
	var tree_right: Sprite2D = camera.get_node("TreeRight") as Sprite2D
	var anchor_x: float = (run.get_node("ResetAnchor") as Marker2D).global_position.x
	var generation_tuning: GenerationTuning = run.get("generation_tuning")
	var climb_tuning: ClimbPrototypeTuning = run.get("climb_tuning")
	var route_border: float = generation_tuning.get_half_usable_width_meters() * climb_tuning.pixels_per_meter
	var panel: Control = run.get_node("UiLayer/RunHud/Panel") as Control
	var pause_button: Control = panel.get_node("ContentMargin/Metrics/Wrapper_BtnPause/PauseButton") as Control
	var heights: Array[int] = [1920, 2400, 2340, 1920]
	for height: int in heights:
		viewport.size = Vector2i(1080, height)
		await get_tree().process_frame
		await get_tree().process_frame
		assert_eq(cloud.position, Vector2.ZERO, "Cloud must share the environment center.")
		assert_eq(mountains.position, Vector2.ZERO)
		assert_almost_eq(cloud.scale.x, cloud.scale.y, 0.001, "Cloud must not stretch unevenly.")
		assert_almost_eq(cloud.scale.x, tree_left.scale.x, 0.001)
		assert_almost_eq(mountains.scale.x, tree_left.scale.x, 0.001)
		assert_eq(tree_left.scale, tree_right.scale, "Side vines must share one pixel scale.")
		var left_inner_edge: float = tree_left.global_position.x + tree_left.region_rect.size.x * tree_left.scale.x
		assert_almost_eq(left_inner_edge, anchor_x - route_border, 0.01, "Left vine must line the route's left border.")
		assert_almost_eq(tree_right.global_position.x, anchor_x + route_border, 0.01, "Right vine must line the route's right border.")
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
	var anchor_y: float = (run.get_node("ResetAnchor") as Marker2D).global_position.y
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
