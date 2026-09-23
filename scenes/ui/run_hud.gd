class_name RunHud
extends Control

signal pause_requested

const RunHudStateScript = preload("res://src/ui/run_hud_state.gd")

@onready var _height_value_label: Label = get_node("Panel/ContentMargin/Metrics/Wrapper_Height/HeightMetric/HeightValueLabel") as Label
@onready var _stamina_value_label: Label = get_node("Panel/ContentMargin/Metrics/Wrapper_Stamina/StaminaMetric/StaminaValueLabel") as Label
@onready var _stamina_bar: TextureProgressBar = get_node("Panel/ContentMargin/Metrics/Wrapper_Stamina/StaminaMetric/StaminaBar") as TextureProgressBar
@onready var _wallet_value_label: Label = get_node("Panel/ContentMargin/Metrics/Wrapper_Wallet/WalletMetric/WalletValueLabel") as Label
@onready var _coins_value_label: Label = get_node("Panel/ContentMargin/Metrics/Wrapper_Wallet/WalletMetric/CoinsValueLabel") as Label
@onready var _pause_button: Button = get_node("Panel/ContentMargin/Metrics/Wrapper_BtnPause/PauseButton") as Button

# Artwork uses a 270x480 canvas, displayed at 4x in the 1080x1920 design.
# Scale the whole HUD uniformly and center it with the environment on tall phones.
func _align_panel() -> void:
	var panel: Control = get_node("Panel") as Control
	var design_size: Vector2 = Vector2(1080.0, 1920.0)
	var fit_scale: float = minf(size.x / design_size.x, size.y / design_size.y)
	panel.size = design_size
	panel.scale = Vector2.ONE * fit_scale
	panel.position = (size - design_size * fit_scale) * 0.5

func _ready() -> void:
	var _resize_connect_result: int = resized.connect(_align_panel)
	_align_panel.call_deferred()
	_validate_required_nodes()
	var _pause_connect_result: int = _pause_button.connect(&"pressed", Callable(self, "_on_pause_button_pressed"))

func apply_state(state: RefCounted) -> void:
	Validation.require_condition(state != null, "RunHud requires a state snapshot.")
	Validation.require_condition(state is RunHudStateScript, "RunHud requires a RunHudState snapshot.")

	var typed_state: RunHudStateScript = state as RunHudStateScript
	typed_state.assert_valid()

	var height_meters: float = typed_state.height_meters
	var current_stamina_seconds: float = typed_state.current_stamina_seconds
	var max_stamina_seconds: float = typed_state.max_stamina_seconds
	var wallet_coins: int = typed_state.wallet_coins
	var run_earned_coins: int = typed_state.run_earned_coins

	_height_value_label.text = "%.1f m" % height_meters
	_stamina_value_label.text = "%.1f / %.1f" % [current_stamina_seconds, max_stamina_seconds]
	_stamina_bar.max_value = max_stamina_seconds
	_stamina_bar.value = current_stamina_seconds
	_wallet_value_label.text = str(wallet_coins)
	_coins_value_label.text = "+%d" % run_earned_coins
	
func _validate_required_nodes() -> void:
	Validation.require_condition(_height_value_label != null, "RunHud requires HeightValueLabel.")
	Validation.require_condition(_stamina_value_label != null, "RunHud requires StaminaValueLabel.")
	Validation.require_condition(_stamina_bar != null, "RunHud requires StaminaBar.")
	Validation.require_condition(_wallet_value_label != null, "RunHud requires WalletValueLabel.")
	Validation.require_condition(_coins_value_label != null, "RunHud requires CoinsValueLabel.")
	Validation.require_condition(_pause_button != null, "RunHud requires PauseButton.")

func _on_pause_button_pressed() -> void:
	pause_requested.emit()
