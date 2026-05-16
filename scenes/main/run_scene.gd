class_name RunScene
extends Node2D

const ChaserContactServiceScript = preload("res://src/gameplay/chaser/chaser_contact_service.gd")
const ChaserFeedbackSnapshotScript = preload("res://src/gameplay/chaser/chaser_feedback_snapshot.gd")
const ChaserKillZoneScript = preload("res://scenes/chaser/chaser_kill_zone.gd")
const ChaserPacingModelScript = preload("res://src/gameplay/chaser/chaser_pacing_model.gd")
const ChaserThemeCatalogScript = preload("res://resources/config/chaser_theme_catalog.gd")
const ClimbPrototypeControllerScript = preload("res://src/gameplay/player/climb_prototype_controller.gd")
const ClimbPrototypeFrameResultScript = preload("res://src/gameplay/player/climb_prototype_frame_result.gd")
const ClimbPrototypeTuningScript = preload("res://resources/config/climb_prototype_tuning.gd")
const CoinTransactionLedgerScript = preload("res://src/economy/coin_transaction_ledger.gd")
const CosmeticInventoryScript = preload("res://src/cosmetics/cosmetic_inventory.gd")
const CosmeticItemCatalogScript = preload("res://resources/config/cosmetic_item_catalog.gd")
const CosmeticItemScript = preload("res://resources/config/cosmetic_item.gd")
const CosmeticLoadoutScript = preload("res://resources/config/cosmetic_loadout.gd")
const CosmeticLoadoutServiceScript = preload("res://src/cosmetics/cosmetic_loadout_service.gd")
const CosmeticPurchaseOutcomeScript = preload("res://src/cosmetics/cosmetic_purchase_outcome.gd")
const CosmeticPurchaseResultScript = preload("res://src/cosmetics/cosmetic_purchase_result.gd")
const CosmeticUnlockPurchaseServiceScript = preload("res://src/cosmetics/cosmetic_unlock_purchase_service.gd")
const DailyChunkGeneratorScript = preload("res://src/gameplay/generation/daily_chunk_generator.gd")
const DesktopDebugInputAdapterScript = preload("res://src/gameplay/player/desktop_debug_input_adapter.gd")
const GeneratedCoinPickupSpawnAdapterScript = preload("res://src/gameplay/pickups/generated_coin_pickup_spawn_adapter.gd")
const GeneratedHandholdAdapterScript = preload("res://src/gameplay/generation/generated_handhold_adapter.gd")
const GeneratedChunkCoordinatorScript = preload("res://src/gameplay/generation/generated_chunk_coordinator.gd")
const GeneratedChunkSceneBuilderScript = preload("res://src/gameplay/generation/generated_chunk_scene_builder.gd")
const GeneratedHazardKindScript = preload("res://src/gameplay/generation/generated_hazard_kind.gd")
const GeneratedHazardSpawnAdapterScript = preload("res://src/gameplay/hazards/generated_hazard_spawn_adapter.gd")
const GenerationTuningScript = preload("res://resources/config/generation_tuning.gd")
const HandholdSurfaceProfileScript = preload("res://resources/config/handhold_surface_profile.gd")
const HandSideScript = preload("res://src/gameplay/player/hand_side.gd")
const HandholdTargetScript = preload("res://src/gameplay/player/handhold_target.gd")
const HandholdTypeDefinitionScript = preload("res://resources/config/handhold_type_definition.gd")
const HandholdTypeScript = preload("res://src/gameplay/generation/handhold_type.gd")
const AppSettingsSnapshotScript = preload("res://src/platform/storage/app_settings_snapshot.gd")
const AppSettingsStorageScript = preload("res://src/platform/storage/app_settings_storage.gd")
const AudioSettingsAdapterScript = preload("res://src/platform/audio/audio_settings_adapter.gd")
const GodotAudioSettingsAdapterScript = preload("res://src/platform/audio/godot_audio_settings_adapter.gd")
const HapticFeedbackTypeScript = preload("res://src/platform/haptics/haptic_feedback_type.gd")
const HapticsAdapterScript = preload("res://src/platform/haptics/haptics_adapter.gd")
const HapticsAdapterFactoryScript = preload("res://src/platform/haptics/haptics_adapter_factory.gd")
const LethalHazardContactServiceScript = preload("res://src/gameplay/hazards/lethal_hazard_contact_service.gd")
const MobileTouchInputAdapterScript = preload("res://src/gameplay/player/mobile_touch_input_adapter.gd")
const MobileTouchContactScript = preload("res://src/gameplay/player/mobile_touch_contact.gd")
const NormalCoinPickupServiceScript = preload("res://src/gameplay/pickups/normal_coin_pickup_service.gd")
const PlayerCosmeticApplicatorScript = preload("res://src/cosmetics/player_cosmetic_applicator.gd")
const PlayerCharacterScript = preload("res://scenes/player/player_character.gd")
const PlayerInputFrameScript = preload("res://src/gameplay/player/player_input_frame.gd")
const PlayerPhysicsModeTransitionsScript = preload("res://src/gameplay/player/player_physics_mode_transitions.gd")
const PersistentCoinTransactionServiceScript = preload("res://src/economy/persistent_coin_transaction_service.gd")
const PostRunCoinDoublerGrantServiceScript = preload("res://src/economy/post_run_coin_doubler_grant_service.gd")
const RewardedAdOutcomeScript = preload("res://src/platform/ads/rewarded_ad_outcome.gd")
const RewardedAdPlacementScript = preload("res://src/platform/ads/rewarded_ad_placement.gd")
const RewardedAdResultScript = preload("res://src/platform/ads/rewarded_ad_result.gd")
const RewardedAdsAdapterScript = preload("res://src/platform/ads/rewarded_ads_adapter.gd")
const RewardedAdsAdapterFactoryScript = preload("res://src/platform/ads/rewarded_ads_adapter_factory.gd")
const RewardedContinueServiceScript = preload("res://src/gameplay/run/rewarded_continue_service.gd")
const RunEndReasonScript = preload("res://src/core/run_end_reason.gd")
const BottomScreenFallServiceScript = preload("res://src/gameplay/run/bottom_screen_fall_service.gd")
const JsonFileLocalStorageAdapterScript = preload("res://src/platform/storage/json_file_local_storage_adapter.gd")
const LocalStorageAdapterScript = preload("res://src/platform/storage/local_storage_adapter.gd")
const AppLifecycleAdapterScript = preload("res://src/platform/lifecycle/app_lifecycle_adapter.gd")
const AppLifecycleEventScript = preload("res://src/platform/lifecycle/app_lifecycle_event.gd")
const GodotAppLifecycleAdapterScript = preload("res://src/platform/lifecycle/godot_app_lifecycle_adapter.gd")
const RunLoopCoordinatorScript = preload("res://src/gameplay/run/run_loop_coordinator.gd")
const RunSessionScript = preload("res://src/gameplay/run/run_session.gd")
const SaveSchemaScript = preload("res://src/platform/storage/save_schema.gd")
const SaveSnapshotScript = preload("res://src/platform/storage/save_snapshot.gd")
const SaveStorageScript = preload("res://src/platform/storage/save_storage.gd")
const StaminaFallServiceScript = preload("res://src/gameplay/run/stamina_fall_service.gd")
const RunStateScript = preload("res://src/gameplay/run/run_state.gd")
const StaminaRuntimeScript = preload("res://src/gameplay/player/stamina_runtime.gd")
const StaminaTuningScript = preload("res://resources/config/stamina_tuning.gd")
const PauseMenuScript = preload("res://scenes/ui/pause_menu.gd")
const PauseMenuStateScript = preload("res://src/ui/pause_menu_state.gd")
const PauseMenuScene = preload("res://scenes/ui/pause_menu.tscn")
const SettingsMenuScript = preload("res://scenes/ui/settings_menu.gd")
const SettingsMenuScene = preload("res://scenes/ui/settings_menu.tscn")
const SettingsPresenterScript = preload("res://src/ui/settings_presenter.gd")
const StorePresenterScript = preload("res://src/ui/store_presenter.gd")
const StoreShellScript = preload("res://scenes/ui/store_shell.gd")
const StoreShellScene = preload("res://scenes/ui/store_shell.tscn")
const UtcDateProviderScript = preload("res://src/platform/clock/utc_date_provider.gd")
const SystemUtcDateProviderScript = preload("res://src/platform/clock/system_utc_date_provider.gd")
const RunUiPresenterScript = preload("res://src/ui/run_ui_presenter.gd")
const RunUiViewScript = preload("res://src/ui/run_ui_view.gd")
const WalletScript = preload("res://src/economy/wallet.gd")
const WalletTransactionServiceScript = preload("res://src/economy/wallet_transaction_service.gd")
const WindGustHazardContactServiceScript = preload("res://src/gameplay/hazards/wind_gust_hazard_contact_service.gd")

@export var climb_tuning: ClimbPrototypeTuningScript
@export var stamina_tuning: StaminaTuningScript
@export var generation_tuning: GenerationTuningScript
@export var cosmetic_loadout: CosmeticLoadoutScript
@export var chaser_theme_catalog: ChaserThemeCatalogScript
@export var cosmetic_item_catalog: CosmeticItemCatalogScript

@onready var _player: PlayerCharacterScript = %PlayerCharacter
@onready var _chaser_kill_zone: ChaserKillZoneScript = get_node("ChaserKillZone") as ChaserKillZoneScript
@onready var _generated_chunk_coordinator: GeneratedChunkCoordinatorScript = %GeneratedChunks
@onready var _reset_anchor: Marker2D = %ResetAnchor
@onready var _camera: Camera2D = %DevCamera
@onready var _starter_handholds_root: Node2D = get_node("Handholds") as Node2D
@onready var _run_hud: Control = %RunHud
@onready var _run_end_screen: Control = %RunEndScreen
@onready var _ui_layer: CanvasLayer = get_node("UiLayer") as CanvasLayer
@onready var _run_ui_view = RunUiViewScript.new(_run_hud, _run_end_screen)

