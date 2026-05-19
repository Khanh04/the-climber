class_name MainMenuScene
extends Control

const AppSettingsSnapshotScript = preload("res://src/platform/storage/app_settings_snapshot.gd")
const AppSettingsStorageScript = preload("res://src/platform/storage/app_settings_storage.gd")
const AudioSettingsAdapterScript = preload("res://src/platform/audio/audio_settings_adapter.gd")
const GodotAudioSettingsAdapterScript = preload("res://src/platform/audio/godot_audio_settings_adapter.gd")
const JsonFileLocalStorageAdapterScript = preload("res://src/platform/storage/json_file_local_storage_adapter.gd")
const LocalStorageAdapterScript = preload("res://src/platform/storage/local_storage_adapter.gd")
const MainMenuScript = preload("res://scenes/ui/main_menu.gd")
const SettingsMenuScript = preload("res://scenes/ui/settings_menu.gd")
const SettingsMenuScene = preload("res://scenes/ui/settings_menu.tscn")
const SettingsPresenterScript = preload("res://src/ui/settings_presenter.gd")
const RUN_SCENE_PATH: String = "res://scenes/main/run_scene.tscn"
const TUTORIAL_SCENE_PATH: String = "res://scenes/main/tutorial_scene.tscn"

@onready var _main_menu: MainMenuScript = %MainMenu

var _app_settings_snapshot: AppSettingsSnapshotScript = null
var _app_settings_storage: AppSettingsStorageScript = null
var _audio_settings_adapter: AudioSettingsAdapterScript = GodotAudioSettingsAdapterScript.new()
var _local_storage_adapter: LocalStorageAdapterScript = JsonFileLocalStorageAdapterScript.new()
var _settings_menu: SettingsMenuScript = null
var _settings_presenter: SettingsPresenterScript = SettingsPresenterScript.new()

func _ready() -> void:
	_validate_required_nodes()
	_initialize_app_settings_storage()
	_load_or_create_app_settings()
	_apply_app_settings()
	var _start_connect_result: int = _main_menu.connect(&"start_requested", Callable(self, "_on_start_requested"))
	var _tutorial_connect_result: int = _main_menu.connect(&"tutorial_requested", Callable(self, "_on_tutorial_requested"))
	var _settings_connect_result: int = _main_menu.connect(&"settings_requested", Callable(self, "_on_settings_requested"))

func set_local_storage_adapter(local_storage_adapter: RefCounted) -> void:
	Validation.require_condition(local_storage_adapter != null, "MainMenuScene requires a local storage adapter.")
	Validation.require_condition(local_storage_adapter is LocalStorageAdapterScript, "MainMenuScene requires a LocalStorageAdapter implementation.")
	_local_storage_adapter = local_storage_adapter as LocalStorageAdapterScript
	if not is_node_ready():
		return

	_initialize_app_settings_storage()
	_load_or_create_app_settings()
	_apply_app_settings()
	_refresh_settings_menu()

func set_audio_settings_adapter(audio_settings_adapter: RefCounted) -> void:
	Validation.require_condition(audio_settings_adapter != null, "MainMenuScene requires an audio settings adapter.")
	Validation.require_condition(audio_settings_adapter is AudioSettingsAdapterScript, "MainMenuScene requires an AudioSettingsAdapter implementation.")
	_audio_settings_adapter = audio_settings_adapter as AudioSettingsAdapterScript
	if not is_node_ready():
		return

	_apply_app_settings()

func get_settings_menu_for_test() -> SettingsMenuScript:
	return _settings_menu

func _on_start_requested() -> void:
	_change_to_scene(RUN_SCENE_PATH)

func _on_tutorial_requested() -> void:
	_change_to_scene(TUTORIAL_SCENE_PATH)

func _change_to_scene(scene_path: String) -> void:
	Validation.require_condition(not scene_path.is_empty(), "MainMenuScene scene path cannot be empty.")
	var change_result: Error = get_tree().change_scene_to_file(scene_path)
	Validation.require_condition(change_result == OK, "MainMenuScene could not load the requested scene.")

func _on_settings_requested() -> void:
	_show_settings_menu()

func _initialize_app_settings_storage() -> void:
	Validation.require_condition(_local_storage_adapter != null, "MainMenuScene requires local storage before initializing app settings.")
	_app_settings_storage = AppSettingsStorageScript.new(_local_storage_adapter)

