extends GutTest

const RunEndScreenStateScript = preload("res://src/ui/run_end_screen_state.gd")
const RunHudStateScript = preload("res://src/ui/run_hud_state.gd")
const RunStateScript = preload("res://src/gameplay/run/run_state.gd")
const RunEndReasonScript = preload("res://src/core/run_end_reason.gd")
const RunUiViewScript = preload("res://src/ui/run_ui_view.gd")

var _restart_requested: bool = false
var _post_run_coin_doubler_requested: bool = false

func test_run_hud_scene_wires_required_nodes() -> void:
	var scene: PackedScene = load("res://scenes/ui/run_hud.tscn")
	var hud_node: Node = scene.instantiate()

	assert_not_null(hud_node)
	assert_true(hud_node is Control)
	var hud: Control = hud_node as Control
	assert_not_null(hud)
	add_child_autofree(hud)
	await get_tree().process_frame

	assert_not_null(hud.get_node_or_null("Panel/ContentMargin/Metrics/HeightMetric/HeightValueLabel"))
	assert_not_null(hud.get_node_or_null("Panel/ContentMargin/Metrics/StaminaMetric/StaminaValueLabel"))
	assert_not_null(hud.get_node_or_null("Panel/ContentMargin/Metrics/StaminaMetric/StaminaBar"))
	assert_not_null(hud.get_node_or_null("Panel/ContentMargin/Metrics/WalletMetric/WalletValueLabel"))
	assert_not_null(hud.get_node_or_null("Panel/ContentMargin/Metrics/CoinsMetric/CoinsValueLabel"))

func test_run_hud_scene_displays_height_stamina_and_run_coins() -> void:
	var scene: PackedScene = load("res://scenes/ui/run_hud.tscn")
	var hud_node: Node = scene.instantiate()

	assert_not_null(hud_node)
	assert_true(hud_node is Control)
	var hud: Control = hud_node as Control
	assert_not_null(hud)
	add_child_autofree(hud)
	await get_tree().process_frame

	hud.call("apply_state", RunHudStateScript.new(18.5, 7.0, 20.0, 9, 4, RunStateScript.Value.CLIMBING))

	var height_value_label: Label = hud.get_node("Panel/ContentMargin/Metrics/HeightMetric/HeightValueLabel") as Label
	var stamina_value_label: Label = hud.get_node("Panel/ContentMargin/Metrics/StaminaMetric/StaminaValueLabel") as Label
	var stamina_bar: ProgressBar = hud.get_node("Panel/ContentMargin/Metrics/StaminaMetric/StaminaBar") as ProgressBar
	var wallet_value_label: Label = hud.get_node("Panel/ContentMargin/Metrics/WalletMetric/WalletValueLabel") as Label
	var coins_value_label: Label = hud.get_node("Panel/ContentMargin/Metrics/CoinsMetric/CoinsValueLabel") as Label

	assert_not_null(height_value_label)
	assert_not_null(stamina_value_label)
	assert_not_null(stamina_bar)
	assert_not_null(wallet_value_label)
	assert_not_null(coins_value_label)
	assert_eq(height_value_label.text, "18.5 m")
	assert_eq(stamina_value_label.text, "7.0 / 20.0")
	assert_eq(stamina_bar.max_value, 20.0)
	assert_eq(stamina_bar.value, 7.0)
	assert_eq(wallet_value_label.text, "9")
	assert_eq(coins_value_label.text, "4")

