class_name MainMenuScene
extends Control

const AppSettingsAndSaveStorageRuntimeScript = preload("res://src/platform/storage/app_settings_and_save_storage_runtime.gd")
const AppSettingsSnapshotScript = preload("res://src/platform/storage/app_settings_snapshot.gd")
const AudioSettingsAdapterScript = preload("res://src/platform/audio/audio_settings_adapter.gd")
const CoinTransactionLedgerScript = preload("res://src/economy/coin_transaction_ledger.gd")
const CosmeticInventoryScript = preload("res://src/cosmetics/cosmetic_inventory.gd")
const CosmeticItemCatalogScript = preload("res://resources/config/cosmetic_item_catalog.gd")
const CosmeticLoadoutScript = preload("res://resources/config/cosmetic_loadout.gd")
const CosmeticLoadoutServiceScript = preload("res://src/cosmetics/cosmetic_loadout_service.gd")
const CosmeticPurchaseResultScript = preload("res://src/cosmetics/cosmetic_purchase_result.gd")
const CosmeticUnlockPurchaseServiceScript = preload("res://src/cosmetics/cosmetic_unlock_purchase_service.gd")
const GodotAudioSettingsAdapterScript = preload("res://src/platform/audio/godot_audio_settings_adapter.gd")
const JsonFileLocalStorageAdapterScript = preload("res://src/platform/storage/json_file_local_storage_adapter.gd")
const LocalStorageAdapterScript = preload("res://src/platform/storage/local_storage_adapter.gd")
const MainMenuScript = preload("res://scenes/ui/main_menu.gd")
const PersistentCoinTransactionServiceScript = preload("res://src/economy/persistent_coin_transaction_service.gd")
const RunEconomyRuntimeScript = preload("res://src/gameplay/run/run_economy_runtime.gd")
const RunOverlayRuntimeScript = preload("res://src/ui/run_overlay_runtime.gd")
const SettingsMenuScript = preload("res://scenes/ui/settings_menu.gd")
const SettingsMenuScene = preload("res://scenes/ui/settings_menu.tscn")
const SettingsPresenterScript = preload("res://src/ui/settings_presenter.gd")
const StorePresenterScript = preload("res://src/ui/store_presenter.gd")
const StoreShellScript = preload("res://scenes/ui/store_shell.gd")
const StoreShellScene = preload("res://scenes/ui/store_shell.tscn")
const WalletScript = preload("res://src/economy/wallet.gd")
const WalletTransactionServiceScript = preload("res://src/economy/wallet_transaction_service.gd")
const RUN_SCENE_PATH: String = "res://scenes/main/run_scene.tscn"
const TUTORIAL_SCENE_PATH: String = "res://scenes/main/tutorial_scene.tscn"

@export var cosmetic_item_catalog: CosmeticItemCatalogScript
@export var cosmetic_loadout: CosmeticLoadoutScript

@onready var _main_menu: MainMenuScript = %MainMenu

var _audio_settings_adapter: AudioSettingsAdapterScript = GodotAudioSettingsAdapterScript.new()
var _local_storage_adapter: LocalStorageAdapterScript = JsonFileLocalStorageAdapterScript.new()
var _settings_menu: SettingsMenuScript = null
var _settings_presenter: SettingsPresenterScript = SettingsPresenterScript.new()
var _storage_runtime: AppSettingsAndSaveStorageRuntimeScript = AppSettingsAndSaveStorageRuntimeScript.new()