var _run_session: RunSessionScript = RunSessionScript.new()
var _stamina: StaminaRuntimeScript
var _desktop_input: DesktopDebugInputAdapterScript = DesktopDebugInputAdapterScript.new()
var _mobile_input: MobileTouchInputAdapterScript = MobileTouchInputAdapterScript.new()
var _controller: ClimbPrototypeControllerScript
var _chaser_contact_service: ChaserContactServiceScript = ChaserContactServiceScript.new()
var _chaser_pacing_model: ChaserPacingModelScript
var _bottom_screen_fall_service: BottomScreenFallServiceScript = BottomScreenFallServiceScript.new()
var _lethal_hazard_contact_service: LethalHazardContactServiceScript = LethalHazardContactServiceScript.new()
var _normal_coin_pickup_service: NormalCoinPickupServiceScript = NormalCoinPickupServiceScript.new()
var _run_loop_coordinator: RunLoopCoordinatorScript = RunLoopCoordinatorScript.new()
var _run_ui_presenter: RunUiPresenterScript = RunUiPresenterScript.new(_run_loop_coordinator)
var _stamina_fall_service: StaminaFallServiceScript = StaminaFallServiceScript.new()
var _wind_gust_hazard_contact_service: WindGustHazardContactServiceScript = WindGustHazardContactServiceScript.new()
var _wallet: WalletScript = WalletScript.new()
var _cosmetic_inventory: CosmeticInventoryScript = CosmeticInventoryScript.new()
var _cosmetic_loadout_service: CosmeticLoadoutServiceScript = CosmeticLoadoutServiceScript.new()
var _cosmetic_unlock_purchase_service: CosmeticUnlockPurchaseServiceScript = CosmeticUnlockPurchaseServiceScript.new()
var _player_cosmetic_applicator: PlayerCosmeticApplicatorScript = PlayerCosmeticApplicatorScript.new()
var _store_presenter: StorePresenterScript = StorePresenterScript.new(_cosmetic_loadout_service)
var _rewarded_ads_adapter: RewardedAdsAdapterScript = RewardedAdsAdapterFactoryScript.create_default()
var _app_lifecycle_adapter: AppLifecycleAdapterScript = GodotAppLifecycleAdapterScript.new()
var _audio_settings_adapter: AudioSettingsAdapterScript = GodotAudioSettingsAdapterScript.new()
var _haptics_adapter: HapticsAdapterScript = HapticsAdapterFactoryScript.create_default()
var _persistent_coin_transaction_service: PersistentCoinTransactionServiceScript = PersistentCoinTransactionServiceScript.new()
var _post_run_coin_doubler_grant_service: PostRunCoinDoublerGrantServiceScript = PostRunCoinDoublerGrantServiceScript.new()
var _rewarded_continue_service: RewardedContinueServiceScript = RewardedContinueServiceScript.new()
var _rewarded_continue_feedback_message: String = ""
var _wallet_transaction_service: WalletTransactionServiceScript = WalletTransactionServiceScript.new()
var _persistent_transaction_ledger: CoinTransactionLedgerScript = CoinTransactionLedgerScript.new()
var _run_pickup_transaction_ledger: CoinTransactionLedgerScript = CoinTransactionLedgerScript.new()
var _active_touch_contacts: Array[RefCounted] = []
var _left_aim_preview: Line2D = null
var _right_aim_preview: Line2D = null
var _aim_target_marker: Polygon2D = null
var _debug_reset_pressed: bool = false
var _app_settings_snapshot: AppSettingsSnapshotScript = null
var _app_settings_storage: AppSettingsStorageScript = null
var _save_snapshot: SaveSnapshotScript = null
var _local_storage_adapter: LocalStorageAdapterScript = null
var _save_storage: SaveStorageScript = null
var _settings_menu: SettingsMenuScript = null
var _settings_presenter: SettingsPresenterScript = SettingsPresenterScript.new()
var _store_shell: StoreShellScript = null
var _store_selected_item_id: StringName = StringName()
var _store_feedback_message: String = ""
var _pause_menu: PauseMenuScript = null
var _pause_menu_visible: bool = false
var _post_run_coin_doubler_reward_id: String = ""
var _start_y: float = 0.0
var utc_date_provider: UtcDateProviderScript = SystemUtcDateProviderScript.new()

func _ready() -> void:
	_validate_required_state()
	_configure_authored_handholds()
	_initialize_save_storage()
	_initialize_app_settings_storage()
	_load_or_create_app_settings()
	_apply_app_settings()
	_load_or_create_save_state()
	cosmetic_loadout = _duplicate_cosmetic_loadout(cosmetic_loadout)
	_apply_saved_cosmetic_selection()
	var _connect_result: int = _run_end_screen.connect(&"restart_requested", _on_run_end_restart_requested)
	var _rewarded_continue_connect_result: int = _run_end_screen.connect(&"rewarded_continue_requested", _on_rewarded_continue_requested)
	var _post_run_coin_doubler_connect_result: int = _run_end_screen.connect(&"post_run_coin_doubler_requested", _on_post_run_coin_doubler_requested)
	var _store_connect_result: int = _run_end_screen.connect(&"store_requested", _on_store_requested)
	var _pause_connect_result: int = _run_hud.connect(&"pause_requested", _on_pause_requested)
	var _chaser_connect_result: int = _chaser_kill_zone.connect(&"chaser_contacted", _on_chaser_contacted)
	_player.set_climb_tuning(climb_tuning)
	_stamina = StaminaRuntimeScript.new(stamina_tuning)
	_controller = ClimbPrototypeControllerScript.new(climb_tuning, _stamina)
	_chaser_pacing_model = ChaserPacingModelScript.new(_chaser_kill_zone.chaser_tuning)
	_apply_cosmetic_loadout()
	_start_y = _reset_anchor.global_position.y
	_configure_generated_chunks()
	_reset_playground()
	_refresh_ui()

func set_local_storage_adapter(local_storage_adapter: RefCounted) -> void:
	Validation.require_condition(local_storage_adapter != null, "RunScene requires a local storage adapter.")
	Validation.require_condition(local_storage_adapter is LocalStorageAdapterScript, "RunScene requires a LocalStorageAdapter implementation.")
	_local_storage_adapter = local_storage_adapter as LocalStorageAdapterScript
	if not is_node_ready():
		return

	_initialize_save_storage()
	_initialize_app_settings_storage()
	_load_or_create_app_settings()
	_apply_app_settings()
	if _save_snapshot == null:
		_load_or_create_save_state()
		_apply_saved_cosmetic_selection()
		_apply_cosmetic_loadout()
		_refresh_ui()
	_refresh_settings_menu()

func set_rewarded_ads_adapter(rewarded_ads_adapter: RefCounted) -> void:
	Validation.require_condition(rewarded_ads_adapter != null, "RunScene requires a rewarded ads adapter.")
	Validation.require_condition(rewarded_ads_adapter is RewardedAdsAdapterScript, "RunScene requires a RewardedAdsAdapter implementation.")
	_rewarded_ads_adapter = rewarded_ads_adapter as RewardedAdsAdapterScript
	if not is_node_ready():
		return

	_refresh_ui()

func set_app_lifecycle_adapter(app_lifecycle_adapter: RefCounted) -> void:
	Validation.require_condition(app_lifecycle_adapter != null, "RunScene requires an app lifecycle adapter.")
	Validation.require_condition(app_lifecycle_adapter is AppLifecycleAdapterScript, "RunScene requires an AppLifecycleAdapter implementation.")
	_app_lifecycle_adapter = app_lifecycle_adapter as AppLifecycleAdapterScript
	if not is_node_ready():
		return

	_consume_app_lifecycle_events()

func set_audio_settings_adapter(audio_settings_adapter: RefCounted) -> void:
	Validation.require_condition(audio_settings_adapter != null, "RunScene requires an audio settings adapter.")
	Validation.require_condition(audio_settings_adapter is AudioSettingsAdapterScript, "RunScene requires an AudioSettingsAdapter implementation.")
	_audio_settings_adapter = audio_settings_adapter as AudioSettingsAdapterScript
	if not is_node_ready():
		return

	_apply_app_settings()

func set_haptics_adapter(haptics_adapter: RefCounted) -> void:
	Validation.require_condition(haptics_adapter != null, "RunScene requires a haptics adapter.")
	Validation.require_condition(haptics_adapter is HapticsAdapterScript, "RunScene requires a HapticsAdapter implementation.")
	_haptics_adapter = haptics_adapter as HapticsAdapterScript

func set_save_snapshot(snapshot: RefCounted) -> void:
	Validation.require_condition(snapshot != null, "RunScene requires a save snapshot.")
	Validation.require_condition(snapshot is SaveSnapshotScript, "RunScene requires a SaveSnapshot implementation.")
	var typed_snapshot: SaveSnapshotScript = snapshot as SaveSnapshotScript
	typed_snapshot.assert_valid()
	_save_snapshot = typed_snapshot
	_hydrate_runtime_save_state_from_snapshot()
	if not is_node_ready():
		return

	_apply_saved_cosmetic_selection()
	_apply_cosmetic_loadout()
	_refresh_ui()

func set_utc_date_provider(date_provider: RefCounted) -> void:
	Validation.require_condition(date_provider != null, "RunScene requires a UTC date provider.")
	Validation.require_condition(date_provider is UtcDateProviderScript, "RunScene requires a UtcDateProvider implementation.")
	utc_date_provider = date_provider as UtcDateProviderScript
	if not is_node_ready():
		return

	_configure_generated_chunks()
	_reset_playground()
	_refresh_ui()

func _physics_process(delta: float) -> void:
	_consume_app_lifecycle_events()

	if _pause_menu_visible:
		return

	if _consume_debug_reset_input():
		_reset_playground()
		_refresh_ui()
		return

	var input_frame: PlayerInputFrameScript = _create_input_frame()
	_update_camera_follow()
	_sync_generated_chunks()
	_update_chaser(delta)

	if _resolve_bottom_screen_fall_if_needed():
		_clear_aim_preview()
		_refresh_ui()
		return

	if _run_session.get_state() != RunStateScript.Value.CLIMBING:
		_clear_aim_preview()
		_refresh_ui()
		return

	_advance_generated_handhold_lifecycle(delta)
	var attachment_state: HandAttachmentState = _controller.get_attachment_state()
	var left_was_attached: bool = attachment_state.is_attached(HandSideScript.Value.LEFT)
	var left_previous_hold_path: NodePath = NodePath()
	if left_was_attached:
		left_previous_hold_path = attachment_state.get_hold_path(HandSideScript.Value.LEFT)
	var right_was_attached: bool = attachment_state.is_attached(HandSideScript.Value.RIGHT)
	var right_previous_hold_path: NodePath = NodePath()
	if right_was_attached:
		right_previous_hold_path = attachment_state.get_hold_path(HandSideScript.Value.RIGHT)

	var left_target: RefCounted = _find_nearest_handhold(_player.get_left_hand_anchor_global_position())
	var right_target: RefCounted = _find_nearest_handhold(_player.get_right_hand_anchor_global_position())
	var result: ClimbPrototypeFrameResultScript = _controller.apply_input_frame(input_frame, left_target, right_target, delta)
	_resolve_generated_handhold_attachment_changes(
		left_was_attached,
		left_previous_hold_path,
		right_was_attached,
		right_previous_hold_path
	)

	_player.apply_frame_motion(result, _controller.get_attachment_state())
	_sync_aim_preview(input_frame)
	_record_height()

	if result.stamina_depleted_now:
		var stamina_fall_service: Object = _stamina_fall_service
		stamina_fall_service.call("resolve", _player, _run_session)
		_clear_aim_preview()
		_trigger_haptic_feedback(HapticFeedbackTypeScript.Value.WARNING)

	_refresh_ui()

