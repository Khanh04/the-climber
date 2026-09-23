extends GutTest

const Snapshot = preload("res://src/platform/storage/app_settings_snapshot.gd")
const Runtime = preload("res://src/platform/storage/app_settings_and_save_storage_runtime.gd")
const MemoryStorage = preload("res://src/platform/storage/in_memory_local_storage_adapter.gd")
const AudioAdapter = preload("res://src/platform/audio/godot_audio_settings_adapter.gd")
const Presenter = preload("res://src/ui/settings_presenter.gd")

func test_old_saves_default_music_to_full_volume_and_reject_invalid_new_values() -> void:
	var payload: Dictionary = Snapshot.new().to_dictionary()
	var _removed: bool = payload.erase("music_volume_ratio")
	assert_true(Snapshot.is_dictionary_valid(payload))
	assert_eq(Snapshot.from_dictionary(payload).music_volume_ratio, 1.0)
	for invalid_value: Variant in [-0.1, 1.1, "loud", true, NAN]:
		payload["music_volume_ratio"] = invalid_value
		assert_false(Snapshot.is_dictionary_valid(payload))

func test_music_round_trip_reaches_presenter_without_changing_master() -> void:
	var snapshot: AppSettingsSnapshot = Snapshot.new()
	snapshot.master_volume_ratio = 0.8
	snapshot.music_volume_ratio = 0.35
	var loaded: AppSettingsSnapshot = Snapshot.from_dictionary(snapshot.to_dictionary())
	var state: SettingsState = Presenter.new().build_state(loaded, true)
	assert_eq(state.music_volume_ratio, 0.35)
	assert_eq(state.master_volume_ratio, 0.8)

func test_music_setting_persists_and_controls_only_music_bus() -> void:
	var master: int = AudioServer.get_bus_index("Master")
	var music: int = AudioServer.get_bus_index("Music")
	assert_gte(music, 0)
	var original_master: float = AudioServer.get_bus_volume_db(master)
	var original_master_mute: bool = AudioServer.is_bus_mute(master)
	var original_music: float = AudioServer.get_bus_volume_db(music)
	var original_music_mute: bool = AudioServer.is_bus_mute(music)
	var memory: InMemoryLocalStorageAdapter = MemoryStorage.new()
	var runtime: AppSettingsAndSaveStorageRuntime = Runtime.new(memory)
	var adapter: GodotAudioSettingsAdapter = AudioAdapter.new()
	runtime.load_or_create_app_settings()
	runtime.set_master_volume_ratio(0.8, adapter)
	runtime.set_music_volume_ratio(0.25, adapter)
	assert_almost_eq(db_to_linear(AudioServer.get_bus_volume_db(music)), 0.25, 0.0001)
	assert_almost_eq(adapter.get_master_volume_ratio(), 0.8, 0.0001)
	assert_eq(AudioServer.get_bus_send(music), &"Master")
	var reloaded: AppSettingsAndSaveStorageRuntime = Runtime.new(memory)
	reloaded.load_or_create_app_settings()
	assert_eq(reloaded.get_app_settings_snapshot().music_volume_ratio, 0.25)
	runtime.set_music_volume_ratio(0.0, adapter)
	assert_true(AudioServer.is_bus_mute(music))
	assert_false(AudioServer.is_bus_mute(master))
	runtime.set_music_volume_ratio(0.5, adapter)
	assert_false(AudioServer.is_bus_mute(music))
	AudioServer.set_bus_volume_db(master, original_master)
	AudioServer.set_bus_mute(master, original_master_mute)
	AudioServer.set_bus_volume_db(music, original_music)
	AudioServer.set_bus_mute(music, original_music_mute)

func test_menu_loads_music_silently_and_emits_music_only_when_dragged() -> void:
	var menu: SettingsMenu = preload("res://scenes/ui/settings_menu.tscn").instantiate() as SettingsMenu
	add_child_autofree(menu)
	watch_signals(menu)
	menu.apply_state(SettingsState.new(true, false, 0.8, true, 0.5, 0.0, 0.35))
	var slider: HSlider = menu.get_node("CenterContainer/Panel/ControlPosition/AudioControl/AudioSlider") as HSlider
	assert_eq(slider.value, 35.0)
	assert_eq(slider.tooltip_text, "Nhạc nền: 35%")
	assert_signal_not_emitted(menu, "music_volume_changed")
	slider.value = 60.0
	assert_signal_emitted_with_parameters(menu, "music_volume_changed", [0.6])
	assert_signal_not_emitted(menu, "master_volume_changed")
	assert_signal_not_emitted(menu, "audio_muted_changed")
