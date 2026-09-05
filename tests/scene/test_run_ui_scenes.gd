extends GutTest

const RunEndScreenStateScript = preload("res://src/ui/run_end_screen_state.gd")
const RunHudStateScript = preload("res://src/ui/run_hud_state.gd")
const RunStateScript = preload("res://src/gameplay/run/run_state.gd")
const RunEndReasonScript = preload("res://src/core/run_end_reason.gd")
const TutorialOverlayStateScript = preload("res://src/ui/tutorial_overlay_state.gd")
const RunUiViewScript = preload("res://src/ui/run_ui_view.gd")
const SettingsStateScript = preload("res://src/ui/settings_state.gd")
const StoreItemStateScript = preload("res://src/ui/store_item_state.gd")
const StoreStateScript = preload("res://src/ui/store_state.gd")
const CosmeticLoadoutScript = preload("res://resources/config/cosmetic_loadout.gd")
const CosmeticSlotScript = preload("res://src/cosmetics/cosmetic_slot.gd")
const InMemoryLocalStorageAdapterScript = preload("res://src/platform/storage/in_memory_local_storage_adapter.gd")
const PauseMenuStateScript = preload("res://src/ui/pause_menu_state.gd")

var _restart_requested: bool = false
var _new_seed_run_requested: bool = false
var _main_menu_requested: bool = false
var _start_requested: bool = false
var _tutorial_requested: bool = false
var _rewarded_continue_requested: bool = false
var _post_run_coin_doubler_requested: bool = false
var _store_requested: bool = false
var _pause_requested: bool = false
var _resume_requested: bool = false
var _settings_requested: bool = false
var _settings_closed: bool = false
var _settings_audio_muted: bool = false
var _settings_master_volume_ratio: float = -1.0
var _settings_haptics_enabled: bool = false
var _settings_touch_split_ratio: float = -1.0
var _settings_touch_dead_zone_ratio: float = -1.0
var _selected_store_item_id: StringName = StringName()
var _purchase_store_item_id: StringName = StringName()
var _equip_store_item_id: StringName = StringName()

func test_project_launches_to_main_menu_scene() -> void:
	var raw_main_scene_path: Variant = ProjectSettings.get_setting("application/run/main_scene")
	assert_true(raw_main_scene_path is String)
	var main_scene_path: String = raw_main_scene_path
	assert_eq(main_scene_path, "res://scenes/main/main_menu_scene.tscn")

func test_main_menu_scene_wires_required_nodes() -> void:
	var scene: PackedScene = load("res://scenes/main/main_menu_scene.tscn")
	var menu_scene_node: Node = scene.instantiate()
	var local_storage: InMemoryLocalStorageAdapterScript = InMemoryLocalStorageAdapterScript.new()

	assert_not_null(menu_scene_node)
	assert_true(menu_scene_node is Control)
	var menu_scene: Control = menu_scene_node as Control
	assert_not_null(menu_scene)
	menu_scene.call("set_local_storage_adapter", local_storage)
	add_child_autofree(menu_scene)
	await get_tree().process_frame

	assert_not_null(menu_scene.get_node_or_null("MainMenu"))
	assert_not_null(menu_scene.get_node_or_null("MainMenu/CenterContainer/Panel/ContentMargin/Content/StartButton"))
	assert_not_null(menu_scene.get_node_or_null("MainMenu/CenterContainer/Panel/ContentMargin/Content/TutorialButton"))
	assert_not_null(menu_scene.get_node_or_null("MainMenu/CenterContainer/Panel/ContentMargin/Content/SettingsButton"))
	assert_not_null(menu_scene.get_node_or_null("MainMenu/CenterContainer/Panel/ContentMargin/Content/StoreButton"))

func test_main_menu_emits_start_tutorial_settings_and_store_requests() -> void:
	var scene: PackedScene = load("res://scenes/ui/main_menu.tscn")
	var menu_node: Node = scene.instantiate()

	assert_not_null(menu_node)
	assert_true(menu_node is Control)
	var menu: Control = menu_node as Control
	assert_not_null(menu)
	add_child_autofree(menu)
	await get_tree().process_frame

	_start_requested = false
	_tutorial_requested = false
	_settings_requested = false
	_store_requested = false
	var _start_connect_result: int = menu.connect(&"start_requested", Callable(self, "_mark_start_requested"))
	var _tutorial_connect_result: int = menu.connect(&"tutorial_requested", Callable(self, "_mark_tutorial_requested"))
	var _settings_connect_result: int = menu.connect(&"settings_requested", Callable(self, "_mark_settings_requested"))
	var _store_connect_result: int = menu.connect(&"store_requested", Callable(self, "_mark_store_requested"))
	var start_button: TextureButton = menu.get_node("CenterContainer/Panel/ContentMargin/Content/StartButton") as TextureButton
	var tutorial_button: TextureButton = menu.get_node("CenterContainer/Panel/ContentMargin/Content/TutorialButton") as TextureButton
	var settings_button: TextureButton = menu.get_node("CenterContainer/Panel/ContentMargin/Content/SettingsButton") as TextureButton
	var store_button: Button = menu.get_node("CenterContainer/Panel/ContentMargin/Content/StoreButton") as Button

	assert_not_null(start_button)
	assert_not_null(tutorial_button)
	assert_not_null(settings_button)
	assert_not_null(store_button)
	assert_false(tutorial_button.disabled)
	assert_false(settings_button.disabled)
	assert_false(store_button.disabled)
	var _start_emit_result: int = start_button.emit_signal("pressed")
	var _tutorial_emit_result: int = tutorial_button.emit_signal("pressed")
	var _settings_emit_result: int = settings_button.emit_signal("pressed")
	var _store_emit_result: int = store_button.emit_signal("pressed")

	assert_true(_start_requested)
	assert_true(_tutorial_requested)
	assert_true(_settings_requested)
	assert_true(_store_requested)