func _advance_generated_handhold_lifecycle(delta_seconds: float) -> void:
	Validation.require_condition(delta_seconds >= 0.0, "RunScene generated handhold lifecycle advance cannot use a negative delta.")
	var attachment_state: HandAttachmentState = _controller.get_attachment_state()
	if attachment_state.is_attached(HandSideScript.Value.LEFT):
		var left_hold_path: NodePath = attachment_state.get_hold_path(HandSideScript.Value.LEFT)
		_advance_generated_handhold_lifecycle_for_path(left_hold_path, delta_seconds)

	if attachment_state.is_attached(HandSideScript.Value.RIGHT):
		var right_hold_path: NodePath = attachment_state.get_hold_path(HandSideScript.Value.RIGHT)
		if right_hold_path != attachment_state.get_hold_path(HandSideScript.Value.LEFT) or not attachment_state.is_attached(HandSideScript.Value.LEFT):
			_advance_generated_handhold_lifecycle_for_path(right_hold_path, delta_seconds)

func _advance_generated_handhold_lifecycle_for_path(hold_path: NodePath, delta_seconds: float) -> void:
	var generated_handhold: GeneratedHandholdAdapterScript = _get_generated_handhold_adapter(hold_path)
	if generated_handhold == null:
		return

	var broke_now: bool = generated_handhold.advance_attached_lifecycle(delta_seconds)
	if not broke_now:
		return

	var attachment_state: HandAttachmentState = _controller.get_attachment_state()
	if attachment_state.is_attached(HandSideScript.Value.LEFT) and attachment_state.get_hold_path(HandSideScript.Value.LEFT) == hold_path:
		attachment_state.release(HandSideScript.Value.LEFT)

	if attachment_state.is_attached(HandSideScript.Value.RIGHT) and attachment_state.get_hold_path(HandSideScript.Value.RIGHT) == hold_path:
		attachment_state.release(HandSideScript.Value.RIGHT)

func _resolve_generated_handhold_attachment_changes(
	left_was_attached: bool,
	left_previous_hold_path: NodePath,
	right_was_attached: bool,
	right_previous_hold_path: NodePath
) -> void:
	_resolve_generated_handhold_attachment_change_for_hand(
		HandSideScript.Value.LEFT,
		left_was_attached,
		left_previous_hold_path
	)
	_resolve_generated_handhold_attachment_change_for_hand(
		HandSideScript.Value.RIGHT,
		right_was_attached,
		right_previous_hold_path
	)

func _resolve_generated_handhold_attachment_change_for_hand(
	hand_side: int,
	was_attached: bool,
	previous_hold_path: NodePath
) -> void:
	HandSideScript.assert_valid(hand_side)
	var attachment_state: HandAttachmentState = _controller.get_attachment_state()
	var is_attached_now: bool = attachment_state.is_attached(hand_side)
	var current_hold_path: NodePath = NodePath()
	if is_attached_now:
		current_hold_path = attachment_state.get_hold_path(hand_side)

	if was_attached and (not is_attached_now or current_hold_path != previous_hold_path):
		_notify_generated_handhold_released(previous_hold_path)

	if is_attached_now and (not was_attached or current_hold_path != previous_hold_path):
		_notify_generated_handhold_attached(current_hold_path)

func _notify_generated_handhold_attached(hold_path: NodePath) -> void:
	var generated_handhold: GeneratedHandholdAdapterScript = _get_generated_handhold_adapter(hold_path)
	if generated_handhold == null:
		return

	generated_handhold.notify_hand_attached()

func _notify_generated_handhold_released(hold_path: NodePath) -> void:
	var generated_handhold: GeneratedHandholdAdapterScript = _get_generated_handhold_adapter(hold_path)
	if generated_handhold == null or generated_handhold.is_broken():
		return

	var release_impulse_pixels: Vector2 = generated_handhold.notify_hand_released()
	if release_impulse_pixels != Vector2.ZERO:
		_player.set_body_linear_velocity(_player.get_body_linear_velocity() + release_impulse_pixels)

func _get_generated_handhold_adapter(hold_path: NodePath) -> GeneratedHandholdAdapterScript:
	if hold_path.is_empty():
		return null

	var hold_node: Node = get_node_or_null(hold_path)
	if hold_node == null or not hold_node is GeneratedHandholdAdapterScript:
		return null

	return hold_node as GeneratedHandholdAdapterScript

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause_menu"):
		_toggle_pause_requested()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed(&"debug_reset_run"):
		_reset_playground()
		_refresh_ui()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventScreenTouch:
		_update_touch_position(event as InputEventScreenTouch)
		return

	if event is InputEventScreenDrag:
		_update_touch_drag(event as InputEventScreenDrag)

func _notification(notification_id: int) -> void:
	if _app_lifecycle_adapter is GodotAppLifecycleAdapterScript:
		var godot_lifecycle_adapter: GodotAppLifecycleAdapterScript = _app_lifecycle_adapter as GodotAppLifecycleAdapterScript
		var notification_recorded: bool = godot_lifecycle_adapter.record_notification(notification_id)
		if notification_recorded and is_node_ready():
			_consume_app_lifecycle_events()

func reset_for_test() -> void:
	_reset_playground()

func get_run_session_for_test() -> RunSessionScript:
	return _run_session

func get_wallet_for_test() -> WalletScript:
	return _wallet

func get_cosmetic_inventory_for_test() -> CosmeticInventoryScript:
	return _cosmetic_inventory

func get_cosmetic_loadout_for_test() -> CosmeticLoadoutScript:
	return cosmetic_loadout

func get_store_shell_for_test() -> StoreShellScript:
	return _store_shell

func show_store_for_test() -> void:
	_show_store()

func get_pause_menu_for_test() -> PauseMenuScript:
	return _pause_menu

func get_settings_menu_for_test() -> SettingsMenuScript:
	return _settings_menu

func show_pause_menu_for_test() -> void:
	_show_pause_menu()

func show_settings_menu_for_test() -> void:
	_show_settings_menu()

func is_pause_menu_visible_for_test() -> bool:
	return _pause_menu_visible

func consume_app_lifecycle_events_for_test() -> void:
	_consume_app_lifecycle_events()

func apply_persistent_coin_transaction(transaction_id: String, source: int, coin_delta: int) -> bool:
	Validation.require_condition(_save_storage != null, "RunScene requires save storage before applying persistent coin transactions.")
	var transaction_applied: bool = _persistent_coin_transaction_service.apply_persistent_transaction(
		_wallet,
		_persistent_transaction_ledger,
		_wallet_transaction_service,
		transaction_id,
		source,
		coin_delta
	)
	if not transaction_applied:
		return false

	_persist_save_state()
	_refresh_ui()
	return true

func purchase_cosmetic_item(item_id: StringName) -> CosmeticPurchaseResultScript:
	Validation.require_condition(not item_id.is_empty(), "RunScene cosmetic purchase item id cannot be empty.")
	Validation.require_condition(_save_storage != null, "RunScene requires save storage before purchasing cosmetics.")
	var result: CosmeticPurchaseResultScript = _cosmetic_unlock_purchase_service.purchase_item(
		_wallet,
		_cosmetic_inventory,
		cosmetic_item_catalog,
		_persistent_transaction_ledger,
		_wallet_transaction_service,
		_persistent_coin_transaction_service,
		item_id
	)
	_store_selected_item_id = result.item_id
	_store_feedback_message = _format_cosmetic_purchase_result(result)
	if result.outcome == CosmeticPurchaseOutcomeScript.Value.PURCHASED:
		_persist_save_state()

	_refresh_ui()
	return result

func equip_cosmetic_item(item_id: StringName) -> void:
	Validation.require_condition(not item_id.is_empty(), "RunScene cosmetic equip item id cannot be empty.")
	Validation.require_condition(_save_storage != null, "RunScene requires save storage before equipping cosmetics.")
	_cosmetic_loadout_service.equip_item(cosmetic_loadout, _cosmetic_inventory, cosmetic_item_catalog, item_id)
	_store_selected_item_id = item_id
	_store_feedback_message = "Equipped %s." % cosmetic_item_catalog.get_required_item_by_id(item_id).display_name
	_apply_cosmetic_loadout()
	_persist_save_state()
	_refresh_ui()

func apply_post_run_coin_doubler_reward(rewarded_ad_result: RefCounted, reward_id: String) -> bool:
	Validation.require_condition(rewarded_ad_result != null, "RunScene requires a rewarded ad result for post-run coin doubling.")
	Validation.require_condition(rewarded_ad_result is RewardedAdResultScript, "RunScene requires a RewardedAdResult implementation for post-run coin doubling.")
	Validation.require_condition(_run_session.get_state() == RunStateScript.Value.ENDED, "RunScene can only apply post-run coin doubler rewards after the run has ended.")
	Validation.require_condition(_run_session.get_run_earned_coins() > 0, "RunScene requires positive run-earned coins before applying post-run coin doubler rewards.")
	var bound_reward_id: String = _bind_post_run_coin_doubler_reward_id(reward_id)

	var reward_applied: bool = _post_run_coin_doubler_grant_service.apply_reward(
		_wallet,
		_persistent_transaction_ledger,
		_wallet_transaction_service,
		_persistent_coin_transaction_service,
		rewarded_ad_result,
		bound_reward_id,
		_run_session.get_run_earned_coins()
	)
	if not reward_applied:
		return false

	_persist_save_state()
	_refresh_ui()
	return true

func apply_rewarded_continue(rewarded_ad_result: RefCounted) -> bool:
	Validation.require_condition(rewarded_ad_result != null, "RunScene requires a rewarded ad result for rewarded continue.")
	Validation.require_condition(rewarded_ad_result is RewardedAdResultScript, "RunScene requires a RewardedAdResult implementation for rewarded continue.")
	Validation.require_condition(_run_session.get_state() == RunStateScript.Value.RESCUE_OFFERED, "RunScene can only apply rewarded continue while rescue is offered.")
	var reward_applied: bool = _rewarded_continue_service.apply_reward(_run_session, rewarded_ad_result)
	if not reward_applied:
		return false

	_restore_rewarded_continue()
	_clear_aim_preview()
	_refresh_ui()
	return true

func get_controller_for_test() -> ClimbPrototypeControllerScript:
	return _controller

func get_player_for_test() -> PlayerCharacterScript:
	return _player

func get_player_body_for_test() -> RigidBody2D:
	return _player.get_player_body()

func get_left_hand_anchor_for_test() -> Marker2D:
	return _player.get_left_hand_anchor()

func get_right_hand_anchor_for_test() -> Marker2D:
	return _player.get_right_hand_anchor()