func test_run_end_screen_shows_summary_and_emits_restart() -> void:
	var scene: PackedScene = load("res://scenes/ui/run_end_screen.tscn")
	var screen_node: Node = scene.instantiate()

	assert_not_null(screen_node)
	assert_true(screen_node is Control)
	var screen: Control = screen_node as Control
	assert_not_null(screen)
	add_child_autofree(screen)
	await get_tree().process_frame

	_restart_requested = false
	_post_run_coin_doubler_requested = false
	var _connect_result: int = screen.connect(&"restart_requested", Callable(self, "_mark_restart_requested"))
	var _post_run_coin_doubler_connect_result: int = screen.connect(&"post_run_coin_doubler_requested", Callable(self, "_mark_post_run_coin_doubler_requested"))
	screen.call(
		"apply_state",
		RunEndScreenStateScript.new(
			true,
			true,
			23.0,
			6,
			6,
			true,
			RunEndReasonScript.Value.BOTTOM_SCREEN_FALL
		)
	)

	var title_label: Label = screen.get_node("CenterContainer/Panel/ContentMargin/Content/TitleLabel") as Label
	var reason_label: Label = screen.get_node("CenterContainer/Panel/ContentMargin/Content/ReasonLabel") as Label
	var summary_label: Label = screen.get_node("CenterContainer/Panel/ContentMargin/Content/SummaryLabel") as Label
	var post_run_coin_doubler_button: Button = screen.get_node("CenterContainer/Panel/ContentMargin/Content/PostRunCoinDoublerButton") as Button
	var restart_button: Button = screen.get_node("CenterContainer/Panel/ContentMargin/Content/RestartButton") as Button

	assert_true(screen.visible)
	assert_not_null(title_label)
	assert_not_null(reason_label)
	assert_not_null(summary_label)
	assert_not_null(post_run_coin_doubler_button)
	assert_not_null(restart_button)
	assert_eq(title_label.text, "Rescue Offered")
	assert_eq(reason_label.text, "Reason: Bottom-screen fall")
	assert_string_contains(summary_label.text, "Height: 23.0 m")
	assert_string_contains(summary_label.text, "Wallet Coins: 6")
	assert_string_contains(summary_label.text, "Run Coins: 6")
	assert_false(post_run_coin_doubler_button.visible)

	var _emit_result: int = restart_button.emit_signal("pressed")

	assert_true(_restart_requested)
	assert_false(_post_run_coin_doubler_requested)

func test_run_end_screen_shows_post_run_coin_doubler_button_when_available() -> void:
	var scene: PackedScene = load("res://scenes/ui/run_end_screen.tscn")
	var screen_node: Node = scene.instantiate()

	assert_not_null(screen_node)
	assert_true(screen_node is Control)
	var screen: Control = screen_node as Control
	assert_not_null(screen)
	add_child_autofree(screen)
	await get_tree().process_frame

	_post_run_coin_doubler_requested = false
	var _connect_result: int = screen.connect(&"post_run_coin_doubler_requested", Callable(self, "_mark_post_run_coin_doubler_requested"))
	screen.call(
		"apply_state",
		RunEndScreenStateScript.new(
			true,
			false,
			31.0,
			9,
			5,
			true,
			RunEndReasonScript.Value.CHASER_CONTACT,
			true
		)
	)

	var post_run_coin_doubler_button: Button = screen.get_node("CenterContainer/Panel/ContentMargin/Content/PostRunCoinDoublerButton") as Button

	assert_not_null(post_run_coin_doubler_button)
	assert_true(post_run_coin_doubler_button.visible)

	var _emit_result: int = post_run_coin_doubler_button.emit_signal("pressed")

	assert_true(_post_run_coin_doubler_requested)

func test_run_ui_view_applies_snapshots_to_both_controls() -> void:
	var hud_scene: PackedScene = load("res://scenes/ui/run_hud.tscn")
	var screen_scene: PackedScene = load("res://scenes/ui/run_end_screen.tscn")
	var hud_node: Node = hud_scene.instantiate()
	var screen_node: Node = screen_scene.instantiate()

	assert_not_null(hud_node)
	assert_not_null(screen_node)
	assert_true(hud_node is Control)
	assert_true(screen_node is Control)

	var hud: Control = hud_node as Control
	var screen: Control = screen_node as Control
	assert_not_null(hud)
	assert_not_null(screen)
	add_child_autofree(hud)
	add_child_autofree(screen)
	await get_tree().process_frame

	var ui_view = RunUiViewScript.new(hud, screen)
	ui_view.apply_state_snapshots(
		RunHudStateScript.new(14.0, 5.0, 8.0, 7, 2, RunStateScript.Value.CLIMBING),
		RunEndScreenStateScript.new(true, true, 14.0, 7, 2, true, RunEndReasonScript.Value.BOTTOM_SCREEN_FALL)
	)

	var height_value_label: Label = hud.get_node("Panel/ContentMargin/Metrics/HeightMetric/HeightValueLabel") as Label
	var title_label: Label = screen.get_node("CenterContainer/Panel/ContentMargin/Content/TitleLabel") as Label

	assert_not_null(height_value_label)
	assert_not_null(title_label)
	assert_eq(height_value_label.text, "14.0 m")
	assert_true(screen.visible)
	assert_eq(title_label.text, "Rescue Offered")

func _mark_restart_requested() -> void:
	_restart_requested = true

func _mark_post_run_coin_doubler_requested() -> void:
	_post_run_coin_doubler_requested = true