func test_main_menu_scene_store_lists_and_equips_a_character() -> void:
	var scene: PackedScene = load("res://scenes/main/main_menu_scene.tscn")
	var menu_scene_node: Node = scene.instantiate()
	var local_storage: InMemoryLocalStorageAdapterScript = InMemoryLocalStorageAdapterScript.new()

	assert_not_null(menu_scene_node)
	var menu_scene: Control = menu_scene_node as Control
	assert_not_null(menu_scene)
	menu_scene.call("set_local_storage_adapter", local_storage)
	add_child_autofree(menu_scene)
	await get_tree().process_frame

	var main_menu: Node = menu_scene.get_node("MainMenu")
	var store_button: Button = main_menu.get_node("CenterContainer/Panel/ContentMargin/Content/StoreButton") as Button
	var _store_emit_result: int = store_button.emit_signal("pressed")

	var store_shell: Control = menu_scene.call("get_store_shell_for_test")
	assert_not_null(store_shell)
	assert_true(store_shell.visible)

	var slot_filter: OptionButton = store_shell.get_node("CenterContainer/Panel/ContentMargin/Content/SlotFilterOption") as OptionButton
	var item_list: ItemList = store_shell.get_node("CenterContainer/Panel/ContentMargin/Content/ItemList") as ItemList
	slot_filter.select(1) # "Character" filter, per StoreShell._populate_slot_filter_options
	var _filter_emit_result: int = slot_filter.emit_signal("item_selected", 1)

	var chr1_index: int = -1
	for index in range(item_list.get_item_count()):
		if item_list.get_item_text(index).findn("CHR1") >= 0:
			chr1_index = index
	assert_gte(chr1_index, 0)

	var _select_emit_result: int = item_list.emit_signal("item_selected", chr1_index)
	var equip_button: Button = store_shell.get_node("CenterContainer/Panel/ContentMargin/Content/Actions/EquipButton") as Button
	assert_false(equip_button.disabled)
	var _equip_emit_result: int = equip_button.emit_signal("pressed")

	var updated_loadout: CosmeticLoadoutScript = menu_scene.get("cosmetic_loadout")
	assert_eq(updated_loadout.player_appearance_id, &"chr1")

func test_menu_buttons_use_mobile_sized_touch_targets() -> void:
	var main_menu_scene: PackedScene = load("res://scenes/ui/main_menu.tscn")
	var pause_menu_scene: PackedScene = load("res://scenes/ui/pause_menu.tscn")
	var settings_menu_scene: PackedScene = load("res://scenes/ui/settings_menu.tscn")
	var main_menu_node: Node = main_menu_scene.instantiate()
	var pause_menu_node: Node = pause_menu_scene.instantiate()
	var settings_menu_node: Node = settings_menu_scene.instantiate()

	assert_not_null(main_menu_node)
	assert_not_null(pause_menu_node)
	assert_not_null(settings_menu_node)
	assert_true(main_menu_node is Control)
	assert_true(pause_menu_node is Control)
	assert_true(settings_menu_node is Control)
	var main_menu: Control = main_menu_node as Control
	var pause_menu: Control = pause_menu_node as Control
	var settings_menu: Control = settings_menu_node as Control
	assert_not_null(main_menu)
	assert_not_null(pause_menu)
	assert_not_null(settings_menu)
	add_child_autofree(main_menu)
	add_child_autofree(pause_menu)
	add_child_autofree(settings_menu)
	await get_tree().process_frame

	var start_button: TextureButton = main_menu.get_node("CenterContainer/Panel/ContentMargin/Content/StartButton") as TextureButton
	var tutorial_button: TextureButton = main_menu.get_node("CenterContainer/Panel/ContentMargin/Content/TutorialButton") as TextureButton
	var main_settings_button: TextureButton = main_menu.get_node("CenterContainer/Panel/ContentMargin/Content/SettingsButton") as TextureButton
	var resume_button: Button = pause_menu.get_node("CenterContainer/Panel/ContentMargin/Content/ResumeButton") as Button
	var restart_button: Button = pause_menu.get_node("CenterContainer/Panel/ContentMargin/Content/RestartButton") as Button
	var pause_settings_button: Button = pause_menu.get_node("CenterContainer/Panel/ContentMargin/Content/SettingsButton") as Button
	var close_button: Button = settings_menu.get_node("CenterContainer/Panel/ControlPosition/CloseButton") as Button

	assert_not_null(start_button)
	assert_not_null(tutorial_button)
	assert_not_null(main_settings_button)
	assert_not_null(resume_button)
	assert_not_null(restart_button)
	assert_not_null(pause_settings_button)
	assert_not_null(close_button)
	assert_eq(start_button.size_flags_horizontal, 3)
	assert_eq(tutorial_button.size_flags_horizontal, 3)
	assert_eq(main_settings_button.size_flags_horizontal, 3)
	assert_eq(resume_button.size_flags_horizontal, 3)
	assert_eq(restart_button.size_flags_horizontal, 3)
	assert_eq(pause_settings_button.size_flags_horizontal, 3)
	assert_gte(start_button.custom_minimum_size.y, 84.0)
	assert_gte(tutorial_button.custom_minimum_size.y, 84.0)
	assert_gte(main_settings_button.custom_minimum_size.y, 84.0)
	assert_gte(resume_button.custom_minimum_size.y, 72.0)
	assert_gte(restart_button.custom_minimum_size.y, 72.0)
	assert_gte(pause_settings_button.custom_minimum_size.y, 72.0)
	assert_gte(close_button.custom_minimum_size.y, 60.0)