var _wallet: WalletScript = WalletScript.new()
var _persistent_transaction_ledger: CoinTransactionLedgerScript = CoinTransactionLedgerScript.new()
var _cosmetic_inventory: CosmeticInventoryScript = CosmeticInventoryScript.new()
var _cosmetic_loadout_service: CosmeticLoadoutServiceScript = CosmeticLoadoutServiceScript.new()
var _cosmetic_unlock_purchase_service: CosmeticUnlockPurchaseServiceScript = CosmeticUnlockPurchaseServiceScript.new()
var _persistent_coin_transaction_service: PersistentCoinTransactionServiceScript = PersistentCoinTransactionServiceScript.new()
var _wallet_transaction_service: WalletTransactionServiceScript = WalletTransactionServiceScript.new()
var _store_presenter: StorePresenterScript = StorePresenterScript.new(_cosmetic_loadout_service)
var _overlay_runtime: RunOverlayRuntimeScript = RunOverlayRuntimeScript.new()
var _run_economy_runtime: RunEconomyRuntimeScript = RunEconomyRuntimeScript.new()
var _store_shell: StoreShellScript = null

func _ready() -> void:
	_validate_required_nodes()
	_validate_required_state()
	_storage_runtime.initialize_app_settings_storage()
	_storage_runtime.initialize_save_storage()
	_storage_runtime.load_or_create_app_settings()
	_storage_runtime.apply_app_settings(_audio_settings_adapter)
	_storage_runtime.load_or_create_save_state(cosmetic_loadout, cosmetic_item_catalog)
	_sync_save_backed_runtime_models()
	cosmetic_loadout = _duplicate_cosmetic_loadout(cosmetic_loadout)
	_storage_runtime.apply_saved_cosmetic_selection(
		cosmetic_loadout,
		_cosmetic_inventory,
		cosmetic_item_catalog,
		_cosmetic_loadout_service
	)
	var _start_connect_result: int = _main_menu.connect(&"start_requested", Callable(self, "_on_start_requested"))
	var _tutorial_connect_result: int = _main_menu.connect(&"tutorial_requested", Callable(self, "_on_tutorial_requested"))
	var _settings_connect_result: int = _main_menu.connect(&"settings_requested", Callable(self, "_on_settings_requested"))
	var _store_connect_result: int = _main_menu.connect(&"store_requested", Callable(self, "_on_store_requested"))

func _validate_required_state() -> void:
	Validation.require_condition(cosmetic_item_catalog != null, "MainMenuScene requires a cosmetic item catalog before ready.")
	Validation.require_condition(cosmetic_loadout != null, "MainMenuScene requires a cosmetic loadout before ready.")

func set_local_storage_adapter(local_storage_adapter: RefCounted) -> void:
	Validation.require_condition(local_storage_adapter != null, "MainMenuScene requires a local storage adapter.")
	Validation.require_condition(local_storage_adapter is LocalStorageAdapterScript, "MainMenuScene requires a LocalStorageAdapter implementation.")
	_local_storage_adapter = local_storage_adapter as LocalStorageAdapterScript
	_storage_runtime.set_local_storage_adapter(_local_storage_adapter)
	if not is_node_ready():
		return

	_storage_runtime.load_or_create_app_settings()
	_storage_runtime.apply_app_settings(_audio_settings_adapter)
	_storage_runtime.load_or_create_save_state(cosmetic_loadout, cosmetic_item_catalog)
	_sync_save_backed_runtime_models()
	_storage_runtime.apply_saved_cosmetic_selection(
		cosmetic_loadout,
		_cosmetic_inventory,
		cosmetic_item_catalog,
		_cosmetic_loadout_service
	)
	_refresh_settings_menu()

func set_audio_settings_adapter(audio_settings_adapter: RefCounted) -> void:
	Validation.require_condition(audio_settings_adapter != null, "MainMenuScene requires an audio settings adapter.")
	Validation.require_condition(audio_settings_adapter is AudioSettingsAdapterScript, "MainMenuScene requires an AudioSettingsAdapter implementation.")
	_audio_settings_adapter = audio_settings_adapter as AudioSettingsAdapterScript
	if not is_node_ready():
		return

	_storage_runtime.apply_app_settings(_audio_settings_adapter)

func get_settings_menu_for_test() -> SettingsMenuScript:
	return _settings_menu

func _on_start_requested() -> void:
	_change_to_scene(RUN_SCENE_PATH)

func _on_tutorial_requested() -> void:
	_change_to_scene(TUTORIAL_SCENE_PATH)