func get_chaser_for_test() -> ChaserKillZoneScript:
	return _chaser_kill_zone

func get_generated_chunk_coordinator_for_test() -> GeneratedChunkCoordinatorScript:
	return _generated_chunk_coordinator

func get_chaser_feedback_snapshot_for_test() -> ChaserFeedbackSnapshotScript:
	Validation.require_condition(_chaser_pacing_model != null, "RunScene requires a chaser pacing model for feedback snapshots.")
	return _chaser_pacing_model.get_current_feedback_snapshot()

func get_chaser_feedback_intensity_ratio_for_test() -> float:
	Validation.require_condition(_chaser_kill_zone != null, "RunScene requires a chaser kill zone for feedback intensity.")
	return _chaser_kill_zone.get_feedback_intensity_ratio()

func resolve_chaser_contact_for_test() -> void:
	_on_chaser_contacted(_player.get_player_body())

func sync_grip_links_for_test() -> void:
	_player.sync_runtime_grip_links(_controller.get_attachment_state())

func sync_aim_preview_for_test(input_frame: PlayerInputFrameScript) -> void:
	_sync_aim_preview(input_frame)

func get_camera_player_lower_screen_offset_for_test() -> float:
	return _get_climb_tuning_float(&"camera_player_lower_screen_offset_pixels")

func get_bottom_fall_margin_for_test() -> float:
	return _get_climb_tuning_float(&"bottom_fall_margin_pixels")

func _validate_required_state() -> void:
	Validation.require_condition(climb_tuning != null, "RunScene requires climb tuning.")
	Validation.require_condition(stamina_tuning != null, "RunScene requires stamina tuning.")
	Validation.require_condition(generation_tuning != null, "RunScene requires generation tuning.")
	Validation.require_condition(cosmetic_loadout != null, "RunScene requires a cosmetic loadout.")
	Validation.require_condition(chaser_theme_catalog != null, "RunScene requires a chaser theme catalog.")
	Validation.require_condition(cosmetic_item_catalog != null, "RunScene requires a cosmetic item catalog.")
	Validation.require_condition(utc_date_provider != null, "RunScene requires a UTC date provider.")
	climb_tuning.assert_valid()
	stamina_tuning.assert_valid()
	generation_tuning.assert_valid()
	cosmetic_loadout.assert_valid()
	chaser_theme_catalog.assert_valid()
	cosmetic_item_catalog.assert_valid()
	_cosmetic_loadout_service.assert_loadout_matches_catalog(cosmetic_loadout, cosmetic_item_catalog)
	var _equipped_theme = chaser_theme_catalog.get_required_theme_by_id(cosmetic_loadout.chaser_theme_id)
	if _save_snapshot != null:
		_save_snapshot.assert_valid()
		var _saved_theme = chaser_theme_catalog.get_required_theme_by_id(_save_snapshot.chaser_theme_id)
		var _saved_body_item = cosmetic_item_catalog.get_required_item_by_id(_save_snapshot.body_cosmetic_id)
		var _saved_left_hand_item = cosmetic_item_catalog.get_required_item_by_id(_save_snapshot.left_hand_cosmetic_id)
		var _saved_right_hand_item = cosmetic_item_catalog.get_required_item_by_id(_save_snapshot.right_hand_cosmetic_id)
		var _saved_chaser_item = cosmetic_item_catalog.get_required_chaser_item_by_theme_id(_save_snapshot.chaser_theme_id)
	Validation.require_condition(_player != null, "RunScene requires PlayerCharacter.")
	Validation.require_condition(_chaser_kill_zone != null, "RunScene requires ChaserKillZone.")
	Validation.require_condition(_generated_chunk_coordinator != null, "RunScene requires GeneratedChunks coordinator.")
	Validation.require_condition(_reset_anchor != null, "RunScene requires ResetAnchor.")
	Validation.require_condition(_camera != null, "RunScene requires DevCamera.")
	Validation.require_condition(_starter_handholds_root != null, "RunScene requires Handholds.")
	Validation.require_condition(_run_hud != null, "RunScene requires RunHud.")
	Validation.require_condition(_run_end_screen != null, "RunScene requires RunEndScreen.")
	Validation.require_condition(_ui_layer != null, "RunScene requires UiLayer.")
	Validation.require_condition(get_tree().get_nodes_in_group(climb_tuning.handhold_group_name).size() > 0, "RunScene requires at least one handhold.")

func _configure_authored_handholds() -> void:
	Validation.require_condition(_starter_handholds_root != null, "RunScene requires Handholds before configuring authored handholds.")

	for child in _starter_handholds_root.get_children():
		Validation.require_condition(child is Node, "RunScene starter handhold roots must contain nodes.")
		var handhold_node: Node = child
		if not handhold_node.is_in_group(climb_tuning.handhold_group_name):
			continue

		Validation.require_condition(
			handhold_node is StaticBody2D,
			"RunScene authored handholds must be StaticBody2D instances."
		)
		if handhold_node is GeneratedHandholdAdapterScript:
			continue

		var normal_definition: HandholdTypeDefinitionScript = generation_tuning.get_required_handhold_definition(HandholdTypeScript.Value.NORMAL)
		var normal_surface_profile: HandholdSurfaceProfileScript = normal_definition.surface_profile as HandholdSurfaceProfileScript
		handhold_node.set_meta(
			&"stamina_drain_multiplier",
			normal_surface_profile.stamina_drain_multiplier
		)
		handhold_node.set_meta(&"handhold_type", HandholdTypeScript.to_label(HandholdTypeScript.Value.NORMAL))
		handhold_node.set_meta(&"definition_id", String(normal_definition.definition_id))

func _create_input_frame() -> PlayerInputFrameScript:
	if _active_touch_contacts.size() > 0 or _mobile_input.has_held_grip_state():
		Validation.require_condition(_app_settings_snapshot != null, "RunScene requires app settings before creating mobile input frames.")
		return _mobile_input.create_input_frame_from_contacts(
			get_viewport_rect().size,
			_active_touch_contacts,
			_app_settings_snapshot.to_touch_input_settings(),
			_controller.get_attachment_state()
		)

	return _desktop_input.create_input_frame(
		Input.is_action_pressed(&"debug_left_grip"),
		Input.is_action_pressed(&"debug_right_grip"),
		_get_debug_aim_vector(),
		false
	)

func _consume_debug_reset_input() -> bool:
	var reset_pressed_now: bool = Input.is_action_pressed(&"debug_reset_run")
	var should_reset: bool = reset_pressed_now and not _debug_reset_pressed
	_debug_reset_pressed = reset_pressed_now
	return should_reset

func _get_debug_aim_vector() -> Vector2:
	var aim_vector: Vector2 = Vector2.ZERO

	if Input.is_action_pressed(&"debug_aim_left"):
		aim_vector.x -= 1.0

	if Input.is_action_pressed(&"debug_aim_right"):
		aim_vector.x += 1.0

	if Input.is_action_pressed(&"debug_aim_up"):
		aim_vector.y -= 1.0

	return aim_vector

func _update_chaser(delta: float) -> void:
	if _chaser_kill_zone == null or _chaser_pacing_model == null:
		return

	var run_state: int = _run_session.get_state()
	if run_state == RunStateScript.Value.READY or run_state == RunStateScript.Value.ENDED:
		return

	_chaser_pacing_model.record_height(_calculate_current_height_meters(), delta)
	var feedback_snapshot: ChaserFeedbackSnapshotScript = _chaser_pacing_model.get_current_feedback_snapshot()
	_chaser_kill_zone.sync_feedback(
		feedback_snapshot,
		_player.get_body_global_position().y,
		_get_climb_tuning_float(&"pixels_per_meter")
	)
	_chaser_kill_zone.advance_rise(
		feedback_snapshot.rise_speed_meters_per_second,
		_get_climb_tuning_float(&"pixels_per_meter"),
		delta
	)

func _update_camera_follow() -> void:
	_camera.global_position.y = _run_loop_coordinator.calculate_camera_target_y(
		_camera.global_position.y,
		_player.get_body_global_position().y,
		_get_climb_tuning_float(&"camera_player_lower_screen_offset_pixels"),
		_run_session.get_state()
	)

func _resolve_bottom_screen_fall_if_needed() -> bool:
	var run_loop_coordinator: Object = _run_loop_coordinator
	var should_resolve_bottom_fall: bool = run_loop_coordinator.call(
		"should_resolve_bottom_screen_fall",
		_run_session.get_state(),
		_player.get_body_global_position().y,
		_camera.global_position.y,
		get_viewport_rect().size.y,
		_get_climb_tuning_float(&"bottom_fall_margin_pixels")
	)
	if not should_resolve_bottom_fall:
		return false

	var bottom_screen_fall_service: Object = _bottom_screen_fall_service
	bottom_screen_fall_service.call("resolve", _controller, _player, _run_session)
	return true

func _find_nearest_handhold(anchor_position: Vector2) -> RefCounted:
	var nearest_target: HandholdTargetScript = null
	var nearest_distance: float = climb_tuning.handhold_detection_radius_pixels

	for handhold in get_tree().get_nodes_in_group(climb_tuning.handhold_group_name):
		Validation.require_condition(handhold is Node2D, "RunScene handholds must be Node2D instances.")
		var handhold_node: Node2D = handhold
		var distance: float = anchor_position.distance_to(handhold_node.global_position)

		if distance <= nearest_distance:
			nearest_target = HandholdTargetScript.new(
				StringName(handhold_node.name),
				handhold_node.global_position,
				handhold_node.get_path(),
				_require_handhold_drain_multiplier(handhold_node),
				_require_handhold_type(handhold_node)
			)
			nearest_distance = distance

	return nearest_target

func _require_handhold_drain_multiplier(handhold_node: Node2D) -> float:
	Validation.require_condition(handhold_node != null, "RunScene requires a handhold node when reading drain multiplier.")

	if handhold_node is GeneratedHandholdAdapterScript:
		var typed_handhold: GeneratedHandholdAdapterScript = handhold_node
		return typed_handhold.stamina_drain_multiplier

	if _is_authored_starter_handhold(handhold_node):
		var normal_definition: HandholdTypeDefinitionScript = generation_tuning.get_required_handhold_definition(HandholdTypeScript.Value.NORMAL)
		var normal_surface_profile: HandholdSurfaceProfileScript = normal_definition.surface_profile as HandholdSurfaceProfileScript
		return normal_surface_profile.stamina_drain_multiplier

	Validation.require_condition(handhold_node.has_meta(&"stamina_drain_multiplier"), "RunScene handholds must provide a stamina drain multiplier.")
	var raw_drain_multiplier: Variant = handhold_node.get_meta(&"stamina_drain_multiplier")
	Validation.require_condition(
		raw_drain_multiplier is float or raw_drain_multiplier is int,
		"RunScene handhold stamina drain multiplier metadata must be numeric."
	)
	var drain_multiplier: float = 0.0
	if raw_drain_multiplier is float:
		drain_multiplier = raw_drain_multiplier
	else:
		var typed_drain_multiplier_int: int = raw_drain_multiplier
		drain_multiplier = float(typed_drain_multiplier_int)
	Validation.require_condition(drain_multiplier > 0.0, "RunScene handhold stamina drain multiplier must be positive.")
	return drain_multiplier