func _load_or_create_app_settings() -> void:
	Validation.require_condition(_app_settings_storage != null, "MainMenuScene requires app settings storage before loading settings.")
	if _app_settings_storage.has_snapshot():
		_app_settings_snapshot = _app_settings_storage.load_snapshot()
	else:
		_app_settings_snapshot = AppSettingsSnapshotScript.new()

func _apply_app_settings() -> void:
	Validation.require_condition(_app_settings_snapshot != null, "MainMenuScene requires app settings before applying them.")
	Validation.require_condition(_audio_settings_adapter != null, "MainMenuScene requires an audio settings adapter before applying settings.")
	_audio_settings_adapter.apply_master_settings(_app_settings_snapshot.master_volume_ratio, _app_settings_snapshot.audio_muted)

func _show_settings_menu() -> void:
	_ensure_settings_menu()
	_refresh_settings_menu(true)

func _ensure_settings_menu() -> void:
	if _settings_menu != null:
		return

	var settings_node: Node = SettingsMenuScene.instantiate()
	Validation.require_condition(settings_node != null, "MainMenuScene settings menu scene must instantiate a node.")
	Validation.require_condition(settings_node is SettingsMenuScript, "MainMenuScene settings menu scene must instantiate SettingsMenu.")
	_settings_menu = settings_node as SettingsMenuScript
	add_child(_settings_menu)
	var _closed_connect_result: int = _settings_menu.connect(&"closed", Callable(self, "_on_settings_closed"))
	var _audio_muted_connect_result: int = _settings_menu.connect(&"audio_muted_changed", Callable(self, "_on_settings_audio_muted_changed"))
	var _volume_connect_result: int = _settings_menu.connect(&"master_volume_changed", Callable(self, "_on_settings_master_volume_changed"))
	var _haptics_connect_result: int = _settings_menu.connect(&"haptics_enabled_changed", Callable(self, "_on_settings_haptics_enabled_changed"))
	var _touch_split_connect_result: int = _settings_menu.connect(&"touch_split_changed", Callable(self, "_on_settings_touch_split_changed"))
	var _touch_dead_zone_connect_result: int = _settings_menu.connect(&"touch_center_dead_zone_changed", Callable(self, "_on_settings_touch_center_dead_zone_changed"))

func _refresh_settings_menu(visible: bool = false) -> void:
	if _settings_menu == null:
		return

	Validation.require_condition(_app_settings_snapshot != null, "MainMenuScene requires app settings before refreshing settings UI.")
	_settings_menu.apply_state(_settings_presenter.build_state(_app_settings_snapshot, visible))

func _persist_app_settings() -> void:
	Validation.require_condition(_app_settings_storage != null, "MainMenuScene requires app settings storage before saving settings.")
	Validation.require_condition(_app_settings_snapshot != null, "MainMenuScene requires app settings before saving settings.")
	_app_settings_snapshot.assert_valid()
	_app_settings_storage.save_snapshot(_app_settings_snapshot)
	_apply_app_settings()
	_refresh_settings_menu(true)

func _on_settings_closed() -> void:
	_refresh_settings_menu(false)

func _on_settings_audio_muted_changed(audio_muted: bool) -> void:
	_app_settings_snapshot.audio_muted = audio_muted
	_persist_app_settings()

func _on_settings_master_volume_changed(master_volume_ratio: float) -> void:
	_app_settings_snapshot.master_volume_ratio = master_volume_ratio
	_persist_app_settings()

func _on_settings_haptics_enabled_changed(haptics_enabled: bool) -> void:
	_app_settings_snapshot.haptics_enabled = haptics_enabled
	_persist_app_settings()

func _on_settings_touch_split_changed(touch_split_ratio: float) -> void:
	_app_settings_snapshot.touch_split_ratio = touch_split_ratio
	_persist_app_settings()

func _on_settings_touch_center_dead_zone_changed(touch_center_dead_zone_ratio: float) -> void:
	_app_settings_snapshot.touch_center_dead_zone_ratio = touch_center_dead_zone_ratio
	_persist_app_settings()

func _validate_required_nodes() -> void:
	Validation.require_condition(_main_menu != null, "MainMenuScene requires MainMenu.")
	Validation.require_condition(_main_menu is MainMenuScript, "MainMenuScene requires a MainMenu implementation.")
