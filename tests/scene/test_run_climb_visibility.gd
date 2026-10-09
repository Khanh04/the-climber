extends GutTest

func test_generated_holds_start_in_view_and_reach_after_restart() -> void:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(1080, 2400)
	add_child_autofree(viewport)
	var run: RunScene = preload("res://scenes/main/run_scene.tscn").instantiate() as RunScene
	run.process_mode = Node.PROCESS_MODE_DISABLED
	run.set_local_storage_adapter(InMemoryLocalStorageAdapter.new())
	var container: GeneratedChunkCoordinator = run.get_node("GeneratedChunks") as GeneratedChunkCoordinator
	var authored_container_position: Vector2 = container.position
	viewport.add_child(run)
	for pass_index: int in range(2):
		await get_tree().process_frame
		await get_tree().process_frame
		assert_eq(container.position, authored_container_position)
		var player: PlayerCharacter = run.get_node("PlayerCharacter") as PlayerCharacter
		var first_chunk: Node2D = container.get_chunk_node(0)
		assert_not_null(first_chunk)
		assert_almost_eq(first_chunk.global_position.x, player.get_body_global_position().x, 0.01)
		var visible_count: int = 0
		var nearest_left: float = INF
		var nearest_right: float = INF
		var artwork_rect: Rect2 = Rect2(0, 240, 1080, 1920)
		for child: Node in first_chunk.get_node("Handholds").get_children():
			var hold: Node2D = child as Node2D
			var screen_position: Vector2 = hold.get_global_transform_with_canvas().origin
			if artwork_rect.has_point(screen_position) and hold.is_visible_in_tree():
				visible_count += 1
			nearest_left = minf(nearest_left, hold.global_position.distance_to(player.get_left_hand_anchor_global_position()))
			nearest_right = minf(nearest_right, hold.global_position.distance_to(player.get_right_hand_anchor_global_position()))
		assert_gte(visible_count, 4, "The starting route must be visible inside the artwork frame.")
		assert_lte(nearest_left, run.climb_tuning.handhold_detection_radius_pixels, "Left hand can reach the opening holds.")
		assert_lte(nearest_right, run.climb_tuning.handhold_detection_radius_pixels, "Right hand can reach the opening holds.")
		if pass_index == 0:
			var _restart: Variant = run.call("_reset_playground")
