class_name PauseMenu
extends Control

signal resume_requested
signal restart_requested
signal new_seed_run_requested
signal main_menu_requested
signal settings_requested

const PauseMenuStateScript = preload("res://src/ui/pause_menu_state.gd")


@onready var _resume_button: Button = get_node("CenterContainer/Panel/ContentMargin/Content/ResumeButton") as Button
@onready var _restart_button: Button = get_node("CenterContainer/Panel/ContentMargin/Content/RestartButton") as Button
@onready var _new_seed_run_button: Button = get_node("CenterContainer/Panel/ContentMargin/Content/NewSeedRunButton") as Button
@onready var _main_menu_button: Button = get_node("CenterContainer/Panel/ContentMargin/Content/MainMenuButton") as Button
@onready var _settings_button: Button = get_node("CenterContainer/Panel/ContentMargin/Content/SettingsButton") as Button

@onready var _panel_frame: Control = $CenterContainer
@onready var _height_value: Label = $CenterContainer/Panel/ContentMargin/Content/HeightValue
@onready var _coin_value: Label = $CenterContainer/Panel/ContentMargin/Content/CoinValue

# Settings replaces the artwork, but the run stays paused underneath it.
func set_settings_obscured(obscured: bool) -> void:
	_panel_frame.visible = not obscured

func _ready() -> void:
	_validate_required_nodes()
	var _resume_connect_result: int = _resume_button.connect(&"pressed", Callable(self, "_on_resume_button_pressed"))
	var _restart_connect_result: int = _restart_button.connect(&"pressed", Callable(self, "_on_restart_button_pressed"))
	var _new_seed_run_connect_result: int = _new_seed_run_button.connect(&"pressed", Callable(self, "_on_new_seed_run_button_pressed"))
	var _main_menu_connect_result: int = _main_menu_button.connect(&"pressed", Callable(self, "_on_main_menu_button_pressed"))
	var _settings_connect_result: int = _settings_button.connect(&"pressed", Callable(self, "_on_settings_button_pressed"))

func apply_state(state: RefCounted) -> void:
	Validation.require_condition(state != null, "PauseMenu requires a state snapshot.")
	Validation.require_condition(state is PauseMenuStateScript, "PauseMenu requires a PauseMenuState snapshot.")
	var typed_state: PauseMenuStateScript = state as PauseMenuStateScript
	typed_state.assert_valid()

	visible = typed_state.visible
	# Copy the current run snapshot into the visible labels whenever Pause refreshes.
	_height_value.text = "%.1f m" % typed_state.height_meters
	_height_value.tooltip_text = "Độ cao cao nhất lượt này: %.1f m" % typed_state.height_meters
	_coin_value.text = str(typed_state.run_earned_coins)
	_coin_value.tooltip_text = "Xu lượt này: %d\nXu trong ví: %d" % [typed_state.run_earned_coins, typed_state.wallet_coins]

func _unhandled_input(event: InputEvent) -> void:
	if not visible or not _panel_frame.visible:
		return

	if event.is_action_pressed(&"pause_menu"):
		resume_requested.emit()
		get_viewport().set_input_as_handled()

func _on_resume_button_pressed() -> void:
	resume_requested.emit()

func _on_restart_button_pressed() -> void:
	restart_requested.emit()

func _on_new_seed_run_button_pressed() -> void:
	new_seed_run_requested.emit()

func _on_main_menu_button_pressed() -> void:
	main_menu_requested.emit()

func _on_settings_button_pressed() -> void:
	settings_requested.emit()

func _validate_required_nodes() -> void:
	Validation.require_condition(_height_value != null, "PauseMenu requires HeightValue.")
	Validation.require_condition(_coin_value != null, "PauseMenu requires CoinValue.")
	Validation.require_condition(_resume_button != null, "PauseMenu requires ResumeButton.")
	Validation.require_condition(_restart_button != null, "PauseMenu requires RestartButton.")
	Validation.require_condition(_new_seed_run_button != null, "PauseMenu requires NewSeedRunButton.")
	Validation.require_condition(_main_menu_button != null, "PauseMenu requires MainMenuButton.")
	Validation.require_condition(_settings_button != null, "PauseMenu requires SettingsButton.")