func test_menu_panels_fit_portrait_phone_widths_better() -> void:
	var main_menu_scene: PackedScene = load("res://scenes/ui/main_menu.tscn")
	var pause_menu_scene: PackedScene = load("res://scenes/ui/pause_menu.tscn")
	var settings_menu_scene: PackedScene = load("res://scenes/ui/settings_menu.tscn")
	var main_menu_node: Node = main_menu_scene.instantiate()
	var pause_menu_node: Node = pause_menu_scene.instantiate()
	var settings_menu_node: Node = settings_menu_scene.instantiate()

	assert_not_null(main_menu_node)
	assert_not_null(pause_menu_node)
	assert_not_null(settings_menu_node)
	assert_true(main_menu_node is Control)
	assert_true(pause_menu_node is Control)
	assert_true(settings_menu_node is Control)
	var main_menu: Control = main_menu_node as Control
	var pause_menu: Control = pause_menu_node as Control
	var settings_menu: Control = settings_menu_node as Control
	assert_not_null(main_menu)
	assert_not_null(pause_menu)
	assert_not_null(settings_menu)
	add_child_autofree(main_menu)
	add_child_autofree(pause_menu)
	add_child_autofree(settings_menu)
	await get_tree().process_frame

	var main_panel: TextureRect = main_menu.get_node("CenterContainer/Panel") as TextureRect
	var pause_panel: PanelContainer = pause_menu.get_node("CenterContainer/Panel") as PanelContainer
	var settings_panel: PanelContainer = settings_menu.get_node("CenterContainer/Panel") as PanelContainer
	var main_content: VBoxContainer = main_menu.get_node("CenterContainer/Panel/ContentMargin/Content") as VBoxContainer
	var pause_content: VBoxContainer = pause_menu.get_node("CenterContainer/Panel/ContentMargin/Content") as VBoxContainer

	assert_not_null(main_panel)
	assert_not_null(pause_panel)
	assert_not_null(settings_panel)
	assert_not_null(main_content)
	assert_not_null(pause_content)
	assert_lte(main_panel.custom_minimum_size.x, 360.0)
	assert_lte(pause_panel.custom_minimum_size.x, 360.0)
	assert_lte(settings_panel.custom_minimum_size.x, 388.0)
	assert_lte(main_content.get_theme_constant("separation"), 12)
	assert_lte(pause_content.get_theme_constant("separation"), 10)

