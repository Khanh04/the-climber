extends GutTest

const Records = preload("res://src/platform/storage/best_score_storage.gd")
const Memory = preload("res://src/platform/storage/in_memory_local_storage_adapter.gd")
const Saves = preload("res://src/platform/storage/save_storage.gd")
const Snapshot = preload("res://src/platform/storage/save_snapshot.gd")
const MenuScene = preload("res://scenes/main/main_menu_scene.tscn")
const RunSceneResource = preload("res://scenes/main/run_scene.tscn")
const LaunchMode = preload("res://src/core/run_launch_mode.gd")
var _requested_scene: String = ""

func _record_scene(scene_path: String) -> void:
	_requested_scene = scene_path

func test_best_score_preserves_legacy_wallet_and_only_increases() -> void:
	var memory: Memory = Memory.new()
	var saves: Saves = Saves.new(memory)
	saves.save_snapshot(Snapshot.new(14))
	var records: Records = Records.new(memory)
	assert_eq(records.get_best_height_meters(), 0.0)
	records.record_height(18.5)
	records.record_height(7.0)
	assert_eq(Records.new(memory).get_best_height_meters(), 18.5)
	assert_eq(saves.load_snapshot().wallet_coins, 14)
	records.record_height(26.7)
	assert_eq(Records.new(memory).get_best_height_meters(), 26.7)
	# Match the float conversion performed by JSON storage on disk.
	var raw: Variant = JSON.parse_string(JSON.stringify(memory.load_dictionary(Records.STORAGE_KEY)))
	var payload: Dictionary = raw
	memory.save_dictionary(Records.STORAGE_KEY, payload)
	assert_eq(Records.new(memory).get_best_height_meters(), 26.7)

func test_main_menu_loads_saved_values_and_keeps_them_behind_settings() -> void:
	var memory: Memory = Memory.new()
	Saves.new(memory).save_snapshot(Snapshot.new(14))
	Records.new(memory).record_height(123.4)
	var menu: MainMenuScene = MenuScene.instantiate() as MainMenuScene
	menu.set_local_storage_adapter(memory)
	add_child_autofree(menu)
	await get_tree().process_frame
	var best: Label = menu.get_node("MainMenu/MainMenuStats/BestScoreRow/BestScoreValue") as Label
	var wallet: Label = menu.get_node("MainMenu/MainMenuStats/WalletRow/WalletCoinsValue") as Label
	assert_eq(best.text, "123.4 m")
	assert_eq(wallet.text, "14")
	var _show: Variant = menu.call("_show_settings_menu")
	assert_true(best.is_visible_in_tree())
	assert_true(wallet.is_visible_in_tree())
	var settings: SettingsMenu = menu.get_settings_menu_for_test()
	(settings.get_node("CloseButton") as BaseButton).pressed.emit()
	assert_true(best.is_visible_in_tree())
	assert_true((menu.get_node("MainMenu/CenterContainer") as Control).visible)
	var _store: Variant = menu.call("_on_store_requested")
	var _purchase: Variant = menu.call("_on_store_purchase_requested", &"body_sunrise_jacket")
	assert_eq(wallet.text, "2", "Spending 12 coins must immediately refresh the Main Menu wallet.")
	assert_eq(Saves.new(memory).load_snapshot().wallet_coins, 2)
	assert_eq(Records.new(memory).get_best_height_meters(), 123.4)

func test_run_pause_restart_and_return_to_menu_keep_best_record() -> void:
	var memory: Memory = Memory.new()
	var run: RunScene = RunSceneResource.instantiate() as RunScene
	run.set_local_storage_adapter(memory)
	run.set_scene_change_callable_for_test(_record_scene)
	add_child_autofree(run)
	await get_tree().process_frame
	var session: RunSession = run.get_test_adapter_for_test().get_run_session_for_test()
	session.record_height(18.5)
	var _pause: Variant = run.call("_show_pause_menu")
	assert_eq(Records.new(memory).get_best_height_meters(), 18.5)
	var _resume: Variant = run.call("_resume_from_pause_menu")
	session.record_height(26.7)
	var _restart: Variant = run.call("_request_restart")
	assert_eq(Records.new(memory).get_best_height_meters(), 26.7)
	session = run.get_test_adapter_for_test().get_run_session_for_test()
	assert_eq(session.get_height_meters(), 0.0)
	session.record_height(8.0)
	var _main: Variant = run.call("_on_main_menu_requested")
	assert_eq(_requested_scene, "res://scenes/main/main_menu_scene.tscn")
	assert_eq(Records.new(memory).get_best_height_meters(), 26.7)
	var menu: MainMenuScene = MenuScene.instantiate() as MainMenuScene
	menu.set_local_storage_adapter(memory)
	add_child_autofree(menu)
	assert_eq((menu.get_node("MainMenu/MainMenuStats/BestScoreRow/BestScoreValue") as Label).text, "26.7 m")

func test_tutorial_does_not_replace_normal_run_record() -> void:
	var memory: Memory = Memory.new()
	Records.new(memory).record_height(12.5)
	var run: RunScene = RunSceneResource.instantiate() as RunScene
	run.set_local_storage_adapter(memory)
	run.set_launch_mode_override(LaunchMode.Value.TUTORIAL)
	add_child_autofree(run)
	await get_tree().process_frame
	var session: RunSession = run.get_test_adapter_for_test().get_run_session_for_test()
	session.record_height(99.0)
	var _pause: Variant = run.call("_show_pause_menu")
	assert_eq(Records.new(memory).get_best_height_meters(), 12.5)
	var _resume: Variant = run.call("_resume_from_pause_menu")

func test_run_end_saves_record_before_leaving_result_screen() -> void:
	var memory: Memory = Memory.new()
	var run: RunScene = RunSceneResource.instantiate() as RunScene
	run.set_local_storage_adapter(memory)
	add_child_autofree(run)
	await get_tree().process_frame
	var session: RunSession = run.get_test_adapter_for_test().get_run_session_for_test()
	session.record_height(31.2)
	session.end_run(RunEndReason.Value.BOTTOM_SCREEN_FALL)
	var _refresh: Variant = run.call("_refresh_ui")
	assert_eq(Records.new(memory).get_best_height_meters(), 31.2)
