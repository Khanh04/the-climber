class_name MainMenu
extends Control

signal start_requested
signal settings_requested

@onready var _start_button: Button = get_node("CenterContainer/Panel/ContentMargin/Content/StartButton") as Button
@onready var _settings_button: Button = get_node("CenterContainer/Panel/ContentMargin/Content/SettingsButton") as Button

func _ready() -> void:
	_validate_required_nodes()
	var _start_connect_result: int = _start_button.connect(&"pressed", Callable(self, "_on_start_button_pressed"))
	var _settings_connect_result: int = _settings_button.connect(&"pressed", Callable(self, "_on_settings_button_pressed"))

func _on_start_button_pressed() -> void:
	start_requested.emit()

func _on_settings_button_pressed() -> void:
	settings_requested.emit()

func _validate_required_nodes() -> void:
	Validation.require_condition(_start_button != null, "MainMenu requires StartButton.")
	Validation.require_condition(_settings_button != null, "MainMenu requires SettingsButton.")