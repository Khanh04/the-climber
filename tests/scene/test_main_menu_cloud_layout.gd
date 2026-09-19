extends GutTest

func test_cloud_stays_aligned_with_background_when_portrait_height_changes() -> void:
	var scene: PackedScene = load("res://scenes/ui/main_menu.tscn")
	var menu: Control = scene.instantiate() as Control
	add_child_autofree(menu)
	menu.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	var background: TextureRect = menu.get_node("decor_preview/background_preview") as TextureRect
	var cloud: AnimatedSprite2D = menu.get_node("decor_preview/cloud/cloud_animated") as AnimatedSprite2D
	var sizes: Array[Vector2] = [Vector2(1080, 1920), Vector2(1080, 2400), Vector2(1080, 2340), Vector2(1080, 1920)]
	for menu_size: Vector2 in sizes:
		menu.size = menu_size
		await get_tree().process_frame
		var expected_center: Vector2 = background.get_global_rect().get_center()
		assert_almost_eq(cloud.global_position.x, expected_center.x, 0.01, "Cloud must stay horizontally centered on the background.")
		assert_almost_eq(cloud.global_position.y, expected_center.y, 0.01, "Cloud must follow the background on taller phones and after resizing back.")
		var frame_texture: Texture2D = cloud.sprite_frames.get_frame_texture(cloud.animation, cloud.frame)
		var expected_width: float = minf(background.size.x, background.size.y * background.texture.get_width() / background.texture.get_height())
		assert_almost_eq(frame_texture.get_width() * cloud.scale.x, expected_width, 0.01, "Cloud artwork must use the same drawn width as the portrait background.")
		assert_true(cloud.is_playing(), "Cloud animation must continue after resizing.")