func _change_to_scene(scene_path: String) -> void:
	Validation.require_condition(not scene_path.is_empty(), "MainMenuScene scene path cannot be empty.")
	var change_result: Error = get_tree().change_scene_to_file(scene_path)
	Validation.require_condition(change_result == OK, "MainMenuScene could not load the requested scene.")

func _on_settings_requested() -> void:
	_show_settings_menu()

func _show_settings_menu() -> void:
	_ensure_settings_menu()
	_refresh_settings_menu(true)

func _ensure_settings_menu() -> void:
	if _settings_menu != null:
		return

	var settings_node: Node = SettingsMenuScene.instantiate()
	Validation.require_condition(settings_node != null, "MainMenuScene settings menu scene must instantiate a node.")
	Validation.require_condition(settings_node is SettingsMenuScript, "MainMenuScene settings menu scene must instantiate SettingsMenu.")
	_settings_menu = settings_node as SettingsMenuScript
	add_child(_settings_menu)
	var _closed_connect_result: int = _settings_menu.connect(&"closed", Callable(self, "_on_settings_closed"))
	var _audio_muted_connect_result: int = _settings_menu.connect(&"audio_muted_changed", Callable(self, "_on_settings_audio_muted_changed"))
	var _volume_connect_result: int = _settings_menu.connect(&"master_volume_changed", Callable(self, "_on_settings_master_volume_changed"))
	var _haptics_connect_result: int = _settings_menu.connect(&"haptics_enabled_changed", Callable(self, "_on_settings_haptics_enabled_changed"))
	var _touch_split_connect_result: int = _settings_menu.connect(&"touch_split_changed", Callable(self, "_on_settings_touch_split_changed"))
	var _touch_dead_zone_connect_result: int = _settings_menu.connect(&"touch_center_dead_zone_changed", Callable(self, "_on_settings_touch_center_dead_zone_changed"))

func _refresh_settings_menu(visible: bool = false) -> void:
	if _settings_menu == null:
		return

	var app_settings_snapshot: AppSettingsSnapshotScript = _storage_runtime.get_app_settings_snapshot()
	_settings_menu.apply_state(_settings_presenter.build_state(app_settings_snapshot, visible))

func _on_settings_closed() -> void:
	_refresh_settings_menu(false)

func _on_settings_audio_muted_changed(audio_muted: bool) -> void:
	_storage_runtime.set_audio_muted(audio_muted, _audio_settings_adapter)
	_refresh_settings_menu(true)

func _on_settings_master_volume_changed(master_volume_ratio: float) -> void:
	_storage_runtime.set_master_volume_ratio(master_volume_ratio, _audio_settings_adapter)
	_refresh_settings_menu(true)

func _on_settings_haptics_enabled_changed(haptics_enabled: bool) -> void:
	_storage_runtime.set_haptics_enabled(haptics_enabled)
	_refresh_settings_menu(true)

func _on_settings_touch_split_changed(touch_split_ratio: float) -> void:
	_storage_runtime.set_touch_split_ratio(touch_split_ratio)
	_refresh_settings_menu(true)

func _on_settings_touch_center_dead_zone_changed(touch_center_dead_zone_ratio: float) -> void:
	_storage_runtime.set_touch_center_dead_zone_ratio(touch_center_dead_zone_ratio)
	_refresh_settings_menu(true)

func get_store_shell_for_test() -> StoreShellScript:
	return _store_shell

func _on_store_requested() -> void:
	_ensure_store_shell()
	_refresh_store_ui()

func _ensure_store_shell() -> void:
	if _store_shell != null:
		return

	var store_node: Node = StoreShellScene.instantiate()
	Validation.require_condition(store_node != null, "MainMenuScene store scene must instantiate a node.")
	Validation.require_condition(store_node is StoreShellScript, "MainMenuScene store scene must instantiate StoreShell.")
	_store_shell = store_node as StoreShellScript
	add_child(_store_shell)
	var _select_connect_result: int = _store_shell.connect(&"item_selected", Callable(self, "_on_store_item_selected"))
	var _purchase_connect_result: int = _store_shell.connect(&"purchase_requested", Callable(self, "_on_store_purchase_requested"))
	var _equip_connect_result: int = _store_shell.connect(&"equip_requested", Callable(self, "_on_store_equip_requested"))
	var _closed_connect_result: int = _store_shell.connect(&"closed", Callable(self, "_on_store_closed"))