func test_run_hud_scene_wires_required_nodes() -> void:
	var scene: PackedScene = load("res://scenes/ui/run_hud.tscn")
	var hud_node: Node = scene.instantiate()

	assert_not_null(hud_node)
	assert_true(hud_node is Control)
	var hud: Control = hud_node as Control
	assert_not_null(hud)
	add_child_autofree(hud)
	await get_tree().process_frame

	assert_not_null(hud.get_node_or_null("Panel/ContentMargin/Metrics/Wrapper_Height/HeightMetric/HeightValueLabel"))
	assert_not_null(hud.get_node_or_null("Panel/ContentMargin/Metrics/Wrapper_Stamina/StaminaMetric/StaminaValueLabel"))
	assert_not_null(hud.get_node_or_null("Panel/ContentMargin/Metrics/Wrapper_Stamina/StaminaMetric/StaminaBar"))
	assert_not_null(hud.get_node_or_null("Panel/ContentMargin/Metrics/Wrapper_Wallet/WalletMetric/WalletValueLabel"))
	assert_not_null(hud.get_node_or_null("Panel/ContentMargin/Metrics/Wrapper_Wallet/WalletMetric/CoinsValueLabel"))
	assert_not_null(hud.get_node_or_null("Panel/ContentMargin/Metrics/Wrapper_BtnPause/PauseButton"))

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

	var height_value_label: Label = hud.get_node("Panel/ContentMargin/Metrics/Wrapper_Height/HeightMetric/HeightValueLabel") as Label
	var stamina_value_label: Label = hud.get_node("Panel/ContentMargin/Metrics/Wrapper_Stamina/StaminaMetric/StaminaValueLabel") as Label
	var stamina_bar: ProgressBar = hud.get_node("Panel/ContentMargin/Metrics/Wrapper_Stamina/StaminaMetric/StaminaBar") as ProgressBar
	var wallet_value_label: Label = hud.get_node("Panel/ContentMargin/Metrics/Wrapper_Wallet/WalletMetric/WalletValueLabel") as Label
	var coins_value_label: Label = hud.get_node("Panel/ContentMargin/Metrics/Wrapper_Wallet/WalletMetric/CoinsValueLabel") as Label
	var pause_button: Button = hud.get_node("Panel/ContentMargin/Metrics/Wrapper_BtnPause/PauseButton") as Button

	assert_not_null(height_value_label)
	assert_not_null(stamina_value_label)
	assert_not_null(stamina_bar)
	assert_not_null(wallet_value_label)
	assert_not_null(coins_value_label)
	assert_not_null(pause_button)
	assert_eq(height_value_label.text, "18.5 m")
	assert_eq(stamina_value_label.text, "7.0 / 20.0")
	assert_eq(stamina_bar.max_value, 20.0)
	assert_eq(stamina_bar.value, 7.0)
	assert_eq(wallet_value_label.text, "9")
	assert_eq(coins_value_label.text, "+4")

func test_run_hud_emits_pause_request() -> void:
	var scene: PackedScene = load("res://scenes/ui/run_hud.tscn")
	var hud_node: Node = scene.instantiate()

	assert_not_null(hud_node)
	assert_true(hud_node is Control)
	var hud: Control = hud_node as Control
	assert_not_null(hud)
	add_child_autofree(hud)
	await get_tree().process_frame

	_pause_requested = false
	var _connect_result: int = hud.connect(&"pause_requested", Callable(self, "_mark_pause_requested"))
	var pause_button: Button = hud.get_node("Panel/ContentMargin/Metrics/Wrapper_BtnPause/PauseButton") as Button

	assert_not_null(pause_button)
	var _emit_result: int = pause_button.emit_signal("pressed")

	assert_true(_pause_requested)

func test_tutorial_overlay_scene_wires_required_nodes() -> void:
	var scene: PackedScene = load("res://scenes/ui/tutorial_overlay.tscn")
	var overlay_node: Node = scene.instantiate()

	assert_not_null(overlay_node)
	assert_true(overlay_node is Control)
	var overlay: Control = overlay_node as Control
	assert_not_null(overlay)
	add_child_autofree(overlay)
	await get_tree().process_frame

	assert_not_null(overlay.get_node_or_null("Panel/PromptLabel"))

