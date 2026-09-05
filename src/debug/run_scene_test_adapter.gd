class_name RunSceneTestAdapter
extends RefCounted

const ChaserFeedbackSnapshotScript = preload("res://src/gameplay/chaser/chaser_feedback_snapshot.gd")
const ChaserKillZoneScript = preload("res://scenes/chaser/chaser_kill_zone.gd")
const ClimbPrototypeControllerScript = preload("res://src/gameplay/player/climb_prototype_controller.gd")
const CosmeticInventoryScript = preload("res://src/cosmetics/cosmetic_inventory.gd")
const CosmeticLoadoutScript = preload("res://resources/config/cosmetic_loadout.gd")
const GeneratedChunkCoordinatorScript = preload("res://src/gameplay/generation/generated_chunk_coordinator.gd")
const PauseMenuScript = preload("res://scenes/ui/pause_menu.gd")
const PlayerCharacterScript = preload("res://scenes/player/player_character.gd")
const PlayerInputFrameScript = preload("res://src/gameplay/player/player_input_frame.gd")
const RunOverlayRuntimeScript = preload("res://src/ui/run_overlay_runtime.gd")
const RunSessionScript = preload("res://src/gameplay/run/run_session.gd")
const SettingsMenuScript = preload("res://scenes/ui/settings_menu.gd")
const StoreShellScript = preload("res://scenes/ui/store_shell.gd")
const WalletScript = preload("res://src/economy/wallet.gd")
const ChaserPacingModelScript = preload("res://src/gameplay/chaser/chaser_pacing_model.gd")

var _player: PlayerCharacterScript
var _controller: ClimbPrototypeControllerScript
var _chaser_kill_zone: ChaserKillZoneScript
var _generated_chunk_coordinator: GeneratedChunkCoordinatorScript
var _overlay_runtime: RunOverlayRuntimeScript
var _wallet: WalletScript
var _cosmetic_inventory: CosmeticInventoryScript
var _cosmetic_loadout: CosmeticLoadoutScript
var _chaser_pacing_model: ChaserPacingModelScript
var _launch_mode: int
var _bottom_fall_margin_pixels: float
var _camera_player_lower_screen_offset_pixels: float
var _get_run_session_callable: Callable
var _get_store_shell_callable: Callable
var _show_store_callable: Callable
var _get_pause_menu_callable: Callable
var _get_settings_menu_callable: Callable
var _show_pause_menu_callable: Callable
var _show_settings_menu_callable: Callable
var _consume_app_lifecycle_events_callable: Callable
var _reset_playground_callable: Callable
var _resolve_chaser_contact_callable: Callable
var _sync_aim_preview_callable: Callable
var _new_seed_run_callable: Callable
var _main_menu_callable: Callable