func _require_handhold_type(handhold_node: Node2D) -> int:
	Validation.require_condition(handhold_node != null, "RunScene requires a handhold node when reading handhold type.")

	if handhold_node is GeneratedHandholdAdapterScript:
		var typed_handhold: GeneratedHandholdAdapterScript = handhold_node
		return typed_handhold.handhold_type

	if _is_authored_starter_handhold(handhold_node):
		return HandholdTypeScript.Value.NORMAL

	Validation.require_condition(handhold_node.has_meta(&"handhold_type"), "RunScene handholds must provide a handhold type.")
	var raw_handhold_type: Variant = handhold_node.get_meta(&"handhold_type")
	Validation.require_condition(raw_handhold_type is String, "RunScene handhold type metadata must be a string label.")
	var handhold_type_label: String = raw_handhold_type
	var handhold_type: int = HandholdTypeScript.from_label(handhold_type_label)
	HandholdTypeScript.assert_valid(handhold_type)
	return handhold_type

func _is_authored_starter_handhold(handhold_node: Node2D) -> bool:
	Validation.require_condition(handhold_node != null, "RunScene requires a handhold node when checking starter-handhold ownership.")
	return handhold_node is StaticBody2D \
		and not handhold_node is GeneratedHandholdAdapterScript \
		and handhold_node.get_parent() == _starter_handholds_root

func _sync_aim_preview(input_frame: PlayerInputFrameScript) -> void:
	if not input_frame.has_aim_intent():
		_clear_aim_preview()
		return

	var attachment_state: HandAttachmentState = _controller.get_attachment_state()
	var aim_intent: Object = input_frame.aim_intent
	var aim_vector: Vector2 = aim_intent.get("aim_vector")
	var aim_target_position: Vector2 = _calculate_aim_preview_target_position(aim_vector)
	var left_visible: bool = not attachment_state.is_attached(HandSideScript.Value.LEFT)
	var right_visible: bool = not attachment_state.is_attached(HandSideScript.Value.RIGHT)

	_left_aim_preview = _sync_aim_preview_line(_left_aim_preview, left_visible, _player.get_left_hand_anchor_global_position(), aim_target_position, &"LeftAimPreview")
	_right_aim_preview = _sync_aim_preview_line(_right_aim_preview, right_visible, _player.get_right_hand_anchor_global_position(), aim_target_position, &"RightAimPreview")
	_aim_target_marker = _sync_aim_target_marker(_aim_target_marker, left_visible or right_visible, aim_target_position)

func _calculate_aim_preview_target_position(aim_vector: Vector2) -> Vector2:
	Validation.require_condition(aim_vector != Vector2.ZERO, "Aim preview target requires a non-zero aim vector.")
	var preview_distance: float = maxf(160.0, climb_tuning.handhold_detection_radius_pixels * 1.75)
	var hand_midpoint: Vector2 = (_player.get_left_hand_anchor_global_position() + _player.get_right_hand_anchor_global_position()) * 0.5
	return hand_midpoint + (aim_vector.normalized() * preview_distance)

func _sync_aim_preview_line(current_line: Line2D, should_show: bool, anchor_position: Vector2, target_position: Vector2, line_name: StringName) -> Line2D:
	if not should_show:
		if current_line != null:
			current_line.queue_free()
		return null

	var active_line: Line2D = current_line
	if active_line == null:
		active_line = Line2D.new()
		active_line.name = line_name
		active_line.width = 3.0
		active_line.default_color = Color(1.0, 0.87, 0.47, 0.85)
		add_child(active_line)

	active_line.points = PackedVector2Array([
		to_local(anchor_position),
		to_local(target_position)
	])
	return active_line

func _sync_aim_target_marker(current_marker: Polygon2D, should_show: bool, target_position: Vector2) -> Polygon2D:
	if not should_show:
		if current_marker != null:
			current_marker.queue_free()
		return null

	var active_marker: Polygon2D = current_marker
	if active_marker == null:
		active_marker = Polygon2D.new()
		active_marker.name = &"AimTargetMarker"
		active_marker.color = Color(1.0, 0.95, 0.62, 0.9)
		active_marker.polygon = PackedVector2Array([Vector2(0.0, -8.0), Vector2(8.0, 0.0), Vector2(0.0, 8.0), Vector2(-8.0, 0.0)])
		add_child(active_marker)

	active_marker.global_position = target_position
	return active_marker

func _calculate_current_height_meters() -> float:
	var height_pixels: float = maxf(0.0, _start_y - _player.get_body_global_position().y)
	return height_pixels / _get_climb_tuning_float(&"pixels_per_meter")

func _record_height() -> void:
	_run_session.record_height(_calculate_current_height_meters())

func _configure_generated_chunks() -> void:
	Validation.require_condition(_generated_chunk_coordinator != null, "RunScene requires GeneratedChunks before configuring generated chunks.")
	var pixels_per_meter: float = _get_climb_tuning_float(&"pixels_per_meter")
	var generated_world_origin: Vector2 = _reset_anchor.global_position
	var chunk_start_height_offset_meters: float = 0.0
	var seed_key: String = DailySeedKey.current_utc(utc_date_provider)
	var builder: GeneratedChunkSceneBuilderScript = GeneratedChunkSceneBuilderScript.new(
		pixels_per_meter,
		climb_tuning.handhold_group_name,
		Vector2(128.0, 34.0),
		2,
		0
	)
	var generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(generation_tuning)
	_generated_chunk_coordinator.configure(
		generation_tuning,
		generator,
		builder,
		seed_key,
		generated_world_origin,
		chunk_start_height_offset_meters
	)
	if not _generated_chunk_coordinator.chunk_spawned.is_connected(_on_generated_chunk_spawned):
		var _chunk_spawn_connect_result: int = _generated_chunk_coordinator.chunk_spawned.connect(_on_generated_chunk_spawned)

func _sync_generated_chunks() -> void:
	if _generated_chunk_coordinator == null:
		return

	_generated_chunk_coordinator.sync_chunks_for_height(_calculate_current_height_meters(), _collect_attached_hold_paths())

func _collect_attached_hold_paths() -> Array[NodePath]:
	var hold_paths: Array[NodePath] = []
	if _controller == null:
		return hold_paths

	var attachment_state: HandAttachmentState = _controller.get_attachment_state()
	if attachment_state.is_attached(HandSideScript.Value.LEFT):
		hold_paths.append(attachment_state.get_hold_path(HandSideScript.Value.LEFT))

	if attachment_state.is_attached(HandSideScript.Value.RIGHT):
		hold_paths.append(attachment_state.get_hold_path(HandSideScript.Value.RIGHT))

	return hold_paths

func _on_generated_chunk_spawned(chunk_node: Node2D) -> void:
	Validation.require_condition(chunk_node != null, "RunScene generated chunk hookup requires a chunk node.")
	_connect_generated_pickups(chunk_node)
	_connect_generated_hazards(chunk_node)

func _connect_generated_pickups(chunk_node: Node2D) -> void:
	var pickup_root: Node = chunk_node.get_node("Pickups")
	for pickup_child in pickup_root.get_children():
		Validation.require_condition(pickup_child is GeneratedCoinPickupSpawnAdapterScript, "RunScene generated pickups must use GeneratedCoinPickupSpawnAdapter.")
		var pickup_spawn: GeneratedCoinPickupSpawnAdapterScript = pickup_child as GeneratedCoinPickupSpawnAdapterScript
		var _connect_result: int = pickup_spawn.collected.connect(_on_generated_coin_pickup_collected)

func _connect_generated_hazards(chunk_node: Node2D) -> void:
	var hazard_root: Node = chunk_node.get_node("Hazards")
	for hazard_child in hazard_root.get_children():
		Validation.require_condition(hazard_child is GeneratedHazardSpawnAdapterScript, "RunScene generated hazards must use GeneratedHazardSpawnAdapter.")
		var hazard_spawn: GeneratedHazardSpawnAdapterScript = hazard_child as GeneratedHazardSpawnAdapterScript
		var _connect_result: int = hazard_spawn.triggered.connect(_on_generated_hazard_triggered.bind(hazard_spawn))

func _on_generated_coin_pickup_collected(socket_id: StringName, coin_amount: int, body: Node) -> void:
	Validation.require_condition(not String(socket_id).is_empty(), "RunScene generated coin pickup requires a socket id.")
	if not _is_run_active_for_generated_spawns():
		return

	var pickup_applied: bool = _normal_coin_pickup_service.resolve(
		socket_id,
		body,
		_player,
		_run_session,
		_wallet,
		_run_pickup_transaction_ledger,
		_wallet_transaction_service,
		coin_amount
	)
	if not pickup_applied:
		return

	_persist_save_state()
	_trigger_haptic_feedback(HapticFeedbackTypeScript.Value.LIGHT_IMPACT)
	_refresh_ui()

func _on_generated_hazard_triggered(body: Node, hazard_spawn: GeneratedHazardSpawnAdapterScript) -> void:
	Validation.require_condition(hazard_spawn != null, "RunScene generated hazard hookup requires a hazard spawn.")
	Validation.require_condition(not String(hazard_spawn.socket_id).is_empty(), "RunScene generated hazard contact requires a socket id.")
	if body != _player.get_player_body():
		return

	var run_state: int = _run_session.get_state()
	if run_state == RunStateScript.Value.READY or run_state == RunStateScript.Value.ENDED:
		return

	match hazard_spawn.hazard_kind:
		GeneratedHazardKindScript.Value.SPIKE_CLUSTER:
			_lethal_hazard_contact_service.resolve(_controller, _player, _run_session)
		GeneratedHazardKindScript.Value.WIND_GUST, GeneratedHazardKindScript.Value.DOWNDRAFT, GeneratedHazardKindScript.Value.UPDRAFT:
			_wind_gust_hazard_contact_service.resolve(
				_controller,
				_player,
				_run_session,
				hazard_spawn.get_impulse_vector_pixels()
			)
		_:
			Validation.require_condition(false, "RunScene requires a supported generated hazard kind.")
	_clear_aim_preview()
	_trigger_haptic_feedback(HapticFeedbackTypeScript.Value.WARNING)
	_refresh_ui()

func _is_run_active_for_generated_spawns() -> bool:
	var run_state: int = _run_session.get_state()
	return run_state == RunStateScript.Value.CLIMBING or run_state == RunStateScript.Value.FALLING or run_state == RunStateScript.Value.RESCUE_OFFERED