func test_tutorial_overlay_scene_displays_prompt_when_present() -> void:
	var scene: PackedScene = load("res://scenes/ui/tutorial_overlay.tscn")
	var overlay_node: Node = scene.instantiate()

	assert_not_null(overlay_node)
	assert_true(overlay_node is Control)
	var overlay: Control = overlay_node as Control
	assert_not_null(overlay)
	add_child_autofree(overlay)
	await get_tree().process_frame

	overlay.call("apply_state", TutorialOverlayStateScript.new("Drag while holding to move your free hand", true))

	var prompt_label: Label = overlay.get_node("Panel/PromptLabel") as Label

	assert_not_null(prompt_label)
	assert_true(overlay.visible)
	assert_eq(prompt_label.text, "Drag while holding to move your free hand")

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
	_new_seed_run_requested = false
	_main_menu_requested = false
	_rewarded_continue_requested = false
	_post_run_coin_doubler_requested = false
	_store_requested = false
	var _connect_result: int = screen.connect(&"restart_requested", Callable(self, "_mark_restart_requested"))
	var _new_seed_run_connect_result: int = screen.connect(&"new_seed_run_requested", Callable(self, "_mark_new_seed_run_requested"))
	var _main_menu_connect_result: int = screen.connect(&"main_menu_requested", Callable(self, "_mark_main_menu_requested"))
	var _rewarded_continue_connect_result: int = screen.connect(&"rewarded_continue_requested", Callable(self, "_mark_rewarded_continue_requested"))
	var _post_run_coin_doubler_connect_result: int = screen.connect(&"post_run_coin_doubler_requested", Callable(self, "_mark_post_run_coin_doubler_requested"))
	var _store_connect_result: int = screen.connect(&"store_requested", Callable(self, "_mark_store_requested"))
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
	var rewarded_continue_button: Button = screen.get_node("CenterContainer/Panel/ContentMargin/Content/RewardedContinueButton") as Button
	var post_run_coin_doubler_button: Button = screen.get_node("CenterContainer/Panel/ContentMargin/Content/PostRunCoinDoublerButton") as Button
	var store_button: Button = screen.get_node("CenterContainer/Panel/ContentMargin/Content/StoreButton") as Button
	var restart_button: Button = screen.get_node("CenterContainer/Panel/ContentMargin/Content/RestartButton") as Button
	var new_seed_run_button: Button = screen.get_node("CenterContainer/Panel/ContentMargin/Content/NewSeedRunButton") as Button
	var main_menu_button: Button = screen.get_node("CenterContainer/Panel/ContentMargin/Content/MainMenuButton") as Button

	assert_true(screen.visible)
	assert_not_null(title_label)
	assert_not_null(reason_label)
	assert_not_null(summary_label)
	assert_not_null(rewarded_continue_button)
	assert_not_null(post_run_coin_doubler_button)
	assert_not_null(store_button)
	assert_not_null(restart_button)
	assert_not_null(new_seed_run_button)
	assert_not_null(main_menu_button)
	assert_eq(title_label.text, "Rescue Offered")
	assert_eq(reason_label.text, "Reason: Bottom-screen fall")
	assert_string_contains(summary_label.text, "Height: 23.0 m")
	assert_string_contains(summary_label.text, "Wallet Coins: 6")
	assert_string_contains(summary_label.text, "Run Coins: 6")
	assert_false(rewarded_continue_button.visible)
	assert_false(post_run_coin_doubler_button.visible)

	var _emit_result: int = restart_button.emit_signal("pressed")
	var _new_seed_run_emit_result: int = new_seed_run_button.emit_signal("pressed")
	var _main_menu_emit_result: int = main_menu_button.emit_signal("pressed")

	assert_true(_restart_requested)
	assert_true(_new_seed_run_requested)
	assert_true(_main_menu_requested)
	assert_false(_rewarded_continue_requested)
	assert_false(_post_run_coin_doubler_requested)
	assert_false(_store_requested)

func test_run_end_screen_emits_store_request() -> void:
	var scene: PackedScene = load("res://scenes/ui/run_end_screen.tscn")
	var screen_node: Node = scene.instantiate()

	assert_not_null(screen_node)
	assert_true(screen_node is Control)
	var screen: Control = screen_node as Control
	assert_not_null(screen)
	add_child_autofree(screen)
	await get_tree().process_frame

	_store_requested = false
	var _connect_result: int = screen.connect(&"store_requested", Callable(self, "_mark_store_requested"))
	screen.call(
		"apply_state",
		RunEndScreenStateScript.new(
			true,
			false,
			23.0,
			6,
			6,
			true,
			RunEndReasonScript.Value.CHASER_CONTACT
		)
	)

	var store_button: Button = screen.get_node("CenterContainer/Panel/ContentMargin/Content/StoreButton") as Button

	assert_not_null(store_button)
	var _emit_result: int = store_button.emit_signal("pressed")

	assert_true(_store_requested)

func test_run_end_screen_shows_rewarded_continue_button_when_available() -> void:
	var scene: PackedScene = load("res://scenes/ui/run_end_screen.tscn")
	var screen_node: Node = scene.instantiate()

	assert_not_null(screen_node)
	assert_true(screen_node is Control)
	var screen: Control = screen_node as Control
	assert_not_null(screen)
	add_child_autofree(screen)
	await get_tree().process_frame

	_rewarded_continue_requested = false
	var _connect_result: int = screen.connect(&"rewarded_continue_requested", Callable(self, "_mark_rewarded_continue_requested"))
	var state: RunEndScreenStateScript = RunEndScreenStateScript.new(
		true,
		true,
		31.0,
		9,
		5,
		true,
		RunEndReasonScript.Value.BOTTOM_SCREEN_FALL,
		false
	)
	var state_object: Object = state
	state_object.set("show_rewarded_continue", true)
	screen.call("apply_state", state)

	var rewarded_continue_button: Button = screen.get_node("CenterContainer/Panel/ContentMargin/Content/RewardedContinueButton") as Button
	var post_run_coin_doubler_button: Button = screen.get_node("CenterContainer/Panel/ContentMargin/Content/PostRunCoinDoublerButton") as Button
	var summary_label: Label = screen.get_node("CenterContainer/Panel/ContentMargin/Content/SummaryLabel") as Label

	assert_not_null(rewarded_continue_button)
	assert_not_null(post_run_coin_doubler_button)
	assert_not_null(summary_label)
	assert_true(rewarded_continue_button.visible)
	assert_false(post_run_coin_doubler_button.visible)
	assert_string_contains(summary_label.text, "Watch an ad to continue this run once")

	var ad_feedback_label: Label = screen.get_node("CenterContainer/Panel/ContentMargin/Content/AdFeedbackLabel") as Label
	assert_not_null(ad_feedback_label)
	assert_false(ad_feedback_label.visible)

	var _emit_result: int = rewarded_continue_button.emit_signal("pressed")

	assert_true(_rewarded_continue_requested)

