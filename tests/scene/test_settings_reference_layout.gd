extends GutTest

func test_settings_controls_remain_inside_portrait_viewport_after_resize() -> void:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(1080, 1920)
	add_child_autofree(viewport)
	var menu: SettingsMenu = preload("res://scenes/ui/settings_menu.tscn").instantiate() as SettingsMenu
	viewport.add_child(menu)
	var panel: Control = menu.get_node("CenterContainer/Panel") as Control
	var close: Control = menu.get_node("CloseButton") as Control
	var sizes: Array[Vector2i] = [Vector2i(1080, 1920), Vector2i(1080, 2400), Vector2i(720, 1280), Vector2i(360, 640)]
	for viewport_size: Vector2i in sizes:
		viewport.size = viewport_size
		await get_tree().process_frame
		await get_tree().process_frame
		var screen_rect: Rect2 = Rect2(Vector2.ZERO, Vector2(viewport_size)).grow(0.1)
		var panel_rect: Rect2 = panel.get_global_transform() * Rect2(Vector2.ZERO, panel.size)
		var close_rect: Rect2 = close.get_global_transform() * Rect2(Vector2.ZERO, close.size)
		assert_true(screen_rect.encloses(panel_rect), "Panel stays in the portrait viewport.")
		assert_true(screen_rect.encloses(close_rect), "Close remains accessible after resizing.")
		assert_true(close_rect.intersects(panel_rect), "Close stays attached to the header corner.")
		assert_almost_eq(panel.get_global_transform().get_scale().x, close.get_global_transform().get_scale().x, 0.001)
		for row: String in ["VolumeControl/VolumeSlider", "AudioControl/AudioSlider", "TouchSplitControl/TouchSplitSlider", "TouchDeadZoneControl/TouchDeadZoneSlider", "HapicControl/HapticsCheckBox"]:
			var control: Control = menu.get_node("CenterContainer/Panel/ControlPosition/" + row) as Control
			var control_rect: Rect2 = control.get_global_transform() * Rect2(Vector2.ZERO, control.size)
			assert_true(panel_rect.encloses(control_rect), "Setting controls stay inside the panel: " + row)