func _reset_playground() -> void:
	_clear_aim_preview()

	if _controller != null:
		_controller.reset()

	_desktop_input.reset()
	_mobile_input.reset()
	_active_touch_contacts = []
	_post_run_coin_doubler_reward_id = ""
	_rewarded_continue_feedback_message = ""
	_run_pickup_transaction_ledger = CoinTransactionLedgerScript.new()
	_run_session = RunSessionScript.new()
	_run_session.start_run()
	if _chaser_pacing_model != null:
		_chaser_pacing_model.reset()
	if _generated_chunk_coordinator != null:
		_generated_chunk_coordinator.reset_chunks()
	_player.reset_physics(_reset_anchor.global_position)
	_camera.global_position = Vector2(
		_reset_anchor.global_position.x,
		_reset_anchor.global_position.y - _get_climb_tuning_float(&"camera_player_lower_screen_offset_pixels")
	)
	if _chaser_kill_zone != null:
		_apply_cosmetic_loadout()
		_chaser_kill_zone.reset_to_player_position(
			_player.get_body_global_position().y,
			_get_climb_tuning_float(&"pixels_per_meter"),
			_camera.global_position.x,
			get_viewport_rect().size.x
		)

func _apply_equipped_chaser_theme() -> void:
	if _chaser_kill_zone == null or chaser_theme_catalog == null or cosmetic_loadout == null:
		return

	_chaser_kill_zone.apply_theme(chaser_theme_catalog.get_required_theme_by_id(cosmetic_loadout.chaser_theme_id))

func _apply_cosmetic_loadout() -> void:
	if _player == null or cosmetic_loadout == null or cosmetic_item_catalog == null:
		return

	_cosmetic_loadout_service.assert_loadout_matches_catalog(cosmetic_loadout, cosmetic_item_catalog)
	if _cosmetic_inventory != null:
		_cosmetic_loadout_service.assert_loadout_owned(cosmetic_loadout, _cosmetic_inventory, cosmetic_item_catalog)
	_player_cosmetic_applicator.apply_loadout(_player, cosmetic_loadout, cosmetic_item_catalog)
	_apply_equipped_chaser_theme()

func _apply_saved_cosmetic_selection() -> void:
	if _save_snapshot == null:
		return

	Validation.require_condition(cosmetic_loadout != null, "RunScene requires a cosmetic loadout before applying saved selection.")
	cosmetic_loadout.chaser_theme_id = _save_snapshot.chaser_theme_id
	cosmetic_loadout.body_cosmetic_id = _save_snapshot.body_cosmetic_id
	cosmetic_loadout.left_hand_cosmetic_id = _save_snapshot.left_hand_cosmetic_id
	cosmetic_loadout.right_hand_cosmetic_id = _save_snapshot.right_hand_cosmetic_id
	cosmetic_loadout.assert_valid()
	_cosmetic_loadout_service.assert_loadout_matches_catalog(cosmetic_loadout, cosmetic_item_catalog)
	_cosmetic_loadout_service.assert_loadout_owned(cosmetic_loadout, _cosmetic_inventory, cosmetic_item_catalog)

func _duplicate_cosmetic_loadout(loadout: Resource) -> CosmeticLoadoutScript:
	Validation.require_condition(loadout != null, "RunScene requires a cosmetic loadout resource.")
	Validation.require_condition(loadout is CosmeticLoadoutScript, "RunScene requires a CosmeticLoadout resource.")
	var duplicated_loadout: Resource = (loadout as CosmeticLoadoutScript).duplicate(true)
	Validation.require_condition(duplicated_loadout is CosmeticLoadoutScript, "RunScene duplicated cosmetic loadout must implement CosmeticLoadout.")
	var typed_duplicated_loadout: CosmeticLoadoutScript = duplicated_loadout as CosmeticLoadoutScript
	typed_duplicated_loadout.assert_valid()
	return typed_duplicated_loadout

func _initialize_save_storage() -> void:
	if _local_storage_adapter == null:
		_local_storage_adapter = JsonFileLocalStorageAdapterScript.new()
	_save_storage = SaveStorageScript.new(_local_storage_adapter)

func _initialize_app_settings_storage() -> void:
	if _local_storage_adapter == null:
		_local_storage_adapter = JsonFileLocalStorageAdapterScript.new()
	_app_settings_storage = AppSettingsStorageScript.new(_local_storage_adapter)

func _load_or_create_app_settings() -> void:
	Validation.require_condition(_app_settings_storage != null, "RunScene requires app settings storage before loading app settings.")
	if _app_settings_storage.has_snapshot():
		_app_settings_snapshot = _app_settings_storage.load_snapshot()
	else:
		_app_settings_snapshot = AppSettingsSnapshotScript.new()

func _apply_app_settings() -> void:
	Validation.require_condition(_app_settings_snapshot != null, "RunScene requires app settings before applying them.")
	Validation.require_condition(_audio_settings_adapter != null, "RunScene requires an audio settings adapter before applying app settings.")
	_audio_settings_adapter.apply_master_settings(_app_settings_snapshot.master_volume_ratio, _app_settings_snapshot.audio_muted)

func _trigger_haptic_feedback(feedback_type: int) -> void:
	HapticFeedbackTypeScript.assert_valid(feedback_type)
	Validation.require_condition(_app_settings_snapshot != null, "RunScene requires app settings before triggering haptic feedback.")
	Validation.require_condition(_haptics_adapter != null, "RunScene requires a haptics adapter before triggering haptic feedback.")
	if not _app_settings_snapshot.haptics_enabled:
		return

	if not _haptics_adapter.supports_feedback(feedback_type):
		return

	_haptics_adapter.trigger_feedback(feedback_type)

func _persist_app_settings() -> void:
	Validation.require_condition(_app_settings_storage != null, "RunScene requires app settings storage before saving app settings.")
	Validation.require_condition(_app_settings_snapshot != null, "RunScene requires app settings before saving app settings.")
	_app_settings_snapshot.assert_valid()
	_app_settings_storage.save_snapshot(_app_settings_snapshot)
	_apply_app_settings()
	_refresh_settings_menu(true)

func _load_or_create_save_state() -> void:
	Validation.require_condition(_save_storage != null, "RunScene requires save storage before loading save state.")
	if _save_snapshot == null:
		if _save_storage.has_snapshot():
			_save_snapshot = _save_storage.load_snapshot()
		else:
			_save_snapshot = SaveSnapshotScript.new(
				0,
				SaveSchemaScript.VERSION,
				cosmetic_loadout.chaser_theme_id,
				PackedStringArray(),
				_get_owned_item_ids_for_new_save(),
				cosmetic_loadout.body_cosmetic_id,
				cosmetic_loadout.left_hand_cosmetic_id,
				cosmetic_loadout.right_hand_cosmetic_id
			)

	_hydrate_runtime_save_state_from_snapshot()

func _hydrate_runtime_save_state_from_snapshot() -> void:
	if _save_snapshot == null:
		return

	_save_snapshot.assert_valid()
	_wallet = WalletScript.new(_save_snapshot.wallet_coins)
	_persistent_transaction_ledger = CoinTransactionLedgerScript.new(_save_snapshot.applied_persistent_transaction_ids)
	_cosmetic_inventory = CosmeticInventoryScript.new(_save_snapshot.owned_cosmetic_ids, cosmetic_item_catalog.get_default_unlocked_item_ids())

func _get_owned_item_ids_for_new_save() -> PackedStringArray:
	var owned_item_ids: PackedStringArray = cosmetic_item_catalog.get_default_unlocked_item_ids()
	_append_unique_owned_item_id(owned_item_ids, cosmetic_loadout.body_cosmetic_id)
	_append_unique_owned_item_id(owned_item_ids, cosmetic_loadout.left_hand_cosmetic_id)
	_append_unique_owned_item_id(owned_item_ids, cosmetic_loadout.right_hand_cosmetic_id)
	var chaser_item: CosmeticItemScript = cosmetic_item_catalog.get_required_chaser_item_by_theme_id(cosmetic_loadout.chaser_theme_id)
	_append_unique_owned_item_id(owned_item_ids, chaser_item.item_id)
	return owned_item_ids

func _append_unique_owned_item_id(owned_item_ids: PackedStringArray, item_id: StringName) -> void:
	Validation.require_condition(not item_id.is_empty(), "RunScene new save owned item id cannot be empty.")
	var item_id_string: String = String(item_id)
	if not owned_item_ids.has(item_id_string):
		var _append_result: bool = owned_item_ids.append(item_id_string)

func _persist_save_state() -> void:
	Validation.require_condition(_save_storage != null, "RunScene requires save storage before persisting save state.")
	Validation.require_condition(_cosmetic_inventory != null, "RunScene requires cosmetic inventory before persisting save state.")
	_cosmetic_loadout_service.assert_loadout_owned(cosmetic_loadout, _cosmetic_inventory, cosmetic_item_catalog)
	var snapshot: SaveSnapshotScript = SaveSnapshotScript.new(
		_wallet.get_coins(),
		SaveSchemaScript.VERSION,
		cosmetic_loadout.chaser_theme_id,
		_persistent_transaction_ledger.get_transaction_ids(),
		_cosmetic_inventory.get_owned_item_ids(),
		cosmetic_loadout.body_cosmetic_id,
		cosmetic_loadout.left_hand_cosmetic_id,
		cosmetic_loadout.right_hand_cosmetic_id
	)
	_save_storage.save_snapshot(snapshot)
	_save_snapshot = snapshot

func _refresh_ui() -> void:
	if _stamina == null or _run_ui_view == null:
		return

	var hud_state: RefCounted = _run_ui_presenter.build_hud_state(_run_session, _stamina, _wallet)
	var run_end_state: RefCounted = _run_ui_presenter.build_run_end_screen_state_with_ad_offers(
		_run_session,
		_wallet,
		_can_offer_post_run_coin_doubler(),
		_can_offer_rewarded_continue(),
		_rewarded_continue_feedback_message
	)
	_run_ui_view.apply_state_snapshots(hud_state, run_end_state)
	if _store_shell != null and _store_shell.visible:
		_refresh_store_ui()
	if _pause_menu != null:
		_refresh_pause_menu_ui()
	if _settings_menu != null:
		_refresh_settings_menu(_settings_menu.visible)

func _show_pause_menu() -> void:
	if _run_session.get_state() == RunStateScript.Value.ENDED:
		return

	_ensure_pause_menu()
	_pause_menu_visible = true
	get_tree().paused = true
	_refresh_pause_menu_ui()

func _resume_from_pause_menu() -> void:
	if not _pause_menu_visible:
		return

	_hide_settings_menu()
	_pause_menu_visible = false
	get_tree().paused = false
	_refresh_pause_menu_ui()
	_refresh_ui()