func test_run_end_screen_shows_ad_feedback_message_when_provided() -> void:
	var scene: PackedScene = load("res://scenes/ui/run_end_screen.tscn")
	var screen_node: Node = scene.instantiate()

	assert_not_null(screen_node)
	assert_true(screen_node is Control)
	var screen: Control = screen_node as Control
	assert_not_null(screen)
	add_child_autofree(screen)
	await get_tree().process_frame

	var state: RunEndScreenStateScript = RunEndScreenStateScript.new(
		true,
		true,
		31.0,
		9,
		5,
		true,
		RunEndReasonScript.Value.BOTTOM_SCREEN_FALL,
		false
	)
	var state_object: Object = state
	state_object.set("show_rewarded_continue", true)
	state_object.set("ad_feedback_message", "Ad cancelled — you can try again.")
	screen.call("apply_state", state)

	var ad_feedback_label: Label = screen.get_node("CenterContainer/Panel/ContentMargin/Content/AdFeedbackLabel") as Label
	assert_not_null(ad_feedback_label)
	assert_true(ad_feedback_label.visible)
	assert_eq(ad_feedback_label.text, "Ad cancelled — you can try again.")

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

	var height_value_label: Label = hud.get_node("Panel/ContentMargin/Metrics/Wrapper_Height/HeightMetric/HeightValueLabel") as Label
	var title_label: Label = screen.get_node("CenterContainer/Panel/ContentMargin/Content/TitleLabel") as Label

	assert_not_null(height_value_label)
	assert_not_null(title_label)
	assert_eq(height_value_label.text, "14.0 m")
	assert_true(screen.visible)
	assert_eq(title_label.text, "Rescue Offered")

func test_store_shell_displays_state_and_emits_purchase_intent() -> void:
	var scene: PackedScene = load("res://scenes/ui/store_shell.tscn")
	var shell_node: Node = scene.instantiate()

	assert_not_null(shell_node)
	assert_true(shell_node is Control)
	var shell: Control = shell_node as Control
	assert_not_null(shell)
	add_child_autofree(shell)
	await get_tree().process_frame

	_selected_store_item_id = StringName()
	_purchase_store_item_id = StringName()
	var _select_connect_result: int = shell.connect(&"item_selected", Callable(self, "_mark_store_item_selected"))
	var _purchase_connect_result: int = shell.connect(&"purchase_requested", Callable(self, "_mark_store_purchase_requested"))
	shell.call("apply_state", StoreStateScript.new(20, _create_store_item_states(), &"chaser_hot_coffee"))

	var wallet_label: Label = shell.get_node("CenterContainer/Panel/ContentMargin/Content/Header/WalletLabel") as Label
	var item_list: ItemList = shell.get_node("CenterContainer/Panel/ContentMargin/Content/ItemList") as ItemList
	var selected_name_label: Label = shell.get_node("CenterContainer/Panel/ContentMargin/Content/SelectedNameLabel") as Label
	var purchase_button: Button = shell.get_node("CenterContainer/Panel/ContentMargin/Content/Actions/PurchaseButton") as Button

	assert_true(shell.visible)
	assert_eq(wallet_label.text, "Wallet: 20")
	assert_eq(item_list.get_item_count(), 2)
	assert_eq(selected_name_label.text, "Hot Coffee")
	assert_true(purchase_button.visible)
	assert_false(purchase_button.disabled)

	var _item_emit_result: int = item_list.emit_signal("item_selected", 0)
	var _purchase_emit_result: int = purchase_button.emit_signal("pressed")

	assert_eq(_selected_store_item_id, &"body_default")
	assert_eq(_purchase_store_item_id, &"chaser_hot_coffee")

func test_store_shell_displays_owned_item_and_emits_equip_intent() -> void:
	var scene: PackedScene = load("res://scenes/ui/store_shell.tscn")
	var shell_node: Node = scene.instantiate()

	assert_not_null(shell_node)
	assert_true(shell_node is Control)
	var shell: Control = shell_node as Control
	assert_not_null(shell)
	add_child_autofree(shell)
	await get_tree().process_frame

	_equip_store_item_id = StringName()
	var _equip_connect_result: int = shell.connect(&"equip_requested", Callable(self, "_mark_store_equip_requested"))
	shell.call("apply_state", StoreStateScript.new(20, _create_store_item_states(), &"body_default"))

	var selected_name_label: Label = shell.get_node("CenterContainer/Panel/ContentMargin/Content/SelectedNameLabel") as Label
	var equip_button: Button = shell.get_node("CenterContainer/Panel/ContentMargin/Content/Actions/EquipButton") as Button

	assert_eq(selected_name_label.text, "Trail Jacket")
	assert_true(equip_button.visible)
	assert_false(equip_button.disabled)

	var _emit_result: int = equip_button.emit_signal("pressed")

	assert_eq(_equip_store_item_id, &"body_default")