func _init(
	player: PlayerCharacterScript,
	controller: ClimbPrototypeControllerScript,
	chaser_kill_zone: ChaserKillZoneScript,
	generated_chunk_coordinator: GeneratedChunkCoordinatorScript,
	overlay_runtime: RunOverlayRuntimeScript,
	wallet: WalletScript,
	cosmetic_inventory: CosmeticInventoryScript,
	cosmetic_loadout: CosmeticLoadoutScript,
	chaser_pacing_model: ChaserPacingModelScript,
	launch_mode: int,
	bottom_fall_margin_pixels: float,
	camera_player_lower_screen_offset_pixels: float,
	get_run_session_callable: Callable,
	get_store_shell_callable: Callable,
	show_store_callable: Callable,
	get_pause_menu_callable: Callable,
	get_settings_menu_callable: Callable,
	show_pause_menu_callable: Callable,
	show_settings_menu_callable: Callable,
	consume_app_lifecycle_events_callable: Callable,
	reset_playground_callable: Callable,
	resolve_chaser_contact_callable: Callable,
	sync_aim_preview_callable: Callable,
	new_seed_run_callable: Callable,
	main_menu_callable: Callable
) -> void:
	Validation.require_condition(player != null, "RunSceneTestAdapter requires a player.")
	Validation.require_condition(controller != null, "RunSceneTestAdapter requires a climb controller.")
	Validation.require_condition(chaser_kill_zone != null, "RunSceneTestAdapter requires a chaser kill zone.")
	Validation.require_condition(generated_chunk_coordinator != null, "RunSceneTestAdapter requires a generated chunk coordinator.")
	Validation.require_condition(overlay_runtime != null, "RunSceneTestAdapter requires an overlay runtime.")
	Validation.require_condition(wallet != null, "RunSceneTestAdapter requires a wallet.")
	Validation.require_condition(cosmetic_inventory != null, "RunSceneTestAdapter requires a cosmetic inventory.")
	Validation.require_condition(cosmetic_loadout != null, "RunSceneTestAdapter requires a cosmetic loadout.")
	Validation.require_condition(chaser_pacing_model != null, "RunSceneTestAdapter requires a chaser pacing model.")
	Validation.require_condition(bottom_fall_margin_pixels >= 0.0, "RunSceneTestAdapter bottom fall margin cannot be negative.")
	Validation.require_condition(
		camera_player_lower_screen_offset_pixels >= 0.0,
		"RunSceneTestAdapter camera lower-screen offset cannot be negative."
	)
	Validation.require_condition(get_run_session_callable.is_valid(), "RunSceneTestAdapter requires a run-session getter.")
	Validation.require_condition(get_store_shell_callable.is_valid(), "RunSceneTestAdapter requires a store-shell getter.")
	Validation.require_condition(show_store_callable.is_valid(), "RunSceneTestAdapter requires a show-store action.")
	Validation.require_condition(get_pause_menu_callable.is_valid(), "RunSceneTestAdapter requires a pause-menu getter.")
	Validation.require_condition(get_settings_menu_callable.is_valid(), "RunSceneTestAdapter requires a settings-menu getter.")
	Validation.require_condition(show_pause_menu_callable.is_valid(), "RunSceneTestAdapter requires a show-pause action.")
	Validation.require_condition(show_settings_menu_callable.is_valid(), "RunSceneTestAdapter requires a show-settings action.")
	Validation.require_condition(
		consume_app_lifecycle_events_callable.is_valid(),
		"RunSceneTestAdapter requires an app-lifecycle consumption action."
	)
	Validation.require_condition(reset_playground_callable.is_valid(), "RunSceneTestAdapter requires a reset action.")
	Validation.require_condition(resolve_chaser_contact_callable.is_valid(), "RunSceneTestAdapter requires a chaser-contact action.")
	Validation.require_condition(sync_aim_preview_callable.is_valid(), "RunSceneTestAdapter requires an aim-preview sync action.")
	Validation.require_condition(new_seed_run_callable.is_valid(), "RunSceneTestAdapter requires a new-seed-run action.")
	Validation.require_condition(main_menu_callable.is_valid(), "RunSceneTestAdapter requires a main-menu action.")

	_player = player
	_controller = controller
	_chaser_kill_zone = chaser_kill_zone
	_generated_chunk_coordinator = generated_chunk_coordinator
	_overlay_runtime = overlay_runtime
	_wallet = wallet
	_cosmetic_inventory = cosmetic_inventory
	_cosmetic_loadout = cosmetic_loadout
	_chaser_pacing_model = chaser_pacing_model
	_launch_mode = launch_mode
	_bottom_fall_margin_pixels = bottom_fall_margin_pixels
	_camera_player_lower_screen_offset_pixels = camera_player_lower_screen_offset_pixels
	_get_run_session_callable = get_run_session_callable
	_get_store_shell_callable = get_store_shell_callable
	_show_store_callable = show_store_callable
	_get_pause_menu_callable = get_pause_menu_callable
	_get_settings_menu_callable = get_settings_menu_callable
	_show_pause_menu_callable = show_pause_menu_callable
	_show_settings_menu_callable = show_settings_menu_callable
	_consume_app_lifecycle_events_callable = consume_app_lifecycle_events_callable
	_reset_playground_callable = reset_playground_callable
	_resolve_chaser_contact_callable = resolve_chaser_contact_callable
	_sync_aim_preview_callable = sync_aim_preview_callable
	_new_seed_run_callable = new_seed_run_callable
	_main_menu_callable = main_menu_callable

func reset_for_test() -> void:
	_reset_playground_callable.call()

func request_new_seed_run_for_test() -> void:
	_new_seed_run_callable.call()

func request_main_menu_for_test() -> void:
	_main_menu_callable.call()