func _ensure_pause_menu() -> void:
	if _pause_menu != null:
		return

	Validation.require_condition(_ui_layer != null, "RunScene requires UiLayer before showing the pause menu.")
	var pause_node: Node = PauseMenuScene.instantiate()
	Validation.require_condition(pause_node != null, "RunScene pause menu scene must instantiate a node.")
	Validation.require_condition(pause_node is PauseMenuScript, "RunScene pause menu scene must instantiate PauseMenu.")
	_pause_menu = pause_node as PauseMenuScript
	_ui_layer.add_child(_pause_menu)
	var _resume_connect_result: int = _pause_menu.connect(&"resume_requested", _on_pause_resume_requested)
	var _restart_connect_result: int = _pause_menu.connect(&"restart_requested", _on_pause_restart_requested)
	var _settings_connect_result: int = _pause_menu.connect(&"settings_requested", _on_pause_settings_requested)

func _refresh_pause_menu_ui() -> void:
	Validation.require_condition(_pause_menu != null, "RunScene requires PauseMenu before refreshing pause UI.")
	var pause_state: PauseMenuStateScript = PauseMenuStateScript.new(
		_pause_menu_visible,
		_run_session.get_height_meters(),
		_wallet.get_coins(),
		_run_session.get_run_earned_coins()
	)
	_pause_menu.apply_state(pause_state)

func _toggle_pause_requested() -> void:
	if _pause_menu_visible:
		_resume_from_pause_menu()
		return

	_show_pause_menu()

func _consume_app_lifecycle_events() -> void:
	Validation.require_condition(_app_lifecycle_adapter != null, "RunScene requires an app lifecycle adapter before consuming lifecycle events.")
	var lifecycle_events: PackedInt32Array = _app_lifecycle_adapter.consume_pending_events()
	for lifecycle_event: int in lifecycle_events:
		_handle_app_lifecycle_event(lifecycle_event)

func _handle_app_lifecycle_event(lifecycle_event: int) -> void:
	AppLifecycleEventScript.assert_valid(lifecycle_event)
	match lifecycle_event:
		AppLifecycleEventScript.Value.PAUSED:
			_show_pause_menu()
		AppLifecycleEventScript.Value.ENTERED_BACKGROUND:
			_show_pause_menu()
		AppLifecycleEventScript.Value.QUIT_REQUESTED:
			_show_pause_menu()
		AppLifecycleEventScript.Value.RESUMED:
			_refresh_ui()
		AppLifecycleEventScript.Value.ENTERED_FOREGROUND:
			_refresh_ui()
		_:
			Validation.require_condition(false, "RunScene requires a supported app lifecycle event.")

func _show_store() -> void:
	_ensure_store_shell()
	_refresh_store_ui()

func _show_settings_menu() -> void:
	_ensure_settings_menu()
	_refresh_settings_menu(true)

func _hide_settings_menu() -> void:
	if _settings_menu == null:
		return

	_refresh_settings_menu(false)

func _ensure_settings_menu() -> void:
	if _settings_menu != null:
		return

	Validation.require_condition(_ui_layer != null, "RunScene requires UiLayer before showing the settings menu.")
	var settings_node: Node = SettingsMenuScene.instantiate()
	Validation.require_condition(settings_node != null, "RunScene settings menu scene must instantiate a node.")
	Validation.require_condition(settings_node is SettingsMenuScript, "RunScene settings menu scene must instantiate SettingsMenu.")
	_settings_menu = settings_node as SettingsMenuScript
	_ui_layer.add_child(_settings_menu)
	var _closed_connect_result: int = _settings_menu.connect(&"closed", _on_settings_closed)
	var _audio_muted_connect_result: int = _settings_menu.connect(&"audio_muted_changed", _on_settings_audio_muted_changed)
	var _volume_connect_result: int = _settings_menu.connect(&"master_volume_changed", _on_settings_master_volume_changed)
	var _haptics_connect_result: int = _settings_menu.connect(&"haptics_enabled_changed", _on_settings_haptics_enabled_changed)
	var _touch_split_connect_result: int = _settings_menu.connect(&"touch_split_changed", _on_settings_touch_split_changed)
	var _touch_dead_zone_connect_result: int = _settings_menu.connect(&"touch_center_dead_zone_changed", _on_settings_touch_center_dead_zone_changed)

func _refresh_settings_menu(visible: bool = false) -> void:
	if _settings_menu == null:
		return

	Validation.require_condition(_app_settings_snapshot != null, "RunScene requires app settings before refreshing settings UI.")
	_settings_menu.apply_state(_settings_presenter.build_state(_app_settings_snapshot, visible))

func _ensure_store_shell() -> void:
	if _store_shell != null:
		return

	Validation.require_condition(_ui_layer != null, "RunScene requires UiLayer before showing the store.")
	var store_node: Node = StoreShellScene.instantiate()
	Validation.require_condition(store_node != null, "RunScene store scene must instantiate a node.")
	Validation.require_condition(store_node is StoreShellScript, "RunScene store scene must instantiate StoreShell.")
	_store_shell = store_node as StoreShellScript
	_ui_layer.add_child(_store_shell)
	var _select_connect_result: int = _store_shell.connect(&"item_selected", _on_store_item_selected)
	var _purchase_connect_result: int = _store_shell.connect(&"purchase_requested", _on_store_purchase_requested)
	var _equip_connect_result: int = _store_shell.connect(&"equip_requested", _on_store_equip_requested)
	var _closed_connect_result: int = _store_shell.connect(&"closed", _on_store_closed)

func _refresh_store_ui() -> void:
	Validation.require_condition(_store_shell != null, "RunScene requires StoreShell before refreshing store UI.")
	var store_state: RefCounted = _store_presenter.build_state(
		cosmetic_item_catalog,
		_cosmetic_inventory,
		cosmetic_loadout,
		_wallet,
		_store_selected_item_id,
		_store_feedback_message
	)
	_store_shell.apply_state(store_state)

func _format_cosmetic_purchase_result(result: CosmeticPurchaseResultScript) -> String:
	Validation.require_condition(result != null, "RunScene requires a cosmetic purchase result to format feedback.")
	result.assert_valid()
	var item_display_name: String = cosmetic_item_catalog.get_required_item_by_id(result.item_id).display_name
	match result.outcome:
		CosmeticPurchaseOutcomeScript.Value.PURCHASED:
			return "Unlocked %s." % item_display_name
		CosmeticPurchaseOutcomeScript.Value.ALREADY_OWNED:
			return "%s is already owned." % item_display_name
		CosmeticPurchaseOutcomeScript.Value.INSUFFICIENT_FUNDS:
			return "Not enough coins for %s." % item_display_name
		_:
			Validation.require_condition(false, "RunScene requires a supported cosmetic purchase outcome.")
			return ""

func _on_run_end_restart_requested() -> void:
	_reset_playground()
	_refresh_ui()

func _on_pause_requested() -> void:
	_show_pause_menu()

func _on_pause_resume_requested() -> void:
	_resume_from_pause_menu()

func _on_pause_restart_requested() -> void:
	_hide_settings_menu()
	_pause_menu_visible = false
	get_tree().paused = false
	_reset_playground()
	_refresh_ui()

func _on_pause_settings_requested() -> void:
	_show_settings_menu()

func _on_settings_closed() -> void:
	_hide_settings_menu()

func _on_settings_audio_muted_changed(audio_muted: bool) -> void:
	Validation.require_condition(_app_settings_snapshot != null, "RunScene requires app settings before changing audio mute.")
	_app_settings_snapshot.audio_muted = audio_muted
	_persist_app_settings()

func _on_settings_master_volume_changed(master_volume_ratio: float) -> void:
	Validation.require_condition(_app_settings_snapshot != null, "RunScene requires app settings before changing master volume.")
	_app_settings_snapshot.master_volume_ratio = master_volume_ratio
	_persist_app_settings()

func _on_settings_haptics_enabled_changed(haptics_enabled: bool) -> void:
	Validation.require_condition(_app_settings_snapshot != null, "RunScene requires app settings before changing haptics.")
	_app_settings_snapshot.haptics_enabled = haptics_enabled
	_persist_app_settings()

func _on_settings_touch_split_changed(touch_split_ratio: float) -> void:
	Validation.require_condition(_app_settings_snapshot != null, "RunScene requires app settings before changing touch split.")
	_app_settings_snapshot.touch_split_ratio = touch_split_ratio
	_persist_app_settings()

func _on_settings_touch_center_dead_zone_changed(touch_center_dead_zone_ratio: float) -> void:
	Validation.require_condition(_app_settings_snapshot != null, "RunScene requires app settings before changing touch center dead zone.")
	_app_settings_snapshot.touch_center_dead_zone_ratio = touch_center_dead_zone_ratio
	_persist_app_settings()

func _on_rewarded_continue_requested() -> void:
	if not _can_offer_rewarded_continue():
		_refresh_ui()
		return

	var rewarded_ad_result: RefCounted = _rewarded_ads_adapter.show(RewardedAdPlacementScript.Value.CONTINUE)
	Validation.require_condition(rewarded_ad_result != null, "RunScene rewarded ads adapter must return a rewarded ad result.")
	Validation.require_condition(rewarded_ad_result is RewardedAdResultScript, "RunScene rewarded ads adapter must return a RewardedAdResult implementation.")
	if apply_rewarded_continue(rewarded_ad_result):
		_trigger_haptic_feedback(HapticFeedbackTypeScript.Value.SUCCESS)
	else:
		var typed_result: RewardedAdResultScript = rewarded_ad_result
		match typed_result.outcome:
			RewardedAdOutcomeScript.Value.CANCELLED:
				_rewarded_continue_feedback_message = "Ad cancelled — you can try again."
			RewardedAdOutcomeScript.Value.FAILED:
				_rewarded_continue_feedback_message = "Ad failed to load — you can try again."
			_:
				_rewarded_continue_feedback_message = ""
		_refresh_ui()

func _on_post_run_coin_doubler_requested() -> void:
	if not _can_offer_post_run_coin_doubler():
		_refresh_ui()
		return

	var rewarded_ad_result: RefCounted = _rewarded_ads_adapter.show(RewardedAdPlacementScript.Value.POST_RUN_COIN_DOUBLER)
	Validation.require_condition(rewarded_ad_result != null, "RunScene rewarded ads adapter must return a rewarded ad result.")
	Validation.require_condition(rewarded_ad_result is RewardedAdResultScript, "RunScene rewarded ads adapter must return a RewardedAdResult implementation.")
	var reward_applied: bool = apply_post_run_coin_doubler_reward(rewarded_ad_result, _get_or_create_post_run_coin_doubler_reward_id())
	if not reward_applied:
		_refresh_ui()

func _on_store_requested() -> void:
	_show_store()

