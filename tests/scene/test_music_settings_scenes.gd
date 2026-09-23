extends GutTest

func test_main_menu_music_slider_saves_and_reopens() -> void:
	await _exercise_scene(preload("res://scenes/main/main_menu_scene.tscn"))

func test_run_scene_music_slider_saves_and_reopens() -> void:
	await _exercise_scene(preload("res://scenes/main/run_scene.tscn"))

func _exercise_scene(scene: PackedScene) -> void:
	var memory: InMemoryLocalStorageAdapter = InMemoryLocalStorageAdapter.new()
	var coordinator: Node = scene.instantiate()
	var _set_result: Variant = coordinator.call("set_local_storage_adapter", memory)
	add_child_autofree(coordinator)
	await get_tree().process_frame
	var _show_result: Variant = coordinator.call("_show_settings_menu")
	var menu: SettingsMenu = coordinator.find_child("SettingsMenu", true, false) as SettingsMenu
	assert_not_null(menu)
	var slider: HSlider = menu.get_node("CenterContainer/Panel/ControlPosition/AudioControl/AudioSlider") as HSlider
	slider.value = 25.0
	var saved: AppSettingsSnapshot = AppSettingsStorage.new(memory).load_snapshot()
	assert_eq(saved.music_volume_ratio, 0.25)
	assert_eq(saved.master_volume_ratio, 1.0)
	var music: int = AudioServer.get_bus_index("Music")
	assert_almost_eq(db_to_linear(AudioServer.get_bus_volume_db(music)), 0.25, 0.0001)
	(menu.get_node("CloseButton") as BaseButton).pressed.emit()
	assert_false(menu.visible)
	var _reopen_result: Variant = coordinator.call("_show_settings_menu")
	assert_true(menu.visible)
	assert_eq(slider.value, 25.0)
