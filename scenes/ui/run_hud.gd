class_name RunHud
extends Control

signal pause_requested

const RunHudStateScript = preload("res://src/ui/run_hud_state.gd")

@onready var _height_value_label: Label = get_node("Panel/ContentMargin/Metrics/Wrapper_Height/HeightMetric/HeightValueLabel") as Label
@onready var _stamina_value_label: Label = get_node("Panel/ContentMargin/Metrics/Wrapper_Stamina/StaminaMetric/StaminaValueLabel") as Label
@onready var _stamina_bar: ProgressBar = get_node("Panel/ContentMargin/Metrics/Wrapper_Stamina/StaminaMetric/StaminaBar") as ProgressBar
@onready var _wallet_value_label: Label = get_node("Panel/ContentMargin/Metrics/Wrapper_Wallet/WalletMetric/WalletValueLabel") as Label
@onready var _pause_button: Button = get_node("Panel/ContentMargin/Metrics/Wrapper_BtnPause/PauseButton") as Button

func _ready() -> void:
	_validate_required_nodes()
	var _pause_connect_result: int = _pause_button.connect(&"pressed", Callable(self, "_on_pause_button_pressed"))

func apply_state(state: RefCounted) -> void:
	Validation.require_condition(state != null, "RunHud requires a state snapshot.")
	Validation.require_condition(state is RunHudStateScript, "RunHud requires a RunHudState snapshot.")

	var typed_state: Object = state
	typed_state.call("assert_valid")

	var height_meters: float = typed_state.get("height_meters")
	var current_stamina_seconds: float = typed_state.get("current_stamina_seconds")
	var max_stamina_seconds: float = typed_state.get("max_stamina_seconds")
	var wallet_coins: int = typed_state.get("wallet_coins")


	_height_value_label.text = "%.1f m" % height_meters
	_stamina_value_label.text = "%.1f / %.1f" % [current_stamina_seconds, max_stamina_seconds]
	_stamina_bar.max_value = max_stamina_seconds
	_stamina_bar.value = current_stamina_seconds
	_wallet_value_label.text = str(wallet_coins)
	

func _validate_required_nodes() -> void:
	Validation.require_condition(_height_value_label != null, "RunHud requires HeightValueLabel.")
	Validation.require_condition(_stamina_value_label != null, "RunHud requires StaminaValueLabel.")
	Validation.require_condition(_stamina_bar != null, "RunHud requires StaminaBar.")
	Validation.require_condition(_wallet_value_label != null, "RunHud requires WalletValueLabel.")
	Validation.require_condition(_pause_button != null, "RunHud requires PauseButton.")

func _on_pause_button_pressed() -> void:
	pause_requested.emit()