func get_launch_mode_for_test() -> int:
	return _launch_mode

func get_player_body_for_test() -> RigidBody2D:
	return _player.get_player_body()

func get_left_hand_anchor_for_test() -> Marker2D:
	return _player.get_left_hand_anchor()

func get_right_hand_anchor_for_test() -> Marker2D:
	return _player.get_right_hand_anchor()

func get_run_session_for_test() -> RunSessionScript:
	var raw_run_session: Variant = _get_run_session_callable.call()
	Validation.require_condition(raw_run_session is RunSessionScript, "RunSceneTestAdapter run-session getter must return RunSession.")
	var typed_run_session: RunSessionScript = raw_run_session
	return typed_run_session

func get_wallet_for_test() -> WalletScript:
	return _wallet

func get_cosmetic_inventory_for_test() -> CosmeticInventoryScript:
	return _cosmetic_inventory

func get_cosmetic_loadout_for_test() -> CosmeticLoadoutScript:
	return _cosmetic_loadout

func get_chaser_for_test() -> ChaserKillZoneScript:
	return _chaser_kill_zone

func get_generated_chunk_coordinator_for_test() -> GeneratedChunkCoordinatorScript:
	return _generated_chunk_coordinator

func get_store_shell_for_test() -> StoreShellScript:
	var raw_store_shell: Variant = _get_store_shell_callable.call()
	Validation.require_condition(raw_store_shell == null or raw_store_shell is StoreShellScript, "RunSceneTestAdapter store-shell getter must return StoreShell or null.")
	if raw_store_shell == null:
		return null

	var typed_store_shell: StoreShellScript = raw_store_shell
	return typed_store_shell

func show_store_for_test() -> void:
	_show_store_callable.call()

func get_pause_menu_for_test() -> PauseMenuScript:
	var raw_pause_menu: Variant = _get_pause_menu_callable.call()
	Validation.require_condition(raw_pause_menu == null or raw_pause_menu is PauseMenuScript, "RunSceneTestAdapter pause-menu getter must return PauseMenu or null.")
	if raw_pause_menu == null:
		return null

	var typed_pause_menu: PauseMenuScript = raw_pause_menu
	return typed_pause_menu

func get_settings_menu_for_test() -> SettingsMenuScript:
	var raw_settings_menu: Variant = _get_settings_menu_callable.call()
	Validation.require_condition(raw_settings_menu == null or raw_settings_menu is SettingsMenuScript, "RunSceneTestAdapter settings-menu getter must return SettingsMenu or null.")
	if raw_settings_menu == null:
		return null

	var typed_settings_menu: SettingsMenuScript = raw_settings_menu
	return typed_settings_menu

func show_pause_menu_for_test() -> void:
	_show_pause_menu_callable.call()

func show_settings_menu_for_test() -> void:
	_show_settings_menu_callable.call()

func is_pause_menu_visible_for_test() -> bool:
	return _overlay_runtime.is_pause_menu_visible()

func consume_app_lifecycle_events_for_test() -> void:
	_consume_app_lifecycle_events_callable.call()

func resolve_chaser_contact_for_test() -> void:
	_resolve_chaser_contact_callable.call()

func get_bottom_fall_margin_for_test() -> float:
	return _bottom_fall_margin_pixels

func get_camera_player_lower_screen_offset_for_test() -> float:
	return _camera_player_lower_screen_offset_pixels

func get_chaser_feedback_snapshot_for_test() -> ChaserFeedbackSnapshotScript:
	return _chaser_pacing_model.get_current_feedback_snapshot()

func get_chaser_feedback_intensity_ratio_for_test() -> float:
	return _chaser_kill_zone.get_feedback_intensity_ratio()

func sync_grip_links_for_test() -> void:
	_player.sync_runtime_grip_links(_controller.get_attachment_state())

func sync_aim_preview_for_test(input_frame: PlayerInputFrameScript) -> void:
	Validation.require_condition(input_frame != null, "RunSceneTestAdapter requires an input frame before syncing aim preview.")
	_sync_aim_preview_callable.call(input_frame)

func get_controller_for_test() -> ClimbPrototypeControllerScript:
	return _controller

func get_player_for_test() -> PlayerCharacterScript:
	return _player