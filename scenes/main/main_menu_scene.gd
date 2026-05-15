class_name MainMenuScene
extends Control

const MainMenuScript = preload("res://scenes/ui/main_menu.gd")
const RUN_SCENE_PATH: String = "res://scenes/main/run_scene.tscn"

@onready var _main_menu: MainMenuScript = %MainMenu

func _ready() -> void:
	_validate_required_nodes()
	var _start_connect_result: int = _main_menu.connect(&"start_requested", Callable(self, "_on_start_requested"))
	var _settings_connect_result: int = _main_menu.connect(&"settings_requested", Callable(self, "_on_settings_requested"))

func _on_start_requested() -> void:
	var change_result: Error = get_tree().change_scene_to_file(RUN_SCENE_PATH)
	Validation.require_condition(change_result == OK, "MainMenuScene could not load RunScene.")

func _on_settings_requested() -> void:
	Validation.require_condition(false, "MainMenuScene settings are not implemented yet.")

func _validate_required_nodes() -> void:
	Validation.require_condition(_main_menu != null, "MainMenuScene requires MainMenu.")
	Validation.require_condition(_main_menu is MainMenuScript, "MainMenuScene requires a MainMenu implementation.")