func _refresh_store_ui() -> void:
	Validation.require_condition(_store_shell != null, "MainMenuScene requires StoreShell before refreshing store UI.")
	var store_state: RefCounted = _overlay_runtime.build_store_state(
		_store_presenter,
		cosmetic_item_catalog,
		_cosmetic_inventory,
		cosmetic_loadout,
		_wallet
	)
	_store_shell.apply_state(store_state)

func _on_store_item_selected(item_id: StringName) -> void:
	Validation.require_condition(not item_id.is_empty(), "MainMenuScene store selected item id cannot be empty.")
	_overlay_runtime.select_store_item(item_id)
	_refresh_store_ui()

func _on_store_purchase_requested(item_id: StringName) -> void:
	Validation.require_condition(not item_id.is_empty(), "MainMenuScene store purchase item id cannot be empty.")
	var result: CosmeticPurchaseResultScript = _run_economy_runtime.purchase_cosmetic_item_and_persist(
		_storage_runtime,
		_wallet,
		_cosmetic_inventory,
		cosmetic_item_catalog,
		_persistent_transaction_ledger,
		cosmetic_loadout,
		_wallet_transaction_service,
		_persistent_coin_transaction_service,
		_cosmetic_unlock_purchase_service,
		item_id
	)
	_overlay_runtime.record_purchase_result(result, cosmetic_item_catalog)
	_refresh_store_ui()

func _on_store_equip_requested(item_id: StringName) -> void:
	Validation.require_condition(not item_id.is_empty(), "MainMenuScene store equip item id cannot be empty.")
	_run_economy_runtime.equip_cosmetic_item_and_persist(
		_storage_runtime,
		_wallet,
		_persistent_transaction_ledger,
		_cosmetic_inventory,
		cosmetic_loadout,
		cosmetic_item_catalog,
		_cosmetic_loadout_service,
		item_id
	)
	_overlay_runtime.record_equipped_item(item_id, cosmetic_item_catalog)
	_refresh_store_ui()

func _on_store_closed() -> void:
	_overlay_runtime.clear_store_feedback()

func _sync_save_backed_runtime_models() -> void:
	if not _storage_runtime.has_save_snapshot():
		return
	_wallet = _storage_runtime.create_wallet_from_save_snapshot()
	_persistent_transaction_ledger = _storage_runtime.create_persistent_transaction_ledger_from_save_snapshot()
	_cosmetic_inventory = _storage_runtime.create_cosmetic_inventory_from_save_snapshot(cosmetic_item_catalog)

func _duplicate_cosmetic_loadout(loadout: Resource) -> CosmeticLoadoutScript:
	Validation.require_condition(loadout != null, "MainMenuScene requires a cosmetic loadout resource.")
	Validation.require_condition(loadout is CosmeticLoadoutScript, "MainMenuScene requires a CosmeticLoadout resource.")
	var duplicated_loadout: Resource = (loadout as CosmeticLoadoutScript).duplicate(true)
	Validation.require_condition(duplicated_loadout is CosmeticLoadoutScript, "MainMenuScene duplicated cosmetic loadout must implement CosmeticLoadout.")
	var typed_duplicated_loadout: CosmeticLoadoutScript = duplicated_loadout as CosmeticLoadoutScript
	typed_duplicated_loadout.assert_valid()
	return typed_duplicated_loadout

func _validate_required_nodes() -> void:
	Validation.require_condition(_main_menu != null, "MainMenuScene requires MainMenu.")
	Validation.require_condition(_main_menu is MainMenuScript, "MainMenuScene requires a MainMenu implementation.")