func test_pause_menu_displays_state_and_emits_actions() -> void:
	var scene: PackedScene = load("res://scenes/ui/pause_menu.tscn")
	var menu_node: Node = scene.instantiate()

	assert_not_null(menu_node)
	assert_true(menu_node is Control)
	var menu: Control = menu_node as Control
	assert_not_null(menu)
	add_child_autofree(menu)
	await get_tree().process_frame

	_resume_requested = false
	_restart_requested = false
	_new_seed_run_requested = false
	_main_menu_requested = false
	_settings_requested = false
	var _resume_connect_result: int = menu.connect(&"resume_requested", Callable(self, "_mark_resume_requested"))
	var _restart_connect_result: int = menu.connect(&"restart_requested", Callable(self, "_mark_restart_requested"))
	var _new_seed_run_connect_result: int = menu.connect(&"new_seed_run_requested", Callable(self, "_mark_new_seed_run_requested"))
	var _main_menu_connect_result: int = menu.connect(&"main_menu_requested", Callable(self, "_mark_main_menu_requested"))
	var _settings_connect_result: int = menu.connect(&"settings_requested", Callable(self, "_mark_settings_requested"))
	menu.call("apply_state", PauseMenuStateScript.new(true, 18.5, 22, 5))

	var summary_label: Label = menu.get_node("CenterContainer/Panel/ContentMargin/Content/SummaryLabel") as Label
	var resume_button: Button = menu.get_node("CenterContainer/Panel/ContentMargin/Content/ResumeButton") as Button
	var restart_button: Button = menu.get_node("CenterContainer/Panel/ContentMargin/Content/RestartButton") as Button
	var new_seed_run_button: Button = menu.get_node("CenterContainer/Panel/ContentMargin/Content/NewSeedRunButton") as Button
	var main_menu_button: Button = menu.get_node("CenterContainer/Panel/ContentMargin/Content/MainMenuButton") as Button
	var settings_button: Button = menu.get_node("CenterContainer/Panel/ContentMargin/Content/SettingsButton") as Button

	assert_true(menu.visible)
	assert_eq(summary_label.text, "Height: 18.5 m\nWallet Coins: 22\nRun Coins: 5")
	assert_not_null(resume_button)
	assert_not_null(restart_button)
	assert_not_null(new_seed_run_button)
	assert_not_null(main_menu_button)
	assert_not_null(settings_button)

	var _resume_emit_result: int = resume_button.emit_signal("pressed")
	var _restart_emit_result: int = restart_button.emit_signal("pressed")
	var _new_seed_run_emit_result: int = new_seed_run_button.emit_signal("pressed")
	var _main_menu_emit_result: int = main_menu_button.emit_signal("pressed")
	var _settings_emit_result: int = settings_button.emit_signal("pressed")

	assert_true(_resume_requested)
	assert_true(_restart_requested)
	assert_true(_new_seed_run_requested)
	assert_true(_main_menu_requested)
	assert_true(_settings_requested)