func _on_store_item_selected(item_id: StringName) -> void:
	Validation.require_condition(not item_id.is_empty(), "RunScene store selected item id cannot be empty.")
	_store_selected_item_id = item_id
	_store_feedback_message = ""
	_refresh_store_ui()

func _on_store_purchase_requested(item_id: StringName) -> void:
	var result: CosmeticPurchaseResultScript = purchase_cosmetic_item(item_id)
	if result.outcome == CosmeticPurchaseOutcomeScript.Value.PURCHASED:
		_trigger_haptic_feedback(HapticFeedbackTypeScript.Value.SUCCESS)

func _on_store_equip_requested(item_id: StringName) -> void:
	equip_cosmetic_item(item_id)
	_trigger_haptic_feedback(HapticFeedbackTypeScript.Value.LIGHT_IMPACT)

func _on_store_closed() -> void:
	_store_feedback_message = ""

func _on_chaser_contacted(body: Node) -> void:
	Validation.require_condition(body != null, "RunScene chaser contact requires a body.")
	if body != _player.get_player_body():
		return

	var run_state: int = _run_session.get_state()
	if run_state == RunStateScript.Value.READY or run_state == RunStateScript.Value.ENDED:
		return

	_chaser_contact_service.resolve(_controller, _player, _run_session)
	_clear_aim_preview()
	_trigger_haptic_feedback(HapticFeedbackTypeScript.Value.ERROR)
	_refresh_ui()

func _can_offer_rewarded_continue() -> bool:
	Validation.require_condition(_rewarded_ads_adapter != null, "RunScene requires a rewarded ads adapter before checking rewarded continue availability.")
	if _run_session.get_state() != RunStateScript.Value.RESCUE_OFFERED:
		return false

	return _rewarded_ads_adapter.can_show(RewardedAdPlacementScript.Value.CONTINUE)

func _can_offer_post_run_coin_doubler() -> bool:
	Validation.require_condition(_rewarded_ads_adapter != null, "RunScene requires a rewarded ads adapter before checking post-run doubler availability.")
	if _run_session.get_state() != RunStateScript.Value.ENDED:
		return false

	if _run_session.get_run_earned_coins() <= 0:
		return false

	if not _rewarded_ads_adapter.can_show(RewardedAdPlacementScript.Value.POST_RUN_COIN_DOUBLER):
		return false

	var reward_id: String = _get_or_create_post_run_coin_doubler_reward_id()
	var transaction_id: String = _post_run_coin_doubler_grant_service.build_transaction_id(reward_id)
	return not _persistent_transaction_ledger.has_transaction_id(transaction_id)

func _get_or_create_post_run_coin_doubler_reward_id() -> String:
	Validation.require_condition(_run_session.get_state() == RunStateScript.Value.ENDED, "RunScene can only build a post-run coin doubler reward id after the run has ended.")
	if _post_run_coin_doubler_reward_id.is_empty():
		_post_run_coin_doubler_reward_id = "run_summary_%s" % str(_run_session.get_instance_id())
	return _post_run_coin_doubler_reward_id

func _bind_post_run_coin_doubler_reward_id(reward_id: String) -> String:
	Validation.require_condition(not reward_id.is_empty(), "RunScene post-run coin doubler reward id cannot be empty.")
	if _post_run_coin_doubler_reward_id.is_empty():
		_post_run_coin_doubler_reward_id = reward_id
	Validation.require_condition(
		_post_run_coin_doubler_reward_id == reward_id,
		"RunScene post-run coin doubler reward id must remain stable for the current run summary."
	)
	return _post_run_coin_doubler_reward_id

func _restore_rewarded_continue() -> void:
	var rescue_hold_targets: Array[HandholdTargetScript] = _find_rewarded_continue_hold_targets()
	Validation.require_condition(rescue_hold_targets.size() == 2, "RunScene rewarded continue requires exactly two rescue hold targets.")
	var left_hold_target: HandholdTargetScript = rescue_hold_targets[0]
	var right_hold_target: HandholdTargetScript = rescue_hold_targets[1]
	var rescue_body_position: Vector2 = _calculate_rewarded_continue_body_position(left_hold_target, right_hold_target)

	_controller.reset()
	_player.reset_physics(rescue_body_position)
	var attachment_state: HandAttachmentState = _controller.get_attachment_state()
	attachment_state.attach(HandSideScript.Value.LEFT, left_hold_target.hold_id, left_hold_target.attach_position, left_hold_target.hold_path)
	attachment_state.attach(HandSideScript.Value.RIGHT, right_hold_target.hold_id, right_hold_target.attach_position, right_hold_target.hold_path)
	_notify_generated_handhold_attached(left_hold_target.hold_path)
	_notify_generated_handhold_attached(right_hold_target.hold_path)
	_player.sync_runtime_grip_joints(attachment_state)
	_player.sync_runtime_grip_links(attachment_state)
	_camera.global_position = Vector2(
		_camera.global_position.x,
		rescue_body_position.y - _get_climb_tuning_float(&"camera_player_lower_screen_offset_pixels")
	)
	_sync_generated_chunks()

func _find_rewarded_continue_hold_targets() -> Array[HandholdTargetScript]:
	var handholds: Array[StaticBody2D] = []
	for handhold in get_tree().get_nodes_in_group(climb_tuning.handhold_group_name):
		Validation.require_condition(handhold is StaticBody2D, "RunScene rescue handholds must be StaticBody2D instances.")
		handholds.append(handhold as StaticBody2D)

	Validation.require_condition(handholds.size() >= 2, "RunScene rewarded continue requires at least two handholds.")
	var target_body_y: float = _camera.global_position.y + _get_climb_tuning_float(&"camera_player_lower_screen_offset_pixels")
	var target_hold_average_y: float = target_body_y - _get_climb_tuning_float(&"grip_hang_offset_pixels")
	var target_center_x: float = _camera.global_position.x
	var target_anchor_spacing: float = _player.get_left_hand_anchor_global_position().distance_to(_player.get_right_hand_anchor_global_position())
	var best_score: float = INF
	var best_left_hold: StaticBody2D = null
	var best_right_hold: StaticBody2D = null

	for first_index in range(handholds.size() - 1):
		for second_index in range(first_index + 1, handholds.size()):
			var first_hold: StaticBody2D = handholds[first_index]
			var second_hold: StaticBody2D = handholds[second_index]
			var left_hold: StaticBody2D = first_hold
			var right_hold: StaticBody2D = second_hold
			if left_hold.global_position.x > right_hold.global_position.x:
				var swapped_hold: StaticBody2D = left_hold
				left_hold = right_hold
				right_hold = swapped_hold

			var average_position: Vector2 = (left_hold.global_position + right_hold.global_position) * 0.5
			var spacing_x: float = absf(right_hold.global_position.x - left_hold.global_position.x)
			var vertical_target_penalty: float = absf(average_position.y - target_hold_average_y)
			var horizontal_target_penalty: float = absf(average_position.x - target_center_x)
			var spacing_penalty: float = absf(spacing_x - target_anchor_spacing)
			var vertical_alignment_penalty: float = absf(left_hold.global_position.y - right_hold.global_position.y)
			var collapse_penalty: float = 0.0
			if spacing_x < 48.0:
				collapse_penalty = 1000.0

			var score: float = vertical_target_penalty \
				+ (horizontal_target_penalty * 0.35) \
				+ (spacing_penalty * 0.5) \
				+ (vertical_alignment_penalty * 0.75) \
				+ collapse_penalty
			if score < best_score:
				best_score = score
				best_left_hold = left_hold
				best_right_hold = right_hold

	Validation.require_condition(best_left_hold != null, "RunScene rewarded continue requires a left rescue handhold.")
	Validation.require_condition(best_right_hold != null, "RunScene rewarded continue requires a right rescue handhold.")
	return [
		HandholdTargetScript.new(
			best_left_hold.name,
			best_left_hold.global_position,
			best_left_hold.get_path(),
			_require_handhold_drain_multiplier(best_left_hold),
			_require_handhold_type(best_left_hold)
		),
		HandholdTargetScript.new(
			best_right_hold.name,
			best_right_hold.global_position,
			best_right_hold.get_path(),
			_require_handhold_drain_multiplier(best_right_hold),
			_require_handhold_type(best_right_hold)
		),
	]

func _calculate_rewarded_continue_body_position(left_hold_target: HandholdTargetScript, right_hold_target: HandholdTargetScript) -> Vector2:
	left_hold_target.assert_valid()
	right_hold_target.assert_valid()
	var average_hold_position: Vector2 = (left_hold_target.attach_position + right_hold_target.attach_position) * 0.5
	return average_hold_position + Vector2.DOWN * _get_climb_tuning_float(&"grip_hang_offset_pixels")

func _get_climb_tuning_float(property_name: StringName) -> float:
	var property_value: Variant = climb_tuning.get(property_name)
	if property_value is float:
		return property_value

	if property_value is int:
		var int_value: int = property_value
		return float(int_value)

	Validation.require_condition(false, "Climb tuning property %s must be numeric." % String(property_name))
	return 0.0

func _clear_aim_preview() -> void:
	if _left_aim_preview != null:
		_left_aim_preview.queue_free()
		_left_aim_preview = null

	if _right_aim_preview != null:
		_right_aim_preview.queue_free()
		_right_aim_preview = null

	if _aim_target_marker != null:
		_aim_target_marker.queue_free()
		_aim_target_marker = null

func _update_touch_position(event: InputEventScreenTouch) -> void:
	if event.pressed:
		_begin_touch_contact(event.index, event.position)
		return

	_end_touch_contact(event.index)

func _update_touch_drag(event: InputEventScreenDrag) -> void:
	var touch_contact: MobileTouchContactScript = _find_touch_contact(event.index)
	if touch_contact == null:
		return

	touch_contact.update_current_position(event.position)

func _begin_touch_contact(index: int, position: Vector2) -> void:
	_end_touch_contact(index)
	_active_touch_contacts.append(MobileTouchContactScript.new(index, position, position))

func _end_touch_contact(index: int) -> void:
	var remaining_touch_contacts: Array[RefCounted] = []
	for raw_touch_contact in _active_touch_contacts:
		var touch_contact: MobileTouchContactScript = _as_touch_contact(raw_touch_contact)
		if touch_contact.index != index:
			remaining_touch_contacts.append(touch_contact)

	_active_touch_contacts = remaining_touch_contacts

func _find_touch_contact(index: int) -> MobileTouchContactScript:
	for raw_touch_contact in _active_touch_contacts:
		var touch_contact: MobileTouchContactScript = _as_touch_contact(raw_touch_contact)
		if touch_contact.index == index:
			return touch_contact

	return null

func _as_touch_contact(raw_touch_contact: RefCounted) -> MobileTouchContactScript:
	Validation.require_condition(raw_touch_contact is MobileTouchContactScript, "RunScene requires MobileTouchContact touch state.")
	return raw_touch_contact as MobileTouchContactScript