func test_settings_menu_displays_state_and_emits_setting_intents() -> void:
	var scene: PackedScene = load("res://scenes/ui/settings_menu.tscn")
	var menu_node: Node = scene.instantiate()

	assert_not_null(menu_node)
	assert_true(menu_node is Control)
	var menu: Control = menu_node as Control
	assert_not_null(menu)
	add_child_autofree(menu)
	await get_tree().process_frame

	_settings_closed = false
	_settings_audio_muted = false
	_settings_master_volume_ratio = -1.0
	_settings_haptics_enabled = false
	_settings_touch_split_ratio = -1.0
	_settings_touch_dead_zone_ratio = -1.0
	var _closed_connect_result: int = menu.connect(&"closed", Callable(self, "_mark_settings_closed"))
	var _audio_connect_result: int = menu.connect(&"audio_muted_changed", Callable(self, "_mark_settings_audio_muted"))
	var _volume_connect_result: int = menu.connect(&"master_volume_changed", Callable(self, "_mark_settings_master_volume"))
	var _haptics_connect_result: int = menu.connect(&"haptics_enabled_changed", Callable(self, "_mark_settings_haptics_enabled"))
	var _split_connect_result: int = menu.connect(&"touch_split_changed", Callable(self, "_mark_settings_touch_split"))
	var _dead_zone_connect_result: int = menu.connect(&"touch_center_dead_zone_changed", Callable(self, "_mark_settings_touch_dead_zone"))
	menu.call("apply_state", SettingsStateScript.new(true, true, 0.65, false, 0.58, 0.07))

	var audio_mute_check_box: CheckBox = menu.get_node("CenterContainer/Panel/ControlPosition/AudioControl/AudioMuteCheckBox") as CheckBox
	var volume_slider: HSlider = menu.get_node("CenterContainer/Panel/ControlPosition/VolumeControl/VolumeSlider") as HSlider
	var volume_value_label: Label = menu.get_node("CenterContainer/Panel/ControlPosition/VolumeControl/value_volume") as Label
	var haptics_check_box: CheckBox = menu.get_node("CenterContainer/Panel/ControlPosition/HapicControl/HapticsCheckBox") as CheckBox
	var touch_split_slider: HSlider = menu.get_node("CenterContainer/Panel/ControlPosition/TouchSplitControl/TouchSplitSlider") as HSlider
	var touch_dead_zone_slider: HSlider = menu.get_node("CenterContainer/Panel/ControlPosition/TouchDeadZoneControl/TouchDeadZoneSlider") as HSlider
	var close_button: Button = menu.get_node("CenterContainer/Panel/ControlPosition/CloseButton") as Button

	# Sliders run 0-100 in this scene; SettingsState stores 0.0-1.0 ratios.
	assert_true(menu.visible)
	assert_true(audio_mute_check_box.button_pressed)
	assert_eq(volume_slider.value, 65.0)
	assert_eq(volume_value_label.text, "65%")
	assert_false(haptics_check_box.button_pressed)
	# HSlider snaps to its default step of 1.0, so 76.667 rounds to 77.0.
	assert_eq(touch_split_slider.value, 77.0)
	assert_eq(touch_dead_zone_slider.value, 35.0)

	var _audio_emit_result: int = audio_mute_check_box.emit_signal("toggled", false)
	var _volume_emit_result: int = volume_slider.emit_signal("value_changed", 35.0)
	var _haptics_emit_result: int = haptics_check_box.emit_signal("toggled", true)
	var _split_emit_result: int = touch_split_slider.emit_signal("value_changed", 50.0)
	var _dead_zone_emit_result: int = touch_dead_zone_slider.emit_signal("value_changed", 25.0)
	var _close_emit_result: int = close_button.emit_signal("pressed")

	assert_false(_settings_audio_muted)
	assert_eq(_settings_master_volume_ratio, 0.35)
	assert_true(_settings_haptics_enabled)
	assert_eq(_settings_touch_split_ratio, 0.5)
	assert_eq(_settings_touch_dead_zone_ratio, 0.05)
	assert_true(_settings_closed)

func _mark_restart_requested() -> void:
	_restart_requested = true

func _mark_new_seed_run_requested() -> void:
	_new_seed_run_requested = true

func _mark_main_menu_requested() -> void:
	_main_menu_requested = true

func _mark_start_requested() -> void:
	_start_requested = true

func _mark_tutorial_requested() -> void:
	_tutorial_requested = true

func _mark_rewarded_continue_requested() -> void:
	_rewarded_continue_requested = true

func _mark_post_run_coin_doubler_requested() -> void:
	_post_run_coin_doubler_requested = true

func _mark_store_requested() -> void:
	_store_requested = true

func _mark_pause_requested() -> void:
	_pause_requested = true

func _mark_resume_requested() -> void:
	_resume_requested = true

func _mark_settings_requested() -> void:
	_settings_requested = true

func _mark_settings_closed() -> void:
	_settings_closed = true

func _mark_settings_audio_muted(audio_muted: bool) -> void:
	_settings_audio_muted = audio_muted

func _mark_settings_master_volume(master_volume_ratio: float) -> void:
	_settings_master_volume_ratio = master_volume_ratio

func _mark_settings_haptics_enabled(haptics_enabled: bool) -> void:
	_settings_haptics_enabled = haptics_enabled

func _mark_settings_touch_split(touch_split_ratio: float) -> void:
	_settings_touch_split_ratio = touch_split_ratio

func _mark_settings_touch_dead_zone(touch_dead_zone_ratio: float) -> void:
	_settings_touch_dead_zone_ratio = touch_dead_zone_ratio

func _mark_store_item_selected(item_id: StringName) -> void:
	_selected_store_item_id = item_id

func _mark_store_purchase_requested(item_id: StringName) -> void:
	_purchase_store_item_id = item_id

func _mark_store_equip_requested(item_id: StringName) -> void:
	_equip_store_item_id = item_id

func _create_store_item_states() -> Array[StoreItemStateScript]:
	return [
		StoreItemStateScript.new(&"body_default", "Trail Jacket", CosmeticSlotScript.Value.BODY, 0, true, false, false, true),
		StoreItemStateScript.new(&"chaser_hot_coffee", "Hot Coffee", CosmeticSlotScript.Value.CHASER_THEME, 15, false, false, true, false),
	]